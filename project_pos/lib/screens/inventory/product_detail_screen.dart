import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';

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
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;

  // Tab controller
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
  String? _movementFilter; // null=Tümü, SALE_OUT, PURCHASE_IN, SALE_RETURN_IN, TRANSFER_IN, ADJUSTMENT_IN

  final _dateFmt     = DateFormat('dd.MM.yyyy');
  final _dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');
  final _currFmt     = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 4 && _movements.isEmpty && !_movementsLoading) {
        _loadMovements();
      }
    });
    _loadProduct();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final product = await ref.read(productServiceProvider).getProductById(widget.productId);
      if (product.isEmpty) {
        setState(() { _error = 'Ürün bulunamadı'; _isLoading = false; });
        return;
      }
      setState(() { _product = product; _isLoading = false; });
      _loadTabData();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String? get _firstVariantId {
    final variants = (_product?['variants'] as List?)?.cast<Map<String, dynamic>>();
    if (variants != null && variants.isNotEmpty) return variants.first['id']?.toString();
    return null;
  }

  List<Map<String, dynamic>> get _allVariants =>
      (_product?['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  Future<void> _loadTabData() async {
    final variantId = _firstVariantId;
    if (variantId == null) return;

    // OEM
    setState(() => _oemLoading = true);
    try {
      final oems = await ref.read(oemServiceProvider).getByVariantId(variantId);
      setState(() { _oemNumbers = oems; _oemLoading = false; });
    } catch (_) { setState(() => _oemLoading = false); }

    // Cross refs
    setState(() => _crossRefLoading = true);
    try {
      final crossRefs = await ref.read(crossReferenceServiceProvider).getByVariantId(variantId);
      setState(() { _crossRefs = crossRefs; _crossRefLoading = false; });
    } catch (_) { setState(() => _crossRefLoading = false); }

    // Vehicle compat
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

  Future<void> _loadMovements() async {
    final variantId = _firstVariantId;
    if (variantId == null) return;
    setState(() => _movementsLoading = true);
    try {
      final movements = await ref.read(stockServiceProvider).getVariantMovements(variantId);
      setState(() { _movements = movements; _movementsLoading = false; });
    } catch (_) { setState(() => _movementsLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
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
          title: 'Ürün Detayı',
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(_error ?? 'Bilinmeyen hata',
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadProduct, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final productName = product['name']?.toString() ?? 'Ürün';

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
            tooltip: 'Yenile',
            onPressed: () {
              _loadProduct();
              if (_tabController.index == 4) _loadMovements();
            },
          ),
          OutlinedButton.icon(
            onPressed: () => context.push('/inventory/add-product?edit=${_product!['id']}'),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Düzenle'),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Genel Bilgi'),
            Tab(text: 'OEM Numaralar'),
            Tab(text: 'Çapraz Ref'),
            Tab(text: 'Araç Uyumluluğu'),
            Tab(text: 'Geçmiş'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralInfoTab(product),
          _buildOemTab(),
          _buildCrossRefTab(),
          _buildVehicleCompatTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ─── Tab 1: Genel Bilgi ───────────────────────────────────────────────────

  Widget _buildGeneralInfoTab(Map<String, dynamic> product) {
    final variants = (product['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
                Text(
                  product['name']?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text('SKU: ${product['sku'] ?? '-'}',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                if (product['barcode'] != null) ...[
                  const SizedBox(height: 4),
                  Text('Barkod: ${product['barcode']}',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildInfoChip('Marka', product['brand']?.toString() ?? '-',
                        Icons.local_offer_outlined),
                    const SizedBox(width: 12),
                    _buildInfoChip('Kategori', product['categoryId']?.toString() ?? '-',
                        Icons.category_outlined),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildStatItem(
                        'Fiyat', '${product['basePrice'] ?? 0} ₺',
                        Icons.attach_money, AppColors.primary)),
                    Expanded(child: _buildStatItem(
                        'Stok', '${product['stock'] ?? 0}',
                        Icons.inventory_2_outlined, AppColors.success)),
                    Expanded(child: _buildStatItem(
                        'Durum', product['isActive'] == true ? 'Aktif' : 'Pasif',
                        Icons.circle,
                        product['isActive'] == true ? AppColors.success : AppColors.danger)),
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
                  const Text('Açıklama',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text(product['description'].toString(),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
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
                  Text('Varyantlar (${variants.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  ...variants.map((v) => _buildVariantRow(v)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantRow(Map<String, dynamic> variant) {
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
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(variant['name']?.toString() ?? variant['sku']?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('SKU: ${variant['sku'] ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          )),
          Expanded(flex: 2, child: Text('Satış: ${variant['salePrice'] ?? '-'} ₺',
              style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500))),
          Expanded(flex: 2, child: Text('Alış: ${variant['purchasePrice'] ?? '-'} ₺',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text('Stok: ${inventory['physicalQuantity'] ?? 0}',
              style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ─── Tab 2: OEM Numaralar ─────────────────────────────────────────────────

  Widget _buildOemTab() {
    if (_oemLoading) return const Center(child: CircularProgressIndicator());
    if (_firstVariantId == null) return const Center(
        child: Text('Varyant bulunamadı', style: TextStyle(color: AppColors.textMuted)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OEM Numaraları (${_oemNumbers.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: _showAddOemDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _oemNumbers.isEmpty
              ? const Center(child: Text('Henüz OEM numarası eklenmemiş',
              style: TextStyle(color: AppColors.textMuted)))
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
                  side: BorderSide(color: isPrimary ? AppColors.warning : AppColors.border),
                ),
                child: ListTile(
                  leading: isPrimary
                      ? const Icon(Icons.star, color: AppColors.warning, size: 24)
                      : const Icon(Icons.tag, color: AppColors.textMuted, size: 24),
                  title: Text(oem['oemNumber']?.toString() ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                          color: AppColors.textPrimary)),
                  subtitle: Text(oem['manufacturer']?.toString() ?? '-',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: isPrimary ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    child: const Text('Birincil',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.warning)),
                  ) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Tab 3: Çapraz Referans ───────────────────────────────────────────────

  Widget _buildCrossRefTab() {
    if (_crossRefLoading) return const Center(child: CircularProgressIndicator());
    if (_firstVariantId == null) return const Center(
        child: Text('Varyant bulunamadı', style: TextStyle(color: AppColors.textMuted)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Çapraz Referanslar (${_crossRefs.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              ElevatedButton.icon(
                onPressed: _showAddCrossReferenceDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _crossRefs.isEmpty
              ? const Center(child: Text('Henüz çapraz referans eklenmemiş',
              style: TextStyle(color: AppColors.textMuted)))
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
                  leading: const Icon(Icons.swap_horiz, color: AppColors.info, size: 24),
                  title: Text(cr['crossRefNumber']?.toString() ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                          color: AppColors.textPrimary)),
                  subtitle: Text(cr['crossRefBrand']?.toString() ?? '-',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: cr['notes'] != null && cr['notes'].toString().isNotEmpty
                      ? Tooltip(message: cr['notes'].toString(),
                      child: const Icon(Icons.info_outline, color: AppColors.textMuted, size: 20))
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Tab 4: Araç Uyumluluğu ──────────────────────────────────────────────

  Widget _buildVehicleCompatTab() {
    if (_vehicleCompatLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Uyumlu Araçlar (${_vehicleCompats.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
        Expanded(
          child: _vehicleCompats.isEmpty
              ? const Center(child: Text('Henüz araç uyumluluğu eklenmemiş',
              style: TextStyle(color: AppColors.textMuted)))
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
                  leading: const Icon(Icons.directions_car, color: AppColors.primary, size: 24),
                  title: Text(
                      '${vc['make'] ?? ''} ${vc['model'] ?? ''} ${vc['engine'] ?? ''}'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                          color: AppColors.textPrimary)),
                  subtitle: Text(
                      'Yıl: ${vc['yearStart'] ?? ''} - ${vc['yearEnd'] ?? 'Güncel'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Tab 5: Geçmiş ────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    final product = _product!;
    final totalStock = (product['stock'] as num?)?.toInt() ?? 0;

    // İstatistikleri hareketlerden hesapla
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
          if (type == 'SALE_OUT')        soldThisMonth     += (mv['quantity'] as num?)?.toInt() ?? 0;
          if (type == 'PURCHASE_IN')     purchasedThisMonth += (mv['quantity'] as num?)?.toInt() ?? 0;
          if (type == 'SALE_RETURN_IN')  returnedThisMonth  += (mv['quantity'] as num?)?.toInt() ?? 0;
        }
      }
    }

    // Filtreli hareketler
    final filtered = _movementFilter == null
        ? _movements
        : _movements.where((mv) {
            final type = mv['movementType']?.toString() ?? '';
            switch (_movementFilter) {
              case 'SALE':
                return type == 'SALE_OUT' || type == 'SALE_CANCEL_IN';
              case 'PURCHASE':
                return type == 'PURCHASE_IN' || type == 'PURCHASE_RETURN_OUT';
              case 'RETURN':
                return type == 'SALE_RETURN_IN';
              case 'TRANSFER':
                return type == 'TRANSFER_IN' || type == 'TRANSFER_OUT';
              case 'ADJUSTMENT':
                return type == 'ADJUSTMENT_IN' || type == 'ADJUSTMENT_OUT';
              default:
                return true;
            }
          }).toList();

    return Column(
      children: [
        // ── Hızlı İşlem Butonları ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4))),
          ),
          child: Row(
            children: [
              Expanded(child: _quickActionBtn(
                icon: Icons.tune_rounded,
                label: 'Stok Düzelt',
                color: AppColors.primary,
                onTap: () => _showStockAdjustDialog(),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickActionBtn(
                icon: Icons.swap_horiz_rounded,
                label: 'Transfer',
                color: Colors.indigo,
                onTap: () => context.push('/stock/transfer'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickActionBtn(
                icon: Icons.receipt_long_outlined,
                label: 'Satışları Gör',
                color: Colors.teal,
                onTap: () => context.push('/sales'),
              )),
            ],
          ),
        ),

        // ── İstatistik Kartları ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Row(
            children: [
              Expanded(child: _statCard(
                  '📦 Mevcut\nStok', '$totalStock adet',
                  totalStock <= 0 ? Colors.red : (totalStock < 5 ? Colors.orange : Colors.green))),
              const SizedBox(width: 8),
              Expanded(child: _statCard('📤 Bu Ay\nSatış', '$soldThisMonth adet', Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('📥 Bu Ay\nAlım', '$purchasedThisMonth adet', Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _statCard(
                  '↩️ Bu Ay\nİade', '$returnedThisMonth adet', Colors.orange)),
            ],
          ),
        ),

        // Son hareket
        if (lastMovementDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Son hareket: ${_dateTimeFmt.format(lastMovementDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

        // ── Filtre Chip'leri ──────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              _mvFilterChip('Tümü',      null,         Icons.list_rounded),
              const SizedBox(width: 6),
              _mvFilterChip('Satış',     'SALE',       Icons.point_of_sale_rounded),
              const SizedBox(width: 6),
              _mvFilterChip('Alım',      'PURCHASE',   Icons.shopping_cart_rounded),
              const SizedBox(width: 6),
              _mvFilterChip('İade',      'RETURN',     Icons.assignment_return_outlined),
              const SizedBox(width: 6),
              _mvFilterChip('Transfer',  'TRANSFER',   Icons.swap_horiz_rounded),
              const SizedBox(width: 6),
              _mvFilterChip('Düzeltme',  'ADJUSTMENT', Icons.build_outlined),
              const SizedBox(width: 6),
              Text(
                '${filtered.length} kayıt',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // ── Hareket Listesi ───────────────────────────────────────────────
        Expanded(
          child: _movementsLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_outlined,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            _movements.isEmpty
                                ? 'Henüz stok hareketi yok'
                                : 'Bu filtreye ait kayıt bulunamadı',
                            style: TextStyle(color: Colors.grey[500], fontSize: 15),
                          ),
                          if (_movements.isEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _loadMovements,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Yenile'),
                            ),
                          ]
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _buildMovementCard(filtered[i]),
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
              Flexible(child: Text(label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), height: 1.3),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _mvFilterChip(String label, String? value, IconData icon) {
    final selected = _movementFilter == value;
    return FilterChip(
      avatar: Icon(icon, size: 14,
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
    final type      = mv['movementType']?.toString() ?? '';
    final qty       = (mv['quantity'] as num?)?.toInt() ?? 0;
    final dateStr   = mv['createTime']?.toString();
    final date      = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final unitPrice = (mv['unitPrice'] as num?)?.toDouble();
    final saleNo    = mv['saleNumber']?.toString();
    final purchaseNo = mv['purchaseNumber']?.toString();
    final user      = mv['createUser']?.toString();
    final storeId   = mv['storeId']?.toString();
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
            // Tür ikonu
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
            // Bilgi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (cfg['color'] as Color).withOpacity(0.12),
                          borderRadius: AppConstants.borderRadiusSmall,
                        ),
                        child: Text(cfg['label'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: cfg['color'] as Color)),
                      ),
                      if (saleNo != null) ...[
                        const SizedBox(width: 6),
                        Text('#$saleNo',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ] else if (purchaseNo != null) ...[
                        const SizedBox(width: 6),
                        Text('#$purchaseNo',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (date != null)
                    Text(_dateTimeFmt.format(date),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (storeId != null || warehouseId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (storeId != null && storeId.isNotEmpty) 'Mağaza: $storeId',
                        if (warehouseId != null && warehouseId.isNotEmpty) 'Depo: $warehouseId',
                      ].join('  ·  '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                  if (user != null && user != 'syste') ...[
                    const SizedBox(height: 2),
                    Text('Kullanıcı: $user',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            // Miktar + fiyat
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  child: Text(
                    '${isIn ? "+" : "-"}$qty adet',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: isIn ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                if (unitPrice != null && unitPrice > 0) ...[
                  const SizedBox(height: 4),
                  Text(_currFmt.format(unitPrice),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Hareket tipi için renk/ikon/etiket konfigürasyonu
  Map<String, dynamic> _movementConfig(String type) {
    switch (type) {
      case 'PURCHASE_IN':
        return {'label': 'Satın Alım', 'icon': Icons.shopping_cart_rounded,
            'color': Colors.green, 'isIn': true};
      case 'PURCHASE_RETURN_OUT':
        return {'label': 'Tedarikçi İadesi', 'icon': Icons.keyboard_return_rounded,
            'color': Colors.deepOrange, 'isIn': false};
      case 'SALE_OUT':
        return {'label': 'Satış', 'icon': Icons.point_of_sale_rounded,
            'color': Colors.red, 'isIn': false};
      case 'SALE_RETURN_IN':
        return {'label': 'Müşteri İadesi', 'icon': Icons.assignment_return_outlined,
            'color': Colors.orange, 'isIn': true};
      case 'SALE_CANCEL_IN':
        return {'label': 'Satış İptali', 'icon': Icons.cancel_outlined,
            'color': Colors.purple, 'isIn': true};
      case 'TRANSFER_IN':
        return {'label': 'Transfer Giriş', 'icon': Icons.arrow_downward_rounded,
            'color': Colors.indigo, 'isIn': true};
      case 'TRANSFER_OUT':
        return {'label': 'Transfer Çıkış', 'icon': Icons.arrow_upward_rounded,
            'color': Colors.indigo, 'isIn': false};
      case 'ADJUSTMENT_IN':
        return {'label': 'Düzeltme (+)', 'icon': Icons.add_circle_outline,
            'color': Colors.teal, 'isIn': true};
      case 'ADJUSTMENT_OUT':
        return {'label': 'Düzeltme (-)', 'icon': Icons.remove_circle_outline,
            'color': Colors.teal, 'isIn': false};
      default:
        return {'label': type, 'icon': Icons.swap_vert_rounded,
            'color': AppColors.textMuted, 'isIn': true};
    }
  }

  // ─── Stok Düzeltme Dialog ─────────────────────────────────────────────────

  void _showStockAdjustDialog() {
    final qtyCtrl    = TextEditingController();
    final notesCtrl  = TextEditingController();
    String direction = 'ADJUSTMENT_IN';
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Stok Düzeltme'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ürün adı + mevcut stok
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
                      Expanded(child: Text(
                        '${_product?['name'] ?? ''}\n'
                        'Mevcut stok: ${_product?['stock'] ?? 0} adet',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Giriş / Çıkış toggle
                Row(
                  children: [
                    Expanded(child: _dirBtn(
                      ctx: ctx, setD: setD,
                      label: '+ Giriş', value: 'ADJUSTMENT_IN',
                      current: direction, color: Colors.green,
                      onSelect: (v) => direction = v,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _dirBtn(
                      ctx: ctx, setD: setD,
                      label: '- Çıkış', value: 'ADJUSTMENT_OUT',
                      current: direction, color: Colors.red,
                      onSelect: (v) => direction = v,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Miktar *',
                    hintText: 'Kaç adet?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Miktar zorunlu';
                    if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Geçersiz miktar';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Not',
                    hintText: 'Düzeltme nedeni (opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final variantId = _firstVariantId;
                if (variantId == null) return;
                try {
                  await ref.read(stockServiceProvider).createStockMovement({
                    'variantId':    variantId,
                    'storeId':      '',
                    'warehouseId':  '',
                    'movementType': direction,
                    'quantity':     int.parse(qtyCtrl.text.trim()),
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _loadProduct();
                  _loadMovements();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Stok düzeltmesi kaydedildi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Kaydet'),
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
          border: Border.all(color: selected ? color : AppColors.border, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textMuted)),
        ),
      ),
    );
  }

  // ─── OEM / Cross Ref Dialogs ──────────────────────────────────────────────

  void _showAddOemDialog() {
    final oemController          = TextEditingController();
    final manufacturerController = TextEditingController();
    final formKey                = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OEM Numarası Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oemController,
                decoration: const InputDecoration(
                    labelText: 'OEM Numarası *', hintText: 'Örn: 1234567890',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'OEM numarası zorunlu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: manufacturerController,
                decoration: const InputDecoration(
                    labelText: 'Üretici Adı', hintText: 'Örn: Bosch',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final variantId = _firstVariantId;
              if (variantId == null) return;
              try {
                await ref.read(oemServiceProvider).create({
                  'variantId':    int.tryParse(variantId) ?? variantId,
                  'oemNumber':    oemController.text.trim(),
                  'manufacturer': manufacturerController.text.trim(),
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadTabData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    ).then((_) {
      oemController.dispose();
      manufacturerController.dispose();
    });
  }

  void _showAddCrossReferenceDialog() {
    final codeController  = TextEditingController();
    final brandController = TextEditingController();
    final notesController = TextEditingController();
    final formKey         = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çapraz Referans Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                    labelText: 'Referans Kodu *', hintText: 'Örn: ABC-123',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Referans kodu zorunlu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(
                    labelText: 'Marka', hintText: 'Örn: Febi',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                    labelText: 'Açıklama', hintText: 'Opsiyonel not',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final variantId = _firstVariantId;
              if (variantId == null) return;
              try {
                await ref.read(crossReferenceServiceProvider).create({
                  'variantId':      int.tryParse(variantId) ?? variantId,
                  'crossRefNumber': codeController.text.trim(),
                  'crossRefBrand':  brandController.text.trim(),
                  'notes':          notesController.text.trim(),
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadTabData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    ).then((_) {
      codeController.dispose();
      brandController.dispose();
      notesController.dispose();
    });
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

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
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: AppConstants.borderRadiusMedium),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
