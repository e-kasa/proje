import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/shared/providers/auth_provider.dart';
import 'package:project_pos/shared/providers/menu_provider.dart';
// Auth
import 'package:project_pos/features/auth/screens/login_screen.dart';
import 'package:project_pos/features/auth/screens/company_registration_screen.dart';
// Dashboard
import 'package:project_pos/features/dashboard/screens/modern_dashboard_screen.dart';
// Menu
import 'package:project_pos/features/menu/screens/menu_screen.dart';
// POS
import 'package:project_pos/features/pos/screens/pos_screen.dart';
// Inventory
import 'package:project_pos/features/inventory/screens/inventory_screen.dart';
import 'package:project_pos/features/inventory/screens/enhanced_product_list_screen.dart';
import 'package:project_pos/features/inventory/screens/product_detail_screen.dart';
import 'package:project_pos/features/inventory/screens/brands_screen.dart';
import 'package:project_pos/features/inventory/screens/units_screen.dart';
import 'package:project_pos/features/inventory/screens/barcode_management_screen.dart';
import 'package:project_pos/features/inventory/screens/add_product/add_product_wizard_screen.dart';
import 'package:project_pos/features/inventory/screens/batch_entry/batch_product_screen.dart';
// Catalog (categories)
import 'package:project_pos/features/catalog/screens/category_list_screen.dart';
import 'package:project_pos/features/catalog/screens/add_category_screen.dart';
import 'package:project_pos/features/catalog/screens/company_category_screen.dart';
// Sales
import 'package:project_pos/features/sales/screens/sale_list_screen.dart';
import 'package:project_pos/features/sales/screens/sale_detail_screen.dart';
import 'package:project_pos/features/sales/screens/sale_return_screen.dart';
// Purchases
import 'package:project_pos/features/purchases/screens/purchase_list_screen.dart';
import 'package:project_pos/features/purchases/screens/add_purchase_screen.dart';
import 'package:project_pos/features/purchases/screens/purchase_detail_screen.dart';
import 'package:project_pos/features/purchases/screens/purchase_return_screen.dart';
// Suppliers (bulk upload wizard hala kullanılıyor)
import 'package:project_pos/features/suppliers/screens/upload/supplier_upload_wizard_screen.dart';
// Supplier Claims
import 'package:project_pos/features/supplier_claims/screens/supplier_claims_list_screen.dart';
import 'package:project_pos/features/supplier_claims/screens/supplier_claim_detail_screen.dart';
// Accounts
import 'package:project_pos/features/accounts/screens/accounts_hub_screen.dart';
// Stock
import 'package:project_pos/features/stock/screens/enhanced_stock_screen.dart';
import 'package:project_pos/features/stock/screens/multi_warehouse_stock_screen.dart';
import 'package:project_pos/features/stock/screens/stock_transfer_review_screen.dart';
import 'package:project_pos/features/stock/screens/stock_count_review_screen.dart';
import 'package:project_pos/features/stock/screens/stock_transfer_screen.dart';
import 'package:project_pos/features/stock/screens/stock_movement_history_screen.dart';
import 'package:project_pos/features/stock/screens/stock_alert_screen.dart';
import 'package:project_pos/features/stock/screens/stock_value_report_screen.dart';
// Finance
import 'package:project_pos/features/finance/screens/finance_dashboard_screen.dart';
import 'package:project_pos/features/finance/screens/expense_list_screen.dart';
import 'package:project_pos/features/finance/screens/add_expense_screen.dart';
import 'package:project_pos/features/finance/screens/add_income_screen.dart';
import 'package:project_pos/features/finance/screens/cash_flow_screen.dart';
// Reports
import 'package:project_pos/features/reports/screens/reports_screen.dart';
import 'package:project_pos/features/reports/screens/sales_summary_screen.dart';
import 'package:project_pos/features/reports/screens/product_sales_analysis_screen.dart';
import 'package:project_pos/features/reports/screens/customer_sales_analysis_screen.dart';
import 'package:project_pos/features/reports/screens/profit_overview_screen.dart';
import 'package:project_pos/features/reports/screens/daily_summary_screen.dart';
// Import (bulk import + scanner)
import 'package:project_pos/features/import/screens/bulk_import_upload_screen.dart';
import 'package:project_pos/features/import/screens/bulk_import_review_screen_v2.dart';
import 'package:project_pos/features/import/screens/supplier_import_review_screen.dart';
import 'package:project_pos/features/import/screens/supplier_import_upload_screen.dart';
import 'package:project_pos/features/import/screens/barcode_scanner_screen.dart';
// Autoparts
import 'package:project_pos/features/autoparts/screens/vehicle_list_screen.dart';
import 'package:project_pos/features/autoparts/screens/vehicle_compatibility_screen.dart';
import 'package:project_pos/features/autoparts/screens/part_search_screen.dart';
// Warehouse
import 'package:project_pos/features/warehouse/screens/warehouse_list_screen.dart';
import 'package:project_pos/features/warehouse/screens/add_warehouse_screen.dart';
// Store
import 'package:project_pos/features/store/screens/store_list_screen.dart';
import 'package:project_pos/features/store/screens/add_store_screen.dart';
// HRM
import 'package:project_pos/features/hrm/screens/employee_list_screen.dart';
import 'package:project_pos/features/hrm/screens/add_employee_screen.dart';
// Settings
import 'package:project_pos/features/settings/screens/settings_screen.dart';
import 'package:project_pos/features/settings/screens/user_management_screen.dart';
import 'package:project_pos/features/settings/screens/company_settings_screen.dart';
import 'package:project_pos/features/settings/screens/sector_settings_screen.dart';
import 'package:project_pos/features/settings/screens/profile_screen.dart';
import 'package:project_pos/features/settings/screens/printer_settings_screen.dart';
import 'package:project_pos/features/settings/screens/label_printer_settings_screen.dart';
// Sprint 23 — Integrations Hub
import 'package:project_pos/features/settings/integrations/screens/integrations_hub_screen.dart';
import 'package:project_pos/features/settings/integrations/screens/email_settings_screen.dart';
import 'package:project_pos/features/settings/integrations/screens/sms_settings_screen.dart';
// Supplier upload models
import 'package:project_pos/features/suppliers/models/supplier_upload_models.dart' as supplier_models;
// Layout
import '../layouts/responsive_layout.dart';

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
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final loc = state.matchedLocation;
      final isPublicRoute = loc == '/login' || loc == '/register';

      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && isPublicRoute) return '/dashboard';

      // Rol bazlı route guard — menü yüklendiyse kontrol et
      if (isAuthenticated) {
        final menuState = ref.read(menuProvider);
        // Detail/sub sayfaları: menüde kayıtlı parent route'a tıklanarak açılan
        // ekranlar. Bunlar menü item'ı olmadan erişilmez ama guard'ı bypass eder.
        const alwaysAllowed = [
          '/dashboard', '/menu', '/profile',
          '/supplier-claims',
          '/purchases/detail',
          '/sales/detail',
        ];
        final isAlways = alwaysAllowed.any(
            (a) => loc == a || loc.startsWith('$a/'));
        if (menuState.categories.isNotEmpty &&
            !isAlways &&
            !ref.read(menuProvider.notifier).isRouteAllowed(loc)) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const CompanyRegistrationScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => ResponsiveLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const ModernDashboardScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SaleListScreen(),
          ),
          GoRoute(
            path: '/sales/detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SaleDetailScreen(saleId: id);
            },
          ),
          GoRoute(
            path: '/sales/return/:saleId',
            builder: (context, state) {
              final saleId = state.pathParameters['saleId']!;
              return SaleReturnScreen(saleId: saleId);
            },
          ),
          GoRoute(
            path: '/pos',
            builder: (context, state) => const PosScreen(),
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
            path: '/stock/transfer',
            builder: (context, state) => const StockTransferScreen(),
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
              GoRoute(
                path: 'batch-entry',
                builder: (context, state) => const BatchProductScreen(),
              ),
            ],
          ),
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
          GoRoute(
            path: '/purchases',
            builder: (context, state) => const PurchaseListScreen(),
          ),
          GoRoute(
            path: '/purchases/create',
            builder: (context, state) => const AddPurchaseScreen(),
          ),
          GoRoute(
            path: '/purchases/detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PurchaseDetailScreen(purchaseId: id);
            },
          ),
          GoRoute(
            path: '/purchases/return/:purchaseId',
            builder: (context, state) {
              final purchaseId = state.pathParameters['purchaseId']!;
              return PurchaseReturnScreen(purchaseId: purchaseId);
            },
          ),
          GoRoute(
            path: '/suppliers/account/:id',
            redirect: (_, __) => '/accounts',
            builder: (context, state) {
              return const SizedBox.shrink();
            },
          ),
          GoRoute(
            path: '/supplier-claims',
            builder: (context, state) => const SupplierClaimsListScreen(),
          ),
          GoRoute(
            path: '/supplier-claims/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierClaimDetailScreen(claimId: id);
            },
          ),
          GoRoute(
            path: '/part-search',
            builder: (context, state) => const PartSearchScreen(),
          ),
          GoRoute(
            path: '/vehicles',
            builder: (context, state) => const VehicleListScreen(),
          ),
          GoRoute(
            path: '/vehicles/compatibility/:variantId',
            builder: (context, state) {
              final variantId = state.pathParameters['variantId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return VehicleCompatibilityScreen(
                variantId: variantId,
                variantName: extra?['variantName'] ?? '',
              );
            },
          ),
          GoRoute(
            path: '/categories/add',
            builder: (context, state) => const AddCategoryScreen(),
          ),
          GoRoute(
            path: '/categories/edit/:id',
            builder: (context, state) {
              final extra = state.extra;
              final category = extra is Map<String, dynamic> ? extra : null;
              return AddCategoryScreen(category: category);
            },
          ),
          GoRoute(
            path: '/categories/company-setup',
            builder: (context, state) => const CompanyCategoryScreen(),
          ),
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
          GoRoute(
            path: '/finance/add-income',
            builder: (context, state) => const AddIncomeScreen(),
          ),
          GoRoute(
            path: '/finance/cash-flow',
            builder: (context, state) => const CashFlowScreen(),
          ),
          GoRoute(
            path: '/hrm/employees',
            builder: (context, state) => const EmployeeListScreen(),
          ),
          GoRoute(
            path: '/hrm/employees/add',
            builder: (context, state) => const AddEmployeeScreen(),
          ),
          GoRoute(
            path: '/hrm/employees/edit/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return AddEmployeeScreen(employeeId: id);
            },
          ),
          GoRoute(
            path: '/bulk-import',
            builder: (context, state) => const BulkImportUploadScreen(),
          ),
          GoRoute(
            path: '/bulk-import/supplier-upload',
            builder: (context, state) => const SupplierImportUploadScreen(),
          ),
          GoRoute(
            path: '/bulk-import/review',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return BulkImportReviewScreenV2(
                importId: extra?['importId'] as String?,
                sector: extra?['sector'] as String? ?? 'genel',
              );
            },
          ),
          GoRoute(
            path: '/bulk-import/supplier',
            builder: (context, state) => const SupplierImportReviewScreen(),
          ),
          GoRoute(
            path: '/bulk-import/supplier-wizard',
            builder: (context, state) {
              final extra = state.extra as supplier_models.SupplierUploadResponse?;
              if (extra == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Veri bulunamadi. Lutfen dosya yukleyin.'),
                  ),
                );
              }
              return SupplierUploadWizardScreen(uploadResponse: extra);
            },
          ),
          GoRoute(
            path: '/customers/account/:id',
            redirect: (_, __) => '/accounts',
            builder: (context, state) {
              return const SizedBox.shrink();
            },
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsHubScreen(),
          ),
          GoRoute(
            path: '/stock/movements',
            builder: (context, state) => const StockMovementHistoryScreen(),
          ),
          GoRoute(
            path: '/stock/alerts',
            builder: (context, state) => const StockAlertScreen(),
          ),
          GoRoute(
            path: '/stock/value-report',
            builder: (context, state) => const StockValueReportScreen(),
          ),
          GoRoute(
            path: '/reports/sales-summary',
            builder: (context, state) => const SalesSummaryScreen(),
          ),
          GoRoute(
            path: '/reports/product-analysis',
            builder: (context, state) => const ProductSalesAnalysisScreen(),
          ),
          GoRoute(
            path: '/reports/customer-analysis',
            builder: (context, state) => const CustomerSalesAnalysisScreen(),
          ),
          GoRoute(
            path: '/reports/profit-overview',
            builder: (context, state) => const ProfitOverviewScreen(),
          ),
          GoRoute(
            path: '/reports/daily-summary',
            builder: (context, state) => const DailySummaryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/users',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: '/settings/company',
            builder: (context, state) => const CompanySettingsScreen(),
          ),
          GoRoute(
            path: '/settings/sector',
            builder: (context, state) => const SectorSettingsScreen(),
          ),
          // Sprint 22 — POS Receipt Printer Settings
          GoRoute(
            path: '/settings/printer',
            builder: (context, state) => const PrinterSettingsScreen(),
          ),
          // Sprint 24 — Label Printer Settings (etiket yazıcı L1→L3 promotion)
          GoRoute(
            path: '/settings/label-printer',
            builder: (context, state) => const LabelPrinterSettingsScreen(),
          ),
          // Sprint 23 — Integrations Hub + skeleton ayar ekranları
          GoRoute(
            path: '/settings/integrations',
            builder: (context, state) => const IntegrationsHubScreen(),
          ),
          GoRoute(
            path: '/settings/email',
            builder: (context, state) => const EmailSettingsScreen(),
          ),
          GoRoute(
            path: '/settings/sms',
            builder: (context, state) => const SmsSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});