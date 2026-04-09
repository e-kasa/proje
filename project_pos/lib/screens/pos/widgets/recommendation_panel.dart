import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../providers/pos_provider.dart';

/// Ürün Önerme Paneli
///
/// POS satış ekranında kasiyere akıllı ürün önerileri sunar:
/// - Satış verisi tabanlı (Frequently Bought Together)
/// - Manuel ilişkiler tabanlı (Benzer/Alternatif ürünler)
///
/// Yatay kaydırılabilir kartlar şeklinde gösterilir
class RecommendationPanel extends ConsumerWidget {
  const RecommendationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    final posNotifier = ref.read(posProvider.notifier);
    final t = i18nOf(ref);

    // Önerilecek ürün yoksa gösterme
    if (posState.recommendations.isEmpty && !posState.isLoadingRecommendations) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgInfo.withOpacity(0.08),
          border: Border(
            top: BorderSide(color: AppColors.info.withOpacity(0.3), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Text(
                  t('pos.recommended_products'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 4),
                if (posState.recommendations.isNotEmpty)
                  Text(
                    '(${posState.recommendations.length})',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info.withOpacity(0.6),
                    ),
                  ),
                if (posState.isLoadingRecommendations) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.info),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Önerilen ürünler (yatay scroll) — loading sırasında da mevcut listeyi göster
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: posState.recommendations.length,
                itemBuilder: (ctx, idx) {
                  final rec = posState.recommendations[idx];
                  return _RecommendationCard(
                    recommendation: rec,
                    addLabel: t('pos.add_to_cart'),
                    onAddToCart: () {
                      posNotifier.addToCart(rec);
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

/// Tek bir önerilen ürün kartı
class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> recommendation;
  final String addLabel;
  final VoidCallback onAddToCart;

  const _RecommendationCard({
    required this.recommendation,
    required this.addLabel,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final name = recommendation['name'] as String? ?? 'Ürün';
    final sku = recommendation['sku'] as String? ?? '';
    final price = recommendation['basePrice'] as num? ?? 0;
    final recommendationType = recommendation['recommendationType'] as String? ?? '';
    final reason = recommendation['reason'] as String? ?? '';

    // Önerme tipine göre badge rengi
    Color badgeColor = AppColors.info;
    IconData badgeIcon = Icons.trending_up;

    if (recommendationType.contains('SIMILAR')) {
      badgeColor = const Color(0xFF6C63FF); // Mor
      badgeIcon = Icons.check_circle_outline;
    } else if (recommendationType.contains('ALTERNATIVE')) {
      badgeColor = const Color(0xFFFF9F43); // Turuncu
      badgeIcon = Icons.swap_horiz;
    } else if (recommendationType.contains('COMPLEMENTARY')) {
      badgeColor = const Color(0xFF00D2D3); // Turkuaz
      badgeIcon = Icons.extension;
    } else if (recommendationType.contains('FREQUENTLY')) {
      badgeColor = AppColors.success;
      badgeIcon = Icons.trending_up;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onAddToCart,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: badgeColor.withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Badge (Önerme tipi)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 12, color: badgeColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          reason.isNotEmpty ? reason : recommendationType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Ürün bilgileri
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Adı
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        // SKU
                        if (sku.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              sku,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Fiyat
                        Text(
                          '₺${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Ekle Butonu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 14,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        addLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
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
}
