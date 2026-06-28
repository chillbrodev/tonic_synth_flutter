import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class StepSeqSynth with TonicSynthMixin {
  StepSeqSynth() : handle = tonic_create_step_seq() {
    logger.d('[StepSeqSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'StepSeqSynth';

  static const int stepCount = 8;

  /// Sequencer tempo in BPM. Range: 50..300
  TonicResult setTempo(double bpm) => setParam('tempo', bpm);

  /// Transpose in semitones. Range: -6..6
  TonicResult setTranspose(double semitones) =>
      setParam('transpose', semitones);

  /// Set pitch for a step (0-7) as MIDI note. Range: 10..80
  TonicResult setStepPitch(int step, double midi) {
    assert(step >= 0 && step < stepCount);
    return setParam('step${step}Pitch', midi);
  }

  /// Set filter cutoff for a step (0-7) in Hz. Range: 30..1500
  TonicResult setStepCutoff(int step, double hz) {
    assert(step >= 0 && step < stepCount);
    return setParam('step${step}Cutoff', hz);
  }
}
