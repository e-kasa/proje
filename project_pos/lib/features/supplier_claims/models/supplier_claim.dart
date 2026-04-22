// Supplier Claim models — tedarikçi eksik teslim / hasarlı teslim talepleri.
// Backend: SupplierClaimControllerImpl (`product/api/v1/supplier-claims`).

class SupplierClaim {
  final String id;
  final String? supplierId;
  final String? supplierName;
  final String? sourcePurchaseId;
  final String? sourcePurchaseInvoice;
  final double claimAmount;
  final double resolvedAmount;
  final ClaimStatus status;
  final ClaimReason reason;
  final ClaimResolution? resolution;
  final DateTime? claimDate;
  final DateTime? resolvedDate;
  final String? notes;
  final bool isFullyResolved;
  final List<SupplierClaimLine> lines;

  const SupplierClaim({
    required this.id,
    this.supplierId,
    this.supplierName,
    this.sourcePurchaseId,
    this.sourcePurchaseInvoice,
    this.claimAmount = 0,
    this.resolvedAmount = 0,
    this.status = ClaimStatus.open,
    this.reason = ClaimReason.shortage,
    this.resolution,
    this.claimDate,
    this.resolvedDate,
    this.notes,
    this.isFullyResolved = false,
    this.lines = const [],
  });

  factory SupplierClaim.fromJson(Map<String, dynamic> json) {
    return SupplierClaim(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString(),
      supplierName: json['supplierName']?.toString(),
      sourcePurchaseId: json['sourcePurchaseId']?.toString(),
      sourcePurchaseInvoice: json['sourcePurchaseInvoice']?.toString(),
      claimAmount: (json['claimAmount'] as num?)?.toDouble() ?? 0,
      resolvedAmount: (json['resolvedAmount'] as num?)?.toDouble() ?? 0,
      status: ClaimStatus.fromString(json['status']?.toString()),
      reason: ClaimReason.fromString(json['claimReason']?.toString()),
      resolution: json['resolution'] != null
          ? ClaimResolution.fromString(json['resolution'].toString())
          : null,
      claimDate: _parseDate(json['claimDate']),
      resolvedDate: _parseDate(json['resolvedDate']),
      notes: json['notes']?.toString(),
      isFullyResolved: json['fullyResolved'] as bool? ?? json['isFullyResolved'] as bool? ?? false,
      lines: (json['lines'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(SupplierClaimLine.fromJson)
              .toList() ??
          const [],
    );
  }

  double get remainingAmount =>
      (claimAmount - resolvedAmount).clamp(0, double.infinity);

  bool get isOpen => status == ClaimStatus.open;
  bool get isResolved => status == ClaimStatus.resolved;
  bool get isCancelled => status == ClaimStatus.cancelled;

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

class SupplierClaimLine {
  final String id;
  final String? variantId;
  final String? variantSku;
  final String? productName;
  final int expectedQty;
  final int receivedQty;
  final int shortageQty;
  final double unitPrice;
  final double lineAmount;
  final ClaimReason reason;
  final String? notes;
  final int resolvedQty;
  final double resolvedAmount;
  final bool isResolved;

  const SupplierClaimLine({
    required this.id,
    this.variantId,
    this.variantSku,
    this.productName,
    this.expectedQty = 0,
    this.receivedQty = 0,
    this.shortageQty = 0,
    this.unitPrice = 0,
    this.lineAmount = 0,
    this.reason = ClaimReason.shortage,
    this.notes,
    this.resolvedQty = 0,
    this.resolvedAmount = 0,
    this.isResolved = false,
  });

  factory SupplierClaimLine.fromJson(Map<String, dynamic> json) {
    final expected = (json['expectedQty'] as num?)?.toInt() ?? 0;
    final received = (json['receivedQty'] as num?)?.toInt() ?? 0;
    final shortageFromJson = (json['shortageQty'] as num?)?.toInt();
    return SupplierClaimLine(
      id: json['id']?.toString() ?? '',
      variantId: json['variantId']?.toString(),
      variantSku: json['variantSku']?.toString(),
      productName: json['productName']?.toString(),
      expectedQty: expected,
      receivedQty: received,
      shortageQty: shortageFromJson ?? (expected - received).clamp(0, 1 << 31),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineAmount: (json['lineAmount'] as num?)?.toDouble() ?? 0,
      reason: ClaimReason.fromString(json['reason']?.toString()),
      notes: json['notes']?.toString(),
      resolvedQty: (json['resolvedQty'] as num?)?.toInt() ?? 0,
      resolvedAmount: (json['resolvedAmount'] as num?)?.toDouble() ?? 0,
      isResolved: json['resolved'] as bool? ?? json['isResolved'] as bool? ?? false,
    );
  }
}

/// Batch cevabında dönen özet — liste ekranına atlamak için yeterlidir.
class SupplierClaimSummary {
  final String claimId;
  final double claimAmount;
  final int lineCount;
  final ClaimStatus status;
  final ClaimReason reason;

  const SupplierClaimSummary({
    required this.claimId,
    this.claimAmount = 0,
    this.lineCount = 0,
    this.status = ClaimStatus.open,
    this.reason = ClaimReason.shortage,
  });

  factory SupplierClaimSummary.fromJson(Map<String, dynamic> json) {
    return SupplierClaimSummary(
      claimId: json['claimId']?.toString() ?? '',
      claimAmount: (json['claimAmount'] as num?)?.toDouble() ?? 0,
      lineCount: (json['lineCount'] as num?)?.toInt() ?? 0,
      status: ClaimStatus.fromString(json['status']?.toString()),
      reason: ClaimReason.fromString(json['reason']?.toString()),
    );
  }
}

enum ClaimStatus {
  open('OPEN'),
  partiallyResolved('PARTIALLY_RESOLVED'),
  resolved('RESOLVED'),
  cancelled('CANCELLED');

  final String apiValue;
  const ClaimStatus(this.apiValue);

  static ClaimStatus fromString(String? v) => ClaimStatus.values.firstWhere(
        (s) => s.apiValue == v,
        orElse: () => ClaimStatus.open,
      );
}

enum ClaimReason {
  shortage('SHORTAGE'),
  damage('DAMAGE'),
  wrongItem('WRONG_ITEM'),
  other('OTHER');

  final String apiValue;
  const ClaimReason(this.apiValue);

  static ClaimReason fromString(String? v) => ClaimReason.values.firstWhere(
        (r) => r.apiValue == v,
        orElse: () => ClaimReason.shortage,
      );
}

enum ClaimResolution {
  discount('DISCOUNT'),
  delivery('DELIVERY'),
  refund('REFUND'),
  replacement('REPLACEMENT'),
  writeOff('WRITE_OFF');

  final String apiValue;
  const ClaimResolution(this.apiValue);

  static ClaimResolution fromString(String? v) => ClaimResolution.values.firstWhere(
        (r) => r.apiValue == v,
        orElse: () => ClaimResolution.discount,
      );
}
