# Task, Activity, Affinity

理论上`Task`包含了多个`Activity`，并为`Activity`的跳转提供了很好的保障。

但这也只是理论上。

安卓系统需要满足的功能很多，比如通过`url`打开应用，或者在应用内打开广告等。这些都与`Task`的功能有联系。在接入广告SDK的时候，实际上有些广告就是新建了一个`Activity`然后跳转。

对于Android
- 一个Task就好像它的名字一样，是一个任务，Android上把一个任务抽象成一系列的UI(Activity)去完成，比如默认情况下一个App就是一个task，一个task把UI逻辑聚合起来，一个task中的Activity在逻辑上应该是完成同一个方法的
- 在最简单的情况下，Android设备上的每一个App都至少对应一个Task，所以分前台Task和后台Task
- 每一个Task都是一个栈的结构

## Task Affinity 任务名词/任务名

对于每一个Activity其实都有`TaskAffinity`属性存在，但是是默认值也就是原本的包名。
```xml
<activity
    android:name=".EntryActivity"
    android:exported="true"
    android:taskAffinity="?">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```
如果在这时候给定一个`taskAffinity`的话，那么相当于给定了一个包名以外的任务。

我们考虑这样一个使用场景：游戏的Activity实际上在应用内部的，但不是小程序而是同一个程序，那么它就不应该给定taskAffinity，给定为空的taskAffinity实际上是为了解决另一个可能的情况，或者是打开小程序的使用场景。

```java
public class MainActivity extends Activity{
    ...
    public void onCreate(Bundle b){
        ...
        if(!isTaskRoot()){
            return;
        }
    }
}
```
这段代码是一种防止应用被别的task打开后又自己打开的情况，这会使得出现两个存在于不同task中的activity，会让使用者混乱。

但如果保留这段代码又给一段taskAffinity的话，就不能从应用内部