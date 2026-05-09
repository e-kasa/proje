import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/theme_provider.dart';
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
    // Sprint 11l — tema primary reactive: TabBar indicator/label rengi kullanıcının
    // seçtiği tema rengiyle senkron.
    final primary = ref.watch(themeProvider).resolvedPrimary;
    return BaseScaffold(
      // TabBar artık AppBar.bottom'a değil, body üstüne kendi beyaz konteynerine
      // koyuluyor — gradient AppBar'dan net ayrı bir şerit, kullanıcı tab
      // olduğunu hemen anlar.
      appBar: AppAppBar.standard(
        title: widget.title,
        actions: widget.appBarActions,
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      body: Column(
        children: [
          _buildTabStrip(primary),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  /// Sprint 11l/m — gri arka planlı, üst+alt border, chip-style selected tab,
  /// belirgin hover. Gradient AppBar ve beyaz body içeriği arasında net bir
  /// "bant" olarak görünür.
  Widget _buildTabStrip(Color primary) {
    return Material(
      color: AppColors.bgLight,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgLight,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
            bottom: BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: TabBar(
          controller: _tabController,
          isScrollable: widget.tabs.length > 4,
          tabAlignment: widget.tabs.length > 4
              ? TabAlignment.start
              : TabAlignment.fill,
          // Chip-style selected tab: tinted bg kapsül + alt accent çizgisi.
          indicator: BoxDecoration(
            color: primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              bottom: BorderSide(color: primary, width: 3),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
          splashBorderRadius: BorderRadius.circular(10),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.pressed)) {
                return primary.withValues(alpha: 0.18);
              }
              if (states.contains(WidgetState.hovered)) {
                return primary.withValues(alpha: 0.08);
              }
              return null;
            },
          ),
          tabs: [
            for (final t in widget.tabs)
              Tab(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (t.icon != null) ...[
                      Icon(t.icon, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        t.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
