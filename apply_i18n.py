#!/usr/bin/env python3
"""Batch apply i18n to Flutter POS project files."""
import re, os

BASE = r"C:\Users\Win11\Documents\GitHub\proje\project_pos\lib"

I18N_IMPORT = "import 'package:project_pos/core/utils/i18n_helper.dart';"

# ─────────────────────────────────────────────────────────────────────────
# For each file: (path_relative_to_lib, is_consumer_stateful, replacements)
# replacements = list of (old_text, new_text)
# ─────────────────────────────────────────────────────────────────────────

def add_import(content, import_line):
    """Add import after last existing import line if not already present."""
    if import_line in content:
        return content
    # Find last import
    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            last_import_idx = i
    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, import_line)
    return '\n'.join(lines)


def add_t_declaration(content, class_state_name):
    """Add 'final t = i18nOf(ref);' as first line of build method for ConsumerState classes."""
    # Pattern: Widget build(BuildContext context) {
    # We need to add final t = i18nOf(ref); right after the opening brace
    pattern = r'(Widget build\(BuildContext context\)\s*\{)'

    if 'final t = i18nOf(ref);' in content:
        return content

    # For ConsumerWidget build(context, ref) pattern
    pattern2 = r'(Widget build\(BuildContext context,\s*WidgetRef ref\)\s*\{)'

    # Try ConsumerState first (build with just context)
    if re.search(pattern, content) and 'ConsumerState' in content:
        content = re.sub(pattern, r'\1\n    final t = i18nOf(ref);', content, count=1)
    elif re.search(pattern2, content):
        content = re.sub(pattern2, r'\1\n    final t = i18nOf(ref);', content, count=1)

    return content


def remove_const_before_t(content):
    """Remove const from widgets that now use t()."""
    # This is tricky - we need to find const before widgets that contain t(
    # Simple approach: remove const from specific patterns
    # const Text('...') where we replaced with Text(t('...'))
    # We'll handle this by looking for const before t( patterns
    result = content
    # Remove "const " before constructs containing "t(" on the same or next line
    # This is a simplified approach
    return result


def process_file(filepath, replacements, is_consumer_widget=False):
    """Process a single file with replacements and i18n setup."""
    if not os.path.exists(filepath):
        print(f"  SKIP (not found): {filepath}")
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Add import
    content = add_import(content, I18N_IMPORT)

    # Add t declaration
    if is_consumer_widget:
        content = add_t_declaration(content, '')
    elif 'ConsumerState' in content:
        content = add_t_declaration(content, '')

    # Apply replacements
    for old, new in replacements:
        content = content.replace(old, new)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  UPDATED: {filepath}")
    else:
        print(f"  NO CHANGE: {filepath}")


# ═══════════════════════════════════════════════════════════════════════════
# FILE DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════

