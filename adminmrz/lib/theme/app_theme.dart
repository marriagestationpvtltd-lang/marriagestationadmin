import 'package:flutter/material.dart';

/// Marriage Station Admin Panel - Design System
/// Professional matrimonial matchmaking brand theme
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFC2185B);       // Deep Rose
  static const Color primaryDark = Color(0xFF880E4F);   // Burgundy
  static const Color primaryLight = Color(0xFFF48FB1);  // Soft Pink
  static const Color accent = Color(0xFFF9A825);        // Gold
  static const Color accentDark = Color(0xFFF57F17);    // Deep Gold

  // ─── Sidebar ────────────────────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFF1C0A13);         // Dark Maroon
  static const Color sidebarActive = Color(0xFFC2185B);     // Primary
  static const Color sidebarActiveLight = Color(0x33C2185B); // 20% primary
  static const Color sidebarText = Color(0xFFE8D0D8);       // Light rose-white
  static const Color sidebarInactiveText = Color(0xFF9E7A8A); // Muted

  // ─── Backgrounds ────────────────────────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFFFDF2F5);   // Very light pink
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color topBarBg = Color(0xFFFFFFFF);

  // ─── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A0A0E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // ─── Status ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ─── Borders ────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFF0D0D8);
  static const Color borderLight = Color(0xFFFAEDF0);

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC2185B), Color(0xFF880E4F)],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2D0B18), Color(0xFF1C0A13)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF9A825), Color(0xFFE65100)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
  );

  // ─── Card Stat Colors ───────────────────────────────────────────────────────
  static const List<Color> statCardColors = [
    Color(0xFFC2185B), // rose
    Color(0xFF1565C0), // blue
    Color(0xFF2E7D32), // green
    Color(0xFFF9A825), // gold
    Color(0xFF6A1B9A), // purple
    Color(0xFFE65100), // orange
    Color(0xFF00838F), // teal
    Color(0xFFC62828), // deep red
  ];

  // ─── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: primary.withOpacity(0.30),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ─── Border Radius ──────────────────────────────────────────────────────────
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(24));

  // ─── Theme Data ─────────────────────────────────────────────────────────────
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: cardBg,
          background: scaffoldBg,
        ),
        scaffoldBackgroundColor: scaffoldBg,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: radiusSm),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFDF5F7),
          border: OutlineInputBorder(
            borderRadius: radiusSm,
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radiusSm,
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radiusSm,
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: borderLight,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
        ),
        dividerTheme: const DividerThemeData(
          color: borderLight,
          thickness: 1,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: textMuted,
          ),
        ),
      );

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Status badge colors
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'verified':
      case 'success':
      case 'completed':
        return success;
      case 'pending':
      case 'processing':
        return warning;
      case 'inactive':
      case 'rejected':
      case 'failed':
      case 'blocked':
        return error;
      case 'premium':
      case 'gold':
        return accent;
      default:
        return textSecondary;
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'verified':
      case 'success':
      case 'completed':
        return successLight;
      case 'pending':
      case 'processing':
        return warningLight;
      case 'inactive':
      case 'rejected':
      case 'failed':
      case 'blocked':
        return errorLight;
      case 'premium':
      case 'gold':
        return const Color(0xFFFFF8E1);
      default:
        return const Color(0xFFF3F4F6);
    }
  }
}
