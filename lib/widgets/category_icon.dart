import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

/// Round tinted icon badge used wherever a category appears.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 44,
    this.iconSize,
  });

  final String category;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final Color accent = AppConstants.colorFor(category);
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    // Background tint derived from the category accent, theme-aware.
    final Color background =
        isDark ? accent.withValues(alpha: 0.20) : accent.withValues(alpha: 0.14);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(theme.cardTheme.shape is RoundedRectangleBorder &&
                    (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
                        is BorderRadius
                ? size * 0.28
                : size * 0.28),
      ),
      child: Icon(
        AppConstants.iconFor(category),
        size: iconSize ?? size * 0.52,
        color: darkAdaptedAccent(accent, isDark),
      ),
    );
  }

  /// Slightly brighter accent in dark mode for legibility.
  static Color darkAdaptedAccent(Color accent, bool isDark) {
    if (!isDark) return accent;
    return Color.lerp(accent, Colors.white, 0.25) ?? accent;
  }
}