# ── settings_screen.dart ──
settings_screen_replacements = [
    # AppBar title
    ("title: 'Ayarlar',", "title: t('settings.title'),"),
    # Tabs
    ("tabs: const [", "tabs: ["),
    ("Tab(icon: Icon(Icons.person), text: 'Profil'),", "Tab(icon: Icon(Icons.person), text: t('profile.title')),"),
    ("Tab(icon: Icon(Icons.palette), text: 'Görünüm'),", "Tab(icon: Icon(Icons.palette), text: t('settings.appearance')),"),
    ("Tab(icon: Icon(Icons.store), text: 'İşletme'),", "Tab(icon: Icon(Icons.store), text: t('settings.business')),"),
    ("Tab(icon: Icon(Icons.settings), text: 'Sistem'),", "Tab(icon: Icon(Icons.settings), text: t('settings.system')),"),
    # Profile settings
    ("'Kişisel Bilgiler',", "t('settings.personal_info'),"),
    ("title: 'Ad Soyad',", "title: t('form.full_name'),"),
    ("title: 'E-posta',", "title: t('form.email'),"),
    ("title: 'Telefon',", "title: t('form.phone'),"),
    ("'Güvenlik',", "t('settings.security'),"),
    ("title: 'Şifre Değiştir',", "title: t('settings.change_password'),"),
    ("title: 'İki Faktörlü Doğrulama',", "title: t('settings.two_factor'),"),
    # Appearance
    ("'Tema',", "t('settings.theme'),"),
    ("title: const Text('Açık Tema'),", "title: Text(t('settings.light_theme')),"),
    ("subtitle: const Text('Her zaman açık tema kullan'),", "subtitle: Text(t('settings.always_light')),"),
    ("title: const Text('Koyu Tema'),", "title: Text(t('settings.dark_theme')),"),
    ("subtitle: const Text('Her zaman koyu tema kullan'),", "subtitle: Text(t('settings.always_dark')),"),
    ("title: const Text('Sistem'),", "title: Text(t('settings.system_theme')),"),
    ("subtitle: const Text('Sistem ayarını takip et'),", "subtitle: Text(t('settings.follow_system')),"),
    ("'Görünüm',", "t('settings.appearance'),"),
    ("title: 'Dil',", "title: t('settings.language'),"),
    ("title: 'Yazı Boyutu',", "title: t('settings.font_size'),"),
    ("title: 'Renk Teması',", "title: t('settings.color_theme'),"),
    # Business
    ("'Şirket Bilgileri',", "t('settings.company_info'),"),
    ("title: 'Şirket Adı',", "title: t('form.company_name'),"),
    ("title: 'Vergi No',", "title: t('form.tax_number'),"),
    ("title: 'Adres',", "title: t('form.address'),"),
    ("'Mağaza Ayarları',", "t('settings.store_settings'),"),
    ("title: 'Varsayılan Mağaza',", "title: t('settings.default_store'),"),
    ("title: 'Varsayılan Depo',", "title: t('settings.default_warehouse'),"),
    ("title: 'Fatura Öneki',", "title: t('settings.invoice_prefix'),"),
    ("'Yonetim',", "t('settings.management'),"),
    ("title: 'Kullanici Yonetimi',", "title: t('settings.user_management'),"),
    ("title: 'Firma Ayarlari',", "title: t('settings.company_info'),"),
    ("title: 'Sektör Ayarları',", "title: t('settings.sector_settings'),"),
    ("subtitle: 'Ürün formu alanlarını sektörünüze göre özelleştirin',", "subtitle: t('settings.sector_settings_desc'),"),
    # Notifications
    ("'Bildirimler',", "t('settings.notifications'),"),
    ("title: 'E-posta Bildirimleri',", "title: t('settings.email_notifications'),"),
    ("title: 'Stok Uyarıları',", "title: t('settings.stock_alerts'),"),
    ("title: 'Satış Uyarıları',", "title: t('settings.sales_alerts'),"),
    # System
    ("'Veri & Gizlilik',", "t('settings.data_privacy'),"),
    ("title: 'Yedekleme',", "title: t('settings.backup'),"),
    ("title: 'Senkronizasyon',", "title: t('settings.sync'),"),
    ("title: 'Önbelleği Temizle',", "title: t('settings.clear_cache'),"),
    ("title: 'Önbelleği Temizle',\n                      message: 'Tüm önbellek verileri silinecek. Devam etmek istiyor musunuz?',",
     "title: t('settings.clear_cache'),\n                      message: t('settings.clear_cache_confirm'),"),
    # About
    ("'Hakkında',", "t('settings.about'),"),
    ("title: 'Versiyon',", "title: t('settings.version'),"),
    ("title: 'Gizlilik Politikası',", "title: t('settings.privacy_policy'),"),
    ("title: 'Kullanım Koşulları',", "title: t('settings.terms'),"),
    # Danger zone
    ("'Tehlikeli Alan',", "t('settings.danger_zone'),"),
    ("title: 'Çıkış Yap',", "title: t('nav.logout'),"),
    ("title: 'Hesabı Sil',", "title: t('settings.delete_account'),"),
    # Dialogs
    ("child: const Text('İptal'),", "child: Text(t('common.cancel')),"),
    ("text: 'Kaydet',", "text: t('common.save'),"),
    ("title: const Text('Şifre Değiştir'),", "title: Text(t('settings.change_password')),"),
    ("decoration: const InputDecoration(labelText: 'Mevcut Şifre'),", "decoration: InputDecoration(labelText: t('settings.current_password')),"),
    ("decoration: const InputDecoration(labelText: 'Yeni Şifre'),", "decoration: InputDecoration(labelText: t('settings.new_password')),"),
    ("decoration: const InputDecoration(labelText: 'Şifreyi Onayla'),", "decoration: InputDecoration(labelText: t('form.confirm_password')),"),
    # Toasts
    ("AppToast.info(context, 'Fotoğraf değiştirme özelliği yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'İki faktörlü doğrulama yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'Dil değiştirme yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'Yazı boyutu ayarı yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'Renk teması değiştirme yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'Mağaza seçimi yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'Depo seçimi yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'Yedekleme ayarları yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'Gizlilik politikası yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.info(context, 'Kullanım koşulları yakında!');", "AppToast.info(context, t('common.coming_soon'));"),
    ("AppToast.success(context, 'Önbellek temizlendi');", "AppToast.success(context, t('settings.cache_cleared'));"),
    ("message: 'Çıkış yapmak istediğinizden emin misiniz?',", "message: t('nav.logout_confirm'),"),
    ("confirmText: 'Çıkış Yap',", "confirmText: t('nav.logout'),"),
    ("subtitle: 'Tüm verileriniz kalıcı olarak silinecek',", "subtitle: t('settings.delete_account_warning'),"),
    ("AppToast.error(context, 'Hesap silme özelliği yakında!');", "AppToast.error(context, t('common.coming_soon'));"),
]

# ── company_settings_screen.dart ──
company_settings_replacements = [
    ("title: 'Firma Ayarlari',", "title: t('settings.company_info'),"),
    ("label: const Text('Kaydet'),", "label: Text(t('common.save')),"),
    ("title: 'Firma Bilgileri',", "title: t('settings.company_info'),"),
    ("label: 'Firma Adi',", "label: t('form.company_name'),"),
    ("? 'Firma adi zorunlu' : null,", "? t('validation.company_name_required') : null,"),
    ("label: 'Vergi No',", "label: t('form.tax_number'),"),
    ("label: 'Vergi Dairesi',", "label: t('form.tax_office'),"),
    ("label: 'Telefon',", "label: t('form.phone'),"),
    ("label: 'E-posta',", "label: t('form.email'),"),
    ("label: 'Adres',", "label: t('form.address'),"),
    ("title: 'Fatura Ayarlari',", "title: t('settings.invoice_settings'),"),
    ("label: 'Seri No Prefix',", "label: t('settings.serial_prefix'),"),
    ("label: 'Varsayilan KDV Orani (%)',", "label: t('settings.default_vat_rate'),"),
    ("title: 'Sistem',", "title: t('settings.system'),"),
    ("labelText: 'Varsayilan Para Birimi',", "labelText: t('settings.default_currency'),"),
    ("AppToast.success(context, 'Firma ayarlari kaydedildi');", "AppToast.success(context, t('settings.company_saved'));"),
    ("AppToast.error(context, 'Ayarlar yuklenemedi: \$e');", "AppToast.error(context, '\${t(\"common.error\")}: \$e');"),
    ("AppToast.error(context, 'Kaydedilemedi: \$e');", "AppToast.error(context, '\${t(\"common.error\")}: \$e');"),
]

