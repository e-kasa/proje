import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shared form field builder with label and optional required marker.
Widget buildFormField({required String label, bool required = false, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          if (required) const Text(' *', style: TextStyle(color: AppColors.danger)),
        ],
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

/// Standard input decoration used across all steps.
InputDecoration inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.bgLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    hintStyle: const TextStyle(fontSize: 13),
  );
}

/// Stat card used in Step 3 statistics.
Widget buildStatCard(String label, String value, Color color, {required bool isMobile}) {
  final parts = label.split('\n');
  final emoji = parts[0].contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))
      ? parts[0].split(' ')[0]
      : '';
  final title = emoji.isNotEmpty
      ? parts[0].substring(emoji.length).trim() + (parts.length > 1 ? ' ${parts[1]}' : '')
      : label.replaceAll('\n', ' ');

  return Container(
    padding: EdgeInsets.all(isMobile ? 4 : 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.10), color.withOpacity(0.03)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
      border: Border.all(color: color.withOpacity(0.25), width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: isMobile ? 3 : 4,
          offset: const Offset(0, 1),
        )
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (emoji.isNotEmpty)
          Text(emoji, style: TextStyle(fontSize: isMobile ? 12 : 16)),
        if (emoji.isNotEmpty) SizedBox(height: isMobile ? 1 : 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 11 : 14,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 1 : 2),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 7 : 8,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// Responsive stat grid used in Step 3.
Widget buildResponsiveStatGrid(List<Map<String, dynamic>> statCards, {required bool isMobile}) {
  final crossAxisCount = isMobile ? 3 : 6;

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: isMobile ? 1.2 : 1.6,
      crossAxisSpacing: isMobile ? 4 : 6,
      mainAxisSpacing: isMobile ? 4 : 6,
    ),
    itemCount: statCards.length,
    itemBuilder: (context, index) {
      final card = statCards[index];
      return buildStatCard(
        card['label'] as String,
        card['value'] as String,
        card['color'] as Color,
        isMobile: isMobile,
      );
    },
  );
}

/// Summary card used in Step 5 preview.
Widget buildSummaryCard(String value, String label, Color color, {required bool isMobile}) {
  return Container(
    padding: EdgeInsets.all(isMobile ? 4 : 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: isMobile ? 3 : 4, offset: const Offset(0, 1))],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 11 : 14,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 1 : 2),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isMobile ? 7 : 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// Responsive summary grid used in Step 5.
Widget buildResponsiveSummaryGrid(List<Map<String, dynamic>> summaryCards, {required bool isMobile}) {
  final crossAxisCount = isMobile ? 3 : 6;

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: isMobile ? 1.2 : 1.6,
      crossAxisSpacing: isMobile ? 4 : 6,
      mainAxisSpacing: isMobile ? 4 : 6,
    ),
    itemCount: summaryCards.length,
    itemBuilder: (context, index) {
      final card = summaryCards[index];
      return buildSummaryCard(
        card['value'] as String,
        card['label'] as String,
        card['color'] as Color,
        isMobile: isMobile,
      );
    },
  );
}

/// Info card used in Step 5 preview.
Widget buildInfoCard(String title, List<Widget> children, {required bool isMobile}) {
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
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        ...children,
      ],
    ),
  );
}

/// Info row inside info cards.
Widget buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
