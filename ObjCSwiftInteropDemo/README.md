# Objective-C 与 Swift 混编 Demo

这个工程用三个范围、十四条实际调用演示 Objective-C 和 Swift 如何调用 App 与 Pod 的接口。主工程只有一个 App target，四个本地 Pod 都以 `.a` 集成。App 界面和控制台显示每条调用从被调用方返回的结果。

| Target | 组成 | 模块从哪里来 |
| --- | --- | --- |
| `ObjCSwiftInteropDemo` | App 内同时编译 `.m` 和 `.swift` | App 的桥接头和 Swift 编译器生成的接口头 |
| `MixedInteropPod` | 同一个 Pod 内同时编译 `.m` 和 `.swift` | 含 Swift 源码，CocoaPods 为它处理模块和兼容头 |
| `LegacyObjCPod` | 纯 Objective-C Pod，由 App 和 `MixedInteropPod` 使用 | Podfile 对这个 Pod 设置了 `:modular_headers => true` |

## 运行

```bash
./verify.sh
open ObjCSwiftInteropDemo.xcworkspace
```

在 Xcode 选择 `ObjCSwiftInteropDemo` scheme 和 iOS 模拟器，按 ⌘R。脚本会安装本地 Pods、构建 App，并检查四个 `.a`、纯 Objective-C module map、混编 Pod 的 Swift 子模块，以及 App 和 Pod 的 `-Swift.h`。实测环境为 Xcode 26.6、CocoaPods 1.16.2 和 arm64 iOS 模拟器。

## 1. 主工程内相互调用

| 调用 | 接口如何可见 |
| --- | --- |
| App Swift → App Objective-C | App target 的 `SWIFT_OBJC_BRIDGING_HEADER` 指向 `ObjCSwiftInteropDemo-Bridging-Header.h`，该文件导入 `AppObjCBridge.h`。同 target 的 Swift 可以直接调用 `AppObjCBridge.message()`。 |
| App Objective-C → App Swift | `main.m` 导入编译器生成的 `"ObjCSwiftInteropDemo-Swift.h"`，然后发送 `[AppSwiftBridge message]`。Demo 用 `NSObject` 子类和 `@objcMembers` 暴露可由 Objective-C 调用的方法。 |

