# JSB Bridge

由于之前的jsJavaBridge的调用方式比较复杂，不太好复用，故提供一种更简便的使用方法。

## JS 调用 Java 事件

### API

js调用java的原型API只有一个。单向调用java事件

```js
/**
     * dispatch custom event with less reflection, not responsible for success or not
     * @param {string} eventName: event name on java/oc layer
     * @param {string} arg: argument as input to call java/oc event, suggest json format
     * @param {string} tag: external information, saving data while callback exist, and which callback to trigger 
     */
    export function callNative(eventName: string, arg?: string|null): void;
```

简单用法:

```js
jsb.callNative("OpenAd", "{URL:"www.xxx.com"}");
```

尽管js的调用各平台的事件接口是统一的，但是对应不同平台确实会有不同的事件注册方法。以JAVA为例，registerEvent会将该事件注册到eventMap中并将事件名称作为索引来调用该事件：

```java
public Interface IEvent{
    public void run(String arg);
}

Class CocosNativeBridge
{
    private static final HashMap<String, IEvent> eventMap = new HashMap<>();
    ...
    public static Boolean registerEvent(String eventName, IEvent ev);
    public static Boolean deleteEvent(String eventName);
    ...
}
```

则注册时必须以同样的方法签名注册。即保证输入和返回值都为String。需要注意的是尽管callNative方法是单向通信，其不会关心下层的返回情况，也不会告知js代码操作成功或者失败。我们举一个打开广告的例子来说明这个接口是如何调用到下层的事件的。

### 简单的例子

```java
//JAVA code
void openAdFunction(String content){...}
Boolean ok = CocosEventManager.registerEvent("OpenAd", openAdFunction);
```

```javascript
jsb.callNative("OpenAd", "{url:"www.xxx.com"}");

```

我们在java层注册了java函数openAdFunction作为打开广告时的操作。并在js层试图触发该事件。
此时jsb会调用绑定的c++代码，从而向java层传递事件。java层会从eventMap中查找对应的事件，如果存在则触发，如果不存在也不会影响主线程的流程。

## JAVA 调用 JS 事件

保持接口的统一性，原始的Api接口同样是单向调用，命名规则相对一致。其定义在CocosJsBridge类中。同时需要被调用的JS的事件被注册在CocosJsBridge中，注册方法和java中注册事件的方式相同。

```java
public class CocosNativeBridge{
    ...
    public static callJs(String eventName, String arg);
}
```

```js
public class CocosJsBridge{
    ...
    private static eventMap: Map<String, Function>;
    public registerEvent(eventName: String, f: Function): boolean;
    public deleteEvent(eventName: String): boolean;
    ...
}
```

用法和js调用机制对称，下面以改变字体事件为例，我们在自定义组件中添加Label的属性，并且定义改变标签的事件changeLabel，并且在Start函数中将其注册到CocosJsBridge的eventMap中：

```js
@ccclass('ExComponent')
export class ExComponent extends Component {
    @property(Label)
    public labelListener : Label|undefined;
    ...
    public changeLabel(label: String): Void{
        this.labelListener!.string = "label";
    }
    ...
    start(){
        CocosJsBridge.registerEvent("changeLabel", this.changeLabel);
    }
}
```

在Java的线程中，当我们需要调用js事件时，我们即可调用java的callJs方法。

```JAVA
CocosNativeBridge.callJs("changeLabel","Hello World");
```

需要注意的是js的事件注册时机是由开发者自己控制的，同时解除注册的时机也是由开发者自己掌控的，通过deleteEvent方法就可以将Event的索引从Map中移除。当然，如果不自己处理java或js的生命周期的话，在游戏结束时会自动处理所有函数的引用。
