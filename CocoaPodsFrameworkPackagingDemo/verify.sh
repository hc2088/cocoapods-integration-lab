#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

./build-vendors.sh
COCOAPODS_DISABLE_STATS=true pod install --no-repo-update

module_map='Pods/Headers/Public/MixedBinaryPod/MixedBinaryPod-Pods-ModularHeadersDemo.modulemap'
plain_config='Pods/Target Support Files/Pods-NoFrameworkDemo/Pods-NoFrameworkDemo.debug.xcconfig'
modular_config='Pods/Target Support Files/Pods-ModularHeadersDemo/Pods-ModularHeadersDemo.debug.xcconfig'
if grep -Fq -- '-fmodule-map-file=' "$plain_config"; then
    printf 'NoFrameworkDemo 意外启用了 module map。\n' >&2
    exit 1
fi
printf '\n=== ModularHeadersDemo 的 module map ===\n'
grep -F -- '-fmodule-map-file=' "$modular_config"
grep -Fxq 'module MixedBinaryPod {' "$module_map"
cat "$module_map"

verify_variant() {
    local variant="$1"
    local scheme="$2"
    local build_dir=".build/$variant"
    local products="$build_dir/DerivedData/Build/Products/Debug-iphonesimulator"
    local pod_target="MixedBinaryPod-Pods-$scheme"
    local app="$products/$scheme.app"
    local executable="$app/$scheme"
    local embedded_pod="$app/Frameworks/MixedBinaryPod.framework/MixedBinaryPod"
    local dynamic_vendor='@rpath/DynamicVendor.framework/DynamicVendor'
    local pod aggregate app_dependencies pod_dependencies symbol_image symbols symbol

    if [[ "$variant" == library || "$variant" == modular ]]; then
        pod="$products/$pod_target/lib$pod_target.a"
        aggregate="$products/libPods-$scheme.a"
    else
        pod="$products/$pod_target/MixedBinaryPod.framework/MixedBinaryPod"
        aggregate="$products/Pods_$scheme.framework/Pods_$scheme"
    fi

    printf '\n=== %s (%s) ===\n' "$scheme" "$variant"
    mkdir -p "$build_dir"
    if ! xcodebuild -workspace FrameworkPackagingDemo.xcworkspace -scheme "$scheme" \
        -configuration Debug -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "$build_dir/DerivedData" "ARCHS=$(uname -m)" ONLY_ACTIVE_ARCH=NO \
        > "$build_dir/xcodebuild.log" 2>&1; then
        tail -80 "$build_dir/xcodebuild.log" >&2
        return 1
    fi

    printf '\n--- Pod 与 CocoaPods 集成 target 的二进制 ---\n'
    file "$pod" "$aggregate"
    file -b "$aggregate" | grep -q 'current ar archive'
    xcrun ar -t "$aggregate"

    printf '\n--- App/Frameworks ---\n'
    find "$app/Frameworks" -maxdepth 1 -name '*.framework' -print | sort
    test -f "$app/Frameworks/DynamicVendor.framework/DynamicVendor"
    test ! -e "$app/Frameworks/StaticVendor.framework"
    test ! -e "$app/Frameworks/Pods_$scheme.framework"

    printf '\n--- App 的动态依赖（otool -L）---\n'
    app_dependencies="$(xcrun otool -L "$executable")"
    grep -F '@rpath/' <<< "$app_dependencies"
    grep -Fq "$dynamic_vendor" <<< "$app_dependencies"

    if [[ "$variant" == dynamic ]]; then
        file -b "$pod" | grep -q 'dynamically linked shared library'
        test -f "$embedded_pod"
        grep -Fq '@rpath/MixedBinaryPod.framework/MixedBinaryPod' <<< "$app_dependencies"

        printf '\n--- MixedBinaryPod 的动态依赖（otool -L）---\n'
        pod_dependencies="$(xcrun otool -L "$embedded_pod")"
        grep -F "$dynamic_vendor" <<< "$pod_dependencies"
        xcrun nm -m "$executable" | grep -E '\(undefined\).* _MixedBinaryPodReport \(from MixedBinaryPod\)$'
        symbol_image="$embedded_pod"
    else
        file -b "$pod" | grep -q 'current ar archive'
        test ! -e "$app/Frameworks/MixedBinaryPod.framework"
        symbol_image="$executable"
    fi

    printf '\n--- 符号所在的二进制 ---\n%s\n' "$symbol_image"
    symbols="$(xcrun nm -m "$symbol_image")"
    for symbol in MixedBinaryPodReport BinaryDemoArchiveValue BinaryDemoStaticFrameworkValue; do
        grep -E "\\(__TEXT,__text\\).* _${symbol}$" <<< "$symbols"
    done
    grep -E '\(undefined\).* _BinaryDemoDynamicFrameworkValue \(from DynamicVendor\)$' <<< "$symbols"

    printf '\n验证通过。App 位于 %s\n' "$app"
}

verify_variant library NoFrameworkDemo
verify_variant modular ModularHeadersDemo
verify_variant static StaticFrameworkDemo
verify_variant dynamic DynamicFrameworkDemo
