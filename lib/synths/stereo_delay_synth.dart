import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class StereoDelaySynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'StereoDelaySynth';

  StereoDelaySynth() : handle = tonic_create_stereo_delay() {
    print('[StereoDelaySynth] created');
  }

  /// Base frequency offset in Hz. Range: 0..500
  TonicResult setFreq(double hz) => setParam('freq', hz);

  /// Random frequency amount. Range: 0..1
  TonicResult setFrequencyRandomAmount(double amount) =>
      setParam('frequencyRandomAmount', amount);

  /// Envelope decay in seconds. Range: 0..2
  TonicResult setDecay(double seconds) => setParam('decay', seconds);
}
