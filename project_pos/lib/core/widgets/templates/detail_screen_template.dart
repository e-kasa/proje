import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../app_app_bar.dart';
import '../app_empty_state.dart';
import '../base_scaffold.dart';

/// Sprint 15 — Detay ekranlarının ortak iskelet template'i.
///
/// `ProductDetailScreen`, `SaleDetailScreen`, `PurchaseDetailScreen` gibi
/// tab-bazlı detay ekranları için TabController + TabBar + TabBarView yönetimi.
///
/// Tab listesi dinamik — sektör config'e göre koşullu tab eklenebilir.
///
/// Kullanım:
/// ```dart
/// DetailScreenTemplate(
///   title: 'Ürün Detayı',
///   tabs: [
///     DetailTab(
///       label: 'Genel',
///       icon: Icons.info_outline,
///       builder: (ctx) => GeneralTab(),
///     ),
///     DetailTab(
///       label: 'Varyantlar',
///       icon: Icons.layers_outlined,
///       builder: (ctx) => VariantsTab(),
///     ),
///   ],
///   appBarActions: [
///     IconButton(icon: Icon(Icons.edit), onPressed: _openEditSheet),
///   ],
/// )
/// ```
class DetailScreenTemplate extends ConsumerStatefulWidget {
  final String title;
  final List<DetailTab> tabs;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final ValueChanged<int>? onTabChanged;
  final int initialTabIndex;

  /// Tab body'lerini IndexedStack ile keepAlive yap (state korunsun).
  /// `false` ise her tab değişiminde re-build.
  final bool keepTabsAlive;

  /// TabBar ile TabBarView arasında render edilecek opsiyonel header.
  /// Date range pill, hızlı kısayollar, üst banner için kullanılır.
  final Widget? headerSlot;

  /// Loading state — true ise body yerine spinner.
  final bool isLoading;

  /// Hata state — null değilse retry empty state.
  final Object? error;
  final VoidCallback? onErrorRetry;

  const DetailScreenTemplate({
    super.key,
    required this.title,
    required this.tabs,
    this.appBarActions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onTabChanged,
    this.initialTabIndex = 0,
    this.keepTabsAlive = false,
    this.headerSlot,
    this.isLoading = false,
    this.error,
    this.onErrorRetry,
  });

  @override
  ConsumerState<DetailScreenTemplate> createState() =>
      _DetailScreenTemplateState();
}

class _DetailScreenTemplateState extends ConsumerState<DetailScreenTemplate>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant DetailScreenTemplate old) {
    super.didUpdateWidget(old);
    if (old.tabs.length != widget.tabs.length) {
      _tabController?.dispose();
      _initController();
    }
  }

  void _initController() {
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, widget.tabs.length - 1),
    );
    if (widget.onTabChanged != null) {
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          widget.onTabChanged!(_tabController!.index);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppAppBar.standard(
        title: widget.title,
        actions: widget.appBarActions,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: widget.tabs.length > 4,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            for (final t in widget.tabs)
              Tab(
                text: t.label,
                icon: t.icon != null ? Icon(t.icon, size: 18) : null,
                iconMargin: const EdgeInsets.only(bottom: 2),
              ),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.error != null) {
      return AppEmptyState.error(
        description: widget.error.toString(),
        onAction: widget.onErrorRetry,
      );
    }
    final tabsWidget = widget.keepTabsAlive
        ? _buildIndexedStack()
        : TabBarView(
            controller: _tabController,
            children: [
              for (final t in widget.tabs)
                Builder(builder: (ctx) => t.builder(ctx)),
            ],
          );
    if (widget.headerSlot != null) {
      return Column(
        children: [
          widget.headerSlot!,
          Expanded(child: tabsWidget),
        ],
      );
    }
    return tabsWidget;
  }

  Widget _buildIndexedStack() {
    return AnimatedBuilder(
      animation: _tabController!,
      builder: (_, _) => IndexedStack(
        index: _tabController!.index,
        children: [
          for (final t in widget.tabs)
            Builder(builder: (ctx) => t.builder(ctx)),
        ],
      ),
    );
  }
}

class DetailTab {
  final String label;
  final IconData? icon;
  final Widget Function(BuildContext context) builder;

  const DetailTab({
    required this.label,
    required this.builder,
    this.icon,
  });
}
