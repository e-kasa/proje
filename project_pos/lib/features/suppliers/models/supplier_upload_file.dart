// Supplier Upload File Model
// Yüklenen dosyaları temsil eder

class SupplierUploadFile {
  final int id;
  final String uploadId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileType;
  final String? mimeType;

  // Analiz durumu
  final UploadStatus status;
  final int totalRows;
  final int processedRows;
  final int successfulRows;
  final int failedRows;

  // Analiz sonuçları özeti
  final DateTime? analysisCompletedAt;
  final DateTime? processingStartedAt;
  final DateTime? processingCompletedAt;

  // Meta bilgiler
  final int uploadedBy;
  final DateTime uploadedAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  SupplierUploadFile({
    required this.id,
    required this.uploadId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    this.mimeType,
    required this.status,
    this.totalRows = 0,
    this.processedRows = 0,
    this.successfulRows = 0,
    this.failedRows = 0,
    this.analysisCompletedAt,
    this.processingStartedAt,
    this.processingCompletedAt,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SupplierUploadFile.fromJson(Map<String, dynamic> json) {
    return SupplierUploadFile(
      id: json['id'] as int,
      uploadId: json['uploadId'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      fileType: json['fileType'] as String,
      mimeType: json['mimeType'] as String?,
      status: UploadStatus.fromString(json['status'] as String),
      totalRows: json['totalRows'] as int? ?? 0,
      processedRows: json['processedRows'] as int? ?? 0,
      successfulRows: json['successfulRows'] as int? ?? 0,
      failedRows: json['failedRows'] as int? ?? 0,
      analysisCompletedAt: json['analysisCompletedAt'] != null
          ? DateTime.parse(json['analysisCompletedAt'] as String)
          : null,
      processingStartedAt: json['processingStartedAt'] != null
          ? DateTime.parse(json['processingStartedAt'] as String)
          : null,
      processingCompletedAt: json['processingCompletedAt'] != null
          ? DateTime.parse(json['processingCompletedAt'] as String)
          : null,
      uploadedBy: json['uploadedBy'] as int,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uploadId': uploadId,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'fileType': fileType,
      'mimeType': mimeType,
      'status': status.value,
      'totalRows': totalRows,
      'processedRows': processedRows,
      'successfulRows': successfulRows,
      'failedRows': failedRows,
      'analysisCompletedAt': analysisCompletedAt?.toIso8601String(),
      'processingStartedAt': processingStartedAt?.toIso8601String(),
      'processingCompletedAt': processingCompletedAt?.toIso8601String(),
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // Progress yüzdesi hesapla
  double get progressPercentage {
    if (totalRows == 0) return 0.0;
    return (processedRows / totalRows * 100).clamp(0.0, 100.0);
  }

  // Durum kontrolü
  bool get isCompleted => status == UploadStatus.completed;
  bool get isProcessing => status == UploadStatus.processing || status == UploadStatus.analyzing;
  bool get hasFailed => status == UploadStatus.failed;
}

enum UploadStatus {
  uploaded('UPLOADED'),
  analyzing('ANALYZING'),
  analyzed('ANALYZED'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  failed('FAILED');

  final String value;
  const UploadStatus(this.value);

  static UploadStatus fromString(String value) {
    return UploadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UploadStatus.uploaded,
    );
  }
}
