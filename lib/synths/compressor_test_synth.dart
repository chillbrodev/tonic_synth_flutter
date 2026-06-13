import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class CompressorTestSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'CompressorTestSynth';

  CompressorTestSynth() : handle = tonic_create_compressor_test() {
    print('[CompressorTestSynth] created');
  }

  /// Threshold in dBFS. Range: -60..0
  TonicResult setThreshold(double db) => setParam('threshold', db);

  /// Compression ratio. Range: 1..64
  TonicResult setRatio(double ratio) => setParam('ratio', ratio);

  /// Attack time in seconds. Range: 0.001..0.1
  TonicResult setAttackTime(double seconds) => setParam('attackTime', seconds);

  /// Release time in seconds. Range: 0.01..0.08
  TonicResult setReleaseTime(double seconds) => setParam('releaseTime', seconds);

  /// Makeup gain in dBFS. Range: 0..36
  TonicResult setGain(double db) => setParam('gain', db);

  /// Bypass. 0 = off, 1 = on.
  TonicResult setBypass(bool on) => setParam('bypass', on ? 1.0 : 0.0);
}
