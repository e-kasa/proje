import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Kapsamlı Stok Yönetim Veritabanı
/// Tüm modüller için tablo yapısı
class ComprehensiveDatabase {
  static final ComprehensiveDatabase instance = ComprehensiveDatabase._init();
  static Database? _database;
  static bool _initialized = false;

  ComprehensiveDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Web için database factory'yi initialize et
    if (kIsWeb && !_initialized) {
      databaseFactory = databaseFactoryFfiWeb;
      _initialized = true;
    }

    _database = await _initDB('pos_complete.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;

    if (kIsWeb) {
      // Web için direkt dosya adını kullan (IndexedDB'de saklanır)
      path = filePath;
    } else {
      // Mobile/Desktop için normal path kullan
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration logic
      await _createDB(db, newVersion);
    }
  }

  Future _createDB(Database db, int version) async {
    // === 1. KATEGORİLER ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        color TEXT,
        parentId INTEGER,
        sortOrder INTEGER DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // === 2. MARKALAR ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS brands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        logo TEXT,
        website TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // === 3. ÜRÜNLER (Gelişmiş) ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        sku TEXT NOT NULL UNIQUE,
        barcode TEXT,
        categoryId INTEGER,
        brandId INTEGER,
        purchasePrice REAL NOT NULL DEFAULT 0,
        sellingPrice REAL NOT NULL,
        discountPrice REAL,
        profitMargin REAL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        minStock INTEGER DEFAULT 5,
        maxStock INTEGER DEFAULT 9999,
        criticalStock INTEGER DEFAULT 10,
        unit TEXT DEFAULT 'adet',
        images TEXT,
        shelfLocation TEXT,
        expiryDate TEXT,
        taxRate REAL DEFAULT 18,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id),
        FOREIGN KEY (brandId) REFERENCES brands (id)
      )
    ''');

    // === 4. ÜRÜN VARYANTLARI ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_variants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        name TEXT NOT NULL,
        sku TEXT,
        barcode TEXT,
        price REAL,
        stock INTEGER DEFAULT 0,
        attributes TEXT,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // === 5. MÜŞTERİLER ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        city TEXT,
        taxNumber TEXT,
        birthday TEXT,
        gender TEXT,
        customerType TEXT DEFAULT 'retail',
        loyaltyPoints INTEGER DEFAULT 0,
        totalPurchases REAL DEFAULT 0,
        lastPurchaseDate TEXT,
        isActive INTEGER DEFAULT 1,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // === 6. TEDARİKÇİLER ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contactPerson TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        taxNumber TEXT,
        paymentTerms TEXT,
        rating INTEGER DEFAULT 0,
        totalOrders REAL DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // === 7. SATIŞLAR ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleNumber TEXT NOT NULL UNIQUE,
        customerId INTEGER,
        subtotal REAL NOT NULL,
        taxAmount REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        paymentStatus TEXT DEFAULT 'paid',
        notes TEXT,
        cashierName TEXT,
        saleDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // === 8. SATIŞ DETAYLARI ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total REAL NOT NULL,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // === 9. STOK HAREKETLERİ ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        movementType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        previousStock INTEGER NOT NULL,
        newStock INTEGER NOT NULL,
        referenceId INTEGER,
        reason TEXT,
        notes TEXT,
        createdBy TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // === 10. SATIN ALMA SİPARİŞLERİ ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderNumber TEXT NOT NULL UNIQUE,
        supplierId INTEGER NOT NULL,
        total REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        orderDate TEXT NOT NULL,
        expectedDate TEXT,
        receivedDate TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (supplierId) REFERENCES suppliers (id)
      )
    ''');

    // === 11. GİDERLER ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        paymentMethod TEXT,
        expenseDate TEXT NOT NULL,
        receiptNumber TEXT,
        createdBy TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // === 12. ÖDEMELER ===
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        referenceType TEXT NOT NULL,
        referenceId INTEGER NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        paymentDate TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // === ÖRNEK VERİ EKLE ===
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Veritabanında zaten veri varsa ekleme yapma
    final existingCategories = await db.query('categories', limit: 1);
    if (existingCategories.isNotEmpty) return;

    // Kategoriler (Oto Yedek Parça)
    final categories = [
      {
        'name': 'Fren Sistemi',
        'icon': 'disc_full',
        'color': '#F44336',
        'sortOrder': 1,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Süspansiyon',
        'icon': 'compress',
        'color': '#2196F3',
        'sortOrder': 2,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Motor Parçaları',
        'icon': 'settings',
        'color': '#FF9800',
        'sortOrder': 3,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Filtreler',
        'icon': 'filter_alt',
        'color': '#4CAF50',
        'sortOrder': 4,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Aydınlatma',
        'icon': 'lightbulb',
        'color': '#FFEB3B',
        'sortOrder': 5,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Elektrik/Akü',
        'icon': 'battery_charging_full',
        'color': '#9C27B0',
        'sortOrder': 6,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Soğutma',
        'icon': 'ac_unit',
        'color': '#00BCD4',
        'sortOrder': 7,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Egzoz',
        'icon': 'air',
        'color': '#795548',
        'sortOrder': 8,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Debriyaj',
        'icon': 'sync',
        'color': '#607D8B',
        'sortOrder': 9,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Kayış/Gergi',
        'icon': 'loop',
        'color': '#E91E63',
        'sortOrder': 10,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (var cat in categories) {
      await db.insert('categories', cat);
    }

    // Markalar (Oto Yedek Parça)
    final brands = [
      {'name': 'Bosch', 'isActive': 1, 'createdAt': now},
      {'name': 'TRW', 'isActive': 1, 'createdAt': now},
      {'name': 'Valeo', 'isActive': 1, 'createdAt': now},
      {'name': 'Mann Filter', 'isActive': 1, 'createdAt': now},
      {'name': 'Brembo', 'isActive': 1, 'createdAt': now},
      {'name': 'Sachs', 'isActive': 1, 'createdAt': now},
      {'name': 'SKF', 'isActive': 1, 'createdAt': now},
      {'name': 'Gates', 'isActive': 1, 'createdAt': now},
      {'name': 'Mahle', 'isActive': 1, 'createdAt': now},
      {'name': 'Delphi', 'isActive': 1, 'createdAt': now},
      {'name': 'Depo', 'isActive': 1, 'createdAt': now},
      {'name': 'Mutlu', 'isActive': 1, 'createdAt': now},
      {'name': 'Nissens', 'isActive': 1, 'createdAt': now},
    ];

    for (var brand in brands) {
      await db.insert('brands', brand);
    }

    // Ürünler (Oto Yedek Parça)
    final products = [
      {
        'name': 'Fren Balatası Ön Takım',
        'sku': 'BOS-FB-001',
        'barcode': '8680000000001',
        'categoryId': 1,
        'brandId': 1,
        'purchasePrice': 280.0,
        'sellingPrice': 450.0,
        'profitMargin': 60.7,
        'stock': 25,
        'minStock': 5,
        'unit': 'takım',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Yağ Filtresi',
        'sku': 'MAN-YF-001',
        'barcode': '8680000000002',
        'categoryId': 4,
        'brandId': 4,
        'purchasePrice': 50.0,
        'sellingPrice': 85.0,
        'profitMargin': 70.0,
        'stock': 50,
        'minStock': 10,
        'unit': 'adet',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Hava Filtresi',
        'sku': 'MAH-HF-001',
        'barcode': '8680000000003',
        'categoryId': 4,
        'brandId': 9,
        'purchasePrice': 70.0,
        'sellingPrice': 120.0,
        'profitMargin': 71.4,
        'stock': 40,
        'minStock': 10,
        'unit': 'adet',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Amortisör Ön Sol',
        'sku': 'SAC-AM-001',
        'barcode': '8680000000004',
        'categoryId': 2,
        'brandId': 6,
        'purchasePrice': 520.0,
        'sellingPrice': 850.0,
        'profitMargin': 63.5,
        'stock': 12,
        'minStock': 3,
        'unit': 'adet',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Buji Takımı (4 adet)',
        'sku': 'BOS-BJ-001',
        'barcode': '8680000000005',
        'categoryId': 3,
        'brandId': 1,
        'purchasePrice': 190.0,
        'sellingPrice': 320.0,
        'profitMargin': 68.4,
        'stock': 30,
        'minStock': 8,
        'unit': 'takım',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Triger Seti',
        'sku': 'GAT-TS-001',
        'barcode': '8680000000006',
        'categoryId': 10,
        'brandId': 8,
        'purchasePrice': 750.0,
        'sellingPrice': 1200.0,
        'profitMargin': 60.0,
        'stock': 8,
        'minStock': 3,
        'unit': 'takım',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Far Sol Komple',
        'sku': 'DEP-FR-001',
        'barcode': '8680000000007',
        'categoryId': 5,
        'brandId': 11,
        'purchasePrice': 950.0,
        'sellingPrice': 1500.0,
        'profitMargin': 57.9,
        'stock': 6,
        'minStock': 2,
        'unit': 'adet',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Akü 60Ah',
        'sku': 'MUT-AK-001',
        'barcode': '8680000000008',
        'categoryId': 6,
        'brandId': 12,
        'purchasePrice': 1400.0,
        'sellingPrice': 2200.0,
        'profitMargin': 57.1,
        'stock': 10,
        'minStock': 3,
        'unit': 'adet',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Debriyaj Seti Komple',
        'sku': 'VAL-DB-001',
        'barcode': '8680000000009',
        'categoryId': 9,
        'brandId': 3,
        'purchasePrice': 1800.0,
        'sellingPrice': 2800.0,
        'profitMargin': 55.6,
        'stock': 5,
        'minStock': 2,
        'unit': 'takım',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Radyatör Su',
        'sku': 'NIS-RD-001',
        'barcode': '8680000000010',
        'categoryId': 7,
        'brandId': 13,
        'purchasePrice': 2200.0,
        'sellingPrice': 3500.0,
        'profitMargin': 59.1,
        'stock': 4,
        'minStock': 2,
        'unit': 'adet',
        'taxRate': 18.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (var product in products) {
      await db.insert('products', product);
    }

    // Müşteriler
    final customers = [
      {
        'name': 'Ahmet Yılmaz',
        'phone': '05551234567',
        'email': 'ahmet@example.com',
        'customerType': 'retail',
        'loyaltyPoints': 150,
        'totalPurchases': 15000.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Ayşe Demir',
        'phone': '05559876543',
        'email': 'ayse@example.com',
        'customerType': 'vip',
        'loyaltyPoints': 500,
        'totalPurchases': 45000.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Mehmet Kaya',
        'phone': '05556547890',
        'customerType': 'wholesale',
        'loyaltyPoints': 0,
        'totalPurchases': 120000.0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (var customer in customers) {
      await db.insert('customers', customer);
    }

    // Tedarikçiler (Oto Yedek Parça)
    final suppliers = [
      {
        'name': 'Bosch Türkiye Distribütör',
        'contactPerson': 'Can Öztürk',
        'phone': '02121234567',
        'email': 'info@bosch-distributor.com',
        'paymentTerms': '30 gün vade',
        'rating': 5,
        'isActive': 1,
        'createdAt': now,
      },
      {
        'name': 'Valeo Yedek Parça Toptan',
        'contactPerson': 'Zeynep Arslan',
        'phone': '02129876543',
        'email': 'siparis@valeo-toptan.com',
        'paymentTerms': '45 gün vade',
        'rating': 4,
        'isActive': 1,
        'createdAt': now,
      },
    ];

    for (var supplier in suppliers) {
      await db.insert('suppliers', supplier);
    }

    // === DAHA FAZLA ÜRÜN EKLE (Oto Yedek Parça) ===
    final moreProducts = [
      // Fren Sistemi kategorisi
      {'name': 'Fren Balatası Arka Takım', 'sku': 'BOS-FB-002', 'barcode': '8680000000011', 'categoryId': 1, 'brandId': 1, 'purchasePrice': 240.0, 'sellingPrice': 380.0, 'stock': 20, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Fren Diski Ön (2 adet)', 'sku': 'BRM-FD-001', 'barcode': '8680000000012', 'categoryId': 1, 'brandId': 5, 'purchasePrice': 600.0, 'sellingPrice': 950.0, 'stock': 15, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Fren Kaliperi Sol', 'sku': 'TRW-FK-001', 'barcode': '8680000000013', 'categoryId': 1, 'brandId': 2, 'purchasePrice': 1100.0, 'sellingPrice': 1750.0, 'stock': 6, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Fren Hidroliği DOT4 1L', 'sku': 'BOS-FH-001', 'barcode': '8680000000014', 'categoryId': 1, 'brandId': 1, 'purchasePrice': 60.0, 'sellingPrice': 95.0, 'stock': 35, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'ABS Sensörü Ön', 'sku': 'DEL-ABS-001', 'barcode': '8680000000015', 'categoryId': 1, 'brandId': 10, 'purchasePrice': 180.0, 'sellingPrice': 300.0, 'stock': 18, 'isActive': 1, 'createdAt': now, 'updatedAt': now},

      // Süspansiyon kategorisi
      {'name': 'Amortisör Ön Sağ', 'sku': 'SAC-AM-002', 'barcode': '8680000000016', 'categoryId': 2, 'brandId': 6, 'purchasePrice': 520.0, 'sellingPrice': 850.0, 'stock': 12, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Amortisör Arka (2 adet)', 'sku': 'SAC-AM-003', 'barcode': '8680000000017', 'categoryId': 2, 'brandId': 6, 'purchasePrice': 400.0, 'sellingPrice': 650.0, 'stock': 14, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Rot Başı Sol', 'sku': 'TRW-RB-001', 'barcode': '8680000000018', 'categoryId': 2, 'brandId': 2, 'purchasePrice': 120.0, 'sellingPrice': 200.0, 'stock': 22, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Salıncak Alt Sol', 'sku': 'TRW-SA-001', 'barcode': '8680000000019', 'categoryId': 2, 'brandId': 2, 'purchasePrice': 350.0, 'sellingPrice': 580.0, 'stock': 10, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Viraj Demir Lastiği', 'sku': 'SKF-VD-001', 'barcode': '8680000000020', 'categoryId': 2, 'brandId': 7, 'purchasePrice': 45.0, 'sellingPrice': 75.0, 'stock': 40, 'isActive': 1, 'createdAt': now, 'updatedAt': now},

      // Motor Parçaları kategorisi
      {'name': 'Supap Kapağı Contası', 'sku': 'MAH-SC-001', 'barcode': '8680000000021', 'categoryId': 3, 'brandId': 9, 'purchasePrice': 80.0, 'sellingPrice': 140.0, 'stock': 20, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Ateşleme Bobini', 'sku': 'BOS-AB-001', 'barcode': '8680000000022', 'categoryId': 3, 'brandId': 1, 'purchasePrice': 250.0, 'sellingPrice': 420.0, 'stock': 16, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Enjektör', 'sku': 'BOS-EN-001', 'barcode': '8680000000023', 'categoryId': 3, 'brandId': 1, 'purchasePrice': 900.0, 'sellingPrice': 1450.0, 'stock': 8, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Krank Keçesi', 'sku': 'SKF-KK-001', 'barcode': '8680000000024', 'categoryId': 3, 'brandId': 7, 'purchasePrice': 55.0, 'sellingPrice': 90.0, 'stock': 25, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Termostat', 'sku': 'MAH-TR-001', 'barcode': '8680000000025', 'categoryId': 3, 'brandId': 9, 'purchasePrice': 75.0, 'sellingPrice': 130.0, 'stock': 18, 'isActive': 1, 'createdAt': now, 'updatedAt': now},

      // Filtreler kategorisi
      {'name': 'Polen Filtresi', 'sku': 'MAN-PF-001', 'barcode': '8680000000026', 'categoryId': 4, 'brandId': 4, 'purchasePrice': 40.0, 'sellingPrice': 70.0, 'stock': 45, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Yakıt Filtresi', 'sku': 'BOS-YF-001', 'barcode': '8680000000027', 'categoryId': 4, 'brandId': 1, 'purchasePrice': 90.0, 'sellingPrice': 150.0, 'stock': 30, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Şanzıman Filtresi', 'sku': 'MAN-SF-001', 'barcode': '8680000000028', 'categoryId': 4, 'brandId': 4, 'purchasePrice': 110.0, 'sellingPrice': 185.0, 'stock': 15, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Hidrolik Direksiyon Filtresi', 'sku': 'MAN-HF-001', 'barcode': '8680000000029', 'categoryId': 4, 'brandId': 4, 'purchasePrice': 65.0, 'sellingPrice': 110.0, 'stock': 20, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Partikül Filtresi (DPF)', 'sku': 'MAH-PF-001', 'barcode': '8680000000030', 'categoryId': 4, 'brandId': 9, 'purchasePrice': 4500.0, 'sellingPrice': 7200.0, 'stock': 3, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
    ];

    for (var product in moreProducts) {
      await db.insert('products', product);
    }

    // === DAHA FAZLA MÜŞTERİ EKLE (Toplam 15 müşteri) ===
    final moreCustomers = [
      {'name': 'Fatma Şahin', 'phone': '05551112233', 'email': 'fatma@example.com', 'customerType': 'retail', 'loyaltyPoints': 80, 'totalPurchases': 5200.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Ali Yıldız', 'phone': '05552223344', 'email': 'ali@example.com', 'customerType': 'vip', 'loyaltyPoints': 350, 'totalPurchases': 28000.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Zeynep Kara', 'phone': '05553334455', 'customerType': 'retail', 'loyaltyPoints': 120, 'totalPurchases': 8500.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Mustafa Aksoy', 'phone': '05554445566', 'email': 'mustafa@example.com', 'customerType': 'wholesale', 'loyaltyPoints': 0, 'totalPurchases': 95000.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Elif Öztürk', 'phone': '05555556677', 'email': 'elif@example.com', 'customerType': 'vip', 'loyaltyPoints': 580, 'totalPurchases': 52000.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Can Demirtaş', 'phone': '05556667788', 'customerType': 'retail', 'loyaltyPoints': 45, 'totalPurchases': 3200.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Selin Aydın', 'phone': '05557778899', 'email': 'selin@example.com', 'customerType': 'retail', 'loyaltyPoints': 200, 'totalPurchases': 12000.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Burak Çelik', 'phone': '05558889900', 'email': 'burak@example.com', 'customerType': 'wholesale', 'loyaltyPoints': 0, 'totalPurchases': 75000.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Deniz Yılmaz', 'phone': '05559990011', 'customerType': 'retail', 'loyaltyPoints': 95, 'totalPurchases': 6800.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Ece Koç', 'phone': '05550011223', 'email': 'ece@example.com', 'customerType': 'vip', 'loyaltyPoints': 420, 'totalPurchases': 38000.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Mert Arslan', 'phone': '05551122334', 'customerType': 'retail', 'loyaltyPoints': 65, 'totalPurchases': 4500.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
      {'name': 'Aylin Türk', 'phone': '05552233445', 'email': 'aylin@example.com', 'customerType': 'retail', 'loyaltyPoints': 150, 'totalPurchases': 9200.0, 'isActive': 1, 'createdAt': now, 'updatedAt': now},
    ];

    for (var customer in moreCustomers) {
      await db.insert('customers', customer);
    }

    // === SATIŞ KAYITLARI EKLE (Son 30 gün) ===
    final sales = [];
    final saleItems = [];

    for (int i = 1; i <= 25; i++) {
      final daysAgo = (i * 1.2).floor();
      final saleDate = DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String();

      final customerId = (i % 15) + 1; // Müşteri ID 1-15 arası
      final paymentMethods = ['cash', 'credit_card', 'debit_card', 'bank_transfer'];
      final paymentMethod = paymentMethods[i % 4];

      // Her satış için 1-5 arası ürün
      final itemCount = (i % 5) + 1;
      double subtotal = 0;

      for (int j = 0; j < itemCount; j++) {
        final productId = ((i + j) % 30) + 1;
        final quantity = (j % 3) + 1;
        final unitPrice = 299.0 + (productId * 100);
        final itemTotal = unitPrice * quantity;
        subtotal += itemTotal;

        saleItems.add({
          'saleId': i,
          'productId': productId,
          'productName': 'Ürün $productId',
          'quantity': quantity,
          'unitPrice': unitPrice,
          'discount': 0.0,
          'tax': itemTotal * 0.18,
          'total': itemTotal,
        });
      }

      final discount = subtotal > 1000 ? subtotal * 0.05 : 0.0;
      final taxAmount = (subtotal - discount) * 0.18;
      final total = subtotal - discount + taxAmount;

      sales.add({
        'saleNumber': 'SAT-2024-${i.toString().padLeft(5, '0')}',
        'customerId': customerId,
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'discount': discount,
        'total': total,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'paid',
        'cashierName': 'Kasiyer ${(i % 3) + 1}',
        'saleDate': saleDate,
        'createdAt': saleDate,
      });
    }

    for (var sale in sales) {
      await db.insert('sales', sale);
    }

    for (var item in saleItems) {
      await db.insert('sale_items', item);
    }

    // === STOK HAREKETLERİ EKLE ===
    final stockMovements = [];
    for (int i = 1; i <= 30; i++) {
      final daysAgo = (i * 0.8).floor();
      final movementDate = DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String();
      final productId = (i % 30) + 1;
      final types = ['in', 'out', 'adjustment', 'return'];
      final type = types[i % 4];
      final quantity = type == 'in' ? (i % 20) + 5 : -((i % 10) + 1);

      stockMovements.add({
        'productId': productId,
        'movementType': type,
        'quantity': quantity.abs(),
        'previousStock': 50,
        'newStock': 50 + quantity,
        'reason': type == 'in' ? 'Tedarikçiden giriş' : type == 'out' ? 'Satış' : type == 'adjustment' ? 'Sayım düzeltmesi' : 'İade',
        'createdBy': 'Sistem',
        'createdAt': movementDate,
      });
    }

    for (var movement in stockMovements) {
      await db.insert('stock_movements', movement);
    }

    // === GİDERLER EKLE ===
    final expenses = [
      {'category': 'Kira', 'amount': 15000.0, 'description': 'Mağaza kirası - Ocak', 'paymentMethod': 'bank_transfer', 'expenseDate': DateTime.now().subtract(Duration(days: 25)).toIso8601String(), 'createdBy': 'Admin', 'createdAt': now},
      {'category': 'Elektrik', 'amount': 3500.0, 'description': 'Elektrik faturası', 'paymentMethod': 'bank_transfer', 'expenseDate': DateTime.now().subtract(Duration(days: 20)).toIso8601String(), 'createdBy': 'Admin', 'createdAt': now},
      {'category': 'Su', 'amount': 450.0, 'description': 'Su faturası', 'paymentMethod': 'bank_transfer', 'expenseDate': DateTime.now().subtract(Duration(days: 20)).toIso8601String(), 'createdBy': 'Admin', 'createdAt': now},
      {'category': 'Maaş', 'amount': 45000.0, 'description': 'Personel maaşları', 'paymentMethod': 'bank_transfer', 'expenseDate': DateTime.now().subtract(Duration(days: 15)).toIso8601String(), 'createdBy': 'Admin', 'createdAt': now},
      {'category': 'İnternet', 'amount': 800.0, 'description': 'İnternet aboneliği', 'paymentMethod': 'bank_transfer', 'expenseDate': DateTime.now().subtract(Duration(days: 18)).toIso8601String(), 'createdBy': 'Admin', 'createdAt': now},
      {'category': 'Temizlik', 'amount': 2000.0, 'description': 'Temizlik malzemeleri', 'paymentMethod': 'cash', 'expenseDate': DateTime.now().subtract(Duration(days: 10)).toIso8601String(), 'createdBy': 'Admin', 'createdAt': now},
      {'category': 'Kırtasiye', 'amount': 650.0, 'description': 'Ofis malzemeleri', 'paymentMethod': 'credit_card', 'expenseDate': DateTime.now().subtract(Duration(days: 8)).toIso8601String(), 'createdBy': 'Admin', 'createdAt': now},
      {'category': 'Bakım', 'amount': 3200.0, 'description': 'Klima bakımı', 'paymentMethod': 'cash', 'expenseDate': DateTime.now().subtract(Duration(days: 5)).toIso8601String(), 'createdBy': 'Admin', 'createdAt': now},
    ];

    for (var expense in expenses) {
      await db.insert('expenses', expense);
    }
  }

  // CRUD İşlemleri burada devam edecek

  /// Veritabanını sıfırlar ve örnek verileri yeniden yükler
  Future<void> resetDatabase() async {
    final db = await database;

    // Tüm tabloları temizle
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('stock_movements');
    await db.delete('expenses');
    await db.delete('payments');
    await db.delete('purchase_orders');
    await db.delete('products');
    await db.delete('customers');
    await db.delete('suppliers');
    await db.delete('brands');
    await db.delete('categories');

    // Örnek verileri yeniden yükle
    await _insertSampleData(db);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
