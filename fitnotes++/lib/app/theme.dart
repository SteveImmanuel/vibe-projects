import 'package:flutter/material.dart';

/// App-wide theming. FitNotes' signature accent is a cyan/teal; we seed a
/// Material 3 scheme from it for both light and dark.
class AppTheme {
  AppTheme._();

  /// FitNotes-style cyan accent.
  static const Color seed = Color(0xFF00ACC1);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
    );
  }

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);
}
