import '../database/tables.dart';

/// Display formatting helpers (kg-only weights in v1).
class Fmt {
  Fmt._();

  /// Trim trailing `.0` (20.0 -> "20", 122.5 -> "122.5").
  static String number(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Weight value with at least one decimal, trimming only the needless
  /// trailing zeros (20 -> "20.0", 122.5 -> "122.5", 1.25 -> "1.25").
  static String weightValue(double kg) {
    var s = kg.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s += '0';
    }
    return s;
  }

  static String weight(double kg) => '${weightValue(kg)} kg';

  static String duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }

  static String distance(double meters) =>
      meters >= 1000 ? '${number(meters / 1000)} km' : '${number(meters)} m';
}

/// One-line summary of a set, depending on the exercise type.
String describeSet({
  required ExerciseType type,
  required double effectiveWeight,
  required int reps,
  required double distance,
  required int durationSeconds,
}) {
  switch (type) {
    case ExerciseType.weightAndReps:
      return '${Fmt.weight(effectiveWeight)}  ×  $reps';
    case ExerciseType.repsOnly:
      return '$reps reps';
    case ExerciseType.distanceAndTime:
      return '${Fmt.distance(distance)}  •  ${Fmt.duration(durationSeconds)}';
    case ExerciseType.timeOnly:
      return Fmt.duration(durationSeconds);
  }
}

String exerciseTypeLabel(ExerciseType type) => switch (type) {
      ExerciseType.weightAndReps => 'Weight & Reps',
      ExerciseType.repsOnly => 'Reps Only',
      ExerciseType.distanceAndTime => 'Distance & Time',
      ExerciseType.timeOnly => 'Time Only',
    };
