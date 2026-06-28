#!/usr/bin/env bash
# scripts/build_native.sh
#
# Builds libtonic_wrapper for Android (all ABIs) and iOS (XCFramework).
# Run from the project root: ./scripts/build_native.sh
#
# Output:
#   native/libs/android/<ABI>/libtonic_wrapper.so
#   native/libs/ios/libtonic_wrapper.xcframework
#   build/build.log

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

NDK_PATH="${NDK_HOME:-/Users/uptech/android/ndk/28.2.13676358}"
ANDROID_PLATFORM="android-24"
ANDROID_STL="c++_static"
BUILD_TYPE="Release"
ANDROID_ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")
# Flutter 3.44 native assets hardcode MinimumOSVersion=13.0 in the generated
# framework plist (flutter/flutter#145104). The binary minos must match or
# Apple validation flags a binary/plist mismatch. Our app deployment target
# (15.6) enforces the real minimum; 13.0 here is the binary floor only.
IOS_MIN_VERSION="13.0"
IOS_SIGNING_IDENTITY="-"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TONIC_DIR="$PROJECT_ROOT/third_party/tonic"
ANDROID_OUTPUT="$PROJECT_ROOT/native/libs/android"
IOS_OUTPUT="$PROJECT_ROOT/native/libs/ios"
BUILD_DIR="$PROJECT_ROOT/build"
LOG_FILE="$BUILD_DIR/build.log"

mkdir -p "$BUILD_DIR"
: > "$LOG_FILE"
exec > "$LOG_FILE" 2>&1

echo "=== tonic_synth_flutter: build native ==="
echo "  Started:  $(date)"
echo ""

# Load signing identity from scripts/signing.env if present
echo "  Loading iOS Signing Identity from scripts/signing.env"
SIGNING_ENV="$SCRIPT_DIR/signing.env"
if [[ -f "$SIGNING_ENV" ]]; then
    echo "Sourcing Signing Env $SIGNING_ENV"
    source "$SIGNING_ENV"
    echo "Using Identity $IOS_SIGNING_IDENTITY"
fi

# ---------------------------------------------------------------------------
# Android
# ---------------------------------------------------------------------------

echo "=== Android ==="
echo "  NDK:      $NDK_PATH"
echo "  Platform: $ANDROID_PLATFORM"
echo "  STL:      $ANDROID_STL"
echo "  ABIs:     ${ANDROID_ABIS[*]}"
echo ""

if [[ ! -d "$NDK_PATH" ]]; then
    echo "ERROR: NDK not found at: $NDK_PATH"
    exit 1
fi

TOOLCHAIN="$NDK_PATH/build/cmake/android.toolchain.cmake"

for ABI in "${ANDROID_ABIS[@]}"; do
    echo "--- Android $ABI ---"

    ABI_BUILD_DIR="$BUILD_DIR/android/$ABI"
    ABI_OUTPUT_DIR="$ANDROID_OUTPUT/$ABI"
    mkdir -p "$ABI_BUILD_DIR" "$ABI_OUTPUT_DIR"

    cmake \
        -S "$TONIC_DIR" \
        -B "$ABI_BUILD_DIR" \
        -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
        -DANDROID_STL="$ANDROID_STL" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="$ABI_OUTPUT_DIR" \
        --log-level=WARNING

    cmake --build "$ABI_BUILD_DIR" \
        --target install \
        --parallel \
        --config "$BUILD_TYPE"

    echo "  ✓ $ABI_OUTPUT_DIR/libtonic_wrapper.so"
done

# ---------------------------------------------------------------------------
# iOS
# ---------------------------------------------------------------------------

echo ""
echo "=== iOS ==="
echo "  Min version:      $IOS_MIN_VERSION"
echo "  Signing identity: $IOS_SIGNING_IDENTITY"
echo ""

# Locate Xcode SDKs
IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
SIMULATOR_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
CLANG=$(xcrun --find clang++)

echo "  SDK (device):    $IPHONEOS_SDK"
echo "  SDK (simulator): $SIMULATOR_SDK"
echo ""

# --- Device (arm64) ---
echo "--- iOS device (arm64) ---"

DEVICE_BUILD_DIR="$BUILD_DIR/ios/arm64"
DEVICE_OUTPUT_DIR="$IOS_OUTPUT/arm64"
mkdir -p "$DEVICE_BUILD_DIR" "$DEVICE_OUTPUT_DIR"

cmake \
    -S "$TONIC_DIR" \
    -B "$DEVICE_BUILD_DIR" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_SYSROOT="$IPHONEOS_SDK" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN_VERSION" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_INSTALL_PREFIX="$DEVICE_OUTPUT_DIR" \
    -DCMAKE_CXX_COMPILER="$CLANG" \
    --log-level=WARNING

cmake --build "$DEVICE_BUILD_DIR" \
    --target install \
    --parallel \
    --config "$BUILD_TYPE"

echo "  ✓ $DEVICE_OUTPUT_DIR/libtonic_wrapper.dylib"

