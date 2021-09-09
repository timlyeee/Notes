# 反射机制的简化和双向反射？

## CXX 反射到 JS

当前的COCOS的反射机制是通过jsb的绑定机制实现，实际是调用了v8的端口（有待确认），但是通过一个应用初始化时的函数队列，可以做到查找到任意函数并调用。

engine > reflection > callStaticFunction 是JS调用CXX函数的主体。但这个函数同样是native函数，是通过 cc::Class >  defineFunction 去注册到js层的。所以一来是参数严格锁定，二来是依赖v8等多种引擎机制。

在引擎中对于JS定义的函数同样可以获取到。但这需要和上述一样的v8 API。callAsFunction。

同时我们声明了ScriptEngine，并在其中声明Call方法，并且在Call方法中将需要调用的方法作为se::Object调用。

如果要优化JS层调用CXX函数的方法，不排除两种可能：1. 消息机制，通过fastMQ消息空间将需要调用的函数进行调用。2. 实现反射方法将JS层的函数映射到CXX层，但这就很依赖编译时处理。

### **消息机制**

如果单纯来看消息机制的实现方法，首先要保证通信和响应的速度。还有一点就是v8本身就开启一个消息通道，以及Devtool同样依赖这个消息通道。这个是怎么实现的呢？

MessageQ实际上是实现了一个BufferArea，去管理众多被Register登记的内容。通过：

```c++
se->addRegisterCallback(functionX);
se::Object *           msgQueue{nullptr};
globalThis->setProperty("__fastMQ__", se::Value(msgQueue))
```

将msgQueue注入到js层，这样js层和C++层就会同时拥有同一个fastMQ对象空间并且对其中的变量或者函数进行控制。

假设我们要减少用户写法上的负担，就需要减少API调用的写法步骤，最简方法如下：

```typescript
//typescript: use callback 
jsb.request(cxxFunctionToCall, args/*args to input to cxxFunctionToCall*/, callback/*()=>{}*/);
```

```cxx
static void cxxFunctionToCall(typename...args){
    //actions
}
functionMap[cxxFunctionToCall]=cxxFunctionToCall;//push to functionMap
```

这样只需要加入需要的方法就可以使用。所以我们需要考虑两个事情：1. 如果加入消息机制，会不会影响消息机制本身的回调，或者增加额外的开销。2. 如果加入消息机制，用户能使用这样的写法嘛？

### **定义函数并添加到jsb绑定**

同样的两个问题，但是因为实现逻辑不一样所以得出的结果可能也不一样。

```c++
__jsbObj->defineFunction("openURL", _SE(JSB_openURL));
v8::Maybe<bool> ret = _obj.handle(__isolate)->Set(context,
                                                      v8::Local<v8::Name>::Cast(maybeFuncName.ToLocalChecked()),
                                                      maybeFunc.ToLocalChecked());
```

以打开URL功能为例，defineFunction会帮助将该函数注册到ScriptEngine中，然后在v8中可以通过使用这个函数进行调用并实现回调。

## 数据处理

如何确认callback的传参和返回值？

如何统一传入的args？或者分解args到各个部分？假设我现在传参都是string。

如何统一eventMap？std::map<string, std::function(void<>)>?

state——》提取参数的操作

### JAVA层的Trigger操作

尽管Function的功能在Java1.8中就已经可以使用，但对于Android而言只在Api24中开放功能。
Api24对应的是Android7.0。也就是说在7.0之前我们要么自己实现一套Function端口功能，要么使用原生的Function interface但是限定版本使用。

JAVA中对应的Function Callable Runnable等分属于不同的库，
- Runnable： The Runnable interface should be implemented by any class whose instances are intended to be executed by a thread. The class must define a method of no arguments called run.不接受参数，返回值为空
- Callable： Callable<V> a single method with no arguments and return V
- Supplier： 不接受参数但是可以使用上下文域内的参数。和Js的匿名函数很像。

Runnable              -> void run( );
Supplier<T>           -> T get( );
Consumer<T>           -> void accept(T);
Predicate<T>          -> boolean test(T);
UnaryOperator<T>      -> T apply(T);
BinaryOperator<T,U,R> -> R apply(T, U);
Function<T,R>         -> R apply(T);
BiFunction<T,U,R>     -> R apply(T, U);
//... and some more of it ...
Callable<V>           -> V call() throws Exception;
Readable              -> int read(CharBuffer) throws IOException;
AutoCloseable         -> void close() throws Exception;
Iterable<T>           -> Iterator<T> iterator();
Comparable<T>         -> int compareTo(T);
Comparator<T>         -> int compare(T,T);
> https://cloud.tencent.com/developer/ask/43770

实际上Function<T, R>的实现十分简单，所以根本不需要用到原本的库，自己实现一套小型接口就行

### JNI StringArray作为返回值

如果Java层需要有两个返回值，一般会用objectArray来存储，

如果在JAVA层返回值为String[]但是其中一个不赋值的话（在c++中是会设置为空“”），会以Null的形势返回。

```java
String[] result;
if(...)
result[0] = error;
else(...)
result[1] = ret;
|->
result = {String[2]@12246}
Nothing showing null elements
1 = "Met"
```

### JNI创建的变量中获取值

类似Jni的接口中一般不判断值的内容而是假定全部正确，而且不会向上层throwException。这会导致即使我们做了Try Catch处理，也不会有异常抛出，而是需要自己判断。