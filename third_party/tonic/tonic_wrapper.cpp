// tonic_wrapper.cpp

#include "tonic_wrapper.h"
#include "src/Tonic.h"

#include <cstring>
#include <map>
#include <string>
#include <vector>
#include <cmath>

// ---------------------------------------------------------------------------
// Shared base
// ---------------------------------------------------------------------------

struct TonicSynth_s {
    Tonic::Synth synth;
    std::map<std::string, Tonic::ControlParameter> params;
    std::vector<float> floatBuf;

    Tonic::ControlParameter addParam(const std::string& name, float initial) {
        auto p = synth.addParameter(name, initial);
        params[name] = p;
        return p;
    }
};

// ---------------------------------------------------------------------------
// Original three synths
// ---------------------------------------------------------------------------

static TonicSynth_s* buildFMDrone() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto volume       = ctx->addParam("volume",       -12.f);
    auto carrierPitch = ctx->addParam("carrierPitch",  28.f);
    auto modIndex     = ctx->addParam("modIndex",       0.25f);
    auto lfoAmt       = ctx->addParam("lfoAmt",         0.5f);

    Generator rCarrierFreq = ControlMidiToFreq().input(carrierPitch).smoothed();
    Generator rModFreq     = rCarrierFreq * 4.0f;

    Generator outputGen = SineWave()
        .freq(rCarrierFreq + (
            SineWave().freq(rModFreq) * rModFreq *
            (modIndex.smoothed() * (1.0f + SineWave().freq(
                (LFNoise().setFreq(0.5f) + 1.f) * 2.f + 0.2f
            ) * (lfoAmt * 0.5f).smoothed()))
        )) * ControlDbToLinear().input(volume).smoothed()
           * ((SineWave().freq(0.15f) + 1.f) * 0.75f + 0.25f);

    ctx->synth.setOutputGen(outputGen);
    return ctx;
}

static TonicSynth_s* buildXYSpeed() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto x = ctx->addParam("x", 0.f);
    auto y = ctx->addParam("y", 0.f);

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

static TonicSynth_s* buildDelayTest() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto tempo     = ctx->addParam("tempo",     120.f);
    auto delayTime = ctx->addParam("delayTime",   0.12f);
    auto feedBack  = ctx->addParam("feedback",    0.4f);
    auto delayMix  = ctx->addParam("delayMix",    0.3f);
    auto decay     = ctx->addParam("decayTime",   0.08f);
    auto volume    = ctx->addParam("volume",     -6.f);

    ControlMetro metro = ControlMetro().bpm(tempo * 4);

    ADSR aEnv = ADSR().attack(0.005f).decay(decay).sustain(0.f).release(0.01f)
        .trigger(metro).doesSustain(false).exponential(true);
    ADSR fEnv = ADSR().attack(0.005f).decay(decay).sustain(0.f).release(0.01f)
        .trigger(metro).doesSustain(false).exponential(true);

    float scalenums[5] = {0, 3, 5, 7, 10};
    std::vector<float> scale(scalenums, scalenums + 5);

    ControlRandom rand      = ControlRandom().min(0).max(36).trigger(metro);
    ControlSnapToScale snap = ControlSnapToScale().setScale(scale).input(rand);
    ControlMidiToFreq freq  = ControlMidiToFreq().input(48 + snap);

    Generator osc =
        ((RectWave().freq(freq * 0.99f).pwm(0.5f) * aEnv * 0.5f)
            >> MonoToStereoPanner().pan(-0.5f))
        + ((RectWave().freq(freq * 1.01f).pwm(0.5f) * aEnv * 0.5f)
            >> MonoToStereoPanner().pan(0.5f));

    LPF12 filt  = LPF12().cutoff(400.f * (1.f + fEnv * 9.f)).Q(1.1f);
    Generator smoothMix = delayMix.smoothed();
    BasicDelay delay = BasicDelay(0.5f, 1.f)
        .delayTime(delayTime.smoothed(0.5f))
        .feedback(feedBack.smoothed())
        .dryLevel(1.f - smoothMix)
        .wetLevel(smoothMix);

    ctx->synth.setOutputGen(
        (osc >> filt >> delay) * ControlDbToLinear().input(volume).smoothed());
    return ctx;
}

