import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/models/bulk_import_models.dart';
import 'package:project_pos/services/bulk_import_service.dart';
import 'modals/update_stock_modal.dart';
import 'modals/match_confirm_modal.dart';
import 'modals/manual_match_modal.dart';

/// Toplu İçe Aktarma - Ürün İnceleme ve Karar Ekranı V2
/// Gerçek backend modelleri ile çalışan production-ready versiyon
class BulkImportReviewScreenV2 extends ConsumerStatefulWidget {
  final String? importId;
  final String sector;

  const BulkImportReviewScreenV2({
    super.key,
    this.importId,
    this.sector = 'genel',
  });

  @override
  ConsumerState<BulkImportReviewScreenV2> createState() => _BulkImportReviewScreenV2State();
}

class _BulkImportReviewScreenV2State extends ConsumerState<BulkImportReviewScreenV2> {
  String Function(String) get t => i18nOf(ref);
  late List<AnalyzedProduct> _products;
  late ImportStatistics _statistics;
  final Set<String> _selectedProducts = {};
  ProductStatus? _filterStatus;
  String _searchQuery = '';
  final Map<String, bool> _expandedProducts = {};

  @override
  void initState() {
    super.initState();
    _importId = widget.importId;
    _sector = widget.sector;
    _loadProducts();
  }

  String? _importId;
  String _sector = 'genel';

  String get _sectorLabel {
    switch (_sector) {
      case 'parcaci': return 'Oto Parça';
      case 'giyim': return 'Giyim';
      default: return 'Genel';
    }
  }

  Future<void> _loadProducts() async {
    setState(() {});
    try {
      final bulkImportService = BulkImportService(ApiClient());
      final data = await bulkImportService.getAnalysisResult(_importId ?? '');
      final productsJson = data['products'] as List;
      _products = productsJson
          .map((json) => AnalyzedProduct.fromJson(json as Map<String, dynamic>))
          .toList();
      _statistics = ImportStatistics.fromJson(
        data['statistics'] as Map<String, dynamic>,
      );
      setState(() {});
    } catch (e) {
      setState(() {
        _products = [];
        _statistics = ImportStatistics(total: 0, newProducts: 0, conflicts: 0, potentialMatches: 0, addVariants: 0, updateVariants: 0, needsVariants: 0, createVariantGroups: 0, errors: 0);
      });
    }
  }

  List<AnalyzedProduct> get _filteredProducts {
    return _products.where((product) {
      // Filter by status
      if (_filterStatus != null && product.status != _filterStatus) {
        return false;
      }

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = product.name.toLowerCase();
        final sku = product.sku.toLowerCase();
        final barcode = product.barcode.toLowerCase();

        if (!name.contains(query) && !sku.contains(query) && !barcode.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedProducts.length == _filteredProducts.length) {
        _selectedProducts.clear();
      } else {
        _selectedProducts.clear();
        for (var product in _filteredProducts) {
          if (product.status != ProductStatus.ERROR) {
            _selectedProducts.add(product.tempId);
          }
        }
      }
    });
  }

  void _toggleProductSelection(String tempId) {
    setState(() {
      if (_selectedProducts.contains(tempId)) {
        _selectedProducts.remove(tempId);
      } else {
        _selectedProducts.add(tempId);
      }
    });
  }

  void _executeAction(AnalyzedProduct product, SuggestedAction action) {
    // Handle ActionType.CREATE ambiguity by checking label
    if (action.action == ActionType.CREATE) {
      if (action.label.toLowerCase().contains('düzenle')) {
        // "Düzenle & Kaydet" - Navigate to AddProductWizardScreen
        _navigateToAddProduct(product);
      } else {
        // "Kaydet" - Direct save without modal
        _directSaveProduct(product);
      }
      return;
    }

    // Handle other action types
    switch (action.action) {
      case ActionType.UPDATE_STOCK:
        _showUpdateStockModal(product);
        break;
      case ActionType.UPDATE_PRICE:
        _showUpdatePriceModal(product);
        break;
      case ActionType.UPDATE_BOTH:
        _showUpdateBothModal(product);
        break;
      case ActionType.MATCH:
        _showMatchConfirmModal(product);
        break;
      case ActionType.MATCH_MANUAL:
        _showManualMatchModal(product);
        break;
      case ActionType.ADD_VARIANT:
        _showAddVariantModal(product);
        break;
      case ActionType.UPDATE_VARIANT:
        _showUpdateVariantModal(product);
        break;
      case ActionType.CREATE_VARIANTS:
        _showCreateVariantsModal(product);
        break;
      case ActionType.CREATE_VARIANT_GROUP:
        _showCreateVariantGroupModal(product);
        break;
      case ActionType.SKIP:
        _skipProduct(product);
        break;
      case ActionType.CREATE:
        // Already handled above
        break;
    }
  }

