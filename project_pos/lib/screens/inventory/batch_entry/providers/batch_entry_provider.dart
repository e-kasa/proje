import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/product_service.dart';
import '../../../../services/purchase_service.dart';
import '../../../../services/oem_service.dart';
import '../../../../services/service_locator.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/config/sector_config.dart';
import '../../../../providers/sector_provider.dart';
import '../models/batch_entry_models.dart';
import 'package:intl/intl.dart';

class BatchEntryNotifier extends StateNotifier<BatchEntryState> {
  final ProductService _productService;
  final PurchaseService _purchaseService;
  // ignore: unused_field
  final OemService _oemService;
  final SectorConfig _sectorConfig;

  BatchEntryNotifier(
    this._productService,
    this._purchaseService,
    this._oemService,
    this._sectorConfig,
  ) : super(BatchEntryState());

  // --- Barkod/Arama ile Urun Ekle -------------------------------------------
  Future<String?> addByBarcode(String input) async {
    if (input.trim().isEmpty) return null;
    final trimmed = input.trim();

    // Ayni barkod zaten tabloda var mi?
    final existingIndex = state.rows.indexWhere(
      (r) => r.barcode == trimmed || r.existingVariantSku == trimmed,
    );
    if (existingIndex != -1) {
      final updatedRows = List<BatchEntryRow>.from(state.rows);
      final row = updatedRows[existingIndex];
      updatedRows[existingIndex] = row.copyWith(quantity: row.quantity + 1);
      state = state.copyWith(rows: updatedRows);
      return '${row.productName} — adet artirildi (${row.quantity + 1})';
    }

    // Backend'te ara
    try {
      final products =
          await _productService.getProducts(search: trimmed, size: 5);

      if (products.isNotEmpty) {
        final p = products.first;
        final row = BatchEntryRow(
          barcode: p['barcode']?.toString() ?? trimmed,
          productName: p['name']?.toString() ?? '',
          brandName: p['brand']?.toString(),
          categoryId: p['categoryId']?.toString(),
          categoryName: p['categoryName']?.toString(),
          purchasePrice: (p['purchasePrice'] as num?)?.toDouble() ??
              (p['basePrice'] as num?)?.toDouble() ?? 0,
          salePrice: (p['sellingPrice'] as num?)?.toDouble() ??
              (p['basePrice'] as num?)?.toDouble() ??
              0,
          vatRate: (p['taxRate'] as num?)?.toDouble() ?? 20.0,
          quantity: 1,
          status: RowStatus.existing,
          existingProductId: p['id']?.toString(),
          existingVariantId: p['variantId']?.toString(),
          existingVariantSku: p['sku']?.toString(),
        );
        state = state.copyWith(rows: [row, ...state.rows]);
        return '${row.productName} eklendi';
      }
    } catch (e) {
      AppLogger.error('Barkod arama hatasi', tag: 'BatchEntry', error: e);
    }

    // Bulunamadi -> yeni urun satiri
    final row = BatchEntryRow(
      barcode: trimmed,
      status: RowStatus.newProduct,
      vatRate: 20.0,
    );
    state = state.copyWith(rows: [row, ...state.rows]);
    return 'Yeni urun satiri acildi — bilgileri doldurun';
  }

  // --- Manuel Satir Ekle -----------------------------------------------------
  void addManualRow() {
    final row = BatchEntryRow(
      status: RowStatus.newProduct,
      vatRate: 20.0,
    );
    state = state.copyWith(rows: [row, ...state.rows]);
  }

