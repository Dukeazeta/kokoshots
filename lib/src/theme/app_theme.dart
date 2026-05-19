import 'package:flutter/material.dart';

class KokoColors {
  static const ivory = Color(0xfffffaeb);
  static const cream = Color(0xfffff0c2);
  static const gold = Color(0xffffd900);
  static const amber = Color(0xffffa110);
  static const orange = Color(0xfffa520f);
  static const flame = Color(0xfffb6424);
  static const black = Color(0xff1f1f1f);
  static const muted = Color(0xff6f6046);
  static const line = Color(0xffead8a8);
  static const white = Color(0xffffffff);
}

ThemeData buildKokoTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: KokoColors.orange,
    brightness: Brightness.light,
    surface: KokoColors.ivory,
    primary: KokoColors.orange,
    secondary: KokoColors.amber,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: KokoColors.ivory,
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 38,
        height: 1,
        fontWeight: FontWeight.w400,
        color: KokoColors.black,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.05,
        fontWeight: FontWeight.w400,
        color: KokoColors.black,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 1.18,
        fontWeight: FontWeight.w400,
        color: KokoColors.black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: KokoColors.black,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.42,
        fontWeight: FontWeight.w400,
        color: KokoColors.muted,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: .7,
        color: KokoColors.black,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KokoColors.ivory,
      foregroundColor: KokoColors.black,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: KokoColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        side: BorderSide(color: KokoColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KokoColors.black,
        foregroundColor: KokoColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KokoColors.black,
        side: const BorderSide(color: KokoColors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KokoColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: KokoColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: KokoColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: KokoColors.orange, width: 1.4),
      ),
    ),
  );
}
