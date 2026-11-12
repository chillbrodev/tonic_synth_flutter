# tonic_synth_flutter

A Flutter app wrapping the [Tonic](https://github.com/TonicAudio/Tonic) C++ audio synthesis library using Dart FFI, FFIGen, and Dart Build Hooks.  100% offline on-device audio generation.

Now available on [Google Play](https://play.google.com/store/apps/details?id=com.uptechstudio.tonic) and [Apple App Store](https://apps.apple.com/us/app/tonic-synths/id6781071843).
---

## What This Is

14 live synthesizers running in Flutter on Android and iOS, powered by a C++ audio engine accessed entirely through Dart FFI:

- **FM Drone** — FM synthesis with LFO modulation, controllable via vertical faders
- **XY Speed** — A filter synth driven by a 2D touch pad
- **Delay Sequencer** — Step sequencer with delay, adjustable tempo and envelope
- **Wavetable** — Arbitrary lookup oscillator with animated waveform visualizer
- **Bandlimited** — Crossfade between aliased and bandlimited square waves — hear the difference
- **Compressor** — 808-style snare through a compressor, with live transfer curve
- **Duck** — Sidechain compression demo with 120 BPM rhythm and DUCK pulse animation
- **Noise Filter** — Pink noise through a BPF bank, 2D drag pad controls cutoff and resonance
- **LF Noise** — Noise-modulated sine wave, controlled via a large rotary encoder
- **Reverb** — Click and tone source through a fully parametric reverb with room visualizer
- **Step Seq** — 8-step sequencer with per-step pitch and filter cutoff, drag to edit
- **Sine Sum** — 10 detuned sine waves swept via a jogwheel
- **Stereo Delay** — Panned stereo echo with animated delay tap visualizer
- **Snap to Scale** — Melodic step sequencer that quantises to a pentatonic scale

Record up to 60 seconds of audio from any synth and export as a WAV file via the system share sheet.

Audio is rendered in real-time by Tonic, streamed to the device speaker via `flutter_soloud`.

---

## Architecture

```
Tonic C++ (synth engine)
        ↓
tonic_wrapper.cpp  (extern "C" bridge — the FFI seam)
        ↓
CMakeLists.txt + build_native.sh  (NDK + Xcode cross-compile)
        ↓
native/libs/android/<ABI>/libtonic_wrapper.so
native/libs/ios/libtonic_wrapper.xcframework
        ↓
hook/build.dart  (DynamicLoadingBundled — no DynamicLibrary.open())
        ↓
tool/ffigen.dart  (@Native annotated bindings)
        ↓
lib/synths/  (typed Dart classes per synth)
        ↓
flutter_soloud  (PCM buffer → device speaker)
```

CMake is a **developer tool only**. The Flutter build system never invokes it — the hook bundles pre-built binaries.

---

## Prerequisites

- Flutter 3.44+
- Android NDK `28.2.13676358`
- CMake 3.18+
- Xcode 26.5+ (see [Xcode 26.5 compatibility notes](#xcode-265-compatibility))
- `ANDROID_NDK_HOME` set in your environment

---

## Building the Native Layer

```bash
./scripts/build_native.sh
```

Output:
```
native/libs/android/arm64-v8a/libtonic_wrapper.so
native/libs/android/armeabi-v7a/libtonic_wrapper.so
native/libs/android/x86_64/libtonic_wrapper.so
native/libs/ios/libtonic_wrapper.xcframework
```

Check `build/build.log` for full output.

### iOS Code Signing

The build script signs the XCFramework's `.framework` bundles using `IOS_SIGNING_IDENTITY`. For convenience, create `scripts/signing.env` (gitignored) with your identity:

```bash
IOS_SIGNING_IDENTITY="Apple Development: Your Name (XXXXXXXXXX)"
```

Find your identity with:

```bash
security find-identity -v -p codesigning
```

The default in `build_native.sh` is `-` (ad-hoc), which is sufficient for simulator. Device builds will have Xcode re-sign with your team certificate automatically — the pre-signing step just satisfies the XCFramework validation check.

---

## Regenerating FFI Bindings

Run this whenever `tonic_wrapper.h` changes:

```bash
dart run tool/ffigen.dart
```

Output: `lib/ffi/gen/tonic_native.g.dart`

---

## Running

```bash
flutter pub get
flutter run
```

---

## Xcode 26.5 Compatibility

Three breaking changes in Xcode 26.5 required fixes that are already applied to the project:

**1. XCFramework must use proper `.framework` bundles**
Xcode 26.5 tightened code-signature verification for embedded frameworks. The iOS native build now produces `tonic_wrapper.framework` bundles (binary + `Info.plist`) inside the XCFramework rather than bare dylibs. If you rebuild the native layer, `scripts/build_native.sh` handles this automatically.

**2. Post-signing plist mutation breaks device install (`0xe8008001`)**
A custom "Fix Framework MinimumOSVersion" build phase previously patched framework `Info.plist` files after Xcode had already signed them. Xcode 26.5 changed phase ordering so this now invalidates the code signature. The build phase has been removed. See [iOS framework minimum version](#ios-framework-minimum-version) below for how this affects `tonic_wrapper` and `App.framework`.

**3. Build output path changed**
Xcode 26.5 puts the built app in `${CONFIGURATION}-iphoneos/` (e.g. `Release-iphoneos/`) whereas Flutter 3.44 expects the flat `iphoneos/` path. A post-build script mirrors the `.app` to the expected location after signing.

---

## Project Structure

```
tonic_synth_flutter/
├── hook/
│   └── build.dart                  # Dart Build Hook — bundles binaries
├── tool/
│   └── ffigen.dart                 # Generates @Native FFI bindings
├── scripts/
│   └── build_native.sh             # Android + iOS build script
├── third_party/tonic/
│   ├── src/                        # Tonic C++ source
│   ├── tonic_wrapper.h             # Plain-C API (FFIGen entry point)
│   ├── tonic_wrapper.cpp           # C++ implementation
│   ├── tonic_wrapper.version       # Linker version script (Android)
│   ├── tonic_wrapper_ios.exp       # Exported symbols list (iOS)
│   └── CMakeLists.txt              # Build configuration
├── native/libs/
│   ├── android/                    # Pre-built .so files (committed)
│   │   ├── arm64-v8a/
│   │   ├── armeabi-v7a/
│   │   └── x86_64/
│   └── ios/
│       └── libtonic_wrapper.xcframework
└── lib/
    ├── ffi/gen/
    │   └── tonic_native.g.dart     # Auto-generated — do not edit
    ├── audio/
    │   └── wav_writer.dart         # PCM to WAV file writer
    ├── synths/
    │   ├── result/
    │   │   └── tonic_result.dart   # Sealed result type
    │   ├── tonic_synth_mixin.dart  # Shared audio/FFI/recording logic
    │   ├── fm_drone_synth.dart
    │   ├── xy_speed_synth.dart
    │   ├── delay_test_synth.dart
    │   └── ...                     # 11 more synth classes
    └── pages/
        ├── page_helpers.dart       # Shared UI helpers
        ├── launcher_page.dart      # 14-card synth grid
        └── ...                     # One page per synth
```

---

## Key Technical Details

### The FFI Seam

Tonic's C++ API uses operator overloading, templates, and namespaces — none of which FFIGen can parse. The wrapper flattens the entire API into `extern "C"` symbols:

```c
TonicSynth* tonic_create_fm_drone(void);
// ... 13 more factory functions
void        tonic_synth_destroy(TonicSynth* synth);
int         tonic_synth_set_parameter(TonicSynth*, const char*, float);
int         tonic_synth_fill_buffer(TonicSynth*, int8_t*, int, int);
void        tonic_set_sample_rate(float);
```

The C++ signal graph — FM modulation, ADSR chains, filter routing — never crosses the FFI boundary.

### Symbol Visibility

Android uses a linker version script (`tonic_wrapper.version`) to export only `tonic_*` symbols. iOS uses an exported symbols list (`tonic_wrapper_ios.exp`) with Apple ld's `_`-prefixed convention. Both ensure Tonic internals stay hidden from the dynamic symbol table.

### NDK 28 + `libc++`

NDK 28 moved `libc++_shared.so` for arm64 into API-level subdirectories and renamed it `libc++.so`. `package:android_libcpp_shared` 0.2.0 does not handle this correctly — the library is built with `ANDROID_STL=c++_static` to avoid the dependency entirely.

Issue filed: [dart-lang/native](https://github.com/dart-lang/native/issues)

### iOS: `Accelerate` Framework

Tonic uses `vDSP_*` SIMD intrinsics on Apple platforms, which live in `Accelerate.framework`. This is linked automatically via CMakeLists — no manual Xcode project changes needed.

### iOS Framework Minimum Version

The app's deployment target is iOS 15.6, but embedded frameworks (`tonic_wrapper.framework`, `App.framework`) declare `MinimumOSVersion = 13.0`. This is intentional and not a bug.

Flutter 3.44 hardcodes 13.0 in every framework plist it generates:
- `App.framework` — Flutter rewrites its plist using `FlutterDarwinPlatform.ios.deploymentTarget()`, which always returns `Version(13, 0, null)`.
- `tonic_wrapper.framework` — Flutter's native assets system has `const targetIOSVersion = 13` and uses it for all native asset framework plists ([flutter/flutter#145104](https://github.com/flutter/flutter/issues/145104)).

Because the plist cannot be patched after signing (see [Xcode 26.5 item 2](#xcode-265-compatibility)), the `tonic_wrapper` binary must be compiled with a matching minos. `build_native.sh` therefore uses `IOS_MIN_VERSION=13.0` for the iOS build, even though the app requires 15.6. Apple's upload validator requires plist `MinimumOSVersion` ≥ binary `minos`; a mismatch triggers rejection. The app's 15.6 deployment target still enforces the true install floor — no device on iOS < 15.6 can install the app regardless of framework minos values.

### `@Native` Annotations

FFIGen generates `@Native` annotated external functions — no `DynamicLibrary.open()` in Dart code. Symbols are resolved by the Dart asset system. The implicit `assetId` must match `CodeAsset.name` in `hook/build.dart` exactly:

```
package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart
```

## Checking Native Dependencies

`scripts/check_dependencies.sh` inspects the linked dependencies of the native
binaries bundled in this project — the iOS `.xcframework` and the Android
`.so` files — so you can quickly sanity-check what each platform's native
layer actually depends on.

### What it does

- **iOS**: runs `otool -L` against every architecture slice inside
  `libtonic_wrapper.xcframework` (`ios-arm64`, `ios-arm64-simulator`) and
  lists each binary's dynamic library dependencies.
- **Android**: runs `readelf -d | grep NEEDED` against `libtonic_wrapper.so`
  for each ABI in `native/libs/android` (`arm64-v8a`, `armeabi-v7a`,
  `x86_64`).

### Usage

```bash
./scripts/check_dependencies.sh
```

Exits non-zero if either platform check fails, so it's safe to drop into CI
as a sanity gate.

### Requirements

- **macOS + Xcode command line tools** for the iOS check (`otool`, `lipo`).
- **A `readelf`-compatible tool** for the Android check. The script
  auto-detects, in order:
  1. An explicit `READELF_BIN` override
  2. System `readelf` (Linux)
  3. Homebrew's `greadelf` (`brew install binutils`)
  4. The Android NDK's `llvm-readelf`, auto-discovered from `$ANDROID_HOME`
     or `$ANDROID_SDK_ROOT`, falling back to standard SDK install locations
     (`~/Library/Android/sdk`, `~/Android/Sdk`, etc.)

No machine-specific paths are hardcoded — this should work out of the box for
any contributor with a standard Android SDK/NDK install.

### Overriding defaults

```bash
IOS_XCFRAMEWORK=path/to/other.xcframework \
ANDROID_LIBS_DIR=path/to/other/libs \
ANDROID_SO_NAME=libother.so \
READELF_BIN=/path/to/llvm-readelf \
./scripts/check_dependencies.sh
```

### A note on iOS dependencies

The iOS check will normally list only public Apple system frameworks (e.g.
`Foundation`, `CoreFoundation`, `AudioToolbox`, `Accelerate`) and base system
libs (`libc++`, `libSystem`) — these ship with every iOS install via the dyld
shared cache, so their *presence* isn't a concern. What's worth verifying
separately is **API availability**: check the binary's minimum supported OS
version against the app's deployment target with:

```bash
otool -l <path-to-binary> | grep -A3 LC_BUILD_VERSION
```
