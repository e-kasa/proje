import 'package:flutter/material.dart';

/// EKRAN 6: Başarı Ekranı
/// İşlem tamamlandıktan sonra özet gösterir
class SupplierUploadSuccessScreen extends StatelessWidget {
  final String documentNumber;
  final String supplierName;
  final DateTime documentDate;
  final UploadResult result;

  const SupplierUploadSuccessScreen({
    super.key,
    required this.documentNumber,
    required this.supplierName,
    required this.documentDate,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✅ İşlem Tamamlandı'),
        elevation: 0,
        automaticallyImplyLeading: false, // Geri butonu gizle
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Başarıyla Tamamlandı!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Document Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.receipt,
                          label: 'Fiş No',
                          value: documentNumber,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.business,
                          label: 'Tedarikçi',
                          value: supplierName,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Tarih',
                          value: _formatDate(documentDate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Results Summary
                  const Text(
                    'Sonuç Özeti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (result.stockAdded.isNotEmpty) ...[
                    _ResultSection(
                      icon: Icons.inventory,
                      title: 'Stok Eklendi: ${result.stockAdded.length} ürün',
                      items: result.stockAdded,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (result.variantsAdded.isNotEmpty) ...[
                    _ResultSection(
                      icon: Icons.add_box,
                      title: 'Varyant Eklendi: ${result.variantsAdded.length} ürün',
                      items: result.variantsAdded,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (result.newProducts.isNotEmpty) ...[
                    _ResultSection(
                      icon: Icons.fiber_new,
                      title: 'Yeni Ürün: ${result.newProducts.length} ürün',
                      items: result.newProducts,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (result.skipped.isNotEmpty) ...[
                    _ResultSection(
                      icon: Icons.skip_next,
                      title: 'Atlandı: ${result.skipped.length} ürün',
                      items: result.skipped,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to products page
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.inventory_2),
                          label: const Text('Ürünlere Git'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // View document
                          },
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Fişi Görüntüle'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate back to upload screen
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Yeni Yükleme'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Info Row Widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Result Section Widget
class _ResultSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;

  const _ResultSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(
                  '• $item',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

/// Upload Result Data Model
class UploadResult {
  final List<String> stockAdded;
  final List<String> variantsAdded;
  final List<String> newProducts;
  final List<String> skipped;

  UploadResult({
    required this.stockAdded,
    required this.variantsAdded,
    required this.newProducts,
    required this.skipped,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      stockAdded: List<String>.from(json['stockAdded'] ?? []),
      variantsAdded: List<String>.from(json['variantsAdded'] ?? []),
      newProducts: List<String>.from(json['newProducts'] ?? []),
      skipped: List<String>.from(json['skipped'] ?? []),
    );
  }
}
