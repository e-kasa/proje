import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';

/// Category picker button that shows the selected category and opens a bottom sheet.
class CategoryPickerButton extends StatelessWidget {
  final WizardState state;
  final VoidCallback onChanged;

  const CategoryPickerButton({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cat = state.selectedCategory != null
        ? state.categories.firstWhere(
            (c) => c['value'] == state.selectedCategory,
            orElse: () => <String, dynamic>{},
          )
        : null;

    final hasSelection = cat != null && cat.isNotEmpty;
    final label = hasSelection ? (cat['label'] as String? ?? '') : '';

    int level = 0;
    if (label.startsWith('      \u2514\u2500')) {
      level = 2;
    } else if (label.startsWith('   \u2514\u2500')) {
      level = 1;
    }

    const levelColors = [Color(0xFF1E88E5), Color(0xFFFF9800), Color(0xFF9C27B0)];
    final levelColor = level < levelColors.length ? levelColors[level] : AppColors.primary;
    const levelIcons = ['\ud83d\udcc1', '\ud83d\udcc2', '\ud83d\udcc4'];
    final levelIcon = level < levelIcons.length ? levelIcons[level] : '\ud83d\udcc4';

    return GestureDetector(
      onTap: () {
        if (state.categories.isEmpty) return;
        _showCategoryPickerSheet(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasSelection ? levelColor.withValues(alpha: 0.04) : Colors.white,
          border: Border.all(
            color: hasSelection ? levelColor.withValues(alpha: 0.5) : Colors.grey.shade300,
            width: hasSelection ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: state.categories.isEmpty
            ? Row(children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400),
                ),
                const SizedBox(width: 8),
                Text('Y\u00fckleniyor...', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ])
            : Row(
                children: [
                  if (hasSelection) ...[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text(levelIcon, style: const TextStyle(fontSize: 13))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.trim(),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            level == 0
                                ? 'Ana Kategori'
                                : level == 1
                                    ? 'Alt Kategori'
                                    : 'Alt-Alt Kategori',
                            style: TextStyle(fontSize: 10, color: levelColor),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        state.selectedCategory = null;
                        onChanged();
                      },
                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                    ),
                  ] else ...[
                    Icon(Icons.account_tree_outlined, size: 18, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Kategori se\u00e7in', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                  ],
                ],
              ),
      ),
    );
  }

  void _showCategoryPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.70,
        maxChildSize: 0.95,
        minChildSize: 0.40,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_tree_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kategori Se\u00e7',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('Firmaya tan\u0131ml\u0131 kategoriler',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (state.selectedCategory != null)
                      TextButton.icon(
                        onPressed: () {
                          state.selectedCategory = null;
                          onChanged();
                          Navigator.pop(sheetCtx);
                        },
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text('Temizle'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Category list
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                  itemCount: state.categories.length,
                  itemBuilder: (_, idx) {
                    final cat = state.categories[idx];
                    final value = cat['value'] as String? ?? '';
                    final rawLabel = cat['label'] as String? ?? '';
                    final isSelected = value == state.selectedCategory;

                    int level = 0;
                    if (rawLabel.startsWith('      \u2514\u2500')) {
                      level = 2;
                    } else if (rawLabel.startsWith('   \u2514\u2500')) {
                      level = 1;
                    }

                    const levelColors = [Color(0xFF1E88E5), Color(0xFFFF9800), Color(0xFF9C27B0)];
                    const levelIcons = ['\ud83d\udcc1', '\ud83d\udcc2', '\ud83d\udcc4'];
                    const levelLabels = ['Ana Kategori', 'Alt Kategori', 'Alt-Alt'];

                    final lColor = level < levelColors.length ? levelColors[level] : AppColors.primary;
                    final lIcon = level < levelIcons.length ? levelIcons[level] : '\ud83d\udcc4';
                    final lLabel = level < levelLabels.length ? levelLabels[level] : '';
                    final indent = level * 20.0;

                    return Padding(
                      padding: EdgeInsets.only(left: indent, bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          state.selectedCategory = value;
                          onChanged();
                          Navigator.pop(sheetCtx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? lColor.withValues(alpha: 0.12)
                                : level == 0
                                    ? Colors.grey.shade50
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? lColor.withValues(alpha: 0.6)
                                  : level == 0
                                      ? Colors.grey.shade200
                                      : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: lColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(child: Text(lIcon, style: const TextStyle(fontSize: 16))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rawLabel.trim(),
                                      style: TextStyle(
                                        fontSize: level == 0 ? 14 : 13,
                                        fontWeight: level == 0 ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected ? lColor : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (lLabel.isNotEmpty)
                                      Text(
                                        lLabel,
                                        style: TextStyle(fontSize: 10, color: lColor.withValues(alpha: 0.8)),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: lColor, size: 22)
                              else
                                Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
