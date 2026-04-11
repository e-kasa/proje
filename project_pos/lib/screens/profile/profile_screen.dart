import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        user?.displayName.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? user?.username ?? 'Kullanıcı',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user?.email != null && user!.email!.isNotEmpty)
                      Text(
                        user.email!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (user?.roles != null && user!.roles.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: user.roles.map((role) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Menu Items
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Profil Bilgileri',
                      subtitle: 'Kişisel bilgilerinizi düzenleyin',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'Ürünlerim',
                      subtitle: 'Ürün listenizi görüntüleyin',
                      onTap: () => context.go('/inventory/products'),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Satış Geçmişi',
                      subtitle: 'Geçmiş satışlarınızı görüntüleyin',
                      onTap: () => context.go('/sales'),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.bar_chart_outlined,
                      title: 'İstatistikler',
                      subtitle: 'Satış ve stok raporları',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Settings Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Bildirimler',
                      subtitle: 'Bildirim ayarlarını yönetin',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Güvenlik',
                      subtitle: 'Şifre ve güvenlik ayarları',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.language_outlined,
                      title: 'Dil',
                      subtitle: 'Türkçe',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Yardım & Destek',
                      subtitle: 'SSS ve iletişim',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Logout Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: AppButton.danger(
                  text: 'Çıkış Yap',
                  icon: Icons.logout,
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  fullWidth: true,
                ),
              ),

              const SizedBox(height: 16),

              // Version Info
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1),
    );
  }
}