  // Modal functions with real implementations
  void _showUpdateStockModal(AnalyzedProduct product) {
    showDialog(
      context: context,
      builder: (context) => UpdateStockModal(
        product: product,
        onDecision: (decision) => _saveDecision(product, decision),
      ),
    );
  }

  void _showUpdatePriceModal(AnalyzedProduct product) {
    // For now, use UPDATE_BOTH modal - in production, create dedicated price modal
    _showUpdateBothModal(product);
  }

  void _showUpdateBothModal(AnalyzedProduct product) {
    showDialog(
      context: context,
      builder: (context) => UpdateStockModal(
        product: product,
        onDecision: (decision) => _saveDecision(product, decision),
      ),
    );
  }

  void _showMatchConfirmModal(AnalyzedProduct product) {
    showDialog(
      context: context,
      builder: (context) => MatchConfirmModal(
        product: product,
        onDecision: (decision) => _saveDecision(product, decision),
      ),
    );
  }

  void _showManualMatchModal(AnalyzedProduct product) {
    // Get all existing products from system
    final availableProducts = <MatchedProduct>[];

    showDialog(
      context: context,
      builder: (context) => ManualMatchModal(
        product: product,
        availableProducts: availableProducts,
        onDecision: (decision) => _saveDecision(product, decision),
      ),
    );
  }


  void _showAddVariantModal(AnalyzedProduct product) {
    // TODO: Create dedicated add variant modal
    AppToast.info(context, 'Varyant ekleme modalı yakında eklenecek');
  }

  void _showUpdateVariantModal(AnalyzedProduct product) {
    _showUpdateStockModal(product);
  }

  void _showCreateVariantsModal(AnalyzedProduct product) {
    // TODO: Integrate quick_variant_modal.dart
    AppToast.info(context, 'Varyant oluşturma modalı yakında eklenecek');
  }

  void _showCreateVariantGroupModal(AnalyzedProduct product) {
    AppToast.info(context, 'Varyant grubu oluşturma modalı yakında eklenecek');
  }

  Future<void> _navigateToAddProduct(AnalyzedProduct product) async {
    // Navigate to AddProductWizardScreen with pre-populated data + sector
    final result = await context.push('/inventory/add-product', extra: {
      'fromBulkImport': true,
      'sector': _sector,
      'importData': {
        'name': product.name,
        'sku': product.sku,
        'barcode': product.barcode,
        'buyPrice': product.buyPrice,
        'sellPrice': product.sellPrice,
        'stock': product.stock,
        'categoryId': product.category,
        'brandId': product.brand,
        'unit': product.unit,
        'taxRate': product.taxRate,
        'description': product.description,
      },
      'tempId': product.tempId,
    });

    // If UserDecision returned, save it
    if (result != null && result is UserDecision) {
      _saveDecision(product, result);
    }
  }

  void _saveDecision(AnalyzedProduct product, UserDecision decision) {
    setState(() {
      final index = _products.indexWhere((p) => p.tempId == product.tempId);
      if (index != -1) {
        _products[index] = product.copyWith(userDecision: decision);
      }
    });

    AppToast.success(context, 'Karar kaydedildi: ${decision.action.name}'); // TODO: i18n bulk_import.decision_saved
  }

  void _skipProduct(AnalyzedProduct product) {
    setState(() {
      final index = _products.indexWhere((p) => p.tempId == product.tempId);
      if (index != -1) {
        _products[index] = product.copyWith(
          userDecision: UserDecision.skip(tempId: product.tempId, reason: 'Kullanıcı atladı'),
        );
      }
    });

    AppToast.info(context, 'Ürün atlandı');
  }

  void _directSaveProduct(AnalyzedProduct product) {
    // Create UserDecision for direct save (no modal)
    final productMap = {
      'name': product.name,
      'sku': product.sku,
      'barcode': product.barcode,
      'category': product.category,
      'brand': product.brand,
      'unit': product.unit,
      'taxRate': product.taxRate,
      'buyPrice': product.buyPrice,
      'sellPrice': product.sellPrice,
      'stock': product.stock,
      'description': product.description,
      'sector': _sector,
    };

    final decision = UserDecision.create(
      tempId: product.tempId,
      product: productMap,
    );

    _saveDecision(product, decision);
  }

  // ========== BULK ACTION METHODS ==========

