import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import '../../providers/sector_provider.dart';
import '../../core/config/sector_config.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../admin/product_relationship_management_panel.dart';

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
          OutlinedButton.icon(
            onPressed: () => context.push('/inventory/add-product?edit=${product['id']}'),
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
    final variants = (product['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final status = product['status']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status != null && status != 'ACTIVE')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppBadge(text: _getStatusLabel(status), variant: _getStatusBadgeVariant(status)),
                  ),
                Text(product['name']?.toString() ?? '-', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('SKU: ${product['sku'] ?? '-'}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                if (product['barcode'] != null) ...[
                  const SizedBox(height: 4),
                  Text('${cfg.labels.barcodeLabel}: ${product['barcode']}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (cfg.fields.showBrand)
                      _buildInfoChip(t('product.brand'), product['brand']?.toString() ?? '-', Icons.local_offer_outlined),
                    if (cfg.fields.showBrand) const SizedBox(width: 12),
                    _buildInfoChip(cfg.labels.categoryName, product['categoryName']?.toString() ?? '-', Icons.category_outlined),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatItem(cfg.labels.salePriceLabel, _currFmt.format(product['basePrice'] ?? 0), Icons.attach_money, AppColors.primary),
                    _buildStatItem(t('stock.stock'), '${product['stock'] ?? 0}', Icons.inventory_2_outlined, AppColors.success),
                    _buildStatItem(t('common.status'), _getStatusLabel(status ?? 'ACTIVE'), Icons.circle, _getStatusColor(status ?? 'ACTIVE')),
                  ],
                ),
              ],
            ),
          ),
          if (product['description'] != null && product['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('product.description'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text(product['description'].toString(), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                ],
              ),
            ),
          ],
          
          if (cfg.fields.showShelf && product['shelfCode'] != null) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.shelves, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Text('${cfg.labels.shelfField}: ${product['shelfCode']}', style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],

          if (variants.length > 1) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t('product.variants')} (${variants.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(variant['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)), Text('SKU: ${variant['sku'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
          Expanded(flex: 2, child: Text(_currFmt.format(variant['salePrice'] ?? 0), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
          Expanded(child: Text('${variant['stock'] ?? 0} Adet', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500))),
        ],
      ),
    );
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _quickActionBtn(icon: Icons.tune, label: t('stock.adjust'), color: AppColors.primary, onTap: _showStockAdjustDialog),
              const SizedBox(width: 10),
              _quickActionBtn(icon: Icons.swap_horiz, label: t('stock.transfer'), color: Colors.indigo, onTap: () => context.push('/stock/transfer')),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: t('common.refresh'),
                onPressed: _loadMovements,
              ),
            ],
          ),
        ),
        _movements.isEmpty
          ? Expanded(
              child: AppEmptyState.noData(
                title: t('stock.no_movements'),
                actionText: t('common.refresh'),
                onAction: _loadMovements,
              ),
            )
          : Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _movements.length,
                itemBuilder: (context, index) {
                  final m = _movements[index];
                  final cfg = _movementConfig(m['movementType']?.toString() ?? '');
                  return AppCard(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: (cfg['color'] as Color).withValues(alpha: 0.1), child: Icon(cfg['icon'] as IconData, color: cfg['color'] as Color, size: 20)),
                      title: Text(cfg['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(m['createTime'] != null ? _dateTimeFmt.format(DateTime.parse(m['createTime'].toString())) : ''),
                      trailing: Text('${cfg['isIn'] ? '+' : '-'}${m['quantity']}', style: TextStyle(fontWeight: FontWeight.bold, color: cfg['isIn'] ? Colors.green : Colors.red, fontSize: 15)),
                    ),
                  );
                },
              ),
            ),
      ],
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

  Color _getStatusColor(String? status) {
    if (status == 'ACTIVE') return AppColors.success;
    if (status == 'DRAFT') return AppColors.warning;
    return AppColors.textMuted;
  }

  BadgeVariant _getStatusBadgeVariant(String? status) {
    if (status == 'ACTIVE') return BadgeVariant.success;
    if (status == 'DRAFT') return BadgeVariant.warning;
    return BadgeVariant.secondary;
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Row(children: [Icon(icon, size: 16, color: AppColors.textSecondary), const SizedBox(width: 8), Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))]),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
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
      case 'PURCHASE_IN':        return {'label': t('stock.purchase_in'), 'icon': Icons.add_shopping_cart, 'color': Colors.green, 'isIn': true};
      case 'PURCHASE_RETURN_OUT': return {'label': 'Satın Alma İade', 'icon': Icons.assignment_return, 'color': Colors.orange, 'isIn': false};
      case 'SALE_OUT':           return {'label': t('sales.sale'), 'icon': Icons.point_of_sale, 'color': Colors.red, 'isIn': false};
      case 'SALE_RETURN_IN':     return {'label': 'Satış İade', 'icon': Icons.assignment_returned, 'color': Colors.teal, 'isIn': true};
      case 'SALE_CANCEL_IN':     return {'label': 'Satış İptal', 'icon': Icons.cancel_outlined, 'color': Colors.deepOrange, 'isIn': true};
      case 'TRANSFER_IN':       return {'label': 'Transfer Giriş', 'icon': Icons.arrow_downward, 'color': Colors.indigo, 'isIn': true};
      case 'TRANSFER_OUT':      return {'label': 'Transfer Çıkış', 'icon': Icons.arrow_upward, 'color': Colors.indigo, 'isIn': false};
      case 'ADJUSTMENT_IN':     return {'label': 'Sayım Fazlası', 'icon': Icons.add_circle_outline, 'color': Colors.blue, 'isIn': true};
      case 'ADJUSTMENT_OUT':    return {'label': 'Sayım Eksiği', 'icon': Icons.remove_circle_outline, 'color': Colors.blueGrey, 'isIn': false};
      default:                  return {'label': type, 'icon': Icons.swap_vert, 'color': AppColors.textMuted, 'isIn': true};
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