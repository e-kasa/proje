import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/modern_dashboard_screen.dart';
import '../../screens/sales/sale_list_screen.dart';
import '../../screens/sales/sale_detail_screen.dart';
import '../../screens/sales/sale_return_screen.dart';
import '../../screens/purchases/purchase_return_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/inventory/enhanced_product_list_screen.dart';
import '../../screens/inventory/product_detail_screen.dart';
import '../../screens/inventory/add_product/add_product_wizard_screen.dart';
import '../../screens/inventory/brands_screen.dart';
import '../../screens/inventory/units_screen.dart';
import '../../screens/inventory/barcode_management_screen.dart';
import '../../screens/inventory/batch_entry/batch_product_screen.dart';
import '../../screens/categories/category_list_screen.dart';
import '../../screens/categories/add_category_screen.dart';
import '../../screens/categories/company_category_screen.dart';
import '../../screens/customers/customer_list_screen.dart';
import '../../screens/customers/add_customer_screen.dart';
import '../../screens/suppliers/supplier_list_screen.dart';
import '../../screens/suppliers/add_supplier_screen.dart';
import '../../screens/pos/pos_screen.dart';
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
import '../../screens/finance/add_income_screen.dart';
import '../../screens/finance/payment_list_screen.dart';
import '../../screens/finance/cash_flow_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/user_management_screen.dart';
import '../../screens/settings/company_settings_screen.dart';
import '../../screens/settings/sector_settings_screen.dart';
import '../../screens/hrm/employee_list_screen.dart';
import '../../screens/hrm/add_employee_screen.dart';
import '../../screens/bulk_import/bulk_import_upload_screen.dart';
import '../../screens/bulk_import/bulk_import_review_screen_v2.dart';
import '../../screens/bulk_import/supplier_import_review_screen.dart';
import '../../screens/bulk_import/supplier_import_upload_screen.dart';
import '../../screens/supplier_upload/supplier_upload_wizard_screen.dart';
import '../../models/supplier_upload_models.dart' as supplier_models;
import '../../screens/stock/multi_warehouse_stock_screen.dart';
import '../../screens/stock/stock_transfer_review_screen.dart';
import '../../screens/stock/stock_count_review_screen.dart';
import '../../screens/purchases/purchase_list_screen.dart';
import '../../screens/purchases/add_purchase_screen.dart';
import '../../screens/purchases/purchase_detail_screen.dart';
import '../../screens/suppliers/supplier_account_detail_screen.dart';
import '../../screens/suppliers/supplier_detail_screen.dart';
import '../../screens/vehicles/vehicle_list_screen.dart';
import '../../screens/part_search/part_search_screen.dart';
import '../../screens/vehicles/vehicle_compatibility_screen.dart';
import '../../screens/customers/customer_account_detail_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';
import '../../screens/accounts/account_summary_dashboard_screen.dart';
import '../../screens/accounts/account_statement_screen.dart';
import '../../screens/accounts/overdue_tracking_screen.dart';
import '../../screens/stock/stock_transfer_screen.dart';
import '../../screens/stock/stock_movement_history_screen.dart';
import '../../screens/stock/stock_alert_screen.dart';
import '../../screens/stock/stock_value_report_screen.dart';
import '../../screens/reports/sales_summary_screen.dart';
import '../../screens/reports/product_sales_analysis_screen.dart';
import '../../screens/reports/customer_sales_analysis_screen.dart';
import '../../screens/reports/profit_overview_screen.dart';
import '../../screens/reports/daily_summary_screen.dart';
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
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
            path: '/customers/detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerDetailScreen(customerId: id);
            },
          ),
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
            path: '/suppliers/detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierDetailScreen(supplierId: id);
            },
          ),
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
          GoRoute(
            path: '/suppliers/account/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SupplierAccountDetailScreen(supplierId: id);
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
            path: '/finance/payments',
            builder: (context, state) => const PaymentListScreen(),
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
            builder: (context, state) => const BulkImportReviewScreenV2(),
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
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerAccountDetailScreen(customerId: id);
            },
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountSummaryDashboardScreen(),
          ),
          GoRoute(
            path: '/accounts/statement',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AccountStatementScreen(
                accountType: extra['accountType'] as String?,
                accountId: extra['accountId'] as String?,
                accountName: extra['accountName'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/accounts/overdue',
            builder: (context, state) => const OverdueTrackingScreen(),
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
        ],
      ),
    ],
  );
});
