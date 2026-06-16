import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tonic_synth_flutter/audio/audio_limits.dart';
import 'package:tonic_synth_flutter/audio/shared_float_ring_buffer.dart';
import 'package:tonic_synth_flutter/audio/synth_feed_isolate.dart';
import 'package:tonic_synth_flutter/audio/wav_writer.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';
import 'package:tonic_synth_flutter/logger.dart';
import 'package:tonic_synth_flutter/synths/result/tonic_result.dart';

/// Audio playback and recording surface shared by all synth pages.
abstract interface class SynthAudioHost {
  Future<void> startAudio();
  Future<String?> stopAudio({bool saveActiveRecording = false});
  void startRecording();
  Future<String?> stopRecording();
  Future<void> shareRecording(String path);
  double get recordingProgress;
  double get recordingSecondsRecorded;
  double get recordingSecondsRemaining;
  void Function(String? savedPath)? get onRecordingLimitReached;
  set onRecordingLimitReached(void Function(String? savedPath)? value);
}

mixin TonicSynthMixin implements SynthAudioHost {
  Pointer<TonicSynth_s> get handle;
  String get synthName;

  SharedFloatRingBuffer? _ringBuffer;
  Pointer<Int32>? _recordedSamples;

  SendPort? _feedSendPort;
  ReceivePort? _feedResponsePort;
  StreamSubscription<dynamic>? _feedResponseSub;

  AudioSource? _stream;
  Timer? _drainTimer;

  final WavWriter _wavWriter = WavWriter();
  bool _isRecording = false;
  bool _feedIsolateRunning = false;
  Stopwatch? _playbackClock;
  int _samplesDeliveredToSoloud = 0;

  Float32List? _drainScratch;
  FeedRecordingStopped? _pendingRecording;
  Completer<FeedRecordingStopped>? _recordingStopCompleter;
  Completer<void>? _shutdownCompleter;

  /// Called when a recording hits the 60s capture limit.
  /// [savedPath] is set when the WAV was saved successfully.
  @override
  void Function(String? savedPath)? onRecordingLimitReached;

  static const int _frames = feedFrames;
  static const int _channels = feedChannels;

  bool get isRecording => _isRecording;
  bool get isPlaying => _feedIsolateRunning;

  @override
  double get recordingSecondsRecorded {
    if (!_isRecording || _recordedSamples == null) return 0;
    return _recordedSamples!.value / (kSampleRate * kChannels);
  }

  @override
  double get recordingSecondsRemaining =>
      (kMaxSessionSeconds - recordingSecondsRecorded)
          .clamp(0.0, kMaxSessionSeconds.toDouble());

  @override
  double get recordingProgress =>
      (recordingSecondsRecorded / kMaxSessionSeconds).clamp(0.0, 1.0);

  // ---------------------------------------------------------------------------
  // Audio playback
  // ---------------------------------------------------------------------------

  @override
  Future<void> startAudio() async {
    _samplesDeliveredToSoloud = 0;
    _playbackClock = Stopwatch()..start();
    _ringBuffer = SharedFloatRingBuffer.create();
    _recordedSamples = calloc<Int32>();
    _drainScratch = Float32List(_frames * _channels);

    _feedResponsePort = ReceivePort();
    _feedResponseSub = _feedResponsePort!.listen(_handleFeedMessage);

    _feedSendPort = await spawnSynthFeedIsolate(
      FeedIsolateConfig(
        synthHandle: handle,
        ringData: _ringBuffer!.data,
        ringHead: _ringBuffer!.head,
        ringTail: _ringBuffer!.tail,
        ringCapacity: _ringBuffer!.capacity,
        recordedSamples: _recordedSamples!,
        mainSendPort: _feedResponsePort!.sendPort,
      ),
    );
    _feedIsolateRunning = true;

    if (_isRecording) {
      _feedSendPort?.send(FeedStartRecording());
    }

    // Let the feed isolate fill the ring before playback starts.
    final prefillDeadline = Stopwatch()..start();
    while (_ringBuffer!.availableToRead < kPrefillSamples &&
        prefillDeadline.elapsedMilliseconds < 300) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    _stream = SoLoud.instance.setBufferStream(
      bufferingType: BufferingType.released,
      sampleRate: kSampleRate,
      channels: Channels.stereo,
      format: BufferType.f32le,
    );

    SoLoud.instance.play(_stream!);

    _drainTimer = Timer.periodic(const Duration(milliseconds: 8), (_) {
      _drainRingBuffer();
    });

    logger.d('[$synthName] audio started (feed isolate)');
  }

  void _drainRingBuffer() {
    final ring = _ringBuffer;
    final stream = _stream;
    final scratch = _drainScratch;
    final clock = _playbackClock;
    if (ring == null || stream == null || scratch == null || clock == null) {
      return;
    }

    final targetDelivered =
        (clock.elapsedMicroseconds * kSampleRate * kChannels ~/ 1000000);
    var budget = targetDelivered - _samplesDeliveredToSoloud;
    if (budget <= 0) return;

    while (budget > 0) {
      final read = ring.readIntoUpTo(scratch, budget);
      if (read == 0) break;

      final bytes = scratch.buffer.asUint8List(0, read * sizeOf<Float>());
      SoLoud.instance.addAudioDataStream(stream, bytes);
      _samplesDeliveredToSoloud += read;
      budget -= read;
    }
  }

  void _handleFeedMessage(dynamic message) {
    switch (message) {
      case FeedIsolateStopped():
        final completer = _shutdownCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
      case FeedRecordingFull():
        _isRecording = false;
        unawaited(_handleRecordingFull());
      case FeedRecordingStopped(:final pcmBytes, :final samplesRecorded):
        final stopped = FeedRecordingStopped(pcmBytes, samplesRecorded);
        final completer = _recordingStopCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete(stopped);
        } else {
          _pendingRecording = stopped;
        }
      case FeedParameterResult(:final name, :final code):
        if (code != 0) {
          logger.d('[$synthName] unknown parameter: $name');
        }
    }
  }

  Future<void> _handleRecordingFull() async {
    final path = await stopRecording();
    onRecordingLimitReached?.call(path);
  }

  @override
  Future<String?> stopAudio({bool saveActiveRecording = false}) async {
    String? savedPath;
    if (_isRecording || _pendingRecording != null) {
      if (saveActiveRecording) {
        savedPath = await stopRecording();
      } else {
        cancelRecording();
      }
    }

    _drainTimer?.cancel();
    _drainTimer = null;

    if (_feedSendPort != null) {
      _shutdownCompleter = Completer<void>();
      _feedSendPort!.send(FeedShutdown());
      await _shutdownCompleter!.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
      _shutdownCompleter = null;
      _feedSendPort = null;
    }

    await _feedResponseSub?.cancel();
    _feedResponseSub = null;
    _feedResponsePort?.close();
    _feedResponsePort = null;
    _feedIsolateRunning = false;
    _playbackClock?.stop();
    _playbackClock = null;
    _samplesDeliveredToSoloud = 0;

    if (_stream != null) {
      SoLoud.instance.setDataIsEnded(_stream!);
      await _stream!.allInstancesFinished.first.timeout(
        const Duration(milliseconds: 300),
        onTimeout: () {},
      );
      await SoLoud.instance.disposeSource(_stream!);
      _stream = null;
    }

    _ringBuffer?.dispose();
    _ringBuffer = null;
    _drainScratch = null;

    if (_recordedSamples != null) {
      calloc.free(_recordedSamples!);
      _recordedSamples = null;
    }

    logger.d('[$synthName] audio stopped');
    return savedPath;
  }

  // ---------------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------------

  @override
  void startRecording() {
    _isRecording = true;
    if (_feedIsolateRunning) {
      if (_recordedSamples != null) {
        _recordedSamples!.value = 0;
      }
      _feedSendPort?.send(FeedStartRecording());
    } else {
      _wavWriter.reset();
    }
    logger.d('[$synthName] recording started');
  }

  void cancelRecording() {
    if (!_isRecording && _pendingRecording == null) return;
    _isRecording = false;
    _pendingRecording = null;

    final completer = _recordingStopCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(FeedRecordingStopped(Uint8List(0), 0));
    }
    _recordingStopCompleter = null;

    if (_feedIsolateRunning) {
      _feedSendPort?.send(FeedCancelRecording());
    } else {
      _wavWriter.reset();
    }

    logger.d('[$synthName] recording cancelled');
  }

  @override
  Future<String?> stopRecording() async {
    if (!_isRecording && _pendingRecording == null) return null;
    _isRecording = false;

    if (_feedIsolateRunning) {
      FeedRecordingStopped? stopped = _pendingRecording;
      _pendingRecording = null;

      if (stopped == null) {
        _recordingStopCompleter = Completer<FeedRecordingStopped>();
        _feedSendPort?.send(FeedStopRecording());
        stopped = await _recordingStopCompleter!.future;
        _recordingStopCompleter = null;
      }

      return _saveRecordingBytes(stopped.pcmBytes, stopped.samplesRecorded);
    }

    return _saveRecordingBytes(_wavWriter.takeBytes(), _wavWriter.samplesWritten);
  }

  Future<String?> _saveRecordingBytes(
    Uint8List pcmBytes,
    int samplesRecorded,
  ) async {
    if (pcmBytes.isEmpty || samplesRecorded == 0) return null;

    try {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/${synthName}_$ts.wav';
      final file = await _wavWriter.savePcm(path, pcmBytes);
      logger.d('[$synthName] recording saved: ${file.path}');
      return file.path;
    } catch (e) {
      logger.d('[$synthName] recording save failed: $e');
      return null;
    }
  }

  @override
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
  // PCM render / visualization
  // ---------------------------------------------------------------------------

  /// Returns recent stereo PCM from the ring buffer for waveform display.
  /// Only valid while audio is running via the feed isolate.
  Float32List peekRecentSamples(int count) {
    final ring = _ringBuffer;
    final scratch = Float32List(count);
    if (ring == null) return scratch;
    ring.peekRecent(scratch, count);
    return scratch;
  }

  /// Renders a mono buffer directly — only for use when audio is not running.
  Float32List fillBuffer(int frames, int channels) {
    final sampleCount = frames * channels;
    final byteCount = sampleCount * sizeOf<Float>();
    final buffer = calloc<Int8>(byteCount);
    try {
      tonic_synth_fill_buffer(handle, buffer, frames, channels);
      return buffer.cast<Float>().asTypedList(sampleCount);
    } finally {
      calloc.free(buffer);
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> destroy() async {
    await stopAudio();
    tonic_synth_destroy(handle);
    logger.d('[$synthName] destroyed');
  }

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------

  TonicResult setParam(String name, double value, {bool silent = false}) {
    if (_feedIsolateRunning && _feedSendPort != null) {
      _feedSendPort!.send(FeedSetParameter(name, value));
      if (!silent) logger.d('[$synthName] $name = $value');
      return TonicOk();
    }
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
