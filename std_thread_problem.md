# 最终目标：限制同一时间内存分配

由于某些分配策略的原因，有些对象的内存会被分配的很大而释放的很晚，导致同一时间堆内存太大。所以需要一个新的策略让释放作为分配的契机。但由于基础的薄弱和忘光光的知识，我需要这么一个文档来帮助我对比不同的策略的效果和实现方法。

## Thread 线程

在我原先的个人理解中，线程是可以独立运行while循环且不打扰主线程运行的。但我明显理解错了。能够不打扰主线程运行的只有另一个主线程，就是另一个进程。只要涉及到数据的交互传输，C++就永远不可能允许一个线程运行while循环且不退出。

线程的创建需要一个 `std::function`,后面可以接若干参数作为传入的 `std::function` 的参数。
```c++
void worker_thread(const std::string& data){
    std::cout<<"worker_thread's data is "<<data<<std::endl;
}
int main(){
    std::thread worker(worker_thread, "Hello world");//"Hello world" as input value for work thread
    std::cout<<"main thread is running\n";
    worker.join();//this function is needed because main thread perhaps runs out first, which will assert error
    return 0;
}
```
这个例子的问题在于主线程会比worker线程早运行完成，所以程序结束之前需要等待。

假设在 `worker_thread` 中加入 `while` 循环，那么主线程会不会等待 `worker` 线程呢？实际上不会，因为在这里并没有赋予锁的操作，所以不会出现线程堵塞。

## mutex 锁

将线程加入锁之后，可以控制变量更改，防止多线程中对同一个变量反复更改。

```c++
#include <string>
#include <iostream>
#include <thread>
#include <mutex>

std::mutex m;
int i = 0;
void worker_thread(const std::string& data) {
    m.lock();
    i++;
    std::cout << "worker_thread's data is " << data << std::endl;
    m.unlock();
}
int main() {
    std::thread worker(worker_thread, "Hello world");//"Hello world" as input value for work thread
    m.lock();
    i++;
    std::cout << "main thread is running\n";
    m.unlock();
    worker.join();
    return 0;
}
```

但是在这个例子中效果并不明显。所以我们再引入一个线程。

```c++
std::mutex m;
int i = 0;
void worker_thread(const std::string& data) {
    //std::this_thread::sleep_for(std::chrono::seconds(1));
    m.lock();
    i++;
    std::cout << "worker_thread's data is " << data << std::endl;
    m.unlock();
}

void editor_thread(){
    m.lock();
    i++;
    std::cout<<"editor_thread's running with i : "<<i<<std::endl;
    m.unlock();
}
int main() {
    std::thread worker(worker_thread, "Hello world");//"Hello world" as input value for work thread
    std::thread editor(editor_thread);
    std::cout << "main thread is running\n";

    worker.join();
    editor.join();
    return 0;
}
```

这样在两个线程中就会出现抢锁的操作，并且有一个线程会在没有抢到锁的时候被阻塞。

如果想不被阻塞，则可以使用 `trylock` 来尝试加锁，该函数会有一个bool的返回值，可以针对该返回值进行其他操作。

## unique lock 单一锁

单一锁的价值在于，它生效于特定作用域，或者是函数作用域，这对于线程来说价值比较大。

在这之前可以先了解 `lock_guard`，在单一作用域中的锁，不需要执行 `unlock` 命令，就会在作用域结束时自动释放。且不可被复制。

比较奇特的是其注册方式，因为是 std 容器，所以需要用模板的方式声明。这也意味着除了单一的 `mutex` 还可以接受其他的子类锁。

```c++
int g_i = 0;
std::mutex g_i_mutex;
void safe_increment()
{
    const std::lock_guard<std::mutex> lock(g_i_mutex);
    ++g_i;
 
    std::cout << "g_i: " << g_i << "; in thread #"
              << std::this_thread::get_id() << '\n';
 
    // g_i_mutex is automatically released when lock
    // goes out of scope
}
int main(){
    ...
    std::thread t1(safe_increment);
    ...
    t1.join();
}
```

`lock_guard` 还可以传入第二个参数来表示锁类型，即 `std::adopt_lock` 假定已经上锁。是该结构的实例：
```c++
constexpr std::adopt_lock_t adopt_lock {};
```

`adopt_lock` 假定构造的时候线程中已经获得了锁。其构造函数和默认构造函数的主要区别就是少了 `lock` 的操作。所以如果不手动进行上锁的话该线程可能会引起未定义行为：对同一个对象同时进行操作。所以关键就在于**手动上锁**。
```c++
{
    std::lock(mlock);
    const std::lock_guard<std::mutex> mlock(g_i_mutex, std::adopt_lock);
    
    ++g_i;
 
    std::cout << "g_i: " << g_i << "; in thread #"
              << std::this_thread::get_id() << '\n';
 
    // g_i_mutex is automatically released when lock
    // goes out of scope
}
```
`lock_guard` 添加了对于锁的延迟管理和多个锁的共同管理。

