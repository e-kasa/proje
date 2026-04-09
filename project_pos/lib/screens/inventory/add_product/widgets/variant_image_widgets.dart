import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../models/wizard_state.dart';

/// Add image button (dashed border).
Widget buildAddImageButton(VoidCallback onTap, {required bool isMobile, required String Function(String) t}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withOpacity(0.05),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, color: AppColors.primary, size: isMobile ? 24 : 32),
          const SizedBox(height: 4),
          Text(
            t('common.add'),
            style: TextStyle(color: AppColors.primary, fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

/// Image preview tile with remove button.
Widget buildImagePreview(String imagePath, VoidCallback onRemove) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
      color: Colors.grey[100],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Icon(Icons.image, size: 40, color: AppColors.textMuted.withOpacity(0.5)),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Color grouped view for variant images.
class ColorGroupedView extends ConsumerWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const ColorGroupedView({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final colorGroups = state.groupVariantsByColor();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: colorGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final color = colorGroups.keys.elementAt(index);
        final variantIndices = colorGroups[color]!;
        return _buildColorGroup(context, color, variantIndices, t);
      },
    );
  }

  Widget _buildColorGroup(BuildContext context, String color, List<int> variantIndices, String Function(String) t) {
    final firstVariant = state.variants[variantIndices.first];
    final groupImages = firstVariant.images;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.primary.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: state.groupingAttribute == 'Renk' ? state.getColorForAttribute(color) : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(
                    color: (state.groupingAttribute == 'Renk' ? state.getColorForAttribute(color) : AppColors.primary).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )],
                ),
                child: Icon(state.getIconForAttribute(state.groupingAttribute), color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(color, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '${variantIndices.length} ${t('product.variant')} (${groupImages.length} ${t('product.image')})',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _applyImagesToColorGroup(context, color, variantIndices, t),
                icon: const Icon(Icons.sync, size: 16),
                label: Text(
                  isMobile ? t('common.apply') : t('product.apply_to_all'),
                  style: const TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Images
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 4 : 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: groupImages.length + 1,
            itemBuilder: (context, imgIndex) {
              if (imgIndex == groupImages.length) {
                return buildAddImageButton(
                  () => _addColorGroupImage(context, color, variantIndices, t),
                  isMobile: isMobile,
                  t: t,
                );
              }
              return buildImagePreview(
                groupImages[imgIndex],
                () => _removeColorGroupImage(context, color, variantIndices, imgIndex, t),
              );
            },
          ),
          const SizedBox(height: 12),

          // Variant chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: variantIndices.map((variantIndex) {
              final variant = state.variants[variantIndex];
              final size = variant.attributes['Beden'] ?? variant.attributes['Size'] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                ),
                child: Text(
                  size.isNotEmpty ? size : variant.sku,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _addColorGroupImage(BuildContext context, String color, List<int> variantIndices, String Function(String) t) {
    final newImage = 'color_${color}_image_${state.variants[variantIndices.first].images.length + 1}.jpg';
    for (final index in variantIndices) {
      state.variants[index].images = [...state.variants[index].images, newImage];
    }
    onChanged();
    AppToast.success(context, '$color - ${t('product.image_added_to_all')} (${variantIndices.length} ${t('product.variant')})');
  }

  void _removeColorGroupImage(BuildContext context, String color, List<int> variantIndices, int imageIndex, String Function(String) t) {
    for (final index in variantIndices) {
      final images = List<String>.from(state.variants[index].images);
      if (images.length > imageIndex) {
        images.removeAt(imageIndex);
        state.variants[index].images = images;
      }
    }
    onChanged();
    AppToast.success(context, '$color - ${t('product.image_removed_from_all')}');
  }

  void _applyImagesToColorGroup(BuildContext context, String color, List<int> variantIndices, String Function(String) t) {
    if (variantIndices.isEmpty) return;
    final firstVariantImages = state.variants[variantIndices.first].images;
    for (final index in variantIndices) {
      state.variants[index].images = List<String>.from(firstVariantImages);
    }
    onChanged();
    AppToast.success(context, '$color - ${t('product.images_copied_to_sizes')} (${variantIndices.length})');
  }
}

/// Variant image accordion (expansion tile).
class VariantImageAccordion extends ConsumerWidget {
  final WizardState state;
  final ProductVariant variant;
  final int variantIndex;
  final VoidCallback onChanged;
  final bool isMobile;

  const VariantImageAccordion({
    super.key,
    required this.state,
    required this.variant,
    required this.variantIndex,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final isExpanded = state.expandedVariants.contains(variantIndex);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
        color: isExpanded ? Colors.white : Colors.grey[50],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            if (expanded) {
              state.expandedVariants.add(variantIndex);
            } else {
              state.expandedVariants.remove(variantIndex);
            }
            onChanged();
          },
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: variant.images.isEmpty ? AppColors.textMuted.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              variant.images.isEmpty ? Icons.image_not_supported : Icons.image,
              color: variant.images.isEmpty ? AppColors.textMuted : AppColors.success,
              size: 20,
            ),
          ),
          title: Text(variant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(variant.sku, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: variant.images.isEmpty ? AppColors.textMuted.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 12,
                      color: variant.images.isEmpty ? AppColors.textMuted : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${variant.images.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: variant.images.isEmpty ? AppColors.textMuted : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textMuted,
              ),
            ],
          ),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 4 : 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: variant.images.length + 1,
              itemBuilder: (context, imageIndex) {
                if (imageIndex == variant.images.length) {
                  return buildAddImageButton(() => _addVariantImage(context, t), isMobile: isMobile, t: t);
                }
                return buildImagePreview(variant.images[imageIndex], () => _removeVariantImage(context, imageIndex, t));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addVariantImage(BuildContext context, String Function(String) t) {
    state.variants[variantIndex].images = [
      ...state.variants[variantIndex].images,
      'variant_${variantIndex}_image_${state.variants[variantIndex].images.length + 1}.jpg',
    ];
    onChanged();
    AppToast.success(context, t('product.variant_image_added'));
  }

  void _removeVariantImage(BuildContext context, int imageIndex, String Function(String) t) {
    final images = List<String>.from(state.variants[variantIndex].images);
    images.removeAt(imageIndex);
    state.variants[variantIndex].images = images;
    onChanged();
    AppToast.success(context, t('product.variant_image_removed'));
  }
}
