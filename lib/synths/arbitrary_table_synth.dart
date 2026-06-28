import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';

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
