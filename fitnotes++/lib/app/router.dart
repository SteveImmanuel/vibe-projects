import 'package:go_router/go_router.dart';

import '../core/util/dates.dart';
import '../features/exercises/edit_exercise_screen.dart';
import '../features/exercises/exercise_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/track/exercise_detail_screen.dart';
import '../features/workout_log/copy_workout_screen.dart';
import '../features/workout_log/home_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/copy',
      builder: (_, state) => CopyWorkoutScreen(
        targetDate: state.uri.queryParameters['date'] ?? Dates.today(),
        sourceDate: state.uri.queryParameters['source'] ??
            (state.uri.queryParameters['date'] ?? Dates.today()),
      ),
    ),
    GoRoute(
      path: '/exercises',
      builder: (_, state) => ExerciseListScreen(
        pickMode: state.uri.queryParameters['pick'] == '1',
        date: state.uri.queryParameters['date'],
      ),
    ),
    GoRoute(
      path: '/exercises/edit',
      builder: (_, state) {
        final id = state.uri.queryParameters['id'];
        return EditExerciseScreen(
          exerciseId: id == null ? null : int.parse(id),
        );
      },
    ),
    GoRoute(
      path: '/log/:exerciseId',
      builder: (_, state) => ExerciseDetailScreen(
        exerciseId: int.parse(state.pathParameters['exerciseId']!),
        date: state.uri.queryParameters['date'] ?? Dates.today(),
      ),
    ),
  ],
);
