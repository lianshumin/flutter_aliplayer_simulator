# 验证记录

日期：2026-11-10（Asia/Shanghai）。

环境：Flutter 3.44.8 / Dart 3.12.2，Xcode 27.2；iPhone Duo 专用 iOS 27.2 arm64 模拟器。上层组件使用官方 aliplayer_widget 7.18.0；example/pubspec.lock 固定此次使用的依赖版本。

结果：

- 新增示例及集成测试的 Flutter analyze 通过。
- Ruby podspec 语法检查通过；解析后的 podspec 只依赖 Flutter。
- 实际 iPhone Duo 上 3 组集成测试通过：原生查询的 Dart 类型、设置回读、多实例隔离、释放重建、无播放事件；全局初始化、两代预加载器和缓存清理；原版上层组件创建 UiKitView、播放/暂停调用、三轮挂载与退出。
- lib/、android/、ios/Classes/ 及 LICENSE 与官方发布包保持一致；iOS 原版 Classes 留作来源参考，不参与 Mock 编译。

限制：

- 验证对象是独立示例，尚未切换或运行 JoyRead/JoyDrama 完整 App。
- 没有真实视频、首帧、播放时长或完播事件；依赖这些事件的业务交互不能据此验收。
- 不宣称 Android 或真机播放已回归验证；iOS Mock 有真机编译阻断保护。
- Flutter 当前通过 CocoaPods 接入该插件，会提示未来需要支持 Swift Package Manager。此次模拟器编译和测试不受影响。
