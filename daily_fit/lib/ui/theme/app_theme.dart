import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens. Screens must reference these (or theme colors),
/// never ad-hoc hex values.
abstract final class AppColors {
  // Brand
  static const Color accent = Color(0xFFFFD60A);
  static const Color accentPressed = Color(0xFFE0B900);
  static const Color tertiary = Color(0xFF8A93FF);

  // Dark surface palette
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceHigh = Color(0xFF1C1C1E);

  // Light surface palette
  static const Color lightBackground = Color(0xFFF6F6F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFECECE8);
}

/// Spacing scale (px).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner-radius scale (px).
abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 1000;
}

class AppTheme {
  static ThemeData get darkTheme => _base(Brightness.dark).copyWith(
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent,
          tertiary: AppColors.tertiary,
          surface: AppColors.darkSurface,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
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
          tertiary: AppColors.tertiary,
          surface: AppColors.lightSurface,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Color(0xFF16161A),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      );

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF16161A);
    final fgMuted = isDark ? Colors.white70 : Colors.black54;
    final surfaceHigh =
        isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh;

    final scheme = brightness == Brightness.dark
        ? const ColorScheme.dark(
            primary: AppColors.accent,
            secondary: AppColors.accent,
            tertiary: AppColors.tertiary,
            surface: AppColors.darkSurface,
            onPrimary: Colors.black,
            onSecondary: Colors.black,
            onSurface: Colors.white,
          )
        : const ColorScheme.light(
            primary: AppColors.accent,
            secondary: AppColors.accent,
            tertiary: AppColors.tertiary,
            surface: AppColors.lightSurface,
            onPrimary: Colors.black,
            onSecondary: Colors.black,
            onSurface: Color(0xFF16161A),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(color: fg, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.inter(color: fg, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.inter(color: fg, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(color: fg, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.inter(color: fg, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.inter(color: fg, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(color: fg, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: fg, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.inter(color: fg, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: fg),
        bodyMedium: GoogleFonts.inter(color: fg),
        bodySmall: GoogleFonts.inter(color: fgMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: fg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.black54,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(
            Colors.black.withValues(alpha: isDark ? 0.12 : 0.10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? Colors.white : const Color(0xFF16161A),
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: surfaceHigh.withValues(alpha: isDark ? 0.6 : 0.9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? Colors.black
                : fgMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? fg : fgMuted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceHigh : const Color(0xFF16161A),
        contentTextStyle: TextStyle(color: isDark ? Colors.white : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.onSurface.withValues(alpha: 0.3),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}