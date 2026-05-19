import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Warp-inspired design tokens — warm near-charcoal canvas, off-white ink,
// tight radii, Inter typography. Derived from warp/DESIGN.md.
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
  static const primary    = Color(0xfff7f5f0); // off-white — the brand's only "color"
  static const onPrimary  = Color(0xff2b2622); // text on primary buttons

  // ── Semantic (minimal — kept for status pills) ──
  static const success    = Color(0xff8aad7a);
  static const warning    = Color(0xffd4a84b);
  static const error      = Color(0xffcf6b6b);
}

// ── Spacing tokens ──
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

// ── Radius tokens ──
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
  const fontFamily = 'Inter';
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
    fontFamily: fontFamily,

    // ── Typography ──
    textTheme: const TextTheme(
      // display-md — section headlines
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.25,   // 40px
        letterSpacing: -0.8,
        color: KokoColors.ink,
      ),
      // display-sm — card titles, screen headers
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.33,   // 32px
        letterSpacing: -0.4,
        color: KokoColors.ink,
      ),
      // body-lg — lead paragraphs
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.55,   // 28px
        color: KokoColors.ink,
      ),
      // body-md-strong — nav / emphasis
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,    // 24px
        color: KokoColors.ink,
      ),
      // body-md — default body
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: KokoColors.ink,
      ),
      // body-sm — secondary body
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.42,
        color: KokoColors.body,
      ),
      // body-sm-strong — nav links, button labels
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.42,
        color: KokoColors.ink,
      ),
      // caption
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: KokoColors.mute,
      ),
      // button-md
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.42,
        color: KokoColors.ink,
      ),
    ),

    // ── App Bar ──
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

    // ── Cards ──
    cardTheme: CardThemeData(
      color: KokoColors.canvasSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: KokoRadius.mdBorder,
        side: const BorderSide(color: KokoColors.hairline),
      ),
    ),

    // ── Buttons ──
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KokoColors.primary,
        foregroundColor: KokoColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: KokoRadius.smBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: KokoSpacing.lg,
          vertical: KokoSpacing.sm,
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
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
      style: IconButton.styleFrom(
        foregroundColor: KokoColors.ink,
      ),
    ),

    // ── Inputs ──
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

    // ── Chips ──
    chipTheme: ChipThemeData(
      backgroundColor: KokoColors.canvasSoft,
      side: const BorderSide(color: KokoColors.hairline),
      shape: RoundedRectangleBorder(borderRadius: KokoRadius.smBorder),
      labelStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: KokoColors.body,
      ),
    ),

    // ── Bottom Sheet ──
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: KokoColors.canvas,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(KokoRadius.lg)),
      ),
      dragHandleColor: KokoColors.hairline,
    ),

    // ── Divider ──
    dividerColor: KokoColors.hairline,
    dividerTheme: const DividerThemeData(
      color: KokoColors.hairline,
      thickness: 1,
      space: 0,
    ),

    // ── Progress indicators ──
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KokoColors.ink,
      linearTrackColor: KokoColors.canvasSoft,
    ),

    // ── Refresh indicator ──
    // Note: RefreshIndicator will use primary color by default
  );
}
