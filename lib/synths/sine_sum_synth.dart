import 'dart:ffi';
import '../logger.dart';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

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
