#!/usr/bin/env bash
# scripts/build_native.sh
set -euo pipefail

NDK_PATH="${NDK_HOME:-/Users/uptech/android/ndk/28.2.13676358}"
ANDROID_PLATFORM="android-24"
# c++_static: STL compiled directly into libtonic_wrapper.so.
# NDK 28 broke c++_shared for arm64 — libc++_shared.so moved into API-level
# subdirectories and was renamed libc++.so. c++_static avoids this entirely.
# hook/build.dart bundles libc++.so from the NDK sysroot separately so the
# talk still demonstrates the dependency bundling story.
ANDROID_STL="c++_static"
BUILD_TYPE="Release"
ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TONIC_DIR="$PROJECT_ROOT/third_party/tonic"
OUTPUT_BASE="$PROJECT_ROOT/native/libs/android"
BUILD_DIR="$PROJECT_ROOT/build/android"
LOG_FILE="$PROJECT_ROOT/build/build.log"

mkdir -p "$PROJECT_ROOT/build"
: > "$LOG_FILE"
exec > "$LOG_FILE" 2>&1

echo "=== tonic_synth_flutter: build native ==="
echo "  Started:  $(date)"
echo ""
echo "  NDK:      $NDK_PATH"
echo "  Platform: $ANDROID_PLATFORM"
echo "  STL:      $ANDROID_STL"
echo "  ABIs:     ${ABIS[*]}"
echo "  Log:      $LOG_FILE"
echo ""

if [[ ! -d "$NDK_PATH" ]]; then
    echo "ERROR: NDK not found at: $NDK_PATH"
    exit 1
fi

TOOLCHAIN="$NDK_PATH/build/cmake/android.toolchain.cmake"
if [[ ! -f "$TOOLCHAIN" ]]; then
    echo "ERROR: NDK toolchain file not found at: $TOOLCHAIN"
    exit 1
fi

for ABI in "${ABIS[@]}"; do
    echo "--- Building $ABI ---"

    ABI_BUILD_DIR="$BUILD_DIR/$ABI"
    ABI_OUTPUT_DIR="$OUTPUT_BASE/$ABI"

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

echo ""
echo "=== Symbol verification ==="

LLVM_NM=""
for HOST in "darwin-x86_64" "linux-x86_64"; do
    CANDIDATE="$NDK_PATH/toolchains/llvm/prebuilt/$HOST/bin/llvm-nm"
    if [[ -f "$CANDIDATE" ]]; then
        LLVM_NM="$CANDIDATE"
        break
    fi
done

if [[ -z "$LLVM_NM" ]]; then
    echo "  WARNING: llvm-nm not found in NDK — skipping symbol check"
else
    SO="$OUTPUT_BASE/arm64-v8a/libtonic_wrapper.so"
    echo "  Exported tonic_* symbols (arm64-v8a):"
    "$LLVM_NM" --defined-only -D "$SO" \
        | grep " T tonic_" \
        | awk '{print "    " $3}'

    echo ""
    echo "  Confirming no Tonic:: internals leaked:"
    LEAKED=$("$LLVM_NM" --defined-only -D "$SO" \
        | grep " T " \
        | grep -v " T tonic_" || true)
    if [[ -z "$LEAKED" ]]; then
        echo "    ✓ No internal symbols exported"
    else
        echo "    WARNING: unexpected exports:"
        echo "$LEAKED" | awk '{print "      " $0}'
    fi
fi

echo ""
echo "=== Done: $(date) ==="