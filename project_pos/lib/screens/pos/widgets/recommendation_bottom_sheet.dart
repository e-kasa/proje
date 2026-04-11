import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import '../providers/pos_provider.dart';

/// Kasiyer dostu öneri popup'ı.
/// CartItemRow'daki 💡 ikona basınca açılır.
void showRecommendationBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RecommendationSheet(),
  );
}

class _RecommendationSheet extends ConsumerWidget {
  const _RecommendationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final recs = posState.recommendations;
    final isLoading = posState.isLoadingRecommendations;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.68,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Başlık ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: AppColors.info, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Müşteriye Öner',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        isLoading
                            ? 'Öneriler yükleniyor…'
                            : recs.isEmpty
                                ? 'Öneri bulunamadı'
                                : '${recs.length} ürün önerisi',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                // Hepsini ekle butonu
                if (recs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      int added = 0;
                      for (final r in recs) {
                        final alreadyInCart = posState.cartItems.any((ci) => ci.variantId == r['variantId']);
                        if (!alreadyInCart) {
                          notifier.addToCart(r);
                          added++;
                        }
                      }
                      Navigator.pop(context);
                      if (added > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$added ürün sepete eklendi'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Tümünü Ekle'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.success),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── İçerik ───────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Öneriler hazırlanıyor…', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : recs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 48, color: AppColors.border),
                            SizedBox(height: 12),
                            Text(
                              'Sepete ürün ekleyin,\nakıllı öneriler burada görünür',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: recs.length,
                        itemBuilder: (ctx, i) {
                          final rec = recs[i];
                          final alreadyInCart = posState.cartItems.any((ci) => ci.variantId == rec['variantId']);
                          return _RecCard(
                            rec: rec,
                            alreadyInCart: alreadyInCart,
                            onAdd: () {
                              if (!alreadyInCart) {
                                notifier.addToCart(rec);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${rec['name'] ?? 'Ürün'} sepete eklendi',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Tek öneri kartı — 2 sütunlu grid için optimize edilmiş
class _RecCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  final bool alreadyInCart;
  final VoidCallback onAdd;

  const _RecCard({required this.rec, required this.alreadyInCart, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final name = rec['name'] as String? ?? 'Ürün';
    final sku = rec['sku'] as String? ?? '';
    final price = (rec['basePrice'] as num?)?.toDouble() ?? 0;
    final costPrice = (rec['costPrice'] as num?)?.toDouble();
    final stock = (rec['stock'] as num?)?.toInt();
    final stockStatus = rec['stockStatus'] as String? ?? '';
    final type = rec['recommendationType'] as String? ?? '';
    final reason = rec['reason'] as String? ?? '';

    final hasProfit = costPrice != null && costPrice > 0 && price > 0;
    final profit = hasProfit ? price - costPrice : 0.0;
    final margin = hasProfit ? (profit / price * 100) : 0.0;

    final badge = _badgeFor(type);

    return GestureDetector(
      onTap: alreadyInCart ? null : onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: alreadyInCart ? AppColors.bgLight : Colors.white,
          border: Border.all(
            color: alreadyInCart ? AppColors.border : badge.color.withValues(alpha: 0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: alreadyInCart
              ? []
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tür badge'i ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Icon(badge.icon, size: 11, color: badge.color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reason.isNotEmpty ? reason : badge.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badge.color),
                    ),
                  ),
                ],
              ),
            ),

            // ── Ürün bilgileri ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: alreadyInCart ? AppColors.textMuted : AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // SKU + Stok
                    Row(
                      children: [
                        if (sku.isNotEmpty)
                          Expanded(
                            child: Text(
                              sku,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ),
                        if (stock != null) _StockChip(stock: stock, status: stockStatus),
                      ],
                    ),

                    const Spacer(),

                    // Fiyat
                    Text(
                      '₺${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: alreadyInCart ? AppColors.textMuted : AppColors.primary,
                      ),
                    ),

                    // Kâr bilgisi
                    if (hasProfit)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Maliyet: ₺${costPrice!.toStringAsFixed(2)}',
                              maxLines: 1,
                              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: profit >= 0 ? AppColors.bgSuccess : AppColors.bgDanger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '%${margin.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: profit >= 0 ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),

            // ── Sepete Ekle butonu ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: alreadyInCart
                    ? AppColors.border.withValues(alpha: 0.3)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    alreadyInCart ? Icons.check_circle_outline : Icons.add_shopping_cart,
                    size: 14,
                    color: alreadyInCart ? AppColors.textMuted : AppColors.success,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    alreadyInCart ? 'Sepette' : 'Sepete Ekle',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: alreadyInCart ? AppColors.textMuted : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _Badge _badgeFor(String type) {
    if (type.contains('CROSS_REFERENCE')) return const _Badge(Color(0xFFE74C3C), Icons.swap_calls, 'Çapraz Ref.');
    if (type.contains('SIMILAR'))         return const _Badge(Color(0xFF6C63FF), Icons.check_circle_outline, 'Benzer');
    if (type.contains('ALTERNATIVE'))     return const _Badge(Color(0xFFFF9F43), Icons.swap_horiz, 'Alternatif');
    if (type.contains('COMPLEMENTARY'))   return const _Badge(Color(0xFF00D2D3), Icons.extension, 'Tamamlayıcı');
    if (type.contains('FREQUENTLY'))      return const _Badge(AppColors.success, Icons.trending_up, 'Birlikte Alınan');
    return const _Badge(AppColors.info, Icons.lightbulb_outline, 'Öneri');
  }
}

class _Badge {
  final Color color;
  final IconData icon;
  final String label;
  const _Badge(this.color, this.icon, this.label);
}

class _StockChip extends StatelessWidget {
  final int stock;
  final String status;
  const _StockChip({required this.stock, required this.status});

  @override
  Widget build(BuildContext context) {
    final isOut = status == 'OUT_OF_STOCK' || stock <= 0;
    final isLow = status == 'LOW_STOCK' || (stock > 0 && stock <= 5);
    final bg    = isOut ? AppColors.bgDanger   : isLow ? AppColors.bgWarning   : AppColors.bgSuccess;
    final fg    = isOut ? AppColors.danger      : isLow ? AppColors.warning      : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        isOut ? 'Yok' : '$stock adet',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}