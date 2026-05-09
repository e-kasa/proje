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

  /// Sprint 11o P1 — beyaz arka planlı (scaffold bgLight'tan ayrı), alt soft
  /// shadow ile gradient AppBar'dan net "ayrı bant" + chip-button selected
  /// indicator. Önceki Sprint 11l/m bgLight aynı renk olduğundan kayboluyordu.
  Widget _buildTabStrip(Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        // Chip-button selected: tinted bg kapsül + 1.5px primary border + 8px
        // radius. Buton gibi görünür, kullanıcı "tıklanabilir tab" anlar.
        indicator: BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary, width: 1.5),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        splashBorderRadius: BorderRadius.circular(8),
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
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (t.icon != null) ...[
                      Icon(t.icon, size: 18),
                      const SizedBox(width: 8),
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
            ),
        ],
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
