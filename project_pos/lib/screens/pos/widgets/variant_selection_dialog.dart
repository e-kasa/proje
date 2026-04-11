import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// Dialog untuk memilih varian produk sebelum menambahkan ke keranjang.
///
/// Menampilkan:
/// - Nama produk
/// - Grid/list varian dengan atribut, harga, dan stok
/// - Badge stok untuk setiap varian
/// - Varian yang habis ditampilkan abu-abu dan tidak dapat dipilih
///
/// Saat varian dipilih, [onVariantSelected] dipanggil dan dialog ditutup.
class VariantSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic> selectedVariant) onVariantSelected;

  const VariantSelectionDialog({
    super.key,
    required this.product,
    required this.onVariantSelected,
  });

  @override
  State<VariantSelectionDialog> createState() => _VariantSelectionDialogState();
}

class _VariantSelectionDialogState extends State<VariantSelectionDialog> {
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  Map<String, dynamic>? _selectedVariant;

  @override
  Widget build(BuildContext context) {
    final productName = widget.product['name']?.toString() ?? '';
    final variants = (widget.product['variants'] as List?) ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Varian Seçin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Variants Grid
            if (variants.isEmpty)
              Center(
                child: Text(
                  'Varian bulunamadı',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 140,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: variants.length,
                    itemBuilder: (context, index) {
                      final variant = variants[index] as Map<String, dynamic>;
                      return _buildVariantCard(variant);
                    },
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.outline(
                  text: 'İptal',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                AppButton.primary(
                  text: 'Seçimi Onayla',
                  onPressed: _selectedVariant != null
                      ? () {
                          widget.onVariantSelected(_selectedVariant!);
                          Navigator.pop(context);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantCard(Map<String, dynamic> variant) {
    // Kendi mağaza stoğu — PosNotifier tarafından normalize edilmişse myStoreStock kullan,
    // yoksa inventory.physicalQuantity veya variant.stock'a düş
    final inv = variant['inventory'] as Map<String, dynamic>?;
    final totalStock = inv != null
        ? (inv['physicalQuantity'] as num?)?.toInt() ?? 0
        : (variant['stock'] as num?)?.toInt() ?? 0;
    final myStoreStock = (variant['myStoreStock'] as num?)?.toInt() ?? totalStock;
    final availableElsewhere = variant['availableElsewhere'] == true;

    final isOutOfStock   = myStoreStock <= 0 && !availableElsewhere;
    final isTransferOnly = myStoreStock <= 0 && availableElsewhere;

    final isSelected = _selectedVariant != null &&
        _selectedVariant!['id'] == variant['id'];

    final price = (variant['sellingPrice'] as num?)?.toDouble() ??
        (variant['basePrice'] as num?)?.toDouble() ??
        (variant['price'] as num?)?.toDouble() ??
        0.0;

    // Build attribute string (e.g., "Ön Aks", "Kırmızı L")
    final attributes = _buildAttributeString(variant);

    // Transferde varyantlar seçilebilir — addToCart crossLocationAlert tetikler
    final canTap = !isOutOfStock;

    return GestureDetector(
      onTap: canTap ? () => setState(() => _selectedVariant = variant) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isOutOfStock
              ? AppColors.bgLight.withValues(alpha: 0.5)
              : isTransferOnly
                  ? AppColors.bgWarning.withValues(alpha: 0.3)
                  : isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isTransferOnly
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canTap ? () => setState(() => _selectedVariant = variant) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attributes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (attributes.isNotEmpty)
                          Text(
                            attributes,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOutOfStock
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Text(
                    _currencyFormat.format(price),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOutOfStock
                          ? AppColors.textMuted
                          : isTransferOnly
                              ? AppColors.warning
                              : AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Stock Badge
                  _buildStockBadge(myStoreStock, isOutOfStock, isTransferOnly: isTransferOnly),

                  // Selection Indicator
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock, bool isOutOfStock, {bool isTransferOnly = false}) {
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
      label = '$stock Kalan';
    } else {
      bgColor = AppColors.bgSuccess;
      textColor = AppColors.success;
      label = '$stock Adet';
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
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _buildAttributeString(Map<String, dynamic> variant) {
    final attributes = <String>[];

    // Common variant attribute fields
    final attrFields = ['color', 'size', 'material', 'sku', 'type'];
    for (var field in attrFields) {
      if (variant.containsKey(field) && variant[field] != null) {
        final value = variant[field].toString().trim();
        if (value.isNotEmpty) {
          attributes.add(value);
        }
      }
    }

    // If no standard attributes found, try generic 'attributes' field
    if (attributes.isEmpty && variant.containsKey('attributes')) {
      final attrs = variant['attributes'];
      if (attrs is Map) {
        attrs.forEach((key, value) {
          if (value != null) {
            attributes.add('$key: $value');
          }
        });
      } else if (attrs is String && attrs.isNotEmpty) {
        attributes.add(attrs);
      }
    }

    return attributes.join(' • ');
  }
}
