import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Card
          _buildProfileCard(context, ref),

          const SizedBox(height: 24),

          // SATIŞ İŞLEMLERİ
          _buildMenuSection(
            context: context,
            title: 'SATIŞ İŞLEMLERİ',
            icon: Icons.point_of_sale,
            iconColor: AppColors.success,
            items: [
              _MenuItem('POS Satış', Icons.shopping_cart, '/pos'),
              _MenuItem('Satış Geçmişi', Icons.history, '/sales'),
              _MenuItem('İadeler', Icons.keyboard_return, '/sales'),
              _MenuItem('Bekleyen Satışlar', Icons.pending_actions, '/sales'),
            ],
          ),

          const SizedBox(height: 16),

          // ÜRÜN YÖNETİMİ
          _buildMenuSection(
            context: context,
            title: 'ÜRÜN YÖNETİMİ',
            icon: Icons.inventory_2,
            iconColor: AppColors.primary,
            items: [
              _MenuItem('Ürünler', Icons.list_alt, '/inventory/products'),
              _MenuItem('Kategoriler', Icons.category, '/inventory/categories'),
              _MenuItem('Firma Kategori Tanımla', Icons.tune, '/categories/company-setup'),
              _MenuItem('Markalar', Icons.branding_watermark, '/inventory/brands'),
              _MenuItem('Birimler', Icons.straighten, '/inventory/units'),
              _MenuItem('Yeni Ürün Ekle', Icons.add_box, '/inventory/add-product'),
              _MenuItem('Toplu Ürün İçe Aktarma', Icons.cloud_upload, '/bulk-import/simplified'),
              _MenuItem('Tedarikçi İthalatı', Icons.local_shipping, '/bulk-import/supplier'),
              _MenuItem('Tedarikçi İthalatı (Tablo)', Icons.table_chart, '/bulk-import/supplier-table'),
              // _MenuItem('Tedarikçi İthalatı (Dropdown)', Icons.arrow_drop_down_circle, '/bulk-import/supplier-dropdown'), // DISABLED: Has errors
              _MenuItem('Tedarikçi İthalatı (Wizard) 🧙', Icons.auto_awesome, '/bulk-import/supplier-wizard'),
              _MenuItem('Barkod Yönetimi', Icons.qr_code_2, '/inventory/barcodes'),
              _MenuItem('Stok Yönetimi', Icons.warehouse, '/stock'),
              _MenuItem('Depo Bazlı Stok', Icons.store, '/stock/multi-warehouse'),
              _MenuItem('Transfer Onay', Icons.swap_horiz, '/stock/transfer-review'),
              _MenuItem('Stok Sayım İnceleme', Icons.fact_check, '/stock/count-review'),
            ],
          ),

          const SizedBox(height: 16),

          // İŞLETME YÖNETİMİ
          _buildMenuSection(
            context: context,
            title: 'İŞLETME YÖNETİMİ',
            icon: Icons.business_center,
            iconColor: AppColors.warning,
            items: [
              _MenuItem('Depolar', Icons.warehouse, '/warehouses'),
              _MenuItem('Mağazalar', Icons.store, '/stores'),
            ],
          ),

          const SizedBox(height: 16),

          // FİNANS YÖNETİMİ
          _buildMenuSection(
            context: context,
            title: 'FİNANS YÖNETİMİ',
            icon: Icons.account_balance,
            iconColor: AppColors.success,
            items: [
              _MenuItem('Finans Özeti', Icons.dashboard, '/finance'),
              _MenuItem('Giderler', Icons.arrow_downward, '/finance/expenses'),
              _MenuItem('Gelirler', Icons.arrow_upward, '/finance'),
              _MenuItem('Raporlar', Icons.analytics, '/finance'),
            ],
          ),

          const SizedBox(height: 16),

          // SATIN ALMA
          _buildMenuSection(
            context: context,
            title: 'SATIN ALMA',
            icon: Icons.shopping_bag_rounded,
            iconColor: Colors.deepPurple,
            items: [
              _MenuItem('Satın Alma Listesi', Icons.receipt_long_rounded, '/purchases'),
              _MenuItem('Yeni Satın Alma', Icons.add_shopping_cart_rounded, '/purchases/create'),
            ],
          ),

          const SizedBox(height: 16),

          // İLİŞKİLER
          _buildMenuSection(
            context: context,
            title: 'İLİŞKİLER',
            icon: Icons.people,
            iconColor: AppColors.info,
            items: [
              _MenuItem('Müşteriler', Icons.person, '/customers'),
              _MenuItem('Tedarikçiler', Icons.business, '/suppliers'),
              _MenuItem('Borç/Alacak', Icons.account_balance_wallet, '/customers'),
            ],
          ),

          const SizedBox(height: 16),

          // ANALİZ & RAPORLAR
          _buildMenuSection(
            context: context,
            title: 'ANALİZ & RAPORLAR',
            icon: Icons.analytics,
            iconColor: Colors.purple,
            items: [
              _MenuItem('Dashboard', Icons.dashboard, '/dashboard'),
              _MenuItem('Satış Analizi', Icons.trending_up, '/reports'),
              _MenuItem('Stok Raporu', Icons.inventory, '/reports'),
              _MenuItem('Kâr/Zarar', Icons.attach_money, '/reports'),
              _MenuItem('Müşteri Analizi', Icons.people_outline, '/reports'),
            ],
          ),

          const SizedBox(height: 16),

          // AYARLAR
          _buildMenuSection(
            context: context,
            title: 'AYARLAR',
            icon: Icons.settings,
            iconColor: AppColors.textSecondary,
            items: [
              _MenuItem('Tema Ayarları', Icons.palette, '/settings/theme'),
              _MenuItem('İşletme Bilgileri', Icons.store, '/profile'),
              _MenuItem('Yazıcı Ayarları', Icons.print, '/settings/printer'),
              _MenuItem('Profil', Icons.person_outline, '/profile'),
            ],
          ),

          const SizedBox(height: 24),

          // Çıkış Butonu
          _buildLogoutButton(context, ref),

          const SizedBox(height: 24),

          // App Version
          Center(
            child: Text(
              'E-Kasa v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Admin Kullanıcı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'admin@ekasa.com',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _buildMenuItem(
                  context: context,
                  item: items[i],
                ),
                if (i < items.length - 1)
                  Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required _MenuItem item,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Çıkış Yap'),
                content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    child: const Text('Çıkış Yap'),
                  ),
                ],
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: const [
                Icon(Icons.logout, color: AppColors.danger),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;

  _MenuItem(this.title, this.icon, this.route);
}
