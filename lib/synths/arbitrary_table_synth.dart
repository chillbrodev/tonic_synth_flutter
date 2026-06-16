import 'dart:ffi';
import '../logger.dart';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';

class ArbitraryTableSynth with TonicSynthMixin {

  ArbitraryTableSynth() : handle = tonic_create_arbitrary_table() {
    logger.d('[ArbitraryTableSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'ArbitraryTableSynth';

  // No parameters — autonomous wavetable oscillator.
}
