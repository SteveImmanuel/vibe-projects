import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fretmate/main.dart';
import 'package:fretmate/practice_controller.dart';

import 'audio_fakes.dart';

void main() {
  testWidgets('tuner selection, listening, navigation and metronome controls', (tester) async {
    final microphone = FakeMicrophone();
    final clicks = FakeClicks();
    final controller = PracticeController(microphone: microphone, clicks: clicks);
    addTearDown(controller.dispose);
    await tester.pumpWidget(FretmateApp(controller: controller));

    expect(find.text('Find your sound.'), findsOneWidget);
    expect(microphone.starts, 0);
    expect(clicks.starts, 0);
    await tester.ensureVisible(find.text('6 · E2'));
    await tester.tap(find.text('6 · E2'));
    await tester.pumpAndSettle();
    expect(controller.selectedString?.label, 'E2');

    await tester.ensureVisible(find.text('Listen & tune'));
    await tester.tap(find.text('Listen & tune'));
    await tester.pumpAndSettle();
    expect(microphone.recording, isTrue);
    expect(find.text('Stop listening'), findsOneWidget);

    await tester.tap(find.text('Metronome'));
    await tester.pumpAndSettle();
    // Broadcast stream cancellation completes outside the widget test clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(controller.tab, 1);
    expect(controller.busy, isFalse);
    expect(microphone.recording, isFalse);
    expect(find.text('Settle into rhythm.'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase tempo'));
    await tester.pumpAndSettle();
    expect(find.text('101'), findsOneWidget);
    await tester.ensureVisible(find.text('3 beats'));
    await tester.tap(find.text('3 beats'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start metronome'));
    await tester.tap(find.text('Start metronome'));
    await tester.pumpAndSettle();
    expect(clicks.settings, (bpm: 101, beats: 3, accent: true, volume: 0.7));
    expect(clicks.playing, isTrue);
    await tester.tap(find.text('Tuner'));
    await tester.pumpAndSettle();
    expect(clicks.playing, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screen and enlarged text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = PracticeController(microphone: FakeMicrophone(), clicks: FakeClicks());
    addTearDown(controller.dispose);
    await tester.pumpWidget(FretmateApp(controller: controller));
    await tester.ensureVisible(find.text('Listen & tune'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Metronome'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start metronome'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
