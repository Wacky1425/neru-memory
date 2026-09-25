import 'package:flutter/material.dart';

class AppTheme {
  static const blue = Color(0xFF2563EB);
  static const paleBlue = Color(0xFFEFF6FF);
  static const ink = Color(0xFF172033);

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: blue, brightness: brightness,
      surface: dark ? const Color(0xFF121722) : Colors.white);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF0D111A) : const Color(0xFFF8FAFD),
      fontFamily: 'sans-serif',
      appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: dark ? Colors.white : ink),
      cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF161D29) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: dark ? const Color(0xFF263044) : const Color(0xFFE8EDF5)))),
      inputDecorationTheme: InputDecorationTheme(filled: true,
        fillColor: dark ? const Color(0xFF161D29) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: dark ? const Color(0xFF263044) : const Color(0xFFE8EDF5)))),
      navigationBarTheme: NavigationBarThemeData(indicatorColor: dark ? const Color(0xFF1D3A70) : paleBlue),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: blue, foregroundColor: Colors.white),
    );
  }
}
