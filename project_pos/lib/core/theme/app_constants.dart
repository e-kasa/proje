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

  // === BORDER RADIUS === (Modern Classic — keskin köşe)
  static const double radiusSmall = 2.0;
  static const double radiusMedium = 2.0;
  static const double radiusLarge = 4.0;
  static const double radiusXLarge = 6.0;
  static const double radiusFull = 999.0;

  static BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // === ELEVATION & SHADOWS ===
  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> shadowColored(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
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
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 36.0;
  static const double buttonHeightLarge = 40.0;

  // === ANIMATIONS ===
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // === PADDING PRESETS ===
  // Industrial Dense: paddingMedium 16→10, paddingLarge 24→16
  static const EdgeInsets paddingSmall = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingMedium = EdgeInsets.all(10);
  static const EdgeInsets paddingLarge = EdgeInsets.all(spacing16);

  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: spacing8);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: 10);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: spacing16);

  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(vertical: spacing8);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(vertical: 10);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(vertical: spacing16);

  // === BORDER WIDTH ===
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // === PAGE & SECTION SPACING ===
  // Industrial Dense: pagePadding 16→12, cardPadding 16→10, formField 16→10, section 24→16, listItem 8→6
  static const EdgeInsets pagePadding = EdgeInsets.all(spacing12);
  static const EdgeInsets pagePaddingHorizontal = EdgeInsets.symmetric(horizontal: spacing12);
  static const EdgeInsets cardPadding = EdgeInsets.all(10);
  static const double formFieldSpacing = 10;
  static const double sectionSpacing = spacing16;
  static const double listItemSpacing = 6;

  // === RESPONSIVE BREAKPOINTS ===
  static const double breakpointMobile = 0;
  static const double breakpointTablet = 768;
  static const double breakpointDesktop = 1200;
  static const double breakpointDesktopLarge = 1600;

  // === RESPONSIVE LAYOUT HELPERS ===
  static bool isMobile(double width) => width < breakpointTablet;

  static bool isTablet(double width) =>
      width >= breakpointTablet && width < breakpointDesktop;

  static bool isDesktop(double width) => width >= breakpointDesktop;

  /// Ürün grid'i için kolon sayısını döndür
  /// Desktop: 4 kolon | Tablet: 3 kolon | Mobile: 2 kolon
  static int getProductGridColumns(double width) {
    if (isDesktop(width)) return 4;
    if (isTablet(width)) return 3;
    return 2;
  }

  /// Grid gap'ini cihaza göre döndür
  /// Desktop: 16px | Tablet: 12px | Mobile: 8px
  static double getGridGap(double width) {
    if (isDesktop(width)) return spacing16;
    if (isTablet(width)) return spacing12;
    return spacing8;
  }

  /// Sepet panel genişliğini döndür
  /// Desktop: 30% | Tablet: 40% | Mobile: 100%
  static double getCartPanelFlex(double width) {
    if (isDesktop(width)) return 30;
    if (isTablet(width)) return 40;
    return 100;
  }

  /// Ürün panel genişliğini döndür
  /// Desktop: 70% | Tablet: 60% | Mobile: 100%
  static double getProductPanelFlex(double width) {
    if (isDesktop(width)) return 70;
    if (isTablet(width)) return 60;
    return 100;
  }

  /// Horizontal padding'i cihaza göre döndür
  /// Desktop: 24px | Tablet: 16px | Mobile: 16px
  static double getHorizontalPadding(double width) {
    if (isDesktop(width)) return spacing24;
    return spacing16;
  }

  /// Body text boyutunu cihaza göre döndür
  static double getBodyTextSize(double width) {
    if (isDesktop(width)) return 14;
    if (isTablet(width)) return 13;
    return 12;
  }

  /// Title text boyutunu cihaza göre döndür
  static double getTitleTextSize(double width) {
    if (isDesktop(width)) return 24;
    if (isTablet(width)) return 20;
    return 18;
  }

  /// Responsive değer getter - Generic kullanım
  /// Example: getResponsiveValue(width: 1920, desktop: 24, tablet: 16, mobile: 12)
  static T getResponsiveValue<T>({
    required double width,
    required T desktop,
    required T tablet,
    required T mobile,
  }) {
    if (isDesktop(width)) return desktop;
    if (isTablet(width)) return tablet;
    return mobile;
  }
}