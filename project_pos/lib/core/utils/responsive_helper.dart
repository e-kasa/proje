import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

/// Responsive layout helper - BuildContext ile responsive kontrolü
class ResponsiveHelper {
  /// Cihazın mobil (<768px) olup olmadığını kontrol et
  static bool isMobile(BuildContext context) {
    return AppConstants.isMobile(MediaQuery.of(context).size.width);
  }

  /// Cihazın tablet (768-1199px) olup olmadığını kontrol et
  static bool isTablet(BuildContext context) {
    return AppConstants.isTablet(MediaQuery.of(context).size.width);
  }

  /// Cihazın desktop (1200px+) olup olmadığını kontrol et
  static bool isDesktop(BuildContext context) {
    return AppConstants.isDesktop(MediaQuery.of(context).size.width);
  }

  /// Cihazın landscape modda olup olmadığını kontrol et
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Cihazın portrait modda olup olmadığını kontrol et
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Ekran genişliğini döndür
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Ekran yüksekliğini döndür
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Ürün grid'i için kolon sayısını döndür
  static int getProductGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AppConstants.getProductGridColumns(width);
  }

  /// Grid gap'ini döndür
  static double getGridGap(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AppConstants.getGridGap(width);
  }

  /// Sepet panel flex değerini döndür (Row kullanıldığında)
  static double getCartPanelFlex(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AppConstants.getCartPanelFlex(width);
  }

  /// Ürün panel flex değerini döndür (Row kullanıldığında)
  static double getProductPanelFlex(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AppConstants.getProductPanelFlex(width);
  }

  /// Horizontal padding'i döndür
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AppConstants.getHorizontalPadding(width);
  }

  /// Body text boyutunu döndür
  static double getBodyTextSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AppConstants.getBodyTextSize(width);
  }

  /// Title text boyutunu döndür
  static double getTitleTextSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AppConstants.getTitleTextSize(width);
  }
}

/// BuildContext extension - Kolay erişim için
extension ResponsiveExt on BuildContext {
  /// Ekran genişliği
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Ekran yüksekliği
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Mobil mi kontrol et
  bool get isMobile => ResponsiveHelper.isMobile(this);

  /// Tablet mi kontrol et
  bool get isTablet => ResponsiveHelper.isTablet(this);

  /// Desktop mi kontrol et
  bool get isDesktop => ResponsiveHelper.isDesktop(this);

  /// Landscape mi kontrol et
  bool get isLandscape => ResponsiveHelper.isLandscape(this);

  /// Portrait mi kontrol et
  bool get isPortrait => ResponsiveHelper.isPortrait(this);

  /// Ürün grid kolon sayısı
  int get gridColumns => ResponsiveHelper.getProductGridColumns(this);

  /// Grid gap değeri
  double get gridGap => ResponsiveHelper.getGridGap(this);

  /// Sepet panel flex'i
  double get cartPanelFlex => ResponsiveHelper.getCartPanelFlex(this);

  /// Ürün panel flex'i
  double get productPanelFlex => ResponsiveHelper.getProductPanelFlex(this);

  /// Horizontal padding
  double get horizontalPadding => ResponsiveHelper.getHorizontalPadding(this);

  /// Body text boyutu
  double get bodyTextSize => ResponsiveHelper.getBodyTextSize(this);

  /// Title text boyutu
  double get titleTextSize => ResponsiveHelper.getTitleTextSize(this);

  /// Safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// View insets (keyboard vb.)
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
}
