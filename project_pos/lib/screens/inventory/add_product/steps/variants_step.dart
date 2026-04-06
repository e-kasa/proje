import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../widgets/variant_dialogs.dart';
import '../../core/widgets/widgets.dart';

class VariantsStep extends StatelessWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const VariantsStep({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.layers, color: Colors.white, size: isMobile ? 20 : 22),
                SizedBox(width: isMobile ? 8 : 10),
                Text(
                  '\u00dcr\u00fcn Tipi & Varyantlar',
                  style: TextStyle(color: Colors.white, fontSize: isMobile ? 15 : 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u00dcr\u00fcn Tipi Se\u00e7imi', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'Basit \u00dcr\u00fcn: Varyant olmadan tek bir \u00fcr\u00fcn (\u00d6rn: USB Kablo)\nVaryantl\u0131 \u00dcr\u00fcn: Farkl\u0131 renk, beden, \u00f6zelliklere sahip (\u00d6rn: Ti\u015f\u00f6rt - S/M/L)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSimpleTypeCard(context)),
              const SizedBox(width: 12),
              Expanded(child: _buildVariantTypeCard(context)),
            ],
          ),

          if (state.productType == 'simple') ...[
            const SizedBox(height: 24),
            _buildSimpleConfirmation(),
          ],

          if (state.productType == 'variant') ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildPresetSection(context),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildAttributesSection(context),
            if (state.attributes.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildGenerateButton(context),
            ],
            if (state.variants.isNotEmpty && state.variants.first.attributes.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildVariantPreview(context),
            ],
          ],
        ],
      ),
    );
  }
  Widget _buildSimpleTypeCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        state.productType = 'simple';
        state.generateVariants(context);
        onChanged();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: state.productType == 'simple' ? AppColors.success.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: state.productType == 'simple' ? AppColors.success : AppColors.border,
            width: state.productType == 'simple' ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2, size: 48, color: state.productType == 'simple' ? AppColors.success : AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Basit \u00dcr\u00fcn', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Varyant yok', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (state.productType == 'simple') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(12)),
                child: const Text('Se\u00e7ili', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildVariantTypeCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        state.productType = 'variant';
        onChanged();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: state.productType == 'variant' ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: state.productType == 'variant' ? AppColors.primary : AppColors.border,
            width: state.productType == 'variant' ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.layers, size: 48, color: state.productType == 'variant' ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Varyantl\u0131 \u00dcr\u00fcn', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Renk, beden vb.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (state.productType == 'variant') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Text('Se\u00e7ili', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildSimpleConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('\u2713 Basit \u00dcr\u00fcn Otomatik Olu\u015fturuldu', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${state.variants.isNotEmpty ? state.variants[0].sku : "-"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPresetSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('\ud83d\udce6 H\u0131zl\u0131 \u015eablon Se\u00e7 (\u0130ste\u011fe Ba\u011fl\u0131)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetButton(context, 'clothing', '\ud83d\udc55 Giyim', Icons.checkroom),
            _buildPresetButton(context, 'electronics', '\ud83d\udcbb Elektronik', Icons.computer),
            _buildPresetButton(context, 'shoes', '\ud83d\udc5f Ayakkab\u0131', Icons.shopping_bag),
            _buildPresetButton(context, 'custom', '\u2795 \u00d6zel', Icons.add_circle_outline),
          ],
        ),
      ],
    );
  }
  Widget _buildPresetButton(BuildContext context, String key, String label, IconData icon) {
    final isSelected = state.selectedPreset == key;
    return GestureDetector(
      onTap: () {
        if (key == 'custom') {
          state.selectedPreset = 'custom';
          state.attributes = [];
        } else {
          state.applyPreset(key);
        }
        onChanged();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildAttributesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('\u00dcr\u00fcn \u00d6zellikleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => showAddAttributeDialog(context: context, state: state, onChanged: onChanged),
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('Yeni \u00d6zellik'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (state.attributes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3), style: BorderStyle.solid),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yukar\u0131dan h\u0131zl\u0131 \u015fablon se\u00e7in veya "Yeni \u00d6zellik" ile \u00f6zel \u00f6zellik ekleyin',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...state.attributes.asMap().entries.map((entry) {
            return _buildAttributeCard(context, entry.key, entry.value);
          }),
      ],
    );
  }
  Widget _buildAttributeCard(BuildContext context, int index, ProductAttribute attr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(attr.icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(attr.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              IconButton(
                onPressed: () {
                  state.removeAttribute(index);
                  onChanged();
                },
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.danger,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...attr.values.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    state.removeValueFromAttribute(index, entry.key);
                    onChanged();
                  },
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  deleteIconColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }),
              ActionChip(
                label: const Text('+ Ekle', style: TextStyle(fontSize: 12)),
                onPressed: () => showAddValueDialog(context: context, state: state, attrIndex: index, attrName: attr.name, onChanged: onChanged),
                backgroundColor: AppColors.success.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.success.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildGenerateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final ok = state.generateVariants(context);
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('\u26a0\ufe0f En az bir \u00f6zellik ve de\u011fer ekleyin'), backgroundColor: AppColors.warning),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('\u2713 ${state.variants.length} varyant olu\u015fturuldu!'), backgroundColor: AppColors.success),
            );
            onChanged();
          }
        },
        icon: const Icon(Icons.bolt),
        label: Text('Varyantlar\u0131 Olu\u015ftur (${state.calculateTotalVariants()} varyant)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
  Widget _buildVariantPreview(BuildContext context) {
    final displayLimit = state.showAllVariants ? state.variants.length : 5;
    final displayedVariants = state.variants.take(displayLimit).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('\ud83d\udcca Varyant \u00d6nizleme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${state.variants.length} Varyant',
                    style: const TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedVariants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final variant = displayedVariants[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                title: Text(variant.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('SKU: ${variant.sku}', style: const TextStyle(fontSize: 11)),
                trailing: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: variant.attributes.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          if (state.variants.length > 5)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: TextButton.icon(
                onPressed: () {
                  state.showAllVariants = !state.showAllVariants;
                  onChanged();
                },
                icon: Icon(state.showAllVariants ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(
                  state.showAllVariants ? 'Daha Az G\u00f6ster' : 'T\u00fcm\u00fcn\u00fc G\u00f6ster (+${state.variants.length - 5} varyant)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
