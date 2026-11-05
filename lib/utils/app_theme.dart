import 'package:flutter/material.dart';

/// PaisaPath – Track Expenses
/// Single seed colour → complete Material 3 light & dark themes.
/// All screens pull colours exclusively from the ColorScheme / ThemeData in
/// here — no screen-level hardcoded colours.

class AppTheme {
  AppTheme._();

  // ── PaisaPath Brand Palette ──────────────────────────────────────────────
  static const Color primaryPlum    = Color(0xFF40243F); // Deep Plum
  static const Color secondaryTeal  = Color(0xFF79C9B1); // Soft Teal
  static const Color accentCoral    = Color(0xFFF4B183); // Warm Coral
  static const Color backgroundIvory = Color(0xFFFAF5ED); // Warm Ivory
  static const Color surfaceWhite   = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF29242A);
  static const Color textSecondary  = Color(0xFF81777D);
  static const Color borderColor    = Color(0xFFE8DCD9);

  // Semantic money colours (mockup redesign): green = money in,
  // red = money out. Bright variants are for use on dark/gradient surfaces.
  static const Color incomeGreen       = Color(0xFF16A34A);
  static const Color incomeGreenBright = Color(0xFF7BE3A2);
  static const Color expenseRed        = Color(0xFFDC2626);
  static const Color expenseRedBright  = Color(0xFFFF8A80);

  // Dark palette
  static const Color darkSurface    = Color(0xFF1A0E1A); // Very dark plum
  static const Color darkBackground = Color(0xFF120E12);
  static const Color darkSurface2   = Color(0xFF261526);

  static const double radiusLarge  = 22;
  static const double radiusMedium = 16;
  static const double radiusSmall  = 10;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark()  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: primaryPlum,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEDD5EC),
      onPrimaryContainer: primaryPlum,
      secondary: secondaryTeal,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB8EAE0),
      onSecondaryContainer: const Color(0xFF004D40),
      tertiary: accentCoral,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFE3CF),
      onTertiaryContainer: const Color(0xFF6B3010),
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFE4E1),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: isLight ? surfaceWhite : darkSurface,
      onSurface: isLight ? textPrimary : const Color(0xFFF5EDF5),
      surfaceContainerHighest: isLight ? borderColor : const Color(0xFF3A1F3A),
      surfaceContainerLow: isLight ? const Color(0xFFFDF9F7) : darkSurface2,
      surfaceContainerHigh: isLight ? const Color(0xFFF5EEF0) : const Color(0xFF301A30),
      onSurfaceVariant: isLight ? textSecondary : const Color(0xFFBBABBB),
      outline: isLight ? borderColor : const Color(0xFF6B5A6B),
      outlineVariant: isLight ? const Color(0xFFF0E8E6) : const Color(0xFF4A334A),
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isLight ? const Color(0xFF2A1A2A) : const Color(0xFFF5EEF5),
      onInverseSurface: isLight ? const Color(0xFFFAF0FA) : const Color(0xFF2A1A2A),
      inversePrimary: const Color(0xFFD4A0D2),
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: isLight ? backgroundIvory : darkBackground,
      splashFactory: InkRipple.splashFactory,
      iconTheme: IconThemeData(color: scheme.onSurface.withValues(alpha: 0.8)),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: isLight ? backgroundIvory : darkBackground,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? surfaceWhite : darkSurface2,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(
            color: scheme.outlineVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFF9F5F2) : darkSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: scheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        errorStyle: TextStyle(color: scheme.error, fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryPlum,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPlum,
          side: const BorderSide(color: primaryPlum, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPlum,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: primaryPlum.withValues(alpha: 0.12),
        showCheckmark: false,
        labelStyle: TextStyle(fontSize: 13, color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? const Color(0xFF2A1A2A) : scheme.inverseSurface,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryPlum,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isLight ? surfaceWhite : darkSurface2,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryPlum.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? primaryPlum : scheme.onSurfaceVariant,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? primaryPlum : scheme.onSurfaceVariant,
          size: 22,
        )),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: isLight ? surfaceWhite : darkSurface2,
        headerForegroundColor: scheme.onSurface,
        headerBackgroundColor: primaryPlum.withValues(alpha: 0.08),
        dayStyle: const TextStyle(fontSize: 13),
        yearStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? surfaceWhite : darkSurface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.85),
          fontSize: 14,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: isLight ? surfaceWhite : darkSurface2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );

    // Global typography.
    final TextTheme text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamily: null, // uses system default
    );
    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge:  text.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: text.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        displaySmall:  text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.1),
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.2),
        headlineSmall:  text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge:  text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall:  text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge:   text.bodyLarge?.copyWith(height: 1.5),
        bodyMedium:  text.bodyMedium?.copyWith(height: 1.4),
        labelLarge:  text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
