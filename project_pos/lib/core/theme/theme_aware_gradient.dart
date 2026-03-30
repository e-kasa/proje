import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class ThemeAwareGradient {
  static LinearGradient primary(WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final primaryColor = themeSettings.primaryColor.color;

    // Create gradient from primary color
    return LinearGradient(
      colors: [
        primaryColor,
        _darken(primaryColor, 0.2),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient custom(Color color) {
    return LinearGradient(
      colors: [
        color,
        _darken(color, 0.2),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}
