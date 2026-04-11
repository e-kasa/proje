import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../../providers/auth_provider.dart';

/// Mobilde sag taraftan acilan tam menu drawer
class RightMenuDrawer extends ConsumerWidget {
  const RightMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final displayName = user?.displayName ?? 'Admin';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, displayName, email, initial),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildSection(context, 'SATIS ISLEMLERI', Icons.point_of_sale, AppColors.success, [
                    _DrawerItem('POS Satis', Icons.shopping_cart, '/pos'),
                    _DrawerItem('Satis Gecmisi', Icons.history, '/sales'),
                  ]),

                  _buildSection(context, 'URUN YONETIMI', Icons.inventory_2, AppColors.primary, [
                    _DrawerItem('Urunler', Icons.list_alt, '/inventory/products'),
                    _DrawerItem('Kategoriler', Icons.category, '/inventory/categories'),
                    _DrawerItem('Firma Kategori', Icons.tune, '/categories/company-setup'),
                    _DrawerItem('Markalar', Icons.branding_watermark, '/inventory/brands'),
                    _DrawerItem('Birimler', Icons.straighten, '/inventory/units'),
                    _DrawerItem('Urun Ekle', Icons.add_box, '/inventory/add-product'),
                    _DrawerItem('Toplu Giris', Icons.playlist_add, '/inventory/batch-entry'),
                    _DrawerItem('Barkodlar', Icons.qr_code_2, '/inventory/barcodes'),
                    _DrawerItem('Parca Ara', Icons.search, '/part-search'),
                  ]),

                  _buildSection(context, 'STOK YONETIMI', Icons.warehouse, Colors.brown, [
                    _DrawerItem('Stok Durumu', Icons.warehouse, '/stock'),
                    _DrawerItem('Hareketler', Icons.history, '/stock/movements'),
                    _DrawerItem('Alarmlar', Icons.notifications_active, '/stock/alerts'),
                    _DrawerItem('Deger Raporu', Icons.bar_chart, '/stock/value-report'),
                    _DrawerItem('Depo Bazli', Icons.store, '/stock/multi-warehouse'),
                    _DrawerItem('Transfer', Icons.swap_horiz, '/stock/transfer'),
                    _DrawerItem('Transfer Onay', Icons.check_circle, '/stock/transfer-review'),
                    _DrawerItem('Sayim', Icons.fact_check, '/stock/count-review'),
                  ]),

                  _buildSection(context, 'ICE AKTARMA', Icons.cloud_upload, Colors.indigo, [
                    _DrawerItem('Toplu Yukleme', Icons.cloud_upload, '/bulk-import'),
                    _DrawerItem('Tedarikci Ithalati', Icons.auto_awesome, '/bulk-import/supplier-wizard'),
                  ]),

                  _buildSection(context, 'SATIN ALMA', Icons.shopping_bag_rounded, Colors.deepPurple, [
                    _DrawerItem('Satin Alma Listesi', Icons.receipt_long, '/purchases'),
                    _DrawerItem('Yeni Satin Alma', Icons.add_shopping_cart, '/purchases/create'),
                  ]),

                  _buildSection(context, 'CARI HESAPLAR', Icons.people, AppColors.info, [
                    _DrawerItem('Hesap Ozeti', Icons.dashboard, '/accounts'),
                    _DrawerItem('Ekstre', Icons.receipt, '/accounts/statement'),
                    _DrawerItem('Vadesi Gecmis', Icons.warning_amber, '/accounts/overdue'),
                    _DrawerItem('Musteriler', Icons.person, '/customers'),
                    _DrawerItem('Tedarikciler', Icons.business, '/suppliers'),
                  ]),

                  _buildSection(context, 'FINANS', Icons.account_balance, AppColors.success, [
                    _DrawerItem('Finans Ozeti', Icons.dashboard, '/finance'),
                    _DrawerItem('Giderler', Icons.arrow_downward, '/finance/expenses'),
                    _DrawerItem('Gelirler', Icons.arrow_upward, '/finance/add-income'),
                    _DrawerItem('Odemeler', Icons.payment, '/finance/payments'),
                    _DrawerItem('Nakit Akisi', Icons.currency_lira, '/finance/cash-flow'),
                  ]),

                  _buildSection(context, 'ISLETME', Icons.business_center, AppColors.warning, [
                    _DrawerItem('Depolar', Icons.warehouse, '/warehouses'),
                    _DrawerItem('Magazalar', Icons.store, '/stores'),
                    _DrawerItem('Araclar', Icons.directions_car, '/vehicles'),
                  ]),

                  _buildSection(context, 'RAPORLAR', Icons.analytics, Colors.purple, [
                    _DrawerItem('Dashboard', Icons.dashboard, '/dashboard'),
                    _DrawerItem('Raporlar', Icons.analytics, '/reports'),
                    _DrawerItem('Gunluk Ozet', Icons.today, '/reports/daily-summary'),
                    _DrawerItem('Satis Ozeti', Icons.show_chart, '/reports/sales-summary'),
                    _DrawerItem('Urun Analizi', Icons.category, '/reports/product-analysis'),
                    _DrawerItem('Musteri Analizi', Icons.people_outline, '/reports/customer-analysis'),
                    _DrawerItem('Kar/Zarar', Icons.trending_up, '/reports/profit-overview'),
                  ]),

                  _buildSection(context, 'INSAN KAYNAKLARI', Icons.people_alt, Colors.teal, [
                    _DrawerItem('Calisanlar', Icons.badge, '/hrm/employees'),
                    _DrawerItem('Calisan Ekle', Icons.person_add, '/hrm/employees/add'),
                  ]),

                  _buildSection(context, 'AYARLAR', Icons.settings, AppColors.textSecondary, [
                    _DrawerItem('Genel Ayarlar', Icons.settings, '/settings'),
                    _DrawerItem('Isletme Bilgileri', Icons.business, '/settings/company'),
                    _DrawerItem('Kullanicilar', Icons.manage_accounts, '/settings/users'),
                    _DrawerItem('Profil', Icons.person_outline, '/profile'),
                  ]),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Cikis butonu
            _buildLogoutButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email, String initial) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData titleIcon,
    Color color,
    List<_DrawerItem> items,
  ) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
          child: Row(
            children: [
              Icon(titleIcon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) {
          final isActive = currentRoute == item.route;
          return _buildDrawerItem(context, item, isActive);
        }),
      ],
    );
  }

  Widget _buildDrawerItem(BuildContext context, _DrawerItem item, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(
          item.icon,
          size: 18,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          Navigator.of(context).pop(); // drawer kapat
          context.go(item.route);
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.logout, color: AppColors.danger, size: 20),
        title: const Text(
          'Cikis Yap',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.danger,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        onTap: () async {
          Navigator.of(context).pop();
          final confirmed = await AppConfirmationDialog.showWarning(
            context: context,
            title: 'Cikis Yap',
            message: 'Cikis yapmak istediginizden emin misiniz?',
            confirmText: 'Cikis Yap',
            cancelText: 'Iptal',
          );
          if (confirmed && context.mounted) {
            ref.read(authProvider.notifier).logout();
            context.go('/login');
          }
        },
      ),
    );
  }
}

class _DrawerItem {
  final String title;
  final IconData icon;
  final String route;

  _DrawerItem(this.title, this.icon, this.route);
}