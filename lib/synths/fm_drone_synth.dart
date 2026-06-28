import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class FmDroneSynth with TonicSynthMixin {
  FmDroneSynth() : handle = tonic_create_fm_drone() {
    logger.d('[FmDroneSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'FmDroneSynth';

  TonicResult setVolume(double db) => setParam('volume', db, silent: true);
  TonicResult setCarrierPitch(double midi) =>
      setParam('carrierPitch', midi, silent: true);
  TonicResult setModIndex(double amount) =>
      setParam('modIndex', amount, silent: true);
  TonicResult setLfoAmount(double amount) =>
      setParam('lfoAmt', amount, silent: true);
}
