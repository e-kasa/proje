import '../models/backend_product_import.dart';

/// Backend response mock data - Backend'in döneceği formatta
class MockBackendImportData {
  static BackendImportResponse getMockImportResponse() {
    return BackendImportResponse(
      importId: 'IMPORT-2025-001',
      total: 5,
      products: [
        // YENİ ÜRÜN - Sistemde yok
        BackendAnalyzedProduct(
          tempId: 'TEMP-001',
          status: ProductImportStatus.NEW,
          confidence: 1.0,
          suggestions: [
            'Yeni ürün olarak kaydet',
            'Kategori ve marka bilgilerini kontrol et',
          ],
          reason: 'Sistemde bu SKU ile ürün bulunamadı',
          payload: {
            'product': {
              'sku': 'APL-IP15P-256',
              'name': 'iPhone 15 Pro 256GB',
              'categoryId': 'cat-123',
              'brand': 'Apple',
              'unit': 'Adet',
            },
            'variants': [
              {
                'sku': 'APL-IP15P-256',
                'name': 'Varsayılan',
                'attributes': {},
                'pricing': {
                  'purchasePrice': 45000.00,
                  'salePrice': 58000.00,
                  'taxRate': 18.0,
                },
                'initialStocks': [
                  {
                    'storeId': 'store-1',
                    'warehouseId': 'WH-001',
                    'quantity': 10,
                  }
                ],
                'barcodes': [
                  {
                    'code': '1234567890123',
                    'type': 'EAN13',
                    'primary': true,
                  }
                ],
              }
            ],
            'purchase': {
              'supplierId': 'supplier-apple',
              'invoiceNumber': 'FAT-2025-001',
              'purchaseDate': '2025-01-03',
            },
          },
        ),

        // BENZER ÜRÜN - Varyant olabilir
        BackendAnalyzedProduct(
          tempId: 'TEMP-002',
          status: ProductImportStatus.SIMILAR,
          confidence: 0.85,
          suggestions: [
            'Mevcut ürüne varyant olarak ekle',
            'Yeni ürün olarak oluştur',
          ],
          reason: 'Ürün adı çok benzer, renk/model farklı olabilir',
          similarProducts: [
            SimilarProduct(
              productId: 'PROD-5678',
              productName: 'AirPods Pro 2. Nesil',
              similarity: 0.85,
              reason: 'İsim benzerliği %85, mevcut varyantlar: Siyah, Gri',
            ),
          ],
          payload: {
            'product': {
              'sku': 'APL-APRO2-WHT',
              'name': 'AirPods Pro 2. Nesil - Beyaz',
              'categoryId': 'cat-456',
              'brand': 'Apple',
              'unit': 'Adet',
            },
            'variants': [
              {
                'sku': 'APL-APRO2-WHT',
                'name': 'Beyaz',
                'attributes': {
                  'Renk': 'Beyaz',
                },
                'pricing': {
                  'purchasePrice': 7500.00,
                  'salePrice': 9500.00,
                  'taxRate': 18.0,
                },
                'initialStocks': [
                  {
                    'storeId': 'store-1',
                    'warehouseId': 'WH-001',
                    'quantity': 20,
                  }
                ],
                'barcodes': [
                  {
                    'code': '1112223334445',
                    'type': 'EAN13',
                    'primary': true,
                  }
                ],
              }
            ],
            'purchase': {
              'supplierId': 'supplier-apple',
              'invoiceNumber': 'FAT-2025-001',
              'purchaseDate': '2025-01-03',
            },
          },
        ),

        // BENZER ÜRÜN 2 - Farklı kapasite
        BackendAnalyzedProduct(
          tempId: 'TEMP-003',
          status: ProductImportStatus.SIMILAR,
          confidence: 0.90,
          suggestions: [
            'Mevcut ürüne varyant olarak ekle (Kapasite varyantı)',
            'Yeni ürün olarak oluştur',
          ],
          reason: 'Aynı model, farklı kapasite',
          similarProducts: [
            SimilarProduct(
              productId: 'PROD-9999',
              productName: 'iPhone 15 Pro 128GB',
              similarity: 0.90,
              reason: 'Aynı model, sadece kapasite farklı (128GB vs 256GB)',
            ),
          ],
          payload: {
            'product': {
              'sku': 'APL-IP15P-512',
              'name': 'iPhone 15 Pro 512GB',
              'categoryId': 'cat-123',
              'brand': 'Apple',
              'unit': 'Adet',
            },
            'variants': [
              {
                'sku': 'APL-IP15P-512',
                'name': '512GB',
                'attributes': {
                  'Kapasite': '512GB',
                },
                'pricing': {
                  'purchasePrice': 52000.00,
                  'salePrice': 65000.00,
                  'taxRate': 18.0,
                },
                'initialStocks': [
                  {
                    'storeId': 'store-1',
                    'warehouseId': 'WH-001',
                    'quantity': 5,
                  }
                ],
                'barcodes': [
                  {
                    'code': '2223334445556',
                    'type': 'EAN13',
                    'primary': true,
                  }
                ],
              }
            ],
            'purchase': {
              'supplierId': 'supplier-apple',
              'invoiceNumber': 'FAT-2025-001',
              'purchaseDate': '2025-01-03',
            },
          },
        ),

        // TAM EŞLEŞME - Sadece stok ekle
        BackendAnalyzedProduct(
          tempId: 'TEMP-004',
          status: ProductImportStatus.EXACT,
          confidence: 1.0,
          suggestions: [
            'Mevcut stoka ekle',
            'Fiyat güncellemesi gerekebilir',
          ],
          reason: 'SKU ve barkod tam eşleşiyor, sadece stok güncellenecek',
          payload: {
            'product': {
              'sku': 'SAM-S24U-256',
              'name': 'Samsung Galaxy S24 Ultra 256GB Siyah',
              'categoryId': 'cat-123',
              'brand': 'Samsung',
              'unit': 'Adet',
            },
            'variants': [
              {
                'sku': 'SAM-S24U-256-BLK',
                'name': 'Siyah',
                'attributes': {
                  'Renk': 'Siyah',
                  'Kapasite': '256GB',
                },
                'pricing': {
                  'purchasePrice': 38000.00,
                  'salePrice': 48000.00,
                  'taxRate': 18.0,
                },
                'initialStocks': [
                  {
                    'storeId': 'store-1',
                    'warehouseId': 'WH-001',
                    'quantity': 8,
                  }
                ],
                'barcodes': [
                  {
                    'code': '7778889990001',
                    'type': 'EAN13',
                    'primary': true,
                  }
                ],
              }
            ],
            'purchase': {
              'supplierId': 'supplier-samsung',
              'invoiceNumber': 'FAT-2025-001',
              'purchaseDate': '2025-01-03',
            },
          },
        ),

        // YENİ ÜRÜN 2
        BackendAnalyzedProduct(
          tempId: 'TEMP-005',
          status: ProductImportStatus.NEW,
          confidence: 1.0,
          suggestions: [
            'Yeni ürün olarak kaydet',
          ],
          reason: 'Sistemde bu ürün bulunamadı',
          payload: {
            'product': {
              'sku': 'SONY-WH1000XM5',
              'name': 'Sony WH-1000XM5 Kablosuz Kulaklık',
              'categoryId': 'cat-789',
              'brand': 'Sony',
              'unit': 'Adet',
            },
            'variants': [
              {
                'sku': 'SONY-WH1000XM5-BLK',
                'name': 'Siyah',
                'attributes': {
                  'Renk': 'Siyah',
                },
                'pricing': {
                  'purchasePrice': 9500.00,
                  'salePrice': 12000.00,
                  'taxRate': 18.0,
                },
                'initialStocks': [
                  {
                    'storeId': 'store-1',
                    'warehouseId': 'WH-001',
                    'quantity': 15,
                  }
                ],
                'barcodes': [
                  {
                    'code': '4548736141111',
                    'type': 'EAN13',
                    'primary': true,
                  }
                ],
              }
            ],
            'purchase': {
              'supplierId': 'supplier-sony',
              'invoiceNumber': 'FAT-2025-001',
              'purchaseDate': '2025-01-03',
            },
          },
        ),
      ],
    );
  }
}
