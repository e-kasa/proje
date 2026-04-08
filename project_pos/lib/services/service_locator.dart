import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import 'auth_service.dart';
import 'product_service.dart';
import 'category_service.dart';
import 'company_category_service.dart';
import 'customer_service.dart';
import 'sales_service.dart';
import 'stock_service.dart';
import 'report_service.dart';
import 'supplier_service.dart';
import 'warehouse_service.dart';
import 'store_service.dart';
import 'purchase_service.dart';
import 'brand_service.dart';
import 'unit_service.dart';
import 'vehicle_service.dart';
import 'oem_service.dart';
import 'cross_reference_service.dart';
import 'part_search_service.dart';
import 'account_service.dart';
import 'stock_report_service.dart';
import 'sales_report_service.dart';
import 'user_service.dart';
import 'bulk_import_service.dart';
import 'payment_service.dart';
import 'registration_service.dart';
import 'menu_service.dart';
import 'i18n_service.dart';

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final productServiceProvider = Provider<ProductService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductService(apiClient);
});

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoryService(apiClient);
});

final companyCategoryServiceProvider = Provider<CompanyCategoryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CompanyCategoryService(apiClient);
});

final customerServiceProvider = Provider<CustomerService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerService(apiClient);
});

final salesServiceProvider = Provider<SalesService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SalesService(apiClient);
});

final stockServiceProvider = Provider<StockService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StockService(apiClient);
});

final reportServiceProvider = Provider<ReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportService(apiClient);
});

final supplierServiceProvider = Provider<SupplierService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupplierService(apiClient);
});

final warehouseServiceProvider = Provider<WarehouseService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WarehouseService(apiClient);
});

final storeServiceProvider = Provider<StoreService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StoreService(apiClient);
});

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PurchaseService(apiClient);
});

final brandServiceProvider = Provider<BrandService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BrandService(apiClient);
});

final unitServiceProvider = Provider<UnitService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UnitService(apiClient);
});

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VehicleService(apiClient);
});

final oemServiceProvider = Provider<OemService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OemService(apiClient);
});

final crossReferenceServiceProvider = Provider<CrossReferenceService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CrossReferenceService(apiClient);
});

final partSearchServiceProvider = Provider<PartSearchService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PartSearchService(apiClient);
});

final accountServiceProvider = Provider<AccountService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AccountService(apiClient);
});

final stockReportServiceProvider = Provider<StockReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StockReportService(apiClient);
});

final salesReportServiceProvider = Provider<SalesReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SalesReportService(apiClient);
});

final userServiceProvider = Provider<UserService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserService(apiClient);
});

final bulkImportServiceProvider = Provider<BulkImportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BulkImportService(apiClient);
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentService(apiClient);
});

final registrationServiceProvider = Provider<RegistrationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RegistrationService(apiClient);
});

final menuServiceProvider = Provider<MenuService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MenuService(apiClient);
});

final i18nServiceProvider = Provider<I18nService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return I18nService(apiClient);
});
