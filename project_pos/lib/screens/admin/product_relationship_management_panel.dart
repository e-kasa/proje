import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/i18n_helper.dart';
import '../../core/widgets/widgets.dart';
import '../../services/recommendation_service.dart';
import '../../services/product_service.dart';
import '../../services/service_locator.dart';

/// Admin: Ürün İlişkileri Yönetim Paneli
///
/// Ürün detay sayfasında gösterilen benzer/alternatif/tamamlayıcı ürünleri yönetir
/// - Benzer ürün ekle
/// - Alternatif ürün ekle
/// - Tamamlayıcı ürün ekle
/// - Ağırlık (priority) ayarla
/// - İlişkiyi sil
class ProductRelationshipManagementPanel extends ConsumerStatefulWidget {
  final String productId;
  final String productName;

  const ProductRelationshipManagementPanel({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  ConsumerState<ProductRelationshipManagementPanel> createState() =>
      _ProductRelationshipManagementPanelState();
}

class _ProductRelationshipManagementPanelState
    extends ConsumerState<ProductRelationshipManagementPanel> {
  late List<Map<String, dynamic>> relationships = [];
  bool isLoading = false;
  String? selectedRelationType = 'SIMILAR';

  @override
  void initState() {
    super.initState();
    _loadRelationships();
  }

  Future<void> _loadRelationships() async {
    setState(() => isLoading = true);
    try {
      final recs = await ref
          .read(recommendationServiceProvider)
          .getRelationships(sourceProductId: widget.productId);
      setState(() {
        relationships = recs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        AppToast.error(context, 'İlişkiler yüklenemedi: $e');
      }
    }
  }

  Future<void> _showAddRelationshipDialog() async {
    final productService = ref.read(productServiceProvider);
    final recommendationService = ref.read(recommendationServiceProvider);

    String? selectedProductId;
    String relationType = 'SIMILAR';
    int weight = 5;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Benzer Ürün Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İlişki Tipi
              const Text('İlişki Tipi:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: relationType,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'SIMILAR',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: const Color(0xFF6C63FF)),
                        const SizedBox(width: 8),
                        const Text('Benzer Ürün'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ALTERNATIVE',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz,
                            size: 16, color: const Color(0xFFFF9F43)),
                        const SizedBox(width: 8),
                        const Text('Alternatif'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'COMPLEMENTARY',
                    child: Row(
                      children: [
                        Icon(Icons.extension,
                            size: 16, color: const Color(0xFF00D2D3)),
                        const SizedBox(width: 8),
                        const Text('Tamamlayıcı'),
                      ],
                    ),
                  ),
                ].toList(),
                onChanged: (val) {
                  if (val != null) setState(() => relationType = val);
                },
              ),
              const SizedBox(height: 20),

              // Ürün Seçimi
              const Text('Ürün Seç:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: productService.getProducts(size: 100),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Ürün bulunamadı');
                  }

                  final products = snapshot.data!
                      .where((p) => p['id'] != widget.productId)
                      .toList();

                  return DropdownButton<String>(
                    value: selectedProductId,
                    isExpanded: true,
                    hint: const Text('Ürün seçiniz'),
                    items: products
                        .map((p) => DropdownMenuItem<String>(
                              value: p['id'].toString(),
                              child: Text(
                                p['name'].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedProductId = val);
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // Ağırlık (Priority)
              const Text('Öncelik (1-10):', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: weight.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: weight.toString(),
                      onChanged: (val) {
                        setState(() => weight = val.toInt());
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        weight.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: selectedProductId == null
                  ? null
                  : () async {
                      try {
                        await recommendationService.createRelationship(
                          sourceProductId: widget.productId,
                          targetProductId: selectedProductId!,
                          relationType: relationType,
                          weight: weight,
                        );
                        Navigator.pop(ctx);
                        _loadRelationships();
                        if (mounted) {
                          AppToast.success(context, 'İlişki başarıyla eklendi');
                        }
                      } catch (e) {
                        if (mounted) {
                          AppToast.error(context, 'Hata: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRelationship(
      String relationshipId, String targetProductName) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sil'),
            content: Text(
              '"$targetProductName" ile ilişkiyi silmek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                child: const Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ref.read(recommendationServiceProvider).deleteRelationship(relationshipId);
      _loadRelationships();
      if (mounted) {
        AppToast.success(context, 'İlişki silindi');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Silinirken hata: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Benzer/İlişkili Ürünler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.productName} için ${relationships.length} ilişki',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddRelationshipDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // İçerik
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else if (relationships.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.link_off, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz ilişki eklenmemiş',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: relationships.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.border,
              ),
              itemBuilder: (ctx, idx) {
                final rel = relationships[idx];
                final type = rel['relationType'] as String? ?? 'SIMILAR';
                final weight = rel['weight'] as int? ?? 5;
                final targetId = rel['targetProductId'] as String? ?? '';

                Color typeColor = AppColors.info;
                IconData typeIcon = Icons.link;

                if (type == 'SIMILAR') {
                  typeColor = const Color(0xFF6C63FF);
                  typeIcon = Icons.check_circle_outline;
                } else if (type == 'ALTERNATIVE') {
                  typeColor = const Color(0xFFFF9F43);
                  typeIcon = Icons.swap_horiz;
                } else if (type == 'COMPLEMENTARY') {
                  typeColor = const Color(0xFF00D2D3);
                  typeIcon = Icons.extension;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(typeIcon, size: 20, color: typeColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              type,
                              style: TextStyle(
                                fontSize: 11,
                                color: typeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ağırlık göstergesi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Ağırlık: $weight',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sil butonu
                      IconButton(
                        onPressed: () => _deleteRelationship(rel['id'] as String? ?? '', targetId),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.danger,
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
