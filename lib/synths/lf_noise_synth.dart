import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

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
