import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/tables.dart';
import '../../core/providers.dart';
import '../../core/repositories/workout_repository.dart';
import '../../core/util/dates.dart';
import '../../core/util/format.dart';

/// The Workout Log home: a single day's logged exercises with date navigation.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final log = ref.watch(dayLogProvider(date));
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitNotes++'),
        actions: [
          IconButton(
            tooltip: 'Jump to date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickDate(context, ref, date),
          ),
          IconButton(
            tooltip: 'Add exercise',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/exercises?pick=1&date=$date'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'exercises') context.push('/exercises');
              if (v == 'settings') context.push('/settings');
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'exercises', child: Text('All Exercises')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _DateBar(date: date),
          const Divider(height: 1),
          Expanded(
            child: log.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load workout:\n$e',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (sets) => sets.isEmpty
                  ? _EmptyLog(date: date)
                  : _DayLog(date: date, sets: sets),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(
      BuildContext context, WidgetRef ref, String date) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: Dates.parse(date),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).set(Dates.iso(picked));
    }
  }
}

class _DateBar extends ConsumerWidget {
  const _DateBar({required this.date});
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(selectedDateProvider.notifier);
    return Row(
      children: [
        IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: notifier.previous),
        Expanded(
          child: Center(
            child: TextButton(
              onPressed: notifier.goToday,
              child: Text(Dates.navLabel(date),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.chevron_right), onPressed: notifier.next),
      ],
    );
  }
}

class _EmptyLog extends ConsumerWidget {
  const _EmptyLog({required this.date});
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Workout Log Empty',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: 32),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add),
            label: const Text('Start New Workout'),
            onPressed: () => context.push('/exercises?pick=1&date=$date'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy Previous Workout'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final n = await ref
                  .read(workoutRepositoryProvider)
                  .copyPreviousWorkout(date);
              messenger.showSnackBar(SnackBar(
                  content: Text(n == 0
                      ? 'No previous workout to copy'
                      : 'Copied $n sets')));
            },
          ),
        ],
      ),
    );
  }
}

class _DayLog extends StatelessWidget {
  const _DayLog({required this.date, required this.sets});
  final String date;
  final List<LoggedSet> sets;

  @override
  Widget build(BuildContext context) {
    final order = <int>[];
    final groups = <int, List<LoggedSet>>{};
    for (final s in sets) {
      final id = s.set.exerciseId;
      groups.putIfAbsent(id, () {
        order.add(id);
        return <LoggedSet>[];
      }).add(s);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        for (final id in order)
          _ExerciseGroup(date: date, exerciseId: id, sets: groups[id]!),
      ],
    );
  }
}

class _ExerciseGroup extends StatelessWidget {
  const _ExerciseGroup(
      {required this.date, required this.exerciseId, required this.sets});
  final String date;
  final int exerciseId;
  final List<LoggedSet> sets;

  @override
  Widget build(BuildContext context) {
    final first = sets.first;
    final type = ExerciseType.values[first.exerciseType];
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/log/$exerciseId?date=$date'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(radius: 6, backgroundColor: Color(first.colorArgb)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(first.exerciseName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16))),
                const Icon(Icons.chevron_right, size: 18),
              ]),
              const SizedBox(height: 6),
              for (var i = 0; i < sets.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    SizedBox(
                        width: 24,
                        child: Text('${i + 1}',
                            style:
                                TextStyle(color: Theme.of(context).hintColor))),
                    Text(describeSet(
                      type: type,
                      effectiveWeight: sets[i].effectiveWeight,
                      reps: sets[i].set.reps,
                      distance: sets[i].set.distance,
                      durationSeconds: sets[i].set.durationSeconds,
                    )),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
