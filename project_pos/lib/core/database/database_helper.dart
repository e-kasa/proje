import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
    CREATE TABLE products (
      id $idType,
      name $textType,
      sku $textType,
      barcode TEXT,
      category $textType,
      price $realType,
      stock $intType,
      unit $textType,
      lowStockThreshold INTEGER DEFAULT 10,
      createdAt TEXT,
      updatedAt TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE sales (
      id $idType,
      productId $intType,
      quantity $intType,
      total $realType,
      date $textType,
      FOREIGN KEY (productId) REFERENCES products (id)
    )
    ''');

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();

    final products = [
      {
        'name': 'Nike Air Max 90',
        'sku': 'NK-001',
        'barcode': '1234567890123',
        'category': 'Ayakkabı',
        'price': 1299.0,
        'stock': 45,
        'unit': 'pcs',
        'lowStockThreshold': 10,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Adidas Ultraboost',
        'sku': 'AD-002',
        'barcode': '1234567890124',
        'category': 'Ayakkabı',
        'price': 1499.0,
        'stock': 38,
        'unit': 'pcs',
        'lowStockThreshold': 10,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'iPhone 15 Pro',
        'sku': 'IP-015',
        'barcode': '1234567890125',
        'category': 'Elektronik',
        'price': 49999.0,
        'stock': 5,
        'unit': 'pcs',
        'lowStockThreshold': 5,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'Samsung Galaxy S24',
        'sku': 'SM-024',
        'barcode': '1234567890126',
        'category': 'Elektronik',
        'price': 39999.0,
        'stock': 8,
        'unit': 'pcs',
        'lowStockThreshold': 5,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'name': 'MacBook Pro 16"',
        'sku': 'MB-016',
        'barcode': '1234567890127',
        'category': 'Elektronik',
        'price': 89999.0,
        'stock': 3,
        'unit': 'pcs',
        'lowStockThreshold': 3,
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (var product in products) {
      await db.insert('products', product);
    }
  }

  // CRUD Operations
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    product['createdAt'] = DateTime.now().toIso8601String();
    product['updatedAt'] = DateTime.now().toIso8601String();
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
  }

  Future<List<Map<String, dynamic>>> getProductsByCategory(
      String category) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await database;
    return await db.rawQuery(
      'SELECT * FROM products WHERE stock <= lowStockThreshold',
    );
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    product['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> bulkDeleteProducts(List<int> ids) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id IN (${ids.join(",")})',
    );
  }

  Future<void> updateStock(int id, int newStock) async {
    final db = await database;
    await db.update(
      'products',
      {
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final totalProducts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    ) ?? 0;

    final lowStockCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM products WHERE stock <= lowStockThreshold',
      ),
    ) ?? 0;

    final totalValue = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(price * stock) FROM products'),
    ) ?? 0;

    return {
      'totalProducts': totalProducts,
      'lowStockCount': lowStockCount,
      'totalValue': totalValue,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