# Wrap in a proper framework bundle so Xcode can re-sign it on-device.
DEVICE_FW_DIR="$DEVICE_OUTPUT_DIR/tonic_wrapper.framework"
mkdir -p "$DEVICE_FW_DIR"
cp "$DEVICE_OUTPUT_DIR/libtonic_wrapper.dylib" "$DEVICE_FW_DIR/tonic_wrapper"
install_name_tool -id "@rpath/tonic_wrapper.framework/tonic_wrapper" \
    "$DEVICE_FW_DIR/tonic_wrapper"
cat > "$DEVICE_FW_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>tonic_wrapper</string>
    <key>CFBundleIdentifier</key>
    <string>dev.chillbro.tonic-wrapper</string>
    <key>CFBundleName</key>
    <string>tonic_wrapper</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>MinimumOSVersion</key>
    <string>$IOS_MIN_VERSION</string>
</dict>
</plist>
PLIST
echo "  ✓ $DEVICE_FW_DIR (framework bundle)"

# --- Simulator (arm64) ---
echo "--- iOS simulator (arm64) ---"

SIM_BUILD_DIR="$BUILD_DIR/ios/arm64-sim"
SIM_OUTPUT_DIR="$IOS_OUTPUT/arm64-sim"
mkdir -p "$SIM_BUILD_DIR" "$SIM_OUTPUT_DIR"

cmake \
    -S "$TONIC_DIR" \
    -B "$SIM_BUILD_DIR" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_SYSROOT="$SIMULATOR_SDK" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN_VERSION" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_INSTALL_PREFIX="$SIM_OUTPUT_DIR" \
    -DCMAKE_CXX_COMPILER="$CLANG" \
    --log-level=WARNING

cmake --build "$SIM_BUILD_DIR" \
    --target install \
    --parallel \
    --config "$BUILD_TYPE"

echo "  ✓ $SIM_OUTPUT_DIR/libtonic_wrapper.dylib"

# Wrap in a proper framework bundle so Xcode can re-sign it on-device.
SIM_FW_DIR="$SIM_OUTPUT_DIR/tonic_wrapper.framework"
mkdir -p "$SIM_FW_DIR"
cp "$SIM_OUTPUT_DIR/libtonic_wrapper.dylib" "$SIM_FW_DIR/tonic_wrapper"
install_name_tool -id "@rpath/tonic_wrapper.framework/tonic_wrapper" \
    "$SIM_FW_DIR/tonic_wrapper"
cat > "$SIM_FW_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>tonic_wrapper</string>
    <key>CFBundleIdentifier</key>
    <string>dev.chillbro.tonic-wrapper</string>
    <key>CFBundleName</key>
    <string>tonic_wrapper</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>MinimumOSVersion</key>
    <string>$IOS_MIN_VERSION</string>
</dict>
</plist>
PLIST
echo "  ✓ $SIM_FW_DIR (framework bundle)"

# --- XCFramework ---
echo "--- Creating XCFramework ---"

XCFRAMEWORK_PATH="$IOS_OUTPUT/libtonic_wrapper.xcframework"
rm -rf "$XCFRAMEWORK_PATH"

xcodebuild -create-xcframework \
    -framework "$DEVICE_FW_DIR" \
    -framework "$SIM_FW_DIR" \
    -output "$XCFRAMEWORK_PATH"

echo "  ✓ $XCFRAMEWORK_PATH"

# --- Sign XCFramework slices ---
echo "--- Signing XCFramework ---"

codesign --force --sign "$IOS_SIGNING_IDENTITY" \
    "$XCFRAMEWORK_PATH/ios-arm64/tonic_wrapper.framework"
codesign --force --sign "$IOS_SIGNING_IDENTITY" \
    "$XCFRAMEWORK_PATH/ios-arm64-simulator/tonic_wrapper.framework"

echo "  ✓ XCFramework signed"

# Clean up intermediate slices — XCFramework contains everything
rm -rf "$DEVICE_OUTPUT_DIR"
rm -rf "$SIM_OUTPUT_DIR"
echo "  ✓ Intermediate slices removed"

# ---------------------------------------------------------------------------
# Symbol verification
# ---------------------------------------------------------------------------

echo ""
echo "=== Symbol verification ==="

# Android (llvm-nm)
LLVM_NM=""
for HOST in "darwin-x86_64" "linux-x86_64"; do
    CANDIDATE="$NDK_PATH/toolchains/llvm/prebuilt/$HOST/bin/llvm-nm"
    if [[ -f "$CANDIDATE" ]]; then
        LLVM_NM="$CANDIDATE"
        break
    fi
done

if [[ -n "$LLVM_NM" ]]; then
    echo "  Android arm64-v8a exports:"
    "$LLVM_NM" --defined-only -D "$ANDROID_OUTPUT/arm64-v8a/libtonic_wrapper.so" \
        | grep " T tonic_" | awk '{print "    " $3}'
fi

# iOS (nm from Xcode toolchain)
echo ""
echo "  iOS device exports:"
xcrun nm --defined-only --extern-only \
    "$XCFRAMEWORK_PATH/ios-arm64/tonic_wrapper.framework/tonic_wrapper" \
    | grep " T _tonic_" | awk '{print "    " $3}'

echo ""
echo "=== Done: $(date) ==="