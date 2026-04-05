import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'wizard_common_widgets.dart';

/// Multi-select chip widget with dropdown for adding new selections.
class MultiSelectChips extends StatelessWidget {
  final List<String> selectedValues;
  final List<Map<String, dynamic>> allOptions;
  final String hintText;
  final IconData icon;
  final ValueChanged<List<String>> onChanged;

  const MultiSelectChips({
    super.key,
    required this.selectedValues,
    required this.allOptions,
    required this.hintText,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final unselected = allOptions.where((o) => !selectedValues.contains(o['value'])).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedValues.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: selectedValues.map((val) {
              final opt = allOptions.firstWhere(
                (o) => o['value'] == val,
                orElse: () => <String, dynamic>{'value': val, 'label': val},
              );
              return Chip(
                label: Text(opt['label']?.toString() ?? val, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.danger),
                onDeleted: () {
                  final newList = List<String>.from(selectedValues)..remove(val);
                  onChanged(newList);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        if (unselected.isNotEmpty)
          DropdownButtonFormField<String>(
            value: null,
            decoration: inputDecoration(hintText).copyWith(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
            ),
            items: unselected.map<DropdownMenuItem<String>>((opt) {
              return DropdownMenuItem<String>(
                value: opt['value'] as String,
                child: Text(opt['label']?.toString() ?? ''),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null && !selectedValues.contains(val)) {
                onChanged([...selectedValues, val]);
              }
            },
          )
        else if (selectedValues.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text('Hen\u00fcz se\u00e7enek y\u00fcklenmedi', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}
