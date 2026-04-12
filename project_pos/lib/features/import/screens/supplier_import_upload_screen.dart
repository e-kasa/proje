import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// Tedarikçi Dosya Yükleme ve Backend Entegrasyon Ekranı
class SupplierImportUploadScreen extends ConsumerStatefulWidget {
  const SupplierImportUploadScreen({super.key});

  @override
  ConsumerState<SupplierImportUploadScreen> createState() =>
      _SupplierImportUploadScreenState();
}

class _SupplierImportUploadScreenState
    extends ConsumerState<SupplierImportUploadScreen> {
  String Function(String) get t => i18nOf(ref);

  // State
  File? _selectedFile;
  bool _uploading = false;
  bool _analyzing = false;
  double _uploadProgress = 0.0;
  String? _importId;
  String? _errorMessage;

  // Form fields
  final _supplierController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _supplierController.dispose();
    _invoiceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  /// ADIM 1: Dosya seç
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Dosya seçilemedi: ${e.toString()}';
      });
    }
  }

  /// ADIM 2: Backend'e yükle ve analiz başlat
  Future<void> _uploadAndAnalyze() async {
    if (_selectedFile == null) {
      setState(() => _errorMessage = t('bulk_import.please_select_file')); // TODO: i18n
      return;
    }

    setState(() {
      _uploading = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      _importId = await _uploadToBackend();

      setState(() {
        _uploading = false;
        _analyzing = true;
      });

      // ADIM 3: Analiz sonucunu bekle (Polling)
      await _waitForAnalysisResult();

    } catch (e) {
      setState(() {
        _uploading = false;
        _analyzing = false;
        _errorMessage = 'Hata: ${e.toString()}';
      });
    }
  }

  /// Backend'e dosya yükle
  Future<String> _uploadToBackend() async {
    final bulkImportService = ref.read(bulkImportServiceProvider);
    final importId = await bulkImportService.uploadFile(_selectedFile!);
    if (mounted) {
      setState(() => _uploadProgress = 1.0);
    }
    return importId;
  }

  /// Analiz sonucunu bekle (Polling)
  Future<void> _waitForAnalysisResult() async {
    try {
      final bulkImportService = ref.read(bulkImportServiceProvider);
      await bulkImportService.waitForAnalysis(importId: _importId!);

      if (mounted) {
        setState(() => _analyzing = false);
        context.push('/bulk-import/supplier', extra: {
          'importId': _importId,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzing = false;
          _errorMessage = '${t('bulk_import.analysis_error')}: ${e.toString()}'; // TODO: i18n
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('supplier_upload.upload'),
        elevation: 0,
      ),
      body: _uploading || _analyzing
          ? _buildProgressView()
          : _buildUploadForm(),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bilgilendirme kartı
          _buildInfoCard(),
          const SizedBox(height: 24),

          // Dosya seçim alanı
          _buildFilePickerArea(),
          const SizedBox(height: 24),

          // Form alanları
          _buildFormFields(),
          const SizedBox(height: 24),

          // Yükle butonu
          _buildUploadButton(),

          // Hata mesajı
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(),
          ],

          const SizedBox(height: 24),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  t('bulk_import.how_it_works'), // TODO: i18n
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoStep(1, t('supplier_upload.step1')), // TODO: i18n
            _buildInfoStep(2, t('supplier_upload.step2')), // TODO: i18n
            _buildInfoStep(3, t('supplier_upload.step3')), // TODO: i18n
            _buildInfoStep(4, t('supplier_upload.step4')), // TODO: i18n
            _buildInfoStep(5, t('supplier_upload.step5')), // TODO: i18n
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildFilePickerArea() {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _selectedFile != null ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedFile != null ? Colors.green : Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
              size: 64,
              color: _selectedFile != null ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile != null
                  ? _selectedFile!.path.split('/').last
                  : t('supplier_upload.select_excel_csv'), // TODO: i18n
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _selectedFile != null ? Colors.green[700] : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFile != null
                  ? t('supplier_upload.file_selected') // TODO: i18n
                  : t('supplier_upload.click_select'), // TODO: i18n
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('supplier_upload.supplier_info_optional'), // TODO: i18n
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Tedarikçi',
                hintText: 'Tedarikçi adı veya ID',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _invoiceController,
              decoration: const InputDecoration(
                labelText: 'Fatura Numarası',
                hintText: 'FAT-2025-001',
                prefixIcon: Icon(Icons.receipt_long),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Satın Alma Tarihi',
                hintText: '2025-01-03',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dateController.text =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton.icon(
      onPressed: _selectedFile != null ? _uploadAndAnalyze : null,
      icon: const Icon(Icons.upload, size: 24),
      label: Text(
        t('supplier_upload.upload_analyze'), // TODO: i18n
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  t('supplier_upload.excel_csv_format'), // TODO: i18n
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t('supplier_upload.excel_columns_required'), // TODO: i18n
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildColumnInfo('Ürün Adı', 'zorunlu'),
            _buildColumnInfo('Barkod', 'önerilen'),
            _buildColumnInfo('Marka', 'önerilen'),
            _buildColumnInfo('Stok', 'zorunlu'),
            _buildColumnInfo('Alış Fiyatı', 'önerilen'),
            _buildColumnInfo('Satış Fiyatı', 'önerilen'),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnInfo(String name, String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, size: 8),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: requirement == 'zorunlu'
                  ? Colors.red[100]
                  : Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 11,
                color: requirement == 'zorunlu'
                    ? Colors.red[700]
                    : Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_uploading) ...[
              const CircularProgressIndicator(strokeWidth: 6),
              const SizedBox(height: 24),
              Text(
                t('bulk_import.step_uploading'), // TODO: i18n
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 8,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ] else if (_analyzing) ...[
              const CircularProgressIndicator(strokeWidth: 6),
              const SizedBox(height: 24),
              Text(
                t('bulk_import.step_analyzing'), // TODO: i18n
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t('supplier_upload.searching_similar'), // TODO: i18n
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                width: 200,
                child: LinearProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}