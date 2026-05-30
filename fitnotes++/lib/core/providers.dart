import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/database.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/stats_repository.dart';
import 'repositories/workout_repository.dart';
import 'util/dates.dart';

/// The single app-wide database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openAppConnection());
  ref.onDispose(db.close);
  return db;
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
    (ref) => ExerciseRepository(ref.watch(databaseProvider)));

final workoutRepositoryProvider = Provider<WorkoutRepository>(
    (ref) => WorkoutRepository(ref.watch(databaseProvider)));

final categoriesProvider = StreamProvider<List<Category>>(
    (ref) => ref.watch(exerciseRepositoryProvider).watchCategories());

final settingsRepositoryProvider = Provider<SettingsRepository>(
    (ref) => SettingsRepository(ref.watch(databaseProvider)));

final settingsProvider = StreamProvider<AppSettingsRow>(
    (ref) => ref.watch(settingsRepositoryProvider).watch());

/// The day currently shown on the Workout Log. Shared across the home UI.
class SelectedDateNotifier extends Notifier<String> {
  @override
  String build() => Dates.today();

  void set(String isoDate) => state = isoDate;
  void next() => state = Dates.shift(state, 1);
  void previous() => state = Dates.shift(state, -1);
  void goToday() => state = Dates.today();
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, String>(SelectedDateNotifier.new);

/// Filter for the exercise list screen.
typedef ExerciseFilter = ({String search, int? categoryId});

final exerciseListProvider = StreamProvider.autoDispose
    .family<List<ExerciseListItem>, ExerciseFilter>((ref, filter) {
  return ref
      .watch(exerciseRepositoryProvider)
      .watchExercises(search: filter.search, categoryId: filter.categoryId);
});

final dayLogProvider = StreamProvider.autoDispose
    .family<List<LoggedSet>, String>((ref, date) =>
        ref.watch(workoutRepositoryProvider).watchDayLog(date));

typedef ExerciseDateKey = ({int exerciseId, String date});

final exerciseSetsProvider = StreamProvider.autoDispose
    .family<List<WorkoutSet>, ExerciseDateKey>((ref, key) => ref
        .watch(workoutRepositoryProvider)
        .watchSetsForExerciseOnDate(key.exerciseId, key.date));

final exerciseProvider = StreamProvider.autoDispose
    .family<Exercise, int>((ref, id) =>
        ref.watch(exerciseRepositoryProvider).watchExercise(id));

/// All sets for an exercise (history + analytics source).
final exerciseHistoryProvider = StreamProvider.autoDispose
    .family<List<WorkoutSet>, int>((ref, id) =>
        ref.watch(workoutRepositoryProvider).watchExerciseHistory(id));

/// IDs of PR-setting sets, recomputed reactively from the history stream.
final prSetIdsProvider =
    Provider.autoDispose.family<Set<int>, int>((ref, id) {
  final history =
      ref.watch(exerciseHistoryProvider(id)).asData?.value ?? const <WorkoutSet>[];
  return Stats.personalRecordSetIds(history);
});

typedef GraphKey = ({int exerciseId, GraphMetric metric});

final graphProvider =
    Provider.autoDispose.family<List<MetricPoint>, GraphKey>((ref, key) {
  final history = ref.watch(exerciseHistoryProvider(key.exerciseId)).asData?.value ??
      const <WorkoutSet>[];
  return Stats.graph(history, key.metric);
});
