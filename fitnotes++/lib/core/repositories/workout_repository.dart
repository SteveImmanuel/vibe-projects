import 'package:drift/drift.dart';

import '../database/database.dart';

/// A logged set joined with the display info its exercise needs (for the
/// day-log home screen).
class LoggedSet {
  LoggedSet({
    required this.set,
    required this.exerciseName,
    required this.colorArgb,
    required this.exerciseType,
  });

  final WorkoutSet set;
  final String exerciseName;
  final int colorArgb;
  final int exerciseType;

  double get effectiveWeight => set.rawWeight * set.weightMultiplier;
}

class WorkoutRepository {
  WorkoutRepository(this.db);

  final AppDatabase db;

  /// Sets for one exercise on one day (the TRACK tab list), in entry order.
  Stream<List<WorkoutSet>> watchSetsForExerciseOnDate(
          int exerciseId, String date) =>
      (db.select(db.workoutSets)
            ..where((s) => s.exerciseId.equals(exerciseId) & s.date.equals(date))
            ..orderBy([
              (s) => OrderingTerm.asc(s.createdAt),
              (s) => OrderingTerm.asc(s.id),
            ]))
          .watch();

  /// All sets ever logged for an exercise, newest day first (HISTORY tab).
  Stream<List<WorkoutSet>> watchExerciseHistory(int exerciseId) =>
      (db.select(db.workoutSets)
            ..where((s) => s.exerciseId.equals(exerciseId))
            ..orderBy([
              (s) => OrderingTerm.desc(s.date),
              (s) => OrderingTerm.asc(s.createdAt),
              (s) => OrderingTerm.asc(s.id),
            ]))
          .watch();

  /// Every set on a given day, with exercise display info, in entry order.
  Stream<List<LoggedSet>> watchDayLog(String date) {
    const sql = '''
      SELECT s.*, e.name AS ex_name, e.type AS ex_type, c.color_argb AS color_argb
      FROM workout_sets s
      JOIN exercises e ON e.id = s.exercise_id
      JOIN categories c ON c.id = e.category_id
      WHERE s.date = ?
      ORDER BY s.created_at, s.id
    ''';
    return db
        .customSelect(sql,
            variables: [Variable.withString(date)],
            readsFrom: {db.workoutSets, db.exercises, db.categories})
        .watch()
        .map((rows) => rows.map((r) {
              final set = db.workoutSets.map(r.data);
              return LoggedSet(
                set: set,
                exerciseName: r.read<String>('ex_name'),
                colorArgb: r.read<int>('color_argb'),
                exerciseType: r.read<int>('ex_type'),
              );
            }).toList());
  }

  Future<String?> previousWorkoutDate(String before) async {
    final row = await db
        .customSelect('SELECT MAX(date) AS d FROM workout_sets WHERE date < ?',
            variables: [Variable.withString(before)])
        .getSingleOrNull();
    return row?.readNullable<String>('d');
  }

  Stream<Set<String>> watchWorkoutDates() => db
      .customSelect('SELECT DISTINCT date FROM workout_sets',
          readsFrom: {db.workoutSets})
      .watch()
      .map((rows) => rows.map((r) => r.read<String>('date')).toSet());

