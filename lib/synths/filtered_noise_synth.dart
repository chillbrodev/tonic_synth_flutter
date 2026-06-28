import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class FilteredNoiseSynth with TonicSynthMixin {
  FilteredNoiseSynth() : handle = tonic_create_filtered_noise() {
    logger.d('[FilteredNoiseSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'FilteredNoiseSynth';

  /// Filter cutoff normalised. Range: 0..1
  TonicResult setCutoff(double amount) => setParam('cutoff', amount);

  /// Filter resonance. Range: 0..10
  TonicResult setQ(double q) => setParam('Q', q);
}
