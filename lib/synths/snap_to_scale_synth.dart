import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class SnapToScaleSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'SnapToScaleSynth';

  SnapToScaleSynth() : handle = tonic_create_snap_to_scale() {
    print('[SnapToScaleSynth] created');
  }

  /// Sequencer speed multiplier. Range: 0..2
  TonicResult setSpeed(double amount) => setParam('speed', amount);

  /// Stepper start position. Range: 0..1
  TonicResult setStepperStart(double amount) => setParam('stepperStart', amount);

  /// Stepper pitch spread. Range: 0..1
  TonicResult setStepperSpread(double amount) => setParam('stepperSpread', amount);
}
