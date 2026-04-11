import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import '../models/wizard_state.dart';

/// Category picker button that shows the selected category and opens a bottom sheet.
class CategoryPickerButton extends StatefulWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final Color accentColor;
  final String Function(String) t;

  const CategoryPickerButton({
    super.key,
    required this.state,
    required this.onChanged,
    required this.t,
    this.accentColor = AppColors.primary,
  });

  @override
  State<CategoryPickerButton> createState() => _CategoryPickerButtonState();
}

class _CategoryPickerButtonState extends State<CategoryPickerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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
    final levelColor = level < levelColors.length ? levelColors[level] : widget.accentColor;
    const levelIcons = ['\ud83d\udcc1', '\ud83d\udcc2', '\ud83d\udcc4'];
    final levelIcon = level < levelIcons.length ? levelIcons[level] : '\ud83d\udcc4';

    return GestureDetector(
      onTap: () {
        if (state.categories.isEmpty) return;
        _showCategoryPickerSheet(context);
      },
      child: hasSelection
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.04),
                border: Border.all(
                  color: levelColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildSelectedContent(label, levelColor, levelIcon, level, state),
            )
          : AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final pulseValue = _pulseAnimation.value;
                final borderColor = Color.lerp(
                  Colors.grey.shade300,
                  widget.accentColor.withValues(alpha: 0.5),
                  pulseValue,
                )!;
                final borderWidth = 1.0 + (pulseValue * 0.5);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: state.categories.isNotEmpty ? borderColor : Colors.grey.shade300,
                      width: state.categories.isNotEmpty ? borderWidth : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: child,
                );
              },
              child: _buildEmptyContent(state),
            ),
    );
  }

  Widget _buildSelectedContent(
    String label,
    Color levelColor,
    String levelIcon,
    int level,
    WizardState state,
  ) {
    return Row(
      children: [
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
                    ? widget.t('product.main_category')
                    : level == 1
                        ? widget.t('product.sub_category')
                        : widget.t('product.sub_sub_category'),
                style: TextStyle(fontSize: 10, color: levelColor),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            state.selectedCategory = null;
            widget.onChanged();
          },
          child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildEmptyContent(WizardState state) {
    if (state.categories.isEmpty) {
      return Row(children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 8),
        Text(widget.t('common.loading'), style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]);
    }
    return Row(
      children: [
        Icon(Icons.account_tree_outlined, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(widget.t('product.select_category'), style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ),
        Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
      ],
    );
  }

  void _showCategoryPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _CategoryPickerSheet(
        state: widget.state,
        accentColor: widget.accentColor,
        onChanged: widget.onChanged,
        t: widget.t,
      ),
    );
  }
}

/// Extracted bottom sheet as a StatefulWidget to hold search state.
class _CategoryPickerSheet extends StatefulWidget {
  final WizardState state;
  final Color accentColor;
  final VoidCallback onChanged;
  final String Function(String) t;

  const _CategoryPickerSheet({
    required this.state,
    required this.accentColor,
    required this.onChanged,
    required this.t,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) return widget.state.categories;
    final query = _searchQuery.toLowerCase();
    return widget.state.categories.where((cat) {
      final label = (cat['label'] as String? ?? '').toLowerCase();
      return label.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoryCount = widget.state.categories.length;
    final filtered = _filteredCategories;

    return DraggableScrollableSheet(
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
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade400,
                      Colors.grey.shade300,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.account_tree_outlined, color: widget.accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.t('product.select_category'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text(widget.t('product.company_categories'),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$categoryCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.state.selectedCategory != null)
                    TextButton.icon(
                      onPressed: () {
                        widget.state.selectedCategory = null;
                        widget.onChanged();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.clear, size: 14),
                      label: Text(widget.t('common.clear')),
                      style: TextButton.styleFrom(foregroundColor: AppColors.bgDanger,
                    ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '${widget.t('product.category')} ${widget.t('common.search').toLowerCase()}...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.accentColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Category list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            widget.t('common.no_results'),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, idx) {
                        final cat = filtered[idx];
                        final value = cat['value'] as String? ?? '';
                        final rawLabel = cat['label'] as String? ?? '';
                        final isSelected = value == widget.state.selectedCategory;

                        int level = 0;
                        if (rawLabel.startsWith('      \u2514\u2500')) {
                          level = 2;
                        } else if (rawLabel.startsWith('   \u2514\u2500')) {
                          level = 1;
                        }

                        const levelColors = [Color(0xFF1E88E5), Color(0xFFFF9800), Color(0xFF9C27B0)];
                        const levelIcons = ['\ud83d\udcc1', '\ud83d\udcc2', '\ud83d\udcc4'];
                        final levelLabels = [widget.t('product.main_category'), widget.t('product.sub_category'), widget.t('product.sub_sub_category_short')];

                        final lColor = level < levelColors.length ? levelColors[level] : widget.accentColor;
                        final lIcon = level < levelIcons.length ? levelIcons[level] : '\ud83d\udcc4';
                        final lLabel = level < levelLabels.length ? levelLabels[level] : '';
                        final indent = level * 20.0;

                        return Padding(
                          padding: EdgeInsets.only(left: indent, bottom: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              widget.state.selectedCategory = value;
                              widget.onChanged();
                              Navigator.pop(context);
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
    );
  }
}
