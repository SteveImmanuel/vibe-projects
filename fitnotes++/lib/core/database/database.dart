import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// Default muscle-group categories, seeded on first launch. Names + colors
/// mirror FitNotes' defaults (the classic Flat-UI palette) so an imported
/// `.fitnotes` backup dedupes against them by name.
const _seedCategories = <(String, int)>[
  ('Abs', 0xFF2C3E50),
  ('Back', 0xFF2980B9),
  ('Biceps', 0xFFF39C12),
  ('Cardio', 0xFF7F8C8D),
  ('Chest', 0xFFC0392B),
  ('Forearm', 0xFF2ECC71),
  ('Legs', 0xFF54B2B6),
  ('Shoulders', 0xFF8E44AD),
  ('Triceps', 0xFF27AE60),
];

@DriftDatabase(
  tables: [
    Categories,
    Exercises,
    ExerciseMultipliers,
    WorkoutSets,
    WorkoutDayNotes,
    PrResetMarkers,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seed();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seed() async {
    await batch((b) {
      for (var i = 0; i < _seedCategories.length; i++) {
        final (name, color) = _seedCategories[i];
        b.insert(
          categories,
          CategoriesCompanion.insert(
            name: name,
            colorArgb: Value(color),
            sortOrder: Value(i),
          ),
        );
      }
    });
    // Single settings row with column defaults.
    await into(appSettings).insert(
      const AppSettingsCompanion(id: Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

/// App connection: a lazily-opened native SQLite file in the app documents dir.
QueryExecutor openAppConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fitnotes_plus.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
