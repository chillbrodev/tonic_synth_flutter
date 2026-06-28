import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class StereoDelaySynth with TonicSynthMixin {
  StereoDelaySynth() : handle = tonic_create_stereo_delay() {
    logger.d('[StereoDelaySynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'StereoDelaySynth';

  /// Base frequency offset in Hz. Range: 0..500
  TonicResult setFreq(double hz) => setParam('freq', hz);

  /// Random frequency amount. Range: 0..1
  TonicResult setFrequencyRandomAmount(double amount) =>
      setParam('frequencyRandomAmount', amount);

  /// Envelope decay in seconds. Range: 0..2
  TonicResult setDecay(double seconds) => setParam('decay', seconds);
}
