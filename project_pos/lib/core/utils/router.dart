import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/modern_dashboard_screen.dart';
import '../../screens/sales/sales_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/inventory/enhanced_product_list_screen.dart';
import '../../screens/inventory/product_detail_screen.dart';
import '../../screens/inventory/add_product_wizard_screen.dart';
import '../../screens/inventory/brands_screen.dart';
import '../../screens/inventory/units_screen.dart';
import '../../screens/inventory/barcode_management_screen.dart';
import '../../screens/categories/category_list_screen.dart';
import '../../screens/categories/add_category_screen.dart';
import '../../screens/categories/company_category_screen.dart';
import '../../screens/customers/customer_list_screen.dart';
import '../../screens/customers/add_customer_screen.dart';
import '../../screens/suppliers/supplier_list_screen.dart';
import '../../screens/suppliers/add_supplier_screen.dart';
import '../../screens/pos/pos_sales_screen.dart';
import '../../screens/stock/enhanced_stock_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/scanner/barcode_scanner_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/menu/menu_screen.dart';
import '../../screens/warehouse/warehouse_list_screen.dart';
import '../../screens/warehouse/add_warehouse_screen.dart';
import '../../screens/store/store_list_screen.dart';
import '../../screens/store/add_store_screen.dart';
import '../../screens/finance/finance_dashboard_screen.dart';
import '../../screens/finance/expense_list_screen.dart';
import '../../screens/finance/add_expense_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/hrm/employee_list_screen.dart';
import '../../screens/bulk_import/bulk_import_upload_screen.dart';
import '../../screens/bulk_import/bulk_import_review_screen_v2.dart';
import '../../screens/bulk_import/simplified_bulk_import_screen.dart';
import '../../screens/bulk_import/supplier_import_review_screen.dart';
import '../../screens/bulk_import/supplier_import_review_table_screen.dart';
// import '../../screens/bulk_import/supplier_import_table_dropdown_screen.dart'; // DISABLED: Has compile errors
import '../../screens/supplier_upload/supplier_upload_wizard_screen.dart';
import '../../models/supplier_upload_models.dart' as supplier_models;
import '../../screens/stock/multi_warehouse_stock_screen.dart';
import '../../screens/stock/stock_transfer_review_screen.dart';
import '../../screens/stock/stock_count_review_screen.dart';
import '../../screens/purchases/purchase_list_screen.dart';
import '../../screens/purchases/add_purchase_screen.dart';
import '../layouts/responsive_layout.dart';  // Changed from main_layout.dart

