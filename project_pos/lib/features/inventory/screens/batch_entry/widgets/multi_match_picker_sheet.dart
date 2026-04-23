import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';

/// Barkod araması ≥ 2 ürün döndürdüğünde açılan seçim sayfası.
///
/// Tek eşleşmede direkt satır eklenir; burada kullanıcı sepetine hangi
/// ürünün gireceğini netleştirir. Seçim → Navigator.pop(chosenProduct).
class MultiMatchPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final String Function(String) t;

  const MultiMatchPickerSheet({
    super.key,
    required this.matches,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t('batch.multi_match_title'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${matches.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('batch.multi_match_hint'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: matches.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final p = matches[i];
                  final name = p['name']?.toString() ?? '—';
                  final sku = p['sku']?.toString();
                  final barcode = p['barcode']?.toString();
                  final brand = p['brand']?.toString();
                  final sale = (p['sellingPrice'] as num?)?.toDouble() ??
                      (p['basePrice'] as num?)?.toDouble();
                  final stock = (p['stock'] as num?)?.toDouble();
                  final variantCount = (p['variants'] as List?)?.length ?? 0;

                  return ListTile(
                    onTap: () => Navigator.of(ctx).pop(p),
                    dense: true,
                    title: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            if (brand != null && brand.isNotEmpty)
                              _chip(Icons.sell_outlined, brand),
                            if (barcode != null && barcode.isNotEmpty)
                              _chip(Icons.qr_code_2_rounded, barcode),
                            if (sku != null && sku.isNotEmpty)
                              _chip(Icons.tag_rounded, sku),
                            if (variantCount > 0)
                              _chip(Icons.layers_rounded, '$variantCount var.'),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (sale != null)
                          Text(
                            '₺${sale.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        if (stock != null)
                          Text(
                            'Stok: ${stock.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
}
