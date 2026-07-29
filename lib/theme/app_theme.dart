// THEME LOCK: light — source: fintech domain signal (trust, clarity)
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens
// CNA Constitution v1.0 — Semantic color tokens, typography hierarchy, light+dark

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Primary Brand ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A5F7A);
  static const Color primaryLight = Color(0xFF2D9CDB);
  static const Color primaryContainer = Color(0xFFE0F2F8);
  static const Color secondary = Color(0xFF2D9CDB);
  static const Color secondaryContainer = Color(0xFFDCF0FB);

  // ─── Semantic Colors ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF2D7A4F);
  static const Color successLight = Color(0xFF34A85A);
  static const Color successContainer = Color(0xFFDCF5E8);

  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerLight = Color(0xFFDC2626);
  static const Color dangerContainer = Color(0xFFFEE2E2);

  // Alias: error = danger (Material convention)
  static const Color error = danger;
  static const Color errorContainer = dangerContainer;

  static const Color info = Color(0xFF1A5F7A);
  static const Color infoLight = Color(0xFF2D9CDB);
  static const Color infoContainer = Color(0xFFE0F2F8);

  static const Color neutral = Color(0xFF64748B);
  static const Color neutralLight = Color(0xFF94A3B8);
  static const Color neutralContainer = Color(0xFFF1F5F9);

  // ─── Asset Category Colors ────────────────────────────────────────────────
  static const Color currentAssetColor = Color(0xFF0EA5E9);
  static const Color fixedAssetColor = Color(0xFF8B5CF6);
  static const Color depreciatingColor = Color(0xFFF59E0B);
  static const Color appreciatingColor = Color(0xFF10B981);
  static const Color intangibleColor = Color(0xFFEC4899);

  // ─── Light Theme Surfaces ─────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F7FA);
  static const Color backgroundLight = Color(0xFFF0F4F8);
  static const Color onSurfaceLight = Color(0xFF1A1A2E);
  static const Color mutedLight = Color(0xFF64748B);
  static const Color outlineLight = Color(0xFFE2E8F0);

  // ─── Dark Theme Surfaces ──────────────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF1E2530);
  static const Color surfaceVariantDark = Color(0xFF252D3A);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color onSurfaceDark = Color(0xFFE6EDF3);
  static const Color mutedDark = Color(0xFF94A3B8);
  static const Color outlineDark = Color(0xFF2D3748);

  // ─── Semantic Color Helpers ───────────────────────────────────────────────
  /// Returns the container color for a given semantic type
  static Color semanticContainer(String type) {
    switch (type) {
      case 'success':
        return successContainer;
      case 'warning':
        return warningContainer;
      case 'danger':
      case 'error':
        return dangerContainer;
      case 'info':
        return infoContainer;
      default:
        return neutralContainer;
    }
  }

  /// Returns the foreground color for a given semantic type
  static Color semanticForeground(String type) {
    switch (type) {
      case 'success':
        return success;
      case 'warning':
        return warning;
      case 'danger':
      case 'error':
        return danger;
      case 'info':
        return info;
      default:
        return neutral;
    }
  }

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF0A3344),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF0A3A52),
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: mutedLight,
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      outline: outlineLight,
      outlineVariant: Color(0xFFF1F5F9),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        // Display — hero numbers, splash
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: onSurfaceLight,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: onSurfaceLight,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: onSurfaceLight,
        ),
        // Headline — screen titles, section headers
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurfaceLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurfaceLight,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurfaceLight,
        ),
        // Title — card titles, list headers
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurfaceLight,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurfaceLight,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onSurfaceLight,
        ),
        // Body — content text
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: onSurfaceLight,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: mutedLight,
        ),
        // Label — badges, chips, captions
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: onSurfaceLight,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: mutedLight,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: mutedLight,
        ),
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      iconTheme: IconThemeData(color: onSurfaceLight),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: outlineLight, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(color: outlineLight, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationThemeData(
      border: UnderlineInputBorder(borderSide: BorderSide(color: outlineLight)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: outlineLight),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: error)),
      filled: false,
      labelStyle: TextStyle(color: mutedLight, fontSize: 14),
      hintStyle: TextStyle(color: mutedLight.withAlpha(153), fontSize: 14),
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primary,
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      side: BorderSide.none,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primary,
      unselectedItemColor: mutedLight,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: onSurfaceLight,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceLight,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: mutedLight,
      indicatorColor: primary,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: primaryContainer,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? primary : mutedLight,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primaryContainer
            : outlineLight,
      ),
    ),
  );

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Color(0xFF0A3344),
      primaryContainer: Color(0xFF0A3A52),
      onPrimaryContainer: Color(0xFFB3E5F9),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF0A3A52),
      onSecondaryContainer: Color(0xFFB3E5F9),
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      surfaceContainerHighest: surfaceVariantDark,
      onSurfaceVariant: mutedDark,
      error: Color(0xFFCF6679),
      onError: Colors.white,
      errorContainer: Color(0xFF4A1A1A),
      outline: outlineDark,
      outlineVariant: Color(0xFF1E2530),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          color: onSurfaceDark,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          color: onSurfaceDark,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: onSurfaceDark,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurfaceDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurfaceDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurfaceDark,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurfaceDark,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurfaceDark,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onSurfaceDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: onSurfaceDark,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: mutedDark,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: onSurfaceDark,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: mutedDark,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: mutedDark,
        ),
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      iconTheme: IconThemeData(color: onSurfaceDark),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: outlineDark, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(color: outlineDark, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationThemeData(
      border: UnderlineInputBorder(borderSide: BorderSide(color: outlineDark)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: outlineDark),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFCF6679)),
      ),
      filled: false,
      labelStyle: TextStyle(color: mutedDark, fontSize: 14),
      hintStyle: TextStyle(color: mutedDark.withAlpha(153), fontSize: 14),
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Color(0xFF0A3344),
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantDark,
      selectedColor: primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      side: BorderSide.none,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: Color(0xFF0A3344),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryLight,
      unselectedItemColor: mutedDark,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceVariantDark,
      contentTextStyle: TextStyle(color: onSurfaceDark, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceDark,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primaryLight,
      unselectedLabelColor: mutedDark,
      indicatorColor: primaryLight,
      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryLight,
      linearTrackColor: Color(0xFF0A3A52),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? primaryLight : mutedDark,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Color(0xFF0A3A52)
            : outlineDark,
      ),
    ),
  );
}
