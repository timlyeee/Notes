# v8 android缺少signal报错

## Symbol:__INTRODUCED_IN

这是Android源代码中用来取代

```C++
#if __ANDROID_API__ >= X 
int sigemptyset(sigset_t* set)
#endif
```

 的一段宏，用法为:

```C++
int sigemptyset(sigset_t* set) __INTRODUCED_IN(X)
```

## 信号和信号函数signal

信号处理函数如下，是一个函数返回函数指针的函数，指向先前指定信号处理函数的函数指针。

```cxx
//Declaration of signal
#include <signal.h>
void ( *signal(int sig, void(*func)(int) ) )) (int);
```

准备捕获的信号的参数由sig给出，接收到的指定信号后要调用的函数由func参数给出，简单来讲就是，接受到sig后运行func。注意的是处理信号函数的原型必须为一下的一种

```cxx
void func（int）

SIG_IGN //默认信号

SIG_DFL //恢复信号的默认行为
```

具体用法如下

```cxx
void shout(int sig){
    std::cout<<"Signal is "<< sig << std::endl;
    //reset to default signal action
    (void) signal(SIGINT, SIG_DFL);
}

int main(){
    (void) signal(SIGINT, shout);
    while(1){
        printf("Hello\n");
        sleep(1);
    }

    return 0;
}
```

在main函数的一开始我们将SIGINT的默认行为改变为shout，这样无论什么类型的SIGINT都只会被改变为调用shout。好在我们会把它改回默认。

这样我们稍微运行这个函数并且使用Ctrl+c进行退出。

```shell
# Running cxx program
Hello
Hello
# exit
^c
Signal is 2
# shout is called and signal int function change back to default
Hello
Hello
# exit
^c
```

所以如果先掌握过eventDispatcher，可以发现信号与event很像，都属于响应方法。只不过响应的方式简单粗暴。

### sigaction

```c++
#include <signal.h>
int sigaction(int sig, const struct sigaction *act, struct sigaction *oact);
```

一个更加健壮的信号处理方式，由于API是向下兼容的，所以原本的没有被取消。

该函数与signal函数一样，用于设置与信号sig关联的动作（action）。oact则用来保存原来信号的动作的位置。act则是新动作。

```cxx
int main()
{
    struct sigaction act;
    act.sa_handler = shout;
     
    // init as empty
    sigemptyset(&act.sa_mask);
     
    // set to default action
    act.sa_flags = SA_RESETHAND;
 
    sigaction(SIGINT, &act, 0);
 
    while(1)
    {
        printf("Hello World!\n");
        sleep(1);
    }
 
    return 0;
}
```

### 信号集

sigset_t。信号集可以包含所有信号，也可以自行选择。如上述的SIGINT。

通过sigset可以设置多个信号响应同一个action。

### sigemptyset

将信号集初始化为空。

## V8 Sigemptyset用法

signal.h会指定android不同版本中的不同函数。所在地点为android_ndk/toolchain中。

## 对低版本android自定义signal工具

 