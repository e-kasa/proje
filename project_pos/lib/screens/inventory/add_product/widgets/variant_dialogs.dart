import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';

import '../models/wizard_state.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// Shows a dialog to add a new product attribute (e.g., Color, Size).
void showAddAttributeDialog({
  required BuildContext context,
  required WizardState state,
  required VoidCallback onChanged,
  required String Function(String) t,
}) {
  final nameController = TextEditingController();
  IconData selectedIcon = Icons.label;

  final iconOptions = [
    {'icon': Icons.palette, 'label': t('product.attr_color')},
    {'icon': Icons.straighten, 'label': t('product.attr_size')},
    {'icon': Icons.memory, 'label': t('product.attr_ram')},
    {'icon': Icons.storage, 'label': t('product.attr_storage')},
    {'icon': Icons.category, 'label': t('product.attr_model')},
    {'icon': Icons.label, 'label': t('product.attr_other')},
  ];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_circle, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(t('product.add_new_attribute')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t('product.attribute_name'),
                hintText: t('product.attribute_name_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(t('product.select_icon'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: iconOptions.map((opt) {
                final icon = opt['icon'] as IconData;
                final isSelected = selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedIcon = icon),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 24, color: isSelected ? AppColors.primary : AppColors.textMuted),
                        const SizedBox(height: 4),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('common.cancel'))),
          AppButton.primary(
            text: t('common.add'),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                state.addAttribute(
                  nameController.text.trim(),
                  selectedIcon,
                );
                onChanged();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    ),
  );
}

/// Shows a dialog to add a value to an existing attribute.
void showAddValueDialog({
  required BuildContext context,
  required WizardState state,
  required int attrIndex,
  required String attrName,
  required VoidCallback onChanged,
  required String Function(String) t,
}) {
  final valueController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(state.attributes[attrIndex].icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('$attrName ${t('product.add_value')}'),
        ],
      ),
      content: TextField(
        controller: valueController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: t('product.value'),
          hintText: t('product.value_hint'),
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (val) {
          if (val.trim().isNotEmpty) {
            state.addValueToAttribute(attrIndex, val.trim());
            onChanged();
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('common.cancel'))),
        AppButton.primary(
          text: t('common.add'),
          onPressed: () {
            if (valueController.text.trim().isNotEmpty) {
              state.addValueToAttribute(attrIndex, valueController.text.trim());
              onChanged();
              Navigator.pop(context);
            }
          },
        ),
      ],
    ),
  );
}