# ── sector_settings_screen.dart ──
sector_settings_replacements = [
    ("title: 'Sektör Ayarları',", "title: t('settings.sector_settings'),"),
    ("'Sektör Seçin',", "t('settings.select_sector'),"),
    ("'Aktif',", "t('common.active'),"),
]

# ── theme_settings_drawer_advanced.dart ──
theme_settings_replacements = [
    ("'Tema Özelleştirici',", "t('settings.theme_customizer'),"),
    ("'Tema, düzen ve renkleri özelleştirin',", "t('settings.theme_customize_desc'),"),
    ("final tabs = ['Genel', 'Düzen', 'Renkler', 'Gelişmiş'];", "final tabs = [t('settings.general'), t('settings.layout'), t('settings.colors'), t('settings.advanced')];"),
    ("_buildSectionTitle('Tema Modu', Icons.brightness_6),", "_buildSectionTitle(t('settings.theme_mode'), Icons.brightness_6),"),
    ("label: 'Açık',", "label: t('settings.light'),"),
    ("label: 'Koyu',", "label: t('settings.dark'),"),
    ("label: 'Sistem',", "label: t('settings.system_theme'),"),
    ("_buildSectionTitle('Ana Renk', Icons.color_lens),", "_buildSectionTitle(t('settings.primary_color'), Icons.color_lens),"),
    ("_buildSectionTitle('Düzen Modu', Icons.view_quilt),", "_buildSectionTitle(t('settings.layout_mode'), Icons.view_quilt),"),
    ("_buildSectionTitle('Genişlik', Icons.settings_overscan),", "_buildSectionTitle(t('settings.width'), Icons.settings_overscan),"),
    ("_buildSectionTitle('Sidebar Görünümü', Icons.menu),", "_buildSectionTitle(t('settings.sidebar_appearance'), Icons.menu),"),
    ("'Özel Sidebar rengi',", "t('settings.custom_sidebar_color'),"),
    ("_buildSectionTitle('Topbar Görünümü', Icons.horizontal_rule),", "_buildSectionTitle(t('settings.topbar_appearance'), Icons.horizontal_rule),"),
    ("'Özel Topbar rengi',", "t('settings.custom_topbar_color'),"),
    ("title: const Text('Renk Seçin'),", "title: Text(t('settings.select_color')),"),
    ("child: const Text('İptal'),", "child: Text(t('common.cancel')),"),
    ("child: const Text('Seç'),", "child: Text(t('common.select')),"),
    ("heading: const Text(", "heading: Text("),
    ("'Hazır Renkler',", "t('settings.preset_colors'),"),
    ("subheading: const Text(", "subheading: Text("),
    ("'Özel Renk',", "t('settings.custom_color'),"),
    ("wheelSubheading: const Text(", "wheelSubheading: Text("),
    ("'Renk Tekeri',", "t('settings.color_wheel'),"),
    ("title: 'Material You',", "title: 'Material You',"),  # keep as-is, brand name
    ("subtitle: 'Dinamik renkler (Material 3)',", "subtitle: t('settings.dynamic_colors'),"),
    ("title: 'RTL Desteği',", "title: t('settings.rtl_support'),"),
    ("subtitle: 'Sağdan sola metin yönü',", "subtitle: t('settings.rtl_desc'),"),
    ("label: const Text('Sıfırla'),", "label: Text(t('settings.reset')),"),
    ("label: const Text('Tamam'),", "label: Text(t('common.ok')),"),
    ("'Ana renk seçin',", "t('settings.select_primary_color'),"),
]

