# cocos第三方库适配注意事项

## 序

* 版本统一的方法
* 各第三方库的编译选项
  * tbb
  * v8
  * Physx
  * PvrFrame
  * Glslang
  * vcpkg
* 常见错误汇总
  
## 版本统一的方法

目前的版本统一记录在Version.txt中，但是库之间的依赖关系并不明确甚至可以说很模糊。以下是比较明显的依赖情况：

* libWebsocket编译需依赖Openssl和libuv，需要版本对齐
* v8依赖自带的zlib，需要包含到第三方库

如果要快速升级所有的库到最新版本，可以尝试使用vcpkg进行升级，它会将有依赖关系的库统一到相同版本。

## 各第三方库的编译选项

### tbb

当前所使用的tbb的git仓库为

> <https://github.com/wjakob/tbb>

该仓库是基于OneTBB创建的，但是编译出的包体要小上很多。

### v8

v8所用的版本记录在version.txt中，编译选项则是在gn args ${GN_MAKE_DIR}所生成的args.gn文件中。该文件记录了编译选项，默认使用Ninja编译器构建编译。针对各平台的编译配置记录在3d-task的issue中。

除了构建选项之外我们在不同的平台可以通过不同的编译器去生成对应项目进行编译。尽管它在编译器里面仍然用的是编译配置中选中的编译器，但这仍然方便了我们去定位问题，具体方法为启动编译的时候

### vcpkg编译时需注意

1. vcpkg下载编译的是默认为shared共享库，如果是静态库被下载的话应该用vcpkg install libuv:x64-windows-static的写法
2. 不同版本的vcpkg下载的包版本也不同，可以在vcpkg的changelog.md中找到

## 常见连接错误

1. vs编译时的librarian和linker会莫名其妙多出additional option导致编译的obj文件生成为x86版本，这是由于在template文件中没有设置目标平台导致的。
2. Link时连接的类型错误，出现：
   > error LNK2019: unresolved external symbol __imp_uv_loop_init referenced in function lws_uv_initloop

> <https://stackoverflow.com/questions/5159353/how-can-i-get-rid-of-the-imp-prefix-in-the-linker-in-vc>
原因是连接的类型不对，libwebsockets是链接到libuv的动态库而我们的libuv.lib是静态库

## tbb

安装的时候改名了。现在的版本是不改名的

## dbg三件套

从系统中导出，或者从windows kit中导出

## freetype2

直接使用官方打包好的static lib

## libuv编译 v1.41.0.1

1.13.1版本通过vs2017编译，编译动态库。
1.41.0.1的版本同样可以使用因为向下兼容性很好
bash : vcpkg install mpg123:x64-windows --x-install-root=E:/x64_Adapt/libuv
会自动编译动态库

## openssl，crypto编译 v1.1.1k 

通过vcpkg下载 1.1.1k版本

## libwebsocket 编译

当前老版本为2.4.2

1. vcpkg编译，其对应的tag只会保存对应的版本。
目前vcpkg0.0.112之前的分支是有2.4.2的，在这之后就没有了。
而2019年之前的分支已经被剪掉了。

2. 从目标库编译：
libwebsocket编译需要依赖 openssl & libuv

cmake -B build-x64 \
    -A x64\
    -DLWS_WITH_LIBUV=ON \
    -DLWS_WITH_SSL=ON \
    -DLWS_WITHOUT_TESTAPPS=ON \
    -DLWS_WITHOUT_TEST_SERVER=ON \
    -DLWS_WITHOUT_TEST_PING=ON \
    -DLWS_WITHOUT_TEST_CLIENT=ON \
    -DLWS_OPENSSL_LIBRARIES="E:\engine-native\external\win64\libs\libssl.lib;E:\engine-native\external\win64\libs\libcrypto.lib" \
    -DLWS_OPENSSL_INCLUDE_DIRS="E:\engine-native\external\win64\include" \
    -DLWS_LIBUV_LIBRARIES="E:\engine-native\external\win64\libs\libuv.lib" \
    -DLWS_LIBUV_INCLUDE_DIRS="E:\engine-native\external\win64\include\uv" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DLWS_IPV6=ON \
    -DLWS_WITH_SHARED=ON \
    -DLWS_WITH_STATIC=OFF \
    -DDISABLE_WERROR=ON

windows端的编译选项为shared，是共享库而不是static导入。

## glsl编译

通过source code编译

编译时注意cmake config: -DENABLE_OPT=OFF -DENABLE_SPVREMAPPER=OFF (否则会依赖另外两个库)
同时需要python3的环境

## 从win32项目编译到x64项目

