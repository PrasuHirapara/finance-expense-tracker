import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return _buildTheme(
      brightness: Brightness.light,
      seed: const Color(0xFF1B5E5A),
      surface: const Color(0xFFFAFBF7),
      scaffoldBackground: const Color(0xFFF4F6F3),
      panelColor: Colors.white,
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      brightness: Brightness.dark,
      seed: const Color(0xFF5EC7BE),
      surface: const Color(0xFF101717),
      scaffoldBackground: const Color(0xFF091111),
      panelColor: const Color(0xFF132020),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color seed,
    required Color surface,
    required Color scaffoldBackground,
    required Color panelColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: surface,
    );

    final textTheme = GoogleFonts.manropeTextTheme().copyWith(
      headlineMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
      titleLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      titleMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 15),
      bodyMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      labelLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panelColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: panelColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: panelColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.72,
        ),
        selectedColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: panelColor,
        indicatorColor: colorScheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
