import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/config/sector_config.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_gradients.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/providers/sector_provider.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'providers/batch_entry_provider.dart';
import 'models/batch_entry_models.dart';
import 'widgets/batch_header_form.dart';

// KDV seçenekleri
const _vatOptions = [0.0, 1.0, 8.0, 10.0, 18.0, 20.0];

class BatchProductScreen extends ConsumerStatefulWidget {
  const BatchProductScreen({super.key});

  @override
  ConsumerState<BatchProductScreen> createState() => _BatchProductScreenState();
}

class _BatchProductScreenState extends ConsumerState<BatchProductScreen>
    with SingleTickerProviderStateMixin {
  final _barcodeController = TextEditingController();
  final _barcodeFocus = FocusNode();
  late final TabController _tabController;
  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  static const _tabs = [
    _Tab('all', null),
    _Tab('new', RowStatus.newProduct),
    _Tab('existing', RowStatus.existing),
    _Tab('error', RowStatus.error),
    _Tab('saved', RowStatus.saved),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addByBarcode() async {
    final input = _barcodeController.text.trim();
    if (input.isEmpty) return;
    final msg =
        await ref.read(batchEntryProvider.notifier).addByBarcode(input);
    _barcodeController.clear();
    _barcodeFocus.requestFocus();
    if (msg != null && mounted) {
      AppToast.info(context, msg);
    }
  }

  Future<void> _submit(BatchEntryState state) async {
    // Validasyon
    final err = ref.read(batchEntryProvider.notifier).validateAll();
    if (err != null) {
      _showError(err);
      return;
    }

    final t = i18nOf(ref);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(state: state, currency: _currency, t: t),
    );
    if (ok != true || !mounted) return;

    try {
      final result =
          await ref.read(batchEntryProvider.notifier).submitAll();
      if (!mounted) return;
      _showResultSheet(result);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _showError(String msg) {
    AppToast.error(context, msg);
  }

  void _showResultSheet(BatchSaveResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultSheet(result: result, currency: _currency, t: i18nOf(ref)),
    );
  }

  List<BatchEntryRow> _filteredRows(
      List<BatchEntryRow> rows, RowStatus? filter) {
    if (filter == null) return rows;
    if (filter == RowStatus.existing) {
      return rows.where((r) => r.isExisting).toList();
    }
    return rows.where((r) => r.status == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final state = ref.watch(batchEntryProvider);
    final cfg = ref.watch(sectorConfigProvider);

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: state.supplierName != null
            ? '${t('batch.bulk_product_entry')} · ${state.supplierName}'
            : t('batch.bulk_product_entry'),
        actions: [
          if (state.rows.isNotEmpty) ...[
            _AppBarChip(
              label: '${state.totalItems}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
            ),
            const SizedBox(width: 6),
            _AppBarChip(
              label: '${state.newItems} ${t('batch.new').toLowerCase()}',
              icon: Icons.add_circle_outline,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: t('batch.clear_list'),
              color: AppColors.danger,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          const BatchHeaderForm(),
          _buildSearchBar(cfg, t),
          _buildTabBar(state, t),
          Expanded(child: _buildBody(state, cfg, t)),
          _buildSummaryBar(state, t),
        ],
      ),
    );
  }

  void _confirmClear() async {
    final t = i18nOf(ref);
    final ok = await AppConfirmationDialog.showWarning(
      context: context,
      title: t('batch.clear_list'),
      message: t('batch.clear_list_confirm'),
    );
    if (ok) ref.read(batchEntryProvider.notifier).clearAll();
  }

  // ── SEARCH / BARCODE BAR ──────────────────────────────────────────────────
  Widget _buildSearchBar(SectorConfig cfg, Function(String) t) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocus,
              onSubmitted: (_) => _addByBarcode(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: cfg.barcodeHint,
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.primary, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  onPressed: _addByBarcode,
                  tooltip: t('batch.search_and_add'),
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF4F5F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: t('batch.add_manual_row'),
            child: Material(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => ref.read(batchEntryProvider.notifier).addManualRow(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ──────────────────────────────────────────────────────────────
  String _tabLabel(String key, Function(String) t) {
    return switch (key) {
      'all' => t('batch.all'),
      'new' => t('batch.new'),
      'existing' => t('batch.existing'),
      'error' => t('common.error'),
      'saved' => t('batch.saved'),
      _ => key,
    };
  }

  Widget _buildTabBar(BatchEntryState state, Function(String) t) {
    int _count(RowStatus? s) {
      if (s == null) return state.rows.length;
      if (s == RowStatus.existing) {
        return state.rows.where((r) => r.isExisting).length;
      }
      return state.rows.where((r) => r.status == s).length;
    }

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        tabs: _tabs.map((tab) {
          final count = _count(tab.status);
          return Tab(
            child: Row(
              children: [
                Text(_tabLabel(tab.label, t)),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _tabBadgeColor(tab.status)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _tabBadgeColor(tab.status),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _tabBadgeColor(RowStatus? s) {
    if (s == null) return AppColors.primary;
    return switch (s) {
      RowStatus.newProduct => AppColors.info,
      RowStatus.existing || RowStatus.matched => AppColors.success,
      RowStatus.error => AppColors.danger,
      RowStatus.saved => AppColors.success,
      RowStatus.saving => AppColors.warning,
    };
  }

  // ── BODY ─────────────────────────────────────────────────────────────────
  Widget _buildBody(BatchEntryState state, SectorConfig cfg, Function(String) t) {
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((tab) {
        final rows = _filteredRows(state.rows, tab.status);
        if (rows.isEmpty) return _buildEmptyState(tab.status, t);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          itemCount: rows.length,
          itemBuilder: (_, i) => _BatchRowCard(
            row: rows[i],
            rowIndex: i,
            currency: _currency,
            cfg: cfg,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(RowStatus? status, Function(String) t) {
    final (icon, title, sub) = status == null
        ? (
            Icons.inventory_2_outlined,
            t('batch.no_products_yet'),
            t('batch.scan_or_add_manual'),
          )
        : (
            Icons.filter_list_off_rounded,
            t('batch.no_products_in_category'),
            t('batch.select_different_tab'),
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child:
                  Icon(icon, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY BAR ──────────────────────────────────────────────────────────
  Widget _buildSummaryBar(BatchEntryState state, Function(String) t) {
    final cfg = ref.read(sectorConfigProvider);
    final totalQty = state.rows.fold(0, (s, r) => s + r.quantity);
    final margin = state.totalSale > 0
        ? (state.totalProfit / state.totalSale * 100)
        : 0.0;
    final readyCount = state.rows.where((r) {
      if (r.isSaved || r.status == RowStatus.saving) return false;
      final c = BatchRowCompletion.compute(
        r,
        isExisting: r.isExisting,
        brandRequired: cfg.fields.brandRequired,
        oemRequired: cfg.fields.oemRequired,
        shelfRequired: cfg.fields.shelfRequired,
        showOem: cfg.fields.showOem,
        showShelf: cfg.fields.showShelf,
      );
      return c.readiness == CardReadiness.ready;
    }).length;
    final pendingCount =
        state.rows.where((r) => !r.isSaved && r.status != RowStatus.saving).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hazır / toplam göstergesi
              if (state.rows.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pendingCount > 0
                              ? readyCount / pendingCount
                              : 0,
                          minHeight: 4,
                          backgroundColor:
                              AppColors.border.withValues(alpha: 0.5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.success),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$readyCount/$pendingCount ${t('batch.ready')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: readyCount == pendingCount && pendingCount > 0
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
            children: [
              // Metrics
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _Metric(
                        label: t('product.product'),
                        value: '${state.totalItems}',
                        color: AppColors.primary),
                    _Metric(
                        label: t('common.quantity'),
                        value: '$totalQty',
                        color: AppColors.info),
                    _Metric(
                        label: t('batch.cost'),
                        value: _currency.format(state.totalCost),
                        color: AppColors.warning),
                    _Metric(
                        label: t('batch.sale'),
                        value: _currency.format(state.totalSale),
                        color: AppColors.success),
                    _Metric(
                        label: t('batch.profit_percent'),
                        value: '%${margin.toStringAsFixed(1)}',
                        color: margin >= 20
                            ? AppColors.success
                            : AppColors.danger),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Save button
              SizedBox(
                height: 48,
                child: state.isSubmitting
                    ? Container(
                        width: 140,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: state.rows.isEmpty
                            ? null
                            : () => _submit(state),
                        child: Container(
                          width: 140,
                          decoration: BoxDecoration(
                            gradient: state.rows.isEmpty
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFc8ccd8),
                                      Color(0xFFc8ccd8)
                                    ],
                                  )
                                : AppGradients.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: state.rows.isEmpty
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                readyCount > 0 && readyCount < pendingCount
                                    ? '${t('common.save')} ($readyCount)'
                                    : t('common.save'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── BATCH ROW CARD ────────────────────────────────────────────────────────────
class _BatchRowCard extends ConsumerStatefulWidget {
  final BatchEntryRow row;
  final int rowIndex;
  final NumberFormat currency;
  final SectorConfig cfg;
  const _BatchRowCard({
    required this.row,
    required this.rowIndex,
    required this.currency,
    required this.cfg,
  });

  @override
  ConsumerState<_BatchRowCard> createState() => _BatchRowCardState();
}

class _BatchRowCardState extends ConsumerState<_BatchRowCard> {

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BatchRowEditDialog(
        rowId: widget.row.id,
        cfg: widget.cfg,
        currency: widget.currency,
      ),
    );
  }

  void _update({
    String? productName,
    String? barcode,
    String? oemNumber,
    List<Map<String, String>>? oemList,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    String? categoryId,
    String? categoryName,
    String? brandName,
    String? unitId,
    String? shelfLocation,
    int? minStockLevel,
    bool? isExpanded,
    double? vatRate,
    bool? vatIncluded,
    String? description,
    Map<String, String>? attributes,
    List<BatchVariantRow>? variantRows,
  }) {
    ref.read(batchEntryProvider.notifier).updateRow(
          widget.row.id,
          productName: productName,
          barcode: barcode,
          oemNumber: oemNumber,
          oemList: oemList,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          quantity: quantity,
          categoryId: categoryId,
          categoryName: categoryName,
          brandName: brandName,
          unitId: unitId,
          shelfLocation: shelfLocation,
          minStockLevel: minStockLevel,
          isExpanded: isExpanded,
          vatRate: vatRate,
          vatIncluded: vatIncluded,
          description: description,
          attributes: attributes,
          variantRows: variantRows,
        );
  }

  BatchRowCompletion get _completion => BatchRowCompletion.compute(
        widget.row,
        isExisting: widget.row.isExisting,
        brandRequired: widget.cfg.fields.brandRequired,
        oemRequired: widget.cfg.fields.oemRequired,
        shelfRequired: widget.cfg.fields.shelfRequired,
        showOem: widget.cfg.fields.showOem,
        showShelf: widget.cfg.fields.showShelf,
        showVariantTable: widget.cfg.fields.showVariantSize,
      );

  Color get _statusColor => switch (_completion.readiness) {
        CardReadiness.draft => AppColors.textMuted,
        CardReadiness.incomplete => AppColors.warning,
        CardReadiness.ready => AppColors.success,
        CardReadiness.saving => AppColors.warning,
        CardReadiness.saved => AppColors.success,
        CardReadiness.error => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final row = widget.row;
    final margin = row.salePrice > 0
        ? ((row.salePrice - row.purchasePrice) / row.salePrice * 100)
        : 0.0;

    final accentColor = _accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showEditDialog(context),
          borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left status bar + row number
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(2),
                              bottomRight: Radius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Row number badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.rowIndex + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Üst satır: hazırlık badge + ürün adı
                          Row(
                            children: [
                              _ReadinessBadge(
                                  completion: _completion, t: t),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  row.productName.isNotEmpty
                                      ? row.productName
                                      : row.barcode.isNotEmpty
                                          ? row.barcode
                                          : t('batch.enter_product_name'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: row.productName.isEmpty
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Alt satır: meta chip'ler + wizard dots
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 3,
                                  children: [
                                    if (row.barcode.isNotEmpty)
                                      _MetaChip(
                                        icon: Icons.qr_code_rounded,
                                        label: row.barcode,
                                      ),
                                    if (row.categoryName != null &&
                                        row.categoryName!.isNotEmpty)
                                      _MetaChip(
                                        icon: Icons.category_outlined,
                                        label: row.categoryName!,
                                        color: accentColor,
                                      ),
                                    if (row.brandName != null &&
                                        row.brandName!.isNotEmpty)
                                      _MetaChip(
                                        icon: Icons.business_outlined,
                                        label: row.brandName!,
                                      ),
                                    // Footwear: varyant sayısı chip
                                    if (widget.cfg.fields.showVariantSize &&
                                        row.variantRows.isNotEmpty)
                                      _MetaChip(
                                        icon: Icons.layers_rounded,
                                        label: '${row.variantRows.length} varyant',
                                        color: accentColor,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              _WizardStepDots(completion: _completion),
                            ],
                          ),
                          // Eksik alan uyarısı (sadece incomplete)
                          if (_completion.readiness == CardReadiness.incomplete &&
                              _completion.missingFields.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 11, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _completion.missingFields.join(', '),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Hata mesajı
                          if (row.errorMessage != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 11, color: AppColors.danger),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    row.errorMessage!,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.danger),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Right: prices + margin + quantity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (row.salePrice > 0) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (row.purchasePrice > 0) ...[
                                Text(
                                  widget.currency.format(row.purchasePrice),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(Icons.arrow_forward_rounded,
                                      size: 10, color: AppColors.textMuted),
                                ),
                              ],
                              Text(
                                widget.currency.format(row.salePrice),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          if (margin > 0) ...[
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: (margin >= 20
                                        ? AppColors.success
                                        : AppColors.warning)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Kâr %${margin.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: margin >= 20
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                        ],
                        _QuantityControl(
                          quantity: row.quantity,
                          onChanged: (q) => _update(quantity: q),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined,
                        color: AppColors.textMuted, size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
  }

  Color get _accentColor => switch (widget.cfg.type) {
        SectorType.autoParts => AppColors.orange,
        SectorType.footwear => AppColors.pink,
        SectorType.technology => AppColors.info,
        SectorType.general => AppColors.primary,
      };
}

// ── BATCH ROW EDIT DIALOG ─────────────────────────────────────────────────────
class _BatchRowEditDialog extends ConsumerStatefulWidget {
  final String rowId;
  final SectorConfig cfg;
  final NumberFormat currency;

  const _BatchRowEditDialog({
    required this.rowId,
    required this.cfg,
    required this.currency,
  });

  @override
  ConsumerState<_BatchRowEditDialog> createState() => _BatchRowEditDialogState();
}

class _BatchRowEditDialogState extends ConsumerState<_BatchRowEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _oemCtrl;
  late final TextEditingController _purchaseCtrl;
  late final TextEditingController _saleCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _shelfCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _minStockCtrl;

  @override
  void initState() {
    super.initState();
    final r = ref.read(batchEntryProvider).rows
        .firstWhere((r) => r.id == widget.rowId, orElse: () => BatchEntryRow());
    _nameCtrl = TextEditingController(text: r.productName);
    _barcodeCtrl = TextEditingController(text: r.barcode);
    _oemCtrl = TextEditingController(text: r.oemNumber ?? '');
    _purchaseCtrl = TextEditingController(
        text: r.purchasePrice > 0 ? r.purchasePrice.toString() : '');
    _saleCtrl = TextEditingController(
        text: r.salePrice > 0 ? r.salePrice.toString() : '');
    _brandCtrl = TextEditingController(text: r.brandName ?? '');
    _shelfCtrl = TextEditingController(text: r.shelfLocation ?? '');
    _descCtrl = TextEditingController(text: r.description ?? '');
    _minStockCtrl = TextEditingController(text: r.minStockLevel.toString());
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _barcodeCtrl, _oemCtrl, _purchaseCtrl,
      _saleCtrl, _brandCtrl, _shelfCtrl, _descCtrl, _minStockCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _update({
    String? productName,
    String? barcode,
    String? oemNumber,
    List<Map<String, String>>? oemList,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    String? categoryId,
    String? categoryName,
    String? brandName,
    String? unitId,
    String? shelfLocation,
    int? minStockLevel,
    double? vatRate,
    bool? vatIncluded,
    String? description,
    Map<String, String>? attributes,
    List<BatchVariantRow>? variantRows,
  }) {
    ref.read(batchEntryProvider.notifier).updateRow(
          widget.rowId,
          productName: productName,
          barcode: barcode,
          oemNumber: oemNumber,
          oemList: oemList,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          quantity: quantity,
          categoryId: categoryId,
          categoryName: categoryName,
          brandName: brandName,
          unitId: unitId,
          shelfLocation: shelfLocation,
          minStockLevel: minStockLevel,
          vatRate: vatRate,
          vatIncluded: vatIncluded,
          description: description,
          attributes: attributes,
          variantRows: variantRows,
        );
  }

  BatchRowCompletion _completion(BatchEntryRow row) => BatchRowCompletion.compute(
        row,
        isExisting: row.isExisting,
        brandRequired: widget.cfg.fields.brandRequired,
        oemRequired: widget.cfg.fields.oemRequired,
        shelfRequired: widget.cfg.fields.shelfRequired,
        showOem: widget.cfg.fields.showOem,
        showShelf: widget.cfg.fields.showShelf,
        showVariantTable: widget.cfg.fields.showVariantSize,
      );

  Color get _accentColor => switch (widget.cfg.type) {
        SectorType.autoParts => AppColors.orange,
        SectorType.footwear => AppColors.pink,
        SectorType.technology => AppColors.info,
        SectorType.general => AppColors.primary,
      };

  IconData get _accentIcon => switch (widget.cfg.type) {
        SectorType.autoParts => Icons.build_circle_outlined,
        SectorType.footwear => Icons.shopping_bag_outlined,
        SectorType.technology => Icons.devices_outlined,
        SectorType.general => Icons.store_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final row = ref.watch(batchEntryProvider.select(
      (s) => s.rows.firstWhere((r) => r.id == widget.rowId,
          orElse: () => BatchEntryRow()),
    ));

    // Satır silindiyse dialog'u kapat
    if (row.id != widget.rowId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final t = i18nOf(ref);
    final completion = _completion(row);
    final accentColor = _accentColor;
    final accentIcon = _accentIcon;
    final margin = row.salePrice > 0
        ? ((row.salePrice - row.purchasePrice) / row.salePrice * 100)
        : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Dialog Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: accentColor.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(accentIcon, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.productName.isNotEmpty
                              ? row.productName
                              : row.barcode.isNotEmpty
                                  ? row.barcode
                                  : t('batch.enter_product_name'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: row.productName.isEmpty
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        _ReadinessBadge(completion: completion, t: t),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _WizardStepDots(completion: completion),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded,
                            size: 20, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable form ───────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // ── Bölüm 1: Ürün Bilgileri ──────────────────────────────
                  _WizardSectionHeader(
                    stepNumber: 1,
                    title: t('product.basic_info'),
                    section: completion.sectionA,
                    isRequired: true,
                    t: t,
                  ),
                  const SizedBox(height: 8),

                  if (row.isExisting)
                    _ExistingProductInfoCard(row: row, accentColor: accentColor, t: t)
                  else
                    _SectionCard(
                      icon: Icons.inventory_2_outlined,
                      title: t('product.basic_info'),
                      color: AppColors.info,
                      showHeader: false,
                      child: Column(
                        children: [
                          _FormRow(children: [
                            _Field(
                              label: '${t('product.product_name')} *',
                              ctrl: _nameCtrl,
                              onChanged: (v) => _update(productName: v),
                              hint: t('batch.enter_product_name'),
                            ),
                            _Field(
                              label: widget.cfg.labels.barcodeLabel,
                              ctrl: _barcodeCtrl,
                              onChanged: (v) => _update(barcode: v),
                              hint: 'EAN13 / QR',
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _FormRow(children: [
                            _CategoryDropdown(
                              label: '${widget.cfg.labels.categoryName} *',
                              selectedId: row.categoryId,
                              onSelected: (id, name) =>
                                  _update(categoryId: id, categoryName: name),
                            ),
                            if (widget.cfg.fields.showBrand)
                              _Field(
                                label: t('product.brand') +
                                    (widget.cfg.fields.brandRequired ? ' *' : ''),
                                ctrl: _brandCtrl,
                                onChanged: (v) => _update(brandName: v),
                                hint: widget.cfg.type == SectorType.autoParts
                                    ? t('batch.hint_auto_brand')
                                    : t('batch.hint_brand_name'),
                              )
                            else
                              const SizedBox.shrink(),
                          ]),
                          const SizedBox(height: 10),
                          _UnitDropdown(
                            label: t('product.unit'),
                            value: row.unitId ?? 'adet',
                            onChanged: (v) => _update(unitId: v),
                          ),
                          const SizedBox(height: 10),
                          _DescField(
                            label: t('product.description'),
                            ctrl: _descCtrl,
                            onChanged: (v) => _update(description: v),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ── Bölüm 2: Fiyat & Stok ────────────────────────────────
                  _WizardSectionHeader(
                    stepNumber: 2,
                    title: t('batch.price_and_stock'),
                    section: completion.sectionB,
                    isRequired: true,
                    t: t,
                  ),
                  const SizedBox(height: 8),
                  _SectionCard(
                    icon: Icons.attach_money_rounded,
                    title: t('batch.price_and_stock'),
                    color: AppColors.success,
                    showHeader: false,
                    child: Column(
                      children: [
                        _FormRow(children: [
                          _Field(
                            label: '${t('batch.purchase_price')} ₺' +
                                (row.isExisting ? ' *' : ''),
                            ctrl: _purchaseCtrl,
                            onChanged: (v) =>
                                _update(purchasePrice: double.tryParse(v) ?? 0),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            hint: '0,00',
                          ),
                          _Field(
                            label: '${widget.cfg.labels.salePriceLabel} ₺ *',
                            ctrl: _saleCtrl,
                            onChanged: (v) =>
                                _update(salePrice: double.tryParse(v) ?? 0),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            hint: '0,00',
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: _VatDropdown(
                              label: t('batch.vat'),
                              value: row.vatRate,
                              onChanged: (v) => _update(vatRate: v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _VatIncludedSwitch(
                              label: t('batch.vat_included'),
                              value: row.vatIncluded,
                              onChanged: (v) => _update(vatIncluded: v),
                            ),
                          ),
                        ]),
                        if (row.salePrice > 0 && row.purchasePrice > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.trending_up_rounded,
                                  size: 15, color: AppColors.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: t('batch.unit_profit') + ': ',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                    ),
                                    TextSpan(
                                      text: widget.currency.format(
                                              row.salePrice -
                                                  row.purchasePrice) +
                                          '  •  ',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success),
                                    ),
                                    TextSpan(
                                      text: t('common.total') + ': ',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                    ),
                                    TextSpan(
                                      text: widget.currency
                                          .format(row.lineProfit),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success),
                                    ),
                                    TextSpan(
                                      text:
                                          '  •  Marj: %${margin.toStringAsFixed(1)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: margin >= 20
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ]),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Bölüm 3: Detaylar / Sektöre Özgü ────────────────────
                  if (widget.cfg.fields.showVariantSize) ...[
                    // FOOTWEAR: Varyant tablosu
                    const SizedBox(height: 14),
                    _WizardSectionHeader(
                      stepNumber: 3,
                      title: t('batch.variants'),
                      section: completion.sectionC,
                      isRequired: true,
                      t: t,
                    ),
                    const SizedBox(height: 8),
                    _FootwearVariantTable(
                      variantRows: row.variantRows,
                      defaultPurchasePrice: row.purchasePrice,
                      defaultSalePrice: row.salePrice,
                      sizeLabel: widget.cfg.labels.variantField,
                      accentColor: accentColor,
                      onChanged: (rows) => _update(variantRows: rows),
                    ),
                  ] else if (widget.cfg.fields.showOem ||
                      widget.cfg.fields.showShelf) ...[
                    // Diğer sektörler: OEM / Raf / Min Stok
                    const SizedBox(height: 14),
                    _WizardSectionHeader(
                      stepNumber: 3,
                      title: '${widget.cfg.type.displayName} ${t('batch.fields')}',
                      section: completion.sectionC,
                      isRequired: widget.cfg.fields.oemRequired ||
                          widget.cfg.fields.shelfRequired,
                      t: t,
                    ),
                    const SizedBox(height: 8),
                    _SectionCard(
                      icon: accentIcon,
                      title: '${widget.cfg.type.displayName} ${t('batch.fields')}',
                      color: accentColor,
                      showHeader: false,
                      child: Column(
                        children: [
                          _FormRow(children: [
                            if (widget.cfg.fields.showOem)
                              _Field(
                                label: widget.cfg.labels.oemField +
                                    (widget.cfg.fields.oemRequired ? ' *' : ''),
                                ctrl: _oemCtrl,
                                onChanged: (v) => _update(
                                  oemNumber: v,
                                  oemList: v.trim().isEmpty
                                      ? []
                                      : [{'oemNumber': v.trim(), 'manufacturer': ''}],
                                ),
                                hint: widget.cfg.type == SectorType.technology
                                    ? t('batch.hint_imei_serial')
                                    : t('batch.hint_original_part_no'),
                              )
                            else
                              const SizedBox.shrink(),
                            if (widget.cfg.fields.showShelf)
                              _Field(
                                label: widget.cfg.labels.shelfField +
                                    (widget.cfg.fields.shelfRequired ? ' *' : ''),
                                ctrl: _shelfCtrl,
                                onChanged: (v) => _update(shelfLocation: v),
                                hint: 'A-12-3',
                              )
                            else
                              const SizedBox.shrink(),
                          ]),
                          const SizedBox(height: 10),
                          _FormRow(children: [
                            _Field(
                              label: t('batch.min_stock_level'),
                              ctrl: _minStockCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  _update(minStockLevel: int.tryParse(v) ?? 10),
                              hint: '10',
                            ),
                            const SizedBox.shrink(),
                          ]),
                        ],
                      ),
                    ),
                  ],

                  // ── Bölüm 4: Varyant Özellikleri (Footwear hariç) ────────
                  if (row.isNew && !widget.cfg.fields.showVariantSize) ...[
                    const SizedBox(height: 10),
                    _BatchAttributesSection(
                      attributes: row.attributes,
                      cfg: widget.cfg,
                      onChanged: (attrs) => _update(attributes: attrs),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Footer actions ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => ref
                            .read(batchEntryProvider.notifier)
                            .removeRow(row.id),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.danger),
                        label: Text(t('common.remove'),
                            style:
                                const TextStyle(color: AppColors.danger, fontSize: 13)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ),

            // ── Dialog Footer ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ref.read(batchEntryProvider.notifier).removeRow(widget.rowId);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.danger),
                    label: Text(t('common.remove'),
                        style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t('common.close'),
                        style: const TextStyle(color: AppColors.textSecondary)),
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

// ── QUANTITY CONTROL ──────────────────────────────────────────────────────────
class _QuantityControl extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  const _QuantityControl(
      {required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QBtn(
            icon: Icons.remove_rounded,
            onTap: quantity > 1
                ? () => onChanged(quantity - 1)
                : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _QBtn(
            icon: Icons.add_rounded,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? AppColors.border : AppColors.primary,
        ),
      ),
    );
  }
}

// ── FORM HELPERS ──────────────────────────────────────────────────────────────
class _FormRow extends StatelessWidget {
  final List<Widget> children;
  const _FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map((c) => Expanded(child: c))
          .toList()
          .fold<List<Widget>>([], (acc, w) {
        if (acc.isNotEmpty) acc.add(const SizedBox(width: 10));
        acc.add(w);
        return acc;
      }),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextInputType? keyboardType;
  const _Field({
    required this.label,
    required this.ctrl,
    required this.onChanged,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: keyboardType ==
                    const TextInputType.numberWithOptions(decimal: true)
                ? [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'))
                  ]
                : null,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide:
                    const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide:
                    const BorderSide(color: Color(0xFFE8E9F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── CATEGORY DROPDOWN ─────────────────────────────────────────────────────────
class _CategoryDropdown extends ConsumerWidget {
  final String label;
  final String? selectedId;
  final void Function(String id, String name) onSelected;

  const _CategoryDropdown({
    required this.label,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(batchCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        asyncCats.when(
          loading: () => const SizedBox(
            height: 40,
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (_, __) => const SizedBox(height: 40),
          data: (cats) {
            final safeValue = cats.any(
                    (c) => c['id']?.toString() == selectedId)
                ? selectedId
                : null;
            return SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                value: safeValue,
                isExpanded: true,
                hint: const Text(
                  '— Seçin —',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: Color(0xFFE8E9F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
                items: cats.map((c) {
                  final id = c['id']?.toString() ?? '';
                  final name = c['name']?.toString() ?? '';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final cat = cats.firstWhere(
                      (c) => c['id']?.toString() == id,
                      orElse: () => {});
                  onSelected(id, cat['name']?.toString() ?? '');
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── UNIT DROPDOWN ─────────────────────────────────────────────────────────────
class _UnitDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _UnitDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const _units = [
    ('adet', 'Adet'),
    ('kg', 'Kilogram (kg)'),
    ('lt', 'Litre (lt)'),
    ('mt', 'Metre (mt)'),
    ('m2', 'Metrekare (m²)'),
    ('kutu', 'Kutu'),
    ('paket', 'Paket'),
    ('takim', 'Takım'),
    ('cift', 'Çift'),
    ('set', 'Set'),
    ('pcs', 'Piece (pcs)'),
  ];

  @override
  Widget build(BuildContext context) {
    final safeValue = _units.any((u) => u.$1 == value) ? value : 'adet';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            value: safeValue,
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFE8E9F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            items: _units
                .map((u) => DropdownMenuItem<String>(
                      value: u.$1,
                      child: Text(u.$2, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ── DESCRIPTION FIELD ─────────────────────────────────────────────────────────
class _DescField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;

  const _DescField({
    required this.label,
    required this.ctrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          onChanged: onChanged,
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '…',
            hintStyle:
                const TextStyle(fontSize: 12, color: AppColors.textMuted),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF7F8FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFE8E9F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── VAT DROPDOWN ──────────────────────────────────────────────────────────────
class _VatDropdown extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _VatDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue =
        _vatOptions.contains(value) ? value : _vatOptions.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label %',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<double>(
            value: safeValue,
            isExpanded: true,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFE8E9F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
            items: _vatOptions
                .map((v) => DropdownMenuItem<double>(
                      value: v,
                      child: Text('%${v.toInt()}'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ── VAT INCLUDED SWITCH ────────────────────────────────────────────────────────
class _VatIncludedSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _VatIncludedSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                value ? 'Dahil' : 'Hariç',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      value ? AppColors.success : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── APP BAR CHIP ──────────────────────────────────────────────────────────────
class _AppBarChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _AppBarChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── META CHIP ─────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaChip(
      {required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: c),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: c,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SECTION CARD ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  final bool showHeader;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
              ]),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── READINESS BADGE ───────────────────────────────────────────────────────────
class _ReadinessBadge extends StatelessWidget {
  final BatchRowCompletion completion;
  final Function(String) t;
  const _ReadinessBadge({required this.completion, required this.t});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (completion.readiness) {
      CardReadiness.draft => (
          t('batch.status_draft'),
          AppColors.textMuted,
          Icons.circle_outlined
        ),
      CardReadiness.incomplete => (
          t('batch.status_incomplete'),
          AppColors.warning,
          Icons.warning_amber_rounded
        ),
      CardReadiness.ready => (
          t('batch.status_ready'),
          AppColors.success,
          Icons.check_circle_outline_rounded
        ),
      CardReadiness.saving => (
          '...',
          AppColors.warning,
          Icons.hourglass_top_rounded
        ),
      CardReadiness.saved => (
          t('batch.status_saved'),
          AppColors.success,
          Icons.check_circle
        ),
      CardReadiness.error => (
          t('batch.status_error'),
          AppColors.danger,
          Icons.error_outline
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── WIZARD STEP DOTS ──────────────────────────────────────────────────────────
class _WizardStepDots extends StatelessWidget {
  final BatchRowCompletion completion;
  const _WizardStepDots({required this.completion});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(section: completion.sectionA),
        const SizedBox(width: 3),
        _Dot(section: completion.sectionB),
        const SizedBox(width: 3),
        _Dot(section: completion.sectionC),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final SectionStatus section;
  const _Dot({required this.section});

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      SectionStatus.complete => Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
      SectionStatus.partial => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.warning, width: 1.5),
          ),
        ),
      SectionStatus.empty => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
        ),
    };
  }
}

// ── WIZARD SECTION HEADER ─────────────────────────────────────────────────────
class _WizardSectionHeader extends StatelessWidget {
  final int stepNumber;
  final String title;
  final SectionStatus section;
  final bool isRequired;
  final Function(String) t;
  const _WizardSectionHeader({
    required this.stepNumber,
    required this.title,
    required this.section,
    required this.isRequired,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipColor) = switch (section) {
      SectionStatus.complete => (t('batch.section_complete'), AppColors.success),
      SectionStatus.partial => (t('batch.section_partial'), AppColors.warning),
      SectionStatus.empty => isRequired
          ? (t('batch.section_required'), AppColors.danger)
          : (t('batch.section_optional'), AppColors.textMuted),
    };

    return Row(
      children: [
        // Step number circle
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: chipColor.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$stepNumber',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: chipColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Title
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Completion chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            chipLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ── EXISTING PRODUCT INFO CARD ────────────────────────────────────────────────
class _ExistingProductInfoCard extends StatelessWidget {
  final BatchEntryRow row;
  final Color accentColor;
  final Function(String) t;
  const _ExistingProductInfoCard({
    required this.row,
    required this.accentColor,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mevcut ürün etiketi
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  size: 13, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                t('batch.status_existing'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              const Spacer(),
              if (row.existingVariantSku != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'SKU: ${row.existingVariantSku}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Ürün adı
          Text(
            row.productName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          // Kategori / marka chip'leri
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (row.categoryName != null && row.categoryName!.isNotEmpty)
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: row.categoryName!,
                  color: accentColor,
                ),
              if (row.brandName != null && row.brandName!.isNotEmpty)
                _InfoChip(
                  icon: Icons.business_outlined,
                  label: row.brandName!,
                  color: AppColors.textSecondary,
                ),
              if (row.barcode.isNotEmpty)
                _InfoChip(
                  icon: Icons.qr_code_rounded,
                  label: row.barcode,
                  color: AppColors.textMuted,
                ),
            ],
          ),
          // Stok alanı bilgisi
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 12, color: AppColors.info),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t('batch.existing_stock_note'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── METRIC ────────────────────────────────────────────────────────────────────
class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

// ── CONFIRM DIALOG ────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final BatchEntryState state;
  final NumberFormat currency;
  final Function(String) t;
  const _ConfirmDialog({required this.state, required this.currency, required this.t});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.save_alt_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(t('batch.complete_save')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ConfirmRow(t('batch.total_products'),
              '${state.totalItems} ${t('batch.items')}'),
          _ConfirmRow(t('batch.new_products'), '${state.newItems} ${t('common.quantity').toLowerCase()}'),
          _ConfirmRow(
              t('batch.existing_products'), '${state.existingItems} ${t('batch.stock_qty')}'),
          const Divider(height: 16),
          _ConfirmRow(t('batch.total_cost'),
              currency.format(state.totalCost)),
          _ConfirmRow(
              t('batch.total_sale'), currency.format(state.totalSale),
              bold: true),
          if (state.supplierName != null)
            _ConfirmRow(t('batch.supplier'), state.supplierName!),
          if (state.locationName != null)
            _ConfirmRow(t('batch.warehouse'), state.locationName!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t('common.cancel')),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(t('common.save')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _ConfirmRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── RESULT SHEET ──────────────────────────────────────────────────────────────
class _ResultSheet extends StatelessWidget {
  final BatchSaveResult result;
  final NumberFormat currency;
  final Function(String) t;
  const _ResultSheet({required this.result, required this.currency, required this.t});

  @override
  Widget build(BuildContext context) {
    final hasErrors = result.errors > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (hasErrors ? AppColors.warning : AppColors.success)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasErrors
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              size: 36,
              color: hasErrors ? AppColors.warning : AppColors.success,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasErrors ? t('batch.partially_completed') : t('batch.saved_successfully'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  hasErrors ? AppColors.warning : AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ResultStat(t('batch.processed'), '${result.totalProcessed}',
                  AppColors.primary),
              _ResultStat(t('batch.new_product'), '${result.newCreated}',
                  AppColors.success),
              _ResultStat(t('batch.stock_updated'),
                  '${result.stockUpdated}', AppColors.info),
              if (result.errors > 0)
                _ResultStat(t('common.error'), '${result.errors}',
                    AppColors.danger),
            ],
          ),
          if (result.errorMessages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.errorMessages
                    .map((e) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 14,
                                  color: AppColors.danger),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(e,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.danger))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(t('common.close'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

// ── BATCH ATTRIBUTES SECTION ─────────────────────────────────────────────────

class _AttrDef {
  final String name;
  final IconData icon;
  final List<String> suggestions;
  const _AttrDef(this.name, this.icon, this.suggestions);
}

class _AttrTemplate {
  final String label;
  final IconData icon;
  final List<String> attrNames;
  const _AttrTemplate(this.label, this.icon, this.attrNames);
}

class _BatchAttributesSection extends StatefulWidget {
  final Map<String, String> attributes;
  final SectorConfig cfg;
  final void Function(Map<String, String>) onChanged;

  const _BatchAttributesSection({
    required this.attributes,
    required this.cfg,
    required this.onChanged,
  });

  @override
  State<_BatchAttributesSection> createState() =>
      _BatchAttributesSectionState();
}

class _BatchAttributesSectionState
    extends State<_BatchAttributesSection> {
  // ── Attribute catalogue ───────────────────────────────────────────────────
  static const Map<String, _AttrDef> _catalogue = {
    'Renk': _AttrDef('Renk', Icons.palette_rounded, [
      'Siyah', 'Beyaz', 'Kırmızı', 'Mavi', 'Yeşil',
      'Sarı', 'Gri', 'Mor', 'Turuncu', 'Kahverengi',
    ]),
    'Beden': _AttrDef('Beden', Icons.straighten_rounded,
        ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL']),
    'Numara': _AttrDef('Numara', Icons.straighten_rounded,
        ['35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45']),
    'Materyal': _AttrDef('Materyal', Icons.texture_rounded,
        ['Deri', 'Süet', 'Kumaş', 'Plastik', 'Metal', 'Kauçuk', 'Ahşap']),
    'Sezon': _AttrDef('Sezon', Icons.wb_sunny_rounded,
        ['İlkbahar/Yaz', 'Sonbahar/Kış', 'Tüm Sezonlar']),
    'RAM': _AttrDef('RAM', Icons.memory_rounded,
        ['2GB', '4GB', '6GB', '8GB', '12GB', '16GB', '32GB', '64GB']),
    'Depolama': _AttrDef('Depolama', Icons.storage_rounded,
        ['32GB', '64GB', '128GB', '256GB', '512GB', '1TB', '2TB']),
    'Garanti (ay)': _AttrDef('Garanti (ay)', Icons.verified_rounded,
        ['6', '12', '18', '24', '36', '60']),
    'Ekran': _AttrDef('Ekran', Icons.monitor_rounded,
        ['5.5"', '6.1"', '6.7"', '13"', '14"', '15.6"', '17"']),
    'İşlemci': _AttrDef('İşlemci', Icons.developer_board_rounded,
        ['i3', 'i5', 'i7', 'i9', 'M1', 'M2', 'Snapdragon', 'Exynos']),
    'Marka': _AttrDef('Marka', Icons.business_rounded, []),
    'Model': _AttrDef('Model', Icons.category_rounded, []),
    'Araç Grubu': _AttrDef('Araç Grubu', Icons.directions_car_rounded,
        ['Binek', 'SUV', 'Pickup', 'Kamyonet', 'Minibüs', 'Ticari']),
    'Motor': _AttrDef('Motor', Icons.engineering_rounded,
        ['1.0', '1.2', '1.4', '1.6', '2.0', '2.5', 'Dizel', 'Benzin', 'Hibrit']),
    'Boyut': _AttrDef('Boyut', Icons.straighten_rounded,
        ['XS', 'S', 'M', 'L', 'XL', '2XL']),
    'Ağırlık': _AttrDef('Ağırlık', Icons.scale_rounded,
        ['50g', '100g', '250g', '500g', '1kg', '2kg', '5kg', '10kg']),
  };

  // ── Sector preset templates ───────────────────────────────────────────────
  static const Map<SectorType, List<_AttrTemplate>> _templates = {
    SectorType.autoParts: [
      _AttrTemplate('Marka + Model', Icons.build_circle_rounded, ['Marka', 'Model']),
      _AttrTemplate('Araç Grubu', Icons.directions_car_rounded, ['Araç Grubu']),
      _AttrTemplate('Renk', Icons.palette_rounded, ['Renk']),
      _AttrTemplate('Motor', Icons.engineering_rounded, ['Motor']),
    ],
    SectorType.footwear: [
      _AttrTemplate('Renk + Numara', Icons.shopping_bag_rounded, ['Renk', 'Numara']),
      _AttrTemplate('Renk + Beden', Icons.checkroom_rounded, ['Renk', 'Beden']),
      _AttrTemplate('Materyal + Sezon', Icons.texture_rounded, ['Materyal', 'Sezon']),
    ],
    SectorType.technology: [
      _AttrTemplate('RAM + Depolama', Icons.devices_rounded, ['RAM', 'Depolama']),
      _AttrTemplate('Renk + RAM', Icons.memory_rounded, ['Renk', 'RAM']),
      _AttrTemplate('Ekran + İşlemci', Icons.monitor_rounded, ['Ekran', 'İşlemci']),
    ],
    SectorType.general: [
      _AttrTemplate('Renk + Beden', Icons.checkroom_rounded, ['Renk', 'Beden']),
      _AttrTemplate('Renk + Boyut', Icons.palette_rounded, ['Renk', 'Boyut']),
      _AttrTemplate('Materyal + Renk', Icons.texture_rounded, ['Materyal', 'Renk']),
    ],
  };

  static const _attrColors = [
    Color(0xFF5C6BC0),
    Color(0xFFEF5350),
    Color(0xFF26A69A),
    Color(0xFFFF7043),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
  ];

  // ── Icon / colour helpers ─────────────────────────────────────────────────
  final Map<String, IconData> _iconOverrides = {};
  final Map<String, TextEditingController> _controllers = {};

  Color get _accent => switch (widget.cfg.type) {
        SectorType.autoParts => AppColors.orange,
        SectorType.footwear => AppColors.pink,
        SectorType.technology => AppColors.info,
        SectorType.general => AppColors.primary,
      };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String name) => _controllers.putIfAbsent(
      name, () => TextEditingController(text: widget.attributes[name] ?? ''));

  IconData _iconFor(String name) =>
      _iconOverrides[name] ?? _catalogue[name]?.icon ?? Icons.label_rounded;

  Color _colorAt(int idx) => _attrColors[idx % _attrColors.length];

  // ── Mutations ─────────────────────────────────────────────────────────────
  void _applyTemplate(_AttrTemplate tpl) {
    final a = Map<String, String>.from(widget.attributes);
    for (final n in tpl.attrNames) {
      a.putIfAbsent(n, () => '');
    }
    widget.onChanged(a);
  }

  void _selectValue(String name, String val) {
    _ctrl(name).text = val;
    widget.onChanged(Map<String, String>.from(widget.attributes)..[name] = val);
  }

  void _setCustom(String name, String val) =>
      widget.onChanged(Map<String, String>.from(widget.attributes)..[name] = val);

  void _removeAttr(String name) {
    _controllers[name]?.dispose();
    _controllers.remove(name);
    _iconOverrides.remove(name);
    final a = Map<String, String>.from(widget.attributes)..remove(name);
    widget.onChanged(a);
  }

  void _addAttr(String name, IconData icon) {
    if (widget.attributes.containsKey(name)) return;
    _iconOverrides[name] = icon;
    widget.onChanged(Map<String, String>.from(widget.attributes)..[name] = '');
  }

  // ── Dialog: add new attribute ─────────────────────────────────────────────
  void _showAddAttrDialog(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    IconData selIcon = Icons.label_rounded;
    String? nameError;

    const iconOpts = [
      (Icons.palette_rounded, 'Renk'),
      (Icons.straighten_rounded, 'Beden'),
      (Icons.memory_rounded, 'RAM'),
      (Icons.storage_rounded, 'Depolama'),
      (Icons.directions_car_rounded, 'Araç'),
      (Icons.business_rounded, 'Marka'),
      (Icons.category_rounded, 'Model'),
      (Icons.verified_rounded, 'Garanti'),
      (Icons.texture_rounded, 'Materyal'),
      (Icons.scale_rounded, 'Ağırlık'),
      (Icons.engineering_rounded, 'Motor'),
      (Icons.label_rounded, 'Diğer'),
    ];

    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDs) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Yeni Özellik',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  onChanged: (_) => setDs(() => nameError = null),
                  decoration: InputDecoration(
                    labelText: 'Özellik Adı',
                    hintText: 'ör: Renk, Beden, Model',
                    errorText: nameError,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(selIcon,
                        size: 18, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('İkon Seç',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: iconOpts.map((pair) {
                    final isSel = selIcon == pair.$1;
                    return GestureDetector(
                      onTap: () =>
                          setDs(() => selIcon = pair.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary
                                  .withValues(alpha: 0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSel ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(pair.$1,
                                size: 15,
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.textMuted),
                            const SizedBox(width: 5),
                            Text(pair.$2,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSel
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: isSel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                )),
                            if (isSel) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                  Icons.check_circle_rounded,
                                  size: 11,
                                  color: AppColors.primary),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('İptal'),
            ),
            AppButton.primary(
              text: 'Ekle',
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDs(() => nameError = 'Özellik adı zorunludur');
                  return;
                }
                if (widget.attributes.containsKey(name)) {
                  setDs(() => nameError = '$name zaten eklenmiş');
                  return;
                }
                Navigator.pop(dCtx);
                setState(() => _addAttr(name, selIcon));
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final templates =
        _templates[widget.cfg.type] ?? _templates[SectorType.general]!;
    final attrs = widget.attributes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header bar ───────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune_rounded, size: 16, color: accent),
                ),
                const SizedBox(width: 10),
                Text('Varyant Özellikleri',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent)),
                if (attrs.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${attrs.length} özellik',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                  ),
                ],
                const Spacer(),
                Material(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _showAddAttrDialog(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.success
                                .withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Yeni',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Quick templates ─────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: templates.map((tpl) {
                    final isActive = tpl.attrNames
                        .every((n) => attrs.containsKey(n));
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _applyTemplate(tpl)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? accent.withValues(alpha: 0.1)
                              : const Color(0xFFF4F5F8),
                          border: Border.all(
                            color: isActive
                                ? accent
                                : AppColors.border,
                            width: isActive ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tpl.icon,
                                size: 13,
                                color: isActive
                                    ? accent
                                    : AppColors.textMuted),
                            const SizedBox(width: 5),
                            Text(tpl.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isActive
                                      ? accent
                                      : AppColors.textSecondary,
                                )),
                            if (isActive) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.check_circle_rounded,
                                  size: 12, color: accent),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // ── Empty hint ──────────────────────────────────────────
                if (attrs.isEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 15,
                          color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Şablon seç veya "Yeni" ile özellik ekle.\n'
                          'Her özellik bu varyantı diğerlerinden ayırt eder.',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.5),
                        ),
                      ),
                    ]),
                  ),
                ],

                // ── Attribute cards ─────────────────────────────────────
                if (attrs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...attrs.entries.toList().asMap().entries.map(
                      (e) => _buildAttrCard(
                          context, e.key, e.value.key, e.value.value, accent)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttrCard(BuildContext context, int idx, String name,
      String curVal, Color accent) {
    final def = _catalogue[name];
    final color = _colorAt(idx);
    final icon = _iconFor(name);
    final suggestions = def?.suggestions ?? [];
    final ctrl = _ctrl(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(name,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(width: 6),
              if (curVal.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(curVal,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Seçilmedi',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning)),
                ),
              const Spacer(),
              Material(
                color: AppColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => setState(() => _removeAttr(name)),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.close_rounded,
                        size: 15, color: AppColors.danger),
                  ),
                ),
              ),
            ]),
          ),

          // Suggestions + text field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (suggestions.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: suggestions.map((val) {
                      final isSel = curVal == val;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectValue(name, val)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSel
                                ? color
                                : color.withValues(alpha: 0.07),
                            border: Border.all(
                              color: isSel
                                  ? color
                                  : color.withValues(alpha: 0.25),
                              width: isSel ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(val,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSel ? Colors.white : color,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const Row(children: [
                    Expanded(child: Divider(height: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('veya gir',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted)),
                    ),
                    Expanded(child: Divider(height: 1)),
                  ]),
                  const SizedBox(height: 8),
                ],
                // Text input
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: ctrl,
                    onChanged: (v) => _setCustom(name, v),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _hintFor(name),
                      hintStyle: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      filled: true,
                      fillColor: color.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: color.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: color.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: color, width: 1.5),
                      ),
                      prefixIcon: Icon(icon,
                          size: 14,
                          color: color.withValues(alpha: 0.5)),
                      prefixIconConstraints: const BoxConstraints(
                          minWidth: 34, minHeight: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hintFor(String name) {
    final lc = name.toLowerCase();
    if (lc.contains('renk')) return 'ör: Kırmızı, #FF5733';
    if (lc.contains('numara')) return 'ör: 40, 41, 42';
    if (lc.contains('beden') || lc.contains('boyut')) return 'ör: S, M, L, XL';
    if (lc.contains('ram')) return 'ör: 8GB, 16GB';
    if (lc.contains('depolama')) return 'ör: 256GB, 1TB';
    if (lc.contains('garanti')) return 'ör: 12 (ay)';
    if (lc.contains('motor')) return 'ör: 1.6 Dizel';
    if (lc.contains('araç')) return 'ör: Binek, SUV';
    if (lc.contains('materyal')) return 'ör: Deri, Kumaş';
    if (lc.contains('sezon')) return 'ör: Sonbahar/Kış';
    if (lc.contains('ekran')) return 'ör: 6.1", 14"';
    if (lc.contains('işlemci')) return 'ör: i7, Snapdragon';
    return 'Değer girin…';
  }
}


// ── SECTOR EXTRA FIELDS ───────────────────────────────────────────────────────
class _SectorExtraFields extends StatefulWidget {
  final SectorConfig cfg;
  final BatchEntryRow row;
  final Function({
    String? shelfLocation,
    String? oemNumber,
    String? brandName,
  }) onUpdate;
  final Function(String) t;

  const _SectorExtraFields({
    required this.cfg,
    required this.row,
    required this.onUpdate,
    required this.t,
  });

  @override
  State<_SectorExtraFields> createState() => _SectorExtraFieldsState();
}

class _SectorExtraFieldsState extends State<_SectorExtraFields> {
  late final TextEditingController _sizeCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _warrantyCtrl;

  @override
  void initState() {
    super.initState();
    _sizeCtrl = TextEditingController();
    _colorCtrl = TextEditingController();
    _warrantyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    _warrantyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[];

    if (widget.cfg.fields.showVariantSize) {
      fields.add(_Field(
        label: widget.cfg.labels.variantField,
        ctrl: _sizeCtrl,
        onChanged: (_) {},
        hint: '36 / 37 / 38...',
      ));
    }

    if (widget.cfg.fields.showVariantColor) {
      fields.add(_Field(
        label: widget.t('product.color'),
        ctrl: _colorCtrl,
        onChanged: (_) {},
        hint: widget.t('batch.hint_colors'),
      ));
    }

    if (widget.cfg.fields.showWarranty) {
      fields.add(_Field(
        label: widget.t('product.warranty_period') +
            (widget.cfg.fields.warrantyRequired ? ' *' : ''),
        ctrl: _warrantyCtrl,
        onChanged: (_) {},
        hint: widget.t('batch.hint_warranty'),
      ));
    }

    if (fields.isEmpty) return const SizedBox.shrink();

    // Her satırda max 2 alan
    final rows = <Widget>[];
    for (int i = 0; i < fields.length; i += 2) {
      final rowFields = fields.sublist(i, i + 2 > fields.length ? fields.length : i + 2);
      rows.add(_FormRow(children: rowFields));
      if (i + 2 < fields.length) rows.add(const SizedBox(height: 10));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.tune_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '${widget.cfg.type.displayName} ${widget.t('batch.fields')}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }
}

// ── FOOTWEAR VARIANT TABLE ────────────────────────────────────────────────────
class _FootwearVariantTable extends StatefulWidget {
  final List<BatchVariantRow> variantRows;
  final double defaultPurchasePrice;
  final double defaultSalePrice;
  final String sizeLabel;
  final Color accentColor;
  final void Function(List<BatchVariantRow>) onChanged;

  const _FootwearVariantTable({
    required this.variantRows,
    required this.defaultPurchasePrice,
    required this.defaultSalePrice,
    required this.sizeLabel,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<_FootwearVariantTable> createState() => _FootwearVariantTableState();
}

class _FootwearVariantTableState extends State<_FootwearVariantTable> {
  // key: "${rowId}_field"
  final Map<String, TextEditingController> _ctrls = {};

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String rowId, String field, String initial) =>
      _ctrls.putIfAbsent('${rowId}_$field', () => TextEditingController(text: initial));

  void _addRow() {
    final newRow = BatchVariantRow(
      purchasePrice: widget.defaultPurchasePrice > 0 ? widget.defaultPurchasePrice : null,
      salePrice: widget.defaultSalePrice > 0 ? widget.defaultSalePrice : null,
    );
    widget.onChanged([...widget.variantRows, newRow]);
  }

  void _removeRow(String rowId) {
    // Dispose controllers for this row
    final toRemove = _ctrls.keys.where((k) => k.startsWith('${rowId}_')).toList();
    for (final k in toRemove) {
      _ctrls[k]!.dispose();
      _ctrls.remove(k);
    }
    widget.onChanged(widget.variantRows.where((r) => r.id != rowId).toList());
  }

  void _updateRow(BatchVariantRow updated) {
    final rows = widget.variantRows.map((r) => r.id == updated.id ? updated : r).toList();
    widget.onChanged(rows);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor = widget.accentColor.withValues(alpha: 0.25);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tablo başlığı ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                _HeaderCell(widget.sizeLabel, flex: 2),
                _HeaderCell('Renk', flex: 2),
                _HeaderCell('Adet', flex: 1),
                _HeaderCell('Barkod', flex: 2),
                _HeaderCell('Alış ₺', flex: 2),
                _HeaderCell('Satış ₺', flex: 2),
                const SizedBox(width: 28), // delete button placeholder
              ],
            ),
          ),
          // ── Satırlar ───────────────────────────────────────────────────────
          if (widget.variantRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Henüz varyant eklenmedi',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...widget.variantRows.asMap().entries.map((entry) {
              final idx = entry.key;
              final vr = entry.value;
              final rowBg = idx.isOdd
                  ? widget.accentColor.withValues(alpha: 0.03)
                  : Colors.transparent;
              return _VariantTableRow(
                key: ValueKey(vr.id),
                variantRow: vr,
                rowBg: rowBg,
                sizeCtrl: _ctrl(vr.id, 'size', vr.size),
                colorCtrl: _ctrl(vr.id, 'color', vr.color),
                barcodeCtrl: _ctrl(vr.id, 'barcode', vr.barcode),
                qtyCtrl: _ctrl(vr.id, 'qty', vr.quantity > 0 ? '${vr.quantity}' : '1'),
                purchaseCtrl: _ctrl(vr.id, 'purchase',
                    vr.purchasePrice != null && vr.purchasePrice! > 0
                        ? vr.purchasePrice!.toString()
                        : ''),
                saleCtrl: _ctrl(vr.id, 'sale',
                    vr.salePrice != null && vr.salePrice! > 0
                        ? vr.salePrice!.toString()
                        : ''),
                onUpdate: _updateRow,
                onDelete: () => _removeRow(vr.id),
              );
            }),
          // ── Ekle butonu ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _addRow,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 15, color: widget.accentColor),
                      const SizedBox(width: 5),
                      Text(
                        'Varyant Ekle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  const _HeaderCell(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _VariantTableRow extends StatelessWidget {
  final BatchVariantRow variantRow;
  final Color rowBg;
  final TextEditingController sizeCtrl;
  final TextEditingController colorCtrl;
  final TextEditingController barcodeCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController purchaseCtrl;
  final TextEditingController saleCtrl;
  final void Function(BatchVariantRow) onUpdate;
  final VoidCallback onDelete;

  const _VariantTableRow({
    super.key,
    required this.variantRow,
    required this.rowBg,
    required this.sizeCtrl,
    required this.colorCtrl,
    required this.barcodeCtrl,
    required this.qtyCtrl,
    required this.purchaseCtrl,
    required this.saleCtrl,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _VCell(sizeCtrl, flex: 2, hint: '41', onChanged: (v) => onUpdate(variantRow.copyWith(size: v))),
          _VCell(colorCtrl, flex: 2, hint: 'Kırmızı', onChanged: (v) => onUpdate(variantRow.copyWith(color: v))),
          _VCell(qtyCtrl, flex: 1, hint: '1', isNum: true,
              onChanged: (v) => onUpdate(variantRow.copyWith(quantity: int.tryParse(v) ?? 1))),
          _VCell(barcodeCtrl, flex: 2, hint: 'Barkod', onChanged: (v) => onUpdate(variantRow.copyWith(barcode: v))),
          _VCell(purchaseCtrl, flex: 2, hint: '0.00', isNum: true,
              onChanged: (v) => onUpdate(variantRow.copyWith(
                  purchasePrice: double.tryParse(v.replaceAll(',', '.'))))),
          _VCell(saleCtrl, flex: 2, hint: '0.00', isNum: true,
              onChanged: (v) => onUpdate(variantRow.copyWith(
                  salePrice: double.tryParse(v.replaceAll(',', '.'))))),
          SizedBox(
            width: 28,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VCell extends StatelessWidget {
  final TextEditingController ctrl;
  final int flex;
  final String hint;
  final bool isNum;
  final void Function(String) onChanged;

  const _VCell(this.ctrl, {
    required this.flex,
    required this.hint,
    required this.onChanged,
    this.isNum = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: TextField(
          controller: ctrl,
          onChanged: onChanged,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          inputFormatters: isNum
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
              : null,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

// ── TAB DATA ──────────────────────────────────────────────────────────────────
class _Tab {
  final String label;
  final RowStatus? status;
  const _Tab(this.label, this.status);
}