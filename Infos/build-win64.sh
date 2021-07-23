#!/bin/bash
set -x

# rm -rf build-win64

cmake -B build-win64 \
    -DLWS_WITH_LIBUV=ON \
    -DLWS_WITH_SSL=ON \
    -DLWS_WITHOUT_TESTAPPS=ON \
    -DLWS_WITHOUT_TEST_SERVER=ON \
    -DLWS_WITHOUT_TEST_PING=ON \
    -DLWS_WITHOUT_TEST_CLIENT=ON \
    -DLWS_OPENSSL_LIBRARIES="D:/Github/cocos2d-x-lite-external/win64/libs/libssl.lib;D:/Github/cocos2d-x-lite-external/win64/libs/libcrypto.lib" \
    -DLWS_OPENSSL_INCLUDE_DIRS="D:/Github/cocos2d-x-lite-external/win64/include" \
    -DLWS_LIBUV_LIBRARIES="D:/Github/cocos2d-x-lite-external/win64/libs/libuv.lib" \
    -DLWS_LIBUV_INCLUDE_DIRS="D:/Github/cocos2d-x-lite-external/win64/include/libuv" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DLWS_IPV6=ON \
    -DLWS_WITH_SHARED=OFF \
    -DLWS_WITH_STATIC=ON \
    -DDISABLE_WERROR=ON

