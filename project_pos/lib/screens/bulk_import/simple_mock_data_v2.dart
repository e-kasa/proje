import '../../models/bulk_import_models.dart';

/// Basit Mock Data V2 - Mevcut modelle uyumlu
class SimpleMockData {
  static const mockImportId = 'IMPORT-2025-001';

  static List<AnalyzedProduct> getTedarikciUrunleri() {
    return [
      // YENİ ÜRÜNLER
      AnalyzedProduct(
        tempId: 'TEMP-001',
        importId: mockImportId,
        name: 'iPhone 15 Pro 256GB',
        sku: 'APL-IP15P-256',
        barcode: '1234567890123',
        category: 'Telefon',
        brand: 'Apple',
        unit: 'Adet',
        buyPrice: 45000.00,
        sellPrice: 58000.00,
        taxRate: 18.0,
        stock: 10,
        status: ProductStatus.NEW,
        confidence: 1.0,
        suggestedActions: [
          SuggestedAction(
            action: ActionType.CREATE,
            label: 'Ürünü Oluştur',
            description: 'Yeni ürün olarak sistemde ekle',
            recommended: true,
          ),
        ],
        errors: [],
      ),

      AnalyzedProduct(
        tempId: 'TEMP-002',
        importId: mockImportId,
        name: 'Samsung Galaxy S24 Ultra 512GB',
        sku: 'SAM-S24U-512',
        barcode: '9876543210987',
        category: 'Telefon',
        brand: 'Samsung',
        unit: 'Adet',
        buyPrice: 42000.00,
        sellPrice: 54000.00,
        taxRate: 18.0,
        stock: 15,
        status: ProductStatus.NEW,
        confidence: 1.0,
        suggestedActions: [
          SuggestedAction(
            action: ActionType.CREATE,
            label: 'Ürünü Oluştur',
            description: 'Yeni ürün olarak sistemde ekle',
            recommended: true,
          ),
        ],
        errors: [],
      ),

      // BENZER ÜRÜNLER (Varyant olabilir)
      AnalyzedProduct(
        tempId: 'TEMP-003',
        importId: mockImportId,
        name: 'AirPods Pro 2. Nesil - Beyaz',
        sku: 'APL-APRO2-WHT',
        barcode: '1112223334445',
        category: 'Kulaklık',
        brand: 'Apple',
        unit: 'Adet',
        buyPrice: 7500.00,
        sellPrice: 9500.00,
        taxRate: 18.0,
        stock: 20,
        status: ProductStatus.POTENTIAL_MATCH,
        confidence: 0.85,
        matchedProduct: MatchedProduct(
          id: 'PROD-5678',
          name: 'AirPods Pro 2. Nesil',
          sku: 'APL-APRO2',
          barcode: '1112223334440',
          category: 'Kulaklık',
          brand: 'Apple',
          currentStock: 50,
          currentBuyPrice: 7000.00,
          currentSellPrice: 9000.00,
          variants: [],
          similarity: 0.85,
          lastUpdated: DateTime.now(),
        ),
        suggestedActions: [
          SuggestedAction(
            action: ActionType.ADD_VARIANT,
            label: 'Varyant Olarak Ekle',
            description: 'Ana ürün: AirPods Pro → Yeni varyant: Beyaz',
            recommended: true,
          ),
          SuggestedAction(
            action: ActionType.CREATE,
            label: 'Yeni Ürün Oluştur',
            description: 'Tamamen farklı ürün olarak ekle',
            recommended: false,
          ),
        ],
        errors: [],
      ),

      AnalyzedProduct(
        tempId: 'TEMP-005',
        importId: mockImportId,
        name: 'iPhone 15 Pro - Kırmızı 256GB',
        sku: 'APL-IP15P-RED-256',
        barcode: '2223334445556',
        category: 'Telefon',
        brand: 'Apple',
        unit: 'Adet',
        buyPrice: 46000.00,
        sellPrice: 59000.00,
        taxRate: 18.0,
        stock: 8,
        status: ProductStatus.POTENTIAL_MATCH,
        confidence: 0.90,
        matchedProduct: MatchedProduct(
          id: 'PROD-9999',
          name: 'iPhone 15 Pro 256GB',
          sku: 'APL-IP15P-256',
          barcode: '1234567890120',
          category: 'Telefon',
          brand: 'Apple',
          currentStock: 25,
          currentBuyPrice: 45000.00,
          currentSellPrice: 58000.00,
          variants: [],
          similarity: 0.90,
          lastUpdated: DateTime.now(),
        ),
        suggestedActions: [
          SuggestedAction(
            action: ActionType.ADD_VARIANT,
            label: 'Varyant Olarak Ekle',
            description: 'Ana ürün: iPhone 15 Pro → Yeni renk: Kırmızı',
            recommended: true,
          ),
          SuggestedAction(
            action: ActionType.CREATE,
            label: 'Yeni Ürün Oluştur',
            description: 'Ayrı ürün olarak ekle',
            recommended: false,
          ),
        ],
        errors: [],
      ),

      // MEVCUT ÜRÜN (Stok ekle)
      AnalyzedProduct(
        tempId: 'TEMP-004',
        importId: mockImportId,
        name: 'iPhone 14 128GB Siyah',
        sku: 'APL-IP14-128-BLK',
        barcode: '7778889990001',
        category: 'Telefon',
        brand: 'Apple',
        unit: 'Adet',
        buyPrice: 32000.00,
        sellPrice: 40000.00,
        taxRate: 18.0,
        stock: 8,
        status: ProductStatus.CONFLICT,
        confidence: 1.0,
        matchedProduct: MatchedProduct(
          id: 'PROD-1234',
          name: 'iPhone 14 128GB Siyah',
          sku: 'APL-IP14-128-BLK',
          barcode: '7778889990001',
          category: 'Telefon',
          brand: 'Apple',
          currentStock: 12,
          currentBuyPrice: 32000.00,
          currentSellPrice: 40000.00,
          variants: [],
          similarity: 1.0,
          lastUpdated: DateTime.now(),
        ),
        suggestedActions: [
          SuggestedAction(
            action: ActionType.UPDATE_STOCK,
            label: 'Stoğa Ekle',
            description: '+8 adet ekle (fiyatlar aynı)',
            recommended: true,
          ),
        ],
        errors: [],
      ),
    ];
  }

  static ImportStatistics getMockStatistics() {
    final products = getTedarikciUrunleri();
    return ImportStatistics(
      total: products.length,
      newProducts: products.where((p) => p.status == ProductStatus.NEW).length,
      conflicts: products.where((p) => p.status == ProductStatus.CONFLICT).length,
      potentialMatches: products.where((p) => p.status == ProductStatus.POTENTIAL_MATCH).length,
      addVariants: 0,
      updateVariants: 0,
      needsVariants: 0,
      createVariantGroups: 0,
      errors: 0,
    );
  }

  static Map<String, dynamic> getMockAnalyzeResponse() {
    final products = getTedarikciUrunleri();
    return {
      'importId': mockImportId,
      'status': 'COMPLETED',
      'products': products.map((p) => p.toJson()).toList(),
      'statistics': getMockStatistics().toJson(),
    };
  }
}
