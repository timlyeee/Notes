# cocos第三方库适配注意事项

## 序

* 版本统一的方法
* 各第三方库的编译选项
  * tbb
  * libwebsocket
  * v8
  * Physx
  * Glslang
  * vcpkg
* 常见错误汇总
  
## 版本统一的方法

目前的版本统一记录在Version.txt中，但是库之间的依赖关系并不明确甚至可以说很模糊。以下是比较明显的依赖情况：

* libWebsocket编译需依赖Openssl和libuv，需要版本对齐
* v8依赖自带的zlib，需要包含到第三方库
* Glslang, Physx库共享头文件需要使用·

如果要快速升级所有的库到最新版本，可以尝试使用vcpkg进行升级，它会将有依赖关系的库统一到相同版本。

## 各第三方库的编译选项

### tbb

当前所使用的tbb的git仓库为

> <https://github.com/wjakob/tbb>

该仓库是基于OneTBB创建的，但是编译出的包体要小上很多。

### libwebsocket

当前老版本为2.4.2，需要从GitHub仓库拉取编译：依赖 openssl & libuv，编译选项如下

```bash
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
    -DLWS_IPV6=OFF \
    -DLWS_WITH_SHARED=ON \
    -DLWS_WITH_STATIC=OFF \
    -DDISABLE_WERROR=ON
```

windows端的编译选项为shared，是共享库而不是static导入。

### v8

v8所用的版本记录在version.txt中，编译选项则是在gn args ${GN_MAKE_DIR}所生成的args.gn文件中。该文件记录了编译选项，默认使用Ninja编译器构建编译。针对各平台的编译配置记录在3d-task的issue中。

除了构建选项之外我们在不同的平台可以通过不同的编译器去生成对应项目进行编译。尽管它在编译器里面仍然用的是编译配置中选中的编译器，但这仍然方便了我们去定位问题，具体方法为启动编译的时候

### Physx

用的是4.1.1版本，需要注意的是Physx的运行库需要和应用的运行库保持一致即Mtd或者Md，这一点可以通过physx/buildtools/presets/public/ 中的对应xml文件进行设置。

```xml
 <cmakeSwitch name="NV_USE_STATIC_WINCRT" value="False" comment="Use the statically linked windows CRT" />
    <cmakeSwitch name="NV_USE_DEBUG_WINCRT" value="True" comment="Use the debug version of the CRT" />
```

需要设置DEBUG为True和false各编译一次，提供debug版本和release版本的Physx库。

### Glslang

基于云潇fork的glslang库编译。

> <https://github.com/YunHsiao/glslang>

其中有编译脚本，但基本选项如下。

基本编译选项为:

```bash
cmake -DENABLE_HLSL=OFF \
    -DENABLE_SPVREMAPPER=OFF \
    -DSKIP_GLSLANG_INSTALL=ON \
    -DSPIRV_SKIP_EXECUTABLES=ON
```

### vcpkg编译时需注意

1. vcpkg下载编译的是默认为shared共享库，如果是静态库被下载的话应该用vcpkg install libuv:x64-windows-static的写法

### mpg123

音频库`mpg123`是纯`C`语言写的库，而其编译于windows上则需要配置一部分的环境，这一部分mingw可以协助完成。

1. 下载 `msys2`，其中需要勾选mingw64的工具用来编译64位所需的动态库。并且安装路径中不要出现空格。
2. 使用 `msys2-win64` 运行 `windows-builds.sh`，跟随配置 x86_64 8。
3. 编译后的文件根据mog

## 常见错误

1. vs编译时的librarian和linker会莫名其妙多出additional option导致编译的obj文件生成为x86版本，这是由于在template文件中没有设置目标平台导致的。
2. Link时连接的类型错误，出现：
   > error LNK2019: unresolved external symbol __imp_uv_loop_init referenced in function lws_uv_initloop

> <https://stackoverflow.com/questions/5159353/how-can-i-get-rid-of-the-imp-prefix-in-the-linker-in-vc>
原因是连接的类型不对，libwebsockets是链接到libuv的动态库而我们的libuv.lib是静态库。

3. 运行时错误：需要更新external仓库中的source/khronos API，因为会有些兼容性问题。
