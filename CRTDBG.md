# CRT DEBUG -- 替换原有的malloc和free用来检测内存泄漏

> [Find memory leaks with the CRT library](https://docs.microsoft.com/en-us/visualstudio/debugger/finding-memory-leaks-using-the-crt-library?view=vs-2022)

## 代码期准备

最好在运行的主入口添加，宏定义不局限位置，crtdbg在需要用到dump函数的区域进行运行。
```c++
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
```

CRTDBG是通过替换原有的malloc和free函数来检测是否每一个被创建出来的内存空间都有被释放。
在debug版本中，malloc被替换为malloc_dbg符号来记录内存创建时机和对象。

## 简单示例

假设我们现在有一个保存Stiker的容器并且内部的内容是由malloc来开辟的。
```c++
#pragma once
#include <vector>
#include "Striker.h"
class mVector {
public:
	mVector() {
		stdVector = std::vector<Striker*>();
	}
	void push(Striker t) {
		Striker* ptr = static_cast<Striker*>(malloc(sizeof(Striker)));
		memcpy(ptr, &t, sizeof(t));
		stdVector.push_back(ptr);
	}
	void erase(Striker t) {
		for (int i = 0; i < stdVector.size();i++) {
			if (stdVector[i]->name == t.name) {
				free(stdVector[i]);
				stdVector.erase(stdVector.begin()+i);
			}
		}
	}
private:
	std::vector<Striker*> stdVector;
};
```

在不运行vector.erase的情况下，通过_CrtDumpMemoryLeaks()函数来查看内存开辟和泄漏情况。
```c++
int main()
{
    mVector mvec;
	mvec.push(Striker("Jack", 18));
	mvec.push(Striker("Marin", 18));
	mvec.push(Striker("Kiki", 18));
	
	//-------dump memory once-----
	std::cout << "Memory leak test" << std::endl;
	_CrtDumpMemoryLeaks();
    ...
}

```

此时输出窗口会显示
```
Detected memory leaks!
Dumping objects ->
{187} normal block at 0x00B59C78, 12 bytes long.
 Data: < u   {  `w  > D0 75 B5 00 20 7B B5 00 60 77 B5 00 
E:\Cases\MallocDebug\mVector.h(10) : {186} normal block at 0x00B57760, 32 bytes long.
 Data: <    Kiki R w    > 00 97 B5 00 4B 69 6B 69 00 52 BF 77 00 00 00 00 
E:\Cases\MallocDebug\mVector.h(10) : {182} normal block at 0x00B57B20, 32 bytes long.
 Data: <    Marin       > E0 97 B5 00 4D 61 72 69 6E 00 CC CC CC CC CC CC 
E:\Cases\MallocDebug\mVector.h(10) : {178} normal block at 0x00B575D0, 32 bytes long.
 Data: <    Jack        > D8 99 B5 00 4A 61 63 6B 00 CC CC CC CC CC CC CC 
 {175} normal block at 0x00B59888, 8 bytes long.
 Data: <  o     > 04 F7 6F 00 00 00 00 00 
Object dump complete.
```

> 关于normal block：A normal block is ordinary memory allocated by your program

## Multiple exit -- 多个退出点的程序

如果程序不止一个程序退出点，则在每一个退出点都做一个crtDump并不现实。我们可以定义一个更泛用的方法。
```c++
_CrtSetDbgFlag ( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
```
这个设置将在程序退出时自动执行_CrtDumpMemoryLeaks 。但是在想要检测内存泄漏的点依然需要自己引用该函数。

## _CrtCheckMemory 确认在调试堆中分配的内存块的完整性（仅限调试版）。

> [_CrtCheckMemory](https://docs.microsoft.com/zh-cn/cpp/c-runtime-library/reference/crtcheckmemory?view=msvc-170)

_CrtCheckMemory 函数验证由调试堆管理器分配的内存，方法是验证基础基堆并检查每个内存块。 如果在基础基堆中遇到错误或内存不一致，则 _CrtCheckMemory 会生成一个调试报告，其中包含描述错误条件的信息。 未定义 _DEBUG 时，将在预处理过程中删除对 _CrtCheckMemory 的调用。

可以通过使用 _CrtSetDbgFlag函数设置 _crtDbgFlag标志的位域，来控制 _CrtCheckMemory 的行为。 将 _CRTDBG_CHECK_ALWAYS_DF 位域打开时，每次请求内存分配操作时都会调用 _CrtCheckMemory 。 尽管此方法减慢了执行速度，但它对快速捕获错误很有用。 关闭 _CRTDBG_ALLOC_MEM_DF 位域会导致 _CrtCheckMemory 不验证堆并立即返回 TRUE。

## 定位内存泄漏的具体地方

