import 'dart:ffi';
import '../ffi/gen/tonic_native.g.dart';
import 'tonic_synth_mixin.dart';
import 'result/tonic_result.dart';

class XySpeedSynth with TonicSynthMixin {
  @override
  final Pointer<TonicSynth_s> handle;

  @override
  String get synthName => 'XySpeedSynth';

  XySpeedSynth() : handle = tonic_create_xy_speed() {
    print('[XySpeedSynth] created');
  }

  TonicResult setX(double x) => setParam('x', x, silent: true);
  TonicResult setY(double y) => setParam('y', y, silent: true);

  void setPosition(double x, double y) {
    setX(x);
    setY(y);
  }
}
