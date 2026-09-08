import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio/audio_services.dart';
import 'audio/click_track.dart';
import 'audio/pitch_detector.dart';

class PracticeController extends ChangeNotifier {
  PracticeController({required MicrophoneInput microphone, required ClickOutput clicks})
    : _microphone = microphone, _clicks = clicks {
    _beatSubscription = _clicks.beats.listen((value) {
      if (value == null) {
        playing = false;
        beat = null;
      } else if (playing) {
        beat = value;
      }
      _notify();
    }, onError: (Object error) => _audioError('Playback interrupted. Tap Start to try again.'));
  }

  final MicrophoneInput _microphone;
  final ClickOutput _clicks;
  final TapTempo _tapTempo = TapTempo();
  final Stopwatch _clock = Stopwatch()..start();
  final List<double> _recentPitches = [];
  late final StreamSubscription<int?> _beatSubscription;
  StreamSubscription<Object?>? _microphoneSubscription;
  Future<void> _pending = Future.value();
  Timer? _stalePitch;
  int _epoch = 0;
  int _operations = 0;
  bool _analyzing = false;
  bool _foreground = true;
  bool _disposed = false;

  int tab = 0;
  bool listening = false;
  bool playing = false;
  double? frequency;
  GuitarString? selectedString;
  String? error;
  int bpm = 100;
  int beatsPerBar = 4;
  bool accent = true;
  double volume = 0.7;
  int? beat;

  bool get busy => _operations > 0;
  GuitarString? get target => selectedString ?? (frequency == null ? null : nearestString(frequency!));
  double? get cents => frequency == null || target == null ? null : centsBetween(frequency!, target!.frequency);
  bool get inTune => cents != null && cents!.abs() <= 5;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    if (_disposed) return Future.value();
    _operations++;
    _notify();
    _pending = _pending.then((_) async {
      try {
        if (!_disposed) await action();
      } on MicrophonePermissionDenied {
        error = 'Microphone access is needed to tune. Allow it when prompted, or enable it in Android Settings → Apps → String & Time → Permissions.';
        await _recover();
      } catch (_) {
        error = 'Audio is unavailable. Close other audio apps and try again.';
        await _recover();
      } finally {
        _operations--;
        _notify();
      }
    });
    return _pending;
  }

  Future<void> _recover() async {
    try {
      await _stopAudio();
    } catch (_) {
      error = 'Audio could not be released. Close and reopen String & Time.';
    }
  }

  Future<void> selectTab(int value) {
    if (value == tab) return _pending;
    tab = value;
    _epoch++;
    error = null;
    return _enqueue(_stopAudio);
  }

  void selectString(GuitarString? value) {
    selectedString = value;
    _notify();
  }

  Future<void> toggleTuner() => _enqueue(() async {
    error = null;
    if (listening) return _stopAudio();
    if (!_foreground || tab != 0) return;
    await _stopAudio();
    final session = _epoch;
    final stream = await _microphone.start();
    if (session != _epoch || !_foreground || _disposed) {
      await _microphone.stop();
      return;
    }
    listening = true;
    final decoder = PcmFrameDecoder();
    _microphoneSubscription = stream.listen((bytes) {
      for (final frame in decoder.add(bytes)) {
        if (_analyzing || !listening) continue;
        _analyzing = true;
        compute(detectPitch, frame).then((pitch) {
          if (!_disposed && listening && session == _epoch) _acceptPitch(pitch);
        }).catchError((Object error) {
          if (session == _epoch) _audioError('Could not analyze the microphone. Tap Listen to try again.');
        }).whenComplete(() => _analyzing = false);
      }
    }, onError: (Object error) {
      if (session == _epoch) _audioError('Microphone interrupted. Tap Listen to try again.');
    }, onDone: () {
      if (session == _epoch && listening) _audioError('Microphone stopped. Tap Listen to try again.');
    });
  });

  void _acceptPitch(double? pitch) {
    if (pitch == null) return;
    if (_recentPitches.isNotEmpty && centsBetween(pitch, _recentPitches.last).abs() > 80) _recentPitches.clear();
    _recentPitches.add(pitch);
    if (_recentPitches.length > 3) _recentPitches.removeAt(0);
    final sorted = [..._recentPitches]..sort();
    frequency = sorted[sorted.length ~/ 2];
    _stalePitch?.cancel();
    _stalePitch = Timer(const Duration(milliseconds: 600), () {
      frequency = null;
      _recentPitches.clear();
      _notify();
    });
    _notify();
  }

  void _audioError(String message) {
    _epoch++;
    unawaited(_enqueue(() async {
      error = message;
      await _stopAudio();
    }));
  }

  Future<void> toggleMetronome() => _enqueue(() async {
    error = null;
    if (playing) return _stopAudio();
    if (!_foreground || tab != 1) return;
    await _stopAudio();
    await _startClicks();
  });

  Future<void> _startClicks() async {
    if (!_foreground || _disposed) return;
    final session = _epoch;
    await _clicks.start(bpm: bpm, beats: beatsPerBar, accent: accent, volume: volume);
    if (session != _epoch || !_foreground || _disposed) {
      await _clicks.stop();
      return;
    }
    playing = true;
    beat = 0;
  }

  void setTempo(int value) {
    bpm = value.clamp(40, 240);
    _notify();
  }

  void tapTempo() {
    final value = _tapTempo.tap(_clock.elapsed);
    if (value == null) return;
    setTempo(value);
    unawaited(applyMetronomeSettings());
  }

  void setBeats(int value) {
    beatsPerBar = value;
    unawaited(applyMetronomeSettings());
  }

  void setAccent(bool value) {
    accent = value;
    unawaited(applyMetronomeSettings());
  }

  void setVolume(double value) {
    volume = value.clamp(0, 1);
    _notify();
  }

  Future<void> applyMetronomeSettings() => _enqueue(() async {
    if (!playing) return;
    await _startClicks();
  });

  Future<void> _stopAudio() async {
    _epoch++;
    listening = false;
    playing = false;
    frequency = null;
    beat = null;
    _recentPitches.clear();
    _stalePitch?.cancel();
    await _microphoneSubscription?.cancel();
    _microphoneSubscription = null;
    try {
      await _microphone.stop();
    } finally {
      await _clicks.stop();
    }
  }

  Future<void> suspend() {
    _foreground = false;
    _epoch++;
    return _enqueue(_stopAudio);
  }

  void resume() => _foreground = true;

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _stalePitch?.cancel();
    unawaited(_pending.then((_) async {
      await _beatSubscription.cancel();
      try {
        await _stopAudio();
      } finally {
        await _microphone.dispose();
        await _clicks.dispose();
      }
    }).catchError((Object error) => debugPrint('Audio cleanup failed: $error')));
    super.dispose();
  }
}
