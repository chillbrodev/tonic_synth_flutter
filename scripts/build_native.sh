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
IOS_MIN_VERSION="16.0"

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
echo "  Min version: $IOS_MIN_VERSION"
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

# --- XCFramework ---
echo "--- Creating XCFramework ---"

XCFRAMEWORK_PATH="$IOS_OUTPUT/libtonic_wrapper.xcframework"

# Remove stale XCFramework if present
rm -rf "$XCFRAMEWORK_PATH"

xcodebuild -create-xcframework \
    -library "$DEVICE_OUTPUT_DIR/libtonic_wrapper.dylib" \
    -library "$SIM_OUTPUT_DIR/libtonic_wrapper.dylib" \
    -output "$XCFRAMEWORK_PATH"

echo "  ✓ $XCFRAMEWORK_PATH"

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
    "$DEVICE_OUTPUT_DIR/libtonic_wrapper.dylib" \
    | grep " T _tonic_" | awk '{print "    " $3}'

echo ""
echo "=== Done: $(date) ==="