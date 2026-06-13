import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class FilteredNoiseSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'FilteredNoiseSynth';

  FilteredNoiseSynth() : handle = tonic_create_filtered_noise() {
    print('[FilteredNoiseSynth] created');
  }

  /// Filter cutoff normalised. Range: 0..1
  TonicResult setCutoff(double amount) => setParam('cutoff', amount);

  /// Filter resonance. Range: 0..10
  TonicResult setQ(double q) => setParam('Q', q);
}
