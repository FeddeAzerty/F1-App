import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const f1Red = Color(0xFFE10600);

TextTheme _brandedTextTheme(TextTheme base) {
  return base.copyWith(
    titleLarge: GoogleFonts.titilliumWeb(
      textStyle: base.titleLarge,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: GoogleFonts.titilliumWeb(
      textStyle: base.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: GoogleFonts.titilliumWeb(
      textStyle: base.labelSmall,
      fontWeight: FontWeight.w600,
    ),
  );
}

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: f1Red,
  scaffoldBackgroundColor: const Color(0xFFF5F1EC),
  textTheme: _brandedTextTheme(ThemeData(brightness: Brightness.light).textTheme),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: f1Red,
  textTheme: _brandedTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
);