而 `unique_lock` 则算是 `lock_guard` 的升级版。其使用方法跟其差不多但是多了三个可用参数， `std::defer_lock`, `std::try_to_lock`, `std::adopt_lock`。

`defer_lock` 其实就是表示调用构造函数的时候可以不获取锁的权限，但是当真正需要对资源进行访问的时候再获取上锁。
```c++
{
    const std::unique_lock<std::mutex> mlock(g_i_mutex, std::defer_lock);
    std::lock(mlock);
    //equivalent approach
    /*
    std::lock(mlock);
    const std::lock_guard<std::mutex> mlock(g_i_mutex, std::adopt_lock);
    */
    ++g_i;
 
    std::cout << "g_i: " << g_i << "; in thread #"
              << std::this_thread::get_id() << '\n';
 
    // g_i_mutex is automatically released when lock
    // goes out of scope
}
```

`try_to_lock` 的实现实际上只是在构造时进行了 `try_lock()` 并将Own变量设置为返回值。并不会阻塞线程运行。所以也没有了互斥操作。只是在实际需要锁的时候仍需要执行 `std::lock`，或者先进行if判断，如果已经获取到锁则执行 A 操作，没有则执行 B 操作。
```c++
{
    const std::unique_lock<std::mutex> mlock(g_i_mutex, std::try_to_lock);
    if(!mlock.owns_lock()){
        std::lock(mlock);
    }
    ++g_i;
 
    std::cout << "g_i: " << g_i << "; in thread #"
              << std::this_thread::get_id() << '\n';
 
    // g_i_mutex is automatically released when lock
    // goes out of scope
}
```

如果定义两个 `unique_lock` 来对数字进行加减操作，我们就可以把 `g_i_mutex` 看作读写锁，进行互斥操作。

```c++
#include <string>
#include <iostream>
#include <thread>
#include <mutex>

struct Box {
    explicit Box(int num) : num_things{ num } {}

    int num_things;
    std::mutex m;
};
void transfer(Box& from, Box& to, int num)
{
    // don't actually take the locks yet
    std::unique_lock<std::mutex> lock1(from.m, std::defer_lock);
    std::unique_lock<std::mutex> lock2(to.m, std::defer_lock);
    // lock both unique_locks without deadlock
    std::lock(lock1, lock2);
    from.num_things -= num;
    to.num_things += num;
    std::cout << "transfer number is " << from.num_things << " and " << to.num_things << std::endl;

    // 'from.m' and 'to.m' mutexes unlocked in 'unique_lock' dtors
}

int main()
{
    Box acc1(100);
    Box acc2(50);

    std::thread t1(transfer, std::ref(acc1), std::ref(acc2), 10);
    std::thread t2(transfer, std::ref(acc2), std::ref(acc1), 5);

    t1.join();
    t2.join();
}
```

```txt
output:
transfer number is 45 and 105
transfer number is 95 and 55
```



## contidion variable 条件变量

cv 是一个同步原语，或者说是同步特征来阻塞一个线程，或者同一个事件阻塞多个线程，这能防止多个线程同时进行上锁操作从而导致死锁或者异常。

使用条件变量的线程需要首先获取锁，通常使用 `lock_guard` 或者 `unique_lock`，都是 std 容器。获取到锁之后进行线程中的函数操作，继而通过 cv 执行 `notify_one` 或者 `notify_all`。即便共享线程拥有原子性，也需要逐步执行。

而需要等待的线程通常使用 `wait`，`wait_for`，`wait_until` 来释放锁和挂起线程。并且只能和 `unique_lock` 配合使用。

在只有 `main_thread` 和 `worker_thread` 时，可以按照以下情形运行。

```c++
std::mutex m;
std::condition_variable cv;
std::string data;
bool ready = false;
bool processed = false;
 
void worker_thread()
{
    // Wait until main() sends data
    std::unique_lock<std::mutex> lk(m);
    cv.wait(lk, []{return ready;});
 
    // after the wait, we own the lock.
    std::cout << "Worker thread is processing data\n";
    data += " after processing";
 
    // Send data back to main()
    processed = true;
    std::cout << "Worker thread signals data processing completed\n";
 
    // Manual unlocking is done before notifying, to avoid waking up
    // the waiting thread only to block again (see notify_one for details)
    lk.unlock();
    cv.notify_one();
}
 
int main()
{
    std::thread worker(worker_thread);
 
    data = "Example data";
    // send data to the worker thread
    {
        std::lock_guard<std::mutex> lk(m);
        ready = true;
        std::cout << "main() signals data ready for processing\n";
    }
    cv.notify_one();
 
    // wait for the worker
    {
        std::unique_lock<std::mutex> lk(m);
        cv.wait(lk, []{return processed;});
    }
    std::cout << "Back in main(), data = " << data << '\n';
 
    worker.join();
}
```