// ---------------------------------------------------------------------------
// New synths
// ---------------------------------------------------------------------------

static TonicSynth_s* buildArbitraryTable() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    const unsigned int tablesize = 2500;
    SampleTable lookupTable = SampleTable(tablesize, 1);
    TonicFloat norm = 1.0f / tablesize;
    TonicFloat* tableData = lookupTable.dataPointer();
    for (unsigned int i = 0; i < tablesize; i++) {
        TonicFloat phase = TWO_PI * i * norm;
        *tableData++ = 0.75f * sinf(phase)
                     + 0.5f  * sinf(phase * 2)
                     + 0.25f * sinf(phase * 5);
    }

    TableLookupOsc osc = TableLookupOsc()
        .setLookupTable(lookupTable)
        .freq(100 + 40 * SineWave().freq(0.1f));

    ctx->synth.setOutputGen(osc * 0.25f);
    return ctx;
}

static TonicSynth_s* buildBandlimitedOsc() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto blend = ctx->addParam("blend", 0.5f);

    Generator freqSweep   = SineWave().freq(0.25f) * 1000 + 1080;
    Generator smoothBlend = blend.smoothed();

    Generator output =
        (SquareWave().freq(freqSweep)   * (1.0f - smoothBlend)) +
        (SquareWaveBL().freq(freqSweep) * smoothBlend);

    ctx->synth.setOutputGen(output * 0.25f);
    return ctx;
}

static TonicSynth_s* buildCompressorTest() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto threshold = ctx->addParam("threshold", -12.f);
    auto ratio     = ctx->addParam("ratio",       2.f);
    auto attack    = ctx->addParam("attackTime",  0.001f);
    auto release   = ctx->addParam("releaseTime", 0.05f);
    auto gain      = ctx->addParam("gain",        0.f);
    auto bypass    = ctx->addParam("bypass",      0.f);

    Generator hpNoise = (Noise() * dBToLin(-18.0))
        >> HPF24().cutoff(2000.f)
        >> LPF12().cutoff(8000.f);
    Generator tones = SineWave().freq(180) * dBToLin(-6.0)
                    + SineWave().freq(332) * dBToLin(-18.0);

    ControlGenerator snareGate = ControlPulse(60.0 * 0.8 / 80.0)
        .trigger(ControlMetro(80));
    ADSR toneADSR  = ADSR(0.0005f, 0.03f, 0.f, 0.01f).trigger(snareGate);
    ADSR noiseADSR = ADSR(0.001f,  0.25f, 0.f, 0.25f).trigger(snareGate);
    Generator noiseEnv = noiseADSR * noiseADSR;

    Compressor compressor = Compressor()
        .attack(attack)
        .release(release)
        .threshold(ControlDbToLinear().input(threshold))
        .ratio(ratio)
        .lookahead(0.001f)
        .makeupGain(ControlDbToLinear().input(gain))
        .bypass(bypass);

    Generator outputGen =
        (((tones * toneADSR) + (hpNoise * noiseEnv)) >> compressor) * 0.5f;

    ctx->synth.setOutputGen(outputGen);
    return ctx;
}

