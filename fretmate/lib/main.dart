import 'dart:async';

import 'package:flutter/material.dart';

import 'audio/audio_services.dart';
import 'practice_controller.dart';
import 'ui/metronome_view.dart';
import 'ui/tuner_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FretmateApp());
}

class FretmateApp extends StatelessWidget {
  const FretmateApp({super.key, this.controller});

  final PracticeController? controller;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF203B36);
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF286957), surface: const Color(0xFFF8F7F2));
    return MaterialApp(
      title: 'Fretmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        textTheme: ThemeData.light().textTheme.apply(bodyColor: ink, displayColor: ink),
        appBarTheme: AppBarTheme(backgroundColor: scheme.surface, foregroundColor: ink, centerTitle: false),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 56),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      home: PracticeScreen(controller: controller),
    );
  }
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, this.controller});

  final PracticeController? controller;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with WidgetsBindingObserver {
  late final PracticeController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? PracticeController(microphone: DeviceMicrophone(), clicks: AndroidClickOutput());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(controller.suspend());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        titleSpacing: 24,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FRETMATE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2.2)),
            SizedBox(height: 4),
            Text('A little practice, every day.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About Fretmate',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Fretmate',
              applicationVersion: '1.0.0',
              children: const [
                Text(
                  'Standard six-string tuning, with A4 = 440 Hz.\n\nPluck one open string at a time. Audio is processed on your device and is never saved. Switching tools or leaving the app stops audio.',
                ),
              ],
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: ValueKey(controller.tab),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          controller.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (controller.tab == 0) TunerView(controller: controller) else MetronomeView(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.tab,
        onDestinationSelected: controller.selectTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.graphic_eq_rounded), label: 'Tuner'),
          NavigationDestination(icon: Icon(Icons.av_timer_rounded), label: 'Metronome'),
        ],
      ),
    ),
  );
}