  Future<int> addSet({
    required int exerciseId,
    required String date,
    double rawWeight = 0,
    double weightMultiplier = 1.0,
    int reps = 0,
    double distance = 0,
    int durationSeconds = 0,
  }) =>
      db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            exerciseId: exerciseId,
            date: date,
            createdAt: DateTime.now(),
            rawWeight: Value(rawWeight),
            weightMultiplier: Value(weightMultiplier),
            reps: Value(reps),
            distance: Value(distance),
            durationSeconds: Value(durationSeconds),
          ));

  Future<void> updateSet(
    int id, {
    double? rawWeight,
    int? reps,
    double? distance,
    int? durationSeconds,
  }) =>
      (db.update(db.workoutSets)..where((s) => s.id.equals(id))).write(
        WorkoutSetsCompanion(
          rawWeight: rawWeight == null ? const Value.absent() : Value(rawWeight),
          reps: reps == null ? const Value.absent() : Value(reps),
          distance: distance == null ? const Value.absent() : Value(distance),
          durationSeconds: durationSeconds == null
              ? const Value.absent()
              : Value(durationSeconds),
        ),
      );

  Future<void> deleteSet(int id) =>
      (db.delete(db.workoutSets)..where((s) => s.id.equals(id))).go();

  Future<void> setComplete(int id, bool value) =>
      (db.update(db.workoutSets)..where((s) => s.id.equals(id)))
          .write(WorkoutSetsCompanion(isComplete: Value(value)));

  Future<void> setNote(int id, String? note) =>
      (db.update(db.workoutSets)..where((s) => s.id.equals(id)))
          .write(WorkoutSetsCompanion(note: Value(note)));

  /// Clone the most recent prior day's sets into [date]. Returns the count.
  Future<int> copyPreviousWorkout(String date) async {
    final prev = await previousWorkoutDate(date);
    if (prev == null) return 0;
    final sets = await (db.select(db.workoutSets)
          ..where((s) => s.date.equals(prev))
          ..orderBy([
            (s) => OrderingTerm.asc(s.createdAt),
            (s) => OrderingTerm.asc(s.id),
          ]))
        .get();
    final now = DateTime.now();
    await db.batch((b) {
      for (final s in sets) {
        b.insert(
          db.workoutSets,
          WorkoutSetsCompanion.insert(
            exerciseId: s.exerciseId,
            date: date,
            createdAt: now,
            rawWeight: Value(s.rawWeight),
            weightMultiplier: Value(s.weightMultiplier),
            reps: Value(s.reps),
            distance: Value(s.distance),
            durationSeconds: Value(s.durationSeconds),
          ),
        );
      }
    });
    return sets.length;
  }

  /// Distinct workout days strictly before [date], newest first.
  Future<List<String>> workoutDatesBefore(String date) async {
    final rows = await db
        .customSelect(
          'SELECT DISTINCT date FROM workout_sets WHERE date < ? ORDER BY date DESC',
          variables: [Variable.withString(date)],
        )
        .get();
    return rows.map((r) => r.read<String>('date')).toList();
  }

  /// One-shot fetch of a day's sets (with exercise display info).
  Future<List<LoggedSet>> dayLog(String date) => watchDayLog(date).first;

  /// Copy the given sets (by id) into [targetDate], preserving their order.
  Future<int> copySetsToDate(List<int> setIds, String targetDate) async {
    if (setIds.isEmpty) return 0;
    final rows = await (db.select(db.workoutSets)
          ..where((s) => s.id.isIn(setIds)))
        .get();
    final byId = {for (final s in rows) s.id: s};
    final ordered =
        setIds.map((id) => byId[id]).whereType<WorkoutSet>().toList();
    final now = DateTime.now();
    await db.batch((b) {
      for (final s in ordered) {
        b.insert(
          db.workoutSets,
          WorkoutSetsCompanion.insert(
            exerciseId: s.exerciseId,
            date: targetDate,
            createdAt: now,
            rawWeight: Value(s.rawWeight),
            weightMultiplier: Value(s.weightMultiplier),
            reps: Value(s.reps),
            distance: Value(s.distance),
            durationSeconds: Value(s.durationSeconds),
          ),
        );
      }
    });
    return ordered.length;
  }

  /// For every workout day, the distinct category colors trained that day
  /// (ordered by category) — used to render calendar dots.
  Future<Map<String, List<int>>> workoutDayCategoryColors() async {
    final rows = await db.customSelect(
      'SELECT s.date AS date, c.color_argb AS color '
      'FROM workout_sets s '
      'JOIN exercises e ON e.id = s.exercise_id '
      'JOIN categories c ON c.id = e.category_id '
      'GROUP BY s.date, c.id '
      'ORDER BY s.date, c.sort_order, c.id',
      readsFrom: {db.workoutSets, db.exercises, db.categories},
    ).get();
    final map = <String, List<int>>{};
    for (final r in rows) {
      (map[r.read<String>('date')] ??= []).add(r.read<int>('color'));
    }
    return map;
  }
}
