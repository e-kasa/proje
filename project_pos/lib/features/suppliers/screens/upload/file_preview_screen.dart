import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// EKRAN 2: Önizleme
/// Kullanıcı yüklenen dosyanın ilk 5-10 satırını görür ve doğrular
class FilePreviewScreen extends ConsumerStatefulWidget {
  final String fileName;
  final List<Map<String, dynamic>> previewRows;

  const FilePreviewScreen({
    super.key,
    required this.fileName,
    required this.previewRows,
  });

  @override
  ConsumerState<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends ConsumerState<FilePreviewScreen> {
  String Function(String) get t => i18nOf(ref);
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
        AppToast.success(context, 'Dosya analiz için gönderildi');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Hata: $e');
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
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Dosya Önizleme', // TODO: i18n supplier_upload.file_preview
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              hasShadow: true,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                hasShadow: true,
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
                          'Ürün Adı', // TODO: i18n supplier_upload.col_product_name
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Barkod', // TODO: i18n supplier_upload.col_barcode
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Adet', // TODO: i18n supplier_upload.col_quantity
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Alış ₺', // TODO: i18n supplier_upload.col_buy_price
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Satış ₺', // TODO: i18n supplier_upload.col_sell_price
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
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                  label: const Text('Geri'), // TODO: i18n common.back
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                AppButton.primary(
                  text: _isProcessing ? 'İşleniyor...' : 'Doğru, Devam Et', // TODO: i18n supplier_upload.confirm_proceed / common.processing
                  icon: Icons.check,
                  onPressed: _isProcessing ? null : _confirmAndProceed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}