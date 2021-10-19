# GameActivity 升级记录

## GameActivity

以下简称GA，是大部分在cpp层实现的Activity，替代原本的AppActivity。推荐使用cmakeList添加依赖项

```bash
find_package(game-activity REQUIRED CONFIG)
target_link_libraries(game
    android
    game-activity::game-activity
)
```

但是要注意的是，此处gameActivity其实是原生依赖项，根据文档所示，需要添加

```gradle
buildFeatures {
    prefab true
}
```

> https://developer.android.com/studio/build/native-dependencies?hl=zh-cn