static TonicSynth_s* buildCompressorDucking() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto compRelease = ctx->addParam("compRelease", 0.025f);

    Generator hpNoise = (Noise() * dBToLin(-18.0))
        >> HPF24().cutoff(2000.f)
        >> LPF12().cutoff(8000.f);
    Generator tones = SineWave().freq(180) * dBToLin(-6.0)
                    + SineWave().freq(332) * dBToLin(-18.0);

    ControlMetro metro   = ControlMetro(120);
    ControlGenerator snareGate = ControlPulse(60.0 * 0.8 / 120.0).trigger(metro);
    ADSR toneADSR  = ADSR(0.0005f, 0.03f, 0.f, 0.01f).trigger(snareGate);
    ADSR noiseADSR = ADSR(0.001f,  0.25f, 0.f, 0.25f).trigger(snareGate);
    Generator noiseEnv = noiseADSR * noiseADSR;

    Compressor duckingComp = Compressor()
        .attack(0.001f)
        .release(compRelease)
        .threshold(dBToLin(-52))
        .ratio(16)
        .lookahead(0.001f);

    float bassScaleArr[4] = {0, 7, 10, 12};
    std::vector<float> bassScale(bassScaleArr, bassScaleArr + 4);

    Generator baseFreq = ((30 + (ControlRandom().min(0).max(12).trigger(metro)
        >> ControlSnapToScale().setScale(bassScale)))
        >> ControlMidiToFreq()).smoothed();

    ADSR bassFiltADSR = ADSR(0.005f, 0.1f, 0.f, 0.05f)
        .doesSustain(false).legato(true).trigger(metro);

    Generator randomBass = (RectWave().freq(baseFreq) * 0.5f)
        >> LPF24().cutoff(300 * (1 + bassFiltADSR * 2)
            * (1 + ((SineWave().freq(0.1f) + 1) * 0.5f))).Q(1.5f);

    StereoDelay delay = StereoDelay(0.37f, 0.38f)
        .feedback(0.4f).dryLevel(0.8f).wetLevel(0.2f);

    Generator snare = (tones * toneADSR) + (hpNoise * noiseEnv);

    ctx->synth.setOutputGen(
        duckingComp.audioInput(randomBass >> delay).sidechainInput(snare)
        + snare * 0.5f);
    return ctx;
}

static TonicSynth_s* buildFilteredNoise() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto cutoffCtrl = ctx->addParam("cutoff", 0.5f);
    auto q_v        = ctx->addParam("Q",      5.f);

    std::vector<float> midiNums = {-24.f, 0.f, 3.f, 7.f, 10.f};
    const float cutoffMult = 100.f;

    PinkNoise noise = PinkNoise();
    Generator q_smooth = q_v.smoothed();

    Adder sumOfFilters;
    for (int i = 0; i < (int)midiNums.size(); i++) {
        Generator tremelo = (SineWave().freq(0.1f + i * 0.05f) + 1.5f) * 0.3f;
        Generator cutoff  = ControlMidiToFreq().input(
            ControlFloor().input(midiNums[i] + cutoffCtrl * cutoffMult)
        ).smoothed().length(0.01f);
        BPF24 filter = BPF24().Q(q_smooth).cutoff(cutoff).normalizesGain(true);
        sumOfFilters.input((noise >> filter) * tremelo);
    }

    ctx->synth.setOutputGen(sumOfFilters * (1 + q_smooth * 0.05f));
    return ctx;
}

static TonicSynth_s* buildLFNoise() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto noiseFreq = ctx->addParam("noiseFreq", 100.f);

    Generator outputGen = SineWave()
        .freq(500 + 500 * LFNoise().setFreq(noiseFreq)) * 0.3f;

    ctx->synth.setOutputGen(outputGen);
    return ctx;
}

static TonicSynth_s* buildReverbTest() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto dry      = ctx->addParam("dry",      -6.f);
    auto wet      = ctx->addParam("wet",     -20.f);
    auto time     = ctx->addParam("decayTime",  1.f);
    auto lowDecay = ctx->addParam("lowDecay", 16000.f);
    auto hiDecay  = ctx->addParam("hiDecay",    20.f);
    auto preDelay = ctx->addParam("preDelay",  0.001f);
    auto inputLPF = ctx->addParam("inputLPF", 18000.f);
    auto inputHPF = ctx->addParam("inputHPF",    20.f);
    auto density  = ctx->addParam("density",    0.5f);
    auto shape    = ctx->addParam("shape",      0.5f);
    auto size     = ctx->addParam("size",       0.5f);
    auto stereo   = ctx->addParam("stereo",     0.5f);

    float bpm = 30.f;
    ControlMetro beat    = ControlMetro().bpm(bpm);
    ControlDelay offbeat = ControlDelay(1.2f).input(beat).delayTime(30.f / bpm);

    Generator click = Noise()
        * ADSR(0.0001f, 0.025f, 0.f, 0.01f)
          .doesSustain(false).exponential(true).trigger(beat);

    Generator tone = RectWave().pwm(0.5f).freq(Tonic::mtof(60))
        * ADSR(0.001f, 0.08f, 0.f, 0.01f)
          .doesSustain(false).exponential(true).trigger(offbeat);

    Reverb reverb = Reverb()
        .preDelayTime(preDelay)
        .inputLPFCutoff(inputLPF)
        .inputHPFCutoff(inputHPF)
        .decayTime(time)
        .decayLPFCutoff(lowDecay)
        .decayHPFCutoff(hiDecay)
        .stereoWidth(stereo)
        .density(density)
        .roomShape(shape)
        .roomSize(size)
        .dryLevel(ControlDbToLinear().input(dry))
        .wetLevel(ControlDbToLinear().input(wet));

    ctx->synth.setOutputGen(((click + tone) >> reverb) * 0.8f);
    return ctx;
}