/// Auth değişimlerini GoRouter'a iletmek için ChangeNotifier.
/// routerProvider GoRouter'ı SADECE BİR KEZ oluşturur;
/// auth state değişince notifyListeners() ile redirect yeniden hesaplanır.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // ref.read — sadece okuma, izleme değil (yeniden oluşturmayı önler)
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main App Routes
      ShellRoute(
        builder: (context, state, child) => ResponsiveLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const ModernDashboardScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesScreen(),
          ),
          GoRoute(
            path: '/pos',
            builder: (context, state) => const PosSalesScreen(),
          ),
          GoRoute(
            path: '/scanner',
            builder: (context, state) => const BarcodeScannerScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const SupplierListScreen(),
          ),
          GoRoute(
            path: '/stock',
            builder: (context, state) => const EnhancedStockScreen(),
          ),
          GoRoute(
            path: '/stock/multi-warehouse',
            builder: (context, state) => const MultiWarehouseStockScreen(),
          ),
          GoRoute(
            path: '/stock/transfer-review',
            builder: (context, state) => const StockTransferReviewScreen(),
          ),
          GoRoute(
            path: '/stock/count-review',
            builder: (context, state) => const StockCountReviewScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/menu',
            builder: (context, state) => const MenuScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
            routes: [
              GoRoute(
                path: 'products',
                builder: (context, state) => const EnhancedProductListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ProductDetailScreen(productId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'add-product',
                builder: (context, state) {
                  // Extract bulk import parameters if provided
                  final extra = state.extra as Map<String, dynamic>?;
                  final fromBulkImport = extra?['fromBulkImport'] as bool? ?? false;
                  final importData = extra?['importData'] as Map<String, dynamic>?;
                  final tempId = extra?['tempId'] as String?;

                  return AddProductWizardScreen(
                    fromBulkImport: fromBulkImport,
                    importData: importData,
                    tempId: tempId,
                  );
                },
              ),
              GoRoute(
                path: 'categories',
                builder: (context, state) => const CategoryListScreen(),
              ),
              GoRoute(
                path: 'brands',
                builder: (context, state) => const BrandsScreen(),
              ),
              GoRoute(
                path: 'units',
                builder: (context, state) => const UnitsScreen(),
              ),
              GoRoute(
                path: 'barcodes',
                builder: (context, state) => const BarcodeManagementScreen(),
              ),
            ],
          ),
          // Warehouse Routes
          GoRoute(
            path: '/warehouses',
            builder: (context, state) => const WarehouseListScreen(),
          ),
          GoRoute(
            path: '/warehouses/add',
            builder: (context, state) => const AddWarehouseScreen(),
          ),
          GoRoute(
            path: '/warehouses/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AddWarehouseScreen(warehouseId: id);
            },
          ),
          // Store Routes
          GoRoute(
            path: '/stores',
            builder: (context, state) => const StoreListScreen(),
          ),
          GoRoute(
            path: '/stores/add',
            builder: (context, state) => const AddStoreScreen(),
          ),
          GoRoute(
            path: '/stores/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AddStoreScreen(storeId: id);
            },
          ),
          // Customer Routes
          GoRoute(
            path: '/customers/add',
            builder: (context, state) => const AddCustomerScreen(),
          ),
          GoRoute(
            path: '/customers/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return AddCustomerScreen(customerId: id);
            },
          ),
          // Purchase Routes
          GoRoute(
            path: '/purchases',
            builder: (context, state) => const PurchaseListScreen(),
          ),
          GoRoute(
            path: '/purchases/create',
            builder: (context, state) => const AddPurchaseScreen(),
          ),
          // Supplier Routes
          GoRoute(
            path: '/suppliers/add',
            builder: (context, state) => const AddSupplierScreen(),
          ),
          GoRoute(
            path: '/suppliers/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return AddSupplierScreen(supplierId: id);
            },
          ),
          // Category Routes
          GoRoute(
            path: '/categories/add',
            builder: (context, state) => const AddCategoryScreen(),
          ),
          GoRoute(
            path: '/categories/edit/:id',
            builder: (context, state) {
              // Kategori verisi extra olarak Map<String, dynamic> gönderilir.
              // Sadece ID varsa boş Map ile geç; kategori ekranı kendi yükler.
              final extra = state.extra;
              final category = extra is Map<String, dynamic> ? extra : null;
              return AddCategoryScreen(category: category);
            },
          ),
          // Firma Kategori Tanımla — Hangi kategorileri kullanacağını seçer
          GoRoute(
            path: '/categories/company-setup',
            builder: (context, state) => const CompanyCategoryScreen(),
          ),
          // Finance Routes
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceDashboardScreen(),
          ),
          GoRoute(
            path: '/finance/expenses',
            builder: (context, state) => const ExpenseListScreen(),
          ),
          GoRoute(
            path: '/finance/expenses/add',
            builder: (context, state) => const AddExpenseScreen(),
          ),
          GoRoute(
            path: '/finance/expenses/edit/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return AddExpenseScreen(expenseId: id);
            },
          ),
          // HRM Routes
          GoRoute(
            path: '/hrm/employees',
            builder: (context, state) => const EmployeeListScreen(),
          ),
          // Bulk Import Routes
          GoRoute(
            path: '/bulk-import',
            builder: (context, state) => const BulkImportUploadScreen(),
          ),
          GoRoute(
            path: '/bulk-import/review',
            builder: (context, state) => const BulkImportReviewScreenV2(),
          ),
          GoRoute(
            path: '/bulk-import/simplified',
            builder: (context, state) => const SimplifiedBulkImportScreen(),
          ),
          GoRoute(
            path: '/bulk-import/supplier',
            builder: (context, state) => const SupplierImportReviewScreen(),
          ),
          GoRoute(
            path: '/bulk-import/supplier-table',
            builder: (context, state) => const SupplierImportReviewTableScreen(),
          ),
          // DISABLED: supplier-dropdown route has compile errors
          // GoRoute(
          //   path: '/bulk-import/supplier-dropdown',
          //   builder: (context, state) => const SupplierImportTableDropdownScreen(),
          // ),
          GoRoute(
            path: '/bulk-import/supplier-wizard',
            builder: (context, state) {
              // Extra data varsa kullan, yoksa mock data
              final extra = state.extra as supplier_models.SupplierUploadResponse?;
              final mockResponse = extra ?? _getMockSupplierUploadResponse();

              return SupplierUploadWizardScreen(uploadResponse: mockResponse);
            },
          ),
          // Settings Route
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

