import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:string_and_time/audio/pitch_detector.dart';

void main() {
  for (final string in standardStrings) {
    for (final cents in [-35, 0, 35]) {
      test('${string.label}, $cents cents, with harmonics, decay and noise', () {
        final frequency = string.frequency * math.pow(2, cents / 1200);
        final random = math.Random(42);
        final samples = Float64List.fromList(
          List.generate(tunerFrameSize, (i) {
            final phase = 2 * math.pi * frequency * i / tunerSampleRate;
            final envelope = math.exp(-2 * i / tunerFrameSize);
            return 0.1 +
                envelope * (0.25 * math.sin(phase) + 0.4 * math.sin(2 * phase) + 0.15 * math.sin(3 * phase)) +
                0.015 * (random.nextDouble() - 0.5);
          }),
        );
        final detected = detectPitch(samples);
        expect(detected, isNotNull);
        expect(centsBetween(detected!, frequency).abs(), lessThan(3));
        expect(nearestString(detected), string);
        expect(centsBetween(detected, string.frequency), closeTo(cents, 3));
      });
    }
  }

  test('silence, DC offset, very quiet audio and noise have no pitch', () {
    expect(detectPitch(Float64List(tunerFrameSize)), isNull);
    expect(detectPitch(Float64List.fromList(List.filled(tunerFrameSize, 0.5))), isNull);
    final random = math.Random(7);
    expect(detectPitch(Float64List.fromList(List.generate(tunerFrameSize, (_) => random.nextDouble() - 0.5))), isNull);
    expect(detectPitch(Float64List.fromList(List.generate(tunerFrameSize, (i) => 0.001 * math.sin(i / 20)))), isNull);
  });

  test('PCM decoding preserves signed samples across arbitrary byte boundaries', () {
    final original = List.generate(tunerFrameSize * 2, (i) => (i * 997) % 65536 - 32768);
    final bytes = ByteData(original.length * 2);
    for (var i = 0; i < original.length; i++) {
      bytes.setInt16(i * 2, original[i], Endian.little);
    }
    final decoder = PcmFrameDecoder();
    final decoded = <double>[];
    final source = bytes.buffer.asUint8List();
    for (var i = 0; i < source.length; i += 333) {
      for (final frame in decoder.add(Uint8List.sublistView(source, i, math.min(i + 333, source.length)))) {
        decoded.addAll(frame);
      }
    }
    expect(decoded, original.map((value) => value / 32768).toList());
  });
}
