// tonic_wrapper.cpp
//
// C++ implementation of the plain-C Tonic wrapper.
//
// Structure:
//   - One context struct per synth preset, each owning a Tonic::Synth
//     and its registered ControlParameters.
//   - A shared TonicSynthBase lets the runtime API (set_parameter,
//     fill_buffer, destroy) work through a single pointer type without
//     the C side ever knowing which preset it holds.
//   - Graph construction is verbatim from the Tonic demo synths —
//     this is intentional. The C++ side is the right place for it.

#include "tonic_wrapper.h"
#include "src/Tonic.h"

#include <cstring>
#include <map>
#include <string>

// ---------------------------------------------------------------------------
// Shared base — type-erased context behind every TonicSynth*
// ---------------------------------------------------------------------------

struct TonicSynth_s {
    Tonic::Synth synth;

    // Shadow map of registered parameters for O(log n) lookup from C.
    // Tonic stores them internally too, but going through the shadow map
    // avoids a linear scan of Tonic's parameter list on every set call.
    std::map<std::string, Tonic::ControlParameter> params;

    // Temporary float render buffer.
    // Sized on first use; reused across fill_buffer calls.
    std::vector<float> floatBuf;

    // Register a parameter and store it in the shadow map.
    Tonic::ControlParameter addParam(const std::string& name, float initial) {
        auto p = synth.addParameter(name, initial);
        params[name] = p;
        return p;
    }
};

// ---------------------------------------------------------------------------
// FMDroneSynth context
//
// Verbatim signal graph from examples/Demo Synths/FMDroneSynth.cpp.
// Parameters exposed to Dart: volume, carrierPitch, modIndex, lfoAmt
// ---------------------------------------------------------------------------

static TonicSynth_s* buildFMDrone() {
    using namespace Tonic;

    auto* ctx = new TonicSynth_s();

    ControlParameter volume       = ctx->addParam("volume",       -12.f);
    ControlParameter carrierPitch = ctx->addParam("carrierPitch",  28.f);
    ControlParameter modIndex     = ctx->addParam("modIndex",       0.25f);
    ControlParameter lfoAmt       = ctx->addParam("lfoAmt",         0.5f);

    Generator rCarrierFreq = ControlMidiToFreq().input(carrierPitch).smoothed();
    Generator rModFreq     = rCarrierFreq * 4.0f;

    Generator outputGen = SineWave()
        .freq( rCarrierFreq
            + (
                SineWave().freq( rModFreq ) *
                rModFreq *
                (modIndex.smoothed() * (1.0f + SineWave().freq(
                    (LFNoise().setFreq(0.5f) + 1.f) * 2.f + 0.2f
                ) * (lfoAmt * 0.5f).smoothed()))
              )
        ) * ControlDbToLinear().input(volume).smoothed()
          * ((SineWave().freq(0.15f) + 1.f) * 0.75f + 0.25f);

    ctx->synth.setOutputGen(outputGen);
    return ctx;
}

// ---------------------------------------------------------------------------
// XYSpeed context
//
// Verbatim signal graph from examples/Demo Synths/XYSpeed.cpp.
// Parameters exposed to Dart: x, y
// Maps naturally to a Flutter GestureDetector drag position.
// ---------------------------------------------------------------------------

static TonicSynth_s* buildXYSpeed() {
    using namespace Tonic;

    auto* ctx = new TonicSynth_s();

    ControlParameter x = ctx->addParam("x", 0.f);
    ControlParameter y = ctx->addParam("y", 0.f);

    Generator speed = ControlXYSpeed().x(x).y(y).smoothed();

    Generator outputGen = RectWave()
        .freq(100 + 20 * speed)
        .pwm(0.05f + (SineWave().freq(0.1f) + 1.f) * 0.2f)
        * SineWave().freq(1.f + 20.f * speed)
        >> LPF12().cutoff(100 + 6000 * speed)
        >> StereoDelay(0.1f, 0.15f).wetLevel(0.1f);

    ctx->synth.setOutputGen(outputGen);
    return ctx;
}

// ---------------------------------------------------------------------------
// DelayTestSynth context
//
// Verbatim signal graph from examples/Demo Synths/DelayTestSynth.cpp.
// Parameters exposed to Dart: tempo, delayTime, feedback, delayMix,
//                             decayTime, volume
// ---------------------------------------------------------------------------

