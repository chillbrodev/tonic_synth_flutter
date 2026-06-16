import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tonic_synth_flutter/logger.dart';
import '../audio/wav_writer.dart';
import '../ffi/gen/tonic_native.g.dart';
import 'result/tonic_result.dart';

mixin TonicSynthMixin {
  Pointer<TonicSynth_s> get handle;
  String get synthName;

  Pointer<Int8>? pcmBuffer;
  int pcmBufferSamples = 0;

  AudioSource? _stream;
  Timer? _feedTimer;

  final WavWriter _wavWriter = WavWriter();
  bool _isRecording = false;

  // Called when the 60s recording limit is hit — page uses this to
  // update its isPlaying/isRecording state.
  void Function(String? savedPath)? onAutoStop;

  static const int _frames = 512;
  static const int _channels = 2;

  bool get isRecording => _isRecording;
  double get recordingSecondsRemaining => _wavWriter.secondsRemaining;
  double get recordingSecondsRecorded => _wavWriter.secondsRecorded;
  double get recordingProgress =>
      (_wavWriter.secondsRecorded / 60.0).clamp(0.0, 1.0);

  // ---------------------------------------------------------------------------
  // Audio playback
  // ---------------------------------------------------------------------------

  Future<void> startAudio() async {
    _stream = SoLoud.instance.setBufferStream(
      bufferingType: BufferingType.released,
      sampleRate: 44100,
      channels: Channels.stereo,
      format: BufferType.f32le,
    );

    SoLoud.instance.play(_stream!);

    _feedTimer = Timer.periodic(const Duration(milliseconds: 8), (_) {
      final samples = fillBuffer(_frames, _channels);
      final bytes = samples.buffer.asUint8List();
      SoLoud.instance.addAudioDataStream(_stream!, bytes);

      if (_isRecording) {
        _wavWriter.append(samples);
        if (_wavWriter.isFull) {
          _handleAutoStop();
        }
      }
    });

    logger.d('[$synthName] audio started');
  }

  Future<void> _handleAutoStop() async {
    final path = await stopRecording();
    await stopAudio();
    onAutoStop?.call(path);
  }

  Future<void> stopAudio() async {
    // Cancel the feed timer first — this drains the buffer immediately
    // so SoLoud has very little left to play, minimising the stop delay.
    _feedTimer?.cancel();
    _feedTimer = null;

    if (_stream != null) {
      SoLoud.instance.setDataIsEnded(_stream!);
      await _stream!.allInstancesFinished.first.timeout(
        const Duration(milliseconds: 300),
        onTimeout: () {},
      );
      await SoLoud.instance.disposeSource(_stream!);
      _stream = null;
    }

    logger.d('[$synthName] audio stopped');
  }

  // ---------------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------------

  void startRecording() {
    _wavWriter.reset();
    _isRecording = true;
    logger.d('[$synthName] recording started');
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    _isRecording = false;

    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/${synthName}_$ts.wav';
      final file = await _wavWriter.save(path);
      logger.d('[$synthName] recording saved: ${file.path}');
      return file.path;
    } catch (e) {
      logger.d('[$synthName] recording save failed: $e');
      return null;
    }
  }

  Future<void> shareRecording(String path) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(path, mimeType: 'audio/wav', name: '$synthName-recording.wav'),
        ],
        subject: '$synthName-recording.wav',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PCM render
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> destroy() async {
    await stopAudio();
    if (pcmBuffer != null) {
      calloc.free(pcmBuffer!);
      pcmBuffer = null;
    }
    tonic_synth_destroy(handle);
    logger.d('[$synthName] destroyed');
  }

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------

  TonicResult setParam(String name, double value, {bool silent = false}) {
    return using((arena) {
      final namePtr = name.toNativeUtf8(allocator: arena);
      final result = tonic_synth_set_parameter(
        handle,
        namePtr.cast<Char>(),
        value,
      );
      if (result == 0) {
        if (!silent) logger.d('[$synthName] $name = $value');
        return TonicOk();
      } else {
        logger.d('[$synthName] unknown parameter: $name');
        return TonicParameterError(name);
      }
    });
  }
}
