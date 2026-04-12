import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../providers/pos_provider.dart';

/// Ürün Önerme Paneli
///
/// POS satış ekranında kasiyere akıllı ürün önerileri sunar:
/// - Satış verisi tabanlı (Frequently Bought Together)
/// - Manuel ilişkiler tabanlı (Benzer/Alternatif ürünler)
/// - Çapraz referans tabanlı (OEM eşleşmeleri)
///
/// Her kart: ürün adı, SKU, satış fiyatı, kâr bilgisi, stok durumu + sepete ekle
class RecommendationPanel extends ConsumerWidget {
  const RecommendationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    final posNotifier = ref.read(posProvider.notifier);
    final t = i18nOf(ref);

    if (posState.recommendations.isEmpty && !posState.isLoadingRecommendations) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgInfo.withValues(alpha: 0.08),
          border: Border(
            top: BorderSide(color: AppColors.info.withValues(alpha: 0.3), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  t('pos.recommended_products'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.info),
                ),
                const SizedBox(width: 4),
                if (posState.recommendations.isNotEmpty)
                  Text(
                    '(${posState.recommendations.length})',
                    style: TextStyle(fontSize: 11, color: AppColors.info.withValues(alpha: 0.6)),
                  ),
                if (posState.isLoadingRecommendations) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.info),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Önerilen ürünler (yatay scroll)
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: posState.recommendations.length,
                itemBuilder: (ctx, idx) {
                  final rec = posState.recommendations[idx];
                  final stockVal = (rec['stock'] as num?)?.toInt() ?? 0;
                  final isOutOfStock = rec['stockStatus'] == 'OUT_OF_STOCK' || stockVal <= 0;
                  return _RecommendationCard(
                    recommendation: rec,
                    addLabel: t('pos.add_to_cart'),
                    isOutOfStock: isOutOfStock,
                    onAddToCart: isOutOfStock ? null : () {
                      final recForCart = <String, dynamic>{
                        ...rec,
                        'myStoreStock': stockVal,
                        'variantId': rec['variantId'] ?? rec['id'],
                      };
                      posNotifier.addToCart(recForCart);
                      // Eklendi feedback
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${rec['name'] ?? 'Ürün'} sepete eklendi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek bir önerilen ürün kartı — kâr bilgisi, stok durumu, sepete ekleme butonu
class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> recommendation;
  final String addLabel;
  final VoidCallback? onAddToCart;
  final bool isOutOfStock;

  const _RecommendationCard({
    required this.recommendation,
    required this.addLabel,
    required this.onAddToCart,
    this.isOutOfStock = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = recommendation['name'] as String? ?? 'Ürün';
    final sku = recommendation['sku'] as String? ?? '';
    final price = (recommendation['basePrice'] as num?)?.toDouble() ?? 0;
    final costPrice = (recommendation['costPrice'] as num?)?.toDouble();
    final stock = (recommendation['stock'] as num?)?.toInt();
    final stockStatus = recommendation['stockStatus'] as String? ?? '';
    final recommendationType = recommendation['recommendationType'] as String? ?? '';
    final reason = recommendation['reason'] as String? ?? '';

    // Kâr hesaplama
    final hasProfit = costPrice != null && costPrice > 0 && price > 0;
    final profit = hasProfit ? price - costPrice : 0.0;
    final profitMargin = hasProfit ? (profit / price * 100) : 0.0;

    // Önerme tipine göre badge
    final badge = _badgeConfig(recommendationType);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onAddToCart,
        child: Opacity(
          opacity: isOutOfStock ? 0.55 : 1.0,
          child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: isOutOfStock ? AppColors.border : (badge.color).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // Badge (Önerme tipi)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(9),
                    topRight: Radius.circular(9),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(badge.icon, size: 11, color: badge.color),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        reason.isNotEmpty ? reason : recommendationType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: badge.color),
                      ),
                    ),
                  ],
                ),
              ),

              // Ürün bilgileri
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ad
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),

                      // SKU + Stok durumu
                      Row(
                        children: [
                          if (sku.isNotEmpty)
                            Expanded(
                              child: Text(
                                sku,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                              ),
                            ),
                          if (stock != null) ...[
                            const SizedBox(width: 4),
                            _StockBadge(stock: stock, status: stockStatus),
                          ],
                        ],
                      ),

                      const Spacer(),

                      // Fiyat satırı
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Satış fiyatı
                          Text(
                            '₺${price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          const Spacer(),
                          // Kâr bilgisi
                          if (hasProfit)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: profit > 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '%${profitMargin.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: profit > 0 ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Maliyet satırı (küçük, muted)
                      if (hasProfit)
                        Row(
                          children: [
                            Text(
                              'Maliyet: ₺${costPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                            ),
                            const Spacer(),
                            Text(
                              'Kâr: ₺${profit.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: profit > 0 ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Sepete Ekle / Stokta Yok Butonu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isOutOfStock ? AppColors.border.withValues(alpha: 0.5) : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(9),
                    bottomRight: Radius.circular(9),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOutOfStock ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                      size: 13,
                      color: isOutOfStock ? AppColors.textMuted : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOutOfStock ? 'Stokta Yok' : addLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock ? AppColors.textMuted : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  _BadgeConfig _badgeConfig(String type) {
    if (type.contains('CROSS_REFERENCE')) {
      return _BadgeConfig(const Color(0xFFE74C3C), Icons.swap_calls);
    } else if (type.contains('SIMILAR')) {
      return _BadgeConfig(const Color(0xFF6C63FF), Icons.check_circle_outline);
    } else if (type.contains('ALTERNATIVE')) {
      return _BadgeConfig(const Color(0xFFFF9F43), Icons.swap_horiz);
    } else if (type.contains('COMPLEMENTARY')) {
      return _BadgeConfig(const Color(0xFF00D2D3), Icons.extension);
    } else if (type.contains('FREQUENTLY')) {
      return _BadgeConfig(AppColors.success, Icons.trending_up);
    }
    return _BadgeConfig(AppColors.info, Icons.trending_up);
  }
}

/// Badge config helper
class _BadgeConfig {
  final Color color;
  final IconData icon;
  const _BadgeConfig(this.color, this.icon);
}

/// Mini stok durumu badge'i
class _StockBadge extends StatelessWidget {
  final int stock;
  final String status;

  const _StockBadge({required this.stock, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;

    if (status == 'OUT_OF_STOCK' || stock <= 0) {
      bgColor = AppColors.danger.withValues(alpha: 0.1);
      textColor = AppColors.danger;
    } else if (status == 'LOW_STOCK' || stock <= 5) {
      bgColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
    } else {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$stock',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}