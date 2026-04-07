import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// Urun grid karti — POS ekraninda urunleri kompakt kart olarak gosterir.
///
/// Icerik: isim, fiyat (TL), stok badge, kategori bilgisi, SKU.
/// Tiklandiginda [onTap] callback cagirilir (sepete ekleme veya varyant secimi).
class ProductGridItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const ProductGridItem({
    super.key,
    required this.product,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? '';
    final price = (product['sellingPrice'] as num?)?.toDouble() ??
        (product['basePrice'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0.0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final sku = product['sku']?.toString() ?? '';
    final categoryName = product['categoryName']?.toString();

    // Mağaza bazlı stok (PosNotifier normalize ettiyse)
    final myStoreStock =
        (product['myStoreStock'] as num?)?.toInt() ?? stock;
    final availableElsewhere = product['availableElsewhere'] == true;

    // Kart durumu: kendi mağazasında 0 ama başka yerde var → tıklanabilir (dialog çıkar)
    final isOutOfStock = myStoreStock <= 0 && !availableElsewhere;
    final isTransferOnly = myStoreStock <= 0 && availableElsewhere;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isOutOfStock
                ? AppColors.bgLight.withOpacity(0.7)
                : isTransferOnly
                    ? AppColors.bgWarning.withOpacity(0.3)
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isTransferOnly
                  ? AppColors.warning.withOpacity(0.5)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ust satir: isim + stok badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urun thumbnail placeholder
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? AppColors.bgLight
                          : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: isOutOfStock
                          ? AppColors.textMuted
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Stok badge
                  _buildStockBadge(myStoreStock, isOutOfStock, isTransferOnly),
                ],
              ),

              const Spacer(),

              // Kategori chip
              if (categoryName != null && categoryName.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgInfo,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // SKU
              if (sku.isNotEmpty)
                Text(
                  sku,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 4),

              // Fiyat
              Text(
                currencyFormat.format(price),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isOutOfStock
                      ? AppColors.textMuted
                      : isTransferOnly
                          ? AppColors.warning
                          : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock, bool isOutOfStock, bool isTransferOnly) {
    Color bgColor;
    Color textColor;
    String label;

    if (isOutOfStock) {
      bgColor = AppColors.bgDanger;
      textColor = AppColors.danger;
      label = 'Tükendi';
    } else if (isTransferOnly) {
      bgColor = AppColors.bgWarning;
      textColor = AppColors.warning;
      label = 'Transferde';
    } else if (stock <= 5) {
      bgColor = AppColors.bgWarning;
      textColor = AppColors.warning;
      label = '$stock';
    } else {
      bgColor = AppColors.bgSuccess;
      textColor = AppColors.success;
      label = '$stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
