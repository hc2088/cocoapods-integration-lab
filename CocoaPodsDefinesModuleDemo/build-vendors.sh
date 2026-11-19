#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

arch="$(uname -m)"
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
compile=(xcrun --sdk iphonesimulator clang -target "${arch}-apple-ios15.0-simulator" -isysroot "$sdk")
sources=VendorSources
vendor=MixedBinaryPod/Vendor
objects=.build/vendor-objects

mkdir -p "$vendor" "$objects"

make_framework_bundle() {
    local name="$1"
    local framework="$vendor/$name.framework"
    mkdir -p "$framework/Headers"
    cp "$sources/$name.h" "$framework/Headers/"
    cat > "$framework/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$name</string>
    <key>CFBundleIdentifier</key>
    <string>org.example.vendoredbinarydemo.$name</string>
    <key>CFBundleName</key>
    <string>$name</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
PLIST
}

build_archive() {
    local name="$1"
    local output="$2"
    "${compile[@]}" -c "$sources/$name.c" -o "$objects/$name.o"
    xcrun libtool -static -o "$output" "$objects/$name.o"
}

cp "$sources/ArchiveVendor.h" "$vendor/"
build_archive ArchiveVendor "$vendor/libArchiveVendor.a"

make_framework_bundle StaticVendor
build_archive StaticVendor "$vendor/StaticVendor.framework/StaticVendor"

make_framework_bundle DynamicVendor
"${compile[@]}" -dynamiclib "$sources/DynamicVendor.c" \
    -install_name '@rpath/DynamicVendor.framework/DynamicVendor' \
    -o "$vendor/DynamicVendor.framework/DynamicVendor"
