import 'package:flutter/material.dart';

/// Brand palette sampled from the official Digital Oak logo and the
/// reference splash design: sage-green foliage, deep forest backdrop,
/// squirrel brown, and a gold accent for highlights.
class OakColors {
  // foliage / identity greens
  static const leafLight = Color(0xFFC6DCB2);
  static const leaf = Color(0xFFA9C48E);
  static const leafDark = Color(0xFF6B9557);
  static const wordmark = Color(0xFF8FAF7E);

  // deep forest gradient stops (splash / hero background)
  static const forestDeep = Color(0xFF16351F);
  static const forest = Color(0xFF24522F);
  static const forestLight = Color(0xFF3A6B44);

  // accents
  static const trunk = Color(0xFF6D4C41);
  static const squirrel = Color(0xFFA9764F);
  static const acorn = Color(0xFFB98A4C);
  static const gold = Color(0xFFE3C77E);

  // surfaces
  static const cream = Color(0xFFF7FBF4);
}

/// Shared gradients so every screen paints the same forest backdrop.
abstract final class OakGradients {
  static const forest = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [OakColors.forestLight, OakColors.forest, OakColors.forestDeep],
  );
}

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: OakColors.leafDark,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OakColors.cream,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: OakColors.leafDark,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
