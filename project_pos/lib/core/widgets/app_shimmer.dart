import 'package:flutter/material.dart';
import '../theme/app_gradients.dart';
import '../theme/app_constants.dart';

/// Shimmer Loading Effect - Skeleton loaders
class AppShimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AppShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: AppGradients.shimmerGradient.colors,
              stops: AppGradients.shimmerGradient.stops,
              begin: Alignment(-1.0 + (_controller.value * 3), 0.0),
              end: Alignment(0.0 + (_controller.value * 3), 0.0),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton Item - Loading placeholder
class AppSkeletonItem extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const AppSkeletonItem({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  factory AppSkeletonItem.circle(double size) {
    return AppSkeletonItem(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? AppConstants.borderRadiusSmall,
      ),
    );
  }
}

/// List Card Skeleton
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: AppConstants.paddingMedium,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            AppSkeletonItem.circle(56),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonItem(width: 120, height: 16),
                  const SizedBox(height: AppConstants.spacing8),
                  AppSkeletonItem(width: double.infinity, height: 12),
                  const SizedBox(height: AppConstants.spacing4),
                  AppSkeletonItem(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product/Item Card Skeleton (for grid views)
class AppSkeletonProductCard extends StatelessWidget {
  const AppSkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusMedium),
                ),
              ),
            ),
            Padding(
              padding: AppConstants.paddingMedium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonItem(width: double.infinity, height: 16),
                  const SizedBox(height: AppConstants.spacing8),
                  AppSkeletonItem(width: 100, height: 14),
                  const SizedBox(height: AppConstants.spacing8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppSkeletonItem(width: 80, height: 20),
                      AppSkeletonItem(width: 40, height: 32),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Statistics Card Skeleton
class AppSkeletonStatCard extends StatelessWidget {
  const AppSkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: AppConstants.paddingMedium,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSkeletonItem.circle(48),
                const SizedBox(width: AppConstants.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonItem(width: 80, height: 14),
                      const SizedBox(height: AppConstants.spacing8),
                      AppSkeletonItem(width: 120, height: 24),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing12),
            AppSkeletonItem(width: 150, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Table Row Skeleton
class AppSkeletonTableRow extends StatelessWidget {
  const AppSkeletonTableRow({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: AppConstants.paddingMedium,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            AppSkeletonItem(width: 60, height: 14),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(child: AppSkeletonItem(width: double.infinity, height: 14)),
            const SizedBox(width: AppConstants.spacing16),
            AppSkeletonItem(width: 80, height: 14),
            const SizedBox(width: AppConstants.spacing16),
            AppSkeletonItem(width: 100, height: 14),
            const SizedBox(width: AppConstants.spacing16),
            AppSkeletonItem(width: 60, height: 28),
          ],
        ),
      ),
    );
  }
}

/// List Skeleton - Multiple skeleton cards
class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget? skeleton;

  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
    this.skeleton,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: AppConstants.spacing12),
      itemBuilder: (context, index) => skeleton ?? const AppSkeletonCard(),
    );
  }
}

/// Grid Skeleton - Multiple product cards
class AppSkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const AppSkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppConstants.spacing12,
        mainAxisSpacing: AppConstants.spacing12,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const AppSkeletonProductCard(),
    );
  }
}
