import 'dart:ffi';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/synths/tonic_synth_mixin.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

class XySpeedSynth with TonicSynthMixin {
  XySpeedSynth() : handle = tonic_create_xy_speed() {
    logger.d('[XySpeedSynth] created');
  }
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'XySpeedSynth';

  TonicResult setX(double x) => setParam('x', x, silent: true);
  TonicResult setY(double y) => setParam('y', y, silent: true);

  void setPosition(double x, double y) {
    setX(x);
    setY(y);
  }
}
