# 各种Plist的写法和在Cmake中的插入方法，写法

plist是在mac os上构建xcode项目时会有的一个项目写法，

info.plist

而entitlements.plist 则是针对xcode项目所引入的配置文件，用于设置类似沙盒一类的设置。

如果我们通过cmake生成项目，则需要在cmakelist.txt文件中声明我们所使用的xcode属性