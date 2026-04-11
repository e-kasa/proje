import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_gradients.dart';

enum AppBarVariant { standard, primary, gradient }

/// Merkezi AppBar Widget - Tüm ekranlarda tutarlı AppBar için
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AppBarVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final double? elevation;

  const AppAppBar({
    super.key,
    required this.title,
    this.variant = AppBarVariant.standard,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.centerTitle = false,
    this.elevation,
  });

  /// Beyaz/surface arka planlı standart AppBar
  factory AppAppBar.standard({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    bool centerTitle = false,
    double? elevation,
  }) {
    return AppAppBar(
      title: title,
      variant: AppBarVariant.standard,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      centerTitle: centerTitle,
      elevation: elevation,
    );
  }

  /// Marka rengi (primary) arka planlı AppBar
  factory AppAppBar.primary({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    bool centerTitle = false,
    double? elevation,
  }) {
    return AppAppBar(
      title: title,
      variant: AppBarVariant.primary,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      centerTitle: centerTitle,
      elevation: elevation,
    );
  }

  /// Gradient arka planlı AppBar
  factory AppAppBar.gradient({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    bool centerTitle = false,
    double? elevation,
  }) {
    return AppAppBar(
      title: title,
      variant: AppBarVariant.gradient,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      centerTitle: centerTitle,
      elevation: elevation,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppBarVariant.standard:
      case AppBarVariant.primary:
      case AppBarVariant.gradient:
        return AppBar(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          foregroundColor: Colors.white,
          elevation: elevation ?? 0,
          surfaceTintColor: Colors.transparent,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          actions: actions,
          bottom: bottom,
          centerTitle: centerTitle,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryGradient,
            ),
          ),
        );
    }
  }
}
