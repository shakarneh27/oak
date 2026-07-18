import 'package:flutter/material.dart';

/// Design tokens ported from the reference design system (index.css of
/// the uploaded digital-oak mockup): sage primary, mint surfaces, sky-blue
/// accent, coral, gold, deep forest gradient, dark teal-green ink.
class OakColors {
  // core tokens
  static const background = Color(0xFFF8FBF5); // --background
  static const ink = Color(0xFF35524A); // --foreground
  static const primary = Color(0xFFA8C686); // --primary (sage)
  static const secondary = Color(0xFFDDE8D2); // --secondary (mint)
  static const accentBlue = Color(0xFF7CC6FE); // --accent
  static const coral = Color(0xFFF28482); // --destructive
  static const gold = Color(0xFFFFD166); // chart-3 / badges

  // splash / hero gradient stops (SplashPage linear-gradient 160deg)
  static const forestDeep = Color(0xFF1A2E1A);
  static const forest = Color(0xFF2D4A2D);
  static const forestLight = Color(0xFF3A5C3A);

  // legacy aliases still used across widgets
  static const leafLight = Color(0xFFDCF0C8);
  static const leaf = primary;
  static const leafDark = Color(0xFF6B9557);
  static const wordmark = Color(0xFF8FAF7E);
  static const trunk = Color(0xFF6D4C41);
  static const squirrel = Color(0xFFE89658);
  static const acorn = Color(0xFFB98A4C);
  static const cream = background;
}

/// Shared gradients so every brand screen paints the same forest backdrop
/// (CSS: linear-gradient(160deg, #1a2e1a, #2d4a2d 40%, #3a5c3a 70%, #2d4a2d)).
abstract final class OakGradients {
  static const forest = LinearGradient(
    begin: Alignment(0.3, -1),
    end: Alignment(-0.3, 1),
    stops: [0.0, 0.4, 0.7, 1.0],
    colors: [
      OakColors.forestDeep,
      OakColors.forest,
      OakColors.forestLight,
      OakColors.forest,
    ],
  );
}

class AppTheme {
  static ThemeData _base(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: OakColors.primary,
      primary: brightness == Brightness.light
          ? OakColors.leafDark
          : OakColors.primary,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      fontFamilyFallback: const ['Tajawal'],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? OakColors.background
          : const Color(0xFF1E2E2A),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      // --radius: 1rem
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.light ? Colors.white : null,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: brightness == Brightness.light
                ? OakColors.secondary
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        shadowColor: OakColors.primary.withValues(alpha: 0.25),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.light ? Colors.white : null,
        indicatorColor: OakColors.primary.withValues(alpha: 0.15),
        elevation: 8,
      ),
    );
  }

  static ThemeData get light => _base(Brightness.light);

  static ThemeData get dark => _base(Brightness.dark);
}
