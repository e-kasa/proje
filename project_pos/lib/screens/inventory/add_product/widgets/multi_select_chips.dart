import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'wizard_common_widgets.dart';

/// Multi-select chip widget with dropdown for adding new selections.
/// Supports sector-aware theming via optional [accentColor].
class MultiSelectChips extends ConsumerWidget {
  final List<String> selectedValues;
  final List<Map<String, dynamic>> allOptions;
  final String hintText;
  final IconData icon;
  final ValueChanged<List<String>> onChanged;
  final Color accentColor;

  const MultiSelectChips({
    super.key,
    required this.selectedValues,
    required this.allOptions,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    this.accentColor = AppColors.primary,
  });

  bool get _allSelected =>
      allOptions.isNotEmpty && selectedValues.length >= allOptions.length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final unselected =
        allOptions.where((o) => !selectedValues.contains(o['value'])).toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Selected chips with numbered badges --
          if (selectedValues.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(selectedValues.length, (index) {
                final val = selectedValues[index];
                final opt = allOptions.firstWhere(
                  (o) => o['value'] == val,
                  orElse: () => <String, dynamic>{'value': val, 'label': val},
                );
                return _buildSelectedChip(
                  label: opt['label']?.toString() ?? val,
                  index: index + 1,
                  onRemove: () {
                    final newList = List<String>.from(selectedValues)
                      ..remove(val);
                    onChanged(newList);
                  },
                );
              }),
            ),
            const SizedBox(height: 10),
          ],

          // -- All-selected success badge --
          if (_allSelected)
            _buildAllSelectedBadge(t)
          // -- Dropdown for remaining options --
          else if (unselected.isNotEmpty)
            DropdownButtonFormField<String>(
              value: null,
              decoration: inputDecoration(hintText).copyWith(
                prefixIcon: Icon(icon, color: accentColor, size: 18),
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
          // -- Empty state with dashed border --
          else if (selectedValues.isEmpty)
            _buildEmptyState(t),
        ],
      ),
    );
  }

  /// A single selected chip with a numbered badge and accent-tinted background.
  Widget _buildSelectedChip({
    required String label,
    required int index,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Numbered badge
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          // Delete button
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 12,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge shown when every option has been selected.
  Widget _buildAllSelectedBadge(String Function(String) t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.08),
            AppColors.success.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${t('common.all_options_selected')} (${selectedValues.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state with dashed border and centered content.
  Widget _buildEmptyState(String Function(String) t) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.border,
        strokeWidth: 1.2,
        dashLength: 6,
        gapLength: 4,
        radius: 10,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('common.no_options_loaded'),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for a dashed rounded-rectangle border.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashLength != oldDelegate.dashLength ||
      gapLength != oldDelegate.gapLength ||
      radius != oldDelegate.radius;
}