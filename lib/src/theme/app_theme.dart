import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Warp-inspired design tokens — warm near-charcoal canvas, off-white ink,
// tight radii, Inter typography via Google Fonts.
// ─────────────────────────────────────────────────────────────────────────────

class KokoColors {
  KokoColors._();

  // ── Surface ──
  static const canvas     = Color(0xff2b2622);
  static const canvasSoft = Color(0xff383330);
  static const hairline   = Color(0xff3f3a36);

  // ── Text ──
  static const ink        = Color(0xfff7f5f0);
  static const bodyStrong = Color(0xffdad2c1);
  static const body       = Color(0xffc9c0ad);
  static const mute       = Color(0xffaea69c);

  // ── Brand / Primary ──
  static const primary    = Color(0xfff7f5f0);
  static const onPrimary  = Color(0xff2b2622);

  // ── Semantic ──
  static const success    = Color(0xff8aad7a);
  static const warning    = Color(0xffd4a84b);
  static const error      = Color(0xffcf6b6b);
}

class KokoSpacing {
  KokoSpacing._();
  static const double xxs = 2;
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 10;
  static const double lg  = 16;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class KokoRadius {
  KokoRadius._();
  static const double sm   = 3;
  static const double md   = 4;
  static const double lg   = 6;
  static const double pill  = 9999;

  static final smBorder  = BorderRadius.circular(sm);
  static final mdBorder  = BorderRadius.circular(md);
  static final lgBorder  = BorderRadius.circular(lg);
  static final pillBorder = BorderRadius.circular(pill);
}

ThemeData buildKokoTheme() {
  // Use Google Fonts Inter for proper font rendering
  final textTheme = GoogleFonts.interTextTheme(
    const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.25,
        letterSpacing: -0.8,
        color: KokoColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: -0.4,
        color: KokoColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: KokoColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: KokoColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: KokoColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.42,
        color: KokoColors.body,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.42,
        color: KokoColors.ink,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: KokoColors.mute,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.42,
        color: KokoColors.ink,
      ),
    ),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: KokoColors.primary,
    brightness: Brightness.dark,
    surface: KokoColors.canvas,
    primary: KokoColors.primary,
    onPrimary: KokoColors.onPrimary,
    secondary: KokoColors.bodyStrong,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: KokoColors.canvas,
    textTheme: textTheme,

    appBarTheme: const AppBarTheme(
      backgroundColor: KokoColors.canvas,
      foregroundColor: KokoColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: KokoColors.canvas,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),

    cardTheme: CardThemeData(
      color: KokoColors.canvasSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: KokoRadius.mdBorder,
        side: const BorderSide(color: KokoColors.hairline),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KokoColors.primary,
        foregroundColor: KokoColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: KokoRadius.smBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: KokoSpacing.lg,
          vertical: KokoSpacing.sm + 4,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KokoColors.ink,
        side: const BorderSide(color: KokoColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: KokoRadius.smBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: KokoSpacing.lg,
          vertical: KokoSpacing.sm,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: KokoColors.ink),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KokoColors.canvasSoft,
      border: OutlineInputBorder(
        borderRadius: KokoRadius.smBorder,
        borderSide: const BorderSide(color: KokoColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: KokoRadius.smBorder,
        borderSide: const BorderSide(color: KokoColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: KokoRadius.smBorder,
        borderSide: const BorderSide(color: KokoColors.ink, width: 1.4),
      ),
      hintStyle: const TextStyle(color: KokoColors.mute, fontSize: 14),
      labelStyle: const TextStyle(color: KokoColors.body, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KokoSpacing.md,
        vertical: KokoSpacing.sm,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: KokoColors.canvasSoft,
      side: const BorderSide(color: KokoColors.hairline),
      shape: RoundedRectangleBorder(borderRadius: KokoRadius.smBorder),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: KokoColors.body),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: KokoColors.canvas,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(KokoRadius.lg)),
      ),
      dragHandleColor: KokoColors.hairline,
    ),

    dividerColor: KokoColors.hairline,
    dividerTheme: const DividerThemeData(color: KokoColors.hairline, thickness: 1, space: 0),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KokoColors.ink,
      linearTrackColor: KokoColors.canvasSoft,
    ),
  );
}