App 桥接头和 `-Swift.h` 各管一个方向。桥接头是工程里的源码文件，`-Swift.h` 是编译生成的文件。 [Apple 的 Objective-C → Swift 指南](https://developer.apple.com/documentation/swift/importing-objective-c-into-swift) · [Apple 的 Swift → Objective-C 指南](https://developer.apple.com/documentation/swift/importing-swift-into-objective-c)

## 2. Pod 内和 Pod 之间的调用

| 调用 | 接口如何可见 |
| --- | --- |
| `MixedInteropPod` Swift → 同 Pod 的 Objective-C | podspec 通过 `public_header_files` 暴露 `PodObjCBridge.h`。CocoaPods 生成 umbrella header 和 Clang module map，Swift 编译时导入底层模块，直接调用 `PodObjCBridge.message()`。 |
| `MixedInteropPod` Objective-C → 同 Pod 的 Swift | `PodObjCBridge.m` 导入编译器生成的 `"MixedInteropPod-Swift.h"`，然后调用 `[PodSwiftBridge message]`。 |
| `MixedInteropPod` Swift → 另一个 Objective-C Pod | podspec 用 `s.dependency 'LegacyObjCPod'` 声明编译依赖。Swift 文件用 `import LegacyObjCPod` 导入这个纯 Objective-C Pod 的 Clang 模块。 |

这里的 `:modular_headers => true` 用于**把已有的纯 Objective-C 静态 Pod 变成 Swift 可以导入的模块**。我在临时副本中移除了 `LegacyObjCPod` 的该选项，`pod install` 会在生成工程前提示 `MixedInteropPod` 依赖的 `LegacyObjCPod` 没有定义模块。恢复选项后，Swift 可以导入它，这两个依赖仍然生成静态 `.a`。 [CocoaPods 的 Swift 静态库和模块化头文件说明](https://blog.cocoapods.org/CocoaPods-1.5.0/#modular-headers)

### 独立 Objective-C Pod 调用另一个 Pod 的 Swift

`SwiftCallerPod` 通过 podspec 的 `s.dependency 'MixedInteropPod'` 声明依赖。它的 Objective-C 实现在 `.m` 中导入 CocoaPods 为静态 Pod 暴露的 Swift 子模块。

```objc
#import "SwiftCaller.h"
@import MixedInteropPod.Swift;
```

随后调用 `[PodSwiftBridge message]`。`#import "MixedInteropPod-Swift.h"` 对应本 Demo 中 `MixedInteropPod` 内部对其生成头的导入。跨 Pod 的示例通过 `.Swift` 子模块找到兼容头副本。

反方向由 App 将实现 `InteropHost` 的 `SwiftCaller` 传给 `PodSwiftBridge.callHost`，Swift 调用协议方法回到 Objective-C。编译依赖仍为 `SwiftCallerPod → MixedInteropPod`。两条结果都在 App 的「Pod 内与 Pod 之间」显示。 [调用源码](SwiftCallerPod/Sources/SwiftCaller.m)

### 独立纯 Swift Pod 调用纯 Objective-C Pod

`SwiftToObjCPod` 的 podspec 用 `s.dependency 'LegacyObjCPod', '1.0.0'` 声明依赖。Podfile 给被调用的 `LegacyObjCPod` 设置 `:modular_headers => true`，让 Swift 可以按模块读取它的公开头文件。

```swift
import LegacyObjCPod

public enum LegacyCaller {
    public static func callObjectiveC() -> String {
        LegacyObjCBridge.message()
    }
}
```

App 调用 `LegacyCaller.callObjectiveC()` 后，实际跨 Pod 的调用在 Swift 源文件里完成。结果显示在「Pod 内与 Pod 之间」。 [调用源码](SwiftToObjCPod/Sources/LegacyCaller.swift)

## 3. 主工程与 Pod 之间的调用

| 调用 | 接口如何可见 |
| --- | --- |
| App Swift → Pod Objective-C | App Swift 文件用 `import LegacyObjCPod`，然后调用 `LegacyObjCBridge.message()`。这里用的是 Pod 的模块。 |
| App Objective-C → Pod Objective-C（头文件导入） | `#import <LegacyObjCPod/LegacyObjCBridge.h>`，然后调用 `[LegacyObjCBridge message]`。 |
| App Objective-C → Pod Objective-C（模块导入） | `@import LegacyObjCPod;`，然后调用同一个方法。 |
| App Objective-C → Pod Swift | `main.m` 用 `@import MixedInteropPod.Swift;`，然后调用 `[PodSwiftBridge message]`。在这个 CocoaPods 静态库构建中，CocoaPods 将 Swift 兼容头加入 `.Swift` 子模块。 |
| Pod Swift → App Objective-C | App 创建实现 `InteropHost` 的 `AppObjCHost` 并传入 Pod。Pod Swift 调用 `host.hostMessage()`，实际执行 App 的 Objective-C 实现。 |
| Pod Objective-C → App Swift | App 把实现同一协议的 `AppSwiftBridge` 对象传入 Pod。Pod Objective-C 调用 `[host hostMessage]`，实际执行 App 的 Swift 实现。 |

**纯 Objective-C Pod 开启模块化后，两种导入写法都可以用。** App target 的头文件搜索路径支持 `#import`，生成的 module map 支持按模块名 `@import`。Demo 将两种写法放进独立的 `.m` 文件，各自调用 `[LegacyObjCBridge message]`。 [`#import` 示例](App/LegacyObjCHeaderImport.m) · [`@import` 示例](App/LegacyObjCModuleImport.m)

这个工程启用了 Clang Modules。使用 `-Rmodule-import` 单独编译这两个文件时，可以看到 Clang 在两种写法下都加载了 `LegacyObjCPod` 模块。通过路径写的 `#import` 也能触发模块导入。

**反向调用通过协议注入。** `InteropHost` 的声明属于 Pod，具体对象由 App 创建。编译依赖仍是 App → Pod，运行时 Pod 可以调用传入对象上的方法。

```objc
@protocol InteropHost <NSObject>
- (NSString *)hostMessage;
@end
```

## Objective-C 调 Swift 的三个导入入口

| 调用位置 | 导入方式 | 头文件来源 |
| --- | --- | --- |
| App 内部 | `#import "ObjCSwiftInteropDemo-Swift.h"` | App target 的 `DERIVED_SOURCES_DIR` |
| 混编 Pod 内部 | `#import "MixedInteropPod-Swift.h"` | Pod target 自己的 `DERIVED_SOURCES_DIR` |
| App 调用静态 Pod 的 Swift | `@import MixedInteropPod.Swift;` | CocoaPods 注册到 `.Swift` 子模块中的兼容头副本 |

在本例的静态库集成里，App 通过生成的 module map 找到 Pod 的 Swift 接口。CocoaPods 的 **Copy generated compatibility header** 阶段将 Pod 编译生成的头复制到 `$(BUILT_PRODUCTS_DIR)/Swift Compatibility Header/MixedInteropPod-Swift.h`（这里的 `BUILT_PRODUCTS_DIR` 属于 Pod target），并在构建产物的 `MixedInteropPod.modulemap` 中添加 `MixedInteropPod.Swift` 子模块。运行 `./verify.sh` 后，可在 `.build/DerivedData/Build/Products/Debug-iphonesimulator/MixedInteropPod/` 查看这两份构建产物。

## 代码和产物

- 主工程的导入和回调入口在 [AppSwiftBridge.swift](App/AppSwiftBridge.swift)、[main.m](App/main.m) 和 [App 桥接头](App/ObjCSwiftInteropDemo-Bridging-Header.h)。
- 混编 Pod 的两个调用方向在 [PodSwiftBridge.swift](MixedInteropPod/Sources/PodSwiftBridge.swift) 和 [PodObjCBridge.m](MixedInteropPod/Sources/PodObjCBridge.m)，回调接口在 [InteropHost.h](MixedInteropPod/Sources/InteropHost.h)。
- `LegacyObjCPod.modulemap` 可在 `Pods/Headers/Public/LegacyObjCPod/` 查看。`MixedInteropPod.modulemap`、`Swift Compatibility Header/MixedInteropPod-Swift.h` 和四个 Pod 的 `.a` 可在 `.build/DerivedData/Build/Products/Debug-iphonesimulator/` 的对应 Pod 目录查看。
