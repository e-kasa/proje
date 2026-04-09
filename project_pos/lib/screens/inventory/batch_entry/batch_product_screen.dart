import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/sector_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/sector_provider.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'providers/batch_entry_provider.dart';
import 'models/batch_entry_models.dart';
import 'widgets/batch_header_form.dart';

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
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(
        children: [
          _buildTopBar(state, isDesktop, t),
          const BatchHeaderForm(),
          _buildSearchBar(cfg, t),
          _buildTabBar(state, t),
          Expanded(child: _buildBody(state, cfg, isDesktop, t)),
          _buildSummaryBar(state, t),
        ],
      ),
    );
  }

  // ── TOP BAR ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BatchEntryState state, bool isDesktop, Function(String) t) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('batch.bulk_product_entry'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (state.supplierName != null)
                      Text(
                        state.supplierName!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Stats chips
              if (state.rows.isNotEmpty) ...[
                _TopChip(
                    label: '${state.totalItems}',
                    icon: Icons.list_alt_rounded),
                const SizedBox(width: 8),
                _TopChip(
                    label: '${state.newItems} ${t('batch.new').toLowerCase()}',
                    icon: Icons.add_circle_outline),
              ],
              const SizedBox(width: 8),
              // Clear button
              if (state.rows.isNotEmpty)
                IconButton(
                  onPressed: _confirmClear,
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.white),
                  tooltip: t('batch.clear_list'),
                ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _barcodeController,
                focusNode: _barcodeFocus,
                onSubmitted: (_) => _addByBarcode(),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: cfg.barcodeHint,
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.primary, size: 22),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Search button
          _ActionBtn(
            icon: Icons.search_rounded,
            color: AppColors.primary,
            onTap: _addByBarcode,
            tooltip: t('batch.search_and_add'),
          ),
          const SizedBox(width: 8),
          // Manual add button
          _ActionBtn(
            icon: Icons.add_rounded,
            color: AppColors.success,
            onTap: () =>
                ref.read(batchEntryProvider.notifier).addManualRow(),
            tooltip: t('batch.add_manual_row'),
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
  Widget _buildBody(BatchEntryState state, SectorConfig cfg, bool isDesktop, Function(String) t) {
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((tab) {
        final rows = _filteredRows(state.rows, tab.status);
        if (rows.isEmpty) return _buildEmptyState(tab.status, t);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          itemCount: rows.length,
          itemBuilder: (_, i) =>
              _BatchRowCard(row: rows[i], currency: _currency, cfg: cfg),
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
    final totalQty =
        state.rows.fold(0, (s, r) => s + r.quantity);
    final margin = state.totalSale > 0
        ? (state.totalProfit / state.totalSale * 100)
        : 0.0;

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
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
                                t('common.save'),
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
        ),
      ),
    );
  }
}

// ── BATCH ROW CARD ────────────────────────────────────────────────────────────
class _BatchRowCard extends ConsumerStatefulWidget {
  final BatchEntryRow row;
  final NumberFormat currency;
  final SectorConfig cfg;
  const _BatchRowCard({required this.row, required this.currency, required this.cfg});

  @override
  ConsumerState<_BatchRowCard> createState() => _BatchRowCardState();
}

