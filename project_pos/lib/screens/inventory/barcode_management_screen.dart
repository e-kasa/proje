import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class BarcodeManagementScreen extends ConsumerStatefulWidget {
  const BarcodeManagementScreen({super.key});

  @override
  ConsumerState<BarcodeManagementScreen> createState() => _BarcodeManagementScreenState();
}

class _BarcodeManagementScreenState extends ConsumerState<BarcodeManagementScreen> {
  String Function(String) get t => i18nOf(ref);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _barcodes = [];
  List<Map<String, dynamic>> _filteredBarcodes = [];
  bool _isLoading = false;
  String _filterType = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadBarcodes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBarcodes() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(productServiceProvider);
      final products = await service.getProducts();
      // Transform products to barcode entries
      final barcodeList = <Map<String, dynamic>>[];
      for (final p in products) {
        if (p['barcode'] != null && (p['barcode'] as String).isNotEmpty) {
          barcodeList.add({
            'id': p['id'],
            'barcode': p['barcode'] ?? '',
            'productName': p['name'] ?? '',
            'sku': p['sku'] ?? '',
            'type': 'EAN-13',
            'price': (p['sellPrice'] ?? p['salePrice'] ?? 0).toDouble(),
            'stock': p['stock'] ?? 0,
            'status': (p['stock'] ?? 0) > 0 ? 'active' : 'inactive',
          });
        }
      }
      setState(() {
        _barcodes = barcodeList;
        _filteredBarcodes = List.from(_barcodes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _barcodes = [];
        _filteredBarcodes = [];
        _isLoading = false;
      });
      if (mounted) {
        AppToast.error(context, 'Veri yuklenemedi');
      }
    }
  }

  void _filterBarcodes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBarcodes = List.from(_barcodes);
      } else {
        _filteredBarcodes = _barcodes.where((barcode) {
          final barcodeNum = barcode['barcode'].toString().toLowerCase();
          final productName = barcode['productName'].toString().toLowerCase();
          final sku = barcode['sku'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return barcodeNum.contains(searchLower) ||
              productName.contains(searchLower) ||
              sku.contains(searchLower);
        }).toList();
      }

      // Apply type filter
      if (_filterType != 'Tümü') {
        _filteredBarcodes = _filteredBarcodes.where((b) => b['type'] == _filterType).toList();
      }
    });
  }

  void _applyTypeFilter(String type) {
    setState(() {
      _filterType = type;
      _filterBarcodes(_searchController.text);
    });
  }

  void _showAddBarcodeDialog() {
    final barcodeController = TextEditingController();
    String selectedType = 'EAN-13';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(t('inventory.add_barcode')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: barcodeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Barkod Numarası *',
                    hintText: 'Barkodu girin veya tarayın',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code_scanner),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Barkod Tipi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ['EAN-13', 'EAN-8', 'CODE-128', 'QR Code'].map<DropdownMenuItem<String>>((type) {
                    return DropdownMenuItem<String>(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/scanner');
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(t('inventory.scan_barcode')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (barcodeController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  AppToast.success(context, 'Barkod eklendi');
                  _loadBarcodes();
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBarcodeDetails(Map<String, dynamic> barcode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Barcode Display
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 80, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      barcode['barcode'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        barcode['type'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Product Info
              _buildInfoSection(t('inventory.product_info'), [
                _buildInfoRow(t('inventory.product_name'), barcode['productName'], Icons.shopping_bag),
                _buildInfoRow('SKU', barcode['sku'], Icons.qr_code_2),
                _buildInfoRow('Fiyat', '${barcode['price']} ₺', Icons.attach_money),
                _buildInfoRow('Stok', '${barcode['stock']} adet', Icons.inventory_2),
              ]),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Edit logic
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(t('common.edit')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Print logic
                      },
                      icon: const Icon(Icons.print),
                      label: Text(t('common.print')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children.map((child) {
              final index = children.indexOf(child);
              return Column(
                children: [
                  child,
                  if (index < children.length - 1) const Divider(height: 24),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('menu.barcodes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterBarcodes,
                        decoration: InputDecoration(
                          hintText: '${t('common.search')}...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: AppColors.bgLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showAddBarcodeDialog,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(t('common.add')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Type Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Tümü', 'EAN-13', 'EAN-8', 'CODE-128', 'QR Code'].map((type) {
                      final isSelected = _filterType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (_) => _applyTypeFilter(type),
                          backgroundColor: AppColors.bgLight,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Quick Stats
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat(t('common.total'), '${_barcodes.length}', Icons.qr_code_2),
                      Container(width: 1, height: 30, color: AppColors.border),
                      _buildQuickStat(t('common.active'), '${_barcodes.where((b) => b['status'] == 'active').length}', Icons.check_circle),
                      Container(width: 1, height: 30, color: AppColors.border),
                      _buildQuickStat(t('stock.out_of_stock'), '${_barcodes.where((b) => b['stock'] == 0).length}', Icons.warning),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barcodes List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBarcodes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredBarcodes.length,
                        itemBuilder: (context, index) {
                          final barcode = _filteredBarcodes[index];
                          return _buildBarcodeCard(barcode);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        
        onPressed: () => context.go('/scanner'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: Text(t('inventory.scan_barcode'), style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.qr_code_2_outlined,
      title: t('inventory.no_barcodes'),
      description: 'Yeni barkod eklemek veya taramak için butonu kullanın',
    );
  }

  Widget _buildBarcodeCard(Map<String, dynamic> barcode) {
    final isLowStock = barcode['stock'] < 10;
    final isOutOfStock = barcode['stock'] == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showBarcodeDetails(barcode),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Barcode Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),

                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barcode['productName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  barcode['sku'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  barcode['type'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stock Badge
                    if (isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t('stock.out_of_stock'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      )
                    else if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t('stock.low_stock'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_scanner, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              barcode['barcode'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, size: 16, color: AppColors.success),
                        Text(
                          '${barcode['price']} ₺',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 16, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          '${barcode['stock']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}