import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_constants.dart';
import '../app_app_bar.dart';
import '../base_scaffold.dart';

/// Sprint 15 — Dashboard ekranlarının ortak iskelet template'i.
///
/// `modern_dashboard_screen`, `finance_dashboard_screen`, `reports_screen`,
/// `daily_summary_screen` gibi stat kartı + section listesi mimarisinde
/// ortak yapı.
///
/// Kullanım:
/// ```dart
/// DashboardScreenTemplate(
///   title: 'Dashboard',
///   onRefresh: notifier.refresh,
///   statCards: [
///     AppStatCard(title: 'Bugün', value: '₺1.234', icon: Icons.today, color: AppColors.primary),
///     AppStatCard(title: 'Hafta', value: '₺12.345', icon: Icons.calendar_view_week, color: AppColors.success),
///   ],
///   sections: [
///     SalesChart(),
///     RecentTransactions(),
///   ],
/// )
/// ```
class DashboardScreenTemplate extends ConsumerWidget {
  final String title;
  final List<Widget>? appBarActions;

  /// Üst stat kartları — typically `AppStatCard`. Default 2 sütun grid.
  final List<Widget> statCards;

  /// Body içindeki section'lar — Card-bazlı bloklar.
  final List<Widget> sections;

  /// Pull-to-refresh callback.
  final Future<void> Function()? onRefresh;

  /// Stat kartı sütun sayısı (default 2). Mobile <600px'de otomatik 2'ye sabitlenir.
  final int statCardColumns;

  /// Stat kartı aspect ratio.
  final double statCardAspectRatio;

  /// Body padding override.
  final EdgeInsets? padding;

  /// Loading durumu — true ise tüm body shimmer/spinner.
  final bool isLoading;

  /// Hata varsa retry empty state.
  final Object? error;
  final VoidCallback? onErrorRetry;

  /// FAB.
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const DashboardScreenTemplate({
    super.key,
    required this.title,
    required this.statCards,
    required this.sections,
    this.appBarActions,
    this.onRefresh,
    this.statCardColumns = 2,
    this.statCardAspectRatio = 1.4,
    this.padding,
    this.isLoading = false,
    this.error,
    this.onErrorRetry,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseScaffold(
      appBar: AppAppBar.standard(title: title, actions: appBarActions),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = ListView(
      padding: padding ?? AppConstants.pagePadding,
      children: [
        if (statCards.isNotEmpty) ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: statCardColumns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: statCardAspectRatio,
            children: statCards,
          ),
          const SizedBox(height: 16),
        ],
        for (int i = 0; i < sections.length; i++) ...[
          sections[i],
          if (i < sections.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
    if (onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: list);
    }
    return list;
  }
}
