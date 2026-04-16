import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/providers/sector_provider.dart';
import 'package:project_pos/core/config/sector_config.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/settings/screens/admin/product_relationship_management_panel.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  String Function(String) get t => i18nOf(ref);

  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;

  TabController? _tabController;
  List<_TabDef> _tabs = [];

  // Data states
  List<Map<String, dynamic>> _oemNumbers = [];
  bool _oemLoading = false;
  List<Map<String, dynamic>> _crossRefs = [];
  bool _crossRefLoading = false;
  List<Map<String, dynamic>> _vehicleCompats = [];
  bool _vehicleCompatLoading = false;
  List<Map<String, dynamic>> _movements = [];
  bool _movementsLoading = false;
  String? _movementsError;
  String _historyFilter = 'ALL';

  final _dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');
  final _currFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  void _setupTabs() {
    final cfg = ref.read(sectorConfigProvider);
    final List<_TabDef> newTabs = [
      _TabDef(_TabType.general, t('common.general_info'), Icons.info_outlined),
    ];

    if (cfg.fields.showOem) {
      newTabs.add(_TabDef(_TabType.oem, cfg.labels.oemField, Icons.confirmation_number));
    }
    if (cfg.fields.showCrossRef) {
      newTabs.add(_TabDef(_TabType.crossRef, t('product.cross_references'), Icons.swap_horiz));
    }
    if (cfg.fields.showVehicleCompat) {
      newTabs.add(_TabDef(_TabType.vehicleCompat, t('product.vehicle_compatibility'), Icons.directions_car));
    }
    newTabs.add(_TabDef(_TabType.history, t('product.history'), Icons.history));
    newTabs.add(_TabDef(_TabType.relationships, 'İlişkiler', Icons.link));

    setState(() {
      _tabs = newTabs;
      _tabController?.dispose();
      _tabController = TabController(length: _tabs.length, vsync: this);

      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          final tab = _tabs[_tabController!.index];
          if (tab.type == _TabType.history && !_movementsLoading) {
            _loadMovements();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final product = await ref.read(productServiceProvider).getProductById(widget.productId);
      if (product.isEmpty) {
        setState(() { _error = t('common.not_found'); _isLoading = false; });
        return;
      }
      _setupTabs();
      setState(() { _product = product; _isLoading = false; });
      _loadTabData();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadTabData() async {
    final variantId = _firstVariantId;
    if (variantId == null) return;
    final cfg = ref.read(sectorConfigProvider);

    if (cfg.fields.showOem) {
      setState(() => _oemLoading = true);
      try {
        final oems = await ref.read(oemServiceProvider).getByVariantId(variantId);
        setState(() { _oemNumbers = oems; _oemLoading = false; });
      } catch (_) { setState(() => _oemLoading = false); }
    }

    if (cfg.fields.showCrossRef) {
      setState(() => _crossRefLoading = true);
      try {
        final crossRefs = await ref.read(crossReferenceServiceProvider).getByVariantId(variantId);
        setState(() { _crossRefs = crossRefs; _crossRefLoading = false; });
      } catch (_) { setState(() => _crossRefLoading = false); }
    }

    if (cfg.fields.showVehicleCompat) {
      setState(() => _vehicleCompatLoading = true);
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.get('product/api/vehicle-compatibility/variant/$variantId');
        final data = response.data['data'];
        if (data is List) {
          setState(() { _vehicleCompats = data.cast<Map<String, dynamic>>(); _vehicleCompatLoading = false; });
        } else { setState(() => _vehicleCompatLoading = false); }
      } catch (_) { setState(() => _vehicleCompatLoading = false); }
    }
  }

  Future<void> _loadMovements() async {
    final variantId = _firstVariantId;
    if (variantId == null) {
      setState(() { _movementsError = 'Varyant ID bulunamadı'; _movementsLoading = false; });
      return;
    }
    setState(() { _movementsLoading = true; _movementsError = null; });
    try {
      final movements = await ref.read(stockServiceProvider).getVariantMovements(variantId);
      setState(() { _movements = movements; _movementsLoading = false; });
    } catch (e) {
      debugPrint('_loadMovements hata: $e');
      setState(() { _movementsError = e.toString(); _movementsLoading = false; });
    }
  }

  String? get _firstVariantId {
    final variants = (_product?['variants'] as List?)?.cast<Map<String, dynamic>>();
    return (variants != null && variants.isNotEmpty) ? variants.first['id']?.toString() : null;
  }

  bool _isMovementIn(String type) => const {
    'PURCHASE_IN', 'SALE_RETURN_IN', 'SALE_CANCEL_IN', 'TRANSFER_IN', 'ADJUSTMENT_IN',
  }.contains(type);

  List<Map<String, dynamic>> get _filteredMovements {
    if (_historyFilter == 'ALL') return _movements;
    return _movements.where((m) {
      final type = m['movementType']?.toString() ?? '';
      switch (_historyFilter) {
        case 'PURCHASE':   return type == 'PURCHASE_IN' || type == 'PURCHASE_RETURN_OUT';
        case 'SALE':       return type == 'SALE_OUT' || type == 'SALE_RETURN_IN' || type == 'SALE_CANCEL_IN';
        case 'TRANSFER':   return type == 'TRANSFER_IN' || type == 'TRANSFER_OUT';
        case 'ADJUSTMENT': return type == 'ADJUSTMENT_IN' || type == 'ADJUSTMENT_OUT';
        default:           return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(sectorConfigProvider);

    if (_isLoading || _tabController == null) {
      return const AppScaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _product == null) {
      return AppScaffold(
        appBar: AppAppBar.standard(title: t('common.error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_error ?? t('common.error')),
              AppButton.primary(text: t('common.retry'), onPressed: _loadProduct),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    return AppScaffold(
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/inventory/products'),
        ),
        title: product['name']?.toString() ?? '',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadProduct();
              if (_tabController!.index < _tabs.length && _tabs[_tabController!.index].type == _TabType.history) {
                _loadMovements();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 22),
            tooltip: t('common.edit'),
            onPressed: () => _showProductEditSheet(),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          switch (tab.type) {
            case _TabType.general: return _buildGeneralInfoTab(product, cfg);
            case _TabType.oem: return _buildOemTab();
            case _TabType.crossRef: return _buildCrossRefTab();
            case _TabType.vehicleCompat: return _buildVehicleCompatTab();
            case _TabType.history: return _buildHistoryTab();
            case _TabType.relationships: return _buildRelationshipsTab(product);
          }
        }).toList(),
      ),
    );
  }

  // ─── TAB 1: GENEL BİLGİ ──────────────────────────────────────────────────

  Widget _buildGeneralInfoTab(Map<String, dynamic> product, SectorConfig cfg) {
    final variants    = (product['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final status      = product['status']?.toString();
    final imageUrl    = product['imageUrl']?.toString();
    final price       = product['basePrice'] ?? product['price'] ?? 0;
    final stock       = (product['stock'] as num?)?.toInt() ?? 0;
    final isOutStock  = stock == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero kart ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ürün görseli
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => _detailImagePlaceholder(160),
                        )
                      : _detailImagePlaceholder(160),
                ),
                // İçerik
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Durum badge
                      if (status != null && status != 'ACTIVE')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppBadge(
                              text: _getStatusLabel(status),
                              variant: _getStatusBadgeVariant(status)),
                        ),
                      // Ürün adı
                      Text(
                        product['name']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bilgi pilleri
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoPill(Icons.qr_code_rounded,
                              'SKU: ${product['sku'] ?? '-'}'),
                          if (product['barcode'] != null)
                            _buildInfoPill(Icons.barcode_reader,
                                '${cfg.labels.barcodeLabel}: ${product['barcode']}'),
                          if (cfg.fields.showBrand &&
                              product['brand'] != null &&
                              product['brand'].toString().isNotEmpty)
                            _buildInfoPill(Icons.local_offer_outlined,
                                product['brand'].toString()),
                          if ((product['categoryName']?.toString() ?? '').isNotEmpty)
                            _buildInfoPill(Icons.category_outlined,
                                product['categoryName'].toString()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showBarcodePrintSheet(),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: Text(t('product.print_barcode')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── İstatistik kartları ───────────────────────────────────────
          Row(
            children: [
              _buildDetailStatCard(
                label: cfg.labels.salePriceLabel,
                value: _currFmt.format(price),
                icon: Icons.payments_rounded,
                color: AppColors.primary,
                flex: 55,
              ),
              const SizedBox(width: 10),
              _buildDetailStatCard(
                label: t('stock.stock'),
                value: '$stock',
                icon: Icons.inventory_2_rounded,
                color: isOutStock ? AppColors.danger : AppColors.success,
                flex: 45,
              ),
            ],
          ),

          // ── Açıklama ──────────────────────────────────────────────────
          if (product['description'] != null &&
              product['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.description_outlined,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 7),
                    Text(t('product.description'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    product['description'].toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Raf kodu ──────────────────────────────────────────────────
          if (cfg.fields.showShelf && product['shelfCode'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shelves,
                        color: AppColors.warning, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cfg.labels.shelfField,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        product['shelfCode'].toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── Varyantlar ────────────────────────────────────────────────
          if (variants.length > 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.layers_rounded,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 7),
                    Text(
                      '${t('product.variants')} (${variants.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ...variants.map((v) => _buildVariantRow(v, cfg)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantRow(Map<String, dynamic> variant, SectorConfig cfg) {
    final vStock = (variant['stock'] as num?)?.toInt() ?? 0;
    final stockColor = vStock == 0 ? AppColors.danger : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variant['name'] ?? '-',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('SKU: ${variant['sku'] ?? '-'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            _currFmt.format(variant['salePrice'] ?? 0),
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '$vStock',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: stockColor),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BARCODE PRINT SHEET ─────────────────────────────────────────────────

  void _showBarcodePrintSheet() {
    if (_product == null) return;
    final product = _product!;
    final barcodeValue = product['barcode']?.toString()
        ?? product['sku']?.toString()
        ?? '';
    if (barcodeValue.isEmpty) {
      AppToast.warning(context, t('product.no_barcode'));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool showName  = true;
        bool showPrice = true;
        bool showSku   = true;
        int  quantity  = 1;
        String labelSize = 'M';

        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              maxChildSize: 0.96,
              minChildSize: 0.4,
              builder: (_, scroll) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t('product.print_barcode'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                )),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: ListView(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        children: [
                          // ── Önizleme ─────────────────────────────────
                          _buildLabelPreview(
                            product, barcodeValue,
                            showName, showPrice, showSku, labelSize,
                          ),
                          const SizedBox(height: 20),

                          // ── Etiket boyutu ─────────────────────────────
                          _editSectionHeader(t('product.label_size'), Icons.straighten_outlined),
                          Row(
                            children: [
                              for (final sz in [
                                ('S', '3×1 cm\nKüçük'),
                                ('M', '5×2 cm\nOrta'),
                                ('L', '8×3 cm\nBüyük'),
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setSheet(() => labelSize = sz.$1),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 120),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: labelSize == sz.$1
                                              ? AppColors.primary.withValues(alpha: 0.1)
                                              : AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(
                                            color: labelSize == sz.$1
                                                ? AppColors.primary : AppColors.border,
                                            width: labelSize == sz.$1 ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Text(
                                          sz.$2,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: labelSize == sz.$1
                                                ? AppColors.primary : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Seçenekler ────────────────────────────────
                          _editSectionHeader(t('common.options'), Icons.tune_outlined),
                          _buildToggleTile(t('product.show_name_on_label'),  showName,
                              (v) => setSheet(() => showName  = v)),
                          _buildToggleTile(t('product.show_price_on_label'), showPrice,
                              (v) => setSheet(() => showPrice = v)),
                          _buildToggleTile(t('product.show_sku_on_label'),   showSku,
                              (v) => setSheet(() => showSku   = v)),
                          const SizedBox(height: 16),

                          // ── Adet ──────────────────────────────────────
                          _editSectionHeader(t('product.print_quantity'), Icons.format_list_numbered_outlined),
                          Row(
                            children: [
                              IconButton(
                                onPressed: quantity > 1 ? () => setSheet(() => quantity--) : null,
                                icon: const Icon(Icons.remove_circle_outline),
                                color: AppColors.primary,
                              ),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  '$quantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: quantity < 100 ? () => setSheet(() => quantity++) : null,
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Yazdır butonu ─────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.print_rounded, color: Colors.white),
                              label: Text(
                                '$quantity ${t("product.print_barcode")}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              onPressed: () => _printBarcodeLabels(
                                ctx, product, barcodeValue,
                                showName, showPrice, showSku,
                                labelSize, quantity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabelPreview(
    Map<String, dynamic> product,
    String barcodeValue,
    bool showName,
    bool showPrice,
    bool showSku,
    String labelSize,
  ) {
    final price = product['basePrice'] ?? product['price'] ?? 0;
    final double previewH = labelSize == 'S' ? 80 : labelSize == 'M' ? 110 : 140;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(t('product.barcode_preview'),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: previewH),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 6),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showName) ...[
                  Text(
                    product['name']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                ],
                SizedBox(
                  height: 52,
                  child: CustomPaint(
                    painter: _BarcodePainter(barcodeValue),
                    size: const Size(double.infinity, 52),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  barcodeValue,
                  style: const TextStyle(
                      fontSize: 9, letterSpacing: 1.5, color: AppColors.textPrimary),
                ),
                if (showSku && (product['sku']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product['sku']}',
                    style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                  ),
                ],
                if (showPrice) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currFmt.format(price),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Future<void> _printBarcodeLabels(
    BuildContext ctx,
    Map<String, dynamic> product,
    String barcodeValue,
    bool showName,
    bool showPrice,
    bool showSku,
    String labelSize,
    int quantity,
  ) async {
    if (ctx.mounted) Navigator.of(ctx).pop();

    final price = (product['basePrice'] as num?)?.toDouble()
        ?? (product['price'] as num?)?.toDouble() ?? 0.0;

    final lW = labelSize == 'S'
        ? PdfPageFormat.cm * 3
        : labelSize == 'M'
            ? PdfPageFormat.cm * 5
            : PdfPageFormat.cm * 8;
    final lH = labelSize == 'S'
        ? PdfPageFormat.cm * 1
        : labelSize == 'M'
            ? PdfPageFormat.cm * 2
            : PdfPageFormat.cm * 3;

    try {
      await Printing.layoutPdf(
        onLayout: (format) async {
          final doc = pw.Document();
          for (int i = 0; i < quantity; i++) {
            doc.addPage(
              pw.Page(
                pageFormat: PdfPageFormat(lW, lH, marginAll: 4),
                build: (context) => pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (showName)
                        pw.Text(
                          product['name']?.toString() ?? '',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      pw.SizedBox(height: 2),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: barcodeValue,
                        width: lW - 16,
                        height: lH * 0.45,
                        textStyle: pw.TextStyle(fontSize: 6),
                        drawText: true,
                      ),
                      if (showSku && (product['sku']?.toString() ?? '').isNotEmpty)
                        pw.Text(
                          'SKU: ${product['sku']}',
                          style: pw.TextStyle(fontSize: 5),
                        ),
                      if (showPrice) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _currFmt.format(price),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }
          return doc.save();
        },
      );
    } catch (e) {
      if (mounted) AppToast.error(context, t('common.error'));
    }
  }

  // ─── TAB: OEM ─────────────────────────────────────────────────────────────

  Widget _buildOemTab() {
    final cfg = ref.watch(sectorConfigProvider);
    if (_oemLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cfg.labels.oemField} (${_oemNumbers.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              AppButton.primary(
                text: t('common.add'),
                icon: Icons.add,
                onPressed: _showAddOemDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: _oemNumbers.isEmpty 
            ? AppEmptyState.noData(title: t('common.no_result'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _oemNumbers.length,
                itemBuilder: (context, index) {
                  final oem = _oemNumbers[index];
                  return AppCard(
                    child: ListTile(leading: const Icon(Icons.tag, color: AppColors.textMuted), title: Text(oem['oemNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(oem['manufacturer'] ?? '')),
                  );
                },
              ),
        ),
      ],
    );
  }

  // ─── TAB: CROSS REF ───────────────────────────────────────────────────────

  Widget _buildCrossRefTab() {
    if (_crossRefLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t('product.cross_references')} (${_crossRefs.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              AppButton.primary(
                text: t('common.add'),
                icon: Icons.add,
                onPressed: _showAddCrossReferenceDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: _crossRefs.isEmpty
            ? AppEmptyState.noData(title: t('common.no_result'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _crossRefs.length,
                itemBuilder: (context, index) {
                  final cr = _crossRefs[index];
                  return AppCard(
                    child: ListTile(leading: const Icon(Icons.swap_horiz, color: AppColors.info), title: Text(cr['crossRefNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(cr['crossRefBrand'] ?? '')),
                  );
                },
              ),
        ),
      ],
    );
  }

  // ─── TAB: VEHICLE COMPAT ──────────────────────────────────────────────────

  Widget _buildVehicleCompatTab() {
    if (_vehicleCompatLoading) return const Center(child: CircularProgressIndicator());
    return _vehicleCompats.isEmpty
      ? AppEmptyState.noData(title: t('common.no_result'))
      : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _vehicleCompats.length,
          itemBuilder: (context, index) {
            final vc = _vehicleCompats[index];
            return AppCard(
              child: ListTile(leading: const Icon(Icons.directions_car, color: AppColors.primary), title: Text('${vc['make'] ?? ''} ${vc['model'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${vc['yearStart'] ?? ''} - ${vc['yearEnd'] ?? t('common.current')}')),
            );
          },
        );
  }

  // ─── TAB: HISTORY ─────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_movementsLoading) return const Center(child: CircularProgressIndicator());

    if (_movementsError != null) {
      return Center(
        child: AppEmptyState.error(
          title: t('common.error'),
          description: _movementsError!,
          actionText: t('common.retry'),
          onAction: _loadMovements,
        ),
      );
    }

    final filtered = _filteredMovements;

    return Column(
      children: [
        if (_movements.isNotEmpty) _buildHistoryStats(),
        _buildHistoryActions(),
        if (_movements.isNotEmpty) _buildHistoryFilterChips(),
        filtered.isEmpty
          ? Expanded(
              child: AppEmptyState.noData(
                title: t('stock.no_movements'),
                actionText: t('common.refresh'),
                onAction: _loadMovements,
              ),
            )
          : Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildTimelineCard(filtered[index], index, filtered.length),
              ),
            ),
      ],
    );
  }

  Widget _buildHistoryStats() {
    final totalIn  = _movements
        .where((m) => _isMovementIn(m['movementType']?.toString() ?? ''))
        .fold<double>(0, (s, m) => s + (m['quantity'] as num? ?? 0).toDouble());
    final totalOut = _movements
        .where((m) => !_isMovementIn(m['movementType']?.toString() ?? ''))
        .fold<double>(0, (s, m) => s + (m['quantity'] as num? ?? 0).toDouble());
    final net = totalIn - totalOut;

    String fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildStatPill(t('stock.total_in'),  '+${fmt(totalIn)}',  AppColors.success),
          _buildStatSep(),
          _buildStatPill(t('stock.total_out'), '-${fmt(totalOut)}', AppColors.danger),
          _buildStatSep(),
          _buildStatPill(
            t('stock.net_change'),
            '${net >= 0 ? '+' : ''}${fmt(net)}',
            net >= 0 ? AppColors.info : AppColors.warning,
          ),
          const Spacer(),
          Text(
            '${_movements.length} ${t('stock.movement_count')}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    ],
  );

  Widget _buildStatSep() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 14),
    width: 1, height: 28, color: AppColors.border,
  );

  Widget _buildHistoryActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _quickActionBtn(icon: Icons.tune,       label: t('stock.adjust'),   color: AppColors.primary, onTap: _showStockAdjustDialog),
          const SizedBox(width: 10),
          _quickActionBtn(icon: Icons.swap_horiz, label: t('stock.transfer'), color: AppColors.info,    onTap: () => context.push('/stock/transfer')),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: t('common.refresh'),
            onPressed: _loadMovements,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryFilterChips() {
    final chips = [
      ('ALL',        t('common.all')),
      ('PURCHASE',   t('stock.purchase')),
      ('SALE',       t('sales.sale')),
      ('TRANSFER',   t('stock.filter_transfer')),
      ('ADJUSTMENT', t('stock.filter_adjustment')),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips.map((chip) {
          final selected = _historyFilter == chip.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(chip.$2,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  )),
              selected: selected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.bgLight,
              side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (_) => setState(() => _historyFilter = chip.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> m, int index, int total) {
    final type     = m['movementType']?.toString() ?? '';
    final cfg      = _movementConfig(type);
    final isIn     = cfg['isIn'] as bool;
    final color    = cfg['color'] as Color;
    final qty      = (m['quantity'] as num?)?.toDouble() ?? 0;
    final qtyStr   = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);

    final unitPrice   = (m['unitPrice']   as num?)?.toDouble();
    final totalAmount = (m['totalAmount'] as num?)?.toDouble()
        ?? (unitPrice != null && qty > 0 ? unitPrice * qty : null);

    final dateStr    = m['createTime'] != null
        ? _dateTimeFmt.format(DateTime.parse(m['createTime'].toString())) : '-';
    final createdBy  = m['createUser']?.toString() ?? m['createdBy']?.toString() ?? '';
    final locationId = m['locationId']?.toString() ?? '';
    final locType    = m['locationType']?.toString() ?? '';
    final reference  = m['referenceId']?.toString() ?? m['referenceNumber']?.toString() ?? '';
    final note       = m['note']?.toString() ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─ Timeline rail ─
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(cfg['icon'] as IconData, size: 13, color: color),
                ),
                if (index < total - 1)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ─ Card content ─
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row: type label + qty badge ──
                  Row(
                    children: [
                      Expanded(
                        child: Text(cfg['label'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: color,
                            )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isIn
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${isIn ? '+' : '-'}$qtyStr',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIn ? AppColors.success : AppColors.danger,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  // ── Time + person ──
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      if (createdBy.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.person_outline_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(createdBy,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                  // ── Amount ──
                  if (totalAmount != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${t('common.amount')}: ',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(_currFmt.format(totalAmount),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                      ],
                    ),
                  ],
                  // ── Location ──
                  if (locationId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          locType.isNotEmpty ? '$locationId ($locType)' : locationId,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  // ── Reference ──
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(reference,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                  // ── Note ──
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(note,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB: RELATIONSHIPS ───────────────────────────────────────────────────

  Widget _buildRelationshipsTab(Map<String, dynamic> product) {
    return SingleChildScrollView(
      child: ProductRelationshipManagementPanel(
        productId: product['id'].toString(),
        productName: product['name']?.toString() ?? 'Ürün',
      ),
    );
  }

  // ─── PRODUCT EDIT SHEET ───────────────────────────────────────────────────

  void _showProductEditSheet() {
    if (_product == null) return;
    final product = _product!;
    final cfg     = ref.read(sectorConfigProvider);

    // ── Kontrolörler ─────────────────────────────────────────────────────
    final nameCtr      = TextEditingController(text: product['name']?.toString() ?? '');
    final descCtr      = TextEditingController(text: product['description']?.toString() ?? '');
    final priceCtr     = TextEditingController(
        text: (product['basePrice'] as num?)?.toStringAsFixed(2) ?? '');
    final purchaseCtr  = TextEditingController(
        text: (product['purchasePrice'] as num?)?.toStringAsFixed(2) ?? '');
    final lowStockCtr  = TextEditingController(
        text: (product['lowStockThreshold'] as num?)?.toString() ?? '10');
    final shelfCtr     = TextEditingController(text: product['shelfCode']?.toString() ?? '');
    final brandCtr     = TextEditingController(text: product['brand']?.toString() ?? '');
    final barcodeCtr   = TextEditingController(text: product['barcode']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String selStatus    = product['status']?.toString() ?? 'ACTIVE';
        double selTaxRate   = (product['taxRate'] as num?)?.toDouble() ?? 18.0;
        String? selCatId    = product['categoryId']?.toString();
        List<Map<String, dynamic>> cats = [];
        bool catsLoading = true;
        bool isSaving    = false;

        return StatefulBuilder(
          builder: (ctx, setSheet) {
            // Kategorileri bir kez yükle
            if (catsLoading) {
              ref.read(companyCategoryServiceProvider).getMyCategoryList()
                  .then((list) => setSheet(() { cats = list; catsLoading = false; }))
                  .catchError((_)  => setSheet(() => catsLoading = false));
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.92,
              maxChildSize: 0.97,
              minChildSize: 0.5,
              builder: (_, scroll) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Tutaç
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Başlık
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t('product.edit_product'),
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // ── İçerik ────────────────────────────────────────────
                    Expanded(
                      child: ListView(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        children: [

                          // ── TEMEL BİLGİLER ──────────────────────────────
                          _editSectionHeader(t('common.general_info'), Icons.info_outlined),
                          _editField(label: t('product.name'), controller: nameCtr),
                          const SizedBox(height: 12),
                          _editField(label: t('product.description'), controller: descCtr, maxLines: 4),
                          const SizedBox(height: 22),

                          // ── FİYATLANDIRMA ───────────────────────────────
                          _editSectionHeader(t('product.pricing'), Icons.payments_outlined),
                          Row(
                            children: [
                              Expanded(
                                child: _editField(
                                  label: cfg.labels.salePriceLabel,
                                  controller: priceCtr,
                                  hint: '0.00',
                                  keyboard: TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _editField(
                                  label: t('product.purchase_price'),
                                  controller: purchaseCtr,
                                  hint: '0.00',
                                  keyboard: TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // KDV seçici
                          _buildTaxRateChips(
                            current: selTaxRate,
                            onSelect: (v) => setSheet(() => selTaxRate = v),
                          ),
                          const SizedBox(height: 22),

                          // ── SINIFLANDIRMA ────────────────────────────────
                          _editSectionHeader(t('product.classification'), Icons.category_outlined),
                          // Durum seçici
                          _buildStatusChips(
                            current: selStatus,
                            onSelect: (v) => setSheet(() => selStatus = v),
                          ),
                          const SizedBox(height: 14),
                          // Kategori dropdown
                          _buildCategoryDropdown(
                            cats:    cats,
                            selId:   selCatId,
                            loading: catsLoading,
                            onSelect: (v) => setSheet(() => selCatId = v),
                          ),
                          if (cfg.fields.showBrand) ...[
                            const SizedBox(height: 12),
                            _editField(label: t('product.brand'), controller: brandCtr),
                          ],
                          const SizedBox(height: 22),

                          // ── STOK & KONUM ─────────────────────────────────
                          _editSectionHeader(t('stock.stock'), Icons.inventory_2_outlined),
                          _editField(
                            label: t('common.barcode'),
                            controller: barcodeCtr,
                            hint: '0000000000000',
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _editField(
                                  label: t('inventory.low_stock_threshold'),
                                  controller: lowStockCtr,
                                  hint: '10',
                                  keyboard: TextInputType.number,
                                ),
                              ),
                              if (cfg.fields.showShelf) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _editField(
                                    label: cfg.labels.shelfField,
                                    controller: shelfCtr,
                                    hint: 'A-01',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 32),

                          // ── KAYDET ───────────────────────────────────────
                          isSaving
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.check_rounded,
                                        color: Colors.white),
                                    label: Text(t('common.save'),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    onPressed: () async {
                                      final name = nameCtr.text.trim();
                                      if (name.isEmpty) {
                                        AppToast.warning(ctx, t('product.name'));
                                        return;
                                      }
                                      setSheet(() => isSaving = true);
                                      try {
                                        final data = <String, dynamic>{
                                          'name':               name,
                                          'description':        descCtr.text.trim(),
                                          'basePrice':          double.tryParse(priceCtr.text) ?? 0,
                                          'status':             selStatus,
                                          'taxRate':            selTaxRate,
                                          'lowStockThreshold':  int.tryParse(lowStockCtr.text) ?? 10,
                                        };
                                        if (purchaseCtr.text.isNotEmpty) {
                                          data['purchasePrice'] = double.tryParse(purchaseCtr.text);
                                        }
                                        if (selCatId != null) data['categoryId'] = selCatId;
                                        if (cfg.fields.showBrand) data['brand'] = brandCtr.text.trim();
                                        if (cfg.fields.showShelf) data['shelfCode'] = shelfCtr.text.trim();
                                        if (barcodeCtr.text.isNotEmpty) data['barcode'] = barcodeCtr.text.trim();

                                        await ref.read(productServiceProvider)
                                            .updateProduct(product['id'].toString(), data);

                                        if (ctx.mounted) Navigator.of(ctx).pop();
                                        if (mounted) {
                                          AppToast.success(context, t('common.saved'));
                                          _loadProduct();
                                        }
                                      } catch (_) {
                                        setSheet(() => isSaving = false);
                                        if (ctx.mounted) AppToast.error(ctx, t('common.error'));
                                      }
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Edit sheet yardımcıları ──────────────────────────────────────────────

  Widget _editSectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.3)),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _editField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.bgLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTaxRateChips({
    required double current,
    required void Function(double) onSelect,
  }) {
    const rates = [0.0, 1.0, 8.0, 10.0, 18.0, 20.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('product.tax_rate'),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: rates.map((r) {
            final sel = r == current;
            return GestureDetector(
              onTap: () => onSelect(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  '%${r.toInt()}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textSecondary),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusChips({
    required String current,
    required void Function(String) onSelect,
  }) {
    final statuses = [
      ('ACTIVE',   t('product.status_active'),   AppColors.success),
      ('DRAFT',    t('product.status_draft'),     AppColors.warning),
      ('INACTIVE', t('product.status_inactive'),  AppColors.textMuted),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('common.status'),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: statuses.map((s) {
            final sel = s.$1 == current;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(s.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? s.$3.withValues(alpha: 0.1)
                          : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: sel ? s.$3 : AppColors.border,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Text(
                      s.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? s.$3 : AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown({
    required List<Map<String, dynamic>> cats,
    required String? selId,
    required bool loading,
    required void Function(String?) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('product.category'),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border),
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(9),
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(t('product.category'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(t('common.all'),
                              style: const TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                      ...cats.map((c) => DropdownMenuItem<String?>(
                            value: c['id']?.toString(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(c['categoryName']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary, fontSize: 13)),
                            ),
                          )),
                    ],
                    onChanged: onSelect,
                  ),
                ),
        ),
      ],
    );
  }

  // ─── DIALOGS & HELPERS ──────────────────────────────────────────────────

  void _showStockAdjustDialog() {
    AppToast.info(context, 'Stok düzeltme modülü aktif');
  }

  void _showAddOemDialog() {
    AppToast.info(context, 'OEM Ekleme modülü aktif');
  }

  void _showAddCrossReferenceDialog() {
    AppToast.info(context, 'Çapraz Referans modülü aktif');
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'DRAFT': return t('product.status_draft');
      case 'ACTIVE': return t('product.status_active');
      case 'INACTIVE': return t('product.status_inactive');
      default: return status ?? '';
    }
  }



  BadgeVariant _getStatusBadgeVariant(String? status) {
    if (status == 'ACTIVE') return BadgeVariant.success;
    if (status == 'DRAFT') return BadgeVariant.warning;
    return BadgeVariant.secondary;
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _detailImagePlaceholder(double height) => Container(
    height: height,
    width: double.infinity,
    color: AppColors.bgLight,
    child: const Center(
      child: Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.border),
    ),
  );

  Widget _buildDetailStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _quickActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))]),
        ),
      ),
    );
  }

  Map<String, dynamic> _movementConfig(String type) {
    switch (type) {
      case 'PURCHASE_IN':
        return {'label': t('stock.purchase_in'),                     'icon': Icons.add_shopping_cart_rounded, 'color': AppColors.success, 'isIn': true};
      case 'PURCHASE_RETURN_OUT':
        return {'label': t('stock.purchase_return'),                  'icon': Icons.assignment_return_outlined, 'color': AppColors.orange,  'isIn': false};
      case 'SALE_OUT':
        return {'label': t('sales.sale'),                             'icon': Icons.point_of_sale_rounded,      'color': AppColors.danger,  'isIn': false};
      case 'SALE_RETURN_IN':
        return {'label': t('stock.movement_sale_return_in'),          'icon': Icons.assignment_returned_outlined,'color': AppColors.info,   'isIn': true};
      case 'SALE_CANCEL_IN':
        return {'label': t('sales.sale_cancel'),                      'icon': Icons.cancel_outlined,             'color': AppColors.warning, 'isIn': true};
      case 'TRANSFER_IN':
        return {'label': t('stock.transfer_in'),                      'icon': Icons.arrow_downward_rounded,      'color': AppColors.primary, 'isIn': true};
      case 'TRANSFER_OUT':
        return {'label': t('stock.transfer_out'),                     'icon': Icons.arrow_upward_rounded,        'color': AppColors.primary, 'isIn': false};
      case 'ADJUSTMENT_IN':
        return {'label': t('stock.movement_adjustment_in'),           'icon': Icons.add_circle_outline_rounded,  'color': AppColors.success, 'isIn': true};
      case 'ADJUSTMENT_OUT':
        return {'label': t('stock.movement_adjustment_out'),          'icon': Icons.remove_circle_outline_rounded,'color': AppColors.textMuted,'isIn': false};
      default:
        return {'label': type,                                        'icon': Icons.swap_vert_rounded,           'color': AppColors.textMuted,'isIn': true};
    }
  }
}

enum _TabType { general, oem, crossRef, vehicleCompat, history, relationships }

class _TabDef {
  final _TabType type;
  final String label;
  final IconData icon;
  const _TabDef(this.type, this.label, this.icon);
}

// ── Barcode preview painter ────────────────────────────────────────────────────
// Renders a deterministic stripe pattern based on the barcode string.
// Not a real encoding — for label preview only.
// For scannable output the pdf package's pw.BarcodeWidget (Code 128) is used.
class _BarcodePainter extends CustomPainter {
  final String data;
  const _BarcodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final bars = <double>[];

    // Start guard: |_|_|
    bars.addAll([2, 1, 2, 1, 2]);

    // One inter-char gap per character
    for (final c in data.codeUnits) {
      bars.addAll([
        (c >> 6 & 1) + 1.0,
        1.0,
        (c >> 4 & 1) + 1.0,
        (c >> 5 & 1) + 1.0,
        (c >> 2 & 1) + 1.0,
        1.0,
        (c & 1) + 1.0,
        (c >> 1 & 1) + 1.0,
        (c >> 3 & 1) + 1.0,
        1.0, // inter-character gap
      ]);
    }

    // Stop guard
    bars.addAll([2, 1, 2, 1, 2]);

    final totalUnits = bars.fold(0.0, (s, b) => s + b);
    if (totalUnits == 0) return;
    final unitW = size.width / totalUnits;

    double x = 0;
    for (int i = 0; i < bars.length; i++) {
      final w = bars[i] * unitW;
      if (i % 2 == 0) {
        // even index = bar (black)
        canvas.drawRect(Rect.fromLTWH(x, 0, (w - 0.5).clamp(0.5, w), size.height), paint);
      }
      x += w;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.data != data;
}