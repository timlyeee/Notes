platform=$1  
echo "Downloading external libraries for certain platform $platform"
mkdir vcpkg-externals-$platform
cd vcpkg
./vcpkg install openssl:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-ssl-141
./vcpkg install libvorbis:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-vorbis-141
./vcpkg install curl:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-curl-141
./vcpkg install ijg-libjpeg:$platform-windows-static --x-install-root=../vcpkg-externals-$platform/vc-ijg-libjpeg-141
./vcpkg install mpg123:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-mpg123-141
./vcpkg install libpng:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-libpng-141
./vcpkg install libwebp:$platform-windows-static --x-install-root=../vcpkg-externals-$platform/vc-libwebp-141
./vcpkg install zlib:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-libzlib-141
./vcpkg install libuv:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-libuv-141
./vcpkg install openal-soft:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-openal-141
./vcpkg install sqlite3:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-sqlite3-141
./vcpkg install SDL2:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-sdl2-141
./vcpkg install libiconv:$platform-windows --x-install-root=../vcpkg-externals-$platform/vc-libiconv-141
./vcpkg install tbb:$platform-windows-static --x-install-root=../vcpkg-externals-$platform/vc-tbb-141
