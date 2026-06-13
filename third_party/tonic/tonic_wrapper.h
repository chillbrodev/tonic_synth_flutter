// tonic_wrapper.h
//
// Plain-C interface to the Tonic audio synthesis library.
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
//   FM Drone:           "volume" "carrierPitch" "modIndex" "lfoAmt"
//   XY Speed:           "x" "y"
//   Delay Test:         "tempo" "delayTime" "feedback" "delayMix" "decayTime" "volume"
//   Arbitrary Table:    (none — autonomous)
//   Bandlimited Osc:    "blend"
//   Compressor Test:    "threshold" "ratio" "attackTime" "releaseTime" "gain" "bypass"
//   Compressor Ducking: "compRelease"
//   Filtered Noise:     "cutoff" "Q"
//   LF Noise:           "noiseFreq"
//   Reverb Test:        "dry" "wet" "decayTime" "lowDecay" "hiDecay" "preDelay"
//                       "inputLPF" "inputHPF" "density" "shape" "size" "stereo"
//   Step Seq:           "tempo" "transpose"
//                       "step0Pitch".."step7Pitch" "step0Cutoff".."step7Cutoff"
//   Sine Sum:           "pitch"
//   Stereo Delay:       "freq" "frequencyRandomAmount" "decay"
//   Snap To Scale:      "speed" "stepperStart" "stepperSpread"

#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// Opaque handle
// ---------------------------------------------------------------------------

typedef struct TonicSynth_s TonicSynth;

// ---------------------------------------------------------------------------
// Global config
// ---------------------------------------------------------------------------

/// Set the global Tonic sample rate. Default is 44100 Hz.
void tonic_set_sample_rate(float sample_rate);

// ---------------------------------------------------------------------------
// Factory functions
// ---------------------------------------------------------------------------

/// FM drone synth.
/// Parameters: "volume" (-60..0 dBFS), "carrierPitch" (MIDI 20..32),
///             "modIndex" (0..1), "lfoAmt" (0..1)
TonicSynth* tonic_create_fm_drone(void);

/// XY speed-controlled filter synth.
/// Parameters: "x" (0..1), "y" (0..1)
TonicSynth* tonic_create_xy_speed(void);

/// Delay + step-sequencer synth.
/// Parameters: "tempo" (60..300 BPM), "delayTime" (0.001..1.0 s),
///             "feedback" (0..0.95), "delayMix" (0..1),
///             "decayTime" (0.05..0.25 s), "volume" (-60..0 dBFS)
TonicSynth* tonic_create_delay_test(void);

/// Arbitrary wavetable oscillator. No parameters — autonomous.
TonicSynth* tonic_create_arbitrary_table(void);

/// Bandlimited oscillator blend demo.
/// Parameters: "blend" (0=aliased .. 1=bandlimited)
TonicSynth* tonic_create_bandlimited_osc(void);

/// Compressor demo with 808-style snare source.
/// Parameters: "threshold" (-60..0 dBFS), "ratio" (1..64),
///             "attackTime" (0.001..0.1 s), "releaseTime" (0.01..0.08 s),
///             "gain" (0..36 dBFS), "bypass" (0=off 1=on)
TonicSynth* tonic_create_compressor_test(void);

/// Compressor ducking demo — autonomous rhythm.
/// Parameters: "compRelease" (0.01..0.5 s)
TonicSynth* tonic_create_compressor_ducking(void);

/// Filtered pink noise synth.
/// Parameters: "cutoff" (0..1), "Q" (0..10)
TonicSynth* tonic_create_filtered_noise(void);

/// LF noise-modulated sine synth.
/// Parameters: "noiseFreq" (1..500 Hz)
TonicSynth* tonic_create_lf_noise(void);

/// Reverb test synth — click/tone source through reverb.
/// Parameters: "dry" (-60..0 dBFS), "wet" (-60..0 dBFS),
///             "decayTime" (0.1..10 s), "lowDecay" (4000..20000 Hz),
///             "hiDecay" (20..250 Hz), "preDelay" (0.001..0.05 s),
///             "inputLPF" (4000..20000 Hz), "inputHPF" (20..250 Hz),
///             "density" (0..1), "shape" (0..1), "size" (0..1), "stereo" (0..1)
TonicSynth* tonic_create_reverb_test(void);

/// 8-step sequencer with per-step pitch and filter cutoff.
/// Parameters: "tempo" (50..300 BPM), "transpose" (-6..6),
///             "step0Pitch".."step7Pitch" (10..80 MIDI),
///             "step0Cutoff".."step7Cutoff" (30..1500 Hz)
TonicSynth* tonic_create_step_seq(void);

/// Sine additive synth — 10 detuned sine waves.
/// Parameters: "pitch" (0..1, sweeps chord stack)
TonicSynth* tonic_create_sine_sum(void);

/// Stereo delay with random frequency source.
/// Parameters: "freq" (0..500 Hz offset), "frequencyRandomAmount" (0..1),
///             "decay" (0..2 s)
TonicSynth* tonic_create_stereo_delay(void);

/// Scale-snapping melodic sequencer.
/// Parameters: "speed" (0..2), "stepperStart" (0..1), "stepperSpread" (0..1)
TonicSynth* tonic_create_snap_to_scale(void);

// ---------------------------------------------------------------------------
// Shared runtime API
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