  void _bulkApplyRecommended(List<AnalyzedProduct> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Önerilen Aksiyonları Uygula'), // TODO: i18n bulk_import.apply_recommended
          ],
        ),
        content: Text(
          '${products.length} ürün için önerilen aksiyonlar otomatik olarak uygulanacak.\n\n'
          'Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processBulkRecommended(products);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Evet, Uygula'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBulkRecommended(List<AnalyzedProduct> products) async {
    int processed = 0;

    for (final product in products) {
      // Find recommended action
      final recommendedAction = product.suggestedActions.firstWhere(
        (a) => a.recommended,
        orElse: () => product.suggestedActions.first,
      );

      // Execute the recommended action
      _executeAction(product, recommendedAction);

      processed++;

      // Small delay for UI feedback
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;
    setState(() {
      _selectedProducts.clear();
    });

    if (!context.mounted) return;
    AppToast.success(context, '$processed ürün için önerilen aksiyonlar uygulandı');
  }

  void _bulkSaveNew(List<AnalyzedProduct> products) {
    final newProducts = products.where((p) => p.status == ProductStatus.NEW).toList();

    if (newProducts.isEmpty) {
      AppToast.warning(context, 'Seçili ürünler arasında YENİ durumda ürün bulunamadı');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.save, color: AppColors.success),
            const SizedBox(width: 12),
            const Text('Yeni Ürünleri Kaydet'), // TODO: i18n bulk_import.save_new_products
          ],
        ),
        content: Text(
          '${newProducts.length} yeni ürün sisteme eklenecek.\n\n'
          'Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processBulkSaveNew(newProducts);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Evet, Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBulkSaveNew(List<AnalyzedProduct> products) async {
    for (final product in products) {
      _directSaveProduct(product);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;
    setState(() {
      _selectedProducts.clear();
    });

    if (!context.mounted) return;
    AppToast.success(context, '${products.length} yeni ürün kaydedildi');
  }

  void _bulkUpdateStock(List<AnalyzedProduct> products) {
    final conflictProducts = products.where((p) =>
      p.status == ProductStatus.CONFLICT && p.matchedProduct != null
    ).toList();

    if (conflictProducts.isEmpty) {
      AppToast.warning(context, 'Seçili ürünler arasında ÇAKIŞMA durumda ürün bulunamadı');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Stok Güncelle'), // TODO: i18n bulk_import.update_stock_title
          ],
        ),
        content: Text(
          '${conflictProducts.length} ürünün stoğu güncellenecek (EKLE modu).\n\n'
          'Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processBulkUpdateStock(conflictProducts);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Evet, Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBulkUpdateStock(List<AnalyzedProduct> products) async {
    for (final product in products) {
      final decision = UserDecision.updateStock(
        tempId: product.tempId,
        productId: product.matchedProduct!.id,
        mode: StockUpdateMode.ADD,
        value: product.stock,
      );
      _saveDecision(product, decision);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;
    setState(() {
      _selectedProducts.clear();
    });

    if (!context.mounted) return;
    AppToast.success(context, '${products.length} ürünün stoğu güncellendi');
  }

  void _bulkSkip(List<AnalyzedProduct> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: AppColors.textMuted),
            const SizedBox(width: 12),
            const Text('Ürünleri Atla'), // TODO: i18n bulk_import.skip_products
          ],
        ),
        content: Text(
          '${products.length} ürün atlanacak.\n\n'
          'Bu ürünler sisteme eklenmeyecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processBulkSkip(products);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textMuted),
            child: const Text('Evet, Atla'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBulkSkip(List<AnalyzedProduct> products) async {
    for (final product in products) {
      _skipProduct(product);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;
    setState(() {
      _selectedProducts.clear();
    });

    if (!context.mounted) return;
    AppToast.info(context, '${products.length} ürün atlandı');
  }

  // ========== SMART SUGGESTIONS: APPLY TO SIMILAR ==========

  void _applyToSimilar(AnalyzedProduct sourceProduct) {
    // Find similar products
    final sameStatus = _products.where((p) =>
      p.tempId != sourceProduct.tempId &&
      p.status == sourceProduct.status &&
      p.userDecision == null
    ).toList();

    final sameCategory = _products.where((p) =>
      p.tempId != sourceProduct.tempId &&
      p.category == sourceProduct.category &&
      p.userDecision == null
    ).toList();

    final sameBrand = _products.where((p) =>
      p.tempId != sourceProduct.tempId &&
      p.brand == sourceProduct.brand &&
      p.userDecision == null
    ).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.copy_all, color: AppColors.info),
            const SizedBox(width: 12),
            const Text('Benzer Ürünlere Uygula'), // TODO: i18n bulk_import.apply_to_similar
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu karar hangi ürünlere uygulansin?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text(
                'Karar: ${_getDecisionLabel(sourceProduct.userDecision!)}',
                style: TextStyle(color: AppColors.success, fontSize: 13),
              ),
              const Divider(height: 24),
              if (sameStatus.isNotEmpty)
                _buildSimilarityOption(
                  context,
                  Icons.label,
                  'Aynı Durumdaki Ürünler',
                  '${sameStatus.length} ürün (${_getStatusInfo(sourceProduct.status).label})',
                  () => _applySimilarDecision(sourceProduct, sameStatus),
                ),
              if (sameCategory.isNotEmpty)
                _buildSimilarityOption(
                  context,
                  Icons.category,
                  'Aynı Kategorideki Ürünler',
                  '${sameCategory.length} ürün (${sourceProduct.category})',
                  () => _applySimilarDecision(sourceProduct, sameCategory),
                ),
              if (sameBrand.isNotEmpty)
                _buildSimilarityOption(
                  context,
                  Icons.storefront,
                  'Aynı Markadaki Ürünler',
                  '${sameBrand.length} ürün (${sourceProduct.brand})',
                  () => _applySimilarDecision(sourceProduct, sameBrand),
                ),
              if (sameStatus.isEmpty && sameCategory.isEmpty && sameBrand.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Benzer karar verilmemiş ürün bulunamadı.',
                          style: TextStyle(color: AppColors.info, fontSize: 13),
                        ),
                      ),
                    ],
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
        ],
      ),
    );
  }

  Widget _buildSimilarityOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward, color: AppColors.primary),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  void _applySimilarDecision(AnalyzedProduct source, List<AnalyzedProduct> targets) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Onayla'), // TODO: i18n common.confirm
          ],
        ),
        content: Text(
          '${targets.length} ürüne aynı karar uygulanacak:\n\n'
          '${_getDecisionLabel(source.userDecision!)}\n\n'
          'Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApplyToSimilar(source, targets);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
            child: const Text('Evet, Uygula'),
          ),
        ],
      ),
    );
  }

  Future<void> _processApplyToSimilar(AnalyzedProduct source, List<AnalyzedProduct> targets) async {
    final sourceDecision = source.userDecision!;

    for (final target in targets) {
      // Clone the decision for each target
      final newDecision = UserDecision(
        tempId: target.tempId,
        action: sourceDecision.action,
        data: Map<String, dynamic>.from(sourceDecision.data),
      );

      _saveDecision(target, newDecision);
      await Future.delayed(const Duration(milliseconds: 30));
    }

    if (!mounted) return;
    if (!context.mounted) return;
    AppToast.success(context, '${targets.length} ürüne karar uygulandı');
  }

  void _changeDecision(AnalyzedProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Kararı Değiştir'), // TODO: i18n bulk_import.change_decision
          ],
        ),
        content: Text(
          '${product.name} için verilen kararı iptal etmek istediğinizden emin misiniz?\n\n'
          'Mevcut Karar: ${_getDecisionLabel(product.userDecision!)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final index = _products.indexWhere((p) => p.tempId == product.tempId);
                if (index != -1) {
                  _products[index] = product.copyWith(userDecision: null);
                }
              });
              Navigator.pop(context);
              AppToast.info(context, 'Karar iptal edildi. Yeni bir karar verebilirsiniz.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Evet, İptal Et'),
          ),
        ],
      ),
    );
  }

  String _getDecisionLabel(UserDecision decision) {
    switch (decision.action) {
      case ActionType.CREATE:
        return 'Yeni Ürün Oluştur';
      case ActionType.UPDATE_STOCK:
        return 'Stok Güncelle';
      case ActionType.UPDATE_PRICE:
        return 'Fiyat Güncelle';
      case ActionType.UPDATE_BOTH:
        return 'Stok ve Fiyat Güncelle';
      case ActionType.MATCH:
        return 'Eşleştir';
      case ActionType.MATCH_MANUAL:
        return 'Manuel Eşleştir';
      case ActionType.ADD_VARIANT:
        return 'Varyant Ekle';
      case ActionType.UPDATE_VARIANT:
        return 'Varyant Güncelle';
      case ActionType.CREATE_VARIANTS:
        return 'Varyantları Oluştur';
      case ActionType.CREATE_VARIANT_GROUP:
        return 'Varyant Grubu Oluştur';
      case ActionType.SKIP:
        return 'Atla';
    }
  }

  String? _getDecisionSummary(UserDecision decision) {
    final data = decision.data;

    switch (decision.action) {
      case ActionType.UPDATE_STOCK:
        if (data['stockUpdate'] != null) {
          final mode = data['stockUpdate']['mode'];
          final value = data['stockUpdate']['value'];
          return mode == 'ADD' ? 'Stok ekle: +$value' : 'Stok değiştir: $value';
        }
        return null;

      case ActionType.UPDATE_PRICE:
        if (data['priceUpdate'] != null) {
          final buy = data['priceUpdate']['buyPrice'];
          final sell = data['priceUpdate']['sellPrice'];
          return 'Alış: ₺$buy, Satış: ₺$sell';
        }
        return null;

      case ActionType.UPDATE_BOTH:
      case ActionType.MATCH:
      case ActionType.MATCH_MANUAL:
        if (data['matchedProductId'] != null) {
          return 'Ürün ID: ${data['matchedProductId']}';
        }
        return null;

      case ActionType.SKIP:
        return data['reason'] ?? 'Ürün atlandı';

      default:
        return null;
    }
  }

  void _saveAllProducts() {
    // STEP 1: Validation
    final decisions = _products
        .where((p) => p.userDecision != null)
        .map((p) => p.userDecision!)
        .toList();

    if (decisions.isEmpty) {
      AppToast.warning(context, 'Kaydedilecek ürün yok. Lütfen en az bir ürün için karar verin.');
      return;
    }

    final undecidedCount = _products.where((p) =>
      p.status != ProductStatus.ERROR && p.userDecision == null
    ).length;

    if (undecidedCount > 0) {
      _showUndecidedWarning(undecidedCount, decisions);
      return;
    }

    // STEP 2: Show preview modal
    _showSavePreviewModal(decisions);
  }

  void _showUndecidedWarning(int undecidedCount, List<UserDecision> decisions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Uyarı: Karar Verilmemiş Ürünler'), // TODO: i18n bulk_import.undecided_warning
          ],
        ),
        content: Text(
          '$undecidedCount ürün için henüz karar verilmedi.\n\n'
          'Bu ürünler atlanacak. Sadece ${decisions.length} ürün işlenecek.\n\n'
          'Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Geri Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSavePreviewModal(decisions);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  void _showSavePreviewModal(List<UserDecision> decisions) {
    // Calculate summary statistics
    final summary = _calculateSaveSummary(decisions);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.preview, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Kayıt Önizleme'), // TODO: i18n bulk_import.save_preview
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aşağıdaki işlemler gerçekleştirilecek:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(Icons.add_circle, 'Yeni Ürün Ekle', summary['create']!, AppColors.success),
              _buildSummaryRow(Icons.update, 'Stok Güncelle', summary['updateStock']!, AppColors.info),
              _buildSummaryRow(Icons.price_change, 'Fiyat Güncelle', summary['updatePrice']!, AppColors.info),
              _buildSummaryRow(Icons.link, 'Ürün Eşleştir', summary['match']!, const Color(0xFFFF9800)),
              _buildSummaryRow(Icons.category, 'Varyant Ekle', summary['addVariant']!, const Color(0xFF9C27B0)),
              _buildSummaryRow(Icons.cancel, 'Atla', summary['skip']!, AppColors.textMuted),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.inventory, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Toplam: ${decisions.length} işlem',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu işlem geri alınamaz!',
                        style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
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
            icon: const Icon(Icons.send),
            label: const Text('Onayla ve Kaydet'), // TODO: i18n bulk_import.confirm_and_save
            onPressed: () {
              Navigator.pop(context);
              _processSaveWithProgress(decisions);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateSaveSummary(List<UserDecision> decisions) {
    final summary = {
      'create': 0,
      'updateStock': 0,
      'updatePrice': 0,
      'match': 0,
      'addVariant': 0,
      'skip': 0,
    };

    for (final decision in decisions) {
      switch (decision.action) {
        case ActionType.CREATE:
          summary['create'] = summary['create']! + 1;
          break;
        case ActionType.UPDATE_STOCK:
        case ActionType.UPDATE_BOTH:
          summary['updateStock'] = summary['updateStock']! + 1;
          break;
        case ActionType.UPDATE_PRICE:
          summary['updatePrice'] = summary['updatePrice']! + 1;
          break;
        case ActionType.MATCH:
        case ActionType.MATCH_MANUAL:
          summary['match'] = summary['match']! + 1;
          break;
        case ActionType.ADD_VARIANT:
        case ActionType.CREATE_VARIANTS:
          summary['addVariant'] = summary['addVariant']! + 1;
          break;
        case ActionType.SKIP:
          summary['skip'] = summary['skip']! + 1;
          break;
        default:
          break;
      }
    }

    return summary;
  }

  Widget _buildSummaryRow(IconData icon, String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processSaveWithProgress(List<UserDecision> decisions) async {
    // Build payloads - Backend'in beklediği format:
    // {product: {...}, variants: [...], purchase: {...}}
    final payloads = BulkSavePayloadBuilder.buildBulkPayload(
      products: _products.where((p) => p.userDecision != null).toList(),
      // TODO: Tedarikçi bilgilerini UI'dan al
      // supplierId: 'SUPPLIER-001',
      // invoiceNumber: 'INV-2024-001',
      // purchaseDate: DateTime.now().toIso8601String(),
    );

    // Debug: Backend'e gönderilecek JSON formatı
    debugPrint('========================================');
    debugPrint('🚀 BACKEND\'E GÖNDERİLECEK FORMAT:');
    debugPrint('========================================');
    for (var i = 0; i < (payloads.length > 2 ? 2 : payloads.length); i++) {
      debugPrint('Payload ${i + 1}:');
      debugPrint('  action: ${payloads[i]['action']}');
      if (payloads[i].containsKey('product')) {
        debugPrint('  product: ${payloads[i]['product']}');
      }
      if (payloads[i].containsKey('variants')) {
        debugPrint('  variants: ${payloads[i]['variants']}');
      }
    }
    debugPrint('========================================');

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SaveProgressDialog(
        totalCount: payloads.length,
      ),
    );

    try {
      // Backend API çağrısı
      final bulkImportService = BulkImportService(ApiClient());
      final result = await bulkImportService.saveDecisions(
        importId: _importId ?? '',
        products: payloads,
        sector: _sector,
        onProgress: (current, total) {
          debugPrint('📦 İşleniyor: $current/$total');
        },
      );

      // Close progress dialog
      if (mounted) Navigator.pop(context);

      // Sonuçları göster
      if (result.hasErrors) {
        final errorMessages = result.errors
            .map((e) => e['error'].toString())
            .join('\n');
        _showSaveError('${result.totalFailed} hata oluştu:\n$errorMessages');
      } else {
        _showSaveSuccess(result.totalProcessed);
      }

      // Debug: Özet bilgi
      debugPrint('========================================');
      debugPrint('📊 BACKEND CEVABI:');
      debugPrint('========================================');
      debugPrint('Oluşturulan: ${result.totalCreated}');
      debugPrint('Güncellenen: ${result.totalUpdated}');
      debugPrint('Eşleştirilen: ${result.totalMatched}');
      debugPrint('Başarısız: ${result.totalFailed}');
      debugPrint('========================================');
    } catch (e) {
      // Close progress dialog
      if (mounted) Navigator.pop(context);

      // Show error
      _showSaveError(e.toString());
    }
  }

  void _showSaveSuccess(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: 12),
            const Text('Başarılı!'), // TODO: i18n common.success
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count ürün başarıyla işlendi.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.thumb_up, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Değişiklikler sisteme yansıtıldı.',
                      style: TextStyle(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/stock');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Stok Ekranına Git'), // TODO: i18n bulk_import.go_to_stock
          ),
        ],
      ),
    );
  }

  void _showSaveError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.danger, size: 32),
            const SizedBox(width: 12),
            const Text('Hata!'), // TODO: i18n common.error
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ürünler kaydedilirken bir hata oluştu:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                style: TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppAppBar.standard(
        title: 'Toplu Ürün Yükleme - İnceleme (${_sectorLabel})', // TODO: i18n bulk_import.review_title
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(),

          const SizedBox(height: 16),

          // Statistics Summary
          _buildStatisticsSummary(),

          const Divider(height: 1),

          // Product List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(product);
              },
            ),
          ),

          // Bottom Actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(1, 'Dosya Yükle', false, true), // TODO: i18n bulk_import.step_upload
          _buildStepConnector(true),
          _buildStepItem(2, 'İncele & Düzenle', true, false), // TODO: i18n bulk_import.step_review
          _buildStepConnector(false),
          _buildStepItem(3, 'Kaydet', false, false), // TODO: i18n common.save
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String label, bool isActive, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : (isActive ? AppColors.primary : AppColors.bgLight),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? AppColors.success
                  : (isActive ? AppColors.primary : AppColors.border),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isCompleted ? AppColors.success : AppColors.border,
    );
  }

  Widget _buildStatisticsSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stats Row 1
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Toplam', '${_statistics.total}', Icons.inventory_2, AppColors.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Yeni', '${_statistics.newProducts}', Icons.add_circle, AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Çakışma', '${_statistics.conflicts}', Icons.warning, AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Hata', '${_statistics.errors}', Icons.error, AppColors.danger),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Stats Row 2
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Benzer', '${_statistics.potentialMatches}', Icons.link, const Color(0xFFFF9800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Varyant +', '${_statistics.addVariants}', Icons.category, const Color(0xFF9C27B0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Varyant ↻', '${_statistics.updateVariants}', Icons.sync, const Color(0xFF9C27B0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Varyant?', '${_statistics.needsVariants}', Icons.help_outline, const Color(0xFF607D8B)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Tracking
          _buildProgressTracking(),

          const SizedBox(height: 16),

          // Bulk Actions Bar (if products selected)
          if (_selectedProducts.isNotEmpty) ...[
            _buildBulkActionsBar(),
            const SizedBox(height: 16),
          ],

          // Filter and Search
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ProductStatus?>(
                  initialValue: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Durum Filtresi',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tümü')),
                    DropdownMenuItem(value: ProductStatus.NEW, child: Text('Yeni')),
                    DropdownMenuItem(value: ProductStatus.CONFLICT, child: Text('Çakışma')),
                    DropdownMenuItem(value: ProductStatus.POTENTIAL_MATCH, child: Text('Benzer')),
                    DropdownMenuItem(value: ProductStatus.ADD_VARIANT, child: Text('Varyant Ekle')),
                    DropdownMenuItem(value: ProductStatus.UPDATE_VARIANT, child: Text('Varyant Güncelle')),
                    DropdownMenuItem(value: ProductStatus.NEEDS_VARIANTS, child: Text('Varyant Gerekli')),
                    DropdownMenuItem(value: ProductStatus.CREATE_VARIANT_GROUP, child: Text('Varyant Grubu')),
                    DropdownMenuItem(value: ProductStatus.ERROR, child: Text('Hata')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Ara (İsim, SKU, Barkod)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: Icon(
                  _selectedProducts.length == _filteredProducts.where((p) => p.status != ProductStatus.ERROR).length
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                label: Text('Tümünü Seç (${_selectedProducts.length})'),
                onPressed: _toggleSelectAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgLight,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracking() {
    final decidedCount = _products.where((p) => p.userDecision != null).length;
    final totalCount = _products.where((p) => p.status != ProductStatus.ERROR).length;
    final progress = totalCount > 0 ? decidedCount / totalCount : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Karar Verme İlerlemesi',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$decidedCount / $totalCount ürün',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(%$percentage)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.bgLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (decidedCount < totalCount) ...[
                Icon(Icons.info_outline, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Text(
                  '${totalCount - decidedCount} ürün için karar bekleniyor',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                Icon(Icons.check_circle, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                const Text(
                  'Tüm ürünler için karar verildi! Kaydetmeye hazır.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    final selectedCount = _selectedProducts.length;
    final selectedProductList = _products.where((p) => _selectedProducts.contains(p.tempId)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.15),
            AppColors.warning.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: AppColors.warning, size: 24),
              const SizedBox(width: 12),
              Text(
                'Toplu İşlem: $selectedCount ürün seçildi',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Seçimi Temizle'),
                onPressed: () {
                  setState(() {
                    _selectedProducts.clear();
                  });
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Apply Recommended Actions
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Önerilen Aksiyonları Uygula'),
                onPressed: () => _bulkApplyRecommended(selectedProductList),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              // Bulk Save (NEW products)
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Tümünü Kaydet (Yeni)'),
                onPressed: () => _bulkSaveNew(selectedProductList),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              // Bulk Update Stock (CONFLICT products)
              ElevatedButton.icon(
                icon: const Icon(Icons.inventory, size: 18),
                label: const Text('Stok Güncelle (Çakışma)'),
                onPressed: () => _bulkUpdateStock(selectedProductList),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              // Bulk Skip
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('Tümünü Atla'),
                onPressed: () => _bulkSkip(selectedProductList),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textMuted,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(AnalyzedProduct product) {
    final isSelected = _selectedProducts.contains(product.tempId);
    final isExpanded = _expandedProducts[product.tempId] ?? false;
    final statusInfo = _getStatusInfo(product.status);
    final hasDecision = product.userDecision != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: hasDecision ? AppColors.success : AppColors.border,
          width: hasDecision ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Main Product Info
          ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: product.status != ProductStatus.ERROR
                  ? (_) => _toggleProductSelection(product.tempId)
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          // Decision badge
                          if (hasDecision) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Karar Verildi',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product.sku.isEmpty ? '-' : product.sku} | Barkod: ${product.barcode.isEmpty ? '-' : product.barcode}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusInfo.color),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusInfo.icon, size: 14, color: statusInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Stok: ${product.stock} | Alış: ₺${product.buyPrice} | Satış: ₺${product.sellPrice}'),
                const SizedBox(height: 8),

                // Decision Summary (if decision made)
                if (hasDecision) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.task_alt, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Karar: ${_getDecisionLabel(product.userDecision!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (_getDecisionSummary(product.userDecision!) != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _getDecisionSummary(product.userDecision!)!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Quick Apply Button (recommended action)
                if (!hasDecision && product.suggestedActions.any((a) => a.recommended)) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusInfo.color.withValues(alpha: 0.15),
                          statusInfo.color.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusInfo.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: statusInfo.color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Önerilen Aksiyon',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                product.suggestedActions.firstWhere((a) => a.recommended).label,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.bolt, size: 16),
                          label: const Text('Hızlı Uygula'),
                          onPressed: () {
                            final recommended = product.suggestedActions.firstWhere((a) => a.recommended);
                            _executeAction(product, recommended);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusInfo.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Action Buttons (only show if no decision made)
                if (!hasDecision)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.suggestedActions.map((action) {
                      return ElevatedButton.icon(
                        icon: Icon(_getActionIcon(action.action), size: 16),
                        label: Text(action.label),
                        onPressed: () => _executeAction(product, action),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: action.recommended ? statusInfo.color : AppColors.bgLight,
                          foregroundColor: action.recommended ? Colors.white : AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    }).toList(),
                  ),

                // Change Decision & Apply to Similar (if decision made)
                if (hasDecision)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Kararı Değiştir'),
                        onPressed: () => _changeDecision(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.copy_all, size: 16),
                        label: const Text('Benzerlere Uygula'),
                        onPressed: () => _applyToSimilar(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Expand/Collapse button
                TextButton.icon(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16),
                  label: Text(isExpanded ? 'Daralt' : 'Detaylar'),
                  onPressed: () {
                    setState(() {
                      _expandedProducts[product.tempId] = !isExpanded;
                    });
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Expanded Details
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Errors
                  if (product.errors != null && product.errors!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error, color: AppColors.danger, size: 20),
                              const SizedBox(width: 8),
                              const Text('Hatalar:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...product.errors!.map((e) => Padding(
                                padding: const EdgeInsets.only(left: 28, top: 4),
                                child: Text('• $e', style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Warnings
                  if (product.warnings != null && product.warnings!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: AppColors.warning, size: 20),
                              const SizedBox(width: 8),
                              const Text('Uyarılar:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...product.warnings!.map((w) => Padding(
                                padding: const EdgeInsets.only(left: 28, top: 4),
                                child: Text('• $w', style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Matched Product Info
                  if (product.matchedProduct != null) ...[
                    const Text('Eşleşen Ürün:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.matchedProduct!.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text('SKU: ${product.matchedProduct!.sku}', style: const TextStyle(fontSize: 13)),
                          Text('Barkod: ${product.matchedProduct!.barcode}', style: const TextStyle(fontSize: 13)),
                          Text('Mevcut Stok: ${product.matchedProduct!.currentStock}',
                              style: const TextStyle(fontSize: 13)),
                          Text(
                              'Mevcut Fiyat: ₺${product.matchedProduct!.currentBuyPrice} / ₺${product.matchedProduct!.currentSellPrice}',
                              style: const TextStyle(fontSize: 13)),
                          if (product.matchedProduct!.similarity < 1.0)
                            Text(
                              'Benzerlik: ${(product.matchedProduct!.similarity * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Variant Analysis
                  if (product.variantAnalysis != null) ...[
                    const Text('Varyant Analizi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ana Ürün: ${product.variantAnalysis!.baseProductName}',
                              style: const TextStyle(fontSize: 13)),
                          if (product.variantAnalysis!.detectedAttributes.isNotEmpty)
                            Text('Özellikler: ${product.variantAnalysis!.detectedAttributes}',
                                style: const TextStyle(fontSize: 13)),
                          Text('Öneri: ${product.variantAnalysis!.suggestedVariantType}',
                              style: const TextStyle(fontSize: 13)),
                          if (product.variantAnalysis!.parentProduct != null)
                            Text(
                                'Mevcut Varyantlar: ${product.variantAnalysis!.parentProduct!.existingVariants.length}',
                                style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final hasDecisions = _products.any((p) => p.userDecision != null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasDecisions
                  ? '${_products.where((p) => p.userDecision != null).length} ürün için karar verildi'
                  : 'Henüz karar verilmedi',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => context.go('/bulk-import/upload'),
            child: const Text('Geri'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Tümünü Kaydet'),
            onPressed: hasDecisions ? _saveAllProducts : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  StatusInfo _getStatusInfo(ProductStatus status) {
    switch (status) {
      case ProductStatus.NEW:
        return StatusInfo('Yeni', AppColors.success, Icons.add_circle);
      case ProductStatus.CONFLICT:
        return StatusInfo('Çakışma', AppColors.warning, Icons.warning);
      case ProductStatus.POTENTIAL_MATCH:
        return StatusInfo('Benzer', const Color(0xFFFF9800), Icons.link);
      case ProductStatus.ADD_VARIANT:
        return StatusInfo('Varyant Ekle', const Color(0xFF9C27B0), Icons.category);
      case ProductStatus.UPDATE_VARIANT:
        return StatusInfo('Varyant Güncelle', const Color(0xFF9C27B0), Icons.sync);
      case ProductStatus.NEEDS_VARIANTS:
        return StatusInfo('Varyant Gerekli', const Color(0xFF607D8B), Icons.help_outline);
      case ProductStatus.CREATE_VARIANT_GROUP:
        return StatusInfo('Varyant Grubu', const Color(0xFF9C27B0), Icons.account_tree);
      case ProductStatus.ERROR:
        return StatusInfo('Hata', AppColors.danger, Icons.error);
    }
  }

  IconData _getActionIcon(ActionType action) {
    switch (action) {
      case ActionType.CREATE:
        return Icons.add_circle;
      case ActionType.UPDATE_STOCK:
        return Icons.inventory;
      case ActionType.UPDATE_PRICE:
        return Icons.price_change;
      case ActionType.UPDATE_BOTH:
        return Icons.sync;
      case ActionType.MATCH:
        return Icons.link;
      case ActionType.MATCH_MANUAL:
        return Icons.search;
      case ActionType.ADD_VARIANT:
        return Icons.category;
      case ActionType.UPDATE_VARIANT:
        return Icons.sync;
      case ActionType.CREATE_VARIANTS:
        return Icons.category;
      case ActionType.CREATE_VARIANT_GROUP:
        return Icons.account_tree;
      case ActionType.SKIP:
        return Icons.cancel;
    }
  }
}

class StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  StatusInfo(this.label, this.color, this.icon);
}

// Progress Dialog Widget for Save Operation
class _SaveProgressDialog extends StatelessWidget {
  final int totalCount;

  const _SaveProgressDialog({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ürünler kaydediliyor...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '$totalCount ürün işleniyor',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}