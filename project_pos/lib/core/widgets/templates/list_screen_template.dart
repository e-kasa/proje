import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../app_app_bar.dart';
import '../app_empty_state.dart';
import '../base_scaffold.dart';

/// Sprint 15 — Liste ekranlarının ortak iskelet template'i.
///
/// Sprint 13'te `enhanced_product_list_screen.dart` üzerinde geliştirilen
/// pagination + RefreshIndicator + loadMore footer pattern'ı reusable hale
/// getirildi.
///
/// Kullanım:
/// ```dart
/// ListScreenTemplate<Sale>(
///   title: 'Satışlar',
///   items: state.items,
///   isLoading: state.isLoading,
///   isLoadingMore: state.isLoadingMore,
///   hasMore: state.hasMore,
///   onRefresh: notifier.loadFirst,
///   onLoadMore: notifier.loadMore,
///   itemBuilder: (sale) => SaleCard(sale: sale),
///   floatingActionButton: FloatingActionButton(...),
/// )
/// ```
class ListScreenTemplate<T> extends ConsumerStatefulWidget {
  final String title;
  final List<Widget>? actions;

  /// Liste verileri.
  final List<T> items;

  /// Tek bir liste öğesi render eder.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// İlk yükleme spinner'ı gösterilir mi.
  final bool isLoading;

  /// Bottom-loading spinner gösterilir mi (pagination loadMore aktif).
  final bool isLoadingMore;

  /// Daha fazla sayfa var mı (hasMore false ise loadMore tetiklenmez).
  final bool hasMore;

  /// Pull-to-refresh + ilk yükleme. RefreshIndicator wrapper otomatik.
  final Future<void> Function()? onRefresh;

  /// Bottom-200px scroll'a indiğinde tetiklenir.
  final Future<void> Function()? onLoadMore;

  /// Hata varsa retry butonlu empty state.
  final Object? error;
  final VoidCallback? onErrorRetry;

  /// Üst-bar slotları — search/filter/istatistik için.
  /// Tipik sıra: `searchSlot` → `filterSlot` → `statsSlot` → liste.
  final Widget? searchSlot;
  final Widget? filterSlot;
  final Widget? statsSlot;

  /// FAB.
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Alt bar — selection toolbar veya summary için.
  final Widget? bottomBar;

  /// Grid mode — true ise GridView.builder, false ise ListView.builder.
  final bool isGrid;
  final SliverGridDelegate? gridDelegate;

  /// Liste padding.
  final EdgeInsets? listPadding;

  /// Boş durum (items.isEmpty && !isLoading) için override.
  final Widget? emptyState;

  const ListScreenTemplate({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.actions,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onRefresh,
    this.onLoadMore,
    this.error,
    this.onErrorRetry,
    this.searchSlot,
    this.filterSlot,
    this.statsSlot,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomBar,
    this.isGrid = false,
    this.gridDelegate,
    this.listPadding,
    this.emptyState,
  });

  @override
  ConsumerState<ListScreenTemplate<T>> createState() =>
      _ListScreenTemplateState<T>();
}

class _ListScreenTemplateState<T> extends ConsumerState<ListScreenTemplate<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 &&
        !widget.isLoadingMore &&
        widget.hasMore &&
        !widget.isLoading &&
        widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppAppBar.standard(
        title: widget.title,
        actions: widget.actions,
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: widget.bottomBar,
      body: Column(
        children: [
          if (widget.searchSlot != null) widget.searchSlot!,
          if (widget.filterSlot != null) widget.filterSlot!,
          if (widget.statsSlot != null) widget.statsSlot!,
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.error != null) {
      return AppEmptyState.error(
        description: widget.error.toString(),
        onAction: widget.onErrorRetry,
      );
    }
    if (widget.isLoading && widget.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.items.isEmpty) {
      return widget.emptyState ?? AppEmptyState.noData();
    }

    final list = widget.isGrid ? _buildGrid() : _buildList();

    if (widget.onRefresh != null) {
      return RefreshIndicator(onRefresh: widget.onRefresh!, child: list);
    }
    return list;
  }

  Widget _buildList() {
    final extraFooter =
        (widget.isLoadingMore || (!widget.hasMore && widget.items.isNotEmpty))
            ? 1
            : 0;
    return ListView.builder(
      controller: _scrollController,
      padding: widget.listPadding ?? AppConstants.pagePadding,
      itemCount: widget.items.length + extraFooter,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return _buildLoadMoreFooter();
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }

  Widget _buildGrid() {
    final delegate = widget.gridDelegate ??
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        );
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: widget.listPadding ?? AppConstants.pagePadding,
          sliver: SliverGrid(
            gridDelegate: delegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  widget.itemBuilder(context, widget.items[index], index),
              childCount: widget.items.length,
            ),
          ),
        ),
        if (widget.isLoadingMore ||
            (!widget.hasMore && widget.items.isNotEmpty))
          SliverToBoxAdapter(child: _buildLoadMoreFooter()),
      ],
    );
  }

  Widget _buildLoadMoreFooter() {
    if (widget.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '${widget.items.length} öğe',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
