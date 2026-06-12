import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const brandPrimary = Color(0xFFED6E1F);
  static const brandPrimaryDark = Color(0xFFC95714);
  static const brandPrimaryLight = Color(0xFFF59B52);
  static const brandSoft = Color(0xFFFFD7B5);
  static const background = Color(0xFFFFF9F2);
  static const surface = Color(0xFFFFFDF9);
  static const surfaceVariant = Color(0xFFF7E8DA);
  static const outline = Color(0xFFD9B89B);
  static const outlineVariant = Color(0xFFE8D4C2);
  static const textPrimary = Color(0xFF2F241C);
  static const textSecondary = Color(0xFF6B5848);
  static const textDisabled = Color(0xFFA58A75);
  static const onPrimary = Color(0xFFFFF8E2);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFD9822B);
  static const error = Color(0xFFC62828);
  static const info = Color(0xFF3A7CA5);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: brandPrimary,
        onPrimary: onPrimary,
        secondary: brandPrimaryLight,
        onSecondary: textPrimary,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        outline: outline,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: outlineVariant),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceVariant,
        selectedColor: brandPrimary,
        secondarySelectedColor: brandPrimary,
        labelStyle: const TextStyle(color: textSecondary),
        secondaryLabelStyle: const TextStyle(color: onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textDisabled),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: brandPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(color: textPrimary, height: 1.4),
        bodyMedium: const TextStyle(color: textSecondary, height: 1.4),
      ),
    );
  }
}
