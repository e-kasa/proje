import '../models/stock_management_models.dart';

/// MOCK DATA - Stok Yönetimi
/// Tedarikçi ithalat mock data'sından esinlenilmiştir

class MockStockManagementData {
  // ==========================================================================
  // 1. MULTI-WAREHOUSE STOCK DATA
  // ==========================================================================

  static List<WarehouseStockItem> getWarehouseStockData() {
    return [
      // 1. Ürün - Birden fazla depoda var
      WarehouseStockItem(
        productId: 'prod-001',
        productName: 'iPhone 15 Pro 256GB',
        sku: 'SKU-IPHONE-15-256',
        barcode: '8699123456789',
        brand: 'Apple',
        category: 'Elektronik',
        totalStock: 45,
        unitPrice: 45000.00,
        unit: 'Adet',
        locationStocks: [
          LocationStock(
            locationId: 'wh-merkez',
            locationName: 'Merkez Depo',
            locationType: LocationType.WAREHOUSE,
            quantity: 25,
            shelfLocation: 'A-12',
            minStock: 10,
            maxStock: 50,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          LocationStock(
            locationId: 'store-kadikoy',
            locationName: 'Kadıköy Mağazası',
            locationType: LocationType.STORE,
            quantity: 15,
            shelfLocation: 'Vitrin-1',
            minStock: 5,
            maxStock: 20,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          LocationStock(
            locationId: 'store-besiktas',
            locationName: 'Beşiktaş Mağazası',
            locationType: LocationType.STORE,
            quantity: 5,
            shelfLocation: 'Raf-B2',
            minStock: 5,
            maxStock: 15,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      ),

      // 2. Ürün - Düşük stok uyarısı
      WarehouseStockItem(
        productId: 'prod-002',
        productName: 'Samsung Galaxy S24 Ultra',
        sku: 'SKU-S24-ULTRA',
        barcode: '8699987654321',
        brand: 'Samsung',
        category: 'Elektronik',
        totalStock: 8,
        unitPrice: 42000.00,
        unit: 'Adet',
        locationStocks: [
          LocationStock(
            locationId: 'wh-merkez',
            locationName: 'Merkez Depo',
            locationType: LocationType.WAREHOUSE,
            quantity: 3,
            shelfLocation: 'A-15',
            minStock: 10,
            maxStock: 40,
            lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
          ),
          LocationStock(
            locationId: 'store-kadikoy',
            locationName: 'Kadıköy Mağazası',
            locationType: LocationType.STORE,
            quantity: 5,
            shelfLocation: 'Vitrin-2',
            minStock: 8,
            maxStock: 15,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
      ),

      // 3. Ürün - Bir depoda tükendi
      WarehouseStockItem(
        productId: 'prod-003',
        productName: 'MacBook Air M3',
        sku: 'SKU-MBA-M3',
        barcode: '8699111222333',
        brand: 'Apple',
        category: 'Bilgisayar',
        totalStock: 12,
        unitPrice: 52000.00,
        unit: 'Adet',
        locationStocks: [
          LocationStock(
            locationId: 'wh-merkez',
            locationName: 'Merkez Depo',
            locationType: LocationType.WAREHOUSE,
            quantity: 12,
            shelfLocation: 'B-08',
            minStock: 5,
            maxStock: 30,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 12)),
          ),
          LocationStock(
            locationId: 'store-besiktas',
            locationName: 'Beşiktaş Mağazası',
            locationType: LocationType.STORE,
            quantity: 0,
            shelfLocation: 'Raf-C1',
            minStock: 3,
            maxStock: 10,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
        ],
      ),

      // 4. Ürün - Şubede kritik stok
      WarehouseStockItem(
        productId: 'prod-004',
        productName: 'AirPods Pro 2',
        sku: 'SKU-AIRPODS-PRO2',
        barcode: '8699444555666',
        brand: 'Apple',
        category: 'Aksesuar',
        totalStock: 38,
        unitPrice: 9500.00,
        unit: 'Adet',
        locationStocks: [
          LocationStock(
            locationId: 'wh-merkez',
            locationName: 'Merkez Depo',
            locationType: LocationType.WAREHOUSE,
            quantity: 30,
            shelfLocation: 'C-22',
            minStock: 20,
            maxStock: 100,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          LocationStock(
            locationId: 'store-kadikoy',
            locationName: 'Kadıköy Mağazası',
            locationType: LocationType.STORE,
            quantity: 5,
            shelfLocation: 'Vitrin-A',
            minStock: 10,
            maxStock: 30,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          LocationStock(
            locationId: 'branch-ankara',
            locationName: 'Ankara Şubesi',
            locationType: LocationType.BRANCH,
            quantity: 3,
            shelfLocation: 'D-11',
            minStock: 5,
            maxStock: 20,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ],
      ),
    ];
  }

  // ==========================================================================
  // 2. STOCK TRANSFER DATA
  // ==========================================================================

  static StockTransferResponse getMockTransferRequest() {
    final now = DateTime.now();

    return StockTransferResponse(
      transferId: 'TRANSFER-2025-001',
      itemCount: 4,
      status: TransferStatus.PENDING,
      createdAt: now.subtract(const Duration(hours: 2)),
      createdBy: 'Ahmet Yılmaz (Beşiktaş Mağaza Müdürü)',
      items: [
        // 1. Transfer - Yeterli stok var
        TransferItem(
          productId: 'prod-001',
          productName: 'iPhone 15 Pro 256GB',
          sku: 'SKU-IPHONE-15-256',
          barcode: '8699123456789',
          requestedQuantity: 10,
          availableStock: 25,
          sourceLocation: LocationStock(
            locationId: 'wh-merkez',
            locationName: 'Merkez Depo',
            locationType: LocationType.WAREHOUSE,
            quantity: 25,
            shelfLocation: 'A-12',
            minStock: 10,
            maxStock: 50,
          ),
          targetLocation: LocationStock(
            locationId: 'store-besiktas',
            locationName: 'Beşiktaş Mağazası',
            locationType: LocationType.STORE,
            quantity: 5,
            shelfLocation: 'Raf-B2',
            minStock: 5,
            maxStock: 15,
          ),
        ),

        // 2. Transfer - Stok yetersiz (kısmi onay gerekebilir)
        TransferItem(
          productId: 'prod-002',
          productName: 'Samsung Galaxy S24 Ultra',
          sku: 'SKU-S24-ULTRA',
          barcode: '8699987654321',
          requestedQuantity: 8,
          availableStock: 3,
          sourceLocation: LocationStock(
            locationId: 'wh-merkez',
            locationName: 'Merkez Depo',
            locationType: LocationType.WAREHOUSE,
            quantity: 3,
            shelfLocation: 'A-15',
            minStock: 10,
            maxStock: 40,
          ),
          targetLocation: LocationStock(
            locationId: 'store-kadikoy',
            locationName: 'Kadıköy Mağazası',
            locationType: LocationType.STORE,
            quantity: 5,
            shelfLocation: 'Vitrin-2',
            minStock: 8,
            maxStock: 15,
          ),
        ),

        // 3. Transfer - Kaynak depoda minimum seviyenin altına düşecek
        TransferItem(
          productId: 'prod-003',
          productName: 'MacBook Air M3',
          sku: 'SKU-MBA-M3',
          barcode: '8699111222333',
          requestedQuantity: 5,
          availableStock: 12,
          sourceLocation: LocationStock(
            locationId: 'wh-merkez',
            locationName: 'Merkez Depo',
            locationType: LocationType.WAREHOUSE,
            quantity: 12,
            shelfLocation: 'B-08',
            minStock: 10,
            maxStock: 30,
          ),
          targetLocation: LocationStock(
            locationId: 'store-besiktas',
            locationName: 'Beşiktaş Mağazası',
            locationType: LocationType.STORE,
            quantity: 0,
            shelfLocation: 'Raf-C1',
            minStock: 3,
            maxStock: 10,
          ),
        ),

        // 4. Transfer - Normal transfer
        TransferItem(
          productId: 'prod-004',
          productName: 'AirPods Pro 2',
          sku: 'SKU-AIRPODS-PRO2',
          barcode: '8699444555666',
          requestedQuantity: 15,
          availableStock: 30,
          sourceLocation: LocationStock(
            locationId: 'wh-merkez',
            locationName: 'Merkez Depo',
            locationType: LocationType.WAREHOUSE,
            quantity: 30,
            shelfLocation: 'C-22',
            minStock: 20,
            maxStock: 100,
          ),
          targetLocation: LocationStock(
            locationId: 'branch-ankara',
            locationName: 'Ankara Şubesi',
            locationType: LocationType.BRANCH,
            quantity: 3,
            shelfLocation: 'D-11',
            minStock: 5,
            maxStock: 20,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 3. STOCK COUNT DATA
  // ==========================================================================

  static StockCountResponse getMockStockCount() {
    return StockCountResponse(
      countId: 'COUNT-2025-001',
      productCount: 5,
      countDate: DateTime.now().subtract(const Duration(hours: 1)),
      countedBy: 'Mehmet Demir (Depo Sorumlusu)',
      products: [
        // 1. Fark yok
        CountedProduct(
          productId: 'prod-001',
          productName: 'iPhone 15 Pro 256GB',
          sku: 'SKU-IPHONE-15-256',
          barcode: '8699123456789',
          systemStock: 25,
          countedStock: 25,
          difference: 0,
          locationId: 'wh-merkez',
          locationName: 'Merkez Depo',
        ),

        // 2. Fazla çıktı (+)
        CountedProduct(
          productId: 'prod-002',
          productName: 'Samsung Galaxy S24 Ultra',
          sku: 'SKU-S24-ULTRA',
          barcode: '8699987654321',
          systemStock: 3,
          countedStock: 5,
          difference: 2,
          locationId: 'wh-merkez',
          locationName: 'Merkez Depo',
        ),

        // 3. Eksik çıktı (-)
        CountedProduct(
          productId: 'prod-003',
          productName: 'MacBook Air M3',
          sku: 'SKU-MBA-M3',
          barcode: '8699111222333',
          systemStock: 12,
          countedStock: 10,
          difference: -2,
          locationId: 'wh-merkez',
          locationName: 'Merkez Depo',
        ),

        // 4. Büyük fark - Eksik (-)
        CountedProduct(
          productId: 'prod-004',
          productName: 'AirPods Pro 2',
          sku: 'SKU-AIRPODS-PRO2',
          barcode: '8699444555666',
          systemStock: 30,
          countedStock: 22,
          difference: -8,
          locationId: 'wh-merkez',
          locationName: 'Merkez Depo',
        ),

        // 5. Çok büyük fark - Fazla (+)
        CountedProduct(
          productId: 'prod-005',
          productName: 'Apple Watch Series 9',
          sku: 'SKU-AW-S9',
          barcode: '8699777888999',
          systemStock: 10,
          countedStock: 18,
          difference: 8,
          locationId: 'wh-merkez',
          locationName: 'Merkez Depo',
        ),
      ],
    );
  }
}
