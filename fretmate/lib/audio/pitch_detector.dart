import 'dart:math' as math;
import 'dart:typed_data';

const tunerSampleRate = 22050;
const tunerFrameSize = 2048;

class GuitarString {
  const GuitarString(this.number, this.note, this.octave, this.frequency);

  final int number;
  final String note;
  final int octave;
  final double frequency;

  String get label => '$note$octave';
}

const standardStrings = [
  GuitarString(6, 'E', 2, 82.4069),
  GuitarString(5, 'A', 2, 110),
  GuitarString(4, 'D', 3, 146.8324),
  GuitarString(3, 'G', 3, 195.9977),
  GuitarString(2, 'B', 3, 246.9417),
  GuitarString(1, 'E', 4, 329.6276),
];

double centsBetween(double frequency, double target) => 1200 * math.log(frequency / target) / math.ln2;

GuitarString nearestString(double frequency) => standardStrings.reduce((a, b) {
  return centsBetween(frequency, a.frequency).abs() < centsBetween(frequency, b.frequency).abs() ? a : b;
});

// YIN difference and cumulative mean normalization, followed by parabolic interpolation.
double? detectPitch(Float64List samples) {
  if (samples.length != tunerFrameSize || samples.any((sample) => !sample.isFinite)) return null;
  final mean = samples.reduce((a, b) => a + b) / samples.length;
  var energy = 0.0;
  for (final sample in samples) {
    energy += (sample - mean) * (sample - mean);
  }
  if (math.sqrt(energy / samples.length) < 0.008) return null;

  const minTau = tunerSampleRate ~/ 400;
  const maxTau = tunerSampleRate ~/ 65;
  const window = tunerFrameSize ~/ 2;
  final difference = Float64List(maxTau + 2);
  difference[0] = 1;
  var runningSum = 0.0;
  for (var tau = 1; tau <= maxTau + 1; tau++) {
    var sum = 0.0;
    for (var i = 0; i < window; i++) {
      final delta = samples[i] - samples[i + tau];
      sum += delta * delta;
    }
    runningSum += sum;
    difference[tau] = runningSum == 0 ? 1 : sum * tau / runningSum;
  }

  for (var tau = minTau; tau <= maxTau; tau++) {
    if (difference[tau] >= 0.15) continue;
    while (tau < maxTau && difference[tau + 1] < difference[tau]) {
      tau++;
    }
    final left = difference[tau - 1];
    final middle = difference[tau];
    final right = difference[tau + 1];
    final denominator = left - 2 * middle + right;
    final offset = denominator == 0 ? 0.0 : (0.5 * (left - right) / denominator).clamp(-1.0, 1.0);
    final frequency = tunerSampleRate / (tau + offset);
    return frequency >= 65 && frequency <= 400 ? frequency : null;
  }
  return null;
}

class PcmFrameDecoder {
  Float64List _frame = Float64List(tunerFrameSize);
  int _position = 0;
  int? _lowByte;

  Iterable<Float64List> add(Uint8List bytes) sync* {
    for (final byte in bytes) {
      if (_lowByte == null) {
        _lowByte = byte;
        continue;
      }
      final value = _lowByte! | (byte << 8);
      _lowByte = null;
      _frame[_position++] = (value >= 32768 ? value - 65536 : value) / 32768;
      if (_position == tunerFrameSize) {
        yield _frame;
        _frame = Float64List(tunerFrameSize);
        _position = 0;
      }
    }
  }
}
