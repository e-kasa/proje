import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_constants.dart';
import '../../theme/app_gradients.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// Filter chip descriptor
// ---------------------------------------------------------------------------
class FilterChipData {
  final String label;
  final Color color;

  const FilterChipData({required this.label, required this.color});
}

// ---------------------------------------------------------------------------
// Base Entity List Screen
// ---------------------------------------------------------------------------
class BaseEntityListScreen<T> extends ConsumerStatefulWidget {
  /// Screen title shown in AppBar
  final String title;

  /// Search bar hint text
  final String searchHint;

  /// Icon shown in AppBar (unused currently but available for extensions)
  final IconData icon;

  /// Theme accent color for FAB, AppBar, etc.
  final Color accentColor;

  /// Fetches items. Receives ref and optional search string.
  final Future<List<T>> Function(WidgetRef ref, {String? search}) fetchItems;

  /// Builds an individual item card.
  /// [isSelected] indicates selection mode highlight.
  /// [onTap] should be called for default tap behaviour.
  final Widget Function(
    BuildContext context,
    T item,
    bool isSelected,
    VoidCallback onTap,
  ) itemBuilder;

  /// Optional stats widgets rendered above the list.
  final List<Widget> Function(List<T> items)? statsBuilder;

  /// Called when the add FAB is tapped. If null, no FAB is shown.
  final VoidCallback? onAdd;

  /// Called to delete a single item. If null, delete is unavailable.
  final Future<void> Function(T item)? onDelete;

  /// Filter chip definitions (including the default "Tumuu" chip).
  final List<FilterChipData> Function()? filterOptions;

  /// Returns true if [item] matches the given [filter] label.
  final bool Function(T item, String filter)? filterMatcher;

  /// Extracts a unique string id from an item (for selection tracking).
  final String Function(T item) idExtractor;

  /// FAB label text
  final String? fabLabel;

  /// FAB icon
  final IconData? fabIcon;

  /// Empty-state title when no data exists at all
  final String emptyTitle;

  /// Empty-state description
  final String emptyDescription;

  /// Empty-state action button text
  final String? emptyActionText;

  /// Custom bulk action icon (defaults to delete_outline)
  final IconData bulkActionIcon;

  /// Custom bulk action tooltip
  final String bulkActionTooltip;

  /// Custom bulk action handler. Receives selected ids.
  final Future<void> Function(Set<String> selectedIds)? onBulkAction;

  /// Extra AppBar actions when NOT in selection mode.
  final List<Widget> Function(VoidCallback reload)? extraActions;

  /// Whether search triggers a reload (server-side) or local filter.
  final bool serverSideSearch;

  /// Local search filter (used when [serverSideSearch] is false).
  final bool Function(T item, String query)? localSearchMatcher;

  const BaseEntityListScreen({
    super.key,
    required this.title,
    required this.searchHint,
    required this.icon,
    required this.accentColor,
    required this.fetchItems,
    required this.itemBuilder,
    required this.idExtractor,
    this.statsBuilder,
    this.onAdd,
    this.onDelete,
    this.filterOptions,
    this.filterMatcher,
    this.fabLabel,
    this.fabIcon,
    this.emptyTitle = 'Henuz veri yok',
    this.emptyDescription = 'Baslamak icin yeni kayit ekleyin',
    this.emptyActionText,
    this.bulkActionIcon = Icons.delete_outline,
    this.bulkActionTooltip = 'Secilenleri Sil',
    this.onBulkAction,
    this.extraActions,
    this.serverSideSearch = false,
    this.localSearchMatcher,
  });

