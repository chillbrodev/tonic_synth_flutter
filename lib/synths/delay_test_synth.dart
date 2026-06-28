import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

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
