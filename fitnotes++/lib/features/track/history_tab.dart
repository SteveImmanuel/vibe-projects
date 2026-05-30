import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/providers.dart';
import '../../core/util/dates.dart';
import '../../core/util/format.dart';

/// HISTORY tab: every set for an exercise, grouped by day (newest first), with
/// PR-setting sets flagged.
class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(exerciseHistoryProvider(exercise.id));
    final prIds = ref.watch(prSetIdsProvider(exercise.id));

    return histAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (sets) {
        if (sets.isEmpty) {
          return Center(
            child: Text('No history yet',
                style: TextStyle(color: Theme.of(context).hintColor)),
          );
        }
        final children = <Widget>[];
        String? currentDate;
        for (final s in sets) {
          if (s.date != currentDate) {
            currentDate = s.date;
            children.add(Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                Dates.sectionHeader(s.date),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ));
            children.add(const Divider(height: 1));
          }
          final isPr = prIds.contains(s.id);
          children.add(ListTile(
            dense: true,
            title: Row(
              children: [
                if (isPr) ...[
                  const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                ],
                Text(describeSet(
                  type: exercise.type,
                  effectiveWeight: s.rawWeight * s.weightMultiplier,
                  reps: s.reps,
                  distance: s.distance,
                  durationSeconds: s.durationSeconds,
                )),
              ],
            ),
            subtitle:
                (s.note != null && s.note!.isNotEmpty) ? Text(s.note!) : null,
          ));
        }
        return ListView(children: children);
      },
    );
  }
}