  // --- Satir Guncelle --------------------------------------------------------
  void updateRow(
    String rowId, {
    String? productName,
    String? barcode,
    String? oemNumber,
    String? brandId,
    String? brandName,
    String? categoryId,
    String? categoryName,
    String? unitId,
    double? purchasePrice,
    double? salePrice,
    double? vatRate,
    int? quantity,
    bool? isExpanded,
    String? description,
    String? shelfLocation,
    int? minStockLevel,
    bool? vatIncluded,
    Map<String, String>? attributes,
    List<Map<String, String>>? oemList,
    List<Map<String, String>>? crossRefList,
    List<BatchVariantRow>? variantRows,
  }) {
    final rows = state.rows.map((r) {
      if (r.id != rowId) return r;
      return r.copyWith(
        productName: productName,
        barcode: barcode,
        oemNumber: oemNumber,
        brandId: brandId,
        brandName: brandName,
        categoryId: categoryId,
        categoryName: categoryName,
        unitId: unitId,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        vatRate: vatRate,
        quantity: quantity,
        isExpanded: isExpanded,
        description: description,
        shelfLocation: shelfLocation,
        minStockLevel: minStockLevel,
        vatIncluded: vatIncluded,
        attributes: attributes,
        oemList: oemList,
        crossRefList: crossRefList,
        variantRows: variantRows,
      );
    }).toList();
    state = state.copyWith(rows: rows);
  }

  // --- Satir Sil -------------------------------------------------------------
  void removeRow(String rowId) {
    state = state.copyWith(
      rows: state.rows.where((r) => r.id != rowId).toList(),
    );
  }

  // --- Baslik Guncelle -------------------------------------------------------
  void updateHeader({
    String? supplierId,
    String? supplierName,
    String? invoiceNumber,
    String? deliveryNoteNumber,
    DateTime? purchaseDate,
    String? storeId,
    String? storeName,
    String? warehouseId,
    String? warehouseName,
    bool? headerCollapsed,
  }) {
    state = state.copyWith(
      supplierId: supplierId,
      supplierName: supplierName,
      invoiceNumber: invoiceNumber,
      deliveryNoteNumber: deliveryNoteNumber,
      purchaseDate: purchaseDate,
      storeId: storeId,
      storeName: storeName,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      headerCollapsed: headerCollapsed,
    );
  }

  // --- Toplu Islemler --------------------------------------------------------
  void applyVatToAll(double vatRate) {
    final rows = state.rows.map((r) => r.copyWith(vatRate: vatRate)).toList();
    state = state.copyWith(rows: rows);
  }

  void applyCategoryToAll(String categoryId, String categoryName) {
    final rows = state.rows.map((r) {
      if (!r.isNew) return r;
      return r.copyWith(categoryId: categoryId, categoryName: categoryName);
    }).toList();
    state = state.copyWith(rows: rows);
  }

  void applyBrandToAll(String brandId, String brandName) {
    final rows = state.rows.map((r) {
      if (!r.isNew) return r;
      return r.copyWith(brandId: brandId, brandName: brandName);
    }).toList();
    state = state.copyWith(rows: rows);
  }

  void applyPriceToAll({double? purchasePrice, double? salePrice}) {
    final rows = state.rows
        .map((r) => r.copyWith(
              purchasePrice: purchasePrice,
              salePrice: salePrice,
            ))
        .toList();
    state = state.copyWith(rows: rows);
  }

  // --- Validasyon ------------------------------------------------------------
  String? validateAll() {
    if (state.rows.isEmpty) return 'En az bir urun ekleyin';
    if (state.supplierId == null) return 'Tedarikci secimi zorunludur';
    if (state.warehouseId == null) return 'Depo secimi zorunludur';
    if (state.storeId == null) return 'Magaza secimi zorunludur';

    for (int i = 0; i < state.rows.length; i++) {
      final r = state.rows[i];
      if (r.isSaved) continue;
      if (r.isNew && r.productName.trim().isEmpty) {
        return 'Satir ${i + 1}: Urun adi zorunludur';
      }
      if (r.isNew && (r.categoryId == null || r.categoryId!.isEmpty)) {
        return 'Satir ${i + 1}: Kategori secimi zorunludur';
      }
      if (r.salePrice <= 0) {
        return 'Satir ${i + 1}: Satis fiyati 0\'dan buyuk olmalidir';
      }
      if (r.quantity <= 0) {
        return 'Satir ${i + 1}: Miktar 0\'dan buyuk olmalidir';
      }
    }
    return null;
  }

