import 'package:drift/drift.dart' show Value;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/import/fitnotes_importer.dart';
import '../../core/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => ListView(
          children: [
            _header(context, 'SETTINGS'),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_themeLabel(s.themeMode)),
              onTap: () async {
                final v = await _pickOption<int>(context, 'Theme',
                    const {0: 'System', 1: 'Light', 2: 'Dark'}, s.themeMode);
                if (v != null) {
                  _update(ref, AppSettingsCompanion(themeMode: Value(v)));
                }
              },
            ),
            const ListTile(
              title: Text('Unit System'),
              subtitle: Text('Metric (kg)'),
              enabled: false,
            ),
            ListTile(
              title: const Text('Calendar Week Start'),
              subtitle: Text(s.firstDayOfWeek == 7 ? 'Sunday' : 'Monday'),
              onTap: () => _update(ref,
                  AppSettingsCompanion(
                      firstDayOfWeek: Value(s.firstDayOfWeek == 7 ? 1 : 7))),
            ),
            ListTile(
              title: const Text('Default Weight Increment'),
              subtitle: Text('${s.defaultWeightIncrement} kg'),
              onTap: () async {
                final v = await _pickOption<double>(
                  context,
                  'Default Weight Increment',
                  {
                    0.5: '0.5 kg',
                    1.0: '1 kg',
                    1.25: '1.25 kg',
                    2.5: '2.5 kg',
                    5.0: '5 kg',
                  },
                  s.defaultWeightIncrement,
                );
                if (v != null) {
                  _update(ref,
                      AppSettingsCompanion(defaultWeightIncrement: Value(v)));
                }
              },
            ),
            ListTile(
              title: const Text('Rest Timer'),
              subtitle: Text('${s.restTimerSeconds}s'),
              onTap: () async {
                final v = await _pickOption<int>(
                  context,
                  'Rest Timer',
                  const {
                    30: '30s',
                    60: '60s',
                    90: '90s',
                    120: '2:00',
                    180: '3:00',
                    300: '5:00',
                  },
                  s.restTimerSeconds,
                );
                if (v != null) {
                  _update(ref, AppSettingsCompanion(restTimerSeconds: Value(v)));
                }
              },
            ),
            SwitchListTile(
              title: const Text('Rest Timer Vibrate'),
              value: s.restTimerVibrate,
              onChanged: (v) => _update(
                  ref, AppSettingsCompanion(restTimerVibrate: Value(v))),
            ),
            SwitchListTile(
              title: const Text('Rest Timer Auto-Start'),
              subtitle: const Text('Start the timer after saving a set'),
              value: s.restTimerAutoStart,
              onChanged: (v) => _update(
                  ref, AppSettingsCompanion(restTimerAutoStart: Value(v))),
            ),
            SwitchListTile(
              title: const Text('Track Personal Records'),
              subtitle: const Text('Flag record sets with a trophy'),
              value: s.trackPersonalRecords,
              onChanged: (v) => _update(
                  ref, AppSettingsCompanion(trackPersonalRecords: Value(v))),
            ),
            SwitchListTile(
              title: const Text('Mark Sets Complete'),
              subtitle: const Text('Show a checkbox on each set'),
              value: s.markSetsComplete,
              onChanged: (v) => _update(
                  ref, AppSettingsCompanion(markSetsComplete: Value(v))),
            ),
            SwitchListTile(
              title: const Text('Keep Screen On'),
              value: s.keepScreenOn,
              onChanged: (v) =>
                  _update(ref, AppSettingsCompanion(keepScreenOn: Value(v))),
            ),
            _header(context, 'DATA'),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Import FitNotes Backup'),
              subtitle: const Text('Load a .fitnotes SQLite backup'),
              onTap: () => _import(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.5)),
      );

  String _themeLabel(int mode) =>
      switch (mode) { 1 => 'Light', 2 => 'Dark', _ => 'System' };

  void _update(WidgetRef ref, AppSettingsCompanion changes) =>
      ref.read(settingsRepositoryProvider).update(changes);

  Future<T?> _pickOption<T>(BuildContext context, String title,
      Map<T, String> options, T current) {
    return showDialog<T>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(title),
        children: [
          for (final e in options.entries)
            ListTile(
              title: Text(e.value),
              trailing: e.key == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, e.key),
            ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await openFile();
    if (file == null) return;
    final path = file.path;
    messenger.showSnackBar(const SnackBar(content: Text('Importing…')));
    try {
      final res = await FitNotesImporter(ref.read(databaseProvider))
          .importFromFile(path);
      messenger.showSnackBar(SnackBar(
          content: Text(
              'Imported ${res.exercises} exercises and ${res.sets} sets')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }
}
