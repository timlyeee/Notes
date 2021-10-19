# 新版本InstantApp构建指南

## Cocos Creator构建InstantApp流程

2.4.6 (更新gradle之前)

    |---> 录制，分包资源
        |----> 构建InstantApp
            |----> 打包为zip文件
                |----> 包体大小为15mb以下。资源为远程资源

2.4.7 (更新gradle之后)

    |----> 录制，分包资源
        |----> 构建InstantApp，并选择deploy as instant app (该选项储存在 $PROJ_DIR/.idea/runConfiguration的配置xml文件中)
            |----> 打包为apk文件
                |----> 包体大小50mb+，资源仍然不能分开

3.x （更新gradle之后）

    |----> 设置remote分包
        |----> 构建AndroidApp（InstantApp亦包括）
            |----> 移除remote文件夹，打包为apk
                |----> 包体大小与remote大小有关

## InstantApp的构建方式

### 老版本的InstantApp构建方式

老版本的InstantApp主要依赖build.gradle的编译脚本实现，需要定义instantApp模块和base模块。并且gms.instantapp模块的依赖并不需要依赖任何内容。

