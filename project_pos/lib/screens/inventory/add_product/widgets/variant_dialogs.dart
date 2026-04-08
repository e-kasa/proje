import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../models/wizard_state.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// Shows a dialog to add a new product attribute (e.g., Color, Size).
void showAddAttributeDialog({
  required BuildContext context,
  required WizardState state,
  required VoidCallback onChanged,
}) {
  final nameController = TextEditingController();
  IconData selectedIcon = Icons.label;

  final iconOptions = [
    {'icon': Icons.palette, 'label': 'Renk'},
    {'icon': Icons.straighten, 'label': 'Beden/Numara'},
    {'icon': Icons.memory, 'label': 'RAM'},
    {'icon': Icons.storage, 'label': 'Depolama'},
    {'icon': Icons.category, 'label': 'Model'},
    {'icon': Icons.label, 'label': 'Di\u011fer'},
  ];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: AppColors.primary, size: 24),
            SizedBox(width: 12),
            Text('Yeni \u00d6zellik Ekle'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '\u00d6zellik Ad\u0131',
                hintText: '\u00d6rn: Renk, Beden, RAM',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('\u0130kon Se\u00e7:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('\u0130ptal')),
          AppButton.primary(
            text: 'Ekle',
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
}) {
  final valueController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(state.attributes[attrIndex].icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('$attrName De\u011feri Ekle'),
        ],
      ),
      content: TextField(
        controller: valueController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'De\u011fer',
          hintText: '\u00d6rn: ${attrName == "Renk" ? "K\u0131rm\u0131z\u0131" : attrName == "Beden" ? "M" : "8GB"}',
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('\u0130ptal')),
        AppButton.primary(
          text: 'Ekle',
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
