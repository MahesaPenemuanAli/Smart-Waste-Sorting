/// Smart Waste Sorting — App Theme Configuration
/// Premium dark theme dengan design system lengkap.
/// Menggunakan Google Fonts, custom color palette, dan Material 3.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kelas utama untuk mengelola tema aplikasi.
class AppTheme {
  AppTheme._(); // Prevent instantiation

  // ─────────────────────────────────────────────
  // Color Palette — Deep Dark + Emerald Accent
  // ─────────────────────────────────────────────

  // Background colors
  static const Color scaffoldDark = Color(0xFF0A0E21);
  static const Color surfaceDark = Color(0xFF111528);
  static const Color cardDark = Color(0xFF1A1F36);
  static const Color cardLightDark = Color(0xFF222847);

  // Primary — Emerald green
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color primaryGreenDark = Color(0xFF00C853);
  static const Color primaryGreenLight = Color(0xFF69F0AE);

  // Accent colors
  static const Color accentBlue = Color(0xFF448AFF);
  static const Color accentPurple = Color(0xFFB388FF);

  // Text colors
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textTertiary = Color(0xFF78909C);

  // Waste category colors
  static const Color organikGreen = Color(0xFF4CAF50);
  static const Color anorganikBlue = Color(0xFF2196F3);
  static const Color b3Red = Color(0xFFF44336);

  // Status colors
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);

  // Gradient sets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E21), Color(0xFF111528)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1F36), Color(0xFF222847)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient organikGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient anorganikGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient b3Gradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─────────────────────────────────────────────
  // Spacing & Sizing
  // ─────────────────────────────────────────────

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ─────────────────────────────────────────────
  // Shadows & Effects
  // ─────────────────────────────────────────────

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primaryGreen.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  // ─────────────────────────────────────────────
  // Theme Data
  // ─────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        onPrimary: scaffoldDark,
        primaryContainer: primaryGreenDark,
        secondary: accentBlue,
        onSecondary: textPrimary,
        surface: surfaceDark,
        onSurface: textPrimary,
        error: error,
        onError: textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: scaffoldDark,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Text theme
      textTheme: _buildTextTheme(),

      // Card
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: scaffoldDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        hintStyle: GoogleFonts.inter(color: textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: textTertiary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: scaffoldDark,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: textTertiary.withValues(alpha: 0.15),
        thickness: 1,
        space: spacingLg,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: primaryGreen.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide(
          color: textTertiary.withValues(alpha: 0.2),
        ),
      ),

      // Page transitions — smooth slide
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Typography — Google Fonts
  // ─────────────────────────────────────────────

  /// Build text theme menggunakan Outfit (heading) dan Inter (body).
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display
      displayLarge: GoogleFonts.outfit(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      // Headline
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      // Title
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),

      // Body — Inter
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
        height: 1.4,
      ),

      // Label
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Helper Methods — Category gradients & colors
  // ─────────────────────────────────────────────

  /// Mendapatkan gradient berdasarkan nama kategori.
  static LinearGradient getCategoryGradient(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'organik':
        return organikGradient;
      case 'anorganik':
        return anorganikGradient;
      case 'b3':
        return b3Gradient;
      default:
        return cardGradient;
    }
  }

  /// Mendapatkan warna solid berdasarkan nama kategori.
  static Color getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'organik':
        return organikGreen;
      case 'anorganik':
        return anorganikBlue;
      case 'b3':
        return b3Red;
      default:
        return textTertiary;
    }
  }

  /// Mendapatkan icon berdasarkan nama kategori.
  static IconData getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'organik':
        return Icons.eco;
      case 'anorganik':
        return Icons.delete_outline;
      case 'b3':
        return Icons.warning_amber;
      default:
        return Icons.help_outline;
    }
  }

  // ─────────────────────────────────────────────
  // Glassmorphism Decoration
  // ─────────────────────────────────────────────

  /// Dekorasi glassmorphism untuk card premium.
  static BoxDecoration get glassmorphism => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Dekorasi glassmorphism dengan warna kustom.
  static BoxDecoration glassmorphismColored(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
