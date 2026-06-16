import 'dart:ffi';
import '../logger.dart';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class FmDroneSynth with TonicSynthMixin {

  FmDroneSynth() : handle = tonic_create_fm_drone() {
    logger.d('[FmDroneSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'FmDroneSynth';

  TonicResult setVolume(double db) => setParam('volume', db);
  TonicResult setCarrierPitch(double midi) => setParam('carrierPitch', midi);
  TonicResult setModIndex(double amount) => setParam('modIndex', amount);
  TonicResult setLfoAmount(double amount) => setParam('lfoAmt', amount);
}
