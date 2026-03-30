/// Mock data for bulk import feature
class MockImportData {
  static final List<Map<String, dynamic>> importedProducts = [
    {
      'id': 'imported_1',
      'name': 'Samsung Galaxy S24 Ultra 256GB',
      'sku': 'SAM-S24U-256-BLK',
      'barcode': '8806095048567',
      'category': 'Elektronik > Cep Telefonu',
      'brand': 'Samsung',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 45000.0,
      'sellPrice': 52000.0,
      'stock': 15,
      'status': 'new', // new, conflict, error
      'description': 'PDF\'den çıkarılan yeni ürün',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_2',
      'name': 'Apple iPhone 15 Pro 128GB',
      'sku': 'APL-IP15P-128-SLV',
      'barcode': '0194253433071',
      'category': 'Elektronik > Cep Telefonu',
      'brand': 'Apple',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 48000.0,
      'sellPrice': 55000.0,
      'stock': 8,
      'status': 'conflict',
      'description': 'SKU sistemde mevcut - Çakışma var',
      'variants': [],
      'existingProduct': {
        'id': 'existing_001',
        'name': 'Apple iPhone 15 Pro 128GB Space Gray',
        'sku': 'APL-IP15P-128-SLV',
        'barcode': '0194253433071',
        'buyPrice': 47500.0,
        'sellPrice': 54500.0,
        'stock': 12,
      },
      'conflictType': 'sku', // sku, barcode, name
      'resolution': null, // update, skip, create_variant
    },
    {
      'id': 'imported_3',
      'name': 'Xiaomi Redmi Note 13 Pro',
      'sku': 'XIA-RN13P-256-BLU',
      'barcode': '6941812747889',
      'category': 'Elektronik > Cep Telefonu',
      'brand': 'Xiaomi',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 12000.0,
      'sellPrice': 14500.0,
      'stock': 25,
      'status': 'new',
      'description': 'Yeni ürün',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_4',
      'name': 'Sony WH-1000XM5 Kulaklık',
      'sku': '', // Empty SKU
      'barcode': '4548736141377',
      'category': 'Elektronik > Ses Sistemleri',
      'brand': 'Sony',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 0.0, // Missing price
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
      'name': 'LG OLED TV 55 inch 4K',
      'sku': 'LG-OLED55-4K',
      'barcode': '8806091234567',
      'category': 'Elektronik > Televizyon',
      'brand': 'LG',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 35000.0,
      'sellPrice': 42000.0,
      'stock': 5,
      'status': 'new',
      'description': 'Yeni ürün',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_6',
      'name': 'MacBook Pro 14" M3 Pro',
      'sku': 'APL-MBP14-M3P-512',
      'barcode': '0195949112233',
      'category': 'Bilgisayar > Dizüstü',
      'brand': 'Apple',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 85000.0,
      'sellPrice': 95000.0,
      'stock': 3,
      'status': 'conflict',
      'description': 'Barkod çakışması',
      'variants': [],
      'existingProduct': {
        'id': 'existing_002',
        'name': 'MacBook Pro 14 M3 Pro 512GB',
        'sku': 'APL-MBP14-512-SLV',
        'barcode': '0195949112233',
        'buyPrice': 84000.0,
        'sellPrice': 94000.0,
        'stock': 7,
      },
      'conflictType': 'barcode',
      'resolution': null,
    },
    {
      'id': 'imported_7',
      'name': 'Logitech MX Master 3S Mouse',
      'sku': 'LOG-MXM3S-BLK',
      'barcode': '097855159885',
      'category': 'Bilgisayar > Aksesuar',
      'brand': 'Logitech',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 2500.0,
      'sellPrice': 3200.0,
      'stock': 40,
      'status': 'new',
      'description': 'Yeni ürün',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_8',
      'name': 'Dell XPS 15 Laptop',
      'sku': '', // Missing SKU
      'barcode': '', // Missing Barcode
      'category': 'Bilgisayar > Dizüstü',
      'brand': 'Dell',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 55000.0,
      'sellPrice': 62000.0,
      'stock': 0, // Zero stock
      'status': 'error',
      'description': 'Kritik eksikler',
      'errors': ['SKU alanı boş', 'Barkod alanı boş', 'Stok miktarı sıfır'],
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_9',
      'name': 'Klasik Pamuk Gömlek',
      'sku': 'GMLEK-KLS-001',
      'barcode': '8697854123456',
      'category': 'Giyim > Erkek',
      'brand': 'LC Waikiki',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 250.0,
      'sellPrice': 399.0,
      'stock': 20, // 20 adet ama beden bilgisi yok
      'status': 'needs_variants',
      'description': 'Miktar belirtilmiş ancak varyant bilgisi eksik',
      'needsVariants': true,
      'suggestedVariantType': 'size',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_10',
      'name': 'Spor Ayakkabı Running Max',
      'sku': 'AYAK-SPR-002',
      'barcode': '8697854234567',
      'category': 'Ayakkabı > Spor',
      'brand': 'Nike',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 1200.0,
      'sellPrice': 1799.0,
      'stock': 15, // 15 adet ama numara bilgisi yok
      'status': 'needs_variants',
      'description': 'Ayakkabı için numara bilgisi gerekli',
      'needsVariants': true,
      'suggestedVariantType': 'size',
      'variants': [],
      'existingProduct': null,
    },
    {
      'id': 'imported_11',
      'name': 'Basic Tişört Pamuklu',
      'sku': 'TISORT-BSC-003',
      'barcode': '8697854345678',
      'category': 'Giyim > Unisex',
      'brand': 'Koton',
      'unit': 'Adet',
      'taxRate': 20.0,
      'buyPrice': 80.0,
      'sellPrice': 149.0,
      'stock': 30, // 30 adet - hem beden hem renk varyantı olabilir
      'status': 'needs_variants',
      'description': 'Çoklu varyant ihtimali - beden ve renk',
      'needsVariants': true,
      'suggestedVariantType': 'size', // İlk öneri beden, kullanıcı renk de ekleyebilir
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
      'Elektronik > Cep Telefonu',
      'Elektronik > Ses Sistemleri',
      'Elektronik > Televizyon',
      'Bilgisayar > Dizüstü',
      'Bilgisayar > Aksesuar',
    ];
  }

