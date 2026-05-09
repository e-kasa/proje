import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

enum AppBarVariant { standard, primary, gradient }

/// Merkezi AppBar — her varyant dinamik gradientle renklenir.
///
/// [ConsumerWidget] olduğundan `resolvedGradientProvider`'ı dinler;
/// tema değişince tüm AppBar'lar otomatik güncellenir.
class AppAppBar extends ConsumerWidget implements PreferredSizeWidget {
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

  factory AppAppBar.standard({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    bool centerTitle = false,
    double? elevation,
  }) =>
      AppAppBar(
        title: title,
        variant: AppBarVariant.standard,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
        centerTitle: centerTitle,
        elevation: elevation,
      );

  factory AppAppBar.primary({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    bool centerTitle = false,
    double? elevation,
  }) =>
      AppAppBar(
        title: title,
        variant: AppBarVariant.primary,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
        centerTitle: centerTitle,
        elevation: elevation,
      );

  factory AppAppBar.gradient({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    bool centerTitle = false,
    double? elevation,
  }) =>
      AppAppBar(
        title: title,
        variant: AppBarVariant.gradient,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
        centerTitle: centerTitle,
        elevation: elevation,
      );

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = ref.watch(resolvedGradientProvider);
    // Sprint 11o P2 — gradient AppBar altında ince halo gölge: AppBar ve
    // içerik arasında profesyonel "tabakalanma" hissi (CSS box-shadow gibi).
    final primary = ref.watch(themeProvider).resolvedPrimary;

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
        decoration: BoxDecoration(
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
