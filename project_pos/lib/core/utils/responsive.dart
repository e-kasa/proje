import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Responsive breakpoints
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  /// Check if current width is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Check if current width is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// Check if current width is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Check if platform is web
  static bool get isWebPlatform => kIsWeb;

  /// Check if platform is desktop (Windows, macOS, Linux)
  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  /// Check if should show sidebar (web, desktop platform, or large screen)
  static bool shouldShowSidebar(BuildContext context) {
    // Always show sidebar on web
    if (isWebPlatform) return true;

    // Always show sidebar on desktop platforms (Windows, macOS, Linux)
    if (isDesktopPlatform) return true;

    // Show sidebar on large screens (tablets/mobile in landscape with large screen)
    return isDesktop(context);
  }

  /// Check if should show bottom nav (mobile platform with small screen)
  static bool shouldShowBottomNav(BuildContext context) {
    // Never show bottom nav on web or desktop platforms
    if (isWebPlatform || isDesktopPlatform) return false;

    // Show bottom nav on mobile/tablet platforms only
    return true;
  }
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }

    if (AppBreakpoints.isTablet(context)) {
      return tablet ?? mobile;
    }

    return mobile;
  }
}

/// Responsive value - returns different values based on screen size
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  T getValue(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }

    if (AppBreakpoints.isTablet(context)) {
      return tablet ?? mobile;
    }

    return mobile;
  }
}

/// Extension on BuildContext for easy responsive checks
extension ResponsiveContext on BuildContext {
  bool get isMobile => AppBreakpoints.isMobile(this);
  bool get isTablet => AppBreakpoints.isTablet(this);
  bool get isDesktop => AppBreakpoints.isDesktop(this);
  bool get isWeb => AppBreakpoints.isWebPlatform;
  bool get isDesktopPlatform => AppBreakpoints.isDesktopPlatform;

  bool get shouldShowSidebar => AppBreakpoints.shouldShowSidebar(this);
  bool get shouldShowBottomNav => AppBreakpoints.shouldShowBottomNav(this);

  /// Get responsive value
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return ResponsiveValue(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    ).getValue(this);
  }
}
