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
        name: 'Fren Balatası Ön Takım (Bosch)',
        sku: 'BOS-FB-003',
        barcode: '4047024567891',
        category: 'Fren Sistemi',
        brand: 'Bosch',
        unit: 'Adet',
        buyPrice: 330.00,
        sellPrice: 460.00,
        taxRate: 18.0,
        stock: 50,
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
        name: 'Triger Seti Komple (Gates) K025603XS',
        sku: 'GAT-TS-003',
        barcode: '5412571234568',
        category: 'Kayış/Gergi',
        brand: 'Gates',
        unit: 'Adet',
        buyPrice: 850.00,
        sellPrice: 1300.00,
        taxRate: 18.0,
        stock: 20,
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
        name: 'Yağ Filtresi (Mann Filter) W 712/95',
        sku: 'MAN-YF-002',
        barcode: '4011558022342',
        category: 'Filtreler',
        brand: 'Mann Filter',
        unit: 'Adet',
        buyPrice: 60.00,
        sellPrice: 92.00,
        taxRate: 18.0,
        stock: 100,
        status: ProductStatus.POTENTIAL_MATCH,
        confidence: 0.85,
        matchedProduct: MatchedProduct(
          id: 'PROD-5678',
          name: 'Yağ Filtresi (Mann Filter) W 712/94',
          sku: 'MAN-YF-001',
          barcode: '4011558022341',
          category: 'Filtreler',
          brand: 'Mann Filter',
          currentStock: 80,
          currentBuyPrice: 55.00,
          currentSellPrice: 85.00,
          variants: [],
          similarity: 0.85,
          lastUpdated: DateTime.now(),
        ),
        suggestedActions: [
          SuggestedAction(
            action: ActionType.ADD_VARIANT,
            label: 'Varyant Olarak Ekle',
            description: 'Ana ürün: W 712/94 → Yeni varyant: W 712/95',
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
        name: 'Amortisör Ön Sol (Sachs) 315 531',
        sku: 'SAC-AM-003',
        barcode: '4013872012346',
        category: 'Süspansiyon',
        brand: 'Sachs',
        unit: 'Adet',
        buyPrice: 600.00,
        sellPrice: 880.00,
        taxRate: 18.0,
        stock: 12,
        status: ProductStatus.POTENTIAL_MATCH,
        confidence: 0.90,
        matchedProduct: MatchedProduct(
          id: 'PROD-9999',
          name: 'Amortisör Ön (Sachs) 315 530',
          sku: 'SAC-AM-001',
          barcode: '4013872098765',
          category: 'Süspansiyon',
          brand: 'Sachs',
          currentStock: 10,
          currentBuyPrice: 560.00,
          currentSellPrice: 820.00,
          variants: [],
          similarity: 0.90,
          lastUpdated: DateTime.now(),
        ),
        suggestedActions: [
          SuggestedAction(
            action: ActionType.ADD_VARIANT,
            label: 'Varyant Olarak Ekle',
            description: 'Ana ürün: 315 530 → Yeni model: 315 531',
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
        name: 'Bujiler Takım (Bosch) FR7DC+',
        sku: 'BOS-BJ-001',
        barcode: '4047024098765',
        category: 'Motor Parçaları',
        brand: 'Bosch',
        unit: 'Adet',
        buyPrice: 210.00,
        sellPrice: 320.00,
        taxRate: 18.0,
        stock: 30,
        status: ProductStatus.CONFLICT,
        confidence: 1.0,
        matchedProduct: MatchedProduct(
          id: 'PROD-1234',
          name: 'Bujiler Takım (Bosch) FR7DC+',
          sku: 'BOS-BJ-001',
          barcode: '4047024098765',
          category: 'Motor Parçaları',
          brand: 'Bosch',
          currentStock: 35,
          currentBuyPrice: 200.00,
          currentSellPrice: 320.00,
          variants: [],
          similarity: 1.0,
          lastUpdated: DateTime.now(),
        ),
        suggestedActions: [
          SuggestedAction(
            action: ActionType.UPDATE_STOCK,
            label: 'Stoğa Ekle',
            description: '+30 adet ekle (fiyatlar aynı)',
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
