import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import '../../providers/sector_provider.dart';
import '../../core/config/sector_config.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

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

  late TabController _tabController;

  // OEM tab state
  List<Map<String, dynamic>> _oemNumbers = [];
  bool _oemLoading = false;

  // Cross reference tab state
  List<Map<String, dynamic>> _crossRefs = [];
  bool _crossRefLoading = false;

  // Vehicle compatibility tab state
  List<Map<String, dynamic>> _vehicleCompats = [];
  bool _vehicleCompatLoading = false;

  // History tab state
  List<Map<String, dynamic>> _movements = [];
  bool _movementsLoading = false;
  String? _movementFilter;

  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');
  final _currFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  // Dynamic tabs
  late List<_TabDef> _tabs;

  @override
  void initState() {
    super.initState();
    _buildTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      final tab = _tabs[_tabController.index];
      if (tab.type == _TabType.history &&
          _movements.isEmpty &&
          !_movementsLoading) {
        _loadMovements();
      }
    });
    _loadProduct();
  }

  void _buildTabs() {
    final cfg = ref.read(sectorConfigProvider);
    _tabs = [
      _TabDef(_TabType.general, t('common.general_info'), Icons.info_outlined),
    ];

    if (cfg.fields.showOem) {
      _tabs.add(_TabDef(
          _TabType.oem, cfg.labels.oemField, Icons.confirmation_number));
    }

    if (cfg.fields.showCrossRef) {
      _tabs.add(_TabDef(
          _TabType.crossRef, t('product.cross_references'), Icons.swap_horiz));
    }

    if (cfg.fields.showVehicleCompat) {
      _tabs.add(_TabDef(_TabType.vehicleCompat,
          t('product.vehicle_compatibility'), Icons.directions_car));
    }

    // History tab - always visible
    _tabs.add(
        _TabDef(_TabType.history, t('product.history'), Icons.history));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final product = await ref
          .read(productServiceProvider)
          .getProductById(widget.productId);
      if (product.isEmpty) {
        setState(() {
          _error = t('common.not_found');
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _product = product;
        _isLoading = false;
      });
      _loadTabData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String? get _firstVariantId {
    final variants =
        (_product?['variants'] as List?)?.cast<Map<String, dynamic>>();
    if (variants != null && variants.isNotEmpty) {
      return variants.first['id']?.toString();
    }
    return null;
  }

  List<Map<String, dynamic>> get _allVariants =>
      (_product?['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  Future<void> _loadTabData() async {
    final variantId = _firstVariantId;
    if (variantId == null) return;
    final cfg = ref.read(sectorConfigProvider);

    // OEM
    if (cfg.fields.showOem) {
      setState(() => _oemLoading = true);
      try {
        final oems =
            await ref.read(oemServiceProvider).getByVariantId(variantId);
        setState(() {
          _oemNumbers = oems;
          _oemLoading = false;
        });
      } catch (_) {
        setState(() => _oemLoading = false);
      }
    }

    // Cross refs
    if (cfg.fields.showCrossRef) {
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

    // Vehicle compat
    if (cfg.fields.showVehicleCompat) {
      setState(() => _vehicleCompatLoading = true);
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient
            .get('product/api/vehicle-compatibility/variant/$variantId');
        final data = response.data['data'];
        if (data is List) {
          setState(() {
            _vehicleCompats = data.cast<Map<String, dynamic>>();
            _vehicleCompatLoading = false;
          });
        } else {
          setState(() => _vehicleCompatLoading = false);
        }
      } catch (_) {
        setState(() => _vehicleCompatLoading = false);
      }
    }
  }

  Future<void> _loadMovements() async {
    final variantId = _firstVariantId;
    if (variantId == null) return;
    setState(() => _movementsLoading = true);
    try {
      final movements =
          await ref.read(stockServiceProvider).getVariantMovements(variantId);
      setState(() {
        _movements = movements;
        _movementsLoading = false;
      });
    } catch (_) {
      setState(() => _movementsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(sectorConfigProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppAppBar.standard(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/inventory/products'),
          ),
          title: t('common.detail'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_error ?? t('common.error'),
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadProduct, child: Text(t('common.retry'))),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final productName = product['name']?.toString() ?? cfg.labels.productName;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/inventory/products'),
        ),
        title: productName,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: t('common.refresh'),
            onPressed: () {
              _loadProduct();
              final currentTab = _tabs[_tabController.index];
              if (currentTab.type == _TabType.history) _loadMovements();
            },
          ),
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/inventory/add-product?edit=${_product!['id']}'),
            icon: const Icon(Icons.edit, size: 18),
            label: Text(t('common.edit')),
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
            case _TabType.general:
              return _buildGeneralInfoTab(product, cfg);
            case _TabType.oem:
              return _buildOemTab();
            case _TabType.crossRef:
              return _buildCrossRefTab();
            case _TabType.vehicleCompat:
              return _buildVehicleCompatTab();
            case _TabType.history:
              return _buildHistoryTab();
          }
        }).toList(),
      ),
    );
  }

  // ─── Tab 1: Genel Bilgi ───────────────────────────────────────────────────

  Widget _buildGeneralInfoTab(
      Map<String, dynamic> product, SectorConfig cfg) {
    final variants = (product['variants'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final status = product['status']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image + info card
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                if (status != null && status != 'ACTIVE')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppBadge(
                      text: _getStatusLabel(status),
                      variant: _getStatusBadgeVariant(status),
                    ),
                  ),
                Text(
                  product['name']?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text('SKU: ${product['sku'] ?? '-'}',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                if (product['barcode'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                      '${cfg.labels.barcodeLabel}: ${product['barcode']}',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (cfg.fields.showBrand)
                      _buildInfoChip(
                          t('product.brand'),
                          product['brand']?.toString() ?? '-',
                          Icons.local_offer_outlined),
                    if (cfg.fields.showBrand) const SizedBox(width: 12),
                    _buildInfoChip(
                        cfg.labels.categoryName,
                        product['categoryId']?.toString() ?? '-',
                        Icons.category_outlined),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatItem(
                            cfg.labels.salePriceLabel,
                            _currFmt.format(product['basePrice'] ?? 0),
                            Icons.attach_money,
                            AppColors.primary)),
                    Expanded(
                        child: _buildStatItem(
                            t('stock.stock'),
                            '${product['stock'] ?? 0}',
                            Icons.inventory_2_outlined,
                            AppColors.success)),
                    Expanded(
                        child: _buildStatItem(
                            t('common.status'),
                            _getStatusLabel(
                                status ?? 'ACTIVE'),
                            Icons.circle,
                            _getStatusColor(status ?? 'ACTIVE'))),
                  ],
                ),
              ],
            ),
          ),

          // Description
          if (product['description'] != null &&
              product['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('product.description'),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text(product['description'].toString(),
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6)),
                ],
              ),
            ),
          ],

          // Sector-specific fields
          if (cfg.fields.showWarranty &&
              product['warrantyPeriod'] != null) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppColors.success),
                  const SizedBox(width: 12),
                  Text(
                      '${cfg.labels.variantField}: ${product['warrantyPeriod']}',
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],

          if (cfg.fields.showImei && product['imei'] != null) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_outlined,
                      color: AppColors.info),
                  const SizedBox(width: 12),
                  Text('IMEI: ${product['imei']}',
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],

          if (cfg.fields.showShelf &&
              product['shelfCode'] != null &&
              product['shelfCode'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.shelves, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Text(
                      '${cfg.labels.shelfField}: ${product['shelfCode']}',
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],

          // Variants
          if (variants.length > 1) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t('product.variants')} (${variants.length})',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
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
    final inventory = variant['inventory'] as Map<String, dynamic>? ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppConstants.pagePadding,
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      variant['name']?.toString() ??
                          variant['sku']?.toString() ??
                          '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('SKU: ${variant['sku'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (cfg.fields.showVariantSize &&
                      variant['size'] != null)
                    Text(
                        '${cfg.labels.variantField}: ${variant['size']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  if (cfg.fields.showVariantColor &&
                      variant['color'] != null)
                    Text('${t('product.color')}: ${variant['color']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ],
              )),
          Expanded(
              flex: 2,
              child: Text(
                  '${cfg.labels.salePriceLabel}: ${variant['salePrice'] ?? '-'} ₺',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500))),
          Expanded(
              child: Text(
                  '${t('stock.stock')}: ${inventory['physicalQuantity'] ?? 0}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ─── Tab: OEM Numaralar ──────────────────────────────────────────────────

  Widget _buildOemTab() {
    final cfg = ref.watch(sectorConfigProvider);
    if (_oemLoading) return const Center(child: CircularProgressIndicator());
    if (_firstVariantId == null) {
      return Center(
          child: Text(t('common.no_result'),
              style: const TextStyle(color: AppColors.textMuted)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cfg.labels.oemField} (${_oemNumbers.length})',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: _showAddOemDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(t('common.add')),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _oemNumbers.isEmpty
              ? Center(
                  child: Text(t('common.no_result'),
                      style:
                          const TextStyle(color: AppColors.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _oemNumbers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final oem = _oemNumbers[index];
                    final isPrimary = oem['isPrimary'] == true;
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppConstants.borderRadiusSmall,
                        side: BorderSide(
                            color: isPrimary
                                ? AppColors.warning
                                : AppColors.border),
                      ),
                      child: ListTile(
                        leading: isPrimary
                            ? const Icon(Icons.star,
                                color: AppColors.warning, size: 24)
                            : const Icon(Icons.tag,
                                color: AppColors.textMuted, size: 24),
                        title: Text(oem['oemNumber']?.toString() ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        subtitle: Text(
                            oem['manufacturer']?.toString() ?? '-',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        trailing: isPrimary
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withOpacity(0.1),
                                  borderRadius:
                                      AppConstants.borderRadiusSmall,
                                ),
                                child: Text(t('product.primary'),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.warning)),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Tab: Çapraz Referans ────────────────────────────────────────────────

  Widget _buildCrossRefTab() {
    if (_crossRefLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_firstVariantId == null) {
      return Center(
          child: Text(t('common.no_result'),
              style: const TextStyle(color: AppColors.textMuted)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${t('product.cross_references')} (${_crossRefs.length})',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: _showAddCrossReferenceDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(t('common.add')),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _crossRefs.isEmpty
              ? Center(
                  child: Text(t('common.no_result'),
                      style:
                          const TextStyle(color: AppColors.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _crossRefs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cr = _crossRefs[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: AppConstants.borderRadiusSmall,
                          side: const BorderSide(color: AppColors.border)),
                      child: ListTile(
                        leading: const Icon(Icons.swap_horiz,
                            color: AppColors.info, size: 24),
                        title: Text(
                            cr['crossRefNumber']?.toString() ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        subtitle: Text(
                            cr['crossRefBrand']?.toString() ?? '-',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        trailing: cr['notes'] != null &&
                                cr['notes'].toString().isNotEmpty
                            ? Tooltip(
                                message: cr['notes'].toString(),
                                child: const Icon(Icons.info_outline,
                                    color: AppColors.textMuted, size: 20))
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Tab: Araç Uyumluluğu ────────────────────────────────────────────────

  Widget _buildVehicleCompatTab() {
    if (_vehicleCompatLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${t('product.vehicle_compatibility')} (${_vehicleCompats.length})',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
        Expanded(
          child: _vehicleCompats.isEmpty
              ? Center(
                  child: Text(t('common.no_result'),
                      style:
                          const TextStyle(color: AppColors.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _vehicleCompats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final vc = _vehicleCompats[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: AppConstants.borderRadiusSmall,
                          side: const BorderSide(color: AppColors.border)),
                      child: ListTile(
                        leading: const Icon(Icons.directions_car,
                            color: AppColors.primary, size: 24),
                        title: Text(
                            '${vc['make'] ?? ''} ${vc['model'] ?? ''} ${vc['engine'] ?? ''}'
                                .trim(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        subtitle: Text(
                            '${t('product.year')}: ${vc['yearStart'] ?? ''} - ${vc['yearEnd'] ?? t('common.current')}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Tab: Geçmiş ─────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    final product = _product!;
    final totalStock = (product['stock'] as num?)?.toInt() ?? 0;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    int soldThisMonth = 0;
    int purchasedThisMonth = 0;
    int returnedThisMonth = 0;
    DateTime? lastMovementDate;

    for (final mv in _movements) {
      final dateStr = mv['createTime']?.toString();
      DateTime? date;
      if (dateStr != null) date = DateTime.tryParse(dateStr);
      if (date != null) {
        if (lastMovementDate == null || date.isAfter(lastMovementDate)) {
          lastMovementDate = date;
        }
        if (!date.isBefore(monthStart)) {
          final type = mv['movementType']?.toString() ?? '';
          if (type == 'SALE_OUT') {
            soldThisMonth += (mv['quantity'] as num?)?.toInt() ?? 0;
          }
          if (type == 'PURCHASE_IN') {
            purchasedThisMonth += (mv['quantity'] as num?)?.toInt() ?? 0;
          }
          if (type == 'SALE_RETURN_IN') {
            returnedThisMonth += (mv['quantity'] as num?)?.toInt() ?? 0;
          }
        }
      }
    }

    final filtered = _movementFilter == null
        ? _movements
        : _movements.where((mv) {
            final type = mv['movementType']?.toString() ?? '';
            switch (_movementFilter) {
              case 'SALE':
                return type == 'SALE_OUT' || type == 'SALE_CANCEL_IN';
              case 'PURCHASE':
                return type == 'PURCHASE_IN' ||
                    type == 'PURCHASE_RETURN_OUT';
              case 'RETURN':
                return type == 'SALE_RETURN_IN';
              case 'TRANSFER':
                return type == 'TRANSFER_IN' || type == 'TRANSFER_OUT';
              case 'ADJUSTMENT':
                return type == 'ADJUSTMENT_IN' ||
                    type == 'ADJUSTMENT_OUT';
              default:
                return true;
            }
          }).toList();

    return Column(
      children: [
        // Quick actions
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
                bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.4))),
          ),
          child: Row(
            children: [
              Expanded(
                  child: _quickActionBtn(
                icon: Icons.tune_rounded,
                label: t('stock.adjust'),
                color: AppColors.primary,
                onTap: () => _showStockAdjustDialog(),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _quickActionBtn(
                icon: Icons.swap_horiz_rounded,
                label: t('stock.transfer'),
                color: Colors.indigo,
                onTap: () => context.push('/stock/transfer'),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _quickActionBtn(
                icon: Icons.receipt_long_outlined,
                label: t('sales.view_sales'),
                color: Colors.teal,
                onTap: () => context.push('/sales'),
              )),
            ],
          ),
        ),

        // Stats
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
          child: Row(
            children: [
              Expanded(
                  child: _statCard(
                      '${t('stock.current_stock')}\n',
                      '$totalStock ${t('product.unit_piece')}',
                      totalStock <= 0
                          ? Colors.red
                          : (totalStock < 5 ? Colors.orange : Colors.green))),
              const SizedBox(width: 8),
              Expanded(
                  child: _statCard(
                      '${t('stock.monthly_sales')}\n',
                      '$soldThisMonth ${t('product.unit_piece')}',
                      Colors.red)),
              const SizedBox(width: 8),
              Expanded(
                  child: _statCard(
                      '${t('stock.monthly_purchase')}\n',
                      '$purchasedThisMonth ${t('product.unit_piece')}',
                      Colors.green)),
              const SizedBox(width: 8),
              Expanded(
                  child: _statCard(
                      '${t('stock.monthly_return')}\n',
                      '$returnedThisMonth ${t('product.unit_piece')}',
                      Colors.orange)),
            ],
          ),
        ),

        // Last movement
        if (lastMovementDate != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.2),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    size: 13,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${t('stock.last_movement')}: ${_dateTimeFmt.format(lastMovementDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant),
                ),
              ],
            ),
          ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              _mvFilterChip(
                  t('common.all'), null, Icons.list_rounded),
              const SizedBox(width: 6),
              _mvFilterChip(t('sales.sale'), 'SALE',
                  Icons.point_of_sale_rounded),
              const SizedBox(width: 6),
              _mvFilterChip(t('stock.purchase'), 'PURCHASE',
                  Icons.shopping_cart_rounded),
              const SizedBox(width: 6),
              _mvFilterChip(t('sales.return'), 'RETURN',
                  Icons.assignment_return_outlined),
              const SizedBox(width: 6),
              _mvFilterChip(t('stock.transfer'), 'TRANSFER',
                  Icons.swap_horiz_rounded),
              const SizedBox(width: 6),
              _mvFilterChip(t('stock.adjustment'), 'ADJUSTMENT',
                  Icons.build_outlined),
              const SizedBox(width: 6),
              Text(
                '${filtered.length} ${t('common.record')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // Movement list
        Expanded(
          child: _movementsLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? AppEmptyState(
                      icon: Icons.history_toggle_off_outlined,
                      title: _movements.isEmpty
                          ? t('stock.no_movements')
                          : t('common.no_result'),
                      actionText: _movements.isEmpty
                          ? t('common.refresh')
                          : null,
                      onAction: _movements.isEmpty
                          ? _loadMovements
                          : null,
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _buildMovementCard(filtered[i]),
                    ),
        ),
      ],
    );
  }

  Widget _quickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: AppConstants.borderRadiusMedium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppConstants.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  height: 1.3),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _mvFilterChip(String label, String? value, IconData icon) {
    final selected = _movementFilter == value;
    return FilterChip(
      avatar: Icon(icon,
          size: 14,
          color: selected ? AppColors.primary : AppColors.textMuted),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _movementFilter = value),
      selectedColor: AppColors.primary.withOpacity(0.12),
      checkmarkColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildMovementCard(Map<String, dynamic> mv) {
    final type = mv['movementType']?.toString() ?? '';
    final qty = (mv['quantity'] as num?)?.toInt() ?? 0;
    final dateStr = mv['createTime']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final unitPrice = (mv['unitPrice'] as num?)?.toDouble();
    final saleNo = mv['saleNumber']?.toString();
    final purchaseNo = mv['purchaseNumber']?.toString();
    final user = mv['createUser']?.toString();
    final storeId = mv['storeId']?.toString();
    final warehouseId = mv['warehouseId']?.toString();

    final cfg = _movementConfig(type);
    final isIn = cfg['isIn'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusMedium,
        side: BorderSide(
          color: (cfg['color'] as Color).withOpacity(0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (cfg['color'] as Color).withOpacity(0.1),
                borderRadius: AppConstants.borderRadiusMedium,
              ),
              child: Icon(cfg['icon'] as IconData,
                  color: cfg['color'] as Color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              (cfg['color'] as Color).withOpacity(0.12),
                          borderRadius: AppConstants.borderRadiusSmall,
                        ),
                        child: Text(cfg['label'] as String,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cfg['color'] as Color)),
                      ),
                      if (saleNo != null) ...[
                        const SizedBox(width: 6),
                        Text('#$saleNo',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ] else if (purchaseNo != null) ...[
                        const SizedBox(width: 6),
                        Text('#$purchaseNo',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (date != null)
                    Text(_dateTimeFmt.format(date),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  if (storeId != null || warehouseId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (storeId != null && storeId.isNotEmpty)
                          '${t('stock.store')}: $storeId',
                        if (warehouseId != null &&
                            warehouseId.isNotEmpty)
                          '${t('stock.warehouse')}: $warehouseId',
                      ].join('  ·  '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                  if (user != null && user != 'syste') ...[
                    const SizedBox(height: 2),
                    Text('${t('common.user')}: $user',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIn
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  child: Text(
                    '${isIn ? "+" : "-"}$qty ${t('product.unit_piece')}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isIn ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                if (unitPrice != null && unitPrice > 0) ...[
                  const SizedBox(height: 4),
                  Text(_currFmt.format(unitPrice),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _movementConfig(String type) {
    switch (type) {
      case 'PURCHASE_IN':
        return {
          'label': t('stock.purchase_in'),
          'icon': Icons.shopping_cart_rounded,
          'color': Colors.green,
          'isIn': true
        };
      case 'PURCHASE_RETURN_OUT':
        return {
          'label': t('stock.purchase_return'),
          'icon': Icons.keyboard_return_rounded,
          'color': Colors.deepOrange,
          'isIn': false
        };
      case 'SALE_OUT':
        return {
          'label': t('sales.sale'),
          'icon': Icons.point_of_sale_rounded,
          'color': Colors.red,
          'isIn': false
        };
      case 'SALE_RETURN_IN':
        return {
          'label': t('sales.customer_return'),
          'icon': Icons.assignment_return_outlined,
          'color': Colors.orange,
          'isIn': true
        };
      case 'SALE_CANCEL_IN':
        return {
          'label': t('sales.sale_cancel'),
          'icon': Icons.cancel_outlined,
          'color': Colors.purple,
          'isIn': true
        };
      case 'TRANSFER_IN':
        return {
          'label': t('stock.transfer_in'),
          'icon': Icons.arrow_downward_rounded,
          'color': Colors.indigo,
          'isIn': true
        };
      case 'TRANSFER_OUT':
        return {
          'label': t('stock.transfer_out'),
          'icon': Icons.arrow_upward_rounded,
          'color': Colors.indigo,
          'isIn': false
        };
      case 'ADJUSTMENT_IN':
        return {
          'label': '${t('stock.adjustment')} (+)',
          'icon': Icons.add_circle_outline,
          'color': Colors.teal,
          'isIn': true
        };
      case 'ADJUSTMENT_OUT':
        return {
          'label': '${t('stock.adjustment')} (-)',
          'icon': Icons.remove_circle_outline,
          'color': Colors.teal,
          'isIn': false
        };
      default:
        return {
          'label': type,
          'icon': Icons.swap_vert_rounded,
          'color': AppColors.textMuted,
          'isIn': true
        };
    }
  }

  // ─── Stok Düzeltme Dialog ────────────────────────────────────────────────

  void _showStockAdjustDialog() {
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String direction = 'ADJUSTMENT_IN';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(t('stock.adjust')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                        '${_product?['name'] ?? ''}\n'
                        '${t('stock.current_stock')}: ${_product?['stock'] ?? 0} ${t('product.unit_piece')}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _dirBtn(
                      ctx: ctx,
                      setD: setD,
                      label: '+ ${t('stock.entry')}',
                      value: 'ADJUSTMENT_IN',
                      current: direction,
                      color: Colors.green,
                      onSelect: (v) => direction = v,
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _dirBtn(
                      ctx: ctx,
                      setD: setD,
                      label: '- ${t('stock.exit')}',
                      value: 'ADJUSTMENT_OUT',
                      current: direction,
                      color: Colors.red,
                      onSelect: (v) => direction = v,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${t('stock.quantity')} *',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return t('validation.required');
                    }
                    if (int.tryParse(v) == null || int.parse(v) <= 0) {
                      return t('validation.invalid');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: t('common.note'),
                    border: const OutlineInputBorder(),
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
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final variantId = _firstVariantId;
                if (variantId == null) return;
                try {
                  await ref
                      .read(stockServiceProvider)
                      .createStockMovement({
                    'variantId': variantId,
                    'storeId': '',
                    'warehouseId': '',
                    'movementType': direction,
                    'quantity': int.parse(qtyCtrl.text.trim()),
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _loadProduct();
                  _loadMovements();
                  if (mounted) {
                    AppToast.success(context, t('common.success'));
                  }
                } catch (e) {
                  if (mounted) {
                    AppToast.error(context, t('common.error'));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: Text(t('common.save')),
            ),
          ],
        ),
      ),
    ).then((_) {
      qtyCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  Widget _dirBtn({
    required BuildContext ctx,
    required StateSetter setD,
    required String label,
    required String value,
    required String current,
    required Color color,
    required Function(String) onSelect,
  }) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => setD(() => onSelect(value)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: AppConstants.borderRadiusSmall,
          border:
              Border.all(color: selected ? color : AppColors.border, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textMuted)),
        ),
      ),
    );
  }

  // ─── OEM / Cross Ref Dialogs ─────────────────────────────────────────────

  void _showAddOemDialog() {
    final cfg = ref.read(sectorConfigProvider);
    final oemController = TextEditingController();
    final manufacturerController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${cfg.labels.oemField} ${t('common.add')}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oemController,
                decoration: InputDecoration(
                    labelText: '${cfg.labels.oemField} *',
                    border: const OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? t('validation.required')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: manufacturerController,
                decoration: InputDecoration(
                    labelText: t('product.manufacturer'),
                    border: const OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final variantId = _firstVariantId;
              if (variantId == null) return;
              try {
                await ref.read(oemServiceProvider).create({
                  'variantId': int.tryParse(variantId) ?? variantId,
                  'oemNumber': oemController.text.trim(),
                  'manufacturer': manufacturerController.text.trim(),
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadTabData();
              } catch (e) {
                if (mounted) AppToast.error(context, t('common.error'));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white),
            child: Text(t('common.save')),
          ),
        ],
      ),
    ).then((_) {
      oemController.dispose();
      manufacturerController.dispose();
    });
  }

  void _showAddCrossReferenceDialog() {
    final codeController = TextEditingController();
    final brandController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${t('product.cross_references')} ${t('common.add')}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeController,
                decoration: InputDecoration(
                    labelText: '${t('product.ref_code')} *',
                    border: const OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? t('validation.required')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: brandController,
                decoration: InputDecoration(
                    labelText: t('product.brand'),
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                    labelText: t('common.note'),
                    border: const OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final variantId = _firstVariantId;
              if (variantId == null) return;
              try {
                await ref.read(crossReferenceServiceProvider).create({
                  'variantId': int.tryParse(variantId) ?? variantId,
                  'crossRefNumber': codeController.text.trim(),
                  'crossRefBrand': brandController.text.trim(),
                  'notes': notesController.text.trim(),
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadTabData();
              } catch (e) {
                if (mounted) AppToast.error(context, t('common.error'));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white),
            child: Text(t('common.save')),
          ),
        ],
      ),
    ).then((_) {
      codeController.dispose();
      brandController.dispose();
      notesController.dispose();
    });
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'DRAFT':
        return t('product.status_draft');
      case 'ACTIVE':
        return t('product.status_active');
      case 'INACTIVE':
        return t('product.status_inactive');
      case 'OUT_OF_STOCK':
        return t('stock.out_of_stock');
      default:
        return status ?? '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'DRAFT':
        return AppColors.warning;
      case 'ACTIVE':
        return AppColors.success;
      case 'INACTIVE':
        return AppColors.textMuted;
      case 'OUT_OF_STOCK':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  BadgeVariant _getStatusBadgeVariant(String? status) {
    switch (status) {
      case 'DRAFT':
        return BadgeVariant.warning;
      case 'ACTIVE':
        return BadgeVariant.success;
      case 'INACTIVE':
        return BadgeVariant.secondary;
      case 'OUT_OF_STOCK':
        return BadgeVariant.danger;
      default:
        return BadgeVariant.secondary;
    }
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMedium),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Tab Definition ──────────────────────────────────────────────────────────

enum _TabType { general, oem, crossRef, vehicleCompat, history }

class _TabDef {
  final _TabType type;
  final String label;
  final IconData icon;

  const _TabDef(this.type, this.label, this.icon);
}