static TonicSynth_s* buildStepSeq() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto tempo     = ctx->addParam("tempo",     100.f);
    auto transpose = ctx->addParam("transpose",   0.f);

    ControlGenerator metro = ControlMetro().bpm(4 * tempo);
    ControlGenerator step  = ControlStepper().end(8).trigger(metro);

    ControlSwitcher pitches = ControlSwitcher().inputIndex(step);
    ControlSwitcher cutoffs = ControlSwitcher().inputIndex(step);

    float initialPitches[8] = {48, 52, 55, 48, 60, 55, 52, 43};
    float initialCutoffs[8] = {500, 800, 300, 1200, 400, 900, 600, 200};

    for (int i = 0; i < 8; i++) {
        pitches.addInput(ctx->addParam("step" + std::to_string(i) + "Pitch",
                                       initialPitches[i]));
        cutoffs.addInput(ctx->addParam("step" + std::to_string(i) + "Cutoff",
                                       initialCutoffs[i]));
    }

    ControlGenerator midiNote = transpose
        + (pitches >> ControlSnapToScale().setScale({0, 2, 3, 5, 7, 10}));

    Generator outputGen = SquareWave().freq(midiNote >> ControlMidiToFreq())
        * ADSR(0.01f, 0.1f, 0.f, 0.f).trigger(metro) * 0.1f;
    outputGen = outputGen >> LPF24().cutoff(cutoffs).Q(0.1f);

    ctx->synth.setOutputGen(outputGen);
    return ctx;
}

static TonicSynth_s* buildSineSum() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto pitch = ctx->addParam("pitch", 0.f);

    const int NUM_SINES = 10;
    Adder outputAdder;

    for (int s = 0; s < NUM_SINES; s++) {
        ControlGenerator pitchGen =
            ((pitch * 220 + 220) * powf(2.f, (s - NUM_SINES / 2) * 5.f / 12.f));
        outputAdder.input(SineWave().freq(pitchGen.smoothed()));
    }

    ctx->synth.setOutputGen(outputAdder * ((1.f / NUM_SINES) * 0.5f));
    return ctx;
}

static TonicSynth_s* buildStereoDelay() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto freq      = ctx->addParam("freq",                  0.f);
    auto freqRand  = ctx->addParam("frequencyRandomAmount", 0.5f);
    auto decay     = ctx->addParam("decay",                 0.5f);

    ControlMetro metro    = ControlMetro().bpm(100);
    ControlGenerator randFreq = ControlRandom().trigger(metro).min(0).max(1);

    Generator tone = RectWave()
        .freq(randFreq * freqRand + 100 + freq)
        * SineWave().freq(50);

    ADSR env = ADSR().attack(0.01f).decay(decay).sustain(0.f).release(0.f)
        .doesSustain(false).trigger(metro);

    StereoDelay delay = StereoDelay(3.f, 3.f)
        .delayTimeLeft( 0.5f + SineWave().freq(0.2f)  * 0.01f)
        .delayTimeRight(0.55f + SineWave().freq(0.23f) * 0.01f)
        .feedback(0.3f).dryLevel(0.8f).wetLevel(0.2f);

    Generator filterFreq = (SineWave().freq(0.01f) + 1) * 200 + 225;
    LPF24 filter = LPF24().Q(2).cutoff(filterFreq);

    ctx->synth.setOutputGen(filter.input(delay.input(tone * env)) * 0.3f);
    return ctx;
}

