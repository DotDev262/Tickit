import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? dynamicColorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: dynamicColorScheme ?? ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.latoTextTheme(),
    );
  }

  static ThemeData darkTheme(ColorScheme? dynamicColorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: dynamicColorScheme ?? ColorScheme.fromSeed(
        seedColor: Colors.indigo, // Changed seedColor for dark theme
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.latoTextTheme(),
    );
  }
}