import 'package:intl/intl.dart';

/// Calendar-day helpers. Dates are stored as `yyyy-MM-dd` strings (matching
/// FitNotes) to keep day grouping/equality timezone-proof.
class Dates {
  Dates._();

  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  static String iso(DateTime d) => _iso.format(d);
  static DateTime parse(String isoDate) => DateTime.parse(isoDate);
  static String today() => iso(DateTime.now());

  static String shift(String isoDate, int days) =>
      iso(DateTime(parse(isoDate).year, parse(isoDate).month,
          parse(isoDate).day + days));

  /// Short, human label for the date navigation bar.
  static String navLabel(String isoDate) {
    final d = parse(isoDate);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(start).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == -1) return 'YESTERDAY';
    if (diff == 1) return 'TOMORROW';
    return DateFormat('EEE, d MMM yyyy').format(d).toUpperCase();
  }

  /// Long header used for grouped history sections.
  static String sectionHeader(String isoDate) =>
      DateFormat('EEEE, d MMMM yyyy').format(parse(isoDate)).toUpperCase();
}
