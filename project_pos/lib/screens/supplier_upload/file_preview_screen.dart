import 'package:flutter/material.dart';

/// EKRAN 2: Önizleme
/// Kullanıcı yüklenen dosyanın ilk 5-10 satırını görür ve doğrular
class FilePreviewScreen extends StatefulWidget {
  final String fileName;
  final List<Map<String, dynamic>> previewRows;

  const FilePreviewScreen({
    super.key,
    required this.fileName,
    required this.previewRows,
  });

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  bool _isProcessing = false;

  Future<void> _confirmAndProceed() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // TODO: Uncomment when backend endpoint is ready
      // final result = await ref.read(apiClientProvider).post(
      //   'product/api/v1/supplier-upload/analyze',
      //   data: {'fileId': widget.fileId},
      // );

      // For now, simulate analysis
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Analiz ekranına geç (Ekran 3)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya analiz için gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👁️ Dosya Önizleme'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.fileName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.previewRows.length} satır bulundu (ilk 5 gösteriliyor)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      border: Border.all(color: Colors.amber[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[900]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sütunlar doğru görünüyor mu? Devam ettiğinizde ürünler sistemdeki mevcut ürünlerle eşleştirilecek.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Preview Table
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.blue[50],
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          '#',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Ürün Adı',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Barkod',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Adet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Alış ₺',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Satış ₺',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                    ],
                    rows: widget.previewRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            Text(row['productName'] ?? '-'),
                          ),
                          DataCell(
                            Text(row['barcode'] ?? '-'),
                          ),
                          DataCell(
                            Text(row['quantity']?.toString() ?? '0'),
                          ),
                          DataCell(
                            Text(
                              row['costPrice']?.toStringAsFixed(2) ?? '0.00',
                            ),
                          ),
                          DataCell(
                            Text(
                              row['sellPrice']?.toStringAsFixed(2) ?? '0.00',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _confirmAndProceed,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isProcessing ? 'İşleniyor...' : 'Doğru, Devam Et',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
