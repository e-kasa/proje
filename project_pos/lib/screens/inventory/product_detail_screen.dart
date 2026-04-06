import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/app_app_bar.dart';
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

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;

  // OEM tab state
  List<Map<String, dynamic>> _oemNumbers = [];
  bool _oemLoading = false;

  // Cross reference tab state
  List<Map<String, dynamic>> _crossRefs = [];
  bool _crossRefLoading = false;

  // Vehicle compatibility tab state
  List<Map<String, dynamic>> _vehicleCompats = [];
  bool _vehicleCompatLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
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
          _error = 'Urun bulunamadi';
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

  Future<void> _loadTabData() async {
    final variantId = _firstVariantId;
    if (variantId == null) return;

    // Load OEM numbers
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

    // Load cross references
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

    // Load vehicle compatibilities
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
          title: 'Urun Detayi',
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Bilinmeyen hata',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final productName = product['name']?.toString() ?? 'Urun';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppAppBar.standard(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.go('/inventory/products'),
          ),
          title: productName,
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                context.push('/inventory/add-product?edit=${_product!['id']}');
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Duzenle'),
            ),
            const SizedBox(width: 12),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Genel Bilgi'),
              Tab(text: 'OEM Numaralar'),
              Tab(text: 'Capraz Referans'),
              Tab(text: 'Arac Uyumlulugu'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralInfoTab(product),
            _buildOemTab(),
            _buildCrossRefTab(),
            _buildVehicleCompatTab(),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: Genel Bilgi ───────────────────────────────────────────────────

  Widget _buildGeneralInfoTab(Map<String, dynamic> product) {
    final variants =
        (product['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info card
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SKU: ${product['sku'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (product['barcode'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Barkod: ${product['barcode']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildInfoChip(
                      'Marka',
                      product['brand']?.toString() ?? '-',
                      Icons.local_offer_outlined,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      'Kategori',
                      product['categoryId']?.toString() ?? '-',
                      Icons.category_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Fiyat',
                        '${product['basePrice'] ?? 0} TL',
                        Icons.attach_money,
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Stok',
                        '${product['stock'] ?? 0}',
                        Icons.inventory_2_outlined,
                        AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Durum',
                        product['isActive'] == true ? 'Aktif' : 'Pasif',
                        Icons.circle,
                        product['isActive'] == true
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description card
          if (product['description'] != null &&
              product['description'].toString().isNotEmpty)
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aciklama',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product['description'].toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

          // Variants card
          if (variants.length > 1) ...[
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Varyantlar (${variants.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
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
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant['name']?.toString() ?? variant['sku']?.toString() ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${variant['sku'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Satis: ${variant['salePrice'] ?? '-'} TL',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Alis: ${variant['purchasePrice'] ?? '-'} TL',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Stok: ${inventory['physicalQuantity'] ?? 0}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
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
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── Tab 2: OEM Numaralar ─────────────────────────────────────────────────

  Widget _buildOemTab() {
    if (_oemLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_firstVariantId == null) {
      return const Center(
        child: Text(
          'Varyant bulunamadi',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: [
        // Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OEM Numaralari (${_oemNumbers.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddOemDialog();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _oemNumbers.isEmpty
              ? const Center(
                  child: Text(
                    'Henuz OEM numarasi eklenmemis',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
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
                              : AppColors.border,
                        ),
                      ),
                      child: ListTile(
                        leading: isPrimary
                            ? const Icon(Icons.star,
                                color: AppColors.warning, size: 24)
                            : const Icon(Icons.tag,
                                color: AppColors.textMuted, size: 24),
                        title: Text(
                          oem['oemNumber']?.toString() ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          oem['manufacturer']?.toString() ?? '-',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: isPrimary
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: AppConstants.borderRadiusSmall,
                                ),
                                child: const Text(
                                  'Birincil',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
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

  // ─── Tab 3: Capraz Referans ───────────────────────────────────────────────

  Widget _buildCrossRefTab() {
    if (_crossRefLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_firstVariantId == null) {
      return const Center(
        child: Text(
          'Varyant bulunamadi',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Capraz Referanslar (${_crossRefs.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddCrossReferenceDialog();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _crossRefs.isEmpty
              ? const Center(
                  child: Text(
                    'Henuz capraz referans eklenmemis',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
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
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.swap_horiz,
                            color: AppColors.info, size: 24),
                        title: Text(
                          cr['crossRefNumber']?.toString() ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          cr['crossRefBrand']?.toString() ?? '-',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: cr['notes'] != null &&
                                cr['notes'].toString().isNotEmpty
                            ? Tooltip(
                                message: cr['notes'].toString(),
                                child: const Icon(Icons.info_outline,
                                    color: AppColors.textMuted, size: 20),
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

  // ─── Tab 4: Arac Uyumlulugu ──────────────────────────────────────────────

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
                'Uyumlu Araclar (${_vehicleCompats.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _vehicleCompats.isEmpty
              ? const Center(
                  child: Text(
                    'Henuz arac uyumlulugu eklenmemis',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
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
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.directions_car,
                            color: AppColors.primary, size: 24),
                        title: Text(
                          '${vc['make'] ?? ''} ${vc['model'] ?? ''} ${vc['engine'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Yil: ${vc['yearStart'] ?? ''} - ${vc['yearEnd'] ?? 'Guncel'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
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

  // ─── Dialogs ─────────────────────────────────────────────────────────────

  void _showAddOemDialog() {
    final oemController = TextEditingController();
    final manufacturerController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OEM Numarasi Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oemController,
                decoration: const InputDecoration(
                  labelText: 'OEM Numarasi *',
                  hintText: 'Orn: 1234567890',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'OEM numarasi zorunlu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: manufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Uretici Adi',
                  hintText: 'Orn: Bosch',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Iptal'),
          ),
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
                _loadOemNumbers();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
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
    final codeController = TextEditingController();
    final brandController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Capraz Referans Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Referans Kodu *',
                  hintText: 'Orn: ABC-123',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Referans kodu zorunlu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(
                  labelText: 'Marka',
                  hintText: 'Orn: Febi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Aciklama',
                  hintText: 'Opsiyonel not',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Iptal'),
          ),
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
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

  void _loadOemNumbers() {
    _loadTabData();
  }
}
