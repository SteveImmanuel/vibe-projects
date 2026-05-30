import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';

void main() {
  runApp(const ProviderScope(child: FitNotesApp()));
}

class FitNotesApp extends StatelessWidget {
  const FitNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitNotes++',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const _BootScreen(),
    );
  }
}

/// Temporary placeholder until the Workout Log home lands in M2.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FitNotes++')),
      body: const Center(child: Text('Scaffolding complete — M0 ✓')),
    );
  }
}
