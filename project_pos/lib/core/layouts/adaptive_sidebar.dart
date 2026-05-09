import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'responsive_layout.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// Profesyonel desktop/web sidebar
class AdaptiveSidebar extends ConsumerWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final bool isExpanded;
  final Function(int, String) onItemSelected;
  final VoidCallback onToggle;

  const AdaptiveSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.isExpanded,
    required this.onItemSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    // Sprint 11j — kullanıcının seçtiği primary tema rengi (preset veya custom).
    // Hover/selected state, logo, avatar, accent bar bu renge bağlı —
    // tema değiştirildiğinde sidebar otomatik yenilenir.
    final theme = ref.watch(themeProvider);
    final primary = theme.resolvedPrimary;
    final primaryEnd = theme.resolvedEnd;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isExpanded ? 240 : 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _buildHeader(t, primary, primaryEnd),
          Expanded(
            child: _buildNavList(primary),
          ),
          _buildFooter(ref, primary),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER: Logo + toggle butonu
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(String Function(String) t, Color primary, Color primaryEnd) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo icon — tema primary gradient
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primaryEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.build_circle, color: Colors.white, size: 20),
          ),

          if (isExpanded) ...[
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('nav.app_name'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    t('nav.app_tagline'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const Spacer(),

          // Toggle butonu
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: const Icon(Icons.chevron_left, size: 20),
              ),
              color: AppColors.textSecondary,
              onPressed: onToggle,
              tooltip: isExpanded ? t('settings.collapse') : t('settings.expand'),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NAVİGASYON LİSTESİ
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildNavList(Color primary) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = index == selectedIndex;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bölüm başlığı (varsa ve sidebar genişse)
            if (item.sectionLabel != null && isExpanded)
              _buildSectionLabel(item.sectionLabel!),

            _buildNavItem(
              item: item,
              index: index,
              isSelected: isSelected,
              primary: primary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NavigationItem item,
    required int index,
    required bool isSelected,
    required Color primary,
  }) {
    final itemWidget = _SidebarNavItem(
      item: item,
      isSelected: isSelected,
      isExpanded: isExpanded,
      primary: primary,
      onTap: () => onItemSelected(index, item.route),
    );

    // Daraltılmış modda tooltip göster
    if (!isExpanded) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        child: itemWidget,
      );
    }

    return itemWidget;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ALT BÖLÜM: Kullanıcı bilgisi
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildFooter(WidgetRef ref, Color primary) {
    final user = ref.watch(authProvider).user;
    final displayName = user?.displayName ?? 'Admin';
    final companyCode = user?.selectedCompanyCode ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Container(
      padding: EdgeInsets.all(isExpanded ? 14 : 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Avatar — tema primary gradient
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          if (isExpanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (companyCode.isNotEmpty)
                    Text(
                      companyCode,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TEKİL NAV ITEM — kendi hover state'ini yönetir
// ──────────────────────────────────────────────────────────────────────────────

class _SidebarNavItem extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final bool isExpanded;
  /// Sprint 11j — kullanıcının seçtiği tema primary rengi.
  /// Hover/selected background, accent bar, icon/text tinting bu rengi kullanır.
  final Color primary;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isExpanded = widget.isExpanded;
    final primary = widget.primary;

    // Sprint 11j — daha belirgin hover state:
    //   normal → şeffaf
    //   hovered → primary tinted bg (alpha 0.10) + sol primary accent (2px) +
    //             ikon/text primary rengine yumuşak geçiş
    //   selected → primary tinted bg (alpha 0.16) + sol primary accent (3px) +
    //              bold text + primary renk
    final Color bgColor;
    final double accentWidth;
    final Color iconColor;
    final Color textColor;
    final FontWeight textWeight;

    if (isSelected) {
      bgColor = primary.withValues(alpha: 0.16);
      accentWidth = 3;
      iconColor = primary;
      textColor = primary;
      textWeight = FontWeight.w700;
    } else if (_hovered) {
      bgColor = primary.withValues(alpha: 0.10);
      accentWidth = 2;
      iconColor = primary;
      textColor = primary;
      textWeight = FontWeight.w600;
    } else {
      bgColor = Colors.transparent;
      accentWidth = 0;
      iconColor = AppColors.textSecondary;
      textColor = AppColors.textSecondary;
      textWeight = FontWeight.w500;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            // Hover ve selected durumlarda hafif elevation
            boxShadow: (isSelected || _hovered)
                ? [
                    BoxShadow(
                      color: primary.withValues(
                          alpha: isSelected ? 0.18 : 0.10),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Sol accent bar — animasyonlu, hover/selected'da görünür
              if (accentWidth > 0)
                Positioned(
                  left: 0,
                  top: 6,
                  bottom: 6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: accentWidth,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // İçerik
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 14 : 10,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        widget.item.icon,
                        size: 20,
                        color: iconColor,
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 11),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 160),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: textWeight,
                            color: textColor,
                            letterSpacing: -0.1,
                          ),
                          child: Text(
                            widget.item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Badge
                      if (widget.item.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.item.badge}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}