import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'responsive_layout.dart';

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
          _buildHeader(),
          Expanded(
            child: _buildNavList(),
          ),
          _buildFooter(ref),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HEADER: Logo + toggle butonu
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.build_circle, color: Colors.white, size: 20),
          ),

          if (isExpanded) ...[
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parçacı',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Stok & Cari Yönetimi',
                    style: TextStyle(
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
              tooltip: isExpanded ? 'Daralt' : 'Genişlet',
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NAVİGASYON LİSTESİ
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildNavList() {
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
  }) {
    final itemWidget = _SidebarNavItem(
      item: item,
      isSelected: isSelected,
      isExpanded: isExpanded,
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

  Widget _buildFooter(WidgetRef ref) {
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
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
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
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(
            horizontal: isExpanded ? 10 : 10,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : _hovered
                    ? AppColors.bgLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              // Sol accent bar (seçili iken)
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 6,
                  bottom: 6,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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
                    Icon(
                      widget.item.icon,
                      size: 20,
                      color: isSelected
                          ? AppColors.primary
                          : _hovered
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : _hovered
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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