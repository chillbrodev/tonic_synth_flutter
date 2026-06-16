import 'dart:ffi';
import '../logger.dart';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class DelayTestSynth with TonicSynthMixin {

  DelayTestSynth() : handle = tonic_create_delay_test() {
    logger.d('[DelayTestSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'DelayTestSynth';

  TonicResult setTempo(double bpm) => setParam('tempo', bpm);
  TonicResult setDelayTime(double seconds) => setParam('delayTime', seconds);
  TonicResult setFeedback(double amount) => setParam('feedback', amount);
  TonicResult setDelayMix(double amount) => setParam('delayMix', amount);
  TonicResult setDecayTime(double seconds) => setParam('decayTime', seconds);
  TonicResult setVolume(double db) => setParam('volume', db);
}