## curl 

从source code编译

## libiconv 
vcpkg 编译

## vorbis & ogg
这两个库是一起编译的
vcpkg

## Win64构建时偶尔出现的崩溃情况

关于这个问题的出现频次很蹊跷，首先是我自己的机器上不会或者说只出现过一次。其次是如果我已经成功过一次，那么之后的几次构建都不会失败也不会崩溃。

目前存在几种可能性

1. 环境问题，da
2. 变量传输问题：
   1. bindState
      1. gpubuffer->glbuffer 0x00000299a13eae30
      2. offset= 1536
      3. glBinding 1
      4. CC.camera
      5. glBuffer 21
      6. 0x000001f161d72ae0

win32: 0x0bac0f80
gpuDescriptor.gpuBuffer->glBuffer 27
gpuDescriptor.gpuBuffer 0x0bac0f80
offset 768
gpuDescriptor.gpuBuffer->size 2304

x64: 0x000002076fcc3190
gpuDescriptor.gpuBuffer->glBuffer 21
gpuDescriptor.gpuBuffer->size 2304
offset 768

3. 编译器问题
这个是最骚的，也是目前试出来的结果，真相。
Platform toolset会影响编译的结果，或者说在我的电脑上的表现情况确实是这样的。如果我使用2017toolset加任意版本的sdk都会导致中途崩溃，但是2019则不会。

想来是其中某个库导致的报错，或者说是某个库编译的时候用到了2019toolset，导致在2017版本上运行失效。但究竟是谁呢？为什么会这样呢？

cmake -S"D:/lixinTmp/test-cases-3d/native/engine/win32" -B"D:/lixinTmp/test-cases-3d/build/windows/proj2" -G"Visual Studio 15 2017 Win64" -DRES_DIR="D:/lixinTmp/test-cases-3d/build/windows"




## Physx 
用的是4.1.2版本，其实应该是4.1.1版本保持一致的，但是没什么报错所以就这样了。
需要注意的是Physx的运行库需要和应用的运行库保持一致即Mtd或者Md，这一点可以通过physx/buildtools/presets/public/ 中的对应xml文件进行设置。

```xml
 <cmakeSwitch name="NV_USE_STATIC_WINCRT" value="False" comment="Use the statically linked windows CRT" />
    <cmakeSwitch name="NV_USE_DEBUG_WINCRT" value="True" comment="Use the debug version of the CRT" />
```

此外，为了跑通sampleRenderer我还安装了dx9-11

cmake -S"E:/Cases/NewProject/native/engine/win32" -B"E:/Cases/NewProject/build/windows/proj" -G"Visual Studio 16 2019" -A"x64" -DRES_DIR="E:/Cases/NewProject/build/windows"

cmake -S"E:/Cases/test-cases-3d/native/engine/win32" -B"E:/Cases/test-cases-3d/build/windows/proj-x86" -G"Visual Studio 16 2019" -A"win32" -DRES_DIR="E:/Cases/test-cases-3d/build/windows"

E:\Cases\NewProject\native\engine\win64


## v8 
编译9.1.269版本需要安装10.0.19的windows sdk否则会报错。这会是导致崩溃的原因吗
同时需要设置vs2017_install或者vs2019_install变量为ide所在路径，以及 DEPOT_TOOLS_WIN_TOOLCHAIN 设置为0表示使用自身所带vs

同时打开windows kit 10.0.19的安装程序把debuggers给装上。。

cmake -S"D:/lixinTmp/test-cases-3d/native/engine/win64" -B"D:/lixinTmp/test-cases-3d/build/windows/proj64" -G"Visual Studio 15 2017 Win64" -DRES_DIR="D:/lixinTmp/test-cases-3d/build/windows"

cmake -S"E:/test-cases-3d/native/engine/win64" -B"E:/test-cases-3d/build/windows/proj-x86" -G"Visual Studio 15 2017" -DRES_DIR="E:/test-cases-3d/build/windows"

websocket 2.4.2 win32
x64 4.1.6 没有lws_uv_initloop方法

cmake -S"D:/lixinTmp/test-cases-3d/native/engine/win32" -B"D:/lixinTmp/test-cases-3d/build/windows/proj2" -G"Visual Studio 15 2017 Win64" -DRES_DIR="D:/lixinTmp/test-cases-3d/build/windows"

10.0.10586
cmake -S"E:/Cases/test-cases-3d/native/engine/win32" -B"E:/Cases/test-cases-3d/build/windows/proj-x64" -G"Visual Studio 15 2017 Win64" -DRES_DIR="E:/Cases/test-cases-3d/build/windows"