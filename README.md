# tonic_synth_flutter

A Flutter demo app wrapping the [Tonic](https://github.com/TonicAudio/Tonic) C++ audio synthesis library using Dart FFI, FFIGen, and Dart Build Hooks. Built as a companion project for the FlutterCon 2026 talk **"Hook, Line & Sinker: Dart Hooks"**.

---

## What This Is

14 live synthesizers running in Flutter on Android, powered by a C++ audio engine accessed entirely through Dart FFI:

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

Audio is rendered in real-time by Tonic, streamed to the device speaker via `flutter_soloud`.

---

## Architecture

```
Tonic C++ (synth engine)
        ↓
tonic_wrapper.cpp  (extern "C" bridge — the FFI seam)
        ↓
CMakeLists.txt + build_native.sh  (NDK cross-compile → .so)
        ↓
native/libs/android/<ABI>/libtonic_wrapper.so
        ↓
hook/build.dart  (DynamicLoadingBundled — no DynamicLibrary.open())
        ↓
tool/ffigen.dart  (@Native annotated bindings)
        ↓
lib/synths/  (typed Dart classes per synth)
        ↓
flutter_soloud  (PCM buffer → device speaker)
```

CMake is a **developer tool only**. The Flutter build system never invokes it — the hook bundles pre-built `.so` files.

---

## Prerequisites

- Flutter 3.44+
- Android NDK `28.2.13676358`
- CMake 3.18+
- `ANDROID_NDK_HOME` set in your environment

---

## Building the Native Layer

```bash
# Build .so files for all Android ABIs
./scripts/build_native.sh

# Output:
# native/libs/android/arm64-v8a/libtonic_wrapper.so
# native/libs/android/armeabi-v7a/libtonic_wrapper.so
# native/libs/android/x86_64/libtonic_wrapper.so

# Check build/build.log for full output
```

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

## Project Structure

```
tonic_synth_flutter/
├── hook/
│   └── build.dart                  # Dart Build Hook — bundles .so files
├── tool/
│   └── ffigen.dart                 # Generates @Native FFI bindings
├── scripts/
│   └── build_native.sh             # NDK cross-compile script
├── third_party/tonic/
│   ├── src/                        # Tonic C++ source
│   ├── tonic_wrapper.h             # Plain-C API (FFIGen entry point)
│   ├── tonic_wrapper.cpp           # C++ implementation
│   ├── tonic_wrapper.version       # Linker version script
│   └── CMakeLists.txt              # Build configuration
├── native/libs/android/            # Pre-built .so files (committed)
│   ├── arm64-v8a/
│   ├── armeabi-v7a/
│   └── x86_64/
└── lib/
    ├── ffi/gen/
    │   └── tonic_native.g.dart     # Auto-generated — do not edit
    ├── synths/
    │   ├── result/
    │   │   └── tonic_result.dart   # Sealed result type
    │   ├── tonic_synth_mixin.dart  # Shared audio/FFI logic
    │   ├── fm_drone_synth.dart
    │   ├── xy_speed_synth.dart
    │   └── delay_test_synth.dart
    └── pages/test_page/
        ├── synth_test_page.dart
        ├── fm_drone_page.dart
        ├── xy_speed_page.dart
        └── delay_test_page.dart
```

---

## Key Technical Details

### The FFI Seam

Tonic's C++ API uses operator overloading, templates, and namespaces — none of which FFIGen can parse. The wrapper flattens the entire API to 7 `extern "C"` symbols:

```c
TonicSynth* tonic_create_fm_drone(void);
TonicSynth* tonic_create_xy_speed(void);
TonicSynth* tonic_create_delay_test(void);
void        tonic_synth_destroy(TonicSynth* synth);
int         tonic_synth_set_parameter(TonicSynth*, const char*, float);
int         tonic_synth_fill_buffer(TonicSynth*, int8_t*, int, int);
void        tonic_set_sample_rate(float);
```

The C++ signal graph construction — FM modulation, ADSR chains, filter routing — never crosses the FFI boundary.

### Symbol Visibility

A linker version script (`tonic_wrapper.version`) ensures only `tonic_*` symbols are exported. Tonic internals stay hidden:

```
{ global: tonic_*; local: *; };
```

### NDK 28 + `libc++_shared`

NDK 28 moved `libc++_shared.so` for arm64 into API-level subdirectories and renamed it `libc++.so`. `package:android_libcpp_shared` 0.2.0 does not handle this — the library is built with `ANDROID_STL=c++_static` instead.

Issue filed: [dart-lang/native](https://github.com/dart-lang/native/issues)

### `@Native` Annotations

FFIGen generates `@Native` annotated external functions — no `DynamicLibrary.open()` in Dart code. Symbols are resolved by the Dart asset system. The implicit `assetId` on each annotation is:

```
package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart
```

This must match `CodeAsset.name` in `hook/build.dart` exactly.

---