import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';

class ArbitraryTableSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'ArbitraryTableSynth';

  ArbitraryTableSynth() : handle = tonic_create_arbitrary_table() {
    print('[ArbitraryTableSynth] created');
  }

  // No parameters — autonomous wavetable oscillator.
}