static TonicSynth_s* buildSnapToScale() {
    using namespace Tonic;
    auto* ctx = new TonicSynth_s();

    auto speed         = ctx->addParam("speed",         0.85f);
    auto stepperStart  = ctx->addParam("stepperStart",   0.5f);
    auto stepperSpread = ctx->addParam("stepperSpread",  0.5f);

    float scaleArr[5] = {0, 2, 3, 7, 10};
    std::vector<float> scale(scaleArr, scaleArr + 5);

    ControlMetro switchIt = ControlMetro().bpm(30 * speed);
    ControlMetro metro    = ControlMetro().bpm(
        ControlStepper().bidirectional(1).start(550).end(650).step(100)
            .trigger(switchIt) * speed);

    ADSR env = ADSR(0.01f, 0.5f, 0.f, 0.f)
        .trigger(metro).doesSustain(false).legato(true)
        .decay(ControlStepper().start(0.05f).end(0.5f).step(0.01f).trigger(metro));

    ControlGenerator start  = stepperStart * 30 + 43;
    ControlGenerator spread = stepperSpread * 50;

    ControlStepper stepper = ControlStepper().bidirectional(1)
        .start(start).end(start + spread).step(4).trigger(metro);

    ControlSnapToScale scaleSnapper = ControlSnapToScale()
        .setScale(scale).input(stepper);

    Generator delayMix = ControlRandom().min(0).max(0.1f)
        .trigger(switchIt).smoothed();

    Reverb verb = Reverb().inputHPFCutoff(200.f).decayTime(0.8f)
        .roomSize(0.1f).density(0.8f).wetLevel(dBToLin(-30.f));

    Generator outputGen = ((
        SineWave().freq(
            ControlMidiToFreq().input(scaleSnapper + -12).smoothed()
        )
        + SineWave().freq(ControlMidiToFreq().input(scaleSnapper + 12)) * 0.1f
    ) * 0.3f * env)
    >> StereoDelay(0.3f, 0.33f).feedback(0.3f)
        .dryLevel(1.f - delayMix).wetLevel(delayMix)
    >> verb;

    ctx->synth.setOutputGen(outputGen);
    return ctx;
}

// ---------------------------------------------------------------------------
// extern "C" API
// ---------------------------------------------------------------------------

void tonic_set_sample_rate(float sample_rate) {
    Tonic::setSampleRate(sample_rate);
}

TonicSynth* tonic_create_fm_drone(void)         { return buildFMDrone();         }
TonicSynth* tonic_create_xy_speed(void)         { return buildXYSpeed();         }
TonicSynth* tonic_create_delay_test(void)       { return buildDelayTest();       }
TonicSynth* tonic_create_arbitrary_table(void)  { return buildArbitraryTable();  }
TonicSynth* tonic_create_bandlimited_osc(void)  { return buildBandlimitedOsc();  }
TonicSynth* tonic_create_compressor_test(void)  { return buildCompressorTest();  }
TonicSynth* tonic_create_compressor_ducking(void){ return buildCompressorDucking(); }
TonicSynth* tonic_create_filtered_noise(void)   { return buildFilteredNoise();   }
TonicSynth* tonic_create_lf_noise(void)         { return buildLFNoise();         }
TonicSynth* tonic_create_reverb_test(void)      { return buildReverbTest();      }
TonicSynth* tonic_create_step_seq(void)         { return buildStepSeq();         }
TonicSynth* tonic_create_sine_sum(void)         { return buildSineSum();         }
TonicSynth* tonic_create_stereo_delay(void)     { return buildStereoDelay();     }
TonicSynth* tonic_create_snap_to_scale(void)    { return buildSnapToScale();     }

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

    const int sampleCount = num_frames * num_channels;
    if ((int)synth->floatBuf.size() < sampleCount)
        synth->floatBuf.resize(sampleCount);

    synth->synth.fillBufferOfFloats(
        synth->floatBuf.data(),
        static_cast<unsigned int>(num_frames),
        static_cast<unsigned int>(num_channels));

    std::memcpy(out_buffer, synth->floatBuf.data(),
                sampleCount * sizeof(float));
    return num_frames;
}