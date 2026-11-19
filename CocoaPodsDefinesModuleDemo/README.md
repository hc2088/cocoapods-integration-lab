# CocoaPods podspec 定义模块实验

本工程复制自 [CocoaPodsFrameworkPackagingDemo](../CocoaPodsFrameworkPackagingDemo/README.md)。重点验证一个 Objective-C 源码 Pod 如何通过 podspec 定义 Clang 模块，同时以静态 `.a` 交给 App 链接。

## 实验配置

[Podfile](Podfile) 的 `NoFrameworkDemo` target 使用默认静态库集成，并显式关闭 Podfile 侧的模块化头文件选项。

```ruby
target 'NoFrameworkDemo' do
  pod 'MixedBinaryPod', :path => './MixedBinaryPod', :modular_headers => false
end
```

[MixedBinaryPod.podspec](MixedBinaryPod/MixedBinaryPod.podspec) 给 Pod target 设置 `DEFINES_MODULE = YES`。同一配置块中的链接参数供动态 framework 版本解析 `DynamicVendor` 符号。

```ruby
s.pod_target_xcconfig = {
  'DEFINES_MODULE' => 'YES',
  'OTHER_LDFLAGS' => '-framework DynamicVendor'
}
```

[App/main.m](App/main.m) 使用 `@import MixedBinaryPod;`，然后调用 `MixedBinaryPodReport()`。

## 运行和查看结果

在本目录运行以下命令，然后选择 `NoFrameworkDemo` scheme 和 iOS 模拟器按 ⌘R。

```bash
./verify.sh
open DefinesModuleDemo.xcworkspace
```

验证环境为 Xcode 26.6、CocoaPods 1.16.2、arm64 iOS 模拟器。脚本会生成三方库、安装 Pods、构建四个 scheme，并打印以下证据。

1. Pod target 的 `.xcconfig` 包含 `DEFINES_MODULE = YES`。
2. CocoaPods 生成 `MixedBinaryPod-Pods-NoFrameworkDemo.modulemap` 和对应的 umbrella header。App 的 `OTHER_CFLAGS` 通过 `-fmodule-map-file` 把 module map 传给 Clang，`@import` 编译通过。
3. `file` 显示 `libMixedBinaryPod-Pods-NoFrameworkDemo.a` 是 `ar` 静态归档，`nm -m` 在 App 主可执行文件中找到 `MixedBinaryPodReport` 的定义。三方动态库仍通过 CocoaPods 嵌入 App。

生成的 [module map](Pods/Headers/Public/MixedBinaryPod/MixedBinaryPod-Pods-NoFrameworkDemo.modulemap) 位于 `Pods/Headers/Public/MixedBinaryPod/`，由当前 target 的 umbrella header 汇总公开 API。Pod 的静态库位于 `.build/library/DerivedData/Build/Products/Debug-iphonesimulator/MixedBinaryPod-Pods-NoFrameworkDemo/`。

## 和原 Demo 对照

| 工程与 scheme | 模块的配置来源 | 源码 Pod 产物与导入方式 |
| --- | --- | --- |
| 原工程的 `NoFrameworkDemo` | 默认头文件集成 | `.a`，`#import` |
| 原工程的 `ModularHeadersDemo` | Podfile 的 `:modular_headers => true` | `.a`，`@import` |
| 本工程的 `NoFrameworkDemo` | podspec 的 `DEFINES_MODULE = YES`，Podfile 设置 `:modular_headers => false` | `.a`，`@import` |

本工程的 `ModularHeadersDemo`、`StaticFrameworkDemo` 和 `DynamicFrameworkDemo` 也使用同一份 podspec。四个 App 使用独立于原工程的 bundle ID，可以在同一台模拟器安装两组 Demo。

四种自动生成 module map 的配置及自定义 module map 的区别，见 [总 README 的配置对照](../CocoaPodsFrameworkPackagingDemo/README.md#开启-module-map-的四种配置)。
