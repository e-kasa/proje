import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'responsive_layout.dart';

/// Profesyonel mobil bottom navigation bar
/// Seçili item: animasyonlu pill arka plan + primary renk
class AdaptiveBottomNav extends StatelessWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final Function(int, String) onItemSelected;
  final bool hasNotch;

  const AdaptiveBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.hasNotch = false,
  });

  @override
  Widget build(BuildContext context) {
    final mainItems = items.take(hasNotch ? 4 : 5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: hasNotch
              ? _buildWithNotch(mainItems)
              : _buildStandard(mainItems),
        ),
      ),
    );
  }

  Widget _buildWithNotch(List<NavigationItem> mainItems) {
    final leftItems = mainItems.take(2).toList();
    final rightItems = mainItems.skip(2).take(2).toList();

    return Row(
      children: [
        // Sol 2 item
        ...leftItems.asMap().entries.map((e) {
          return Expanded(
            child: _BottomNavItem(
              item: e.value,
              isSelected: e.key == selectedIndex,
              onTap: () => onItemSelected(e.key, e.value.route),
            ),
          );
        }),

        // Orta FAB boşluğu
        const SizedBox(width: 72),

        // Sağ 2 item
        ...rightItems.asMap().entries.map((e) {
          final index = e.key + 2;
          return Expanded(
            child: _BottomNavItem(
              item: e.value,
              isSelected: index == selectedIndex,
              onTap: () => onItemSelected(index, e.value.route),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStandard(List<NavigationItem> mainItems) {
    return Row(
      children: mainItems.asMap().entries.map((e) {
        return Expanded(
          child: _BottomNavItem(
            item: e.value,
            isSelected: e.key == selectedIndex,
            onTap: () => onItemSelected(e.key, e.value.route),
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TEKİL BOTTOM NAV ITEM — animasyonlu pill göstergesi
// ──────────────────────────────────────────────────────────────────────────────

class _BottomNavItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon + animasyonlu pill arka plan
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        item.icon,
                        key: ValueKey(isSelected),
                        size: 22,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    // Badge
                    if (item.badge != null)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 15, minHeight: 15),
                          child: Text(
                            '${item.badge}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 3),

              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
