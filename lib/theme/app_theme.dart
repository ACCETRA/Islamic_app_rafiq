import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Builds the app's light and dark themes from [AppColors].
///
/// Both themes reuse the same 5 swatches; light mode puts the light
/// end of the palette in the background and the dark end in text/
/// accents, dark mode does the reverse.
class AppTheme {
  AppTheme._();

  /// Style for Arabic script (dhikr, duas, ayah/surah names). Use this
  /// explicitly wherever Arabic text is rendered — the UI's default
  /// font (see [_themeFrom]) is a Latin-script font and doesn't cover
  /// Arabic glyphs meaningfully.
  static TextStyle arabic({
    double fontSize = 20,
    double height = 1.8,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.slateTeal,
      onPrimary: Colors.white,
      secondary: AppColors.mintTeal,
      onSecondary: AppColors.deepNavy,
      surface: AppColors.cardSurface,
      onSurface: AppColors.deepNavy,
      surfaceContainerHighest: AppColors.warmSurface,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _themeFrom(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.offWhite,
      cardColor: AppColors.cardSurface,
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.mintTeal,
      onPrimary: AppColors.deepNavy,
      secondary: AppColors.slateTeal,
      onSecondary: Colors.white,
      surface: AppColors.darkTeal,
      onSurface: AppColors.lightGray,
      surfaceContainerHighest: AppColors.darkTeal,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _themeFrom(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.deepNavy,
      cardColor: AppColors.darkTeal,
    );
  }

  static ThemeData _themeFrom({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
  }) {
    final onSurface = colorScheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(TextTheme(
        headlineLarge: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.55,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: onSurface.withValues(alpha: 0.72),
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: onSurface.withValues(alpha: 0.72),
        ),
      )),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: colorScheme.primary.withValues(alpha: 0.05),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.5)),
        prefixIconColor: onSurface.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.92),
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.primary : onSurface.withValues(alpha: 0.58),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : onSurface.withValues(alpha: 0.58),
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 56,
        horizontalTitleGap: 14,
        iconColor: onSurface.withValues(alpha: 0.72),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? colorScheme.primary : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colorScheme.primary.withValues(alpha: 0.5)
                : null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? colorScheme.primary : null),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? AppColors.lightGray
            : AppColors.deepNavy,
        contentTextStyle: TextStyle(
          color: colorScheme.brightness == Brightness.dark
              ? AppColors.deepNavy
              : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: onSurface.withValues(alpha: 0.12),
      ),
    );
  }
}
