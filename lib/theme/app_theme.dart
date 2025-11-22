import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static final _defaultBorderRadius = BorderRadius.circular(16.0);
  static const _defaultElevation = 4.0;
  static const _defaultAnimationDuration = Duration(milliseconds: 300);

  // Style de texte pour les valeurs numériques (score, niveau, etc.)
  static TextStyle numberTextStyle({
    required Color color,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: 'PressStart2P',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.2,
      letterSpacing: 1,
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.quicksandTextTheme().copyWith(
        displayLarge: GoogleFonts.medievalSharp(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.medievalSharp(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        // Style pour les valeurs numériques
        labelSmall: numberTextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
        labelMedium: numberTextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        labelLarge: numberTextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.medievalSharp(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardTheme(
        elevation: _defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: _defaultBorderRadius,
        ),
        color: Colors.white.withOpacity(0.9),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: _defaultElevation,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: _defaultBorderRadius,
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return 2.0;
              }
              if (states.contains(MaterialState.hovered)) {
                return 6.0;
              }
              return _defaultElevation;
            },
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.quicksandTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.medievalSharp(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.medievalSharp(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          color: Colors.white,
        ),
        // Style pour les valeurs numériques
        labelSmall: numberTextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        labelMedium: numberTextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        labelLarge: numberTextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.medievalSharp(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: _defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: _defaultBorderRadius,
        ),
        color: AppColors.textPrimary.withOpacity(0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: _defaultElevation,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: _defaultBorderRadius,
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return 2.0;
              }
              if (states.contains(MaterialState.hovered)) {
                return 6.0;
              }
              return _defaultElevation;
            },
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.textPrimary.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _defaultBorderRadius,
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}