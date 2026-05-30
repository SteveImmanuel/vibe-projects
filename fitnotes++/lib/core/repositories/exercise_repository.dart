import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/tables.dart';

/// An exercise plus its display category and usage stats (for the list).
class ExerciseListItem {
  ExerciseListItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.colorArgb,
    required this.type,
    required this.isFavourite,
    required this.workoutCount,
    required this.lastDate,
  });

  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final int colorArgb;
  final ExerciseType type;
  final bool isFavourite;
  final int workoutCount;
  final String? lastDate;
}

class ExerciseRepository {
  ExerciseRepository(this.db);

  final AppDatabase db;

  Stream<List<Category>> watchCategories() => (db.select(db.categories)
        ..orderBy([(c) => OrderingTerm(expression: c.name)]))
      .watch();

  Future<List<Category>> getCategories() => (db.select(db.categories)
        ..orderBy([(c) => OrderingTerm(expression: c.name)]))
      .get();

  Stream<List<ExerciseListItem>> watchExercises({
    String? search,
    int? categoryId,
  }) {
    final where = <String>['e.archived = 0'];
    final vars = <Variable>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add("e.name LIKE '%' || ? || '%'"); // LIKE is case-insensitive (ASCII)
      vars.add(Variable.withString(search.trim()));
    }
    if (categoryId != null) {
      where.add('e.category_id = ?');
      vars.add(Variable.withInt(categoryId));
    }
    final sql = '''
      SELECT e.id, e.name, e.category_id, e.type, e.is_favourite,
             c.name AS category_name, c.color_argb AS color_argb,
             (SELECT COUNT(DISTINCT s.date) FROM workout_sets s
                WHERE s.exercise_id = e.id) AS workout_count,
             (SELECT MAX(s.date) FROM workout_sets s
                WHERE s.exercise_id = e.id) AS last_date
      FROM exercises e
      JOIN categories c ON c.id = e.category_id
      WHERE ${where.join(' AND ')}
      ORDER BY e.name COLLATE NOCASE
    ''';
    return db
        .customSelect(sql,
            variables: vars,
            readsFrom: {db.exercises, db.categories, db.workoutSets})
        .watch()
        .map((rows) => rows
            .map((r) => ExerciseListItem(
                  id: r.read<int>('id'),
                  name: r.read<String>('name'),
                  categoryId: r.read<int>('category_id'),
                  categoryName: r.read<String>('category_name'),
                  colorArgb: r.read<int>('color_argb'),
                  type: ExerciseType.values[r.read<int>('type')],
                  isFavourite: r.read<int>('is_favourite') == 1,
                  workoutCount: r.read<int>('workout_count'),
                  lastDate: r.readNullable<String>('last_date'),
                ))
            .toList());
  }

  Future<Exercise> getExercise(int id) =>
      (db.select(db.exercises)..where((e) => e.id.equals(id))).getSingle();

  Stream<Exercise> watchExercise(int id) =>
      (db.select(db.exercises)..where((e) => e.id.equals(id))).watchSingle();

  Future<int> createExercise({
    required String name,
    required int categoryId,
    required ExerciseType type,
    String? notes,
  }) =>
      db.into(db.exercises).insert(ExercisesCompanion.insert(
            name: name,
            categoryId: categoryId,
            type: Value(type),
            notes: Value(notes),
          ));

  Future<void> updateExercise({
    required int id,
    required String name,
    required int categoryId,
    required ExerciseType type,
    String? notes,
  }) =>
      (db.update(db.exercises)..where((e) => e.id.equals(id))).write(
        ExercisesCompanion(
          name: Value(name),
          categoryId: Value(categoryId),
          type: Value(type),
          notes: Value(notes),
        ),
      );

  Future<int> createCategory({required String name, required int colorArgb}) =>
      db.into(db.categories).insert(
            CategoriesCompanion.insert(name: name, colorArgb: Value(colorArgb)),
          );
}
