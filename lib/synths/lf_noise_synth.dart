import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class LfNoiseSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'LfNoiseSynth';

  LfNoiseSynth() : handle = tonic_create_lf_noise() {
    print('[LfNoiseSynth] created');
  }

  /// LF noise frequency in Hz. Range: 1..500
  TonicResult setNoiseFreq(double hz) => setParam('noiseFreq', hz);
}