  @override
  ConsumerState<BaseEntityListScreen<T>> createState() =>
      BaseEntityListScreenState<T>();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
enum _ScreenState { loading, loaded, error }

class BaseEntityListScreenState<T>
    extends ConsumerState<BaseEntityListScreen<T>> {
  final searchCtrl = TextEditingController();
  Timer? _debounce;

  List<T> _all = [];
  List<T> _filtered = [];
  Set<String> _selected = {};

  _ScreenState _state = _ScreenState.loading;
  String _errorMsg = '';
  bool _selectionMode = false;

  String _activeFilter = '';

  /// Expose filtered items for external stats builders
  List<T> get allItems => _all;
  List<T> get filteredItems => _filtered;
  bool get selectionMode => _selectionMode;

  // -------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _activeFilter =
        widget.filterOptions?.call().firstOrNull?.label ?? '';
    searchCtrl.addListener(_onSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  @override
  void dispose() {
    searchCtrl.removeListener(_onSearch);
    searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  void _onSearch() {
    _debounce?.cancel();
    if (widget.serverSideSearch) {
      _debounce = Timer(const Duration(milliseconds: 400), load);
    } else {
      _debounce = Timer(const Duration(milliseconds: 400), _applyLocalFilter);
    }
  }

  // -------------------------------------------------------------------------
  Future<void> load() async {
    setState(() {
      _state = _ScreenState.loading;
      _errorMsg = '';
    });

    try {
      final search = searchCtrl.text.trim().isEmpty
          ? null
          : searchCtrl.text.trim();

      final list = await widget.fetchItems(ref, search: search);

      if (!mounted) return;
      setState(() {
        _all = list;
        _state = _ScreenState.loaded;
        _applyLocalFilterSync();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMsg = e.toString();
      });
    }
  }

  void _applyLocalFilter() {
    if (mounted) setState(_applyLocalFilterSync);
  }

  void _applyLocalFilterSync() {
    var items = _all;

    // Local search
    if (!widget.serverSideSearch) {
      final q = searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty && widget.localSearchMatcher != null) {
        items = items.where((i) => widget.localSearchMatcher!(i, q)).toList();
      }
    }

    // Filter chips
    if (_activeFilter.isNotEmpty &&
        widget.filterMatcher != null) {
      items =
          items.where((i) => widget.filterMatcher!(i, _activeFilter)).toList();
    }

    _filtered = items;
  }

  // -------------------------------------------------------------------------
  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _startSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selected.add(id);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  Future<void> _handleBulkAction() async {
    if (_selected.isEmpty) return;
    if (widget.onBulkAction != null) {
      await widget.onBulkAction!(_selected);
      if (mounted) {
        setState(() {
          _selected.clear();
          _selectionMode = false;
        });
        load();
      }
    }
  }

  // =========================================================================
  // Build
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // -------------------------------------------------------------------------
  Widget? _buildFab() {
    if (_selectionMode) return null;
    if (widget.onAdd == null) return null;
    return FloatingActionButton.extended(
      onPressed: widget.onAdd,
      backgroundColor: widget.accentColor,
      icon: Icon(widget.fabIcon ?? Icons.add, color: Colors.white),
      label: Text(
        widget.fabLabel ?? 'Yeni Ekle',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  AppBar _buildAppBar() {
    return AppBar(
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primaryGradient),
      ),
      title: _selectionMode
          ? Text(
              '${_selected.length} secili',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            )
          : Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
      actions: [
        if (_selectionMode) ...[
          if (widget.onBulkAction != null)
            IconButton(
              icon: Icon(widget.bulkActionIcon),
              onPressed: _handleBulkAction,
              tooltip: widget.bulkActionTooltip,
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exitSelection,
          ),
        ] else ...[
          if (widget.extraActions != null)
            ...widget.extraActions!(load),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: load,
            tooltip: 'Yenile',
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------------
  Widget _buildSearchAndFilters() {
    final filters = widget.filterOptions?.call() ?? [];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppSearchInput(
              controller: searchCtrl,
              hint: widget.searchHint,
            ),
          ),

          // Filter chips
          if (filters.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: filters
                    .map((f) => _buildFilterChip(
                          label: f.label,
                          selected: _activeFilter == f.label,
                          color: f.color,
                          onTap: () {
                            setState(() => _activeFilter = f.label);
                            if (widget.serverSideSearch) {
                              load();
                            } else {
                              _applyLocalFilter();
                            }
                          },
                        ))
                    .toList(),
              ),
            ),

          // Stats
          if (_state == _ScreenState.loaded && widget.statsBuilder != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: widget.statsBuilder!(_all)
                    .expand((w) => [w, const SizedBox(width: 10)])
                    .toList()
                  ..removeLast(),
              ),
            ),

          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: AppConstants.borderRadiusFull,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  Widget _buildBody() {
    return switch (_state) {
      _ScreenState.loading => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppSkeletonCard(),
          ),
        ),
      _ScreenState.error => AppEmptyState.error(
          description: _errorMsg,
          onAction: load,
        ),
      _ScreenState.loaded => _buildList(),
    };
  }

  Widget _buildList() {
    if (_all.isEmpty) {
      return AppEmptyState.noData(
        title: widget.emptyTitle,
        description: widget.emptyDescription,
        actionText: widget.emptyActionText,
        onAction: widget.onAdd,
      );
    }

    if (_filtered.isEmpty) {
      return AppEmptyState.search(
        description: 'Farkli filtreler veya arama terimi deneyin',
      );
    }

    return RefreshIndicator(
      color: widget.accentColor,
      onRefresh: load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop grid (> 800px width)
          if (constraints.maxWidth > 800) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 1200 ? 3 : 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 140,
              ),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) => _buildItemWrapper(_filtered[i]),
            );
          }

          // Mobile list
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) => _buildItemWrapper(_filtered[i]),
          );
        },
      ),
    );
  }

  Widget _buildItemWrapper(T item) {
    final id = widget.idExtractor(item);
    final isSelected = _selected.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: () => _startSelection(id),
        child: widget.itemBuilder(
          context,
          item,
          isSelected,
          () {
            if (_selectionMode) {
              _toggleSelection(id);
            }
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable stat pill widget (shared across screens)
// ---------------------------------------------------------------------------
class StatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatPill({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppConstants.borderRadiusSmall,
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable popup menu row widget
// ---------------------------------------------------------------------------
class MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const MenuRow(this.icon, this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}