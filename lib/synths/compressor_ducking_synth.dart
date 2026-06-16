import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class CompressorDuckingSynth with TonicSynthMixin {

  CompressorDuckingSynth() : handle = tonic_create_compressor_ducking() {
    logger.d('[CompressorDuckingSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'CompressorDuckingSynth';

  /// Compressor release time in seconds. Range: 0.01..0.5
  TonicResult setCompRelease(double seconds) => setParam('compRelease', seconds);
}
