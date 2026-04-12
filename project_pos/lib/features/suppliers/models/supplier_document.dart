// Supplier Document Model
// Tedarikçi fiş, fatura, irsaliye gibi belgeleri temsil eder

class SupplierDocument {
  final int id;
  final String documentNumber;

  // Döküman bilgileri
  final DocumentType documentType;
  final int supplierId;

  // Döküman tarihleri
  final DateTime documentDate;
  final DateTime? deliveryDate;
  final DateTime? dueDate;

  // Finansal bilgiler
  final String currency;
  final double? totalAmount;
  final double? taxAmount;
  final double? discountAmount;
  final double? netAmount;

  // Ödeme bilgileri
  final PaymentStatus paymentStatus;
  final double paidAmount;
  final DateTime? paymentDueDate;

  // Döküman durumu
  final DocumentStatus status;
  final ApprovalStatus approvalStatus;
  final int? approvedBy;
  final DateTime? approvedAt;

  // Notlar ve açıklamalar
  final String? notes;
  final String? internalNotes;

  // Meta bilgiler
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  SupplierDocument({
    required this.id,
    required this.documentNumber,
    required this.documentType,
    required this.supplierId,
    required this.documentDate,
    this.deliveryDate,
    this.dueDate,
    this.currency = 'TRY',
    this.totalAmount,
    this.taxAmount,
    this.discountAmount,
    this.netAmount,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paidAmount = 0.0,
    this.paymentDueDate,
    this.status = DocumentStatus.draft,
    this.approvalStatus = ApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.notes,
    this.internalNotes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SupplierDocument.fromJson(Map<String, dynamic> json) {
    return SupplierDocument(
      id: json['id'] as int,
      documentNumber: json['documentNumber'] as String,
      documentType: DocumentType.fromString(json['documentType'] as String),
      supplierId: json['supplierId'] as int,
      documentDate: DateTime.parse(json['documentDate'] as String),
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'] as String)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      currency: json['currency'] as String? ?? 'TRY',
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      netAmount: (json['netAmount'] as num?)?.toDouble(),
      paymentStatus: PaymentStatus.fromString(json['paymentStatus'] as String? ?? 'UNPAID'),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      paymentDueDate: json['paymentDueDate'] != null
          ? DateTime.parse(json['paymentDueDate'] as String)
          : null,
      status: DocumentStatus.fromString(json['status'] as String? ?? 'DRAFT'),
      approvalStatus: ApprovalStatus.fromString(json['approvalStatus'] as String? ?? 'PENDING'),
      approvedBy: json['approvedBy'] as int?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      internalNotes: json['internalNotes'] as String?,
      createdBy: json['createdBy'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentNumber': documentNumber,
      'documentType': documentType.value,
      'supplierId': supplierId,
      'documentDate': documentDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'currency': currency,
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'netAmount': netAmount,
      'paymentStatus': paymentStatus.value,
      'paidAmount': paidAmount,
      'paymentDueDate': paymentDueDate?.toIso8601String(),
      'status': status.value,
      'approvalStatus': approvalStatus.value,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'notes': notes,
      'internalNotes': internalNotes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // Kalan borç
  double get remainingAmount {
    if (totalAmount == null) return 0.0;
    return totalAmount! - paidAmount;
  }

  // Durum kontrolü
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isConfirmed => status == DocumentStatus.confirmed;
}

enum DocumentType {
  fis('FIS'),
  fatura('FATURA'),
  irsaliye('IRSALIYE'),
  siparis('SIPARIS');

  final String value;
  const DocumentType(this.value);

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.fis,
    );
  }
}

enum PaymentStatus {
  unpaid('UNPAID'),
  partial('PARTIAL'),
  paid('PAID');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

enum DocumentStatus {
  draft('DRAFT'),
  confirmed('CONFIRMED'),
  approved('APPROVED'),
  cancelled('CANCELLED');

  final String value;
  const DocumentStatus(this.value);

  static DocumentStatus fromString(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DocumentStatus.draft,
    );
  }
}

enum ApprovalStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  final String value;
  const ApprovalStatus(this.value);

  static ApprovalStatus fromString(String value) {
    return ApprovalStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ApprovalStatus.pending,
    );
  }
}