// ============================================================================
// MOCK DATA - Test için geçici
// ============================================================================

supplier_models.SupplierUploadResponse _getMockSupplierUploadResponse() {
  return supplier_models.SupplierUploadResponse(
    productCount: 5,
    products: [
      // Ürün 1: Benzer ürün var
      supplier_models.ReadProductItem(
        readProductName: 'iPhone 15 Pro Max 256GB',
        readStock: 10,
        similarProducts: [
          supplier_models.SimilarProduct(
            sku: 'PROD-IPHONE-001',
            name: 'iPhone 15 Pro Max',
            slug: 'iphone-15-pro-max',
            categoryId: 'CAT-001',
            brand: 'Apple',
            unit: 'Adet',
            description: 'iPhone 15 Pro Max Akıllı Telefon',
            variants: [
              supplier_models.ProductVariant(
                sku: 'VAR-IPHONE-256-BLUE',
                name: '256GB Mavi',
                attributes: {'kapasite': '256GB', 'renk': 'Mavi'},
                pricing: supplier_models.VariantPricing(
                  purchasePrice: 45000.0,
                  salePrice: 52000.0,
                ),
                initialStocks: [],
                barcodes: [],
              ),
              supplier_models.ProductVariant(
                sku: 'VAR-IPHONE-256-BLACK',
                name: '256GB Siyah',
                attributes: {'kapasite': '256GB', 'renk': 'Siyah'},
                pricing: supplier_models.VariantPricing(
                  purchasePrice: 45000.0,
                  salePrice: 52000.0,
                ),
                initialStocks: [],
                barcodes: [],
              ),
            ],
          ),
        ],
      ),

      // Ürün 2: Benzer ürün yok (yeni ürün olacak)
      supplier_models.ReadProductItem(
        readProductName: 'Samsung Galaxy S24 Ultra 512GB',
        readStock: 5,
        similarProducts: [],
      ),

      // Ürün 3: Benzer ürün var, yeni varyant eklenebilir
      supplier_models.ReadProductItem(
        readProductName: 'MacBook Air M3 16GB',
        readStock: 3,
        similarProducts: [
          supplier_models.SimilarProduct(
            sku: 'PROD-MBA-001',
            name: 'MacBook Air M3',
            slug: 'macbook-air-m3',
            categoryId: 'CAT-002',
            brand: 'Apple',
            unit: 'Adet',
            description: 'MacBook Air M3 Dizüstü Bilgisayar',
            variants: [
              supplier_models.ProductVariant(
                sku: 'VAR-MBA-8GB-SILVER',
                name: '8GB Gümüş',
                attributes: {'ram': '8GB', 'renk': 'Gümüş'},
                pricing: supplier_models.VariantPricing(
                  purchasePrice: 35000.0,
                  salePrice: 42000.0,
                ),
                initialStocks: [],
                barcodes: [],
              ),
            ],
          ),
        ],
      ),

      // Ürün 4: Kot Gömlek (benzer ürün var)
      supplier_models.ReadProductItem(
        readProductName: 'Kot Gömlek Erkek',
        readStock: 20,
        similarProducts: [
          supplier_models.SimilarProduct(
            sku: 'PROD-SHIRT-001',
            name: 'Kot Gömlek',
            slug: 'kot-gomlek',
            categoryId: 'CAT-003',
            brand: 'Mavi',
            unit: 'Adet',
            description: 'Erkek Kot Gömlek',
            variants: [
              supplier_models.ProductVariant(
                sku: 'VAR-SHIRT-S-BLUE',
                name: 'S Beden Mavi',
                attributes: {'beden': 'S', 'renk': 'Mavi'},
                pricing: supplier_models.VariantPricing(
                  purchasePrice: 250.0,
                  salePrice: 450.0,
                ),
                initialStocks: [],
                barcodes: [],
              ),
              supplier_models.ProductVariant(
                sku: 'VAR-SHIRT-M-BLUE',
                name: 'M Beden Mavi',
                attributes: {'beden': 'M', 'renk': 'Mavi'},
                pricing: supplier_models.VariantPricing(
                  purchasePrice: 250.0,
                  salePrice: 450.0,
                ),
                initialStocks: [],
                barcodes: [],
              ),
            ],
          ),
        ],
      ),

      // Ürün 5: Benzer ürün yok
      supplier_models.ReadProductItem(
        readProductName: 'Sony WH-1000XM5 Kulaklık',
        readStock: 8,
        similarProducts: [],
      ),
    ],
  );
}
