import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/util/dates.dart';

/// A month calendar that marks each workout day with its category-color dots
/// (mirrors FitNotes' calendar). Tapping a selectable day calls [onSelectDay].
class WorkoutCalendar extends StatefulWidget {
  const WorkoutCalendar({
    super.key,
    required this.dayColors,
    required this.onSelectDay,
    this.initialMonth,
    this.selectable,
  });

  /// date (yyyy-MM-dd) -> category color ARGB ints for that day.
  final Map<String, List<int>> dayColors;
  final void Function(String isoDate) onSelectDay;
  final String? initialMonth;
  final bool Function(String isoDate)? selectable;

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  late DateTime _month;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final base = Dates.parse(widget.initialMonth ?? Dates.today());
    _month = DateTime(base.year, base.month);
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday - 1; // Mon=0
    final cells = <int?>[
      ...List.filled(leading, null),
      for (var d = 1; d <= daysInMonth; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftMonth(-1)),
              Expanded(
                child: Center(
                  child: Text(
                    Dates.monthLabel(_month),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftMonth(1)),
            ],
          ),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(w,
                        style: TextStyle(
                            fontSize: 12, color: theme.hintColor)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < cells.length; i += 7)
            Row(
              children: [
                for (var j = i; j < i + 7; j++)
                  Expanded(child: _cell(cells[j])),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(int? day) {
    if (day == null) return const SizedBox(height: 48);
    final theme = Theme.of(context);
    final dateStr = Dates.iso(DateTime(_month.year, _month.month, day));
    final colors = widget.dayColors[dateStr] ?? const <int>[];
    final isToday = dateStr == Dates.today();
    // No predicate => any day is selectable (used by the top-bar jump).
    final canSelect = widget.selectable?.call(dateStr) ?? true;

    final cell = SizedBox(
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
                    color: theme.colorScheme.primary, shape: BoxShape.circle)
                : null,
            child: Text(
              '$day',
              style: TextStyle(
                color: isToday
                    ? theme.colorScheme.onPrimary
                    : (canSelect
                        ? theme.colorScheme.onSurface
                        : theme.disabledColor),
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in colors.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Color(c), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!canSelect) return Opacity(opacity: 0.4, child: cell);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => widget.onSelectDay(dateStr),
      child: cell,
    );
  }
}

/// Shared workout-calendar dialog. Returns the chosen day (or null).
/// Pass [selectableDays] to restrict selection (Copy flow); omit it to allow
/// any day (top-bar jump-to-date). Workout days always show their dots.
Future<String?> showWorkoutCalendar(
  BuildContext context,
  WidgetRef ref, {
  required String initialDate,
  Set<String>? selectableDays,
}) async {
  final colors =
      await ref.read(workoutRepositoryProvider).workoutDayCategoryColors();
  if (!context.mounted) return null;
  return showDialog<String>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: WorkoutCalendar(
            dayColors: colors,
            initialMonth: initialDate,
            selectable: selectableDays == null
                ? null
                : (d) => selectableDays.contains(d),
            onSelectDay: (d) => Navigator.pop(context, d),
          ),
        ),
      ),
    ),
  );
}
