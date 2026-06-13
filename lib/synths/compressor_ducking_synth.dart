import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class CompressorDuckingSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'CompressorDuckingSynth';

  CompressorDuckingSynth() : handle = tonic_create_compressor_ducking() {
    print('[CompressorDuckingSynth] created');
  }

  /// Compressor release time in seconds. Range: 0.01..0.5
  TonicResult setCompRelease(double seconds) => setParam('compRelease', seconds);
}
