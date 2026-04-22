import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/features/supplier_claims/models/supplier_claim.dart';

/// API: `product/api/v1/supplier-claims/*`
class SupplierClaimsService {
  final ApiClient _api;
  static const String _base = 'product/api/v1/supplier-claims';

  SupplierClaimsService(this._api);

  Future<List<SupplierClaim>> list({ClaimStatus? status, String? supplierId}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status.apiValue;
    if (supplierId != null && supplierId.isNotEmpty) params['supplierId'] = supplierId;

    final response = await _api.get(_base, queryParameters: params);
    final data = response.data['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(SupplierClaim.fromJson)
          .toList();
    }
    return const [];
  }

  Future<SupplierClaim> getById(String id) async {
    final response = await _api.get('$_base/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return SupplierClaim.fromJson(data);
  }

  Future<List<SupplierClaim>> listByPurchase(String purchaseId) async {
    final response = await _api.get('$_base/by-purchase/$purchaseId');
    final data = response.data['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(SupplierClaim.fromJson)
          .toList();
    }
    return const [];
  }

  Future<SupplierClaim> resolve(String id, ResolveClaimRequest request) async {
    final response = await _api.patch('$_base/$id/resolve', data: request.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    return SupplierClaim.fromJson(data);
  }

  Future<SupplierClaim> cancel(String id, {String? reason}) async {
    final response = await _api.patch(
      '$_base/$id/cancel',
      data: {'reason': reason ?? ''},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SupplierClaim.fromJson(data);
  }

  Future<double> openTotalFor(String supplierId) async {
    final response = await _api.get('$_base/suppliers/$supplierId/open-total');
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['openClaimTotal'] as num?)?.toDouble() ?? 0;
  }
}

/// PATCH /{id}/resolve body
class ResolveClaimRequest {
  final ClaimResolution resolution;
  final double resolvedAmount;
  final String? creditNoteNumber;
  final String? notes;

  const ResolveClaimRequest({
    required this.resolution,
    required this.resolvedAmount,
    this.creditNoteNumber,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'resolution': resolution.apiValue,
        'resolvedAmount': resolvedAmount,
        if (creditNoteNumber != null && creditNoteNumber!.isNotEmpty)
          'creditNoteNumber': creditNoteNumber,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
