import 'package:flutter/material.dart';

/// Merkezi Design System - React benzeri sabitler
class AppConstants {
  // === SPACING SYSTEM ===
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // === BORDER RADIUS ===
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusFull = 999.0;

  static BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // === ELEVATION & SHADOWS ===
  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> shadowColored(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // === ICON SIZES ===
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;

  // === BUTTON SIZES ===
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 52.0;

  // === ANIMATIONS ===
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // === PADDING PRESETS ===
  static const EdgeInsets paddingSmall = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingMedium = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingLarge = EdgeInsets.all(spacing24);

  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: spacing8);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: spacing16);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: spacing24);

  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(vertical: spacing8);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(vertical: spacing16);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(vertical: spacing24);

  // === BORDER WIDTH ===
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // === PAGE & SECTION SPACING ===
  static const EdgeInsets pagePadding = EdgeInsets.all(spacing16);
  static const EdgeInsets pagePaddingHorizontal = EdgeInsets.symmetric(horizontal: spacing16);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing16);
  static const double formFieldSpacing = spacing16;
  static const double sectionSpacing = spacing24;
  static const double listItemSpacing = spacing8;
}
