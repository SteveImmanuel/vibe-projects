import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:string_and_time/audio/pitch_detector.dart';
import 'package:string_and_time/practice_controller.dart';

import 'audio_fakes.dart';

void main() {
  late FakeMicrophone microphone;
  late FakeClicks clicks;
  late PracticeController controller;

  setUp(() {
    microphone = FakeMicrophone();
    clicks = FakeClicks();
    controller = PracticeController(microphone: microphone, clicks: clicks);
  });
  tearDown(() => controller.dispose());

  test('microphone PCM reaches the tuner and stale readings expire', () async {
    await controller.toggleTuner();
    final detected = Completer<void>();
    final expired = Completer<void>();
    controller.addListener(() {
      if (controller.frequency != null && !detected.isCompleted) detected.complete();
      if (detected.isCompleted && controller.frequency == null && !expired.isCompleted) expired.complete();
    });
    final pcm = ByteData(tunerFrameSize * 2);
    for (var i = 0; i < tunerFrameSize; i++) {
      pcm.setInt16(i * 2, (16000 * math.sin(2 * math.pi * 110 * i / tunerSampleRate)).round(), Endian.little);
    }
    microphone.stream.add(pcm.buffer.asUint8List());
    await detected.future.timeout(const Duration(seconds: 5));
    expect(controller.frequency, closeTo(110, 0.2));
    expect(controller.target?.label, 'A2');
    expect(controller.inTune, isTrue);
    await expired.future.timeout(const Duration(seconds: 2));
    expect(controller.frequency, isNull);
    expect(controller.target, isNull);
    expect(controller.listening, isTrue);
  });

  test('permission denial keeps the microphone off and allows retry', () async {
    microphone.permission = false;
    await controller.toggleTuner();
    expect(controller.listening, isFalse);
    expect(controller.error, contains('Microphone access'));
    microphone.permission = true;
    await controller.toggleTuner();
    expect(controller.error, isNull);
    expect(controller.listening, isTrue);
    await controller.suspend();
    expect(microphone.recording, isFalse);
  });

  test('leaving during the permission request cancels the eventual recording', () async {
    microphone.startGate = Completer<void>();
    final start = controller.toggleTuner();
    await Future<void>.delayed(Duration.zero);
    final stop = controller.suspend();
    microphone.startGate!.complete();
    await Future.wait([start, stop]);
    expect(microphone.recording, isFalse);
    expect(controller.listening, isFalse);
    expect(controller.busy, isFalse);
    controller.resume();
    expect(controller.listening, isFalse);
  });

  test('switching away during microphone startup never enables listening', () async {
    microphone.startGate = Completer<void>();
    final start = controller.toggleTuner();
    await Future<void>.delayed(Duration.zero);
    final switchTab = controller.selectTab(1);
    microphone.startGate!.complete();
    await Future.wait([start, switchTab]);
    expect(controller.tab, 1);
    expect(controller.listening, isFalse);
    expect(microphone.recording, isFalse);
  });

  test('audio failure clears playing state and can be retried', () async {
    await controller.selectTab(1);
    clicks.fail = true;
    await controller.toggleMetronome();
    expect(controller.playing, isFalse);
    expect(controller.error, isNotNull);
    clicks.fail = false;
    await controller.toggleMetronome();
    expect(controller.playing, isTrue);
    expect(controller.error, isNull);
    await controller.selectTab(0);
    expect(clicks.playing, isFalse);
  });

  test('switching tools stops an active microphone stream', () async {
    await controller.toggleTuner();
    expect(microphone.recording, isTrue);
    await controller.selectTab(1);
    expect(microphone.recording, isFalse);
    expect(controller.busy, isFalse);
  });

  test('backgrounding while playback starts releases the audio', () async {
    await controller.selectTab(1);
    clicks.startGate = Completer<void>();
    final start = controller.toggleMetronome();
    await Future<void>.delayed(Duration.zero);
    final stop = controller.suspend();
    clicks.startGate!.complete();
    await Future.wait([start, stop]);
    expect(clicks.playing, isFalse);
    expect(controller.playing, isFalse);
  });

  test('native audio focus loss stops the visual beat', () async {
    await controller.selectTab(1);
    await controller.toggleMetronome();
    clicks.events.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(controller.beat, 2);
    clicks.events.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(controller.playing, isFalse);
    expect(controller.beat, isNull);
  });
}
