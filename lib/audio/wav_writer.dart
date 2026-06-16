// lib/audio/wav_writer.dart
//
// Writes PCM float32 buffers to a WAV file.
// Call append() during recording, then save() to flush to disk.

import 'dart:io';
import 'dart:typed_data';

import 'package:tonic_synth_flutter/audio/audio_limits.dart';

class WavWriter {
  static const int _sampleRate = kSampleRate;
  static const int _channels = kChannels;
  static const int _bitsPerSample = 32; // float32
  static const int maxSamples = kMaxSessionSamples;
  static const int _maxSamples = maxSamples;
  static const int maxSeconds = kMaxSessionSeconds;

  final _builder = BytesBuilder();
  int _samplesWritten = 0;
  int get samplesWritten => _samplesWritten;
  bool get isFull => _samplesWritten >= _maxSamples;
  double get secondsRecorded => _samplesWritten / (_sampleRate * _channels);
  double get secondsRemaining =>
      (_maxSamples - _samplesWritten) / (_sampleRate * _channels);

  /// Append a Float32List buffer (interleaved stereo float32).
  /// Silently drops frames once the 60s limit is reached.
  void append(Float32List samples) {
    if (isFull) return;
    final remaining = _maxSamples - _samplesWritten;
    final toWrite = samples.length > remaining ? remaining : samples.length;
    final bytes = samples.buffer.asUint8List(
      samples.offsetInBytes,
      toWrite * Float32List.bytesPerElement,
    );
    _builder.add(bytes);
    _samplesWritten += toWrite;
  }

  /// Write the WAV file to [path]. Returns the File on success.
  Future<File> save(String path) async {
    return savePcm(path, _builder.toBytes());
  }

  /// Write pre-built PCM bytes to [path]. Returns the File on success.
  Future<File> savePcm(String path, Uint8List pcmBytes) async {
    final file = File(path);
    final sink = file.openWrite();

    sink.add(_buildWavHeader(pcmBytes.length));
    sink.add(pcmBytes);

    await sink.flush();
    await sink.close();
    return file;
  }

  void reset() {
    _builder.clear();
    _samplesWritten = 0;
  }

  /// Returns accumulated PCM bytes and clears the internal buffer.
  Uint8List takeBytes() {
    final bytes = _builder.toBytes();
    reset();
    return bytes;
  }

  List<int> _buildWavHeader(int pcmByteCount) {
    final totalDataSize = pcmByteCount;
    final byteRate = _sampleRate * _channels * (_bitsPerSample ~/ 8);
    final blockAlign = _channels * (_bitsPerSample ~/ 8);

    final header = ByteData(44);
    // RIFF chunk
    _setFourCC(header, 0, 'RIFF');
    header.setUint32(4, 36 + totalDataSize, Endian.little);
    _setFourCC(header, 8, 'WAVE');
    // fmt sub-chunk
    _setFourCC(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // sub-chunk size
    header.setUint16(20, 3, Endian.little); // PCM float = 3
    header.setUint16(22, _channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, _bitsPerSample, Endian.little);
    // data sub-chunk
    _setFourCC(header, 36, 'data');
    header.setUint32(40, totalDataSize, Endian.little);

    return header.buffer.asUint8List();
  }

  void _setFourCC(ByteData data, int offset, String s) {
    for (int i = 0; i < 4; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
