# CocoaPods 静态库、Framework 与模块导入

本 Demo 用同一份 Objective-C 源码 Pod `MixedBinaryPod` 对照四种集成方式。Pod 同时调用三个本地编译的预编译库，分别是 `libArchiveVendor.a`、静态 `StaticVendor.framework` 和动态 `DynamicVendor.framework`。App 用 `dladdr` 显示每个函数实际所在的二进制。

**先区分三个问题。** 包装方式决定产物是裸 `.a` 还是 `.framework`。模块配置决定 Clang 如何导入 API 声明。链接方式决定函数实现最终进入哪个二进制。

## 运行与实测

在本目录运行以下命令。验证环境为 Xcode 26.6、CocoaPods 1.16.2、arm64 iOS 模拟器。

```bash
./verify.sh
open FrameworkPackagingDemo.xcworkspace
```

`verify.sh` 从 [VendorSources](VendorSources) 生成三方库，执行 `pod install`，再构建并检查四个 scheme。在 Xcode 选择任一 scheme 和 iOS 模拟器后按 ⌘R。

| Scheme | 配置与导入方式 | 源码 Pod 的二进制产物 | 两个三方静态函数的位置 | App 包内的 `Frameworks/` |
| --- | --- | --- | --- | --- |
| `NoFrameworkDemo` | 默认静态库，`#import` | `libMixedBinaryPod-Pods-NoFrameworkDemo.a` | App 主可执行文件 | `DynamicVendor.framework` |
| `ModularHeadersDemo` | `:modular_headers => true`，`@import` | `libMixedBinaryPod-Pods-ModularHeadersDemo.a` | App 主可执行文件 | `DynamicVendor.framework` |
| `StaticFrameworkDemo` | `use_frameworks! :linkage => :static`，`@import` | `MixedBinaryPod.framework` 内的静态归档 | App 主可执行文件 | `DynamicVendor.framework` |
| `DynamicFrameworkDemo` | `use_frameworks! :linkage => :dynamic`，`@import` | `MixedBinaryPod.framework` 内的 Mach-O 动态库 | `MixedBinaryPod.framework/MixedBinaryPod` | `DynamicVendor.framework`、`MixedBinaryPod.framework` |

## 包装与链接

- **裸静态库** `libXX.a` 是由对象文件组成的 `ar` 归档，头文件通过独立的搜索路径提供。
- **静态 framework** 把静态归档、头文件和模块描述组织进 `XX.framework`。
- **动态 framework** 使用同样的目录结构，内部二进制是 Mach-O `DYLIB`。库作为独立的二进制随 App 分发，运行时由 dyld 加载。Demo 中两种 framework 都是 arm64，区别在于链接类型。

两份 framework 的构建产物都有 `Headers/`、`Modules/` 和 `Info.plist`。其中公开头文件相同，module map 使用相同的模块名，分别引用各自生成的 umbrella header。

### Podfile 和 podspec 谁决定产物