static TonicSynth_s* buildDelayTest() {
    using namespace Tonic;

    auto* ctx = new TonicSynth_s();

    ControlParameter tempo     = ctx->addParam("tempo",     120.f);
    ControlParameter delayTime = ctx->addParam("delayTime",   0.12f);
    ControlParameter feedBack  = ctx->addParam("feedback",    0.4f);
    ControlParameter delayMix  = ctx->addParam("delayMix",    0.3f);
    ControlParameter decay     = ctx->addParam("decayTime",   0.08f);
    ControlParameter volume    = ctx->addParam("volume",     -6.f);

    ControlMetro metro = ControlMetro().bpm(tempo * 4);

    ADSR aEnv = ADSR()
        .attack(0.005f).decay(decay).sustain(0.0f).release(0.01f)
        .trigger(metro).doesSustain(false).exponential(true);
    ADSR fEnv = ADSR()
        .attack(0.005f).decay(decay).sustain(0.0f).release(0.01f)
        .trigger(metro).doesSustain(false).exponential(true);

    float scalenums[5] = {0, 3, 5, 7, 10};
    std::vector<float> scale(scalenums, scalenums + 5);

    ControlRandom rand       = ControlRandom().min(0).max(36).trigger(metro);
    ControlSnapToScale snap  = ControlSnapToScale().setScale(scale).input(rand);
    ControlMidiToFreq freq   = ControlMidiToFreq().input(48 + snap);

    Generator osc =
        (( RectWave().freq(freq * 0.99f).pwm(0.5f) * aEnv * 0.5f )
            >> MonoToStereoPanner().pan(-0.5f))
        +
        (( RectWave().freq(freq * 1.01f).pwm(0.5f) * aEnv * 0.5f )
            >> MonoToStereoPanner().pan(0.5f));

    LPF12 filt = LPF12()
        .cutoff(400.0f * (1.0f + fEnv * 9.0f))
        .Q(1.1f);

    Generator smoothMix = delayMix.smoothed();

    BasicDelay delay = BasicDelay(0.5f, 1.0f)
        .delayTime(delayTime.smoothed(0.5f))
        .feedback(feedBack.smoothed())
        .dryLevel(1.0f - smoothMix)
        .wetLevel(smoothMix);

    ctx->synth.setOutputGen(
        (osc >> filt >> delay) * ControlDbToLinear().input(volume).smoothed()
    );

    return ctx;
}

// ---------------------------------------------------------------------------
// extern "C" — the only surface FFIGen and Dart FFI ever see
// ---------------------------------------------------------------------------

void tonic_set_sample_rate(float sample_rate) {
    Tonic::setSampleRate(sample_rate);
}

TonicSynth* tonic_create_fm_drone(void)  { return buildFMDrone();  }
TonicSynth* tonic_create_xy_speed(void)  { return buildXYSpeed();  }
TonicSynth* tonic_create_delay_test(void){ return buildDelayTest(); }

void tonic_synth_destroy(TonicSynth* synth) {
    delete synth;
}

int tonic_synth_set_parameter(TonicSynth* synth,
                               const char* name,
                               float value) {
    if (!synth || !name) return -1;

    auto it = synth->params.find(std::string(name));
    if (it == synth->params.end()) return -1;

    synth->synth.setParameter(std::string(name), value);
    return 0;
}

int tonic_synth_fill_buffer(TonicSynth* synth,
                             int8_t*    out_buffer,
                             int        num_frames,
                             int        num_channels) {
    if (!synth || !out_buffer || num_frames <= 0 || num_channels <= 0) return -1;

    // Resize internal float buffer if needed.
    const int sampleCount = num_frames * num_channels;
    if (static_cast<int>(synth->floatBuf.size()) < sampleCount) {
        synth->floatBuf.resize(sampleCount);
    }

    synth->synth.fillBufferOfFloats(
        synth->floatBuf.data(),
        static_cast<unsigned int>(num_frames),
        static_cast<unsigned int>(num_channels)
    );

    // Reinterpret the float samples as bytes for the int8_t* caller.
    // PCM format: 32-bit IEEE 754 float, interleaved, native endian.
    std::memcpy(out_buffer,
                synth->floatBuf.data(),
                static_cast<size_t>(sampleCount) * sizeof(float));

    return num_frames;
}