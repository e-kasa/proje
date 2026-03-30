import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_constants.dart';
import '../theme/app_gradients.dart';

/// Glassmorphism Card - Modern buzlu cam efekti
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double blur;
  final double opacity;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.blur = 10.0,
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    final widget = ClipRRect(
      borderRadius: AppConstants.borderRadiusLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? AppConstants.paddingMedium,
          decoration: BoxDecoration(
            gradient: AppGradients.glassGradient,
            borderRadius: AppConstants.borderRadiusLarge,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppConstants.borderRadiusLarge,
        child: widget,
      );
    }

    return widget;
  }
}