  // --- TOPLU KAYDET ----------------------------------------------------------
  Future<BatchSaveResult> submitAll() async {
    final error = validateAll();
    if (error != null) throw Exception(error);

    state = state.copyWith(isSubmitting: true);
    int newCreated = 0;
    int stockUpdated = 0;
    int errors = 0;
    final errorMessages = <String>[];
    String? purchaseId;

    final pendingRows = state.rows.where((r) => !r.isSaved).toList();

    // 1. Mevcut urunler icin satin alma olustur
    final existingRows = pendingRows.where((r) => r.isExisting).toList();
    if (existingRows.isNotEmpty) {
      try {
        final purchaseData = {
          'supplierId': state.supplierId,
          'invoiceNumber': state.invoiceNumber ??
              'INV-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}',
          'purchaseDate':
              DateFormat('yyyy-MM-dd').format(state.purchaseDate),
          'storeId': state.storeId,
          'warehouseId': state.warehouseId,
          'deliveryNoteNumber': state.deliveryNoteNumber,
          'items': existingRows
              .map((r) => {
                    'variantId': r.existingVariantId,
                    'quantity': r.quantity,
                    'unitPrice': r.purchasePrice,
                  })
              .toList(),
        };
        final result = await _purchaseService.createPurchase(purchaseData);
        purchaseId = result['id']?.toString();

        // Basarili olanlari isaretle
        final updatedRows = List<BatchEntryRow>.from(state.rows);
        for (final row in existingRows) {
          final idx = updatedRows.indexWhere((r) => r.id == row.id);
          if (idx != -1) {
            updatedRows[idx] = row.copyWith(status: RowStatus.saved);
            stockUpdated++;
          }
        }
        state = state.copyWith(rows: updatedRows);
      } catch (e) {
        // Mevcut urunler toplu hata
        final updatedRows = List<BatchEntryRow>.from(state.rows);
        for (final row in existingRows) {
          final idx = updatedRows.indexWhere((r) => r.id == row.id);
          if (idx != -1) {
            updatedRows[idx] = row.copyWith(
              status: RowStatus.error,
              errorMessage: 'Satin alma olusturulamadi: $e',
            );
            errors++;
            errorMessages.add('${row.productName}: $e');
          }
        }
        state = state.copyWith(rows: updatedRows);
      }
    }

    // 2. Yeni urunler icin tek tek olustur
    final newRows = pendingRows.where((r) => r.isNew).toList();
    for (final row in newRows) {
      try {
        // Satiri saving durumuna al
        _updateRowStatus(row.id, RowStatus.saving);

        final sku =
            'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        final payload = {
          'product': {
            'name': row.productName,
            'sku': sku,
            'categoryId': row.categoryId,
            'brand': row.brandName ?? '',
            'unit': row.unitId ?? 'pcs',
            'description': row.description ?? '',
            'sector': _sectorConfig.type.apiValue,
            'metadata': _buildMetadata(row),
          },
          'oemNumbers': _buildOemList(row),
          'crossReferences': row.crossRefList
              .where((c) => (c['crossRefNumber'] ?? '').isNotEmpty)
              .map((c) => {
                    'crossRefNumber': c['crossRefNumber'],
                    'crossRefBrand': c['crossRefBrand'] ?? '',
                  })
              .toList(),
          'variants': [
            {
              'sku': sku,
              'name': row.productName,
              'shelfLocationCode': row.shelfLocation,
              'attributes': row.attributes,
              'minStockLevel': row.minStockLevel,
              'pricing': {
                'purchasePrice': row.purchasePrice,
                'salePrice': row.salePrice,
                'vatRate': row.vatRate,
                'vatIncluded': row.vatIncluded,
                'taxExempt': false,
                'specialTaxRate': null,
                'withholdingTaxRate': null,
              },
              'initialStocks': [
                {
                  'storeId': state.storeId,
                  'warehouseId': state.warehouseId,
                  'quantity': row.quantity,
                },
              ],
              'barcodes': row.barcode.isNotEmpty
                  ? [
                      {
                        'code': row.barcode,
                        'type': 'EAN13',
                        'isPrimary': true,
                      }
                    ]
                  : [],
            },
          ],
          'purchase': {
            'supplierId': state.supplierId,
            'invoiceNumber': state.invoiceNumber ??
                'INV-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}',
            'purchaseDate':
                DateFormat('yyyy-MM-dd').format(state.purchaseDate),
            'storeId': state.storeId,
            'warehouseId': state.warehouseId,
            'deliveryNoteNumber': state.deliveryNoteNumber,
            'notes': null,
          },
        };

        await _productService.createProduct(payload);

        _updateRowStatus(row.id, RowStatus.saved);
        newCreated++;
      } catch (e) {
        _updateRowStatus(row.id, RowStatus.error, errorMessage: '$e');
        errors++;
        errorMessages.add('${row.productName}: $e');
      }
    }

