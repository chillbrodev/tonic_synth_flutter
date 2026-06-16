// lib/audio/shared_float_ring_buffer.dart
//
// Single-producer / single-consumer float32 ring buffer backed by native
// memory so it can be shared between the feed isolate and the main isolate.

import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

/// ~743 ms of stereo audio at 44.1 kHz (power-of-two capacity).
const int kDefaultRingCapacity = 65536;

final class SharedFloatRingBuffer {
  SharedFloatRingBuffer._({
    required this.data,
    required this.head,
    required this.tail,
    required this.capacity,
  });

  final Pointer<Float> data;
  final Pointer<Int64> head;
  final Pointer<Int64> tail;
  final int capacity;

  factory SharedFloatRingBuffer.create({int capacity = kDefaultRingCapacity}) {
    assert(_isPowerOfTwo(capacity), 'capacity must be a power of two');
    return SharedFloatRingBuffer._(
      data: calloc<Float>(capacity),
      head: calloc<Int64>(),
      tail: calloc<Int64>(),
      capacity: capacity,
    );
  }

  factory SharedFloatRingBuffer.view({
    required Pointer<Float> data,
    required Pointer<Int64> head,
    required Pointer<Int64> tail,
    required int capacity,
  }) {
    return SharedFloatRingBuffer._(
      data: data,
      head: head,
      tail: tail,
      capacity: capacity,
    );
  }

  int get availableToRead {
    final used = head.value - tail.value;
    return used > capacity ? capacity : used;
  }

  int get availableToWrite => capacity - availableToRead;

  /// Producer: copy [count] samples from [src] into the ring. Returns samples written.
  int write(Float32List src, int count) {
    if (count <= 0) return 0;

    final headValue = head.value;
    final tailValue = tail.value;
    final used = headValue - tailValue;
    if (used >= capacity) return 0;

    final space = capacity - used;
    final toWrite = count < space ? count : space;
    final mask = capacity - 1;
    var writeIndex = headValue & mask;

    for (var i = 0; i < toWrite; i++) {
      data[writeIndex] = src[i];
      writeIndex = (writeIndex + 1) & mask;
    }

    head.value = headValue + toWrite;
    return toWrite;
  }

  /// Consumer: copy up to [maxSamples] into [dest]. Returns samples read.
  int readIntoUpTo(Float32List dest, int maxSamples) {
    if (maxSamples <= 0) return 0;
    final limit = maxSamples < dest.length ? maxSamples : dest.length;
    final headValue = head.value;
    final tailValue = tail.value;
    final available = headValue - tailValue;
    if (available <= 0) return 0;

    final toRead = available < limit ? available : limit;
    final mask = capacity - 1;
    var readIndex = tailValue & mask;

    for (var i = 0; i < toRead; i++) {
      dest[i] = data[readIndex];
      readIndex = (readIndex + 1) & mask;
    }

    tail.value = tailValue + toRead;
    return toRead;
  }

  /// Consumer: copy up to [dest].length samples into [dest]. Returns samples read.
  int readInto(Float32List dest) => readIntoUpTo(dest, dest.length);

  /// Read the most recent [count] samples without consuming them.
  int peekRecent(Float32List dest, int count) {
    final headValue = head.value;
    final tailValue = tail.value;
    final available = headValue - tailValue;
    if (available <= 0) return 0;

    final toPeek = count < available ? count : available;
    final mask = capacity - 1;
    final start = (headValue - toPeek) & mask;

    for (var i = 0; i < toPeek; i++) {
      dest[i] = data[(start + i) & mask];
    }

    return toPeek;
  }

  void reset() {
    head.value = 0;
    tail.value = 0;
  }

  void dispose() {
    calloc.free(data);
    calloc.free(head);
    calloc.free(tail);
  }

  static bool _isPowerOfTwo(int value) => value > 0 && (value & (value - 1)) == 0;
}
