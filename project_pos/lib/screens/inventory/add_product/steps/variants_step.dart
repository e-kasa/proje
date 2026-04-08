import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/config/sector_config.dart';
import '../models/wizard_state.dart';
import '../widgets/variant_dialogs.dart';
import 'package:project_pos/core/widgets/widgets.dart';

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

  Color get _accentColor => switch (state.sectorType) {
        SectorType.autoParts => AppColors.orange,
        SectorType.footwear => AppColors.pink,
        SectorType.technology => AppColors.info,
        SectorType.general => AppColors.primary,
      };

  static const _attrColors = [
    Color(0xFF5C6BC0), // indigo
    Color(0xFFEF5350), // red
    Color(0xFF26A69A), // teal
    Color(0xFFFF7043), // deep orange
    Color(0xFF42A5F5), // blue
    Color(0xFFAB47BC), // purple
  ];

  Color _colorForAttrIndex(int index) =>
      _attrColors[index % _attrColors.length];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProductTypeCard(context),
        if (state.productType == 'simple') ...[
          const SizedBox(height: 16),
          _buildSimpleConfirmation(),
        ],
        if (state.productType == 'variant') ...[
          const SizedBox(height: 16),
          _buildPresetSection(context),
          const SizedBox(height: 16),
          _buildAttributesSection(context),
          if (state.attributes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildGenerateButton(context),
          ],
          if (state.variants.isNotEmpty &&
              state.variants.first.attributes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildVariantPreview(context),
          ],
        ],
      ],
    );
  }

  // ─── Product Type Selection ─────────────────────────────────────────────

  Widget _buildProductTypeCard(BuildContext context) {
    final accent = _accentColor;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.layers_rounded, 'Urun Tipi & Varyantlar'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.info.withOpacity(0.7)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Basit: Tek varyant  |  Varyantli: Renk, beden gibi secenekler',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  context,
                  key: 'simple',
                  icon: Icons.inventory_2_rounded,
                  title: 'Basit Urun',
                  subtitle: 'Varyant yok',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption(
                  context,
                  key: 'variant',
                  icon: Icons.layers_rounded,
                  title: 'Varyantli Urun',
                  subtitle: 'Renk, beden vb.',
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    BuildContext context, {
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = state.productType == key;
    return GestureDetector(
      onTap: () {
        state.productType = key;
        if (key == 'simple') state.generateVariants(context);
        onChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 24,
                  color: isSelected ? color : AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10)),
                child: const Text('Secili',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Simple Confirmation ────────────────────────────────────────────────

  Widget _buildSimpleConfirmation() {
    return _card(
      accentBorder: true,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Basit Urun Olusturuldu',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${state.variants.isNotEmpty ? state.variants[0].sku : "-"}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Preset Section ─────────────────────────────────────────────────────

  Widget _buildPresetSection(BuildContext context) {
    final accent = _accentColor;
    final presets = state.getSectorPresets();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.flash_on_rounded, 'Hizli Sablon'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...presets.where((p) => p != 'custom').map((presetKey) {
                final isSelected = state.selectedPreset == presetKey;
                final presetIcon = _presetIcon(presetKey);
                return _buildPresetChip(
                  context,
                  key: presetKey,
                  label: _presetLabel(presetKey),
                  icon: presetIcon,
                  isSelected: isSelected,
                  color: accent,
                );
              }),
              _buildPresetChip(
                context,
                key: 'custom',
                label: 'Ozel',
                icon: Icons.tune_rounded,
                isSelected: state.selectedPreset == 'custom',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _presetLabel(String key) {
    return switch (key) {
      'clothing' => 'Giyim',
      'electronics' => 'Elektronik',
      'shoes' => 'Ayakkabi',
      'auto_parts' => 'Oto Parca',
      _ => key,
    };
  }

  IconData _presetIcon(String key) {
    return switch (key) {
      'clothing' => Icons.checkroom_rounded,
      'electronics' => Icons.devices_rounded,
      'shoes' => Icons.shopping_bag_rounded,
      'autoparts' => Icons.build_circle_rounded,
      _ => Icons.category_rounded,
    };
  }

  Widget _buildPresetChip(
    BuildContext context, {
    required String key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
  }) {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 14, vertical: isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? color : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Attributes Section ─────────────────────────────────────────────────

  Widget _buildAttributesSection(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _header(Icons.tune_rounded, 'Ozellikler'),
              const Spacer(),
              if (state.attributes.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.attributes.length} ozellik',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _accentColor),
                  ),
                ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => showAddAttributeDialog(
                    context: context, state: state, onChanged: onChanged),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('Yeni',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (state.attributes.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Yukaridan sablon secin veya "Yeni" ile ozellik ekleyin',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
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
      ),
    );
  }

  Widget _buildAttributeCard(
      BuildContext context, int index, ProductAttribute attr) {
    final attrColor = _colorForAttrIndex(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(attr.icon, size: 16, color: attrColor),
              const SizedBox(width: 6),
              Text(attr.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: attrColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${attr.values.length} deger',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: attrColor),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  state.removeAttribute(index);
                  onChanged();
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...attr.values.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value,
                      style: TextStyle(
                          fontSize: 11,
                          color: attrColor,
                          fontWeight: FontWeight.w500)),
                  deleteIcon: Icon(Icons.close_rounded,
                      size: 14, color: attrColor.withOpacity(0.6)),
                  onDeleted: () {
                    state.removeValueFromAttribute(index, entry.key);
                    onChanged();
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: attrColor.withOpacity(0.08),
                  side: BorderSide(color: attrColor.withOpacity(0.2)),
                );
              }),
              ActionChip(
                label: const Text('+ Ekle', style: TextStyle(fontSize: 11)),
                onPressed: () => showAddValueDialog(
                    context: context,
                    state: state,
                    attrIndex: index,
                    attrName: attr.name,
                    onChanged: onChanged),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColors.success.withOpacity(0.06),
                side: BorderSide(color: AppColors.success.withOpacity(0.2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Generate Button ────────────────────────────────────────────────────

  Widget _buildGenerateButton(BuildContext context) {
    final count = state.calculateTotalVariants();
    return SizedBox(
      width: double.infinity,
      child: AppButton.success(
        text: 'Varyantlari Olustur ($count)',
        icon: Icons.bolt_rounded,
        onPressed: () {
          state.generateVariants(context);
          onChanged();
        },
      ),
    );
  }

  // ─── Variant Preview ────────────────────────────────────────────────────

  Widget _buildVariantPreview(BuildContext context) {
    final accent = _accentColor;
    final displayLimit = state.showAllVariants ? state.variants.length : 5;
    final displayed = state.variants.take(displayLimit).toList();

    return _card(
      accentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _header(Icons.preview_rounded, 'Varyant Onizleme'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.variants.length} varyant',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayed.asMap().entries.map((entry) {
            final v = entry.value;
            final isEven = entry.key.isEven;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 14,
                  vertical: isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: isEven ? AppColors.bgLight : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: Text('${entry.key + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(v.sku,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    Wrap(
                      spacing: 4,
                      children: v.attributes.entries.map((e) {
                        final attrIdx = state.attributes
                            .indexWhere((a) => a.name == e.key);
                        final chipColor = attrIdx >= 0
                            ? _colorForAttrIndex(attrIdx)
                            : AppColors.info;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: chipColor.withOpacity(0.2)),
                          ),
                          child: Text(e.value,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: chipColor)),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          }),
          if (state.variants.length > 5)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  state.showAllVariants = !state.showAllVariants;
                  onChanged();
                },
                icon: Icon(
                    state.showAllVariants
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: accent),
                label: Text(
                  state.showAllVariants
                      ? 'Daha az goster'
                      : 'Tumunu goster (+${state.variants.length - 5})',
                  style: TextStyle(fontSize: 12, color: accent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child, bool accentBorder = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: accentBorder
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            )
          : child,
    );
  }

  Widget _header(IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _accentColor),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _accentColor)),
      ],
    );
  }
}
