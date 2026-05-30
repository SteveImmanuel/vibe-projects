# FitNotes++

A modern Flutter rebuild of [FitNotes](https://www.fitnotesapp.com/) — the offline,
free, no-account strength-training logger — plus two custom features.

See [`FITNOTES_REFERENCE.md`](FITNOTES_REFERENCE.md) for the reverse-engineered reference
that drives this rebuild (schema, exercise types, graph metrics, Brzycki 1RM, CSV format,
competitor analysis, rebuild priorities).

## Status

| Milestone | Scope | State |
|---|---|---|
| M0 | Scaffold, deps, theme | ✅ |
| M1 | Drift data layer + `.fitnotes` importer (+ tests on a real backup) | ✅ |
| M2 | Workout Log, exercise DB, TRACK/save loop | ✅ |
| M3 | History tab, progress Graphs (Brzycki 1RM), PR detection | ✅ |
| M4 | Settings, rest timer, theme, import UI | ✅ |
| M5 | **Feature 1** — per-exercise weight multipliers | planned |
| M6 | **Feature 2** — global PR reset ("PR seasons") | planned |

## Custom features (designed-in, dormant until M5/M6)

The schema already carries both feature seams so they drop in without migration:

1. **Weight multipliers** — every set stores `weightMultiplier` (default `1.0`);
   `effectiveWeight = rawWeight × weightMultiplier` is used everywhere (PRs, graphs). An
   `exercise_multipliers` table holds named per-exercise factors that multiply together.
2. **PR reset window** — all PR queries take a `sinceDate` (epoch in v1 = all-time). A
   `pr_reset_markers` table will supply the latest reset date for the "current period"
   while all-time records are preserved.

## Architecture

- **DB**: [Drift](https://drift.simonbinder.eu/) (SQLite). Schema in `lib/core/database/`.
- **State**: Riverpod 3 (`lib/core/providers.dart`).
- **Routing**: go_router (`lib/app/router.dart`).
- **Charts**: fl_chart.
- **Feature screens**: `lib/features/{workout_log,exercises,track,settings}/`.
- Weights are stored canonically in **kg**.

## Run

```bash
flutter pub get
dart run build_runner build        # regenerate Drift code (database.g.dart)
flutter run                        # Linux desktop, or an Android device
flutter test                       # unit + widget tests (imports the real backup)
```

## Import a FitNotes backup

Settings → **Import FitNotes Backup** → pick a `.fitnotes` file. It maps categories,
exercises, training log (incl. set comments) and workout-day notes into the app.
