import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/widgets/widgets.dart';

/// EKRAN 1: Dosya Yükle
/// Kullanıcı tedarikçi seçer ve Excel/CSV dosyası yükler
class SupplierFileUploadScreen extends StatefulWidget {
  const SupplierFileUploadScreen({super.key});

  @override
  State<SupplierFileUploadScreen> createState() =>
      _SupplierFileUploadScreenState();
}

class _SupplierFileUploadScreenState extends State<SupplierFileUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  int? _selectedSupplierId;
  File? _selectedFile;
  String? _fileName;
  int? _fileSize;

  // Dummy data - Production'da API'den gelecek
  final List<Map<String, dynamic>> _suppliers = [
    {'id': 1, 'name': 'Mavi Tekstil'},
    {'id': 2, 'name': 'Apple Türkiye'},
    {'id': 3, 'name': 'Samsung Elektronik'},
    {'id': 4, 'name': 'Nike Store'},
    {'id': 5, 'name': 'Adidas Spor'},
  ];

  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileSize = result.files.single.size;
        });
      }
    } catch (e) {
      _showError('Dosya seçilirken hata oluştu: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      _showError('Lütfen bir dosya seçin');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // TODO: Uncomment when backend endpoint is ready
      // final response = await ref.read(apiClientProvider).upload(
      //   'product/api/v1/supplier-upload/file',
      //   filePath: _selectedFile!.path,
      //   fieldName: 'file',
      // );
      // Navigate to preview with response data

      // For now, simulate upload
      await Future.delayed(const Duration(seconds: 1));

      // Önizleme ekranına git
      if (mounted) {
        // Navigator.push(...) - Ekran 2'ye geç
        _showSuccess('Dosya yüklendi, önizleme gösteriliyor...');
      }
    } catch (e) {
      _showError('Yükleme hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.standard(
        title: '📦 Tedarikçi Dosyası Yükle',
        elevation: 0,
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık
                  Text(
                    'Tedarikçi Dosyası Yükle',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Excel veya CSV formatında tedarikçi fişi yükleyin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Tedarikçi Seçimi
                  DropdownButtonFormField<int>(
                    value: _selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Tedarikçi Seçin',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    items: _suppliers.map((supplier) {
                      return DropdownMenuItem<int>(
                        value: supplier['id'] as int,
                        child: Text(supplier['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplierId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Lütfen bir tedarikçi seçin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dosya Seçimi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedFile != null
                            ? Colors.green
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (_selectedFile == null) ...[
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Excel/CSV Dosyası',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Desteklenen formatlar: .xlsx, .xls, .csv',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.insert_drive_file,
                            size: 48,
                            color: Colors.green[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fileName ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          if (_fileSize != null)
                            Text(
                              'Boyut: ${_formatFileSize(_fileSize!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: Text(
                            _selectedFile == null
                                ? 'Dosya Seç...'
                                : 'Farklı Dosya Seç',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isUploading
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('İptal'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadFile,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: Text(
                          _isUploading ? 'Yükleniyor...' : 'Yükle ve Devam Et',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}