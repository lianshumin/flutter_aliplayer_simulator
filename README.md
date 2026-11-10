# flutter_aliplayer iOS Simulator Mock

基于官方发布包 **flutter_aliplayer 7.18.0**，供 JoyRead、JoyDrama 在 arm64 iOS 模拟器（最低 iOS 15.0）上调试 Flutter 界面。包名和 Dart API 保持 `flutter_aliplayer`，上层 `aliplayer_widget` 不需要 Fork。

## 分支与来源

- `main`、标签 `upstream-7.18.0`：未修改的官方发布包源码。
- `simulator-mock`：iOS 模拟器 Mock，CocoaPods 只编译 `ios/MockClasses`。
- 原版说明保存在 [README.upstream.md](README.upstream.md)，原有 LICENSE 和版权声明保留。
- **不能把只配置了仓库 URL、未配置 ref 的 Git 依赖当作 Mock 使用。默认 main 仍是原版。**

## 能做什么

iOS 构建不再引入 AliPlayerSDK_iOS、AliPlayerSDK_iOS_ARTC、RtsSDK 和 MJExtension，也不再限制为 x86_64。插件注册、空白原生视频视图、播放器常用查询、设置、释放、全局初始化、缓存清理及两代预加载通道可正常调用。

准备时只发出固定 1080×1920 占位尺寸通知，让上层组件创建布局。不会解码或下载视频，没有声音，也不会发出准备成功、首帧、播放进度、完播或下载成功事件。上层依赖这些事件显示的播放控件可能继续隐藏或显示加载占位；该版本用于首页、列表和静态布局调试，不验证完整播放交互。视图本身透明，业务封面按原有逻辑保留。

iOS 真机构建会在编译时明确失败，要求移除覆盖，防止误把空播放器用于真机。Android 文件未修改，仍是原版播放器实现。

## 两个 App 的接入方式

在 App 入口 `pubspec.yaml` 旁创建临时 `pubspec_overrides.yaml`：

- JoyDrama：项目根目录。
- JoyRead：`flavors/whale/`。

```yaml
dependency_overrides:
  flutter_aliplayer:
    git:
      url: https://github.com/lianshumin/flutter_aliplayer_simulator.git
      ref: simulator-mock
```

首次验证可以使用分支名；团队使用时将 ref 改成验证通过的完整提交 SHA，防止远程分支更新改变调试环境。

**保留现有 dependency_overrides。** 如果 App 已有其他覆盖（例如 JoyDrama 的 google_mobile_ads），请在同一个覆盖文件中保留它们；[pubspec_overrides.yaml](https://dart.dev/tools/pub/dependencies#pubspec-overridesyaml) 中的同名顶层字段会覆盖 pubspec.yaml 的字段，不能仅复制上面的最小示例而丢掉其他覆盖。

在 App 入口目录执行：

```sh
fvm flutter pub get
(cd ios && pod install)
fvm flutter run -d <模拟器 ID>
```

若缓存仍引用旧 SDK，先 `fvm flutter clean`，再重复以上步骤。不要手改 GeneratedPluginRegistrant、.flutter-plugins-dependencies 或 .pub-cache。

恢复真机/正式构建：移除 flutter_aliplayer 的临时覆盖，保留其他已有覆盖，重新运行 pub get 和 pod install。覆盖启用期间 pubspec.lock、Podfile.lock 和生成文件会变化；不要把临时路径或 Mock 依赖误提交到 App 的正常构建配置。

## 独立验证

`example/` 直接使用原版 aliplayer_widget 7.18.0 和此插件，不 Mock Dart MethodChannel。集成测试通过真实的 iOS 原生实现检查：

- 查询返回类型、设置回读、多播放器隔离、释放后重新创建；
- 全局设置、两代预加载器、缓存清理；
- 原版 AliPlayerWidget 创建原生视图，播放/暂停，以及反复挂载和退出。

```sh
cd example
flutter pub get
flutter analyze --no-pub lib integration_test
flutter test integration_test/simulator_mock_test.dart -d <iOS 模拟器 ID>
```

`test/flutter_aliplayer_test.dart` 是原版发布包附带的空模板测试，不作为本 Mock 的验证证据。
