// Supplier Upload File Row Model
// Dosyadan okunan her satırı temsil eder

class SupplierUploadFileRow {
  final int id;
  final int uploadFileId;
  final int rowNumber;

  // Dosyadan okunan ham veriler
  final String? readProductName;
  final String? readBarcode;
  final String? readSku;
  final double? readQuantity;
  final double? readCostPrice;
  final double? readSellPrice;
  final String? readCategory;
  final String? readBrand;
  final Map<String, dynamic>? readAttributes;
  final String? readNotes;
  final Map<String, dynamic>? readRawData;

  // Eşleşme analizi sonuçları
  final bool isNewProduct;
  final MatchAnalysis? matchAnalysis;

  // Kullanıcı kararı
  final UserDecisionType? userDecision;
  final DateTime? userDecidedAt;
  final int? decidedBy;
  final Map<String, dynamic>? decisionData;

  // İşlem durumu
  final RowStatus status;
  final Map<String, dynamic>? processingResult;
  final String? errorMessage;

  // Meta bilgiler
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierUploadFileRow({
    required this.id,
    required this.uploadFileId,
    required this.rowNumber,
    this.readProductName,
    this.readBarcode,
    this.readSku,
    this.readQuantity,
    this.readCostPrice,
    this.readSellPrice,
    this.readCategory,
    this.readBrand,
    this.readAttributes,
    this.readNotes,
    this.readRawData,
    this.isNewProduct = false,
    this.matchAnalysis,
    this.userDecision,
    this.userDecidedAt,
    this.decidedBy,
    this.decisionData,
    this.status = RowStatus.pending,
    this.processingResult,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierUploadFileRow.fromJson(Map<String, dynamic> json) {
    return SupplierUploadFileRow(
      id: json['id'] as int,
      uploadFileId: json['uploadFileId'] as int,
      rowNumber: json['rowNumber'] as int,
      readProductName: json['readProductName'] as String?,
      readBarcode: json['readBarcode'] as String?,
      readSku: json['readSku'] as String?,
      readQuantity: (json['readQuantity'] as num?)?.toDouble(),
      readCostPrice: (json['readCostPrice'] as num?)?.toDouble(),
      readSellPrice: (json['readSellPrice'] as num?)?.toDouble(),
      readCategory: json['readCategory'] as String?,
      readBrand: json['readBrand'] as String?,
      readAttributes: json['readAttributes'] as Map<String, dynamic>?,
      readNotes: json['readNotes'] as String?,
      readRawData: json['readRawData'] as Map<String, dynamic>?,
      isNewProduct: json['isNewProduct'] as bool? ?? false,
      matchAnalysis: json['matchAnalysis'] != null
          ? MatchAnalysis.fromJson(json['matchAnalysis'] as Map<String, dynamic>)
          : null,
      userDecision: json['userDecision'] != null
          ? UserDecisionType.fromString(json['userDecision'] as String)
          : null,
      userDecidedAt: json['userDecidedAt'] != null
          ? DateTime.parse(json['userDecidedAt'] as String)
          : null,
      decidedBy: json['decidedBy'] as int?,
      decisionData: json['decisionData'] as Map<String, dynamic>?,
      status: RowStatus.fromString(json['status'] as String? ?? 'PENDING'),
      processingResult: json['processingResult'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uploadFileId': uploadFileId,
      'rowNumber': rowNumber,
      'readProductName': readProductName,
      'readBarcode': readBarcode,
      'readSku': readSku,
      'readQuantity': readQuantity,
      'readCostPrice': readCostPrice,
      'readSellPrice': readSellPrice,
      'readCategory': readCategory,
      'readBrand': readBrand,
      'readAttributes': readAttributes,
      'readNotes': readNotes,
      'readRawData': readRawData,
      'isNewProduct': isNewProduct,
      'matchAnalysis': matchAnalysis?.toJson(),
      'userDecision': userDecision?.value,
      'userDecidedAt': userDecidedAt?.toIso8601String(),
      'decidedBy': decidedBy,
      'decisionData': decisionData,
      'status': status.value,
      'processingResult': processingResult,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Durum kontrol metodları
  bool get isPending => status == RowStatus.pending;
  bool get isDecided => userDecision != null;
  bool get isCompleted => status == RowStatus.completed;
  bool get hasFailed => status == RowStatus.failed;
  bool get isSkipped => status == RowStatus.skipped;
}

// Match Analysis
class MatchAnalysis {
  final List<ProductMatch> forProduct;

  MatchAnalysis({required this.forProduct});

  factory MatchAnalysis.fromJson(Map<String, dynamic> json) {
    return MatchAnalysis(
      forProduct: (json['forProduct'] as List<dynamic>?)
              ?.map((e) => ProductMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forProduct': forProduct.map((e) => e.toJson()).toList(),
    };
  }

  ProductMatch? get topMatch => forProduct.isNotEmpty ? forProduct.first : null;
}

class ProductMatch {
  final String productId;
  final String productName;
  final int matchScore;
  final String matchType;
  final List<String> matchReasons;

  ProductMatch({
    required this.productId,
    required this.productName,
    required this.matchScore,
    required this.matchType,
    this.matchReasons = const [],
  });

  factory ProductMatch.fromJson(Map<String, dynamic> json) {
    return ProductMatch(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      matchScore: json['matchScore'] as int,
      matchType: json['matchType'] as String,
      matchReasons: (json['matchReasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'matchScore': matchScore,
      'matchType': matchType,
      'matchReasons': matchReasons,
    };
  }
}

enum UserDecisionType {
  addVariant('ADD_VARIANT'),
  addStock('ADD_STOCK'),
  createNew('CREATE_NEW'),
  editAndCreate('EDIT_AND_CREATE'),
  skip('SKIP');

  final String value;
  const UserDecisionType(this.value);

  static UserDecisionType fromString(String value) {
    return UserDecisionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserDecisionType.skip,
    );
  }
}

enum RowStatus {
  pending('PENDING'),
  decided('DECIDED'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  failed('FAILED'),
  skipped('SKIPPED');

  final String value;
  const RowStatus(this.value);

  static RowStatus fromString(String value) {
    return RowStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RowStatus.pending,
    );
  }
}