# ── reports_screen.dart ──
reports_screen_replacements = [
    ("title: 'Raporlar',", "title: t('reports.title'),"),
    ("tooltip: 'Tarih Aralığı Seç',", "tooltip: t('reports.select_date_range'),"),
    ("tooltip: 'Raporu İndir',", "tooltip: t('reports.download_report'),"),
    ("Tab(text: 'Satışlar', icon: Icon(Icons.shopping_cart)),", "Tab(text: t('reports.sales'), icon: Icon(Icons.shopping_cart)),"),
    ("Tab(text: 'Müşteriler', icon: Icon(Icons.people)),", "Tab(text: t('reports.customers'), icon: Icon(Icons.people)),"),
    ("Tab(text: 'Envanter', icon: Icon(Icons.inventory_2)),", "Tab(text: t('reports.inventory'), icon: Icon(Icons.inventory_2)),"),
    ("tabs: const [", "tabs: ["),
    ("title: const Text('Rapor Dışa Aktar'),", "title: Text(t('reports.export_report')),"),
    ("title: const Text('PDF olarak dışa aktar'),", "title: Text(t('reports.export_pdf')),"),
    ("title: const Text('Excel olarak dışa aktar'),", "title: Text(t('reports.export_excel')),"),
    ("child: const Text('İptal'),", "child: Text(t('common.cancel')),"),
    ("description: 'Veri yüklenemedi',", "description: t('common.error'),"),
    ("'Detaylı Analizler',", "t('reports.detailed_analysis'),"),
    ("_ReportLink('Satış Özeti',", "_ReportLink(t('reports.sales_summary'),"),
    ("_ReportLink('Ürün Analizi',", "_ReportLink(t('reports.product_analysis'),"),
    ("_ReportLink('Müşteri Analizi',", "_ReportLink(t('reports.customer_analysis'),"),
    ("_ReportLink('Kar Analizi',", "_ReportLink(t('reports.profit_overview'),"),
    # Stats
    ("_buildStatCard('Toplam Satış',", "_buildStatCard(t('reports.total_sales'),"),
    ("_buildStatCard('Toplam Tutar',", "_buildStatCard(t('reports.total_amount'),"),
    ("_buildStatCard('Ortalama',", "_buildStatCard(t('reports.average'),"),
    ("_buildStatCard('Bugün',", "_buildStatCard(t('reports.today'),"),
    ("child: Text('Son Satışlar',", "child: Text(t('reports.recent_sales'),"),
    ("description: 'Satış kaydı yok')", "description: t('common.no_data'))"),
    ("_buildStatCard('Toplam Müşteri',", "_buildStatCard(t('reports.total_customers'),"),
    ("_buildStatCard('Aktif',", "_buildStatCard(t('common.active'),"),
    ("child: Text('En İyi Müşteriler',", "child: Text(t('reports.top_customers'),"),
    ("description: 'Müşteri kaydı yok')", "description: t('common.no_data'))"),
    ("_buildStatCard('Toplam Ürün',", "_buildStatCard(t('reports.total_products'),"),
    ("_buildStatCard('Düşük Stok',", "_buildStatCard(t('reports.low_stock'),"),
    ("_buildStatCard('Tükenen',", "_buildStatCard(t('reports.out_of_stock'),"),
    ("_buildStatCard('Toplam Değer',", "_buildStatCard(t('reports.total_value'),"),
    ("Text('Stok Durumu',", "Text(t('reports.stock_status'),"),
]

# ── daily_summary_screen.dart ──
daily_summary_replacements = [
    ("title: 'Gunluk Ozet',", "title: t('reports.daily_summary'),"),
    ("const Text('Bugun',", "Text(t('reports.today'),"),
    ("_summaryCard('Toplam Satis',", "_summaryCard(t('reports.total_sales'),"),
    ("_summaryCard('Toplam Gelir',", "_summaryCard(t('reports.total_revenue'),"),
    ("_summaryCard('Ort. Siparis',", "_summaryCard(t('reports.avg_order'),"),
    ("_summaryCard('Net Kar',", "_summaryCard(t('reports.net_profit'),"),
    ("const Text('Odeme Yontemleri',", "Text(t('reports.payment_methods'),"),
    ("const Text('En Cok Satan Urunler',", "Text(t('reports.top_products'),"),
    ("description: 'Veri bulunamadi')", "description: t('common.no_data'))"),
    ("const Text('Son Islemler',", "Text(t('reports.recent_transactions'),"),
    ("description: 'Bugun islem yapilmamis')", "description: t('reports.no_transactions_today'))"),
]

# ── sales_summary_screen.dart ──
sales_summary_replacements = [
    ("title: 'Satis Ozeti',", "title: t('reports.sales_summary'),"),
    ("tooltip: 'Tarih Araligi Sec',", "tooltip: t('reports.select_date_range'),"),
    ("'Satis Adedi',", "t('reports.sales_count'),"),
    ("'Toplam Ciro',", "t('reports.total_revenue'),"),
    ("'Ort. Sepet',", "t('reports.avg_cart'),"),
    ("'Odeme Yontemi Dagilimi',", "t('reports.payment_distribution'),"),
]

# ── product_sales_analysis_screen.dart ──
product_analysis_replacements = [
    ("title: 'Urun Satis Analizi',", "title: t('reports.product_analysis'),"),
    ("tooltip: 'Tarih Araligi Sec',", "tooltip: t('reports.select_date_range'),"),
    ("'Toplam Urun',", "t('reports.total_products'),"),
    ("'Toplam Satis',", "t('reports.total_sales'),"),
    ("'Toplam Ciro',", "t('reports.total_revenue'),"),
]

# ── customer_sales_analysis_screen.dart ──
customer_analysis_replacements = [
    ("title: 'Musteri Satis Analizi',", "title: t('reports.customer_analysis'),"),
    ("text: 'Tekrar Dene',", "text: t('common.retry'),"),
    ("Text('Musteri verisi bulunamadi'),", "Text(t('common.no_data')),"),
]

# ── profit_overview_screen.dart ──
profit_overview_replacements = [
    ("title: 'Kar/Zarar Ozeti',", "title: t('reports.profit_overview'),"),
    ("tooltip: 'Tarih Araligi Sec',", "tooltip: t('reports.select_date_range'),"),
    ("'Toplam Gelir',", "t('reports.total_revenue'),"),
    ("'Toplam Gider',", "t('reports.total_expense'),"),
    ("'Net Kar',", "t('reports.net_profit'),"),
    ("'Kar Marji',", "t('reports.profit_margin'),"),
]

