import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../../../../core/config/sector_config.dart';
import '../models/wizard_state.dart';
import '../widgets/variant_image_widgets.dart';

class ImagesStep extends ConsumerWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const ImagesStep({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  Color get _accentColor => switch (state.sectorType) {
        SectorType.autoParts => AppColors.orange,
        SectorType.footwear => AppColors.pink,
        SectorType.technology => AppColors.info,
        SectorType.general => AppColors.primary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProductImages(context, t),
          const SizedBox(height: 16),
          if (state.variants.isNotEmpty) _buildVariantImages(context, t),
        ],
      ),
    );
  }

  // ─── Product Images ─────────────────────────────────────────────────────────

  Widget _buildProductImages(BuildContext context, String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: Icons.image,
            title: t('product.product_images'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.productImages.length} ${t('common.image')}',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (state.productImages.isEmpty)
            _buildEmptyProductState(context, t)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 3 : 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: state.productImages.length + 1,
              itemBuilder: (context, index) {
                if (index == state.productImages.length) {
                  return buildAddImageButton(() => _addProductImage(context), isMobile: isMobile, t: t);
                }
                return buildImagePreview(state.productImages[index], () => _removeProductImage(context, index));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyProductState(BuildContext context, String Function(String) t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _accentColor.withOpacity(0.25),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        color: _accentColor.withOpacity(0.03),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.add_photo_alternate,
              size: 40,
              color: _accentColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t('product.no_images_yet'),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('product.add_images_hint'),
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => _addProductImage(context),
            icon: Icon(Icons.add, size: 18, color: _accentColor),
            label: Text(
              t('product.add_first_image'),
              style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              backgroundColor: _accentColor.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Variant Images ─────────────────────────────────────────────────────────

  Widget _buildVariantImages(BuildContext context, String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: Icons.collections,
            title: t('product.variant_images'),
            subtitle: t('product.variant_images_hint'),
          ),
          const SizedBox(height: 16),

          // View mode toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    state.colorGroupedView ? Icons.palette : Icons.view_list,
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.colorGroupedView ? t('product.color_grouped_view') : t('product.variant_list'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        state.colorGroupedView ? t('product.colors_grouped') : t('product.all_variants_separate'),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.colorGroupedView,
                  onChanged: (val) {
                    state.colorGroupedView = val;
                    onChanged();
                  },
                  activeColor: AppColors.success,
                ),
              ],
            ),
          ),

          // Grouping attribute selector
          if (state.colorGroupedView && state.getAvailableAttributes().isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accentColor.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 18, color: _accentColor),
                      const SizedBox(width: 8),
                      Text('${t('product.grouping')}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: state.getAvailableAttributes().contains(state.groupingAttribute)
                                ? state.groupingAttribute
                                : (state.getAvailableAttributes().isNotEmpty ? state.getAvailableAttributes().first : null),
                            isDense: true,
                            items: state.getAvailableAttributes().map<DropdownMenuItem<String>>((attr) {
                              return DropdownMenuItem<String>(
                                value: attr,
                                child: Row(
                                  children: [
                                    Icon(state.getIconForAttribute(attr), size: 14, color: _accentColor),
                                    const SizedBox(width: 6),
                                    Text(attr, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              state.groupingAttribute = val ?? (state.getAvailableAttributes().isNotEmpty ? state.getAvailableAttributes().first : 'Renk');
                              onChanged();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Search + stats
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: t('product.search_variant'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: state.variantSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () { state.variantSearchQuery = ''; onChanged(); },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _accentColor, width: 1.5),
                    ),
                    isDense: true,
                  ),
                  onChanged: (val) { state.variantSearchQuery = val; onChanged(); },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.apps, size: 16, color: _accentColor),
                    const SizedBox(width: 6),
                    Text(
                      '${state.getFilteredVariants().length}/${state.variants.length}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _accentColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              _quickActionButton(
                icon: Icons.unfold_more,
                label: t('common.expand_all'),
                onPressed: () {
                  state.expandedVariants.addAll(List.generate(state.variants.length, (i) => i));
                  onChanged();
                },
              ),
              const SizedBox(width: 8),
              _quickActionButton(
                icon: Icons.unfold_less,
                label: t('common.collapse_all'),
                onPressed: () {
                  state.expandedVariants.clear();
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Variant list
          if (state.getFilteredVariants().isEmpty)
            _buildEmptyVariantSearch(t)
          else if (state.colorGroupedView && state.hasColorAttribute())
            ColorGroupedView(state: state, onChanged: onChanged, isMobile: isMobile)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.getFilteredVariants().length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final variantIndex = state.getFilteredVariants()[index];
                final variant = state.variants[variantIndex];
                return VariantImageAccordion(
                  state: state,
                  variant: variant,
                  variantIndex: variantIndex,
                  onChanged: onChanged,
                  isMobile: isMobile,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyVariantSearch(String Function(String) t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textMuted.withOpacity(0.15),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        color: AppColors.bgLight.withOpacity(0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_off,
              size: 36,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('product.variant_not_found'),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: child,
      ),
    );
  }

  Widget _header({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: _accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentColor.withOpacity(0.4), _accentColor.withOpacity(0.0)],
              stops: const [0.0, 1.0],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: _accentColor),
      label: Text(label, style: TextStyle(fontSize: 11, color: _accentColor)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        backgroundColor: _accentColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _addProductImage(BuildContext context) {
    // TODO: Implement real image picker (image_picker package)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gorsel secici yaklasimda...'), backgroundColor: AppColors.info),
    );
  }

  void _removeProductImage(BuildContext context, int index) {
    state.productImages.removeAt(index);
    onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('\ud83d\uddd1\ufe0f G\u00f6rsel kald\u0131r\u0131ld\u0131'), backgroundColor: AppColors.success),
    );
  }
}