    state = state.copyWith(isSubmitting: false);

    return BatchSaveResult(
      totalProcessed: pendingRows.length,
      newCreated: newCreated,
      stockUpdated: stockUpdated,
      errors: errors,
      errorMessages: errorMessages,
      purchaseId: purchaseId,
    );
  }

  void _updateRowStatus(String rowId, RowStatus status,
      {String? errorMessage}) {
    final rows = state.rows.map((r) {
      if (r.id != rowId) return r;
      return r.copyWith(status: status, errorMessage: errorMessage);
    }).toList();
    state = state.copyWith(rows: rows);
  }

  /// oemList doluysa ondan, değilse tek oemNumber field'ından oluşturur
  List<Map<String, dynamic>> _buildOemList(BatchEntryRow row) {
    if (row.oemList.isNotEmpty) {
      return row.oemList
          .where((o) => (o['oemNumber'] ?? '').isNotEmpty)
          .map((o) => {
                'oemNumber': o['oemNumber'],
                'manufacturer': o['manufacturer'] ?? '',
                'isPrimary': o == row.oemList.first,
              })
          .toList();
    }
    if (row.oemNumber != null && row.oemNumber!.trim().isNotEmpty) {
      return [
        {
          'oemNumber': row.oemNumber!.trim(),
          'manufacturer': '',
          'isPrimary': true,
        }
      ];
    }
    return [];
  }

  Map<String, dynamic>? _buildMetadata(BatchEntryRow row) {
    final meta = <String, dynamic>{};
    switch (_sectorConfig.type) {
      case SectorType.autoParts:
        if (row.shelfLocation != null) meta['shelfLocation'] = row.shelfLocation;
        if (row.oemList.isNotEmpty) meta['oemCount'] = row.oemList.length;
      case SectorType.technology:
        if (row.shelfLocation != null) meta['imeiSerial'] = row.shelfLocation;
      case SectorType.footwear:
        // fabric, season fields can be added here in future
        break;
      case SectorType.general:
        if (row.shelfLocation != null) meta['shelfLocation'] = row.shelfLocation;
    }
    return meta.isEmpty ? null : meta;
  }

  // --- Temizle ---------------------------------------------------------------
  void clearAll() {
    state = state.copyWith(rows: []);
  }

  void clearSavedRows() {
    state = state.copyWith(
      rows: state.rows.where((r) => !r.isSaved).toList(),
    );
  }
}

final batchEntryProvider =
    StateNotifierProvider.autoDispose<BatchEntryNotifier, BatchEntryState>(
  (ref) => BatchEntryNotifier(
    ref.read(productServiceProvider),
    ref.read(purchaseServiceProvider),
    ref.read(oemServiceProvider),
    ref.read(sectorConfigProvider),
  ),
);

/// Kategori listesi — kart içindeki dropdown için paylaşımlı cache
final batchCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(companyCategoryServiceProvider).getMyCategoryList(),
);
