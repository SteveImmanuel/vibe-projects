import 'dart:math' as math;
import 'dart:typed_data';

class ClickTrack {
  ClickTrack({required int bpm, required int beats, required bool accent}) {
    if (bpm < 40 || bpm > 240 || beats < 1 || beats > 6) {
      throw ArgumentError('Tempo must be 40–240 BPM and beats must be 1–6.');
    }
    framesPerBeat = (sampleRate * 60 / bpm).round();
    final data = ByteData(framesPerBeat * beats * 2);
    const clickFrames = sampleRate ~/ 30;
    for (var beat = 0; beat < beats; beat++) {
      final accented = accent && beat == 0;
      final frequency = accented ? 1800.0 : 1200.0;
      final amplitude = accented ? 0.8 : 0.55;
      for (var frame = 0; frame < clickFrames; frame++) {
        final envelope = math.sin(math.pi * frame / clickFrames) * math.exp(-5 * frame / clickFrames);
        final value = amplitude * envelope * math.sin(2 * math.pi * frequency * frame / sampleRate);
        data.setInt16((beat * framesPerBeat + frame) * 2, (value * 32767).round(), Endian.little);
      }
    }
    pcm = data.buffer.asUint8List();
  }

  static const sampleRate = 44100;
  late final int framesPerBeat;
  late final Uint8List pcm;
}

class TapTempo {
  final List<Duration> _taps = [];

  int? tap(Duration now) {
    if (_taps.isNotEmpty && (now - _taps.last > const Duration(seconds: 2) || now <= _taps.last)) {
      _taps.clear();
    }
    if (_taps.isNotEmpty && now - _taps.last < const Duration(milliseconds: 180)) return null;
    _taps.add(now);
    if (_taps.length > 5) _taps.removeAt(0);
    if (_taps.length < 2) return null;
    final average = (now - _taps.first).inMicroseconds / (_taps.length - 1);
    return (60000000 / average).round().clamp(40, 240);
  }
}
