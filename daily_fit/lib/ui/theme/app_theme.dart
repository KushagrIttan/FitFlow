import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens. Screens must reference these (or theme colors),
/// never ad-hoc hex values.
abstract final class AppColors {
  // Brand
  static const Color accent = Color(0xFFFFD60A);

  // Dark
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceHigh = Color(0xFF1C1C1E);

  // Light
  static const Color lightBackground = Color(0xFFF6F6F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFECECE8);
}

class AppTheme {
  static ThemeData get darkTheme => _base(Brightness.dark).copyWith(
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent,
          surface: AppColors.darkSurface,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.white54,
          elevation: 8,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      );

  static ThemeData get lightTheme => _base(Brightness.light).copyWith(
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          secondary: AppColors.accent,
          surface: AppColors.lightSurface,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Color(0xFF16161A),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          selectedItemColor: Color(0xFF8A6D00),
          unselectedItemColor: Colors.black45,
          elevation: 8,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      );

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? Colors.white : const Color(0xFF16161A);
    final secondary = isDark ? Colors.white70 : Colors.black54;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(color: primary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.inter(color: primary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.inter(color: primary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: primary),
        bodyMedium: GoogleFonts.inter(color: primary),
        bodySmall: GoogleFonts.inter(color: secondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
