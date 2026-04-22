import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/features/supplier_claims/services/supplier_claims_service.dart';

final supplierClaimsServiceProvider = Provider<SupplierClaimsService>((ref) {
  return SupplierClaimsService(ref.watch(apiClientProvider));
});
