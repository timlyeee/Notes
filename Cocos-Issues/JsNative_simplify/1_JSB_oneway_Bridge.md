# JSB Bridge

由于之前的jsJavaBridge的调用方式比较复杂，不太好复用，故提供一种更简便的使用方法。

## 命名及理由

!!!!!!

当前的单向通道其实仔细想来不符合任何设计模式，是一个原本jsb绑定机制和跨语言调用机制的简化！比如JS调用JAVA或者OC或者CXX事件，其实只是去**告知**(inform)该语言层处理或**使用**(apply)该被**添加**(add)的**功能**(method/function)。这需要具体到使用的位置和层级。比如在原生设备上的JAVA/OC层和CXX层其实是共存的，比如Windows端是以CXX语言开启的App。这需要去指明调用的是哪一层。至于request和receive并不切合这个语义，因为request是有回应的，而**告知**（inform）是不需要有回应的。

所以对应的接口名称就是

```js
//JavaScript
export function informApp(methodName: string, arg?: string|null): void;
public class MethodManager{
    private static methodMap: Map<String, Function>;
    public addMethod(methodName: String, f: Function): boolean;
    public deleteMethod(methodName: String): boolean;
}
```

```JAVA
//JAVA
public Interface IMethod{
    public void apply(String arg);
}

Class MethodManager
{
    public static void informScript(String methodName, String arg);
    public static Boolean addMethod(String eventName, IEvent ev);
    public static Boolean deleteMethod(String eventName);
    private static final HashMap<String, IMethod> methodMap = new HashMap<>();
}
```

## JS 调用 Java 事件

### API

js调用java的原型API只有一个。单向调用java事件

```js
/**
     * inform application to apply specific method/function
     * @param {string} methodName: event name on java/oc layer
     * @param {string} arg: argument as input to call java/oc event, suggest json format
     * @param {string} tag: external information, saving data while callback exist, and which callback to trigger 
     */
    export function informApp(methodName: string, arg?: string|null): void;
```

简单用法:

```js
jsb.informApp("OpenAd", "{URL:"www.xxx.com"}");
```

尽管js的调用各平台的事件接口是统一的，但是对应不同平台确实会有不同的事件注册方法。以JAVA为例，addMethod会将该方法添加到methodMap中并将方法名称作为索引来调用该方法：

```JAVA
//JAVA
public Interface IMethod{
    public void apply(String arg);
}

public class CocosMethodManager
{
    public static void informScript(String methodName, String arg);
    public static Boolean addMethod(String eventName, IEvent ev);
    public static Boolean deleteMethod(String eventName);
    private static final HashMap<String, IMethod> methodMap = new HashMap<>();
}
```

需要注意的是尽管callNative方法是单向通信，其不会关心下层的返回情况，也不会告知js代码操作成功或者失败。我们举一个打开广告的例子来说明这个接口是如何调用到下层的事件的。

### 简单的例子

我们先创建一个AdClass来保存我们需要的打开广告的操作。以往的JavaScriptJavaBridge只能调用Static函数，但是通过addMethod我们则可以把成员函数也暴露给脚本层。

```java
//JAVA code
public class AdClass{
    ...
    
    public IMethod openAdFunction= new IMethod(){
        public void apply(String s){...}
    };
}
```

上述代码中我们通过初始化一个IMethod作为我们的方法。当然，我们也可以直接通过 public void openAdFunction(String s){}的方式初始化，但是明确数据类型是一种比较好的习惯。

```JAVA
public class MyActivity{
    ...
    public init(){
        ...
        AdClass ad = new AdClass();
        Boolean ok = CocosMethodManager.addMethod("OpenAd",ad.openAdFunction);
    }
    ...
}
```

```javascript
jsb.informApp("OpenAd", "{url:"www.xxx.com"}");

```

我们在java层注册了java函数openAdFunction作为打开广告时的操作。并在js层试图触发该事件。
此时jsb会调用绑定的c++代码，从而向java层传递事件。java层会从eventMap中查找对应的事件，如果存在则触发，如果不存在也不会影响主线程的流程。但是这时候也许JAVA层会希望能够告知脚本层失败的信息，所以我们同样提供APP层到脚本层的调用方法，下面仍然以JAVA和JS举例

## JAVA 调用 JS 方法

保持接口的统一性，原始的Api接口同样是单向调用，命名规则相对一致。其定义在CocosMethodManager类中。同时需要被调用的JS的事件被注册在CocosMethodManager中，注册方法和java中注册事件的方式相同。

```java
public class CocosMethodManager{
    public static informScript(String methodName, String arg);
}
```

```js
public class MethodManager{
    ...
    private static methodMap: Map<String, Function>;
    public addMethod(methodName: String, f: Function): boolean;
    public deleteMethod(methodName: String): boolean;
    ...
}
```

用法和js调用机制对称，下面以改变字体的方法为例，我们在自定义组件中添加Label的属性，并且定义改变标签的方法changeLabel，并且在Start函数中将其添加到MethodManager的methodMap中：

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
        MethodManager.addMethod("changeLabel", this.changeLabel);
    }
}
```

在Java的线程中，当我们需要调用js事件时，我们即可调用java的callJs方法。

```JAVA
CocosMethodManager.informScript("changeLabel","Hello World");
```

需要注意的是js的事件注册时机是由开发者自己控制的，同时解除注册的时机也是由开发者自己掌控的，通过deleteMethod方法就可以将方法从Map中移除。
