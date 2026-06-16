import 'dart:ffi';
import '../logger.dart';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class BandlimitedOscSynth with TonicSynthMixin {

  BandlimitedOscSynth() : handle = tonic_create_bandlimited_osc() {
    logger.d('[BandlimitedOscSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'BandlimitedOscSynth';

  /// Blend between aliased (0.0) and bandlimited (1.0) square wave.
  TonicResult setBlend(double amount) => setParam('blend', amount);
}
