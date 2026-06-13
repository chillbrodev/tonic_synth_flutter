import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class ReverbTestSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'ReverbTestSynth';

  ReverbTestSynth() : handle = tonic_create_reverb_test() {
    print('[ReverbTestSynth] created');
  }

  /// Dry level in dBFS. Range: -60..0
  TonicResult setDry(double db) => setParam('dry', db);

  /// Wet level in dBFS. Range: -60..0
  TonicResult setWet(double db) => setParam('wet', db);

  /// Reverb decay time in seconds. Range: 0.1..10
  TonicResult setDecayTime(double seconds) => setParam('decayTime', seconds);

  /// Decay lowpass cutoff in Hz. Range: 4000..20000
  TonicResult setLowDecay(double hz) => setParam('lowDecay', hz);

  /// Decay highpass cutoff in Hz. Range: 20..250
  TonicResult setHiDecay(double hz) => setParam('hiDecay', hz);

  /// Pre-delay in seconds. Range: 0.001..0.05
  TonicResult setPreDelay(double seconds) => setParam('preDelay', seconds);

  /// Input lowpass cutoff in Hz. Range: 4000..20000
  TonicResult setInputLPF(double hz) => setParam('inputLPF', hz);

  /// Input highpass cutoff in Hz. Range: 20..250
  TonicResult setInputHPF(double hz) => setParam('inputHPF', hz);

  /// Reverb density. Range: 0..1
  TonicResult setDensity(double amount) => setParam('density', amount);

  /// Room shape. Range: 0..1
  TonicResult setShape(double amount) => setParam('shape', amount);

  /// Room size. Range: 0..1
  TonicResult setSize(double amount) => setParam('size', amount);

  /// Stereo width. Range: 0..1
  TonicResult setStereo(double amount) => setParam('stereo', amount);
}