**Podfile 先决定是否使用 framework 包装。开启包装后，podspec 的 `s.static_framework = true` 可以把当前 Pod 的链接类型固定为静态。** Podfile 参数的正确拼写是 `:linkage`。CocoaPods 按 App target 应用该配置，子 target 可以继承它。 [Podfile 配置](https://guides.cocoapods.org/syntax/podfile.html#use_frameworks_bang) · [CocoaPods 1.16.2 的构建类型判断](https://github.com/CocoaPods/CocoaPods/blob/1.16.2/lib/cocoapods/installer/analyzer.rb#L911-L918)

| App target 生效的 Podfile 配置 | podspec 未设置 `static_framework` 或设为 `false` | podspec 设置 `s.static_framework = true` |
| --- | --- | --- |
| 未开启 framework 包装 | 静态 `.a` | 静态 `.a` |
| `use_frameworks! :linkage => :static` | 静态 `.framework` | 静态 `.framework` |
| `use_frameworks!` 或 `use_frameworks! :linkage => :dynamic` | 动态 `.framework` | 静态 `.framework` |

单独写 `use_frameworks!` 时，默认链接类型为动态。表中的规则针对 **Pod 源码编译出的产物**。预编译库仍按二进制本身的静态或动态类型处理。 [Podspec 的 `static_framework`](https://guides.cocoapods.org/syntax/podspec.html#static_framework)

在本 Demo 的临时副本中给 `MixedBinaryPod` 加上 `s.static_framework = true` 后，`NoFrameworkDemo` 仍产出静态 `.a`，而设为 `:linkage => :dynamic` 的 `DynamicFrameworkDemo` 产出内部为静态归档的 `MixedBinaryPod.framework`。两个 App 仍都嵌入预编译的 `DynamicVendor.framework`。

### 模块化 .a 和静态 framework 怎么选

| 需求 | 优先选择 | 原因 |
| --- | --- | --- |
| 现有 App 已用 `.a` 集成 Pods，只需要让某个 Objective-C Pod 能被 Swift 的 `import` 或 Objective-C 的 `@import` 导入 | 保持静态库集成，对该 Pod 设置 `:modular_headers => true` | 仅对该 Pod 开启模块化头文件，CocoaPods 生成 module map，源码产物依旧是 `.a` |
| 工程或 SDK 交付流程要求 `.framework` 目录，同时要求静态链接 | 在消费方 target 设置 `use_frameworks! :linkage => :static` | 头文件、模块描述和静态归档放在同一个标准 framework 目录内，适合统一使用 framework 的工程 |

两种方案都能提供按模块导入的接口。在本 Demo 中，使用到的静态函数也都进入 App 主可执行文件。选型时看实际需要的是**为单个依赖提供模块接口**，还是**为 target 的源码 Pods 采用 framework 包装**。已有工程切换整个 target 的包装方式时，需要一起考虑该 target 的其他依赖。 [CocoaPods 模块化头文件说明](https://blog.cocoapods.org/CocoaPods-1.5.0/#modular-headers)

## 三方二进制最终去了哪里

`MixedBinaryPod.podspec` 用 `vendored_libraries` 声明 `.a`，用 `vendored_frameworks` 声明两个预编译的 `.framework`。CocoaPods 检查 framework 内部二进制，识别哪些需要嵌入。 [Demo podspec](MixedBinaryPod/MixedBinaryPod.podspec) · [CocoaPods 动态产物收集逻辑](https://github.com/CocoaPods/CocoaPods/blob/1.16.2/lib/cocoapods/target/pod_target.rb)

- **静态的两个库**由产生最终 Mach-O 的链接步骤取用。前三个 scheme 在链接 App 时取用它们，动态 scheme 在链接 `MixedBinaryPod.framework` 时取用它们。归档中被引用的代码因此进入相应的二进制。
- **动态的 `DynamicVendor.framework`** 在四个 scheme 中都由 `[CP] Embed Pods Frameworks` 复制到 `App.app/Frameworks/`，包括两个未开启 `use_frameworks!` 的 scheme。动态模式下，`MixedBinaryPod` 自己也需要解析它的符号，因此本 Demo 用 `pod_target_xcconfig` 给 Pod 补了 `-framework DynamicVendor`。

## CocoaPods 集成产物和 dummy 文件

`pod install` 会生成单独的 Pod target，以及每个 App 对应的 `Pods-<App>` 集成 target，并生成 `.xcconfig` 和构建脚本。以 `NoFrameworkDemo` 为例，两个归档各自由自己的 target 生成。

| 产物 | 归档内容 |
| --- | --- |
| `libMixedBinaryPod-Pods-NoFrameworkDemo.a` | 包含由 `MixedBinaryPod.m` 编译出的 `MixedBinaryPod.o`，以及生成的 dummy 对象 |
| `libPods-NoFrameworkDemo.a` | 只有生成的 `Pods-NoFrameworkDemo-dummy.o` |

`dummy.m` 定义一个空的 Objective-C 类，为集成 target 提供可编译的占位源码。Demo 使用 `-ObjC` 链接，因此也能在 App 主可执行文件里查到该类的符号。

App 的链接器分别读取集成归档和由 `OTHER_LDFLAGS` 指定的 Pod 产物。这里 `-l"MixedBinaryPod-Pods-NoFrameworkDemo"` 直接指向源码 Pod 的归档，`-l"ArchiveVendor"` 和 `-framework "StaticVendor"` 指向两个三方静态库。两个 framework 模式的集成产物叫 `Pods_StaticFrameworkDemo.framework` 和 `Pods_DynamicFrameworkDemo.framework`，内部都是静态归档，含 dummy 对象和版本对象。

## 模块化头文件与 module map

### 开启 module map 的四种配置

对由 CocoaPods 构建的 Objective-C 源码 Pod，按**触发 CocoaPods 默认生成 module map 的配置写法**计，有四种常用入口。

| 写法 | 配置位置和作用范围 | 源码 Pod 的产物 |
| --- | --- | --- |
| `use_frameworks!`，可指定 `:linkage => :static` 或 `:dynamic` | Podfile 的 target 采用 framework 包装，静态和动态 framework 默认都会生成模块描述 | 静态或动态 `.framework` |
| `use_modular_headers!` | Podfile 全局或 target 级，为作用域内的静态库 Pod 开启模块化头文件，子 target 可继承 | 保持静态 `.a` |
| `pod 'MixedBinaryPod', :modular_headers => true` | Podfile 的单个依赖声明，适合只给这个 Pod 补模块支持 | 保持静态 `.a` |
| `s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }` | Podspec，Pod 作者为自己的 Pod target 声明模块 | 未启用 framework 包装时保持静态 `.a` |

在 `use_modular_headers!` 的作用域内，可以用 `:modular_headers => false` 关闭单个 Pod 的 Podfile 侧启用。该 Pod 的 podspec 若声明了 `DEFINES_MODULE = YES`，仍可触发生成。Swift 源码 Pod 也会被 CocoaPods 自动识别为模块，这里统计的是 Objective-C 源码 Pod 的显式配置。 [CocoaPods Podfile 文档](https://guides.cocoapods.org/syntax/podfile.html#use_modular_headers_bang) · [模块判定源码](https://github.com/CocoaPods/CocoaPods/blob/1.16.2/lib/cocoapods/target/pod_target.rb#L359-L377) · [podspec 实测工程](../CocoaPodsDefinesModuleDemo/README.md)

**自定义 module map 是另一层配置。** `s.module_map = 'Sources/Explicit.modulemap'` 指定模块启用后由 CocoaPods 使用的文件。单独设置文件路径时，普通 Objective-C `.a` target 仍需要上述模块启用条件。也可以由编译配置直接传给 Clang，例如 `-fmodule-map-file=路径`。`s.module_map = false` 会让 CocoaPods 跳过生成步骤。 [CocoaPods 文件生成条件](https://github.com/CocoaPods/CocoaPods/blob/1.16.2/lib/cocoapods/installer/xcode/pods_project_generator/pod_target_installer.rb#L75-L92) · [Clang Modules 参数](https://clang.llvm.org/docs/Modules.html#command-line-parameters)

在临时副本里验证过，给 `NoFrameworkDemo` 的 target 添加 `use_modular_headers!` 后，App 能用 `@import` 构建，源码 Pod 仍产出 `.a`。只设置自定义 `s.module_map` 路径的测试中，CocoaPods 未给普通 `.a` 的 App 集成配置加上该 module map。

### Module map 和 umbrella header

`NoFrameworkDemo` 通过 `#import <MixedBinaryPod/MixedBinaryPod.h>` 导入公开头文件。配置了 `:modular_headers => true` 的 `ModularHeadersDemo` 使用 `@import MixedBinaryPod;`，其 Pod 二进制仍是 `.a`。本工程设置 `:deduplicate_targets => false`，让这两种静态库模式各自生成 Pod target，便于比较生成的配置。 [Podfile](Podfile) · [App 的导入分支](App/main.m)

**Module map 是 Clang 使用的文本配置**，描述头文件归属哪个模块，以及导入模块时哪些声明可见。模块化 `.a` 的 module map 以 `module MixedBinaryPod {` 开头，CocoaPods 在 App 的 `.xcconfig` 中通过 `-fmodule-map-file` 指定它。Framework 产物的 module map 放在 `Modules/module.modulemap`，以下是动态 framework 的实际声明。

```text
framework module MixedBinaryPod {
  umbrella header "MixedBinaryPod-Pods-DynamicFrameworkDemo-umbrella.h"

  export *
  module * { export * }
}
```

| 声明 | 含义 |
| --- | --- |
| `framework module MixedBinaryPod` | 声明模块名，并使用 framework 的目录布局查找头文件 |
| `umbrella header "…"` | 指定入口头文件。本例的入口会导入公开头 `MixedBinaryPod.h` |
| `export *` | 将头文件实际导入的模块再导出，使调用方能看到这些模块的声明 |
| `module * { export * }` | 为 umbrella 覆盖且未单独声明的头文件推导子模块，并应用同样的再导出规则 |

默认生成的 module map 通过 `umbrella header` 找到公开接口的汇总头。编写自己的 module map 时，也可以用 `header "MixedBinaryPod.h"` 直接声明模块包含的头文件。

Clang 可以将解析后的声明保存为可复用的 `.pcm` 模块文件。两种静态库的编译对照已验证，普通模式的 `#import` 可以通过，将同一调用改成 `@import` 会报 `module not found`，提供 module map 后可以通过。 [Clang Modules 规范](https://clang.llvm.org/docs/Modules.html#module-map-language)

## 编译、链接、运行分别看什么

1. **编译**。Clang 读取头文件声明或模块信息，做类型检查，再生成带有函数引用的 `.o`。导入 framework 模块时，Clang 也可以在 `.o` 中写入供链接器读取的 `LC_LINKER_OPTION`。这个阶段的典型问题是找不到头文件或模块。
2. **链接**。链接器根据 `OTHER_LDFLAGS`、库搜索路径和符号引用取用静态归档中的代码，或在最终 Mach-O 中记录动态库依赖，例如 `@rpath/DynamicVendor.framework/DynamicVendor`。这个阶段的典型问题是 `Undefined symbols`。
3. **打包与运行**。CocoaPods 将动态 framework 放进 App 的 `Frameworks/`，嵌入脚本会过滤 `Headers`、`PrivateHeaders` 和 `Modules`。启动时 dyld 根据 Mach-O 记录的依赖和运行时搜索路径加载库，例如通过 `@executable_path/Frameworks` 解析 `@rpath`。这个阶段的典型问题是 `Library not loaded`。

## 查看实际产物

四种模式的构建目录依次是 `.build/library/`、`.build/modular/`、`.build/static/` 和 `.build/dynamic/`。每个目录下都有 `xcodebuild.log`，二进制位于 `DerivedData/Build/Products/Debug-iphonesimulator/`。以下命令以普通 `.a` 模式为例。

```bash
products=.build/library/DerivedData/Build/Products/Debug-iphonesimulator
app="$products/NoFrameworkDemo.app"

file "$products/MixedBinaryPod-Pods-NoFrameworkDemo/libMixedBinaryPod-Pods-NoFrameworkDemo.a"
xcrun ar -t "$products/libPods-NoFrameworkDemo.a"
xcrun nm -m "$app/NoFrameworkDemo" | grep -E 'MixedBinaryPodReport|BinaryDemo.*Value'
xcrun otool -L "$app/NoFrameworkDemo"
ls "$app/Frameworks"
```

`file` 检查二进制的类型，`ar -t` 列出归档成员，`nm -m` 区分符号定义与外部引用，`otool -L` 查看动态库依赖。完整的四组检查可直接运行 [verify.sh](verify.sh)。
