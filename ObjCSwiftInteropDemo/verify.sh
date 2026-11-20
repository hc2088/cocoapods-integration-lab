#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

COCOAPODS_DISABLE_STATS=true pod install --no-repo-update

mkdir -p .build
if ! xcodebuild -workspace ObjCSwiftInteropDemo.xcworkspace -scheme ObjCSwiftInteropDemo \
    -configuration Debug -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath .build/DerivedData "ARCHS=$(uname -m)" ONLY_ACTIVE_ARCH=NO \
    > .build/xcodebuild.log 2>&1; then
    tail -80 .build/xcodebuild.log >&2
    exit 1
fi

products=.build/DerivedData/Build/Products/Debug-iphonesimulator
mixed="$products/MixedInteropPod"
app_build=.build/DerivedData/Build/Intermediates.noindex/ObjCSwiftInteropDemo.build/Debug-iphonesimulator/ObjCSwiftInteropDemo.build

printf '\n=== 四个 Pod 的静态归档 ===\n'
for archive in "$products/LegacyObjCPod/libLegacyObjCPod.a" "$mixed/libMixedInteropPod.a" \
    "$products/SwiftCallerPod/libSwiftCallerPod.a" \
    "$products/SwiftToObjCPod/libSwiftToObjCPod.a"; do
    kind="$(file -b "$archive")"
    printf '%s: %s\n' "$archive" "$kind"
    [[ "$kind" == *'current ar archive'* ]]
done

printf '\n=== 纯 Objective-C Pod 的 Clang 模块 ===\n'
grep -Fx 'module LegacyObjCPod {' Pods/Headers/Public/LegacyObjCPod/LegacyObjCPod.modulemap

printf '\n=== Objective-C 可见的 Swift 接口 ===\n'
grep -Fx 'module MixedInteropPod.Swift {' "$mixed/MixedInteropPod.modulemap"
grep -F '@interface PodSwiftBridge' "$mixed/Swift Compatibility Header/MixedInteropPod-Swift.h"
grep -F '@interface AppSwiftBridge' "$app_build/DerivedSources/ObjCSwiftInteropDemo-Swift.h"

printf '\n构建检查通过。App 位于 %s/ObjCSwiftInteropDemo.app\n' "$products"
