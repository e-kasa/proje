import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../widgets/variant_image_widgets.dart';

class ImagesStep extends StatelessWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const ImagesStep({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProductImages(context),
          const SizedBox(height: 16),
          if (state.variants.isNotEmpty) _buildVariantImages(context),
        ],
      ),
    );
  }

  Widget _buildProductImages(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: isMobile ? 6 : 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.white, size: isMobile ? 20 : 22),
                SizedBox(width: isMobile ? 8 : 10),
                const Expanded(
                  child: Text('\u00dcr\u00fcn G\u00f6rselleri', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text('${state.productImages.length} g\u00f6rsel', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                return buildAddImageButton(() => _addProductImage(context), isMobile: isMobile);
              }
              return buildImagePreview(state.productImages[index], () => _removeProductImage(context, index));
            },
          ),

          if (state.productImages.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate, size: 60, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('Hen\u00fcz g\u00f6rsel eklenmedi', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _addProductImage(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('\u0130lk G\u00f6rseli Ekle'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVariantImages(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: isMobile ? 6 : 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.collections, color: AppColors.info),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Varyant G\u00f6rselleri', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Her varyant i\u00e7in \u00f6zel g\u00f6rseller (iste\u011fe ba\u011fl\u0131)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // View mode toggle
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(state.colorGroupedView ? Icons.palette : Icons.view_list, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.colorGroupedView ? 'Renk Gruplu G\u00f6r\u00fcn\u00fcm' : 'Varyant Listesi',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              state.colorGroupedView ? 'Renkler grupland\u0131r\u0131lm\u0131\u015f' : 'T\u00fcm varyantlar ayr\u0131 ayr\u0131',
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
              ),
            ],
          ),

          // Grouping attribute selector
          if (state.colorGroupedView && state.getAvailableAttributes().isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.info.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list, size: 18, color: AppColors.info),
                            const SizedBox(width: 8),
                            const Text('Grupland\u0131rma:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                                          Icon(state.getIconForAttribute(attr), size: 14, color: AppColors.primary),
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
                    ),
                  ],
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
                    hintText: 'Varyant ara...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: state.variantSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () { state.variantSearchQuery = ''; onChanged(); },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onChanged: (val) { state.variantSearchQuery = val; onChanged(); },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.apps, size: 16, color: AppColors.info),
                    const SizedBox(width: 6),
                    Text(
                      '${state.getFilteredVariants().length}/${state.variants.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.info),
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
              TextButton.icon(
                onPressed: () {
                  state.expandedVariants.addAll(List.generate(state.variants.length, (i) => i));
                  onChanged();
                },
                icon: const Icon(Icons.unfold_more, size: 16),
                label: const Text('T\u00fcm\u00fcn\u00fc A\u00e7', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  state.expandedVariants.clear();
                  onChanged();
                },
                icon: const Icon(Icons.unfold_less, size: 16),
                label: const Text('T\u00fcm\u00fcn\u00fc Kapat', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Variant list
          if (state.getFilteredVariants().isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('Varyant bulunamad\u0131', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            )
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
