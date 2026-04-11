import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// POS'ta seçilen ürünün kendi mağazasında stoğu yokken
/// başka lokasyonda mevcut olduğunda gösterilen uyarı dialogu.
///
/// Kullanıcıya:
///   - Hangi lokasyonlarda kaç adet olduğu gösterilir
///   - "Yine de Ekle" ile sepete forceAdd yapılır
///   - "İptal" ile işlem durdurulur
class OutOfStockLocationDialog extends StatelessWidget {
  /// crossLocationAlert map: {product, variant, productName, otherLocations}
  final Map<String, dynamic> alert;

  /// Kullanıcı "Yine de Ekle" seçtiğinde çağrılır
  final VoidCallback onForceAdd;

  /// Kullanıcı "İptal" seçtiğinde çağrılır
  final VoidCallback onCancel;

  const OutOfStockLocationDialog({
    super.key,
    required this.alert,
    required this.onForceAdd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final productName = alert['productName']?.toString() ?? '';
    final otherLocations =
        (alert['otherLocations'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Uyarı ikonu
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.bgWarning,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.warning,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            const Text(
              'Mağazanızda Stok Yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              productName,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Mevcut lokasyonlar
            if (otherLocations.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgDanger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hiçbir lokasyonda stok bulunamadı.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Stok Mevcut Konumlar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...otherLocations.map((loc) => _buildLocationRow(loc)),
            ],

            const SizedBox(height: 24),

            // Aksiyon butonları
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'İptal',
                    onPressed: () {
                      Navigator.pop(context);
                      onCancel();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: otherLocations.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            onForceAdd();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Yine de Ekle',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(Map<String, dynamic> loc) {
    final qty = (loc['physicalQuantity'] as num?)?.toInt() ?? 0;
    final storeId = loc['storeId']?.toString();
    final warehouseId = loc['warehouseId']?.toString();

    // Lokasyon etiketi: store ID'nin son segmentini göster
    String locationLabel;
    IconData locationIcon;
    if (storeId != null && storeId.isNotEmpty) {
      locationLabel = 'Mağaza (${storeId.split('-').last.toUpperCase()})';
      locationIcon = Icons.store_outlined;
    } else if (warehouseId != null && warehouseId.isNotEmpty) {
      locationLabel = 'Depo (${warehouseId.split('-').last.toUpperCase()})';
      locationIcon = Icons.warehouse_outlined;
    } else {
      locationLabel = 'Diğer Konum';
      locationIcon = Icons.location_on_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgInfo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(locationIcon, color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              locationLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgSuccess,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$qty Adet',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}