import 'dart:async';
import 'dart:typed_data';

import 'package:string_and_time/audio/audio_services.dart';

class FakeMicrophone implements MicrophoneInput {
  final stream = StreamController<Uint8List>.broadcast();
  bool permission = true;
  bool recording = false;
  int starts = 0;
  Completer<void>? startGate;

  @override
  Future<Stream<Uint8List>> start() async {
    starts++;
    await startGate?.future;
    if (!permission) throw MicrophonePermissionDenied();
    recording = true;
    return stream.stream;
  }

  @override
  Future<void> stop() async => recording = false;

  @override
  Future<void> dispose() => stream.close();
}

class FakeClicks implements ClickOutput {
  final events = StreamController<int?>.broadcast();
  bool playing = false;
  bool fail = false;
  int starts = 0;
  ({int bpm, int beats, bool accent, double volume})? settings;
  Completer<void>? startGate;

  @override
  Stream<int?> get beats => events.stream;

  @override
  Future<void> start({required int bpm, required int beats, required bool accent, required double volume}) async {
    await startGate?.future;
    if (fail) throw StateError('No audio device');
    playing = true;
    starts++;
    settings = (bpm: bpm, beats: beats, accent: accent, volume: volume);
  }

  @override
  Future<void> stop() async => playing = false;

  @override
  Future<void> dispose() => events.close();
}
