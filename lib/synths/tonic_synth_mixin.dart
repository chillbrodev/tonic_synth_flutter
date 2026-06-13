import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../ffi/gen/tonic_native.g.dart';
import 'result/tonic_result.dart';

mixin TonicSynthMixin {
  Pointer<TonicSynth_s> get handle;
  String get synthName;

  Pointer<Int8>? pcmBuffer;
  int pcmBufferSamples = 0;

  AudioSource? _stream;
  Timer? _feedTimer;

  static const int _frames = 512;
  static const int _channels = 2;

  Future<void> startAudio() async {
    _stream = SoLoud.instance.setBufferStream(
      bufferingType: BufferingType.released,
      sampleRate: 44100,
      channels: Channels.stereo,
      format: BufferType.f32le,
    );

    SoLoud.instance.play(_stream!);

    // Feed buffers every ~8ms — stays ahead of 512 frames @ 44100Hz (~11.6ms)
    _feedTimer = Timer.periodic(const Duration(milliseconds: 8), (_) {
      final bytes = fillBuffer(_frames, _channels).buffer.asUint8List();
      SoLoud.instance.addAudioDataStream(_stream!, bytes);
    });

    print('[$synthName] audio started');
  }

  Future<void> stopAudio() async {
    _feedTimer?.cancel();
    _feedTimer = null;

    if (_stream != null) {
      SoLoud.instance.setDataIsEnded(_stream!);
      await SoLoud.instance.disposeSource(_stream!);
      _stream = null;
    }

    print('[$synthName] audio stopped');
  }

  Float32List fillBuffer(int frames, int channels) {
    final sampleCount = frames * channels;
    final byteCount = sampleCount * sizeOf<Float>();

    if (sampleCount > pcmBufferSamples) {
      if (pcmBuffer != null) calloc.free(pcmBuffer!);
      pcmBuffer = calloc<Int8>(byteCount);
      pcmBufferSamples = sampleCount;
    }

    tonic_synth_fill_buffer(handle, pcmBuffer!, frames, channels);
    return pcmBuffer!.cast<Float>().asTypedList(sampleCount);
  }

  Future<void> destroy() async {
    await stopAudio();
    if (pcmBuffer != null) {
      calloc.free(pcmBuffer!);
      pcmBuffer = null;
    }
    tonic_synth_destroy(handle);
    print('[$synthName] destroyed');
  }

  TonicResult setParam(String name, double value, {bool silent = false}) {
    return using((arena) {
      final namePtr = name.toNativeUtf8(allocator: arena);
      final result = tonic_synth_set_parameter(
        handle,
        namePtr.cast<Char>(),
        value,
      );
      if (result == 0) {
        if (!silent) print('[$synthName] $name = $value');
        return TonicOk();
      } else {
        print('[$synthName] unknown parameter: $name');
        return TonicParameterError(name);
      }
    });
  }
}
