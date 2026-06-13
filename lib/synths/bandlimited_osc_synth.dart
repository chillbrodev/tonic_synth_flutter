import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class BandlimitedOscSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'BandlimitedOscSynth';

  BandlimitedOscSynth() : handle = tonic_create_bandlimited_osc() {
    print('[BandlimitedOscSynth] created');
  }

  /// Blend between aliased (0.0) and bandlimited (1.0) square wave.
  TonicResult setBlend(double amount) => setParam('blend', amount);
}
