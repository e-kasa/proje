import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// Sprint 29-fix-6: PDF print akışı sistemde kullanılmıyor → pdf/printing
// import'ları kaldırıldı. Statement export PDF'i ayrı service'ta yaşıyor.
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/print/label_print_service.dart';
import 'package:project_pos/services/print/label_print_settings.dart';
// Sprint 29-fix: fiş yazıcısı fallback (Case 1.5)
import 'package:project_pos/services/print/print_settings.dart';
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
    newTabs.add(_TabDef(_TabType.relationships, t('product.relationships'), Icons.link));

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
      return const BaseScaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _product == null) {
      return BaseScaffold(
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
    return BaseScaffold(
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

          // ── Varyantlar & Barkod ───────────────────────────────────────
          if (variants.isNotEmpty) ...[
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
                    Expanded(
                      child: Text(
                        variants.length == 1
                            ? t('product.variant_and_barcode')
                            : '${t('product.variants')} (${variants.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ...variants.map((v) => _buildVariantRow(v, cfg, product)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantRow(
    Map<String, dynamic> variant,
    SectorConfig cfg,
    Map<String, dynamic> product,
  ) {
    final vStock    = (variant['stock'] as num?)?.toInt() ?? 0;
    final stockColor = vStock == 0 ? AppColors.danger : AppColors.success;

    // Varyantın barkodunu bul (barcode alanı yoksa SKU fallback)
    // Backend: variant.barcodes[].barcodeCode  (primary öncelikli)
    final barcodeList = (variant['barcodes'] as List?)
        ?.cast<Map<String, dynamic>>();
    String? primaryBarcode;
    if (barcodeList != null && barcodeList.isNotEmpty) {
      final picked = barcodeList.firstWhere(
        (b) => b['isPrimary'] == true,
        orElse: () => barcodeList.first,
      );
      primaryBarcode = picked['barcodeCode']?.toString();
    }
    final rawBarcode = variant['barcode']?.toString() ?? primaryBarcode;
    final vp = _VariantPrint(
      variantId:      variant['id']?.toString() ?? '',
      variantName:    variant['name']?.toString() ?? '',
      barcodeValue:   rawBarcode ?? variant['sku']?.toString() ?? '',
      hasBarcodeReal: rawBarcode != null,
      price: (variant['salePrice'] as num?)?.toDouble()
          ?? (product['basePrice'] as num?)?.toDouble() ?? 0.0,
      sku: variant['sku']?.toString() ?? '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
        children: [
          // ── Sol: isim + SKU + barkod bilgisi ────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(variant['name'] ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.qr_code_rounded,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      vp.hasBarcodeReal
                          ? vp.barcodeValue
                          : 'SKU: ${vp.sku}',
                      style: TextStyle(
                        fontSize: 10,
                        color: vp.hasBarcodeReal
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (!vp.hasBarcodeReal) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('SKU',
                            style: TextStyle(
                                fontSize: 8,
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),

          // ── Orta: fiyat ──────────────────────────────────────────────
          Text(
            _currFmt.format(variant['salePrice'] ?? 0),
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
          const SizedBox(width: 8),

          // ── Stok badge ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('$vStock',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: stockColor)),
          ),
          const SizedBox(width: 4),

          // ── Barkod yazdır butonu ─────────────────────────────────────
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(9)),
            child: InkWell(
              onTap: () => _showBarcodePrintSheet(vp),
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(9)),
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.6))),
                ),
                child: const Icon(
                  Icons.print_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ─── BARCODE PRINT SHEET ─────────────────────────────────────────────────

  void _showBarcodePrintSheet(_VariantPrint variantPrint) {
    if (_product == null) return;
    final product = _product!;

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
        String codeType  = 'BARCODE'; // 'BARCODE' | 'QR'

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
                    // Başlık: varyant adını göster
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.print_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t('product.print_barcode'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    )),
                                if (variantPrint.variantName.isNotEmpty)
                                  Text(
                                    variantPrint.variantName,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted),
                                  ),
                              ],
                            ),
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
                            product, variantPrint,
                            showName, showPrice, showSku,
                            labelSize, codeType,
                          ),
                          const SizedBox(height: 20),

                          // ── Kod türü (Barkod / QR) ────────────────────
                          _editSectionHeader(t('product.code_type'), Icons.qr_code_2_outlined),
                          Row(
                            children: [
                              for (final ct in [
                                ('BARCODE', t('product.barcode_code128'), Icons.barcode_reader),
                                ('QR',      t('product.qr_code'),         Icons.qr_code_2_rounded),
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setSheet(() => codeType = ct.$1),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(vertical: 13),
                                        decoration: BoxDecoration(
                                          color: codeType == ct.$1
                                              ? AppColors.primary.withValues(alpha: 0.1)
                                              : AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(
                                            color: codeType == ct.$1
                                                ? AppColors.primary : AppColors.border,
                                            width: codeType == ct.$1 ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(ct.$3, size: 16,
                                                color: codeType == ct.$1
                                                    ? AppColors.primary
                                                    : AppColors.textSecondary),
                                            const SizedBox(width: 6),
                                            Text(ct.$2,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: codeType == ct.$1
                                                      ? AppColors.primary
                                                      : AppColors.textSecondary,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

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
                          _editSectionHeader(t('product.print_quantity'),
                              Icons.format_list_numbered_outlined),
                          Row(
                            children: [
                              IconButton(
                                onPressed: quantity > 1
                                    ? () => setSheet(() => quantity--)
                                    : null,
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
                                onPressed: quantity < 100
                                    ? () => setSheet(() => quantity++)
                                    : null,
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
                                ctx, product, variantPrint,
                                showName, showPrice, showSku,
                                labelSize, quantity, codeType,
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
    _VariantPrint variant,
    bool showName,
    bool showPrice,
    bool showSku,
    String labelSize,
    String codeType,
  ) {
    final isQr = codeType == 'QR';
    final double previewH = isQr ? 160 : (labelSize == 'S' ? 88 : labelSize == 'M' ? 118 : 148);

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
          // Başlık + tür badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t('product.barcode_preview'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isQr ? t('product.qr_code') : t('product.barcode_code128'),
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Etiket önizleme kartı
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: previewH),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
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
                // ── Barkod veya QR ──────────────────────────────────
                if (isQr)
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _QrPreviewPainter(variant.barcodeValue),
                    ),
                  )
                else
                  SizedBox(
                    height: 52,
                    child: CustomPaint(
                      painter: _BarcodePainter(variant.barcodeValue),
                      size: const Size(double.infinity, 52),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  variant.barcodeValue,
                  style: const TextStyle(
                      fontSize: 9, letterSpacing: 1.2, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                if (showSku && variant.sku.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('SKU: ${variant.sku}',
                      style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
                ],
                if (showPrice) ...[
                  const SizedBox(height: 5),
                  Text(
                    _currFmt.format(variant.price),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
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

  /// Sprint 24 + 29-fix-3 — 4-state akış:
  /// - Case 1: USB etiket yazıcısı kayıtlı + masaüstü → ESC/POS direkt
  /// - Case 1.5 (Sprint 29-fix): Etiket yazıcı yok ama fiş yazıcısı kayıtlı →
  ///   fiş yazıcısını etiket için reuse et (POSA hem fiş hem etiket basabilir)
  /// - Case 2: USB hata → detaylı hata toast (PDF'e DÜŞME — kullanıcı
  ///   "FeedMe POS Print Job" gibi sistem sanal yazıcısına yönlendirilince
  ///   şaşırıyor)
  /// - Case 3: SADECE web build veya hiçbir USB cihaz yok → PDF dialog
  Future<void> _printBarcodeLabels(
    BuildContext ctx,
    Map<String, dynamic> product,
    _VariantPrint variant,
    bool showName,
    bool showPrice,
    bool showSku,
    String labelSize,
    int quantity,
    String codeType,
  ) async {
    if (ctx.mounted) Navigator.of(ctx).pop();

    final labelSettings = ref.read(labelPrintSettingsProvider);

    // Case 1: Etiket yazıcı yapılandırılmış + masaüstü → USB direkt
    if (!kIsWeb && labelSettings.isConfigured) {
      final ok = await _printViaUsbLabelPrinter(
        product: product,
        variant: variant,
        showName: showName,
        showPrice: showPrice,
        showSku: showSku,
        quantity: quantity,
        codeType: codeType,
      );
      if (ok) return;
      // Case 2: USB hata — kullanıcıya detaylı hata, PDF'e DÜŞME
      if (mounted) {
        AppToast.error(
          context,
          'Etiket yazıcısına bağlanılamadı. USB bağlantı + driver kontrol edin '
          '(Ayarlar → Cihazlar → Etiket Yazıcı).',
        );
      }
      return;
    }

    // Case 1.5 (Sprint 29-fix): Etiket yazıcı yok ama fiş yazıcısı kayıtlı →
    // fiş yazıcısını etiket için reuse et. POSA gibi termal cihazlar
    // ESC/POS standardında barkod basabilir; ekstra cihaz almayı zorunlu kılma.
    if (!kIsWeb && !labelSettings.isConfigured) {
      final receiptSettings = ref.read(printSettingsProvider);
      if (receiptSettings.isConfigured) {
        final res = await _printViaReceiptPrinterFallback(
          receiptSettings: receiptSettings,
          product: product,
          variant: variant,
          showName: showName,
          showPrice: showPrice,
          showSku: showSku,
          quantity: quantity,
          codeType: codeType,
        );
        if (res.success) {
          if (mounted) {
            AppToast.info(
              context,
              'Etiket fiş yazıcısı (${receiptSettings.deviceName ?? "USB"}) ile basıldı. '
              'Özel etiket yazıcı için: Ayarlar → Cihazlar → Etiket Yazıcı.',
            );
          }
          return;
        }
        // Sprint 29-fix-3: Fallback hata → detaylı toast, PDF'e DÜŞME.
        // (Önceden Case 3 PDF dialog'a düşüyordu → "FeedMe POS Print Job"
        // gibi sistem sanal yazıcısı kullanıcıyı şaşırtıyordu.)
        if (mounted) {
          AppToast.error(
            context,
            'Fiş yazıcısı (${receiptSettings.deviceName ?? "USB"}) ile etiket '
            'basılamadı: ${res.error}. USB bağlantı + WinUSB driver kontrol edin.',
          );
        }
        return;
      }
      // Sprint 29-fix-4 (kullanıcı 17 deneme): Desktop'ta hiç USB cihaz yoksa
      // PDF dialog'u açmıyoruz — Windows default sistem yazıcısı genellikle
      // sanal PDF (FeedMe POS Print Job, Microsoft Print to PDF) ve kullanıcı
      // bunlara basılan PDF'i Adobe Reader ile açmaya çalışıp şaşırıyor.
      // Açık hata + ayar ekranına yönlendirme net UX.
      if (mounted) {
        AppToast.error(
          context,
          'USB yazıcı yapılandırılmamış. Ayarlar → Cihazlar & Entegrasyonlar → '
          'Etiket Yazıcı veya Fiş Yazıcı menüsünden cihaz seçin.',
        );
      }
      return;
    }

    // Sprint 29-fix-6: PDF dialog tamamen kaldırıldı. Web build'de de USB
    // yapılandırılması zorunlu (çünkü termal cihaz Windows desktop'ta).
    // Web kullanıcısı için açık mesaj.
    if (kIsWeb && mounted) {
      AppToast.error(
        context,
        'Etiket basma için masaüstü uygulamasını + USB yazıcı kullanın. '
        'Web tarayıcıda yazıcı erişimi yoktur.',
      );
    }
  }

  /// USB termal etiket yazıcısına ESC/POS bytes gönder.
  /// Returns true on success.
  Future<bool> _printViaUsbLabelPrinter({
    required Map<String, dynamic> product,
    required _VariantPrint variant,
    required bool showName,
    required bool showPrice,
    required bool showSku,
    required int quantity,
    required String codeType,
  }) async {
    final service = ref.read(labelPrintServiceProvider);
    final type = codeType == 'QR'
        ? LabelCodeType.qr
        : LabelCodeType.code128;

    try {
      for (int i = 0; i < quantity; i++) {
        final result = await service.printBarcodeLabel(
          value: variant.barcodeValue,
          productName: showName ? product['name']?.toString() : null,
          sku: showSku ? variant.sku : null,
          price: showPrice ? variant.price : null,
          codeType: type,
        );
        if (!result.success) return false;
      }
      if (mounted) {
        AppToast.success(context, '$quantity etiket yazdırıldı.');
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sprint 29-fix-3 — Case 1.5: Etiket yazıcı yok ama fiş yazıcısı (Sprint 22)
  /// var. Fiş yazıcısının USB info'sunu makul label defaults ile birleştirip
  /// `LabelPrintService` ile gönderir (aynı paket, aynı ESC/POS driver).
  ///
  /// POSA gibi termal cihazlar (80mm rulo) hem fiş hem barkod basabilir.
  ///
  /// Returns detailed result so the caller can surface the real error
  /// instead of falling silently to the PDF dialog (which spawns the
  /// system default printer — typically a virtual PDF printer that
  /// confuses users).
  Future<({bool success, String? error})> _printViaReceiptPrinterFallback({
    required PrintSettings receiptSettings,
    required Map<String, dynamic> product,
    required _VariantPrint variant,
    required bool showName,
    required bool showPrice,
    required bool showSku,
    required int quantity,
    required String codeType,
  }) async {
    final type = codeType == 'QR'
        ? LabelCodeType.qr
        : LabelCodeType.code128;
    // Fiş yazıcısı ID'si + makul label default'ları
    final fallbackSettings = LabelPrinterSettings(
      vendorId: receiptSettings.vendorId,
      productId: receiptSettings.productId,
      deviceName: receiptSettings.deviceName,
      labelWidthMm: receiptSettings.paperWidth.mm,  // 58 veya 80
      labelHeightMm: 25,                            // termal rulo için makul
      defaultCodeType: type,
      autoCutAfterEach: true,
      showProductName: showName,
      showSku: showSku,
      showPrice: showPrice,
    );
    final fallbackService = LabelPrintService(fallbackSettings);
    try {
      for (int i = 0; i < quantity; i++) {
        final result = await fallbackService.printBarcodeLabel(
          value: variant.barcodeValue,
          productName: showName ? product['name']?.toString() : null,
          sku: showSku ? variant.sku : null,
          price: showPrice ? variant.price : null,
          codeType: type,
        );
        if (!result.success) {
          return (success: false, error: result.error ?? 'Bilinmeyen yazıcı hatası');
        }
      }
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Sprint 29-fix-6: _printViaPdfDialog metodu tamamen KALDIRILDI.
  //
  // Sebep: Sistemde PDF print akışı kullanılmıyor. Eski Case 3 fallback
  // Windows default sistem yazıcısına (sanal PDF: Microsoft Print to PDF,
  // FeedMe POS Print Job, vb.) yönlendiriyordu — termal POSA cihaz PDF
  // basamadığı için kullanıcı şaşırıyordu.
  //
  // Etiket basma artık SADECE USB ESC/POS:
  //   Case 1   : labelPrintSettings.isConfigured → ESC/POS direkt
  //   Case 1.5 : printSettings (fiş yazıcısı) → POSA reuse
  //   ELSE     : Açık hata toast + Ayar ekranına yönlendirme
  //
  // pdf/printing import'ları da kaldırıldı (statement_pdf_service.dart hâlâ
  // kullanıyor — pubspec.yaml'da paket kalır). Eski kod git history'de.

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

  // ─── STOCK ADJUST DIALOG ─────────────────────────────────────────────────

  void _showStockAdjustDialog() {
    final variantId = _firstVariantId;
    if (variantId == null || _product == null) {
      AppToast.warning(context, t('common.not_found'));
      return;
    }
    final productId = _product!['id']?.toString() ?? '';
    final qtyCtrl   = TextEditingController(text: '1');
    final noteCtrl  = TextEditingController();
    bool isIn   = true;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.tune, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(t('stock.adjust'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hareket türü ────────────────────────────────
                Text(t('stock.movement_type'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDlg(() => isIn = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isIn
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.bgLight,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: isIn ? AppColors.success : AppColors.border,
                                width: isIn ? 1.5 : 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: 16,
                                  color: isIn ? AppColors.success : AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(t('stock.entry'),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isIn
                                          ? AppColors.success
                                          : AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDlg(() => isIn = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: !isIn
                                ? AppColors.danger.withValues(alpha: 0.1)
                                : AppColors.bgLight,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: !isIn ? AppColors.danger : AppColors.border,
                                width: !isIn ? 1.5 : 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_circle_outline,
                                  size: 16,
                                  color: !isIn ? AppColors.danger : AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(t('stock.exit'),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: !isIn
                                          ? AppColors.danger
                                          : AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Miktar ──────────────────────────────────────
                Text(t('stock.quantity'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '1',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1.5)),
                    filled: true,
                    fillColor: AppColors.bgLight,
                  ),
                ),
                const SizedBox(height: 14),
                // ── Not ─────────────────────────────────────────
                Text(t('common.note'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: t('stock.adjustment'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1.5)),
                    filled: true,
                    fillColor: AppColors.bgLight,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t('common.cancel')),
            ),
            saving
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                      if (qty <= 0) return;
                      setDlg(() => saving = true);
                      try {
                        await ref.read(stockServiceProvider).createStockMovement({
                          'variantId': variantId,
                          'productId': productId,
                          'quantity': qty,
                          'movementType':
                              isIn ? 'ADJUSTMENT_IN' : 'ADJUSTMENT_OUT',
                          if (noteCtrl.text.trim().isNotEmpty)
                            'notes': noteCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          AppToast.success(context, t('common.saved'));
                          _loadProduct();
                          _loadMovements();
                        }
                      } catch (e) {
                        setDlg(() => saving = false);
                        if (ctx.mounted) AppToast.error(ctx, t('common.error'));
                      }
                    },
                    child: Text(t('common.save'),
                        style: const TextStyle(color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }

  // ─── ADD OEM DIALOG ───────────────────────────────────────────────────────

  void _showAddOemDialog() {
    final variantId = _firstVariantId;
    if (variantId == null) {
      AppToast.warning(context, t('common.not_found'));
      return;
    }
    final oemCtrl = TextEditingController();
    final mfrCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.confirmation_number, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(t('product.add_oem'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('product.oem_no'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: oemCtrl,
                  decoration: InputDecoration(
                    hintText: 'OEM-123456',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1.5)),
                    filled: true,
                    fillColor: AppColors.bgLight,
                  ),
                ),
                const SizedBox(height: 14),
                Text(t('product.manufacturer'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: mfrCtrl,
                  decoration: InputDecoration(
                    hintText: 'Bosch, NGK...',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1.5)),
                    filled: true,
                    fillColor: AppColors.bgLight,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t('common.cancel')),
            ),
            saving
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      final oemNum = oemCtrl.text.trim();
                      if (oemNum.isEmpty) return;
                      setDlg(() => saving = true);
                      try {
                        await ref.read(oemServiceProvider).create({
                          'variantId': variantId,
                          'oemNumber': oemNum,
                          if (mfrCtrl.text.trim().isNotEmpty)
                            'manufacturer': mfrCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          AppToast.success(context, t('common.saved'));
                          // OEM listesini yenile
                          setState(() => _oemLoading = true);
                          try {
                            final oems = await ref
                                .read(oemServiceProvider)
                                .getByVariantId(variantId);
                            setState(() {
                              _oemNumbers = oems;
                              _oemLoading = false;
                            });
                          } catch (_) {
                            setState(() => _oemLoading = false);
                          }
                        }
                      } catch (e) {
                        setDlg(() => saving = false);
                        if (ctx.mounted) AppToast.error(ctx, t('common.error'));
                      }
                    },
                    child: Text(t('common.add'),
                        style: const TextStyle(color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }

  // ─── ADD CROSS REFERENCE DIALOG ───────────────────────────────────────────

  void _showAddCrossReferenceDialog() {
    final variantId = _firstVariantId;
    if (variantId == null) {
      AppToast.warning(context, t('common.not_found'));
      return;
    }
    final refCtrl   = TextEditingController();
    final brandCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz, size: 20, color: AppColors.info),
              const SizedBox(width: 8),
              Text(t('product.add_cross_ref'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('product.ref_code'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(
                    hintText: 'CR-123456',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1.5)),
                    filled: true,
                    fillColor: AppColors.bgLight,
                  ),
                ),
                const SizedBox(height: 14),
                Text(t('product.brand'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: brandCtrl,
                  decoration: InputDecoration(
                    hintText: 'Bosch, Mann...',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1.5)),
                    filled: true,
                    fillColor: AppColors.bgLight,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t('common.cancel')),
            ),
            saving
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      final refNum = refCtrl.text.trim();
                      if (refNum.isEmpty) return;
                      setDlg(() => saving = true);
                      try {
                        await ref.read(crossReferenceServiceProvider).create({
                          'variantId': variantId,
                          'crossRefNumber': refNum,
                          if (brandCtrl.text.trim().isNotEmpty)
                            'crossRefBrand': brandCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          AppToast.success(context, t('common.saved'));
                          // Cross ref listesini yenile
                          setState(() => _crossRefLoading = true);
                          try {
                            final crossRefs = await ref
                                .read(crossReferenceServiceProvider)
                                .getByVariantId(variantId);
                            setState(() {
                              _crossRefs = crossRefs;
                              _crossRefLoading = false;
                            });
                          } catch (_) {
                            setState(() => _crossRefLoading = false);
                          }
                        }
                      } catch (e) {
                        setDlg(() => saving = false);
                        if (ctx.mounted) AppToast.error(ctx, t('common.error'));
                      }
                    },
                    child: Text(t('common.add'),
                        style: const TextStyle(color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
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

// ── Varyant yazdırma modeli ───────────────────────────────────────────────────
class _VariantPrint {
  final String variantId;
  final String variantName;
  final String barcodeValue;  // gerçek barkod yoksa SKU fallback
  final bool   hasBarcodeReal;
  final double price;
  final String sku;

  const _VariantPrint({
    required this.variantId,
    required this.variantName,
    required this.barcodeValue,
    required this.hasBarcodeReal,
    required this.price,
    required this.sku,
  });
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

// ── QR code preview painter ───────────────────────────────────────────────────
// Draws a realistic-looking QR code preview with correct finder patterns and
// a deterministic pseudo-random data area. Not a real QR encoding —
// for preview only. Actual scannable QR is generated by pw.Barcode.qrCode().
class _QrPreviewPainter extends CustomPainter {
  final String data;
  const _QrPreviewPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    const n = 21; // QR Version 1 = 21×21 modül
    final c = size.width / n;

    // ── Finder pattern (köşe işaret karesi 7×7) ──────────────────────────
    void drawFinder(int startRow, int startCol) {
      for (int r = 0; r < 7; r++) {
        for (int col = 0; col < 7; col++) {
          final onOuter = r == 0 || r == 6 || col == 0 || col == 6;
          final onInner = r >= 2 && r <= 4 && col >= 2 && col <= 4;
          if (onOuter || onInner) {
            canvas.drawRect(
              Rect.fromLTWH(
                  (startCol + col) * c, (startRow + r) * c, c - 0.4, c - 0.4),
              paint,
            );
          }
        }
      }
    }

    drawFinder(0, 0);      // sol üst
    drawFinder(0, n - 7);  // sağ üst
    drawFinder(n - 7, 0);  // sol alt

    // ── Zamanlama çizgileri (6. satır / sütun) ────────────────────────────
    for (int i = 8; i < n - 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(i * c, 6 * c, c - 0.4, c - 0.4), paint);
        canvas.drawRect(Rect.fromLTWH(6 * c, i * c, c - 0.4, c - 0.4), paint);
      }
    }

    // ── Veri modülleri (deterministic pseudo-random) ──────────────────────
    int s = data.hashCode.abs();
    for (int r = 0; r < n; r++) {
      for (int col = 0; col < n; col++) {
        // finder pattern ve separator alanlarını atla
        if (r < 8 && col < 8) continue;
        if (r < 8 && col >= n - 8) continue;
        if (r >= n - 8 && col < 8) continue;
        if (r == 6 || col == 6) continue; // timing
        s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
        if ((s >> 16) & 1 == 1) {
          canvas.drawRect(
              Rect.fromLTWH(col * c, r * c, c - 0.4, c - 0.4), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPreviewPainter old) => old.data != data;
}