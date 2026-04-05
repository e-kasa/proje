/// Mock data for bulk import feature
class MockImportData {
  static final List<Map<String, dynamic>> importedProducts = [
    {
      'id': 'imported_1',
      'name': 'Fren Balatası Ön Takım (Bosch)',
      'sku': 'BOS-FB-002',
      'barcode': '4047024567890',
      'category': 'Fren Sistemi > Balata',
      'brand': 'Bosch',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 320.0,
      'sellPrice': 450.0,
      'stock': 40,
      'status': 'new',
      'description': 'PDF\'den çıkarılan yeni ürün',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_2',
      'name': 'Yağ Filtresi (Mann Filter) W 712/95',
      'sku': 'MAN-YF-001',
      'barcode': '4011558022341',
      'category': 'Filtreler > Yağ Filtresi',
      'brand': 'Mann Filter',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 58.0,
      'sellPrice': 90.0,
      'stock': 100,
      'status': 'conflict',
      'description': 'SKU sistemde mevcut - Çakışma var',
      'variants': [],
      'existingProduct': {
        'id': 'existing_001',
        'name': 'Yağ Filtresi (Mann Filter) W 712/94',
        'sku': 'MAN-YF-001',
        'barcode': '4011558022341',
        'buyPrice': 55.0,
        'sellPrice': 85.0,
        'stock': 80,
      },
      'conflictType': 'sku',
      'resolution': null,
    },
    {
      'id': 'imported_3',
      'name': 'Amortisör Ön Sol (Sachs)',
      'sku': 'SAC-AM-002',
      'barcode': '4013872012345',
      'category': 'Süspansiyon > Amortisör',
      'brand': 'Sachs',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 580.0,
      'sellPrice': 850.0,
      'stock': 15,
      'status': 'new',
      'description': 'Yeni ürün',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_4',
      'name': 'Debriyaj Baskı (Valeo)',
      'sku': '',
      'barcode': '3276424567891',
      'category': 'Debriyaj > Baskı',
      'brand': 'Valeo',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 0.0,
      'sellPrice': 0.0,
      'stock': 10,
      'status': 'error',
      'description': 'Eksik bilgi - SKU ve fiyat yok',
      'errors': ['SKU alanı boş', 'Alış fiyatı belirtilmemiş', 'Satış fiyatı belirtilmemiş'],
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_5',
      'name': 'Triger Seti Komple (Gates)',
      'sku': 'GAT-TS-002',
      'barcode': '5412571234567',
      'category': 'Kayış/Gergi > Triger',
      'brand': 'Gates',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 820.0,
      'sellPrice': 1250.0,
      'stock': 12,
      'status': 'new',
      'description': 'Yeni ürün',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_6',
      'name': 'Akü 72Ah (Mutlu)',
      'sku': 'MUT-AK-002',
      'barcode': '8690535012345',
      'category': 'Elektrik/Akü > Akü',
      'brand': 'Mutlu',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 1950.0,
      'sellPrice': 2800.0,
      'stock': 8,
      'status': 'conflict',
      'description': 'Barkod çakışması',
      'variants': [],
      'existingProduct': {
        'id': 'existing_002',
        'name': 'Akü 72Ah (Mutlu) EFB',
        'sku': 'MUT-AK-072-EFB',
        'barcode': '8690535012345',
        'buyPrice': 2100.0,
        'sellPrice': 2900.0,
        'stock': 5,
      },
      'conflictType': 'barcode',
      'resolution': null,
    },
    {
      'id': 'imported_7',
      'name': 'Hava Filtresi (Mahle) LX 1566',
      'sku': 'MAH-HF-002',
      'barcode': '4009026834567',
      'category': 'Filtreler > Hava Filtresi',
      'brand': 'Mahle',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 78.0,
      'sellPrice': 130.0,
      'stock': 60,
      'status': 'new',
      'description': 'Yeni ürün',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_8',
      'name': 'Radyatör Komple (Nissens)',
      'sku': '',
      'barcode': '',
      'category': 'Soğutma > Radyatör',
      'brand': 'Nissens',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 2500.0,
      'sellPrice': 3600.0,
      'stock': 0,
      'status': 'error',
      'description': 'Kritik eksikler',
      'errors': ['SKU alanı boş', 'Barkod alanı boş', 'Stok miktarı sıfır'],
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_9',
      'name': 'Fren Diski Ön (Brembo)',
      'sku': 'BRM-FD-001',
      'barcode': '8020584012345',
      'category': 'Fren Sistemi > Disk',
      'brand': 'Brembo',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 520.0,
      'sellPrice': 750.0,
      'stock': 20,
      'status': 'needs_variants',
      'description': 'Miktar belirtilmiş ancak varyant bilgisi eksik',
      'needsVariants': true,
      'suggestedVariantType': 'size',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_10',
      'name': 'Rot Başı (TRW)',
      'sku': 'TRW-RB-001',
      'barcode': '4006633012345',
      'category': 'Süspansiyon > Rot',
      'brand': 'TRW',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 180.0,
      'sellPrice': 290.0,
      'stock': 30,
      'status': 'needs_variants',
      'description': 'Sol/sağ varyant bilgisi gerekli',
      'needsVariants': true,
      'suggestedVariantType': 'size',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_11',
      'name': 'V Kayışı (Gates)',
      'sku': 'GAT-VK-002',
      'barcode': '5412571345678',
      'category': 'Kayış/Gergi > V Kayışı',
      'brand': 'Gates',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 110.0,
      'sellPrice': 185.0,
      'stock': 50,
      'status': 'needs_variants',
      'description': 'Çoklu varyant ihtimali - ebat bilgisi',
      'needsVariants': true,
      'suggestedVariantType': 'size',
      'variants': [],
      'existingProduct': null,
    },
  ];

