// tonic_wrapper.h
//
// Plain-C interface to the Tonic audio synthesis library.
//
// Why does this exist?
// Tonic's API is pure C++ — namespaces, templates, operator overloading,
// shared smart pointers. FFIGen cannot parse any of it. This file flattens
// three concrete synth graphs into extern "C" symbols that FFIGen can see
// and Dart FFI can call without knowing C++ exists.
//
// Design principles:
//   - Opaque handle (TonicSynth*) — FFIGen emits a proper Opaque subclass
//   - Factory per synth — graph construction stays entirely in C++
//   - Shared runtime API — set_parameter / fill_buffer work on any handle
//   - int8_t* PCM buffer — matches Dart's typed data conventions
//   - int return codes — 0 = success, negative = error, Dart decides what to do
//
// Parameters per synth:
//
//   FM Drone:     "volume" "carrierPitch" "modIndex" "lfoAmt"
//   XY Speed:     "x" "y"
//   Delay Test:   "tempo" "delayTime" "feedback" "delayMix" "decayTime" "volume"

#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// Opaque handle
//
// Forward-declared struct — never defined in C. FFIGen generates:
//   final class TonicSynth extends Opaque {}
// All functions take Pointer<TonicSynth>, giving Dart type safety.
// ---------------------------------------------------------------------------

typedef struct TonicSynth_s TonicSynth;

// ---------------------------------------------------------------------------
// Global config — call before creating any synth
// ---------------------------------------------------------------------------

/// Set the global Tonic sample rate. Default is 44100 Hz.
void tonic_set_sample_rate(float sample_rate);

// ---------------------------------------------------------------------------
// Factory functions — one per synth preset
//
// Each factory constructs the full Tonic signal graph internally.
// Dart never sees operator overloading, templates, or C++ classes.
// Caller owns the returned pointer; must call tonic_synth_destroy().
// ---------------------------------------------------------------------------

/// FM drone synth.
/// Parameters: "volume" (-60..0 dBFS), "carrierPitch" (MIDI 20..32),
///             "modIndex" (0..1), "lfoAmt" (0..1)
TonicSynth* tonic_create_fm_drone(void);

/// XY speed-controlled filter synth.
/// Parameters: "x" (0..1), "y" (0..1)
/// Map a Flutter drag gesture directly to these two values.
TonicSynth* tonic_create_xy_speed(void);

/// Delay + step-sequencer synth.
/// Parameters: "tempo" (60..300 BPM), "delayTime" (0.001..1.0 s),
///             "feedback" (0..0.95), "delayMix" (0..1),
///             "decayTime" (0.05..0.25 s), "volume" (-60..0 dBFS)
TonicSynth* tonic_create_delay_test(void);

// ---------------------------------------------------------------------------
// Shared runtime API — works on any TonicSynth*
// ---------------------------------------------------------------------------

/// Destroy a synth and free all associated resources.
void tonic_synth_destroy(TonicSynth* synth);

/// Set a named parameter by value.
/// Returns  0 on success.
/// Returns -1 if the parameter name is not registered on this synth.
int tonic_synth_set_parameter(TonicSynth* synth,
                               const char* name,
                               float value);

/// Render audio into a caller-allocated int8_t buffer.
/// The buffer must be at least num_frames * num_channels * sizeof(float) bytes.
/// PCM format: 32-bit float, interleaved channels, native endian.
/// Returns the number of frames written, or -1 on error.
int tonic_synth_fill_buffer(TonicSynth* synth,
                             int8_t*    out_buffer,
                             int        num_frames,
                             int        num_channels);

#ifdef __cplusplus
}
#endif