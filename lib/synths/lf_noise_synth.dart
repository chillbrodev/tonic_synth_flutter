import 'dart:ffi';
import '../logger.dart';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class LfNoiseSynth with TonicSynthMixin {

  LfNoiseSynth() : handle = tonic_create_lf_noise() {
    logger.d('[LfNoiseSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'LfNoiseSynth';

  /// LF noise frequency in Hz. Range: 1..500
  TonicResult setNoiseFreq(double hz) => setParam('noiseFreq', hz);
}
