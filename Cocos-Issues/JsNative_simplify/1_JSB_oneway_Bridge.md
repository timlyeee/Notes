# JSB Bridge

由于之前的jsJavaBridge的调用方式比较复杂，不太好复用，故提供一种更简便的使用方法。

## 命名

```js
//JavaScript
export namespace reflection{
        /**
         * https://docs.cocos.com/creator/manual/zh/advanced-topics/java-reflection.html
         * call OBJC/Java static methods
         *
         * @param className
         * @param methodName
         * @param methodSignature
         * @param parameters
         */
        export function callStaticMethod (className: string, methodName: string, methodSignature: string, ...parameters:any): any;
        /**
         * inform application to apply specific method/function
         * @param {string} methodName: method name on java/oc layer
         * @param {string} arg: argument as input for app's function, json format suggest.
         */
         export function sendToNative(arg0: string, arg1?: string | null): void;
         /**
          * save your own callback controller with a js function
          * @param {Function} callback: method accepts 2 string args
          */
         export function setCallback(callback: Function): void;
 
    }
```

```JAVA
//JAVA
public class JsbBridge {
    public interface ICallback{
        /**
         * Applies this callback to the given argument.
         *
         * @param arg0 as input
         * @param arg1 as input
         */
        void onScript(String arg0, String arg1);
    }
    private static ICallback callback;

    private static boolean callByScript(String arg0, String arg1){
        if(JsbBridge.callback == null)
            return false;
        callback.onScript(arg0, arg1);
        return true;
    }

    /**Add a callback which you would like to apply
     * @param f ICallback, the method which will be actually applied. multiple calls will override
     * */
    public static void setCallback(ICallback f){
        JsbBridge.callback = f;
    }
    /**
     * Java dispatch Js event, use native c++ code
     * @param arg0 input values
     */
    public static native void sendToScript(String arg0, String arg1);
    public static void sendToScript(String arg0){
        sendToScript(arg0, null);
    }
}
```
```objc
typedef void (^ICallback)(NSString*, NSString*);
//typedef int64_t strFunc;

@interface JsbBridge : NSObject
+(instancetype)sharedInstance;
-(bool)setCallback:(ICallback)cb;
-(bool)callByScript:(NSString*)arg0 arg1:(NSString*)arg1;
-(void)sendToScript:(NSString*)arg0 arg1:(NSString*)arg1;
@end

```

## JS 调用 Java 事件

### API

js调用java的原型API只有一个。单向调用java事件

```js
    export function sendToNative(arg0: string, arg1?: string | null): void;
```

简单用法:

```js
jsb.sendToNative("OpenAd", "{URL:"www.xxx.com"}");
```

尽管js的调用各平台的事件接口是统一的，但是对应不同平台确实会有不同的事件注册方法。以JAVA为例，addMethod会将该方法添加到methodMap中并将方法名称作为索引来调用该方法：

```JAVA
//JAVA
public class JsbBridge {
    public interface ICallback{
            /**
            * Applies this callback to the given argument.
            *
            * @param arg0 as input
            * @param arg1 as input
            */
            void onScript(String arg0, String arg1);
    }
    private static ICallback callback;

    public static void setCallback(ICallback f){
        JsbBridge.callback = f;
    }
    private static boolean callByScript(String arg0, String arg1){
        if(JsbBridge.callback == null)
            return false;
        callback.onScript(arg0, arg1);
        return true;
    }
}
```

需要注意的是尽管 sendToScript 方法是单向通信，其不会关心下层的返回情况，也不会告知js代码操作成功或者失败。我们举一个打开广告的例子来说明这个接口是如何调用到下层的事件的。

### 简单的例子，实现一个以map存储的eventMap

我们先创建一个 JsbBridgeTest 来保存我们需要的打开广告的操作。以往的JavaScriptJavaBridge只能调用Static函数，但是通过addMethod我们则可以把成员函数也暴露给脚本层。

```java
//JAVA code
public class JsbBridgeTest {
    public interface MyCallback{
        void onTrigger(String arg);
    }

    public static HashMap<String, MyCallback> myCallbackHashMap = new HashMap<>();
    private static JsbBridgeTest instance;
}
//In AppActivity
JsbBridgeTest.myCallbackHashMap.put("callWithArg", arg ->{
            System.out.print("@JAVA: here is the argument transport in" + arg);
            JsbBridge.sendToScript("sayHelloInJs","Charlotte");
        }
        );
        JsbBridge.setCallback(new JsbBridge.ICallback() {
            @Override
            public void onScript(String arg0, String arg1) {
                JsbBridgeTest.myCallbackHashMap.get(arg0).onTrigger(arg1);
            }
        });
```

上述代码中我们通过初始化一个 callWithArg 作为我们的方法。并且创建一个匿名函数作为JsbBridge的Callback。这个callback可以把第一个传入的参数作为索引，第二个参数作为map中函数的参数，这样就实现了一个一个ICallback处理多个event的功能

## JAVA 调用 JS 方法

保持接口的统一性，原始的Api接口同样是单向调用，命名规则相对一致。其定义在CocosMethodManager类中。同时需要被调用的JS的事件被注册在CocosMethodManager中，注册方法和java中注册事件的方式相同。

```java
public class JsbBridge{
    public static sendToScript(String methodName, String arg);
}
```

用法和js调用机制对称，下面以改变字体的方法为例，我们在自定义组件中添加Label的属性，并且定义改变标签的方法sayHelloInJs，并且在Start函数中setCallback 并同样注册到eventMap中：

```js
@ccclass('CallNative')
export class CallNative extends Component {
    //static eventMap: Map<string, Function> = new Map<string, Function>();    
    @property(Label)
    public labelListener : Label|undefined;

    start () {
        new EventManager;
        jsb.reflection.setCallback((eventname: string, arg1: string)=>{
            console.log("Trigger event for "+eventname+"is"+EventManager.instance.applyMethod(eventname, arg1));
        })
        this.registerAllScriptEvent();
        this.dispatchJavaEventTest();
    }
    public dispatchJavaEventTest(){
        //Call with argument and success
        jsb.reflection.sendToNative("callWithArg", "@MYSaddHello");
    }
    public registerAllScriptEvent(){
        EventManager.instance.addMethod("sayHelloInJs", (usr : string)=>{
            this.sayHelloInJs(usr);
        });
    }

    //cb
    public sayHelloInJs(user: string):void {
        console.log("Hello "+ user +" I'm K");
        this.labelListener!.string = "Hello " + user + " ! I'm K";
        //debugger;
        
    }    
}

```

在Java的线程中，当我们需要调用js事件时，我们即可调用java的callJs方法。

```JAVA
CocosMethodManager.informScript("sayHelloInJs","Charlotte");
```

需要注意的是js的事件注册时机是由开发者自己控制的，同时解除注册的时机也是由开发者自己掌控的，通过deleteMethod方法就可以将方法从Map中移除。
