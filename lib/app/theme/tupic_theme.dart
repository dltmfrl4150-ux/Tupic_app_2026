import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tupic_colors.dart';

abstract final class TupicTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
    );

    final colorScheme = ColorScheme.dark(
      surface: TupicColors.mainBackground,
      primary: TupicColors.accentViolet,
      onPrimary: TupicColors.mainBackground,
      secondary: TupicColors.selected,
      onSecondary: TupicColors.primaryText,
      onSurface: TupicColors.primaryText,
      error: TupicColors.error,
      onError: TupicColors.primaryText,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TupicColors.mainBackground,
      canvasColor: TupicColors.secondary,
      cardColor: TupicColors.card,
      dividerColor: TupicColors.borderSubtle,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        foregroundColor: TupicColors.primaryText,
        titleTextStyle: TextStyle(
          color: TupicColors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: TupicColors.primaryText,
        displayColor: TupicColors.primaryText,
      ),
      iconTheme: const IconThemeData(color: TupicColors.primaryText),
      drawerTheme: const DrawerThemeData(
        backgroundColor: TupicColors.secondary,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TupicColors.card,
        selectedColor: TupicColors.selected,
        labelStyle: const TextStyle(color: TupicColors.primaryText),
        secondaryLabelStyle: const TextStyle(color: TupicColors.primaryText),
        side: const BorderSide(color: TupicColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TupicColors.card,
        contentTextStyle: const TextStyle(color: TupicColors.primaryText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TupicColors.secondary,
        titleTextStyle: const TextStyle(
          color: TupicColors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(color: TupicColors.mutedText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TupicColors.accentViolet,
          foregroundColor: TupicColors.mainBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TupicColors.primaryText,
          side: const BorderSide(color: TupicColors.borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: TupicColors.accentViolet),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TupicColors.card,
        hintStyle: const TextStyle(color: TupicColors.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TupicColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TupicColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TupicColors.accentViolet),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TupicColors.accentViolet,
      ),
    );
  }
}
