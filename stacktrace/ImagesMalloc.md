# Showcase 运行过载

## 从代码反推引擎行为逻辑

由于对于Image的malloc行为并不完全了解和清晰，在native层和js层就可能会出现一些认知上的偏差或者本身这两者的垃圾回收处理就有区别。在无法确认内存管理情况下，只能先通过堆栈反推逻辑了。

在malloc失败的代码断点有三个，第一个是Image中的`InitWithPngData`(或者其它的图像数据格式)，第二个是`CopyBufferToTexture`，第三个是`ThreadSafeLinearAllocator`中的alloc。这三者都是与Image相关。 所以可以从Image的`InitWithJpgData`。

StackTrace：For Cpp
```c++
js_loadImage(){
    ..
    jsb_global_load_image(..)
    ..
}REGISTER_AS("jsb.loadImage")
bool jsb_global_load_image(..){
    ..
    initWithImageFile(path)
    ..
}
-> 
Image::initWithImageFile(){
        ...
        _data    = static_cast<unsigned char *>(malloc(_dataLen * sizeof(unsigned char)));
        ...
    }
->
```
StackTrace: For JS
```js
jsb.loadImage(src, ()=>{
    ...
})
downloadDomImage(){
    const img = new Image();
    ..
    img.src = url;
    ..
}
class pipeline{
    _flow(index, task):void{
        ...
    }
}
PackManager.load()
{
    parse(task, done)// this indirectly goto pipeline's task
}

loadOneAssetPipeline = new Pipeline('loadOneAsset', [


])
```

由此可知，图像内容的读取实际上是在PackManager中加载并获取的，那么这个loadOneAssetPipeline是做什么的呢？

其本质是一个Pipeline，而读取分包资源实际上就是其中一个Pipe步骤。

PackManager用来处理打包资源，包括拆包，加载，缓存等等，这是一个单例, 所有成员能通过 `cc.assetManager.packManager` 访问

现在目光聚焦于我~这里很明显有一个疑惑，Image真的不会出现内存泄漏嘛，因为除了pipeline还有别的地方回去读取文件数据，但肯定都会通过PackManager或者AssetManager进行读取。

在尝试了许多个场景之后我能够确定得出另一个结论：

`loadImage`和`destroyImage`应该是一一对应的，在场景开始加载时渲染管线会将内容动态加载到pipeline中，在场景渲染完成后调用`js_destroyImage`销毁，那么被创造出来的image是什么时候被销毁的呢？两者是否一一对应？另外，创建出来的texture最终的生命周期是否正常呢？

## Count计数加位置追踪

我尝试在`loadImage`和`destroyImage`的地方分别加入计数处理，来判断最终两者的加减是否相同。并且在`initImageWithData`和`~Image`处分别加入了另一个计数处理。最终发现实际上`destroyImage`总是跟随着场景的初始化完成，但并非每一次都能够彻底清空其内部。并且`destroyImage`是由freeAsset最终导向的。

故此有了疑点一。

在sponza场景初始化完成后，`loadImage`的计数甚至达到了80，但却没有`destroyImage`，结果在下一个场景加载时，就因为malloc失败而导致程序卡死。

但是在单独测试sponza场景和后一个场景的加载中，我发现loadImage的调用次数也能上升到84且没有崩溃，所以陷入死局。

## 内存分配策略

更广义的来看内存分配的策略。以及回收机制的话，大部分应该聚焦于即时分配大量内存而没有统一管理的情况。比如场景加载到加载完成是否有未释放的内存，或者需求的内存太多而无法供给。

运行内存和堆内存是否相同？不，运行内存包含了堆内存。

## Buffer[] 的释放？

如果把