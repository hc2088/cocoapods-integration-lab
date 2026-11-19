# CocoaPods集成与混编总结

# CocoaPods 集成、模块化与 Swift / Objective-C 混编

## 1. Pod 源码怎么打包

| Podfile 配置 | 源码 Pod 产物 |
| --- | --- |
| 不开启 `use_frameworks!` | 静态 `libXX.a` |
| `use_frameworks! :linkage => :static` | 静态 `XX.framework`，内部是静态归档 |
| `use_frameworks! :linkage => :dynamic`，或直接写 `use_frameworks!` | 动态 `XX.framework`，内部是 Mach-O 动态库 |

- **Podfile 决定是否套壳。** 已开启套壳时，podspec 的 `s.static_framework = true` 可把该 Pod 固定为静态 framework，即使 Podfile 指定了 `:dynamic`。不开壳时它仍产出 `.a`。
- **静态代码进入链接它的二进制。** 在 Demo 里，两个三方静态函数会进入 App 主程序，或进入链接它们的动态 Pod。预编译的 `DynamicVendor.framework` 在不开壳时也会由 CocoaPods 嵌入 `App.app/Frameworks/`，运行时由 dyld 加载。
- **源码 Pod 与集成 target 各有产物。** Demo 中 `libXX.a` 包含 Pod 源码编译后的对象文件，`libPods-<App>.a` 是集成 target 的占位归档，App 分别链接所需产物。

## 2. 模块化头文件解决什么

**Module map 告诉 Clang 哪些头文件属于哪个模块。** CocoaPods 默认生成的 umbrella header 汇总公开头文件。两者让调用方在编译时看到 API 声明，链接器再从库里找到实现。

| 配置 | 作用范围 |
| --- | --- |
| `use_frameworks!` | framework 形式的源码 Pod 默认生成模块描述 |
| `use_modular_headers!` | 为作用域内的静态库 Pods 开启模块化头文件 |
| `:modular_headers => true` | 在 Podfile 中只给指定 Pod 开启 |
| `s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }` | Pod 作者在 podspec 中声明模块 |

- 含 Swift 源码的 Pod 会被 CocoaPods 自动识别为模块。纯 Objective-C 的 `LegacyObjCPod` 开启模块化后，Swift 可用 `import LegacyObjCPod`，Objective-C 可按路径 `#import <LegacyObjCPod/LegacyObjCBridge.h>`，也可按模块名 `@import LegacyObjCPod;`。
- 已有 `.a` 集成且只需给一个 Objective-C Pod 补模块接口时，用 `:modular_headers => true`。工程或 SDK 交付要求 `.framework` 目录且希望静态链接时，用 `:linkage => :static`。

## 3. Swift 和 Objective-C 怎么互调

| 范围 | Swift 调 Objective-C | Objective-C 调 Swift |
| --- | --- | --- |
| 同一个 App target | App 桥接头导入 Objective-C 头文件，Xcode 通过 `SWIFT_OBJC_BRIDGING_HEADER` 指定桥接头 | 在 `.m` 中导入编译器生成的 `"AppModule-Swift.h"` |
| 同一个混编 Pod | Swift 编译时导入 Pod 的底层 Clang 模块，接口由公开头文件和 umbrella header 提供 | 在 `.m` 中导入生成的 `"PodModule-Swift.h"` |
| App 调 Pod | Swift 用 `import LegacyObjCPod` 导入纯 Objective-C Pod | 本 Demo 的 CocoaPods 静态库使用 `@import MixedInteropPod.Swift;` 访问 Pod 的 Swift 接口 |

- Swift 暴露给 Objective-C 的 API 要能映射到 Objective-C。Demo 用 `NSObject` 子类加 `@objcMembers`，供 App 调用的 Pod Swift 方法声明为 `public`。
- **Pod 反向调用 App**通过协议注入。Pod 定义 `InteropHost`，App 把 Objective-C 或 Swift 实现传入，Pod 通过协议回调。编译依赖仍是 App → Pod。

## 三个实测工程

- [CocoaPodsFrameworkPackagingDemo](CocoaPodsFrameworkPackagingDemo/README.md) 对照普通 `.a`、模块化 `.a`、静态 framework、动态 framework。
- [CocoaPodsDefinesModuleDemo](CocoaPodsDefinesModuleDemo/README.md) 验证 Podfile 即使设置 `:modular_headers => false`，podspec 的 `DEFINES_MODULE = YES` 仍可让 `.a` 支持 `@import`。
- [ObjCSwiftInteropDemo](ObjCSwiftInteropDemo/README.md) 实测 App 内、Pod 内和跨 target 的 11 条调用。
