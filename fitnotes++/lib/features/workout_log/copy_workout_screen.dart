import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/tables.dart';
import '../../core/providers.dart';
import '../../core/repositories/workout_repository.dart';
import '../../core/util/dates.dart';
import '../../core/util/format.dart';
import 'workout_calendar.dart';

/// Step 2 of copy: granular selection (Select All / per-exercise / per-set)
/// for a chosen source day. The day is picked via a calendar (step 1) before
/// arriving here, and can be changed from the header.
class CopyWorkoutScreen extends ConsumerStatefulWidget {
  const CopyWorkoutScreen({
    super.key,
    required this.targetDate,
    required this.sourceDate,
  });

  final String targetDate;
  final String sourceDate;

  @override
  ConsumerState<CopyWorkoutScreen> createState() => _CopyWorkoutScreenState();
}

class _CopyWorkoutScreenState extends ConsumerState<CopyWorkoutScreen> {
  late String _source = widget.sourceDate;
  bool _loading = true;
  List<LoggedSet> _sets = [];
  final Set<int> _selected = {};

  WorkoutRepository get _repo => ref.read(workoutRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _loadSource(_source);
  }

  Future<void> _loadSource(String date) async {
    setState(() => _loading = true);
    final sets = await _repo.dayLog(date);
    if (!mounted) return;
    setState(() {
      _source = date;
      _sets = sets;
      _selected
        ..clear()
        ..addAll(sets.map((s) => s.set.id));
      _loading = false;
    });
  }

  Future<void> _changeSource() async {
    final priors = await _repo.workoutDatesBefore(widget.targetDate);
    if (priors.isEmpty || !mounted) return;
    final picked = await pickCopyDay(context, ref,
        initialDate: _source, selectableDays: priors.toSet());
    if (picked != null) await _loadSource(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copy Workout')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sets.isEmpty
              ? Center(
                  child: Text('That workout has no sets',
                      style: TextStyle(color: Theme.of(context).hintColor)))
              : _content(),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _content() {
    final order = <int>[];
    final groups = <int, List<LoggedSet>>{};
    for (final s in _sets) {
      groups.putIfAbsent(s.set.exerciseId, () {
        order.add(s.set.exerciseId);
        return <LoggedSet>[];
      }).add(s);
    }
    final allIds = _sets.map((s) => s.set.id).toSet();
    final allSelected = allIds.isNotEmpty && _selected.length == allIds.length;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.event),
          title: Text('From ${Dates.navLabel(_source)}'),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: _changeSource,
        ),
        const Divider(height: 1),
        CheckboxListTile(
          title: const Text('Select All',
              style: TextStyle(fontWeight: FontWeight.w600)),
          value: allSelected,
          onChanged: (v) => setState(() {
            _selected.clear();
            if (v == true) _selected.addAll(allIds);
          }),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              for (final id in order) ..._exerciseSection(groups[id]!),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _exerciseSection(List<LoggedSet> exSets) {
    final type = ExerciseType.values[exSets.first.exerciseType];
    final ids = exSets.map((s) => s.set.id).toList();
    final allSel = ids.every(_selected.contains);
    return [
      Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: CheckboxListTile(
          dense: true,
          title: Text(exSets.first.exerciseName.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          value: allSel,
          onChanged: (v) => setState(() {
            if (v == true) {
              _selected.addAll(ids);
            } else {
              _selected.removeAll(ids);
            }
          }),
        ),
      ),
      for (final s in exSets)
        CheckboxListTile(
          dense: true,
          title: Text(describeSet(
            type: type,
            effectiveWeight: s.effectiveWeight,
            reps: s.set.reps,
            distance: s.set.distance,
            durationSeconds: s.set.durationSeconds,
          )),
          value: _selected.contains(s.set.id),
          onChanged: (v) => setState(() {
            if (v == true) {
              _selected.add(s.set.id);
            } else {
              _selected.remove(s.set.id);
            }
          }),
        ),
    ];
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: () => context.pop(), child: const Text('Cancel')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _selected.isEmpty ? null : _copy,
                child: Text('Copy (${_selected.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    // Preserve the source workout's order.
    final ids = _sets
        .where((s) => _selected.contains(s.set.id))
        .map((s) => s.set.id)
        .toList();
    final n = await _repo.copySetsToDate(ids, widget.targetDate);
    messenger.showSnackBar(SnackBar(content: Text('Copied $n sets')));
    nav.pop();
  }
}
