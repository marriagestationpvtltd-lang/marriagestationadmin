import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide design tokens and theme configuration

// ─── Color Palette ───────────────────────────────────────────────────────────

/// Primary color - Pink (marriage theme)
const kPrimary = Color(0xFFE91E63);

/// Primary dark variant
const kPrimaryDark = Color(0xFFC2185B);

/// Secondary color - Light Pink
const kSecondary = Color(0xFFFF4081);

/// Accent color - Gold/Amber
const kAccent = Color(0xFFFFC107);

/// Success color
const kSuccess = Color(0xFF4CAF50);

/// Warning color
const kWarning = Color(0xFFFF9800);

/// Error color
const kError = Color(0xFFF44336);

/// Info color
const kInfo = Color(0xFF2196F3);

// Neutral colors
const kTextPrimary = Color(0xFF212121);
const kTextSecondary = Color(0xFF757575);
const kTextMuted = Color(0xFF9E9E9E);
const kBackground = Color(0xFFFAFAFA);
const kSurface = Colors.white;
const kDivider = Color(0xFFE0E0E0);

// ─── Spacing System ──────────────────────────────────────────────────────────

const kSpacing4 = 4.0;
const kSpacing8 = 8.0;
const kSpacing12 = 12.0;
const kSpacing16 = 16.0;
const kSpacing24 = 24.0;
const kSpacing32 = 32.0;
const kSpacing48 = 48.0;

// ─── Border Radius ───────────────────────────────────────────────────────────

const kRadiusSmall = 8.0;
const kRadiusMedium = 12.0;
const kRadiusLarge = 16.0;
const kRadiusXLarge = 24.0;

// ─── Theme Builder ───────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: kPrimary,
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.light(
      primary: kPrimary,
      secondary: kSecondary,
      error: kError,
      surface: kSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kTextPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kSurface,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacing24,
          vertical: kSpacing16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMedium),
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
        borderSide: const BorderSide(color: kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
        borderSide: const BorderSide(color: kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
        borderSide: const BorderSide(color: kError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
        borderSide: const BorderSide(color: kError, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: kSpacing16,
        vertical: kSpacing16,
      ),
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: kPrimary,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: kPrimary,
      secondary: kSecondary,
      error: kError,
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
  );
}
