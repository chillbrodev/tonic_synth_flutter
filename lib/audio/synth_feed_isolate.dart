// lib/audio/synth_feed_isolate.dart
//
// Dedicated isolate that renders PCM via FFI and writes into a shared ring
// buffer. Recording accumulation also happens here so every frame is captured.

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:tonic_synth_flutter/audio/audio_limits.dart';
import 'package:tonic_synth_flutter/audio/shared_float_ring_buffer.dart';
import 'package:tonic_synth_flutter/audio/wav_writer.dart';
import 'package:tonic_synth_flutter/ffi/gen/tonic_native.g.dart';

const int feedFrames = kFeedFrames;
const int feedChannels = kChannels;

sealed class FeedCommand {}

final class FeedShutdown extends FeedCommand {}

final class FeedSetParameter extends FeedCommand {
  FeedSetParameter(this.name, this.value);
  final String name;
  final double value;
}

final class FeedStartRecording extends FeedCommand {}

final class FeedStopRecording extends FeedCommand {}

final class FeedCancelRecording extends FeedCommand {}

final class FeedIsolateStarted {
  FeedIsolateStarted(this.sendPort);
  final SendPort sendPort;
}

final class FeedParameterResult {
  FeedParameterResult(this.name, this.code);
  final String name;
  final int code;
}

final class FeedRecordingStopped {
  FeedRecordingStopped(this.pcmBytes, this.samplesRecorded);
  final Uint8List pcmBytes;
  final int samplesRecorded;
}

final class FeedRecordingFull {}

final class FeedIsolateStopped {}

class FeedIsolateConfig {
  FeedIsolateConfig({
    required this.synthHandle,
    required this.ringData,
    required this.ringHead,
    required this.ringTail,
    required this.ringCapacity,
    required this.recordedSamples,
    required this.mainSendPort,
  });

  final Pointer<TonicSynth_s> synthHandle;
  final Pointer<Float> ringData;
  final Pointer<Int64> ringHead;
  final Pointer<Int64> ringTail;
  final int ringCapacity;
  final Pointer<Int32> recordedSamples;
  final SendPort mainSendPort;
}

Future<SendPort> spawnSynthFeedIsolate(FeedIsolateConfig config) async {
  final readyPort = ReceivePort();
  await Isolate.spawn(_feedIsolateEntry, (config, readyPort.sendPort));
  final started = await readyPort.first as FeedIsolateStarted;
  readyPort.close();
  return started.sendPort;
}

void _feedIsolateEntry((FeedIsolateConfig, SendPort) args) {
  final (config, readySendPort) = args;
  final commandPort = ReceivePort();
  readySendPort.send(FeedIsolateStarted(commandPort.sendPort));

  final ring = SharedFloatRingBuffer.view(
    data: config.ringData,
    head: config.ringHead,
    tail: config.ringTail,
    capacity: config.ringCapacity,
  );

  final handle = config.synthHandle;
  final mainSendPort = config.mainSendPort;
  final recordedSamples = config.recordedSamples;

  final pcmBuffer = calloc<Int8>(feedFrames * feedChannels * sizeOf<Float>());
  final scratch = Float32List(feedFrames * feedChannels);
  final wavWriter = WavWriter();
  var isRecording = false;
  var running = true;
  final pendingParams = <String, double>{};

  void flushPendingParams() {
    if (pendingParams.isEmpty) return;

    for (final entry in pendingParams.entries) {
      using((arena) {
        final namePtr = entry.key.toNativeUtf8(allocator: arena);
        final code = tonic_synth_set_parameter(
          handle,
          namePtr.cast<Char>(),
          entry.value,
        );
        if (code != 0) {
          mainSendPort.send(FeedParameterResult(entry.key, code));
        }
      });
    }
    pendingParams.clear();
  }

  void processCommand(FeedCommand command) {
    switch (command) {
      case FeedShutdown():
        break;
      case FeedSetParameter(:final name, :final value):
        pendingParams[name] = value;
      case FeedStartRecording():
        wavWriter.reset();
        recordedSamples.value = 0;
        isRecording = true;
      case FeedStopRecording():
        isRecording = false;
        final samplesWritten = wavWriter.samplesWritten;
        final pcmBytes = wavWriter.takeBytes();
        mainSendPort.send(FeedRecordingStopped(pcmBytes, samplesWritten));
        recordedSamples.value = 0;
      case FeedCancelRecording():
        isRecording = false;
        wavWriter.reset();
        recordedSamples.value = 0;
    }
  }

  commandPort.listen((message) {
    if (message is FeedShutdown) {
      running = false;
      commandPort.close();
    } else if (message is FeedCommand) {
      processCommand(message);
    }
  });

  unawaited(() async {
    while (running) {
      final sampleCount = feedFrames * feedChannels;

      flushPendingParams();

      tonic_synth_fill_buffer(handle, pcmBuffer, feedFrames, feedChannels);
      scratch.setRange(
        0,
        sampleCount,
        pcmBuffer.cast<Float>().asTypedList(sampleCount),
      );

      while (running && ring.availableToWrite < sampleCount) {
        await Future<void>.delayed(const Duration(microseconds: 200));
      }
      if (!running) break;

      ring.write(scratch, sampleCount);

      if (isRecording) {
        wavWriter.append(scratch);
        recordedSamples.value = wavWriter.samplesWritten;
        if (wavWriter.isFull) {
          isRecording = false;
          final samplesWritten = wavWriter.samplesWritten;
          final pcmBytes = wavWriter.takeBytes();
          mainSendPort.send(FeedRecordingStopped(pcmBytes, samplesWritten));
          recordedSamples.value = 0;
          mainSendPort.send(FeedRecordingFull());
        }
      }

      // Yield so parameter/recording commands on the ReceivePort are handled.
      await Future<void>.delayed(Duration.zero);
    }

    calloc.free(pcmBuffer);
    mainSendPort.send(FeedIsolateStopped());
  }());
}
