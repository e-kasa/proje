import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import '../../services/purchase_service.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class PurchaseListState {
  final List<Map<String, dynamic>> purchases;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final bool? isCancelledFilter; // null=tümü, false=aktif, true=iptal

  const PurchaseListState({
    this.purchases = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.isCancelledFilter,
  });

  List<Map<String, dynamic>> get filtered {
    var list = purchases;
    if (isCancelledFilter != null) {
      list = list.where((p) => p['isCancelled'] == isCancelledFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((p) =>
              (p['invoiceNumber']?.toString().toLowerCase().contains(q) ?? false) ||
              (p['supplierName']?.toString().toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  PurchaseListState copyWith({
    List<Map<String, dynamic>>? purchases,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Object? isCancelledFilter = _sentinel,
  }) {
    return PurchaseListState(
      purchases: purchases ?? this.purchases,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      isCancelledFilter:
          isCancelledFilter == _sentinel ? this.isCancelledFilter : isCancelledFilter as bool?,
    );
  }
}

const _sentinel = Object();

// ─── Notifier ───────────────────────────────────────────────────────────────

class PurchaseListNotifier extends StateNotifier<PurchaseListState> {
  final PurchaseService _service;

  PurchaseListNotifier(this._service) : super(const PurchaseListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getPurchases();
      state = state.copyWith(purchases: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void setFilter(bool? val) => state = state.copyWith(isCancelledFilter: val);

  Future<void> cancel(String id, BuildContext context) async {
    try {
      await _service.cancelPurchase(id);
      await load();
      if (context.mounted) {
        AppToast.warning(context, 'Satın alma iptal edildi');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'İptal hatası: $e');
      }
    }
  }
}

final purchaseListProvider =
    StateNotifierProvider.autoDispose<PurchaseListNotifier, PurchaseListState>(
  (ref) => PurchaseListNotifier(ref.read(purchaseServiceProvider)),
);

// ─── Screen ─────────────────────────────────────────────────────────────────

class PurchaseListScreen extends ConsumerStatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  ConsumerState<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends ConsumerState<PurchaseListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppAppBar.standard(
        title: 'Satın Alma',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(purchaseListProvider.notifier).load(),
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/purchases/create');
          if (mounted) ref.read(purchaseListProvider.notifier).load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Alım'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(state, theme),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildError(state.error!)
                    : state.filtered.isEmpty
                        ? _buildEmpty()
                        : _buildList(state.filtered, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(PurchaseListState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Arama
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => ref.read(purchaseListProvider.notifier).setSearch(v),
            decoration: InputDecoration(
              hintText: 'Fatura no veya tedarikçi ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(purchaseListProvider.notifier).setSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: AppConstants.borderRadiusMedium,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
          const SizedBox(height: 8),
          // Filtre çipleri
          Row(
            children: [
              _filterChip('Tümü', null, state.isCancelledFilter),
              const SizedBox(width: 8),
              _filterChip('Aktif', false, state.isCancelledFilter),
              const SizedBox(width: 8),
              _filterChip('İptal', true, state.isCancelledFilter),
              const Spacer(),
              Text(
                '${state.filtered.length} kayıt',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool? value, bool? current) {
    final selected = current == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => ref.read(purchaseListProvider.notifier).setFilter(value),
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, ThemeData theme) {
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFmt = DateFormat('dd.MM.yyyy');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        final cancelled = p['isCancelled'] == true;
        final remaining = (p['remainingDebt'] as num?)?.toDouble() ?? 0;
        final total = (p['totalAmount'] as num?)?.toDouble() ?? 0;
        final dateStr = p['purchaseDate'] != null
            ? dateFmt.format(DateTime.tryParse(p['purchaseDate'].toString()) ?? DateTime.now())
            : '-';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
          borderColor: cancelled
              ? Colors.red.withOpacity(0.3)
              : null,
          onTap: () async {
            await context.push('/purchases/detail/${p['id']}');
            if (mounted) ref.read(purchaseListProvider.notifier).load();
          },
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cancelled
                              ? Colors.red.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: AppConstants.borderRadiusSmall,
                        ),
                        child: Icon(
                          cancelled ? Icons.cancel_outlined : Icons.receipt_long_rounded,
                          color: cancelled ? Colors.red : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['supplierName'] ?? 'Tedarikçi',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: cancelled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fatura: ${p['invoiceNumber'] ?? '-'}  •  $dateStr',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmt.format(total),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cancelled ? Colors.grey : AppColors.primary,
                            ),
                          ),
                          if (remaining > 0 && !cancelled)
                            Text(
                              'Borç: ${fmt.format(remaining)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (p['itemCount'] != null || cancelled) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (p['itemCount'] != null)
                          _tag(
                            '${p['itemCount']} kalem',
                            Icons.inventory_2_outlined,
                            theme.colorScheme.onSurfaceVariant,
                            theme,
                          ),
                        const Spacer(),
                        if (cancelled)
                          _tag('İptal Edildi', Icons.cancel_outlined, Colors.red, theme)
                        else if (remaining > 0)
                          _tag('Vadeli', Icons.schedule_rounded, Colors.orange, theme)
                        else
                          _tag('Ödendi', Icons.check_circle_outline, Colors.green, theme),
                        if (!cancelled) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _confirmCancel(p['id'] as String),
                            child: _tag('İptal Et', Icons.close_rounded, Colors.red, theme),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
          ),
        ),
        );
      },
    );
  }

  Widget _tag(String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppConstants.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return AppEmptyState.error(
      title: 'Veri yüklenirken hata oluştu',
      description: error,
      actionText: 'Tekrar Dene',
      onAction: () => ref.read(purchaseListProvider.notifier).load(),
    );
  }

  Widget _buildEmpty() {
    return AppEmptyState.noData(
      title: 'Satın alma kaydı bulunamadı',
      description: '"Yeni Alım" butonuna tıklayarak başlayın',
    );
  }

  Future<void> _confirmCancel(String id) async {
    final confirm = await AppConfirmationDialog.showDelete(
      context: context,
      title: 'Satın Almayı İptal Et',
      message: 'Bu satın almayı iptal etmek istediğinize emin misiniz?',
    );
    if (confirm && mounted) {
      await ref.read(purchaseListProvider.notifier).cancel(id, context);
    }
  }
}
