import '../database/database.dart';
import '../util/onerm.dart';

/// A progress-graph metric (the v1 subset of FitNotes' 13).
enum GraphMetric {
  estimated1rm('Estimated 1RM'),
  maxWeight('Max Weight'),
  workoutVolume('Workout Volume');

  const GraphMetric(this.label);
  final String label;
}

/// A single point on a progress graph: a per-day aggregate.
typedef MetricPoint = ({String date, double value});

/// Pure analytics over a list of sets, so results react to DB streams without
/// extra queries. All entry points accept a [sinceDate] window — the epoch in
/// v1 (all-time); Feature 2 (PR reset) will pass the latest reset date.
class Stats {
  Stats._();

  static const String allTime = '0000-01-01';

  static double effective(WorkoutSet s) => s.rawWeight * s.weightMultiplier;

  static List<WorkoutSet> _chronological(List<WorkoutSet> sets) {
    final out = [...sets];
    out.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return out;
  }

  /// IDs of the sets that set a personal record (heaviest effective weight for
  /// their rep-count) within the window starting at [sinceDate].
  static Set<int> personalRecordSetIds(List<WorkoutSet> sets,
      {String sinceDate = allTime}) {
    final best = <int, double>{};
    final prIds = <int>{};
    for (final s in _chronological(sets)) {
      if (s.date.compareTo(sinceDate) < 0 || s.reps <= 0) continue;
      final eff = effective(s);
      if (eff <= 0) continue;
      final prev = best[s.reps];
      if (prev == null || eff > prev) {
        best[s.reps] = eff;
        prIds.add(s.id);
      }
    }
    return prIds;
  }

  /// Per-day points for [metric], oldest first.
  static List<MetricPoint> graph(List<WorkoutSet> sets, GraphMetric metric,
      {String sinceDate = allTime}) {
    final byDay = <String, List<WorkoutSet>>{};
    for (final s in sets) {
      if (s.date.compareTo(sinceDate) < 0) continue;
      (byDay[s.date] ??= []).add(s);
    }
    final points = <MetricPoint>[];
    byDay.forEach((date, daySets) {
      var value = 0.0;
      for (final s in daySets) {
        final eff = effective(s);
        switch (metric) {
          case GraphMetric.estimated1rm:
            final e = OneRm.brzycki(eff, s.reps);
            if (e > value) value = e;
          case GraphMetric.maxWeight:
            if (eff > value) value = eff;
          case GraphMetric.workoutVolume:
            value += eff * s.reps;
        }
      }
      points.add((date: date, value: value));
    });
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }
}
