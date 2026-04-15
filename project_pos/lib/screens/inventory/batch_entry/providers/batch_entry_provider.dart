import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/product_service.dart';
import '../../../../services/oem_service.dart';
import '../../../../services/service_locator.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/config/sector_config.dart';
import '../../../../providers/sector_provider.dart';
import '../models/batch_entry_models.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/features/inventory/services/document_analyze_service.dart';

class BatchEntryNotifier extends StateNotifier<BatchEntryState> {
  final ProductService _productService;
  // ignore: unused_field
  final OemService _oemService;
  final SectorConfig _sectorConfig;

  BatchEntryNotifier(
    this._productService,
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

  // --- Döküman Analizi'nden Satır Ekle ----------------------------------------
  void addFromDocumentItems(List<DocumentAnalyzeItem> items) {
    final newRows = items.map((item) {
      final vat = item.vatRate ?? 20.0;
      final vatIncluded = item.vatIncluded ?? false;
      final unitId = _mapUnit(item.unit);

      if (item.isFound && item.matchedVariantId != null) {
        // Mevcut ürün → existing satır
        return BatchEntryRow(
          productName: item.matchedProductName ??
              item.extractedName ??
              item.rawText,
          barcode: item.extractedCode ?? '',
          quantity: item.extractedQuantity?.toInt() ?? 1,
          purchasePrice: item.extractedUnitPrice ?? 0,
          salePrice: item.extractedUnitPrice ?? 0,
          vatRate: vat,
          vatIncluded: vatIncluded,
          unitId: unitId,
          status: RowStatus.existing,
          existingVariantId: item.matchedVariantId,
          existingProductId: item.matchedProductId,
          existingVariantSku: item.matchedSku,
        );
      } else {
        // Yeni ürün → newProduct satır
        return BatchEntryRow(
          productName: item.extractedName ?? item.rawText,
          barcode: item.extractedCode ?? '',
          quantity: item.extractedQuantity?.toInt() ?? 1,
          purchasePrice: item.extractedUnitPrice ?? 0,
          salePrice: item.extractedUnitPrice ?? 0,
          vatRate: vat,
          vatIncluded: vatIncluded,
          unitId: unitId,
          status: RowStatus.newProduct,
        );
      }
    }).toList();

    // Yeni satırları listenin başına ekle
    state = state.copyWith(rows: [...newRows, ...state.rows]);
  }

  /// Faturadan gelen birim string'ini sistem birim koduna çevirir.
  String? _mapUnit(String? unit) => switch (unit?.toUpperCase()) {
    'ADET' || 'ADT' || 'PCS' => 'adet',
    'KG'   || 'KGR'          => 'kg',
    'LT'   || 'LTR'          => 'lt',
    'MT'   || 'MTR'          => 'mt',
    'M2'                     => 'm2',
    'GR'   || 'GRAM'         => 'gr',
    _                        => 'adet',  // bilinmiyorsa adet default
  };

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
    String? locationId,
    String? locationName,
    String? locationType,
    bool? headerCollapsed,
  }) {
    state = state.copyWith(
      supplierId: supplierId,
      supplierName: supplierName,
      invoiceNumber: invoiceNumber,
      deliveryNoteNumber: deliveryNoteNumber,
      purchaseDate: purchaseDate,
      locationId: locationId,
      locationName: locationName,
      locationType: locationType,
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
    if (state.rows.isEmpty) return 'batch.min_one_product';
    if (state.supplierId == null) return 'batch.supplier_required';
    if (state.locationId == null) return 'batch.location_required';

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

    final pendingRows = state.rows.where((r) => !r.isSaved).toList();
    final invoiceNumber = state.invoiceNumber ??
        'INV-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';
    final purchaseDate = DateFormat('yyyy-MM-dd').format(state.purchaseDate);
    final isFootwear = _sectorConfig.type == SectorType.footwear;

    // Tüm satırları saving durumuna al
    _markRowsAsSaving(pendingRows.map((r) => r.id).toList());

    // ── Yeni ürün kalemlerini oluştur ─────────────────────────────────────
    final newRows = pendingRows.where((r) => r.isNew).toList();
    final newProductItems = newRows.map((row) {
      final sku = _generateSku();

      // Footwear: variantRows → çoklu variant; diğerleri: tek variant
      final variants = (isFootwear && row.variantRows.isNotEmpty)
          ? row.variantRows.map((vr) => {
                'sku': _generateSku(),
                'name': '${row.productName} - ${vr.size}'
                    '${vr.color.isNotEmpty ? " ${vr.color}" : ""}',
                'shelfLocationCode': row.shelfLocation,
                'attributes': {
                  'Numara': vr.size,
                  if (vr.color.isNotEmpty) 'Renk': vr.color,
                },
                'pricing': {
                  'purchasePrice': vr.purchasePrice ?? row.purchasePrice,
                  'salePrice': vr.salePrice ?? row.salePrice,
                  'vatRate': row.vatRate,
                  'vatIncluded': row.vatIncluded,
                  'taxExempt': false,
                },
                'initialStocks': [
                  {
                    'locationId': state.locationId,
                    'locationType': state.locationType ?? 'STORE',
                    'quantity': vr.quantity,
                  }
                ],
                'barcodes': vr.barcode.isNotEmpty
                    ? [{'code': vr.barcode, 'type': 'EAN13', 'isPrimary': true}]
                    : [],
              }).toList()
          : [
              {
                'sku': sku,
                'name': row.productName,
                'shelfLocationCode': row.shelfLocation,
                'attributes': row.attributes,
                'pricing': {
                  'purchasePrice': row.purchasePrice,
                  'salePrice': row.salePrice,
                  'vatRate': row.vatRate,
                  'vatIncluded': row.vatIncluded,
                  'taxExempt': false,
                },
                'initialStocks': [
                  {
                    'locationId': state.locationId,
                    'locationType': state.locationType ?? 'STORE',
                    'quantity': row.quantity,
                  }
                ],
                'barcodes': row.barcode.isNotEmpty
                    ? [{'code': row.barcode, 'type': 'EAN13', 'isPrimary': true}]
                    : [],
              }
            ];

      return {
        'tempId': row.id,
        'product': {
          'name': row.productName,
          'sku': sku,
          'categoryId': row.categoryId,
          'brand': row.brandName ?? '',
          'unit': row.unitId ?? 'adet',
          'description': row.description ?? '',
          'sector': _sectorConfig.type.apiValue,
          'metadata': _buildMetadata(row),
        },
        'variants': variants,
        'oemNumbers': _buildOemList(row),
        'crossReferences': row.crossRefList
            .where((c) => (c['crossRefNumber'] ?? '').isNotEmpty)
            .map((c) => {
                  'crossRefNumber': c['crossRefNumber'],
                  'crossRefBrand': c['crossRefBrand'] ?? '',
                })
            .toList(),
      };
    }).toList();

    // ── Mevcut ürün kalemlerini oluştur ───────────────────────────────────
    final existingRows = pendingRows.where((r) => r.isExisting).toList();
    final existingItems = existingRows.map((row) => {
          'tempId': row.id,
          'variantId': row.existingVariantId,
          'quantity': row.quantity,
          'unitPrice': row.purchasePrice,
          'taxRate': row.vatRate,
        }).toList();

    // ── Tek toplu istek ───────────────────────────────────────────────────
    final batchRequest = {
      'supplierId': state.supplierId,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': purchaseDate,
      'locationId': state.locationId,
      'locationType': state.locationType ?? 'STORE',
      'deliveryNoteNumber': state.deliveryNoteNumber,
      'newProducts': newProductItems,
      'existingProducts': existingItems,
    };

    try {
      final response = await _productService.batchCreate(batchRequest);

      final results = List<Map<String, dynamic>>.from(
        (response['results'] as List?) ?? [],
      );
      final purchaseId = response['purchaseId']?.toString();

      // Sonuçları satırlara eşle
      int newCreated = 0;
      int stockUpdated = 0;
      int errors = 0;
      final errorMessages = <String>[];
      final updatedRows = List<BatchEntryRow>.from(state.rows);

      for (final result in results) {
        final tempId = result['tempId']?.toString();
        final success = result['success'] as bool? ?? false;
        final message = result['message']?.toString();
        final idx = updatedRows.indexWhere((r) => r.id == tempId);
        if (idx == -1) continue;

        final originalRow = updatedRows[idx];
        if (success) {
          updatedRows[idx] = originalRow.copyWith(status: RowStatus.saved);
          if (originalRow.isExisting) stockUpdated++;
          else newCreated++;
        } else {
          updatedRows[idx] = originalRow.copyWith(
            status: RowStatus.error,
            errorMessage: message ?? 'Bilinmeyen hata',
          );
          errors++;
          errorMessages.add('${originalRow.productName}: ${message ?? ""}');
        }
      }

      state = state.copyWith(rows: updatedRows, isSubmitting: false);

      return BatchSaveResult(
        totalProcessed: pendingRows.length,
        newCreated: newCreated,
        stockUpdated: stockUpdated,
        errors: errors,
        errorMessages: errorMessages,
        purchaseId: purchaseId,
      );
    } catch (e) {
      // Tüm satırları error yap
      final updatedRows = state.rows.map((r) {
        if (!pendingRows.any((p) => p.id == r.id)) return r;
        return r.copyWith(status: RowStatus.error, errorMessage: '$e');
      }).toList();
      state = state.copyWith(rows: updatedRows, isSubmitting: false);
      rethrow;
    }
  }

  /// Satırları saving durumuna al
  void _markRowsAsSaving(List<String> rowIds) {
    final updatedRows = state.rows.map((r) {
      if (!rowIds.contains(r.id)) return r;
      return r.copyWith(status: RowStatus.saving);
    }).toList();
    state = state.copyWith(rows: updatedRows);
  }

  String _generateSku() =>
      'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
      '-${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';


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
        // IMEI attributes['imei'] alanında saklanır (ayrı SerialNumber entity yok)
        if (row.oemNumber != null && row.oemNumber!.isNotEmpty)
          meta['imei'] = row.oemNumber;
        if (row.shelfLocation != null) meta['shelfLocation'] = row.shelfLocation;
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
    ref.read(oemServiceProvider),
    ref.read(sectorConfigProvider),
  ),
);

/// Kategori listesi — kart içindeki dropdown için paylaşımlı cache
final batchCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(companyCategoryServiceProvider).getMyCategoryList(),
);