  static List<String> getBrands() {
    return ['Samsung', 'Apple', 'Xiaomi', 'Sony', 'LG', 'Logitech', 'Dell'];
  }

  static List<Map<String, String>> getUnits() {
    return [
      {'value': 'Adet', 'label': 'Adet'},
      {'value': 'Kilogram', 'label': 'Kilogram'},
      {'value': 'Litre', 'label': 'Litre'},
      {'value': 'Metre', 'label': 'Metre'},
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
      'name': 'Apple iPhone 15 Pro 128GB Space Gray',
      'sku': 'APL-IP15P-128-SLV',
      'barcode': '0194253433071',
      'category': 'Elektronik > Cep Telefonu',
      'brand': 'Apple',
      'buyPrice': 47500.0,
      'sellPrice': 54500.0,
      'stock': 12,
    },
    {
      'id': 'existing_002',
      'name': 'MacBook Pro 14 M3 Pro 512GB',
      'sku': 'APL-MBP14-512-SLV',
      'barcode': '0195949112233',
      'category': 'Bilgisayar > Dizüstü',
      'brand': 'Apple',
      'buyPrice': 84000.0,
      'sellPrice': 94000.0,
      'stock': 7,
    },
    {
      'id': 'existing_003',
      'name': 'Samsung Galaxy S23 Ultra 512GB',
      'sku': 'SAM-S23U-512-BLK',
      'barcode': '8806094563789',
      'category': 'Elektronik > Cep Telefonu',
      'brand': 'Samsung',
      'buyPrice': 42000.0,
      'sellPrice': 49000.0,
      'stock': 8,
    },
    {
      'id': 'existing_004',
      'name': 'Sony WH-1000XM4 Kulaklık',
      'sku': 'SNY-WH1000-XM4',
      'barcode': '4548736113183',
      'category': 'Elektronik > Ses Sistemleri',
      'brand': 'Sony',
      'buyPrice': 8500.0,
      'sellPrice': 10500.0,
      'stock': 15,
    },
    {
      'id': 'existing_005',
      'name': 'LG OLED TV 65 inch 4K',
      'sku': 'LG-OLED65-4K',
      'barcode': '8806091987654',
      'category': 'Elektronik > Televizyon',
      'brand': 'LG',
      'buyPrice': 45000.0,
      'sellPrice': 52000.0,
      'stock': 3,
    },
    {
      'id': 'existing_006',
      'name': 'Logitech MX Keys Klavye',
      'sku': 'LOG-MXKEY-BLK',
      'barcode': '097855138071',
      'category': 'Bilgisayar > Aksesuar',
      'brand': 'Logitech',
      'buyPrice': 3500.0,
      'sellPrice': 4200.0,
      'stock': 22,
    },
    {
      'id': 'existing_007',
      'name': 'Dell XPS 13 Laptop',
      'sku': 'DELL-XPS13-I7',
      'barcode': '0884116345678',
      'category': 'Bilgisayar > Dizüstü',
      'brand': 'Dell',
      'buyPrice': 48000.0,
      'sellPrice': 55000.0,
      'stock': 5,
    },
    {
      'id': 'existing_008',
      'name': 'Xiaomi Redmi Note 12 Pro',
      'sku': 'XIA-RN12P-256-WHT',
      'barcode': '6941812734156',
      'category': 'Elektronik > Cep Telefonu',
      'brand': 'Xiaomi',
      'buyPrice': 10000.0,
      'sellPrice': 12500.0,
      'stock': 30,
    },
  ];
}