  static Map<String, int> getStatistics() {
    int newCount = 0;
    int conflictCount = 0;
    int errorCount = 0;
    int needsVariantsCount = 0;

    for (var product in importedProducts) {
      switch (product['status']) {
        case 'new':
          newCount++;
          break;
        case 'conflict':
          conflictCount++;
          break;
        case 'error':
          errorCount++;
          break;
        case 'needs_variants':
          needsVariantsCount++;
          break;
      }
    }

    return {
      'total': importedProducts.length,
      'new': newCount,
      'conflict': conflictCount,
      'error': errorCount,
      'needsVariants': needsVariantsCount,
    };
  }

  static List<String> getCategories() {
    return [
      'Fren Sistemi > Balata',
      'Fren Sistemi > Disk',
      'Filtreler > Yağ Filtresi',
      'Filtreler > Hava Filtresi',
      'Süspansiyon > Amortisör',
      'Süspansiyon > Rot',
      'Motor Parçaları > Buji',
      'Kayış/Gergi > Triger',
      'Kayış/Gergi > V Kayışı',
      'Elektrik/Akü > Akü',
      'Soğutma > Radyatör',
      'Debriyaj > Baskı',
      'Aydınlatma > Far',
    ];
  }

  static List<String> getBrands() {
    return ['Bosch', 'TRW', 'Valeo', 'Mann Filter', 'Brembo', 'Sachs', 'SKF', 'Gates', 'Mahle', 'Delphi', 'Nissens', 'Mutlu'];
  }

  static List<Map<String, String>> getUnits() {
    return [
      {'value': 'Adet', 'label': 'Adet'},
      {'value': 'Takım', 'label': 'Takım'},
      {'value': 'Set', 'label': 'Set'},
      {'value': 'Çift', 'label': 'Çift'},
    ];
  }

  static List<Map<String, dynamic>> getTaxRates() {
    return [
      {'value': 0.0, 'label': '%0'},
      {'value': 1.0, 'label': '%1'},
      {'value': 10.0, 'label': '%10'},
      {'value': 20.0, 'label': '%20'},
    ];
  }

  /// Sistemdeki mevcut ürünler (Manuel eşleştirme için)
  static final List<Map<String, dynamic>> existingProductsInSystem = [
    {
      'id': 'existing_001',
      'name': 'Yağ Filtresi (Mann Filter) W 712/94',
      'sku': 'MAN-YF-001',
      'barcode': '4011558022341',
      'category': 'Filtreler > Yağ Filtresi',
      'brand': 'Mann Filter',
      'buyPrice': 55.0,
      'sellPrice': 85.0,
      'stock': 80,
    },
    {
      'id': 'existing_002',
      'name': 'Akü 72Ah (Mutlu) EFB',
      'sku': 'MUT-AK-072-EFB',
      'barcode': '8690535012345',
      'category': 'Elektrik/Akü > Akü',
      'brand': 'Mutlu',
      'buyPrice': 2100.0,
      'sellPrice': 2900.0,
      'stock': 5,
    },
    {
      'id': 'existing_003',
      'name': 'Fren Balatası Ön (Bosch) BP1234',
      'sku': 'BOS-FB-001',
      'barcode': '4047024567800',
      'category': 'Fren Sistemi > Balata',
      'brand': 'Bosch',
      'buyPrice': 310.0,
      'sellPrice': 440.0,
      'stock': 25,
    },
    {
      'id': 'existing_004',
      'name': 'Amortisör Ön (Sachs) 315 530',
      'sku': 'SAC-AM-001',
      'barcode': '4013872098765',
      'category': 'Süspansiyon > Amortisör',
      'brand': 'Sachs',
      'buyPrice': 560.0,
      'sellPrice': 820.0,
      'stock': 10,
    },
    {
      'id': 'existing_005',
      'name': 'Triger Seti (Gates) K015603XS',
      'sku': 'GAT-TS-001',
      'barcode': '5412571098765',
      'category': 'Kayış/Gergi > Triger',
      'brand': 'Gates',
      'buyPrice': 800.0,
      'sellPrice': 1200.0,
      'stock': 8,
    },
    {
      'id': 'existing_006',
      'name': 'Hava Filtresi (Mahle) LX 1566',
      'sku': 'MAH-HF-001',
      'barcode': '4009026812345',
      'category': 'Filtreler > Hava Filtresi',
      'brand': 'Mahle',
      'buyPrice': 75.0,
      'sellPrice': 120.0,
      'stock': 45,
    },
    {
      'id': 'existing_007',
      'name': 'Debriyaj Seti (Valeo) 826 303',
      'sku': 'VAL-DB-001',
      'barcode': '3276424012345',
      'category': 'Debriyaj > Set',
      'brand': 'Valeo',
      'buyPrice': 1900.0,
      'sellPrice': 2800.0,
      'stock': 6,
    },
    {
      'id': 'existing_008',
      'name': 'Bujiler Takım (Bosch) FR7DC+',
      'sku': 'BOS-BJ-001',
      'barcode': '4047024098765',
      'category': 'Motor Parçaları > Buji',
      'brand': 'Bosch',
      'buyPrice': 200.0,
      'sellPrice': 320.0,
      'stock': 35,
    },
  ];
}