# ── warehouse_list_screen.dart ──
warehouse_list_replacements = [
    ("title: 'Depo Yönetimi',", "title: t('warehouse.title'),"),
    ("tooltip: 'Yenile',", "tooltip: t('common.refresh'),"),
    ("hintText: 'Depo ara...',", "hintText: t('warehouse.search'),"),
    ("title: 'Depo bulunamadı',", "title: t('warehouse.not_found'),"),
    ("actionText: 'Yeni Depo Ekle',", "actionText: t('warehouse.add'),"),
    ("label: const Text('Yeni Depo'),", "label: Text(t('warehouse.add')),"),
    ("title: const Text('Depo Sil'),", "title: Text(t('warehouse.delete')),"),
    ("child: const Text('İptal'),", "child: Text(t('common.cancel')),"),
    ("text: 'Sil',", "text: t('common.delete'),"),
    ("AppToast.success(context, 'Depo başarıyla silindi');", "AppToast.success(context, t('common.success'));"),
    ("AppToast.error(context, 'Depolar yüklenirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
    ("AppToast.error(context, 'Depo silinirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
    ("AppToast.success(context, 'Durum güncellendi');", "AppToast.success(context, t('settings.status_updated'));"),
    ("AppToast.error(context, 'Durum güncellenirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
    ("label: const Text('Sadece Aktif'),", "label: Text(t('common.active')),"),
    ("text: 'Düzenle',", "text: t('common.edit'),"),
]

# ── add_warehouse_screen.dart ──
add_warehouse_replacements = [
    ("title: widget.warehouseId != null ? 'Depo Düzenle' : 'Yeni Depo Ekle',", "title: widget.warehouseId != null ? t('warehouse.edit') : t('warehouse.add'),"),
    ("title: 'Depo Tipi',", "title: t('warehouse.type'),"),
    ("title: 'Temel Bilgiler',", "title: t('warehouse.basic_info'),"),
    ("title: 'Konum Bilgileri',", "title: t('warehouse.location_info'),"),
    ("title: 'İletişim Bilgileri',", "title: t('warehouse.contact_info'),"),
    ("title: 'Durum',", "title: t('common.status'),"),
    ("title: const Text('Aktif'),", "title: Text(t('common.active')),"),
    ("text: _isSaving\n                            ? 'Kaydediliyor...'\n                            : widget.warehouseId != null\n                                ? 'Güncelle'\n                                : 'Kaydet',",
     "text: _isSaving\n                            ? t('common.loading')\n                            : widget.warehouseId != null\n                                ? t('common.update')\n                                : t('common.save'),"),
    ("AppToast.success(context, 'Depo başarıyla güncellendi');", "AppToast.success(context, t('common.success'));"),
    ("AppToast.success(context, 'Depo başarıyla oluşturuldu');", "AppToast.success(context, t('common.success'));"),
    ("AppToast.error(context, 'Depo kaydedilirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
    ("AppToast.error(context, 'Depo bilgileri yüklenirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
]

# ── store_list_screen.dart ──
store_list_replacements = [
    ("title: 'Mağaza Yönetimi',", "title: t('store.title'),"),
    ("tooltip: 'Yenile'", "tooltip: t('common.refresh')"),
    ("hintText: 'Mağaza ara...',", "hintText: t('store.search'),"),
    ("title: 'Mağaza bulunamadı',", "title: t('store.not_found'),"),
    ("actionText: 'Yeni Mağaza Ekle',", "actionText: t('store.add'),"),
    ("label: const Text('Yeni Mağaza'),", "label: Text(t('store.add')),"),
    ("Text('Mağaza Sil')],", "Text(t('store.delete'))],"),
    ("child: const Text('İptal')", "child: Text(t('common.cancel'))"),
    ("text: 'Sil',", "text: t('common.delete'),"),
    ("text: 'Düzenle',", "text: t('common.edit'),"),
    ("AppToast.error(context, 'Mağazalar yüklenirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
    ("AppToast.success(context, 'Mağaza başarıyla silindi');", "AppToast.success(context, t('common.success'));"),
    ("AppToast.error(context, 'Mağaza silinirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
]

# ── add_store_screen.dart ──
add_store_replacements = [
    ("title: widget.storeId != null ? 'Mağaza Düzenle' : 'Yeni Mağaza Ekle',", "title: widget.storeId != null ? t('store.edit') : t('store.add'),"),
    ("AppToast.success(context, 'Mağaza başarıyla güncellendi');", "AppToast.success(context, t('common.success'));"),
    ("AppToast.success(context, 'Mağaza başarıyla oluşturuldu');", "AppToast.success(context, t('common.success'));"),
    ("AppToast.error(context, 'Mağaza kaydedilirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
    ("AppToast.error(context, 'Mağaza bilgileri yüklenirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
]

# ── category_list_screen.dart ──
category_list_replacements = [
    ("title: 'Kategoriler',", "title: t('category.title'),"),
    ("tooltip: 'Seçilenleri Sil',", "tooltip: t('common.delete'),"),
    ("tooltip: 'İptal',", "tooltip: t('common.cancel'),"),
    ("tooltip: 'Seçim Modu',", "tooltip: t('category.selection_mode'),"),
    ("tooltip: 'Yenile',", "tooltip: t('common.refresh'),"),
    ("hintText: 'Kategori ara...',", "hintText: t('category.search'),"),
    ("label: const Text('Yeni Kategori'),", "label: Text(t('category.add')),"),
    ("title: const Text('Kategoriyi Sil'),", "title: Text(t('category.delete')),"),
    ("title: const Text('Toplu Silme'),", "title: Text(t('category.bulk_delete')),"),
    ("child: const Text('İptal')),", "child: Text(t('common.cancel'))),"),
    ("text: 'Sil',", "text: t('common.delete'),"),
    ("Text('Düzenle'),", "Text(t('common.edit')),"),
    ("Text('Sil',", "Text(t('common.delete'),"),
]

# ── add_category_screen.dart ──
add_category_replacements = [
    ("title: isEdit ? 'Kategori Düzenle' : 'Yeni Kategori',", "title: isEdit ? t('category.edit') : t('category.add'),"),
    ("title: 'Temel Bilgiler',", "title: t('category.basic_info'),"),
    ("title: 'İkon Seçimi',", "title: t('category.icon_selection'),"),
    ("title: 'Gelişmiş Ayarlar',", "title: t('category.advanced_settings'),"),
    ("text: isEdit ? 'Güncelle' : 'Oluştur',", "text: isEdit ? t('common.update') : t('common.create'),"),
]

# ── company_category_screen.dart ──
company_category_replacements = [
    ("title: const Text('Kategori Tanımla'),", "title: Text(t('category.define')),"),
    ("label: const Text('Tümünü Seç', style: TextStyle(color: Colors.white, fontSize: 12)),", "label: Text(t('category.select_all'), style: const TextStyle(color: Colors.white, fontSize: 12)),"),
    ("label: const Text('Temizle', style: TextStyle(color: Colors.white70, fontSize: 12)),", "label: Text(t('common.clear'), style: const TextStyle(color: Colors.white70, fontSize: 12)),"),
    ("text: 'Tekrar Dene',", "text: t('common.retry'),"),
    ("Text('Kategoriler yükleniyor...', style: TextStyle(color: AppColors.textSecondary)),", "Text(t('common.loading'), style: const TextStyle(color: AppColors.textSecondary)),"),
]

# ── vehicle_list_screen.dart ──
vehicle_list_replacements = [
    ("Text(isEdit ? 'Arac Duzenle' : 'Yeni Arac Ekle'),", "Text(isEdit ? t('vehicle.edit') : t('vehicle.add')),"),
    ("const Text('Henuz arac eklenmemis',", "Text(t('vehicle.no_vehicles'),"),
    ("child: const Text('Iptal')),", "child: Text(t('common.cancel'))),"),
    ("Text('Araci Sil'),", "Text(t('vehicle.delete')),"),
    ("label: Text(isEdit ? 'Guncelle' : 'Kaydet'),", "label: Text(isEdit ? t('common.update') : t('common.save')),"),
    ("child: const Text('Iptal')", "child: Text(t('common.cancel'))"),
    ("label: const Text('Yeni Arac'),", "label: Text(t('vehicle.add')),"),
    ("Text('Duzenle'),", "Text(t('common.edit')),"),
    ("Text('Sil'),", "Text(t('common.delete')),"),
]

# ── vehicle_compatibility_screen.dart ──
vehicle_compat_replacements = [
    ("title: 'Arac Uyumlulugu',", "title: t('vehicle.compatibility'),"),
    ("const Text('Henuz arac uyumlulugu eklenmemis',", "Text(t('vehicle.no_compatibility'),"),
    ("text: 'Arac Ekle',", "text: t('vehicle.add_vehicle'),"),
    ("Text('Arac Uyumlulugu Ekle'),", "Text(t('vehicle.add_compatibility')),"),
    ("child: const Text('Iptal')),", "child: Text(t('common.cancel'))),"),
]

# ── employee_list_screen.dart ──
employee_list_replacements = [
    ("title: 'Çalışanlar',", "title: t('hrm.employees'),"),
    ("title: 'Çalışan Bulunamadı',", "title: t('hrm.no_employees'),"),
    ("label: const Text('Yeni Çalışan'),", "label: Text(t('hrm.add_employee')),"),
    ("title: 'Çalışanı Sil',", "title: t('hrm.delete_employee'),"),
    ("AppToast.error(context, 'Çalışanlar yüklenirken hata oluştu');", "AppToast.error(context, t('common.error'));"),
    ("AppToast.success(context, 'Durum güncellendi');", "AppToast.success(context, t('settings.status_updated'));"),
    ("AppToast.error(context, 'Durum güncellenemedi');", "AppToast.error(context, t('common.error'));"),
    ("AppToast.success(context, 'Çalışan silindi');", "AppToast.success(context, t('common.success'));"),
    ("AppToast.error(context, 'Çalışan silinemedi');", "AppToast.error(context, t('common.error'));"),
]

# ── add_employee_screen.dart ──
add_employee_replacements = [
    ("title: _isEditing ? 'Calisan Duzenle' : 'Yeni Calisan',", "title: _isEditing ? t('hrm.edit_employee') : t('hrm.add_employee'),"),
    ("const Text('Kaydet',", "Text(t('common.save'),"),
    ("_sectionTitle('Kisisel Bilgiler'),", "_sectionTitle(t('hrm.personal_info')),"),
    ("_sectionTitle('Is Bilgileri'),", "_sectionTitle(t('hrm.job_info')),"),
    ("_sectionTitle('Ek Bilgiler'),", "_sectionTitle(t('hrm.additional_info')),"),
    ("text: _isSaving\n                        ? 'Kaydediliyor...'\n                        : _isEditing\n                            ? 'Guncelle'\n                            : 'Kaydet',",
     "text: _isSaving\n                        ? t('common.loading')\n                        : _isEditing\n                            ? t('common.update')\n                            : t('common.save'),"),
]

# ── modern_dashboard_screen.dart ──
dashboard_replacements = [
    ("? 'Günaydın'", "? t('dashboard.good_morning')"),
    ("? 'İyi Günler'", "? t('dashboard.good_afternoon')"),
    (": 'İyi Akşamlar';", ": t('dashboard.good_evening');"),
    ("_buildSectionTitle('Hızlı Aksiyonlar')", "_buildSectionTitle(t('dashboard.quick_actions'))"),
    ("_buildSectionTitle('Modüller')", "_buildSectionTitle(t('dashboard.modules'))"),
    ("_buildSectionTitle('Son Aktiviteler')", "_buildSectionTitle(t('dashboard.recent_activities'))"),
    ("'Henüz aktivite yok',", "t('dashboard.no_activity'),"),
    ("'Son Aktiviteler',", "t('dashboard.recent_activities'),"),
    ("'Tümünü gör →',", "t('common.view_all'),"),
    # KPI
    ("label: 'Günlük Gelir',", "label: t('dashboard.daily_revenue'),"),
    ("label: 'Satış Adedi',", "label: t('dashboard.sales_count'),"),
    ("label: 'Müşteriler',", "label: t('dashboard.customers'),"),
    ("label: 'Düşük Stok',", "label: t('dashboard.low_stock'),"),
    # Quick actions
    ("_Action('POS Satış',", "_Action(t('dashboard.pos_sales'),"),
    ("_Action('Barkod Tara',", "_Action(t('dashboard.scan_barcode'),"),
    ("_Action('Satış Geçmişi',", "_Action(t('dashboard.sales_history'),"),
    ("_Action('Stok Durumu',", "_Action(t('dashboard.stock_status'),"),
    ("_Action('Yeni Ürün',", "_Action(t('dashboard.new_product'),"),
    ("_Action('Raporlar',", "_Action(t('reports.title'),"),
    # Activity
    ("title: 'Satış tamamlandı',", "title: t('dashboard.sale_completed'),"),
    ("title: 'Düşük stok uyarısı',", "title: t('dashboard.low_stock_warning'),"),
    # Months
    ("'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',\n      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'",
     "t('month.january'), t('month.february'), t('month.march'), t('month.april'), t('month.may'), t('month.june'),\n      t('month.july'), t('month.august'), t('month.september'), t('month.october'), t('month.november'), t('month.december')"),
]

# ── profile_screen.dart ──
profile_replacements = [
    ("title: 'Profil Bilgileri',", "title: t('profile.edit_info'),"),
    ("subtitle: 'Kişisel bilgilerinizi düzenleyin',", "subtitle: t('profile.edit_info_desc'),"),
    ("title: 'Ürünlerim',", "title: t('profile.my_products'),"),
    ("subtitle: 'Ürün listenizi görüntüleyin',", "subtitle: t('profile.my_products_desc'),"),
    ("title: 'Satış Geçmişi',", "title: t('profile.sales_history'),"),
    ("subtitle: 'Geçmiş satışlarınızı görüntüleyin',", "subtitle: t('profile.sales_history_desc'),"),
    ("title: 'İstatistikler',", "title: t('profile.statistics'),"),
    ("subtitle: 'Satış ve stok raporları',", "subtitle: t('profile.statistics_desc'),"),
    ("title: 'Bildirimler',", "title: t('settings.notifications'),"),
    ("subtitle: 'Bildirim ayarlarını yönetin',", "subtitle: t('profile.notifications_desc'),"),
    ("title: 'Güvenlik',", "title: t('profile.security'),"),
    ("subtitle: 'Şifre ve güvenlik ayarları',", "subtitle: t('profile.security_desc'),"),
    ("title: 'Dil',", "title: t('settings.language'),"),
    ("title: 'Yardım & Destek',", "title: t('profile.help'),"),
    ("subtitle: 'SSS ve iletişim',", "subtitle: t('profile.help_desc'),"),
    ("text: 'Çıkış Yap',", "text: t('nav.logout'),"),
    ("'Yönetici',", "t('profile.admin'),"),
]

# ── barcode_scanner_screen.dart ──
scanner_replacements = [
    ("'Barkod Tarandı',", "t('scanner.barcode_scanned'),"),
    ("'Barkod Kodu:',", "t('scanner.barcode_code'),"),
    ("child: const Text('Tekrar Tara'),", "child: Text(t('scanner.scan_again')),"),
    ("text: 'Ürünü Bul',", "text: t('scanner.find_product'),"),
    ("'Barkodu Okutun',", "t('scanner.scan_barcode'),"),
    ("'Ürün barkodunu kare içerisine hizalayın',", "t('scanner.align_barcode'),"),
    ("label: 'Ürün Ekle',", "label: t('scanner.add_product'),"),
    ("label: 'Geçmiş',", "label: t('scanner.history'),"),
    ("label: 'Ayarlar',", "label: t('settings.title'),"),
]

# ── part_search_screen.dart ──
part_search_replacements = [
    ("hintText: 'Parca adi, OEM no, capraz referans, barkod...',", "hintText: t('partsearch.search_hint'),"),
    ("const Text('Arac Filtresi',", "Text(t('partsearch.vehicle_filter'),"),
    ("label: const Text('Temizle',", "label: Text(t('common.clear'),"),
    ("const Text('Parca Arama',", "Text(t('partsearch.title'),"),
    ("const Text('Sonuc bulunamadi',", "Text(t('common.no_result'),"),
    ("const Text('Farkli anahtar kelime deneyin',", "Text(t('partsearch.try_different'),"),
]

# ── right_menu_drawer.dart ──
right_menu_replacements = [
    ("const Text('Cikis Yap'),", "Text(t('nav.logout')),"),
    ("title: const Text('Cikis Yap'),", "title: Text(t('nav.logout')),"),
    ("content: const Text('Cikis yapmak istediginizden emin misiniz?'),", "content: Text(t('nav.logout_confirm')),"),
    ("child: const Text('Iptal'),", "child: Text(t('common.cancel')),"),
    ("child: const Text('Cikis Yap'),", "child: Text(t('nav.logout')),"),
]

# ── adaptive_sidebar.dart ──
adaptive_sidebar_replacements = [
    ("'Parçacı',", "t('nav.app_name'),"),
    ("'Stok & Cari Yönetimi',", "t('nav.app_tagline'),"),
    ("tooltip: isExpanded ? 'Daralt' : 'Genişlet',", "tooltip: isExpanded ? t('settings.collapse') : t('settings.expand'),"),
]

# ── success_screen.dart ──
success_screen_replacements = [
    ("title: const Text('✅ İşlem Tamamlandı'),", "title: const Text('İşlem Tamamlandı'),"),
    ("'Başarıyla Tamamlandı!',", "'İşlem Başarılı!',"),
    ("label: const Text('Ürünlere Git'),", "label: const Text('Ürünlere Git'),"),  # keep, no ConsumerState
    ("label: const Text('Fişi Görüntüle'),", "label: const Text('Fişi Görüntüle'),"),
    ("label: const Text('Yeni Yükleme'),", "label: const Text('Yeni Yükleme'),"),
    ("'Sonuç Özeti',", "'Sonuç Özeti',"),
]


# ═══════════════════════════════════════════════════════════════════════════
# PROCESS ALL FILES
# ═══════════════════════════════════════════════════════════════════════════

files = [
    ("screens/settings/settings_screen.dart", settings_screen_replacements),
    ("screens/settings/company_settings_screen.dart", company_settings_replacements),
    ("screens/settings/sector_settings_screen.dart", sector_settings_replacements),
    ("screens/settings/theme_settings_drawer_advanced.dart", theme_settings_replacements),
    ("screens/reports/reports_screen.dart", reports_screen_replacements),
    ("screens/reports/daily_summary_screen.dart", daily_summary_replacements),
    ("screens/reports/sales_summary_screen.dart", sales_summary_replacements),
    ("screens/reports/product_sales_analysis_screen.dart", product_analysis_replacements),
    ("screens/reports/customer_sales_analysis_screen.dart", customer_analysis_replacements),
    ("screens/reports/profit_overview_screen.dart", profit_overview_replacements),
    ("screens/warehouse/warehouse_list_screen.dart", warehouse_list_replacements),
    ("screens/warehouse/add_warehouse_screen.dart", add_warehouse_replacements),
    ("screens/store/store_list_screen.dart", store_list_replacements),
    ("screens/store/add_store_screen.dart", add_store_replacements),
    ("screens/categories/category_list_screen.dart", category_list_replacements),
    ("screens/categories/add_category_screen.dart", add_category_replacements),
    ("screens/categories/company_category_screen.dart", company_category_replacements),
    ("screens/vehicles/vehicle_list_screen.dart", vehicle_list_replacements),
    ("screens/vehicles/vehicle_compatibility_screen.dart", vehicle_compat_replacements),
    ("screens/hrm/employee_list_screen.dart", employee_list_replacements),
    ("screens/hrm/add_employee_screen.dart", add_employee_replacements),
    ("screens/dashboard/modern_dashboard_screen.dart", dashboard_replacements),
    ("screens/profile/profile_screen.dart", profile_replacements),
    ("screens/scanner/barcode_scanner_screen.dart", scanner_replacements),
    ("screens/part_search/part_search_screen.dart", part_search_replacements),
    ("core/layouts/right_menu_drawer.dart", right_menu_replacements),
    ("core/layouts/adaptive_sidebar.dart", adaptive_sidebar_replacements),
]

# Files that are ConsumerWidget (not ConsumerStatefulWidget)
consumer_widget_files = {
    "screens/settings/sector_settings_screen.dart",
    "screens/profile/profile_screen.dart",
    "core/layouts/right_menu_drawer.dart",
    "core/layouts/adaptive_sidebar.dart",
}

print("=" * 60)
print("Applying i18n to Flutter POS project files")
print("=" * 60)

for rel_path, replacements in files:
    filepath = os.path.join(BASE, rel_path.replace('/', os.sep))
    is_cw = rel_path in consumer_widget_files
    print(f"\nProcessing: {rel_path}")
    process_file(filepath, replacements, is_consumer_widget=is_cw)

# success_screen.dart - StatelessWidget, no i18n (no ref available)
# We skip adding i18n import and t() for this file since it's a plain StatelessWidget

print("\n" + "=" * 60)
print("Done!")
print("=" * 60)
