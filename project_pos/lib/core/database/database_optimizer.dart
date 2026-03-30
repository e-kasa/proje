import 'package:sqflite/sqflite.dart';

/// Database Performance Optimizer
class DatabaseOptimizer {
  /// Create indexes for faster queries
  static Future<void> createIndexes(Database db) async {
    // Products indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON products(categoryId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_active ON products(isActive)');

    // Categories indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(isActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_sort ON categories(sortOrder)');

    // Customers indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_type ON customers(customerType)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_active ON customers(isActive)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_purchases ON customers(totalPurchases)');

    // Sales indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(saleDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customerId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(paymentStatus)');

    // Stock movements indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_product ON stock_movements(productId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_date ON stock_movements(createdAt)');
  }

  /// Vacuum database for optimization
  static Future<void> vacuum(Database db) async {
    await db.execute('VACUUM');
  }

  /// Analyze database for query optimization
  static Future<void> analyze(Database db) async {
    await db.execute('ANALYZE');
  }

  /// Clear old data (soft delete)
  static Future<void> clearOldData(Database db, {int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();

    // Archive old sales
    await db.delete(
      'sales',
      where: 'saleDate < ? AND paymentStatus = ?',
      whereArgs: [cutoffDate, 'completed'],
    );

    // Clean up old stock movements
    await db.delete(
      'stock_movements',
      where: 'createdAt < ?',
      whereArgs: [cutoffDate],
    );
  }

  /// Get database size info
  static Future<Map<String, dynamic>> getDatabaseInfo(Database db) async {
    final pageCount = await db.rawQuery('PRAGMA page_count');
    final pageSize = await db.rawQuery('PRAGMA page_size');
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

    return {
      'pageCount': pageCount,
      'pageSize': pageSize,
      'tables': tables,
      'estimatedSize': (pageCount.first.values.first as int) *
                       (pageSize.first.values.first as int),
    };
  }
}