class _BatchRowCardState extends ConsumerState<_BatchRowCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _oemCtrl;
  late final TextEditingController _purchaseCtrl;
  late final TextEditingController _saleCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _shelfCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    _nameCtrl = TextEditingController(text: r.productName);
    _barcodeCtrl = TextEditingController(text: r.barcode);
    _oemCtrl = TextEditingController(text: r.oemNumber ?? '');
    _purchaseCtrl = TextEditingController(
        text: r.purchasePrice > 0 ? r.purchasePrice.toString() : '');
    _saleCtrl = TextEditingController(
        text: r.salePrice > 0 ? r.salePrice.toString() : '');
    _categoryCtrl = TextEditingController(text: r.categoryName ?? '');
    _brandCtrl = TextEditingController(text: r.brandName ?? '');
    _shelfCtrl = TextEditingController(text: r.shelfLocation ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _barcodeCtrl, _oemCtrl, _purchaseCtrl,
      _saleCtrl, _categoryCtrl, _brandCtrl, _shelfCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _update({
    String? productName,
    String? barcode,
    String? oemNumber,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    String? categoryName,
    String? brandName,
    String? shelfLocation,
    bool? isExpanded,
  }) {
    ref.read(batchEntryProvider.notifier).updateRow(
          widget.row.id,
          productName: productName,
          barcode: barcode,
          oemNumber: oemNumber,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          quantity: quantity,
          categoryName: categoryName,
          brandName: brandName,
          shelfLocation: shelfLocation,
          isExpanded: isExpanded,
        );
  }

  Color get _statusColor => switch (widget.row.status) {
        RowStatus.newProduct => AppColors.info,
        RowStatus.existing || RowStatus.matched => AppColors.success,
        RowStatus.error => AppColors.danger,
        RowStatus.saving => AppColors.warning,
        RowStatus.saved => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final row = widget.row;
    final margin = row.salePrice > 0
        ? ((row.salePrice - row.purchasePrice) / row.salePrice * 100)
        : 0.0;
    final isExpanded = row.isExpanded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Collapsed header ──────────────────────────────────────────────
          InkWell(
            onTap: () => _update(isExpanded: !isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StatusBadge(status: row.status, t: t),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                row.productName.isNotEmpty
                                    ? row.productName
                                    : row.barcode.isNotEmpty
                                        ? row.barcode
                                        : t('batch.enter_product_name'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (row.barcode.isNotEmpty) ...[
                              Icon(Icons.qr_code_rounded,
                                  size: 12,
                                  color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(row.barcode,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                              const SizedBox(width: 10),
                            ],
                            if (row.categoryName != null &&
                                row.categoryName!.isNotEmpty) ...[
                              Icon(Icons.category_outlined,
                                  size: 12,
                                  color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(row.categoryName!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted)),
                            ],
                          ],
                        ),
                        if (row.errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 12, color: AppColors.danger),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  row.errorMessage!,
                                  style: const TextStyle(
                                      fontSize: 11,
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
                  const SizedBox(width: 8),
                  // Right side: prices + quantity control
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Prices row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (row.purchasePrice > 0)
                            Text(
                              widget.currency.format(row.purchasePrice),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.none),
                            ),
                          if (row.purchasePrice > 0 && row.salePrice > 0)
                            const Text(' → ',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                          if (row.salePrice > 0)
                            Text(
                              widget.currency.format(row.salePrice),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Margin badge
                      if (margin > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (margin >= 20
                                    ? AppColors.success
                                    : AppColors.warning)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${t('batch.profit')} %${margin.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: margin >= 20
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      // Quantity control
                      _QuantityControl(
                        quantity: row.quantity,
                        onChanged: (q) => _update(quantity: q),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded form ─────────────────────────────────────────────────
          if (isExpanded) ...[
            Divider(
                height: 1,
                color: _statusColor.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Ürün adı + Barkod
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
                  // Row 2: Alış / Satış
                  _FormRow(children: [
                    _Field(
                      label: '${t('batch.purchase_price')} ₺',
                      ctrl: _purchaseCtrl,
                      onChanged: (v) =>
                          _update(purchasePrice: double.tryParse(v) ?? 0),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      hint: '0.00',
                    ),
                    _Field(
                      label: '${widget.cfg.labels.salePriceLabel} ₺ *',
                      ctrl: _saleCtrl,
                      onChanged: (v) =>
                          _update(salePrice: double.tryParse(v) ?? 0),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      hint: '0.00',
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Row 3: OEM (sektöre göre) + Raf
                  _FormRow(children: [
                    if (widget.cfg.fields.showOem)
                      _Field(
                        label: widget.cfg.labels.oemField +
                            (widget.cfg.fields.oemRequired ? ' *' : ''),
                        ctrl: _oemCtrl,
                        onChanged: (v) => _update(oemNumber: v),
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
                  // Row 4: Kategori + Marka
                  _FormRow(children: [
                    _Field(
                      label: widget.cfg.labels.categoryName,
                      ctrl: _categoryCtrl,
                      onChanged: (v) => _update(categoryName: v),
                      hint: widget.cfg.type == SectorType.autoParts
                          ? t('batch.hint_auto_category')
                          : widget.cfg.type == SectorType.footwear
                              ? t('batch.hint_footwear_category')
                              : t('batch.hint_category'),
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
                  // Row 5: Sektöre özel ekstra alanlar
                  if (widget.cfg.fields.showVariantSize ||
                      widget.cfg.fields.showVariantColor ||
                      widget.cfg.fields.showWarranty) ...[
                    const SizedBox(height: 10),
                    _SectorExtraFields(cfg: widget.cfg, row: widget.row, onUpdate: _update, t: t),
                  ],
                  const SizedBox(height: 14),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profit summary
                      if (row.salePrice > 0 && row.purchasePrice > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up_rounded,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(
                                '${t('batch.unit_profit')}: ${widget.currency.format(row.salePrice - row.purchasePrice)}  •  ${t('common.total')}: ${widget.currency.format(row.lineProfit)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      // Remove button
                      TextButton.icon(
                        onPressed: () => ref
                            .read(batchEntryProvider.notifier)
                            .removeRow(row.id),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.danger),
                        label: Text(t('common.remove'),
                            style: const TextStyle(color: AppColors.danger)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
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

// ── STATUS BADGE ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final RowStatus status;
  final Function(String) t;
  const _StatusBadge({required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      RowStatus.newProduct => (t('batch.status_new'), AppColors.info, Icons.add_circle_outline),
      RowStatus.existing => (t('batch.status_existing'), AppColors.success, Icons.check_circle_outline),
      RowStatus.matched => (t('batch.status_matched'), AppColors.primary, Icons.link_rounded),
      RowStatus.error => (t('batch.status_error'), AppColors.danger, Icons.error_outline),
      RowStatus.saving => ('...', AppColors.warning, Icons.hourglass_top_rounded),
      RowStatus.saved => ('✓ OK', AppColors.success, Icons.check_circle),
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
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SMALL WIDGETS ─────────────────────────────────────────────────────────────
class _TopChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TopChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.onTap,
      required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

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
          if (state.warehouseName != null)
            _ConfirmRow(t('batch.warehouse'), state.warehouseName!),
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

// ── TAB DATA ──────────────────────────────────────────────────────────────────
class _Tab {
  final String label;
  final RowStatus? status;
  const _Tab(this.label, this.status);
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               