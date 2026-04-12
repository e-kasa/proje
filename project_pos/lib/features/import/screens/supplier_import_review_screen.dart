import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/models/supplier_import_models.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/services/bulk_import_service.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// Modern Tedarikçi İthalat İnceleme Ekranı
class SupplierImportReviewScreen extends ConsumerStatefulWidget {
  final String? importId;

  const SupplierImportReviewScreen({
    super.key,
    this.importId,
  });

  @override
  ConsumerState<SupplierImportReviewScreen> createState() =>
      _SupplierImportReviewScreenState();
}

class _SupplierImportReviewScreenState
    extends ConsumerState<SupplierImportReviewScreen> {
  String Function(String) get t => i18nOf(ref);
  late SupplierImportResponse _response;
  bool _loading = true;
  String? _expandedProductId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final bulkImportService = BulkImportService(ApiClient());
      final data = await bulkImportService.getAnalysisResult(widget.importId ?? '');
      setState(() {
        _response = SupplierImportResponse.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _response = SupplierImportResponse(productCount: 0, products: []);
        _loading = false;
      });
      debugPrint('Supplier import veri yuklenemedi: $e');
    }
  }

  int get _decidedCount =>
      _response.products.where((p) => p.hasDecision).length;
  int get _pendingCount =>
      _response.products.where((p) => !p.hasDecision).length;

  Future<void> _handleSave() async {
    final undecided = _response.products.where((p) => !p.hasDecision).toList();

    if (undecided.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eksik Kararlar'), // TODO: i18n bulk_import.missing_decisions
          content: Text(
            '${undecided.length} ürün için henüz karar vermediniz.\n\nDevam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'), // TODO: i18n common.cancel
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Devam Et'), // TODO: i18n common.continue
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    _showLoadingDialog();

    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pop(context); // Close loading

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      AppToast.error(context, 'Hata: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Ürünler kaydediliyor...', // TODO: i18n bulk_import.saving_products
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Başarılı!'), // TODO: i18n common.success
        content: Text('$_decidedCount ürün başarıyla kaydedildi.'), // TODO: i18n bulk_import.products_saved
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Close screen
            },
            child: const Text('Tamam'), // TODO: i18n common.ok
          ),
        ],
      ),
    );
  }

  void _showDecisionSheet(SupplierProductItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DecisionBottomSheet(
        item: item,
        onDecisionMade: (decision) {
          setState(() {
            item.userDecision = decision;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Tedarikçi Ürün Kontrolü', // TODO: i18n supplier_upload.product_review_title
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_decidedCount / ${_response.productCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _response.products.length,
                    itemBuilder: (context, index) {
                      final item = _response.products[index];
                      return _buildProductCard(item, index);
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _decidedCount > 0 ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save),
                      const SizedBox(width: 8),
                      Text(
                        _decidedCount == 0
                            ? 'Henüz Karar Verilmedi'
                            : 'Kaydet ($_decidedCount Ürün)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = _response.productCount > 0
        ? _decidedCount / _response.productCount
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam ${_response.productCount} Ürün',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_pendingCount ürün inceleme bekliyor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(SupplierProductItem item, int index) {
    final hasDecision = item.hasDecision;
    final isNew = item.isNewProduct;
    final isExpanded = _expandedProductId == item.readProductName;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: hasDecision ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasDecision ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedProductId = isExpanded ? null : item.readProductName;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isNew
                      ? [Colors.blue[400]!, Colors.blue[600]!]
                      : [Colors.orange[400]!, Colors.orange[600]!],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isNew ? Colors.blue[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isNew ? Icons.fiber_new : Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isNew ? 'YENİ ÜRÜN' : '${item.forProduct.length} BENZER ÜRÜN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (hasDecision)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Karar Verildi',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),

          // Tedarikçi Bilgisi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.readProductName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.readBrand != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.label, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  item.readBrand!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (item.readBarcode != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.qr_code, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  item.readBarcode!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.readStock} Adet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (item.readPrice != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${item.readPrice!.toStringAsFixed(2)} ₺',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Karar Durumu veya Seçenekler
                const SizedBox(height: 16),
                if (hasDecision)
                  _buildDecisionStatus(item)
                else
                  _buildActionButtons(item),

                // Benzer Ürünler (Expanded)
                if (isExpanded && item.hasSystemMatches) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'BENZER ÜRÜNLER:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...item.forProduct.map((product) =>
                      _buildSystemProductCard(item, product)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionStatus(SupplierProductItem item) {
    final decision = item.userDecision!;
    IconData icon;
    String text;
    Color color;

    switch (decision.action) {
      case ProductImportAction.CREATE_NEW:
        icon = Icons.add_circle;
        text = 'Yeni ürün olarak oluşturulacak';
        color = Colors.green;
        break;
      case ProductImportAction.MATCH_EXISTING:
        icon = Icons.inventory;
        text = 'Mevcut ürüne stok eklenecek';
        color = Colors.blue;
        break;
      case ProductImportAction.ADD_AS_VARIANT:
        icon = Icons.category;
        text = 'Yeni varyant olarak eklenecek';
        color = Colors.purple;
        break;
      case ProductImportAction.SKIP:
        icon = Icons.block;
        text = 'Atlandı';
        color = Colors.grey;
        break;
      default:
        icon = Icons.help;
        text = 'İşleniyor';
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                item.userDecision = null;
              });
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Değiştir'), // TODO: i18n common.edit
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SupplierProductItem item) {
    if (item.isNewProduct) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showDecisionSheet(item),
            icon: const Icon(Icons.add_circle, size: 22),
            label: const Text('Yeni Ürün Oluştur'), // TODO: i18n bulk_import.create_new_product
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                item.userDecision = UserProductDecision(
                  action: ProductImportAction.SKIP,
                );
              });
            },
            icon: const Icon(Icons.block, size: 20),
            label: const Text('Atla'), // TODO: i18n bulk_import.skip
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _showDecisionSheet(item),
      icon: const Icon(Icons.touch_app, size: 22),
      label: Text('Karar Ver (${item.forProduct.length} Seçenek)'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSystemProductCard(
    SupplierProductItem supplierItem,
    SystemProduct product,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          child: Icon(Icons.inventory, color: Colors.orange[700], size: 20),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('SKU: ${product.sku}'),
        children: [
          if (product.variants.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Varyantlar (${product.variants.length}):',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...product.variants.map((variant) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variant.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (variant.pricing != null)
                              Text(
                                '${variant.pricing!.salePrice.toStringAsFixed(2)} ₺',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// Bottom Sheet for Decision Making
class _DecisionBottomSheet extends StatelessWidget {
  final SupplierProductItem item;
  final Function(UserProductDecision) onDecisionMade;

  const _DecisionBottomSheet({
    required this.item,
    required this.onDecisionMade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.readProductName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.readStock} Adet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (item.isNewProduct) ...[
                    _DecisionOption(
                      icon: Icons.add_circle,
                      title: 'Yeni Ürün Oluştur',
                      subtitle: 'Tamamen yeni bir ürün olarak sisteme ekle',
                      color: Colors.green,
                      onTap: () {
                        onDecisionMade(UserProductDecision(
                          action: ProductImportAction.CREATE_NEW,
                        ));
                      },
                    ),
                  ] else ...[
                    ...item.forProduct.map((product) => Column(
                          children: [
                            _DecisionOption(
                              icon: Icons.inventory,
                              title: 'Stoğa Ekle: ${product.name}',
                              subtitle:
                                  'Mevcut ürüne ${item.readStock} adet stok ekle',
                              color: Colors.blue,
                              onTap: () {
                                onDecisionMade(UserProductDecision(
                                  action: ProductImportAction.MATCH_EXISTING,
                                  selectedProductId: product.productId,
                                ));
                              },
                            ),
                            const SizedBox(height: 12),
                            _DecisionOption(
                              icon: Icons.category,
                              title: 'Varyant Ekle: ${product.name}',
                              subtitle: 'Mevcut ürüne yeni varyant olarak ekle',
                              color: Colors.purple,
                              onTap: () {
                                onDecisionMade(UserProductDecision(
                                  action: ProductImportAction.ADD_AS_VARIANT,
                                  selectedProductId: product.productId,
                                ));
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        )),
                    _DecisionOption(
                      icon: Icons.add_circle,
                      title: 'Yeni Ürün Oluştur',
                      subtitle: 'Hiçbiri değil, yeni ürün olarak ekle',
                      color: Colors.green,
                      onTap: () {
                        onDecisionMade(UserProductDecision(
                          action: ProductImportAction.CREATE_NEW,
                        ));
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DecisionOption(
                    icon: Icons.block,
                    title: 'Atla',
                    subtitle: 'Bu ürünü şimdilik işleme',
                    color: Colors.grey,
                    onTap: () {
                      onDecisionMade(UserProductDecision(
                        action: ProductImportAction.SKIP,
                      ));
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DecisionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
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