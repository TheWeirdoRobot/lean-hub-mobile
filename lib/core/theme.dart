import 'package:material_ui/material_ui.dart';

class AppColors {
  AppColors._();

  static const accent = Color(0xFF7C3AED);
  static const background = Color(0xFF0D0D1A);
  static const surface = Color(0xFF16162A);
  static const surfaceHigh = Color(0xFF1F1F36);
  static const border = Color(0xFF2A2A44);
  static const danger = Color(0xFFF85149);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    surface: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceHigh,
    outlineVariant: AppColors.border,
    error: AppColors.danger,
  );
  return _base(scheme).copyWith(scaffoldBackgroundColor: AppColors.background);
}

/// Light theme for the Settings toggle in a later checkpoint.
ThemeData buildLightTheme() => _base(ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ).copyWith(primary: AppColors.accent));

ThemeData _base(ColorScheme scheme) => ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary.withValues(alpha: 0.25),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
