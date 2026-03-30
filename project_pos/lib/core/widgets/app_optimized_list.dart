import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

/// Optimized List Builder - Çok hızlı liste gösterimi
class AppOptimizedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? separator;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final bool shrinkWrap;

  const AppOptimizedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separator,
    this.padding,
    this.controller,
    this.onRefresh,
    this.onLoadMore,
    this.hasMore = false,
    this.emptyWidget,
    this.loadingWidget,
    this.shrinkWrap = false,
  });

  @override
  State<AppOptimizedList<T>> createState() => _AppOptimizedListState<T>();
}

class _AppOptimizedListState<T> extends State<AppOptimizedList<T>>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    if (widget.onLoadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    await widget.onLoadMore?.call();

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.items.isEmpty && widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    Widget listView = ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? AppConstants.paddingMedium,
      shrinkWrap: widget.shrinkWrap,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: (context, index) {
        return widget.separator ?? const SizedBox(height: AppConstants.spacing12);
      },
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          return widget.loadingWidget ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.spacing16),
                  child: CircularProgressIndicator(),
                ),
              );
        }

        final item = widget.items[index];

        // RepaintBoundary for better performance
        return RepaintBoundary(
          child: widget.itemBuilder(context, item, index),
        );
      },
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
}

/// Optimized Grid Builder
class AppOptimizedGrid<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AppOptimizedGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = AppConstants.spacing12,
    this.mainAxisSpacing = AppConstants.spacing12,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding ?? AppConstants.paddingMedium,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}
