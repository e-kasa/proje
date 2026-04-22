import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/config/sector_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../../providers/sector_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/features/inventory/screens/batch_entry/widgets/document_analyze_result_sheet.dart';
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

  // ── Kaynak seçim tipi ────────────────────────────────────────────────────
  static const _srcPdf     = 'pdf';
  static const _srcCamera  = 'camera';
  static const _srcGallery = 'gallery';

  Future<void> _uploadDocument() async {
    final t = i18nOf(ref);

    // 1. Kaynak dialog
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t('batch.select_source')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _srcPdf),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger),
              const SizedBox(width: 12),
              Text(t('batch.upload_pdf')),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _srcCamera),
            child: Row(children: [
              const Icon(Icons.camera_alt_rounded, color: AppColors.info),
              const SizedBox(width: 12),
              Text(t('batch.take_photo')),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _srcGallery),
            child: Row(children: [
              const Icon(Icons.photo_library_rounded, color: AppColors.success),
              const SizedBox(width: 12),
              Text(t('batch.choose_from_gallery')),
            ]),
          ),
        ],
      ),
    );
    if (choice == null) return;

    // 2. Dosya → bytes + filename (web ve native için ortak)
    Uint8List? fileBytes;
    String? fileName;

    if (choice == _srcPdf) {
      // withData: true → web'de path null olduğu için bytes gerekli
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null) return;
      final pf = result.files.single;
      if (pf.bytes != null) {
        fileBytes = pf.bytes;
        fileName = pf.name;
      } else if (pf.path != null) {
        // native fallback
        fileBytes = await File(pf.path!).readAsBytes();
        fileName = pf.name;
      }
    } else if (choice == _srcCamera) {
      // Kamera izni
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        AppToast.error(context, t('batch.camera_permission_denied'));
        return;
      }
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (picked == null) return;
      fileBytes = await picked.readAsBytes();
      fileName = picked.name;
    } else {
      // Galeri
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      fileBytes = await picked.readAsBytes();
      fileName = picked.name;
    }

    if (fileBytes == null || fileName == null) return;

    // 10 MB ön kontrol
    if (fileBytes!.length > 10 * 1024 * 1024) {
      if (mounted) AppToast.error(context, t('batch.file_too_large'));
      return;
    }

    if (!mounted) return;

    // 3. Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(t('batch.document_uploading')),
          ],
        ),
      ),
    );

    try {
      final service = ref.read(documentAnalyzeServiceProvider);
      final analyzeResult =
          await service.analyzeDocumentFromBytes(fileBytes, fileName);

      // Root navigator'dan pop et — showDialog useRootNavigator:true ile açar
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;

      if (analyzeResult.items.isEmpty) {
        AppToast.error(context, t('batch.document_no_items'));
        return;
      }

      // 4. Sonuç sheet'ini göster
      await DocumentAnalyzeResultSheet.show(
        context: context,
        result: analyzeResult,
        onImport: (selected) {
          ref.read(batchEntryProvider.notifier).addFromDocumentItems(selected);
          AppToast.success(
            context,
            '${selected.length} ${t('batch.document_items_imported')}',
          );
          // Satış fiyatı alış fiyatına eşitlendi — kullanıcıyı uyar
          if (selected.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) {
                AppToast.warning(context, t('batch.sale_price_check_required'));
              }
            });
          }
        },
      );
    } catch (e) {
      // Root navigator'dan pop et
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;

      String key = 'batch.document_analyze_error';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          key = 'batch.document_timeout_error';
        } else if (e.response?.statusCode == 400) {
          final msg = (e.response?.data?['message'] as String?) ?? '';
          key = (msg.contains('10 MB') || msg.contains('boyut'))
              ? 'batch.file_too_large'
              : 'batch.document_parse_error';
        } else if (e.response?.statusCode == 500) {
          key = 'batch.document_parse_error';
        }
      }
      AppToast.error(context, t(key));
    }
  }

  Future<void> _addByBarcode() async {
    final input = _barcodeController.text.trim();
    if (input.isEmpty) return;
    final msg =
        await ref.read(batchEntryProvider.notifier).addByBarcode(input);
    _barcodeController.clear();
    _barcodeFocus.requestFocus();
    if (msg != null && mounted) {
      final t = i18nOf(ref);
      AppToast.info(context, _formatBarcodeMsg(msg, t));
    }
  }

  String _formatBarcodeMsg(String msg, String Function(String) t) {
    final parts = msg.split('|');
    return switch (parts[0]) {
      'batch.barcode_qty_increased' =>
        '${parts.elementAtOrNull(1) ?? ''} — ${t("batch.barcode_qty_increased")} (${parts.elementAtOrNull(2) ?? ''})',
      'batch.barcode_added' =>
        '${parts.elementAtOrNull(1) ?? ''} ${t("batch.barcode_added")}',
      _ => t(parts[0]),
    };
  }

  Future<void> _submit(BatchEntryState state) async {
    // validateAll() "batch.key|rowNum" formatında döner
    final err = ref.read(batchEntryProvider.notifier).validateAll();
    if (err != null) {
      final t = i18nOf(ref);
      if (err.contains('|')) {
        final parts = err.split('|');
        _showError('${parts[1]}. ${t(parts[0])}');
      } else {
        _showError(t(err));
      }
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
      // Exception: prefix'i soy
      final raw = e.toString().replaceFirst('Exception: ', '');
      if (mounted) _showError(raw);
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
          _BulkActionsPanel(t: t),
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
          const SizedBox(width: 8),
          Tooltip(
            message: t('batch.upload_or_photo'),
            child: Material(
              color: AppColors.info,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _uploadDocument,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  child: const Icon(Icons.add_a_photo_rounded,
                      color: Colors.white, size: 22),
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
              // Eksik teslimat uyarısı
              if (state.hasAnyShortage) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 13, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      '${state.shortageItems} ${t('batch.shortage_summary')}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ]),
                ),
              ],
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
    double? discountRate,
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
                                    // Varyant chip: footwear → N varyant,
                                    // diğer yeni ürünler → 1 varyant (otomatik)
                                    if (widget.cfg.fields.showVariantSize &&
                                        row.variantRows.isNotEmpty)
                                      _MetaChip(
                                        icon: Icons.layers_rounded,
                                        label: '${row.variantRows.length} ${t('batch.variants')}',
                                        color: accentColor,
                                      )
                                    else if (row.isNew)
                                      _MetaChip(
                                        icon: Icons.inventory_2_rounded,
                                        label: '1 ${t('batch.variant')}',
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
                                    _completion.missingFields
                                        .map((f) => i18nOf(ref)(f))
                                        .join(', '),
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
                                '${t('batch.profit_percent')} ${margin.toStringAsFixed(0)}',
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
                        if (row.variantRows.isNotEmpty)
                          _VariantQtyBadge(row.effectiveQuantity)
                        else
                          _QuantityControl(
                            quantity: row.quantity,
                            onChanged: (q) => _update(quantity: q),
                          ),
                        // Eksik teslimat rozeti
                        if (row.isExisting && row.hasShortage) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.warning, width: 0.5),
                            ),
                            child: Text(
                              '${row.shortageQty} ${t('batch.shortage_badge')}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
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
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _invoiceQtyCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _shelfCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _discountCtrl;
  /// Toplam satır fiyatı — variant grup durumunda kullanıcı toplam girip
  /// variantlara orantılı birim fiyat dağıtabilsin.
  late final TextEditingController _totalPurchaseCtrl;
  late final TextEditingController _totalSaleCtrl;

  @override
  void initState() {
    super.initState();
    final r = ref.read(batchEntryProvider).rows
        .firstWhere((r) => r.id == widget.rowId, orElse: () => BatchEntryRow());
    _nameCtrl = TextEditingController(text: r.productName);
    _barcodeCtrl = TextEditingController(text: r.barcode);
    _oemCtrl = TextEditingController(text: r.oemNumber ?? '');
    _discountCtrl = TextEditingController(
        text: r.discountRate > 0 ? r.discountRate.toString() : '');
    _purchaseCtrl = TextEditingController(
        text: r.purchasePrice > 0 ? r.purchasePrice.toString() : '');
    _saleCtrl = TextEditingController(
        text: r.salePrice > 0 ? r.salePrice.toString() : '');
    _quantityCtrl = TextEditingController(text: r.quantity.toString());
    _invoiceQtyCtrl = TextEditingController(
        text: r.invoiceQuantity?.toString() ?? r.quantity.toString());
    _brandCtrl = TextEditingController(text: r.brandName ?? '');
    _shelfCtrl = TextEditingController(text: r.shelfLocation ?? '');
    _descCtrl = TextEditingController(text: r.description ?? '');
    _minStockCtrl = TextEditingController(text: r.minStockLevel.toString());
    // Toplam satır fiyatı — başlangıçta lineCost/lineTotal'dan hesapla
    _totalPurchaseCtrl = TextEditingController(
        text: r.lineCost > 0 ? r.lineCost.toStringAsFixed(2) : '');
    _totalSaleCtrl = TextEditingController(
        text: r.lineTotal > 0 ? r.lineTotal.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _barcodeCtrl, _oemCtrl, _purchaseCtrl,
      _saleCtrl, _quantityCtrl, _invoiceQtyCtrl, _brandCtrl, _shelfCtrl,
      _descCtrl, _minStockCtrl, _discountCtrl,
      _totalPurchaseCtrl, _totalSaleCtrl,
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
    List<Map<String, String>>? crossRefList,
    double? purchasePrice,
    double? salePrice,
    int? quantity,
    int? invoiceQuantity,
    bool clearInvoiceQuantity = false,
    String? categoryId,
    String? categoryName,
    String? brandId,
    String? brandName,
    String? unitId,
    String? shelfLocation,
    int? minStockLevel,
    double? vatRate,
    double? discountRate,
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
          crossRefList: crossRefList,
          purchasePrice: purchasePrice,
          salePrice: salePrice,
          quantity: quantity,
          invoiceQuantity: invoiceQuantity,
          clearInvoiceQuantity: clearInvoiceQuantity,
          categoryId: categoryId,
          categoryName: categoryName,
          brandId: brandId,
          brandName: brandName,
          unitId: unitId,
          shelfLocation: shelfLocation,
          minStockLevel: minStockLevel,
          vatRate: vatRate,
          discountRate: discountRate,
          vatIncluded: vatIncluded,
          description: description,
          attributes: attributes,
          variantRows: variantRows,
        );
  }

  /// Kart alış fiyatını TÜM variant satırlarına uygular (üzerine yazar).
  void _applyPurchaseToAllVariants(BatchEntryRow row) {
    final val = double.tryParse(_purchaseCtrl.text.replaceAll(',', '.')) ?? 0;
    if (val <= 0) return;
    _update(
      purchasePrice: val,
      variantRows: row.variantRows.map((vr) => vr.copyWith(purchasePrice: val)).toList(),
    );
  }

  /// Kart satış fiyatını TÜM variant satırlarına uygular (üzerine yazar).
  void _applySaleToAllVariants(BatchEntryRow row) {
    final val = double.tryParse(_saleCtrl.text.replaceAll(',', '.')) ?? 0;
    if (val <= 0) return;
    _update(
      salePrice: val,
      variantRows: row.variantRows.map((vr) => vr.copyWith(salePrice: val)).toList(),
    );
  }

  /// Toplam satır fiyatını variant adet oranına göre birim fiyatlara böl.
  /// Senaryoda: 5 beden Tshirt × toplam 500 TL → her variant 100 TL birim fiyat.
  /// [which] 'purchase' | 'sale' | 'both' — hangi alan güncellensin.
  void _distributeTotalToVariants(BatchEntryRow row, double totalPrice, String which) {
    if (totalPrice <= 0 || row.variantRows.isEmpty) return;
    final totalQty = row.variantRows.fold<int>(0, (s, v) => s + v.quantity);
    if (totalQty <= 0) return;
    final splitUnitPrice = totalPrice / totalQty;
    final updated = row.variantRows.map((vr) {
      return vr.copyWith(
        purchasePrice: (which == 'purchase' || which == 'both') ? splitUnitPrice : null,
        salePrice:     (which == 'sale'     || which == 'both') ? splitUnitPrice : null,
      );
    }).toList();
    _update(
      purchasePrice: (which == 'purchase' || which == 'both') ? splitUnitPrice : null,
      salePrice:     (which == 'sale'     || which == 'both') ? splitUnitPrice : null,
      variantRows: updated,
    );
    // Ctrl'leri de senkronize et ki field içinde görünüm tutarlı olsun
    if (which == 'purchase' || which == 'both') {
      _purchaseCtrl.text = splitUnitPrice.toStringAsFixed(2);
    }
    if (which == 'sale' || which == 'both') {
      _saleCtrl.text = splitUnitPrice.toStringAsFixed(2);
    }
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

  void _syncExternalChanges(BatchEntryRow row) {
    // applyBrandToAll / applyCategoryToAll gibi toplu işlemlerden sonra
    // TextEditingController'ları senkronize et.
    // Fiyat alanlarına dokunulmaz — kullanıcı yazarken cursor bozulur.
    final brand = row.brandName ?? '';
    if (_brandCtrl.text != brand) _brandCtrl.text = brand;
  }

  @override
  Widget build(BuildContext context) {
    final row = ref.watch(batchEntryProvider.select(
      (s) => s.rows.firstWhere((r) => r.id == widget.rowId,
          orElse: () => BatchEntryRow()),
    ));

    // Satır silindiyse dialog'u kapat
    if (row.id != widget.rowId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      });
      return const SizedBox.shrink();
    }

    // Toplu işlemlerden gelen dışsal state güncellemelerini controller'lara yansıt.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExternalChanges(row));

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
                      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
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
                              _BrandAutocomplete(
                                label: t('product.brand') +
                                    (widget.cfg.fields.brandRequired ? ' *' : ''),
                                ctrl: _brandCtrl,
                                hint: widget.cfg.type == SectorType.autoParts
                                    ? t('batch.hint_auto_brand')
                                    : t('batch.hint_brand_name'),
                                onSelected: (id, name) =>
                                    _update(brandId: id, brandName: name),
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

                  // ── Varyant Garanti Banner — yeni ürün için tek varyant ──
                  // Mimari: her yeni ürün en az 1 variantla kaydedilir.
                  // Birim fiyat + stok + barkod bu variant'a aktarılır.
                  if (row.isNew && !widget.cfg.fields.showVariantSize)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VariantSummaryBanner(row: row, accentColor: accentColor, t: t),
                    ),

                  // ── Bölüm 2: Varyant — Fiyat & Stok ──────────────────────
                  _WizardSectionHeader(
                    stepNumber: 2,
                    title: row.isNew
                        ? t('batch.variant_price_stock')
                        : t('batch.price_and_stock'),
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
                        // ── Fiyat alanları ─────────────────────────────────
                        // KURAL: Mevcut ürün eşleşmesinde salePrice SİSTEM
                        // fiyatıyla aynı kalır (read-only, 🔒 ikon).
                        // Yeni ürün veya manuel satırda düzenlenebilir.
                        _FormRow(children: [
                          _Field(
                            label: row.variantRows.isNotEmpty
                                ? '${t('batch.default_label')} ${t('batch.purchase_price')} ₺'
                                : '${t('batch.purchase_price')} ₺${row.isExisting ? ' *' : ''}',
                            ctrl: _purchaseCtrl,
                            onChanged: (v) =>
                                _update(purchasePrice: double.tryParse(v.replaceAll(',', '.')) ?? 0),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            hint: '0,00',
                          ),
                          if (row.isExisting && row.existingSalePrice != null)
                            // Mevcut ürün — satış fiyatı SİSTEMDEN (kilitli)
                            _LockedPriceField(
                              label: '🔒 ${widget.cfg.labels.salePriceLabel} ₺',
                              value: row.existingSalePrice!,
                              tooltip: t('batch.system_price_locked_tooltip'),
                            )
                          else
                            _Field(
                              label: row.variantRows.isNotEmpty
                                  ? '${t('batch.default_label')} ${widget.cfg.labels.salePriceLabel} ₺'
                                  : '${widget.cfg.labels.salePriceLabel} ₺ *',
                              ctrl: _saleCtrl,
                              onChanged: (v) =>
                                  _update(salePrice: double.tryParse(v.replaceAll(',', '.')) ?? 0),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              hint: '0,00',
                            ),
                        ]),

                        // ── Varyantlara Uygula (sadece variant varsa) ──────
                        if (row.variantRows.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const SizedBox(width: 2),
                              _ApplyToVariantsBtn(
                                label: '↓ ${t('batch.purchase_price')}',
                                onTap: () => _applyPurchaseToAllVariants(row),
                              ),
                              const SizedBox(width: 8),
                              _ApplyToVariantsBtn(
                                label: '↓ ${widget.cfg.labels.salePriceLabel}',
                                onTap: () => _applySaleToAllVariants(row),
                              ),
                              const Spacer(),
                              // Toplam stok: varyant adetlerinin toplamı
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.info.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.layers_rounded,
                                        size: 11, color: AppColors.info),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${t('batch.total_stock')}: ${row.effectiveQuantity}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.info,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // ── Toplam Fiyat → Variant birim fiyatına orantılı bölüşüm ─
                          // Senaryo: 5 beden Tshirt → toplam 500 TL gir → her variant
                          // adet başına 100 TL birim fiyat. (totalPrice / sumOfQty)
                          const SizedBox(height: 10),
                          _FormRow(children: [
                            _Field(
                              label: '${t('batch.total_purchase_price')} ₺',
                              ctrl: _totalPurchaseCtrl,
                              onChanged: (v) {
                                final total = double.tryParse(
                                    v.replaceAll(',', '.')) ?? 0;
                                if (total > 0) {
                                  _distributeTotalToVariants(row, total, 'purchase');
                                }
                              },
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              hint: '0,00',
                            ),
                            _Field(
                              label: '${t('batch.total_sale_price')} ₺',
                              ctrl: _totalSaleCtrl,
                              onChanged: (v) {
                                final total = double.tryParse(
                                    v.replaceAll(',', '.')) ?? 0;
                                if (total > 0) {
                                  _distributeTotalToVariants(row, total, 'sale');
                                }
                              },
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              hint: '0,00',
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                t('batch.total_price_distribute_hint'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ]),
                        ],

                        // ── Adet: Fatura Adedi + Teslim Alınan (tüm ürünler) ──
                        if (row.variantRows.isEmpty) ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: _Field(
                                label: t('batch.invoice_qty'),
                                ctrl: _invoiceQtyCtrl,
                                onChanged: (v) => _update(
                                  invoiceQuantity: int.tryParse(v),
                                  clearInvoiceQuantity: v.isEmpty,
                                ),
                                keyboardType: TextInputType.number,
                                hint: '0',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Field(
                                label: '${t('batch.received_qty')} *',
                                ctrl: _quantityCtrl,
                                onChanged: (v) =>
                                    _update(quantity: int.tryParse(v) ?? 1),
                                keyboardType: TextInputType.number,
                                hint: '1',
                              ),
                            ),
                          ]),
                          // Shortage uyarı banner
                          if (row.hasShortage) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.warning.withValues(alpha: 0.4)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 14, color: AppColors.warning),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${row.shortageQty} ${t('batch.shortage_note')}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ],

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
                              trueLabel: t('batch.vat_included_yes'),
                              falseLabel: t('batch.vat_included_no'),
                              value: row.vatIncluded,
                              onChanged: (v) => _update(vatIncluded: v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              label: t('batch.field_discount'),
                              ctrl: _discountCtrl,
                              keyboardType: const TextInputType
                                  .numberWithOptions(decimal: true),
                              onChanged: (v) => _update(
                                discountRate: double.tryParse(
                                        v.replaceAll(',', '.')) ??
                                    0,
                              ),
                              hint: '0',
                            ),
                          ),
                        ]),

                        // ── Kâr özet banner ────────────────────────────────
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
                                    // Varyantlar varsa: Maliyet · Satış · Kâr
                                    if (row.variantRows.isNotEmpty) ...[
                                      TextSpan(
                                        text: '${t("batch.cost")}: ',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                      TextSpan(
                                        text: widget.currency.format(row.lineCost),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.warning),
                                      ),
                                      TextSpan(
                                        text: '  •  ${t("common.total")} ${t("batch.sale_price")}: ',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                      TextSpan(
                                        text: widget.currency.format(row.lineTotal),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.info),
                                      ),
                                      TextSpan(
                                        text: '  •  ${t("batch.unit_profit")}: ',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                      TextSpan(
                                        text: widget.currency.format(row.lineProfit),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: row.lineProfit >= 0
                                                ? AppColors.success
                                                : AppColors.danger),
                                      ),
                                      TextSpan(
                                        text: '  •  ${row.effectiveQuantity} ${t("common.quantity_unit")}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ] else ...[
                                      TextSpan(
                                        text: '${t('batch.unit_profit')}: ',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                      TextSpan(
                                        text: widget.currency.format(
                                                row.salePrice - row.purchasePrice) +
                                            '  •  ',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.success),
                                      ),
                                      TextSpan(
                                        text: '${t('common.total')}: ',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                      TextSpan(
                                        text: widget.currency.format(row.lineProfit),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.success),
                                      ),
                                    ],
                                    TextSpan(
                                      text: '  •  ${t('batch.margin')}: %${margin.toStringAsFixed(1)}',
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
                    _BatchVariantBuilder(
                      variantRows: row.variantRows,
                      defaultPurchasePrice: row.purchasePrice,
                      defaultSalePrice: row.salePrice,
                      sizeLabel: widget.cfg.labels.variantField,
                      accentColor: accentColor,
                      onChanged: (rows) => _update(variantRows: rows),
                      t: t,
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
                                      : [
                                          {
                                            'oemNumber': v.trim(),
                                            'manufacturer': ''
                                          }
                                        ],
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
                      t: t,
                    ),
                  ],

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
                      // Sadece satırı sil — build() addPostFrameCallback ile dialog'u kapatır.
                      // İkinci Navigator.pop() ekleme: double-pop ekranı atıyor.
                      ref.read(batchEntryProvider.notifier).removeRow(widget.rowId);
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
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
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
// Kart üzerinde: varyant ürün için toplam stok rozeti (tıklanamaz)
class _VariantQtyBadge extends StatelessWidget {
  final int totalQty;
  const _VariantQtyBadge(this.totalQty);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.layers_rounded, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            '$totalQty',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog Section 2: "↓ Alışı / Satışı Varyantlara Uygula" mini butonu
class _ApplyToVariantsBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ApplyToVariantsBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }
}

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
    final t = i18nOf(ref);
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
                hint: Text(
                  '— ${t('common.select')} —',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
  final String trueLabel;
  final String falseLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _VatIncludedSwitch({
    required this.label,
    required this.trueLabel,
    required this.falseLabel,
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
                value ? trueLabel : falseLabel,
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
    final brandName = row.brandName ?? row.existingBrandName;
    final shelf = row.existingShelfLocation;
    final stock = row.existingCurrentStock;

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
          // ── Üst satır: Mevcut etiketi + stok rozeti + SKU ───────────────
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
              if (stock != null) _StockBadge(stock: stock, t: t),
              if (stock != null && row.existingVariantSku != null)
                const SizedBox(width: 6),
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
          // Kategori / marka / barkod / raf chip'leri
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
              if (brandName != null && brandName.isNotEmpty)
                _InfoChip(
                  icon: Icons.business_outlined,
                  label: brandName,
                  color: AppColors.textSecondary,
                ),
              if (row.barcode.isNotEmpty)
                _InfoChip(
                  icon: Icons.qr_code_rounded,
                  label: row.barcode,
                  color: AppColors.textMuted,
                ),
              if (shelf != null && shelf.isNotEmpty)
                _InfoChip(
                  icon: Icons.shelves,
                  label: shelf,
                  color: AppColors.info,
                ),
            ],
          ),

          // ── Varyant Özeti — "Bu ürünün N varyantı var" ───────────────────
          if (row.existingVariantCount != null && row.existingVariantCount! > 0) ...[
            const SizedBox(height: 8),
            _ExistingVariantsSection(
              count: row.existingVariantCount!,
              variants: row.existingVariants,
              accentColor: accentColor,
              t: t,
            ),
          ],

          // ── OEM chip listesi ─────────────────────────────────────────────
          if (row.existingOemCodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t('batch.oem_codes')}: ',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: row.existingOemCodes
                        .map((code) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.orange
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.orange
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.orange,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],

          // ── Yeni fiyat girin uyarısı (kritik — kullanıcı sistemin eski
          // fiyatını baz alacak sanmasın) + sistemdeki son fiyat referansı ──
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 13, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t('batch.new_price_required_note'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                // Referans: sistemdeki son alış + satış fiyatları
                if (row.existingLastPurchasePrice != null ||
                    row.existingSalePrice != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 19),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (row.existingLastPurchasePrice != null &&
                            row.existingLastPurchasePrice! > 0)
                          Text(
                            '${t("batch.last_purchase_price")}: ₺${row.existingLastPurchasePrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (row.existingSalePrice != null &&
                            row.existingSalePrice! > 0)
                          Text(
                            '${t("batch.system_sale_price")}: ₺${row.existingSalePrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Stok + cari güncellenecek info notu (ikincil bilgi)
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

/// Mevcut ürün kartı sağ üst — toplam stok rozeti.
class _StockBadge extends StatelessWidget {
  final double stock;
  final Function(String) t;
  const _StockBadge({required this.stock, required this.t});

  @override
  Widget build(BuildContext context) {
    final isEmpty = stock <= 0;
    final color = isEmpty ? AppColors.danger : AppColors.success;
    final label = isEmpty
        ? t('batch.no_stock')
        : '${t('batch.current_stock')}: ${stock.toInt()}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmpty
                ? Icons.warning_amber_rounded
                : Icons.layers_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
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
          if (result.claim != null) ...[
            const SizedBox(height: 16),
            _ClaimBanner(claim: result.claim!, currency: currency, t: t),
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

class _ClaimBanner extends StatelessWidget {
  final BatchClaimInfo claim;
  final NumberFormat currency;
  final Function(String) t;
  const _ClaimBanner({required this.claim, required this.currency, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_problem_outlined,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('su.claim_batch_toast'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${claim.lineCount} ${t('batch.items')}  •  ${currency.format(claim.claimAmount)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(t('su.claim_view_action')),
              onPressed: () {
                Navigator.pop(context);
                context.push('/supplier-claims/${claim.claimId}');
              },
            ),
          ),
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
  final String Function(String) t;

  const _BatchAttributesSection({
    required this.attributes,
    required this.cfg,
    required this.onChanged,
    required this.t,
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
            Text(widget.t('batch.add_attribute'),
                style: const TextStyle(
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
                    labelText: widget.t('batch.attribute_name'),
                    hintText: widget.t('batch.hint_attr_name'),
                    errorText: nameError,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(selIcon,
                        size: 18, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.t('batch.select_icon'),
                    style: const TextStyle(
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
              child: Text(widget.t('common.cancel')),
            ),
            AppButton.primary(
              text: widget.t('common.add'),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDs(() => nameError = widget.t('batch.attribute_required'));
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
                Text(widget.t('batch.variant_attributes'),
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
                    child: Text('${attrs.length} ${widget.t('batch.variants')}',
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(widget.t('batch.add_new'),
                              style: const TextStyle(
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

// ── BATCH VARIANT BUILDER ─────────────────────────────────────────────────────

// Renk paleti — veri değerleri (DB'ye bu şekilde kaydedilir, i18n gerekmez)
const _kColorPalette = [
  ('Siyah',      Color(0xFF1a1a1a)),
  ('Beyaz',      Color(0xFFf5f5f5)),
  ('Kırmızı',    Color(0xFFe53935)),
  ('Mavi',       Color(0xFF1e88e5)),
  ('Lacivert',   Color(0xFF1a237e)),
  ('Gri',        Color(0xFF757575)),
  ('Yeşil',      Color(0xFF43a047)),
  ('Sarı',       Color(0xFFfdd835)),
  ('Mor',        Color(0xFF8e24aa)),
  ('Pembe',      Color(0xFFe91e8c)),
  ('Kahverengi', Color(0xFF6d4c41)),
  ('Turuncu',    Color(0xFFf4511e)),
];

// Hızlı beden setleri — (chip etiketi, beden listesi)
const _kSizeSets = [
  ('35–42', ['35','36','37','38','39','40','41','42']),
  ('37–44', ['37','38','39','40','41','42','43','44']),
  ('S/M/L/XL', ['S','M','L','XL']),
  ('XS–XXL', ['XS','S','M','L','XL','XXL']),
];

// Varyant özelliği — builder fazında kullanılan yerel model
class _VAttr {
  final String id;
  String name;
  IconData icon;
  List<String> values;

  _VAttr({
    String? id,
    required this.name,
    required this.icon,
    List<String>? values,
  })  : id = id ?? 'attr-${DateTime.now().microsecondsSinceEpoch}',
        values = values ?? [];
}

// Preset şablonlar — wizard.dart ile aynı içerik
List<_VAttr> _buildPreset(String key) {
  switch (key) {
    case 'shoes':
      return [
        _VAttr(name: 'Renk', icon: Icons.palette_outlined,
            values: ['Siyah', 'Beyaz', 'Mavi']),
        _VAttr(name: 'Numara', icon: Icons.format_size_rounded,
            values: ['38', '39', '40', '41', '42']),
      ];
    case 'clothing':
      return [
        _VAttr(name: 'Renk', icon: Icons.palette_outlined,
            values: ['Kırmızı', 'Mavi', 'Siyah', 'Beyaz']),
        _VAttr(name: 'Beden', icon: Icons.straighten_rounded,
            values: ['XS', 'S', 'M', 'L', 'XL', 'XXL']),
      ];
    case 'electronics':
      return [
        _VAttr(name: 'RAM', icon: Icons.memory_rounded,
            values: ['4 GB', '8 GB', '16 GB']),
        _VAttr(name: 'Depolama', icon: Icons.storage_rounded,
            values: ['128 GB', '256 GB', '512 GB']),
        _VAttr(name: 'Renk', icon: Icons.palette_outlined,
            values: ['Siyah', 'Beyaz', 'Gri']),
      ];
    default:
      return [];
  }
}

class _BatchVariantBuilder extends StatefulWidget {
  final List<BatchVariantRow> variantRows;
  final double defaultPurchasePrice;
  final double defaultSalePrice;
  final String sizeLabel;
  final Color accentColor;
  final void Function(List<BatchVariantRow>) onChanged;
  final String Function(String) t;

  const _BatchVariantBuilder({
    required this.variantRows,
    required this.defaultPurchasePrice,
    required this.defaultSalePrice,
    required this.sizeLabel,
    required this.accentColor,
    required this.onChanged,
    required this.t,
  });

  @override
  State<_BatchVariantBuilder> createState() => _BatchVariantBuilderState();
}

class _BatchVariantBuilderState extends State<_BatchVariantBuilder> {
  // ── Tablo fazı için controller map ────────────────────────────────────────
  final Map<String, TextEditingController> _ctrls = {};

  // ── Builder fazı state ────────────────────────────────────────────────────
  bool _showBuilder = true;
  List<_VAttr> _attrs = [];
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _showBuilder = widget.variantRows.isEmpty;
    if (_showBuilder) {
      _selectedPreset = 'shoes';
      _attrs = _buildPreset('shoes');
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Parent değişikliklerini (örn. _distributeTotalToVariants ile fiyat
  /// güncellemesi) controller text'lerine yansıt.
  /// Aksi halde row.purchasePrice değişse de UI'da eski değer görünür.
  @override
  void didUpdateWidget(covariant _BatchVariantBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final row in widget.variantRows) {
      // purchase
      final pCtrl = _ctrls['${row.id}_purchase'];
      if (pCtrl != null) {
        final expected = (row.purchasePrice ?? widget.defaultPurchasePrice)
            .toStringAsFixed(2);
        if (pCtrl.text != expected && expected != '0.00') {
          pCtrl.text = expected;
        }
      }
      // sale
      final sCtrl = _ctrls['${row.id}_sale'];
      if (sCtrl != null) {
        final expected = (row.salePrice ?? widget.defaultSalePrice)
            .toStringAsFixed(2);
        if (sCtrl.text != expected && expected != '0.00') {
          sCtrl.text = expected;
        }
      }
      // quantity
      final qCtrl = _ctrls['${row.id}_quantity'];
      if (qCtrl != null) {
        final expected = row.quantity.toString();
        if (qCtrl.text != expected) {
          qCtrl.text = expected;
        }
      }
    }
  }

  TextEditingController _ctrl(String rowId, String field, String initial) =>
      _ctrls.putIfAbsent('${rowId}_$field', () => TextEditingController(text: initial));

  // ── Preset uygula ─────────────────────────────────────────────────────────
  void _applyPreset(String key) {
    setState(() {
      _selectedPreset = key;
      _attrs = _buildPreset(key);
    });
  }

  void _addRow() {
    final newRow = BatchVariantRow(
      purchasePrice: widget.defaultPurchasePrice > 0 ? widget.defaultPurchasePrice : null,
      salePrice: widget.defaultSalePrice > 0 ? widget.defaultSalePrice : null,
    );
    widget.onChanged([...widget.variantRows, newRow]);
  }

  void _addSizeSet(List<String> sizes) {
    // Boş size'lı (manuel boş eklenen) satırlar varsa duplicate sayma
    final existingSizes = widget.variantRows
        .map((r) => r.size.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final newRows = sizes
        .where((s) => !existingSizes.contains(s))
        .map((s) => BatchVariantRow(
              size: s,
              purchasePrice: widget.defaultPurchasePrice > 0 ? widget.defaultPurchasePrice : null,
              salePrice: widget.defaultSalePrice > 0 ? widget.defaultSalePrice : null,
            ))
        .toList();
    // Kullanıcıya her zaman feedback ver (0 yeni eklendi de bilgi)
    final tot = widget.variantRows.length + newRows.length;
    final t = widget.t;
    if (newRows.isNotEmpty) {
      widget.onChanged([...widget.variantRows, ...newRows]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${newRows.length} ${t('batch.variants_added')} $tot'),
          duration: const Duration(seconds: 2),
        ));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('batch.all_sizes_added')),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _removeRow(String rowId) {
    final toRemove = _ctrls.keys.where((k) => k.startsWith('${rowId}_')).toList();
    for (final k in toRemove) {
      _ctrls[k]!.dispose();
      _ctrls.remove(k);
    }
    widget.onChanged(widget.variantRows.where((r) => r.id != rowId).toList());
  }

  void _copyRow(BatchVariantRow source) {
    final copy = BatchVariantRow(
      size: source.size,
      color: source.color,
      barcode: '',
      quantity: source.quantity,
      purchasePrice: source.purchasePrice,
      salePrice: source.salePrice,
    );
    final idx = widget.variantRows.indexWhere((r) => r.id == source.id);
    final updated = [...widget.variantRows];
    updated.insert(idx + 1, copy);
    widget.onChanged(updated);
  }

  void _updateRow(BatchVariantRow updated) {
    final rows = widget.variantRows.map((r) => r.id == updated.id ? updated : r).toList();
    widget.onChanged(rows);
  }

  void _applyPurchaseToAll() {
    if (widget.defaultPurchasePrice <= 0) return;
    final rows = widget.variantRows
        .map((r) => (r.purchasePrice == null || r.purchasePrice == 0)
            ? r.copyWith(purchasePrice: widget.defaultPurchasePrice)
            : r)
        .toList();
    widget.onChanged(rows);
    // Ctrl'leri güncelle
    for (final r in rows) {
      final c = _ctrls['${r.id}_purchase'];
      if (c != null && c.text.isEmpty) {
        c.text = widget.defaultPurchasePrice.toString();
      }
    }
  }

  void _applySaleToAll() {
    if (widget.defaultSalePrice <= 0) return;
    final rows = widget.variantRows
        .map((r) => (r.salePrice == null || r.salePrice == 0)
            ? r.copyWith(salePrice: widget.defaultSalePrice)
            : r)
        .toList();
    widget.onChanged(rows);
    for (final r in rows) {
      final c = _ctrls['${r.id}_sale'];
      if (c != null && c.text.isEmpty) {
        c.text = widget.defaultSalePrice.toString();
      }
    }
  }

  // ── Varyant üret (kartezyen çarpım) ──────────────────────────────────────
  void _generateVariants() {
    final validAttrs = _attrs.where((a) => a.values.isNotEmpty).toList();
    if (validAttrs.isEmpty) return;

    List<Map<String, String>> combos = [{}];
    for (final attr in validAttrs) {
      final newCombos = <Map<String, String>>[];
      for (final combo in combos) {
        for (final val in attr.values) {
          newCombos.add({...combo, attr.name: val});
        }
      }
      combos = newCombos;
    }

    final rows = combos.map((combo) {
      final color = combo['Renk'] ?? '';
      final otherVals = combo.entries
          .where((e) => e.key != 'Renk')
          .map((e) => e.value)
          .join(' / ');
      return BatchVariantRow(
        size: otherVals,
        color: color,
        // Tam attribute haritasını sakla — provider backend payload'ını buradan üretir
        attributesMap: Map<String, String>.from(combo),
        purchasePrice: widget.defaultPurchasePrice > 0 ? widget.defaultPurchasePrice : null,
        salePrice: widget.defaultSalePrice > 0 ? widget.defaultSalePrice : null,
      );
    }).toList();

    // Ctrl'leri temizle — yeni satırlar geliyor
    for (final c in _ctrls.values) { c.dispose(); }
    _ctrls.clear();

    widget.onChanged(rows);
    setState(() => _showBuilder = false);
  }

  int get _totalVariantCount {
    if (_attrs.isEmpty) return 0;
    final filled = _attrs.where((a) => a.values.isNotEmpty).toList();
    if (filled.isEmpty) return 0;
    return filled.fold(1, (acc, a) => acc * a.values.length);
  }

  // ── Değer ekle dialogu ────────────────────────────────────────────────────
  void _showAddValueDialog(BuildContext context, _VAttr attr) {
    final ctrl = TextEditingController();
    final t = widget.t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(attr.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t('batch.add_value'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              setState(() => attr.values.add(v.trim()));
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) {
                setState(() => attr.values.add(v));
                Navigator.pop(context);
              }
            },
            child: Text(t('common.add')),
          ),
        ],
      ),
    );
  }

  // ── Özellik ekle dialogu ──────────────────────────────────────────────────
  void _showAddAttrDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final t = widget.t;
    IconData selectedIcon = Icons.label_outline_rounded;
    final iconChoices = [
      (Icons.palette_outlined, 'Renk'),
      (Icons.format_size_rounded, 'Beden'),
      (Icons.memory_rounded, 'RAM'),
      (Icons.storage_rounded, 'Depo'),
      (Icons.straighten_rounded, 'Ölçü'),
      (Icons.devices_rounded, 'Model'),
      (Icons.label_outline_rounded, 'Diğer'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(t('batch.add_attribute'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: t('batch.attribute_name'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Text(t('batch.select_icon'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: iconChoices.map((item) {
                  final isSel = selectedIcon == item.$1;
                  return GestureDetector(
                    onTap: () => setLocal(() => selectedIcon = item.$1),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel
                            ? widget.accentColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSel ? widget.accentColor : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.$1, size: 18,
                          color: isSel ? widget.accentColor : AppColors.textMuted),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('common.cancel')),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  _attrs.add(_VAttr(name: name, icon: selectedIcon));
                  _selectedPreset = null;
                });
                Navigator.pop(ctx);
              },
              child: Text(t('common.add')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showBuilder
        ? _buildBuilderPhase(context)
        : _buildTablePhase(context);
  }

  // ── BUILDER FAZI ─────────────────────────────────────────────────────────
  Widget _buildBuilderPhase(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor = widget.accentColor.withValues(alpha: 0.25);
    final t = widget.t;
    final canGenerate = _attrs.any((a) => a.values.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Başlık ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 15, color: widget.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('batch.variant_attributes'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor,
                    ),
                  ),
                ),
                if (widget.variantRows.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _showBuilder = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.table_rows_rounded, size: 11,
                              color: widget.accentColor),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.variantRows.length} ${t("batch.variant")}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Preset şablonlar ────────────────────────────────────
                Text(
                  t('batch.variant_presets'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPresetChip('shoes',       Icons.directions_walk_rounded, t('batch.preset_shoes'),       t),
                    _buildPresetChip('clothing',    Icons.checkroom_rounded,       t('batch.preset_clothing'),    t),
                    _buildPresetChip('electronics', Icons.devices_rounded,         t('batch.preset_electronics'), t),
                    _buildPresetChip('custom',      Icons.tune_rounded,            t('batch.preset_custom'),      t),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Özellik kartları ─────────────────────────────────────
                if (_attrs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        t('batch.no_variants_added'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  ..._attrs.asMap().entries.map((e) {
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: e.key < _attrs.length - 1 ? 10 : 0),
                      child: _buildAttrCard(context, e.value, t),
                    );
                  }),
                const SizedBox(height: 10),

                // ── Özellik ekle butonu ──────────────────────────────────
                GestureDetector(
                  onTap: () => _showAddAttrDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.35)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 14,
                            color: widget.accentColor),
                        const SizedBox(width: 5),
                        Text(
                          t('batch.add_attribute'),
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
                const SizedBox(height: 12),

                // ── Varyant oluştur butonu ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canGenerate ? _generateVariants : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                    label: Text(
                      canGenerate
                          ? '${t("batch.generate_variants")} ($_totalVariantCount)'
                          : t('batch.generate_variants'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildPresetChip(
      String key, IconData icon, String label, String Function(String) t) {
    final isSel = _selectedPreset == key;
    return GestureDetector(
      onTap: () => _applyPreset(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel
              ? widget.accentColor
              : widget.accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel
                ? widget.accentColor
                : widget.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12,
                color: isSel ? Colors.white : widget.accentColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSel ? Colors.white : widget.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttrCard(
      BuildContext context, _VAttr attr, String Function(String) t) {
    const attrColors = [
      Colors.indigo,
      Colors.red,
      Colors.teal,
      Colors.deepOrange,
      Colors.blue,
      Colors.purple,
    ];
    final idx = _attrs.indexOf(attr);
    final cardColor = attrColors[idx % attrColors.length];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(attr.icon, size: 14, color: cardColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  attr.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cardColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _attrs.remove(attr)),
                child: Icon(Icons.close_rounded, size: 15,
                    color: cardColor.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...attr.values.map((val) {
                final colorEntry =
                    _kColorPalette.where((c) => c.$1 == val).firstOrNull;
                return GestureDetector(
                  onTap: () => setState(() => attr.values.remove(val)),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorEntry != null
                          ? colorEntry.$2.withValues(alpha: 0.15)
                          : cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorEntry != null
                            ? colorEntry.$2.withValues(alpha: 0.5)
                            : cardColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (colorEntry != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorEntry.$2,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.1)),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          val,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cardColor,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.close_rounded, size: 10,
                            color: cardColor.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                );
              }),
              // Renk için renk paleti, diğerleri için metin giriş
              if (attr.name == 'Renk')
                _buildColorAddChip(context, attr, cardColor, t)
              else
                GestureDetector(
                  onTap: () => _showAddValueDialog(context, attr),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cardColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 11,
                            color: cardColor),
                        const SizedBox(width: 3),
                        Text(
                          t('batch.add_value'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorAddChip(BuildContext context, _VAttr attr, Color cardColor,
      String Function(String) t) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => _ColorPickerSheet(
            selected: '',
            accentColor: widget.accentColor,
            customLabel: t('batch.variant_color_custom'),
            onSelect: (name) {
              Navigator.pop(context);
              if (name == '__custom__') {
                _showAddValueDialog(context, attr);
              } else if (!attr.values.contains(name)) {
                setState(() => attr.values.add(name));
              }
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 11, color: cardColor),
            const SizedBox(width: 3),
            Text(
              t('batch.add_value'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cardColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TABLO FAZI ────────────────────────────────────────────────────────────
  Widget _buildTablePhase(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor = widget.accentColor.withValues(alpha: 0.25);
    final t = widget.t;

    final totalQty = widget.variantRows.fold(0, (s, r) => s + r.quantity);
    final totalValue = widget.variantRows.fold(0.0, (s, r) {
      final price = r.salePrice ?? widget.defaultSalePrice;
      return s + price * r.quantity;
    });
    final invalidCount = widget.variantRows.where((r) => !r.isValid).length;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Başlık + "Yapılandırmayı Düzenle" ────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14,
                    color: widget.accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.variantRows.length} ${t("batch.variant")}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showBuilder = true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 11,
                            color: widget.accentColor),
                        const SizedBox(width: 4),
                        Text(
                          t('batch.back_to_builder'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Hızlı beden seti ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Text(
                  t('batch.variant_quick_sizes'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _kSizeSets.map((set) {
                      return GestureDetector(
                        onTap: () => _addSizeSet(set.$2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: widget.accentColor
                                    .withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            set.$1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.accentColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Tablo başlığı ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.07),
            ),
            child: Row(
              children: [
                _HeaderCell(widget.sizeLabel, flex: 2),
                _HeaderCell(t('batch.variant_color'), flex: 2),
                _HeaderCell(t('common.quantity'), flex: 1),
                _HeaderCell(t('common.barcode'), flex: 2),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${t("batch.purchase")} ₺',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (widget.defaultPurchasePrice > 0)
                        GestureDetector(
                          onTap: _applyPurchaseToAll,
                          child: Tooltip(
                            message: t('common.apply'),
                            child: Icon(
                              Icons.vertical_align_bottom_rounded,
                              size: 13,
                              color: widget.accentColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${t("batch.sale")} ₺',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (widget.defaultSalePrice > 0)
                        GestureDetector(
                          onTap: _applySaleToAll,
                          child: Tooltip(
                            message: t('common.apply'),
                            child: Icon(
                              Icons.vertical_align_bottom_rounded,
                              size: 13,
                              color: widget.accentColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 52),
              ],
            ),
          ),
          // ── Satırlar ──────────────────────────────────────────────────────
          if (widget.variantRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  t('batch.no_variants_added'),
                  style: const TextStyle(
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
              final isInvalid = !vr.isValid;
              final rowBg = isInvalid
                  ? AppColors.danger.withValues(alpha: 0.05)
                  : idx.isOdd
                      ? widget.accentColor.withValues(alpha: 0.03)
                      : Colors.transparent;
              return _VariantTableRow(
                key: ValueKey(vr.id),
                variantRow: vr,
                rowBg: rowBg,
                isInvalid: isInvalid,
                sizeCtrl: _ctrl(vr.id, 'size', vr.size),
                barcodeCtrl: _ctrl(vr.id, 'barcode', vr.barcode),
                qtyCtrl: _ctrl(vr.id, 'qty',
                    vr.quantity > 0 ? '${vr.quantity}' : '1'),
                purchaseCtrl: _ctrl(
                    vr.id,
                    'purchase',
                    vr.purchasePrice != null && vr.purchasePrice! > 0
                        ? vr.purchasePrice!.toString()
                        : ''),
                saleCtrl: _ctrl(
                    vr.id,
                    'sale',
                    vr.salePrice != null && vr.salePrice! > 0
                        ? vr.salePrice!.toString()
                        : ''),
                accentColor: widget.accentColor,
                t: t,
                onUpdate: _updateRow,
                onDelete: () => _removeRow(vr.id),
                onCopy: () => _copyRow(vr),
              );
            }),
          // ── Özet bar ─────────────────────────────────────────────────────
          if (widget.variantRows.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.04),
                border: Border(
                  top: BorderSide(
                      color: widget.accentColor.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${widget.variantRows.length} ${t("batch.variant")}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('·',
                      style: TextStyle(
                          color: widget.accentColor.withValues(alpha: 0.5))),
                  const SizedBox(width: 6),
                  Text(
                    '$totalQty ${t("common.quantity_unit")}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  const Text('·',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 6),
                  Text(
                    '₺${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (invalidCount > 0) ...[
                    const Spacer(),
                    const Icon(Icons.warning_amber_rounded,
                        size: 13, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text(
                      '$invalidCount ${t("batch.incomplete")}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.warning),
                    ),
                  ],
                ],
              ),
            ),
          // ── Manuel satır ekle butonu ──────────────────────────────────────
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
                        color: widget.accentColor.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 15,
                          color: widget.accentColor),
                      const SizedBox(width: 5),
                      Text(
                        t('batch.variants_add'),
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
  final bool isInvalid;
  final TextEditingController sizeCtrl;
  final TextEditingController barcodeCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController purchaseCtrl;
  final TextEditingController saleCtrl;
  final Color accentColor;
  final String Function(String) t;
  final void Function(BatchVariantRow) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const _VariantTableRow({
    super.key,
    required this.variantRow,
    required this.rowBg,
    required this.isInvalid,
    required this.sizeCtrl,
    required this.barcodeCtrl,
    required this.qtyCtrl,
    required this.purchaseCtrl,
    required this.saleCtrl,
    required this.accentColor,
    required this.t,
    required this.onUpdate,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: isInvalid
            ? Border(
                left: BorderSide(
                  color: AppColors.warning.withValues(alpha: 0.6),
                  width: 3,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _VCell(sizeCtrl, flex: 2, hint: '41',
              onChanged: (v) => onUpdate(variantRow.copyWith(size: v))),
          // Renk seçici
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _ColorPickerCell(
                value: variantRow.color,
                accentColor: accentColor,
                customLabel: t('batch.variant_color_custom'),
                onChanged: (v) => onUpdate(variantRow.copyWith(color: v)),
              ),
            ),
          ),
          _VCell(qtyCtrl, flex: 1, hint: '1', isNum: true,
              onChanged: (v) => onUpdate(variantRow.copyWith(quantity: int.tryParse(v) ?? 1))),
          _VCell(barcodeCtrl, flex: 2, hint: t('common.barcode'),
              onChanged: (v) => onUpdate(variantRow.copyWith(barcode: v))),
          _VCell(purchaseCtrl, flex: 2, hint: '0.00', isNum: true,
              onChanged: (v) => onUpdate(variantRow.copyWith(
                  purchasePrice: double.tryParse(v.replaceAll(',', '.'))))),
          _VCell(saleCtrl, flex: 2, hint: '0.00', isNum: true,
              onChanged: (v) => onUpdate(variantRow.copyWith(
                  salePrice: double.tryParse(v.replaceAll(',', '.'))))),
          // Kopyala butonu
          SizedBox(
            width: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: onCopy,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_all_rounded, size: 13,
                      color: accentColor.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),
          // Sil butonu
          SizedBox(
            width: 24,
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

// ── Renk Seçici Hücre ─────────────────────────────────────────────────────────
class _ColorPickerCell extends StatefulWidget {
  final String value;
  final Color accentColor;
  final String customLabel;
  final void Function(String) onChanged;

  const _ColorPickerCell({
    required this.value,
    required this.accentColor,
    required this.customLabel,
    required this.onChanged,
  });

  @override
  State<_ColorPickerCell> createState() => _ColorPickerCellState();
}

class _ColorPickerCellState extends State<_ColorPickerCell> {
  bool _showCustom = false;
  late final TextEditingController _customCtrl;

  @override
  void initState() {
    super.initState();
    // Eğer değer palette'de yoksa "Özel" modunda başla
    final isPreset = _kColorPalette.any((c) => c.$1 == widget.value);
    _showCustom = widget.value.isNotEmpty && !isPreset;
    _customCtrl = TextEditingController(text: _showCustom ? widget.value : '');
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Color? _presetColor(String name) {
    for (final c in _kColorPalette) {
      if (c.$1 == name) return c.$2;
    }
    return null;
  }

  void _pick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ColorPickerSheet(
        selected: widget.value,
        accentColor: widget.accentColor,
        customLabel: widget.customLabel,
        onSelect: (name) {
          Navigator.pop(context);
          if (name == '__custom__') {
            setState(() => _showCustom = true);
          } else {
            setState(() => _showCustom = false);
            widget.onChanged(name);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showCustom) {
      return TextField(
        controller: _customCtrl,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: widget.customLabel,
          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.primary)),
          suffixIcon: GestureDetector(
            onTap: () => setState(() {
              _showCustom = false;
              _customCtrl.clear();
              widget.onChanged('');
            }),
            child: const Icon(Icons.close_rounded, size: 14),
          ),
        ),
      );
    }

    final presetColor = _presetColor(widget.value);
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (presetColor != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: presetColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(
                widget.value.isEmpty ? '—' : widget.value,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.value.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: 16,
                color: widget.accentColor.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerSheet extends StatelessWidget {
  final String selected;
  final Color accentColor;
  final String customLabel;
  final void Function(String) onSelect;

  const _ColorPickerSheet({
    required this.selected,
    required this.accentColor,
    required this.customLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutamaç
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._kColorPalette.map((c) {
                  final isSelected = selected == c.$1;
                  return GestureDetector(
                    onTap: () => onSelect(c.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.$2.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? c.$2 : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: c.$2,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(c.$1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: AppColors.textPrimary,
                              )),
                        ],
                      ),
                    ),
                  );
                }),
                // Özel seçeneği
                GestureDetector(
                  onTap: () => onSelect('__custom__'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      color: AppColors.bgLight,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Text(customLabel,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

// ── TOPLU İŞLEM PANELİ ───────────────────────────────────────────────────────

/// Yeni ürün satırı varken görünür. Kategori, KDV ve marka tüm yeni satırlara
/// tek tıkla uygulanmasını sağlar.
class _BulkActionsPanel extends ConsumerWidget {
  final String Function(String) t;
  const _BulkActionsPanel({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batchEntryProvider);
    final newCount = state.rows.where((r) => r.isNew).length;
    if (newCount == 0) return const SizedBox.shrink();

    return Container(
      color: AppColors.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      child: Row(
        children: [
          const Icon(Icons.auto_fix_high_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            '${t("batch.bulk_actions")} ($newCount)',
            style: const TextStyle(
                fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _BulkChip(
                    icon: Icons.category_outlined,
                    label: t('batch.field_category'),
                    onTap: () => _pickCategory(context, ref),
                  ),
                  const SizedBox(width: 6),
                  _BulkChip(
                    icon: Icons.percent_rounded,
                    label: t('batch.field_vat'),
                    onTap: () => _pickVat(context, ref),
                  ),
                  const SizedBox(width: 6),
                  _BulkChip(
                    icon: Icons.business_outlined,
                    label: t('batch.field_brand'),
                    onTap: () => _enterBrand(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    List<Map<String, dynamic>> categories;
    try {
      categories = await ref.read(batchCategoriesProvider.future);
    } catch (_) {
      return;
    }
    if (!context.mounted) return;

    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(t('batch.apply_to_new'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.category_outlined,
                          size: 18, color: AppColors.primary),
                      title: Text(cat['name']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13)),
                      onTap: () => Navigator.pop(context, cat),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      ref.read(batchEntryProvider.notifier).applyCategoryToAll(
        picked['id']?.toString() ?? '',
        picked['name']?.toString() ?? '',
      );
    }
  }

  Future<void> _pickVat(BuildContext context, WidgetRef ref) async {
    const vatOptions = [0.0, 1.0, 8.0, 10.0, 18.0, 20.0];
    final picked = await showDialog<double>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t('batch.field_vat')),
        children: vatOptions
            .map((v) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, v),
                  child: Text('${v.toInt()}%',
                      style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
      ),
    );
    if (picked != null) {
      ref.read(batchEntryProvider.notifier).applyVatToAll(picked);
    }
  }

  Future<void> _enterBrand(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('batch.field_brand')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t('batch.field_brand'),
            isDense: true,
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t('batch.apply_to_new')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (picked != null && picked.isNotEmpty) {
      ref.read(batchEntryProvider.notifier).applyBrandToAll('', picked);
    }
  }
}

class _BulkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BulkChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── BRAND AUTOCOMPLETE ───────────────────────────────────────────────────────
/// Marka autocomplete: mevcut markaları batchBrandsProvider'dan yükler,
/// kullanıcı yeni marka adı yazabilir (free-text fallback).
class _BrandAutocomplete extends ConsumerWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final void Function(String? id, String name) onSelected;

  const _BrandAutocomplete({
    required this.label,
    required this.ctrl,
    required this.onSelected,
    this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(batchBrandsProvider);
    final t = i18nOf(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        async.when(
          loading: () => const SizedBox(
            height: 38,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => TextField(
            controller: ctrl,
            onChanged: (v) => onSelected(null, v),
            style: const TextStyle(fontSize: 13),
            decoration: _brandInputDecoration(hint ?? t('batch.brand_type_new')),
          ),
          data: (brands) => Autocomplete<Map<String, dynamic>>(
            initialValue: TextEditingValue(text: ctrl.text),
            optionsBuilder: (value) {
              final q = value.text.trim().toLowerCase();
              if (q.isEmpty) return brands;
              return brands.where((b) =>
                  (b['name']?.toString().toLowerCase() ?? '').contains(q));
            },
            displayStringForOption: (b) => b['name']?.toString() ?? '',
            fieldViewBuilder:
                (context, textCtrl, focusNode, onSubmit) {
              return TextField(
                controller: textCtrl,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 13),
                decoration: _brandInputDecoration(
                    hint ?? t('batch.brand_type_new')),
                onChanged: (v) {
                  // Parent ctrl'e yaz ama build'de sync yapma (state leak olmasın)
                  ctrl.value = TextEditingValue(
                    text: v,
                    selection: TextSelection.collapsed(offset: v.length),
                  );
                  onSelected(null, v); // serbest metin — id yok
                },
              );
            },
            onSelected: (b) {
              final id = b['id']?.toString();
              final name = b['name']?.toString() ?? '';
              ctrl.value = TextEditingValue(
                text: name,
                selection: TextSelection.collapsed(offset: name.length),
              );
              onSelected(id, name);
            },
            optionsViewBuilder: (context, onSelect, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (_, i) {
                        final opt = options.elementAt(i);
                        return InkWell(
                          onTap: () => onSelect(opt),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              opt['name']?.toString() ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _brandInputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

// ── VARYANT ÖZET BANNER ──────────────────────────────────────────────────────
/// Yeni ürün kartında Section 2 üstünde gösterilen varyant özeti.
///
/// Mimari: her yeni ürün EN AZ 1 varyantla kaydedilir; birim fiyat, stok,
/// barkod ve attributes bu varyanta aktarılır. Bu banner o varyantın
/// önizlemesini yapar — kullanıcı "ürün mü? varyant mı?" ayrımını net görür.
class _VariantSummaryBanner extends StatelessWidget {
  final BatchEntryRow row;
  final Color accentColor;
  final Function(String) t;

  const _VariantSummaryBanner({
    required this.row,
    required this.accentColor,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final barcode = row.barcode.isNotEmpty ? row.barcode : null;
    final shelf = row.shelfLocation;
    final attrCount = row.attributes.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_rounded, size: 13, color: accentColor),
              const SizedBox(width: 6),
              Text(
                t('batch.variant_auto_created'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _VariantChip(
                label: 'SKU',
                value: t('batch.variant_auto_sku'),
                icon: Icons.fingerprint_rounded,
              ),
              if (barcode != null)
                _VariantChip(
                  label: t('batch.barcode'),
                  value: barcode,
                  icon: Icons.qr_code_rounded,
                ),
              if (shelf != null && shelf.isNotEmpty)
                _VariantChip(
                  label: t('batch.shelf'),
                  value: shelf,
                  icon: Icons.shelves,
                ),
              if (attrCount > 0)
                _VariantChip(
                  label: t('batch.variant_attributes'),
                  value: '$attrCount',
                  icon: Icons.label_outline_rounded,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 11, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  t('batch.variant_price_note'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _VariantChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── EXISTING PRODUCT — VARYANT ÖZETİ ─────────────────────────────────────────
/// Mevcut ürünün tüm varyantlarını özet halinde gösterir.
/// Collapsed: "3 varyant" chip. Tap → expand → her varyant için
/// attributes/stok/fiyat/raf satırı. Eşleşen varyant vurgulanır.
class _ExistingVariantsSection extends StatefulWidget {
  final int count;
  final List<Map<String, dynamic>> variants;
  final Color accentColor;
  final Function(String) t;

  const _ExistingVariantsSection({
    required this.count,
    required this.variants,
    required this.accentColor,
    required this.t,
  });

  @override
  State<_ExistingVariantsSection> createState() =>
      _ExistingVariantsSectionState();
}

class _ExistingVariantsSectionState extends State<_ExistingVariantsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.variants.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — sadece sayı chip'i (tek varyantta sade)
        InkWell(
          onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_rounded, size: 12, color: widget.accentColor),
                const SizedBox(width: 4),
                Text(
                  '${widget.count} ${widget.t("batch.variants")}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor,
                  ),
                ),
                if (canExpand) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: widget.accentColor,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Expanded — her varyantın satır satır detayı
        if (_expanded && canExpand) ...[
          const SizedBox(height: 6),
          // Açıklayıcı not: her variantın kendi birim fiyatı vardır,
          // gösterilen ₺X/adet ürünün toplam fiyatı DEĞİL — variantın birimi.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 11, color: AppColors.info),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.t('batch.variant_independent_price_note'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.info,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ]),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8)),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: widget.variants.asMap().entries.map((e) {
                final idx = e.key;
                final v = e.value;
                return _ExistingVariantRow(
                  variant: v,
                  accentColor: widget.accentColor,
                  isLast: idx == widget.variants.length - 1,
                  t: widget.t,
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExistingVariantRow extends StatelessWidget {
  final Map<String, dynamic> variant;
  final Color accentColor;
  final bool isLast;
  final Function(String) t;

  const _ExistingVariantRow({
    required this.variant,
    required this.accentColor,
    required this.isLast,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final sku = variant['sku']?.toString() ?? '';
    final name = variant['name']?.toString() ?? '';
    final stock = (variant['currentStock'] as num?)?.toDouble();
    final price = (variant['salePrice'] as num?)?.toDouble();
    final shelf = variant['shelfLocationCode']?.toString();
    final isMatched = variant['isMatched'] as bool? ?? false;

    final attrs = variant['attributes'];
    String attrDisplay = '';
    if (attrs is Map && attrs.isNotEmpty) {
      attrDisplay = attrs.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(' · ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isMatched
            ? accentColor.withValues(alpha: 0.06)
            : Colors.transparent,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eşleşme işareti
          Icon(
            isMatched
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            size: 12,
            color: isMatched ? accentColor : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          // Attributes + SKU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attrDisplay.isNotEmpty
                      ? attrDisplay
                      : (name.isNotEmpty ? name : '—'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isMatched ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sku.isNotEmpty)
                  Text(
                    sku,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Stok + fiyat + raf
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stock != null)
                Text(
                  '${t("batch.current_stock")}: ${stock.toInt()} ${t("common.quantity_unit")}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: stock <= 0 ? AppColors.danger : AppColors.success,
                  ),
                ),
              if (price != null && price > 0)
                // /adet suffix → birim fiyat olduğu net anlaşılır
                // (ürünün toplam fiyatı değil variantın birim fiyatı).
                // Satır toplamı = price × stock; kullanıcı kafasında karıştırmasın.
                Tooltip(
                  message: '${t("batch.variant_unit_price_tooltip")}'
                      ': ₺${price.toStringAsFixed(2)}'
                      '${stock != null && stock > 0 ? " · ${t("common.total")}: ₺${(price * stock).toStringAsFixed(2)}" : ""}',
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '₺${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: '/${t("common.quantity_unit")}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]),
                  ),
                ),
              if (shelf != null && shelf.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shelves, size: 9, color: AppColors.info),
                    const SizedBox(width: 2),
                    Text(
                      shelf,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── KİLİTLİ FİYAT ALANI — mevcut ürün satış fiyatı ───────────────────────────
/// Mevcut ürün eşleşmesinde satış fiyatı SİSTEM değeriyle aynı kalır.
/// Kullanıcı düzenleyemez (read-only), kilit ikonu ile vurgulanır.
/// Değer sabitlendiği için `row.salePrice = existingSalePrice` provider'da atanır.
class _LockedPriceField extends StatelessWidget {
  final String label;
  final double value;
  final String tooltip;

  const _LockedPriceField({
    required this.label,
    required this.value,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        Tooltip(
          message: tooltip,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '₺${value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.lock_outline_rounded,
                    size: 13, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
