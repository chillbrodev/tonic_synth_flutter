import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class SineSumSynth with TonicSynthMixin {
  SineSumSynth() : handle = tonic_create_sine_sum() {
    logger.d('[SineSumSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'SineSumSynth';

  /// Pitch sweep across the chord stack. Range: 0..1
  TonicResult setPitch(double amount) => setParam('pitch', amount);
}
