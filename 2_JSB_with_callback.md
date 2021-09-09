# JSB with callback

## 带有回调的JS Java bridge示例

### 机制实现

基于原本的机制，我们可以额外封装一层多事件派发的 callNativeWithCb 接口和一系列用法来完成异步回调的功能。这个接口允许开发者触发下层事件之后，通过下层事件的返回值来触发回调函数。同时可以有多个cb存在（此时需要注意对应的prototype是否相同）。它们会在事件被调用完成后进行异步处理。此处的调用机制实际上和之前的jsb调用不同，CbNativeBridge是一个调用了CocosNativeBridge的类。这是一个单例对象，同时之后在Java调用js回调的流程中也会使用到。

```js
class CbNativeBridge{
    private cbMap: Map<String, Map<number, Function>>;
    public instance: CbNativeBridge;
    /**
     * Based on callPlatformEvent, call with less reflection, 
     * Async Method
     * @param {string} eventName: event name on java/oc layer
     * @param {string} arg: argument as input to dispatch java/oc event, map format and will be transferred on Java layer etc.
     */
    constructor(){
        this.cbMap = new Map<String, Map<number, Function>>();
        CbNativeBridge.instance = this;
        CocosNativeBridge.registerEvent("triggerCb",this.triggerCallbackof);
    }
    public callNativeWithCb(eventName: string, arg?: string|null,tag?:number, cb?: (arg: string)=>void): void{
        if(!this.cbMap.get(eventName)){
            var m = new Map<number, Function>();
            this.cbMap.set(eventName, m);
        }
        if(!tag){
            tag = this.cbMap[eventName].size();
        }
        this.cbMap[eventName].set(tag, cb);
        jsb.callNative(eventName, arg);
    }

    public triggerCallbackOf(arg: string): void{
        var jsonObj = JSON.parse(arg);
        var eventName = jsonObj.eventName;
        var callbackArg = jsonObj.arg;
        var tag = jsonObj.tag;

        this.cbMap.get(eventName)!.get(tag)!(callbackArg);
    }
}
```

这个事件会将callNativeWithCb会将callback方法注册到cbMap中，同时callback对应的索引值由eventName和顺序生成的tag组合进行查找。并调用eventName对应的Function数组中的回调函数，从而通过相对简单的数据结构，允许开发者调用多次Event并回调不同的方法。

在JAVA层中该方法会调用eventName对应的IEvent，并将tag作为参数添加到传参中。此时开发者可以自己选择在JAVA事件中选择是否触发该方法。

这时候在JAVA层，callJsCallback的实现是这样的：

```JAVA
public class CbJsBridge{
    public static CbJsBridge instance;
    public void callJsCallbackOf(String eventName, int tag, String arg){
        JSONObject cbArg = new JSONObject();
            try {
                cbArg.put("eventName", s);
                cbArg.put("tag",tag);
                cbArg.put("arg", arg);
            }catch (Exception e){
                return;
            }
        CocosNativeBridge.callJs("triggerCb",cbArg.toString());
    }
    CbJsBridge(){
        instance = this;
    }
}
```

我们通过callJs方法调用到js层的triggerCb函数，来调用被注册的callback。当然，其中cbArg是被封装为Json对象后在js层再次被解析。

### 调用举例

同样以OpenAd举例：

```js
@ccclass('ExComponent')
export class ExComponent extends Component {
    ...
    start(){
        CocosNativeBridge.callNativeWithCb("openAd", "{url:"www.xxx.com"}", (arg)=>{
            //Do something
        })
    }
}
```

```JAVA
//JAVA code
void openAdFunction(String content){
    ...
    JSONObject jsonArg = JSONObject(content);
    int tag = jsonArg.getInt("tag");
    ...
    CocosJsBridge.callJsCallbackOf("openAd", tag, arg);
}
//JSONObject is a native util which admit you to jsonfy 
Boolean ok = CocosEventManager.registerEvent("OpenAd", openAdFunction);

```

这样就完成了一次Js调用Java的回调函数的调用。也许你会觉得有点绕，为什么callJsCallback方法所使用的eventName和自己所注册的事件名称是一致的呢？这是为了保证命名能够符合语义。从英语语义上来讲，就是
> js call native function "OpenAd" with callback F, java event was dispatched and call js callback function of event "OpenAd", leads to callback F.

此外，这样的接口还有很多的延展性。比如callNativeWithCb实际上是将Callback函数注册到map中，但是Java可以回调多个事件所注册的函数甚至是以下的写法：

```JAVA
void openAdFunction(String content){
    ...
    JSONObject jsonArg = JSONObject(content);
    int tag = jsonArg.getInt("tag");
    ...
    CocosJsBridge.callJsCallbackOf("openAd", tag, arg);
    CocosJsBridge.callJs("changeLabel", argX);
}
```

这赋予了开发者很高的自由度。

## 带有回调的JAVA调用Js示例

我们同样可以将这个接口反过来处理，来实现带有回调函数的Java -> Js的调用

```JAVA
public class CbJsBridge{
    private final HashMap<String, HashMap<Integer,IEvent>> cbMap = new HashMap<>();
    public void callJsWithCb(String eventName, String arg, int tag, IEvent cb){
        if(cbMap.get(eventName) == null){
            cbMap.put(eventName, new HashMap<>());
        }
        cbMap.get(eventName).put(tag, cb);
        CocosJsBridge.callJs(eventName, arg);
    }
    public void triggerCallbackOf(String arg) {
        try{
            JSONObject jobj = new JSONObject(arg);
            String eventName = jobj.getString("eventName");
            String cbArg = jobj.getString("cbArg");
            int tag = jobj.getInt("tag");
            cbMap.get(eventName).get(tag).run(cbArg);
        }
        catch (Exception ignored){
        }
    }
}
```

同样是通过封装接口到一个类中，并借由android和主线程不同的特性实现异步回调。并且自由度也很高（当然也很容易写出bug）。

```js
public class CbNativeBridge
{
    public callNativeCallbackOf(eventName: String, tag: number, arg: String):void{
        var args = {
            eventName :eventName,
            tag:tag,
            arg:arg
        }
        jsb.callNative(JSON.stringify(args));
    }
}
```

用法

```js
@ccclass('ExComponent')
export class ExComponent extends Component {
    ...
    public changeLabel(arg: String){
        var jsonObj = JSON.parse(arg);
        var tag = jsonObj.tag;
        ...
        CocosNativeBridge.callNativeCallbackOf("changeLabel",tag, cbArg);
    }
    start(){
        CocosNativeBridge.registerEvent("changeLabel", this.changeLabel);
    }
}
```

```JAVA

CbJsBridge.instance.callJsWithCb("changeLabel", "Hello",(String arg)->{
    //Do something
})
```

至此我们通过原本的两个管道接口实现了一个带有回调函数的事件触发。但这个功能封装还有很大的改进空间，也可以用来做很多有趣的事情。这里只是给出了最简实现。
