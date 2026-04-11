import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/menu_provider.dart';
import '../../providers/i18n_provider.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/widgets.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.shouldShowSidebar;

    // Dinamik menü — backend'den gelen verilere göre oluşturulur
    final menuState = ref.watch(menuProvider);
    final i18n = ref.watch(i18nProvider);

    // Kategori renk paleti
    const categoryColors = [AppColors.success, AppColors.primary, Colors.brown, AppColors.info, Colors.purple, Colors.teal, Colors.deepOrange, Colors.indigo];

    // Fallback sabit liste
    final List<_CategoryData> defaultCategories = [
      _CategoryData('SATIŞ & OPERASYON', AppColors.success, [
        _MenuAction('POS Satış', Icons.shopping_cart, '/pos', 'Hızlı perakende satış ekranı'),
        _MenuAction('Satış Geçmişi', Icons.history, '/sales', 'Geçmiş faturaları incele'),
        _MenuAction('Barkod Okuyucu', Icons.qr_code_scanner, '/scanner', 'Ürün sorgula ve tara'),
        _MenuAction('Parça Ara', Icons.search, '/part-search', 'Detaylı yedek parça kataloğu'),
        _MenuAction('Araç Listesi', Icons.directions_car, '/vehicles', 'Uyumlu araç tanımları'),
      ]),
      _CategoryData('ÜRÜN KATALOĞU', AppColors.primary, [
        _MenuAction('Tüm Ürünler', Icons.list_alt, '/inventory/products', 'Stok listesini yönet'),
        _MenuAction('Yeni Ürün Ekle', Icons.add_box, '/inventory/add-product', 'Kataloğa yeni kart aç'),
        _MenuAction('Toplu Ürün Girişi', Icons.playlist_add, '/inventory/batch-entry', 'Excel ile toplu giriş'),
        _MenuAction('Kategoriler', Icons.category, '/inventory/categories', 'Ürün gruplandırma'),
        _MenuAction('Marka Yönetimi', Icons.branding_watermark, '/inventory/brands', 'Marka tanımları'),
        _MenuAction('Birimler', Icons.straighten, '/inventory/units', 'Ölçü birimi ayarları'),
      ]),
      _CategoryData('STOK & DEPO', Colors.brown, [
        _MenuAction('Stok Durumu', Icons.warehouse, '/stock', 'Genel miktar raporu'),
        _MenuAction('Depolar', Icons.store, '/warehouses', 'Depo ve raf tanımları'),
        _MenuAction('Transferler', Icons.swap_horiz, '/stock/transfer', 'Depolar arası sevk'),
        _MenuAction('Stok Alarmları', Icons.notifications_active, '/stock/alerts', 'Kritik stok seviyeleri'),
      ]),
      _CategoryData('FİNANS & CARİ', AppColors.info, [
        _MenuAction('Cari Hesaplar', Icons.account_balance_wallet, '/accounts', 'Borç/Alacak takibi'),
        _MenuAction('Müşteriler', Icons.person, '/customers', 'Müşteri kartları'),
        _MenuAction('Tedarikçiler', Icons.business, '/suppliers', 'Tedarikçi kartları'),
        _MenuAction('Giderler', Icons.arrow_downward, '/finance/expenses', 'Gider girişi ve takibi'),
        _MenuAction('Nakit Akışı', Icons.currency_lira, '/finance/cash-flow', 'Para trafiği analizi'),
      ]),
      _CategoryData('ANALİZ & SİSTEM', Colors.purple, [
        _MenuAction('Raporlar', Icons.analytics, '/reports', 'Detaylı sistem raporları'),
        _MenuAction('Satış Analizi', Icons.show_chart, '/reports/sales-summary', 'Grafiksel performans'),
        _MenuAction('Toplu Aktarım', Icons.cloud_upload, '/bulk-import', 'Excel ile veri aktarımı'),
        _MenuAction('Ayarlar', Icons.settings, '/settings', 'Sistem yapılandırma'),
      ]),
    ];

    // Bundle kodunu çevir
    String t(String code) => i18n.isLoaded ? i18n.bundle(code) : code;

    // Backend'den menü geldiyse dinamik oluştur, yoksa fallback kullan
    final List<_CategoryData> categories = menuState.categories.isNotEmpty
        ? menuState.categories.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final color = categoryColors[i % categoryColors.length];
            return _CategoryData(
              t(cat.label),
              color,
              cat.menus.expand((m) => m.items.map((item) => _MenuAction(
                    t(item.label),
                    menuIconMap[m.icon] ?? Icons.circle,
                    item.link,
                    '',
                  ))).toList(),
            );
          }).toList()
        : defaultCategories;

    // Filtreleme mantığı
    final filteredCategories = categories.map((cat) {
      final filteredActions = cat.actions.where((action) => 
        action.title.toLowerCase().contains(_searchQuery) || 
        action.subtitle.toLowerCase().contains(_searchQuery)
      ).toList();
      return _CategoryData(cat.title, cat.color, filteredActions);
    }).where((cat) => cat.actions.isNotEmpty).toList();

    return AppScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(context, isDesktop),
          ),

          // Boş Durum (Empty State)
          if (filteredCategories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 16,
                vertical: 8,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = filteredCategories[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: _buildCategoryGroup(context, cat, isDesktop),
                    );
                  },
                  childCount: filteredCategories.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(isDesktop ? 48 : 24, 40, isDesktop ? 48 : 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UYGULAMA BAŞLATICI', 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('İşlem Seçin', 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              if (isDesktop) _buildUserBadge(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Hızlıca modül veya işlem arayın...',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              }) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildUserBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 16, color: Colors.white)),
          const SizedBox(width: 10),
          const Text('Admin Panel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
            onPressed: () => context.go('/login'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(BuildContext context, _CategoryData cat, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16, top: 40),
          child: Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Text(cat.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.5)),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 2,
            mainAxisExtent: 88,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: cat.actions.length,
          itemBuilder: (context, index) => _MenuCard(action: cat.actions[index], accentColor: cat.color),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState.search(
      title: 'Sonuç Bulunamadı',
      description: 'Aradığınız kelimeye uygun bir modül bulunamadı.',
    );
  }
}

class _MenuCard extends StatefulWidget {
  final _MenuAction action;
  final Color accentColor;
  const _MenuCard({required this.action, required this.accentColor});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        transform: _isHovered ? (Matrix4.identity()..translate(0, -4, 0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? widget.accentColor : AppColors.border.withValues(alpha:0.5), width: _isHovered ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? widget.accentColor.withValues(alpha:0.12) : Colors.black.withValues(alpha:0.02),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 10 : 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => context.push(widget.action.route),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isHovered ? widget.accentColor : widget.accentColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.action.icon, size: 24, color: _isHovered ? Colors.white : widget.accentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.action.title, 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.2)),
                      const SizedBox(height: 2),
                      Text(widget.action.subtitle, 
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _isHovered ? widget.accentColor : AppColors.border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  final String title;
  final Color color;
  final List<_MenuAction> actions;
  _CategoryData(this.title, this.color, this.actions);
}

class _MenuAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  _MenuAction(this.title, this.icon, this.route, this.subtitle);
}