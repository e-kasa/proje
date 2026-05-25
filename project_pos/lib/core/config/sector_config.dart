/// Şirket sektörüne göre uygulama davranışını belirleyen konfigürasyon sistemi.
///
/// Kullanım:
///   final cfg = ref.watch(sectorConfigProvider);
///   if (cfg.showOemField) ...
///   Text(cfg.label.productName)   // "Parça" / "Ürün" / "Cihaz" / "Model"

// ── Sektör Türleri ────────────────────────────────────────────────────────────
enum SectorType {
  autoParts,   // Yedek parça / otomotiv
  general,     // Genel perakende / girişimci
  technology,  // Elektronik / teknoloji
  footwear,    // Ayakkabı / tekstil
}

extension SectorTypeExt on SectorType {
  String get displayName => switch (this) {
        SectorType.autoParts   => 'Yedek Parçacı',
        SectorType.general     => 'Genel Perakende',
        SectorType.technology  => 'Teknoloji / Elektronik',
        SectorType.footwear    => 'Ayakkabı / Tekstil',
      };

  String get apiValue => switch (this) {
        SectorType.autoParts   => 'AUTO_PARTS',
        SectorType.general     => 'GENERAL',
        SectorType.technology  => 'TECHNOLOGY',
        SectorType.footwear    => 'FOOTWEAR',
      };

  static SectorType fromApi(String? value) {
    return switch (value?.toUpperCase()) {
      'AUTO_PARTS' || 'AUTOPARTS' || 'OTOMOTIV' => SectorType.autoParts,
      'TECHNOLOGY' || 'TECH' || 'ELEKTRONIK'    => SectorType.technology,
      'FOOTWEAR'   || 'TEKSTIL' || 'AYAKKABI'   => SectorType.footwear,
      _                                          => SectorType.general,
    };
  }
}

// ── Sektöre Özgü Etiketler ───────────────────────────────────────────────────
class SectorLabels {
  /// "Parça" / "Ürün" / "Cihaz" / "Model"
  final String productName;

  /// "Parça Grubu" / "Kategori" / "Ürün Tipi" / "Koleksiyon"
  final String categoryName;

  /// "OEM No" / (gizli) / "Seri No" / (gizli)
  final String oemField;

  /// "Raf Kodu" / "Depo Konumu" / "Raf" / "Raf"
  final String shelfField;

  /// "Araç Uyumu" / (gizli) / "Garanti Süresi" / "Numara/Beden"
  final String variantField;

  /// "Alış Fiyatı" aynı kalır, satış fiyatı farklılaşabilir
  final String salePriceLabel;

  /// Barkod alan başlığı
  final String barcodeLabel;

  /// Birim (adet / çift / kutu / cihaz)
  final String defaultUnit;

  const SectorLabels({
    required this.productName,
    required this.categoryName,
    required this.oemField,
    required this.shelfField,
    required this.variantField,
    required this.salePriceLabel,
    required this.barcodeLabel,
    required this.defaultUnit,
  });
}

// ── Alan Görünürlük Ayarları ──────────────────────────────────────────────────
class SectorFields {
  final bool showOem;           // OEM / Seri No alanı
  final bool oemRequired;
  final bool showVehicleCompat; // Araç uyumu (sadece parçacı)
  final bool showShelf;         // Raf konumu
  final bool shelfRequired;
  final bool showVariantSize;   // Beden / Numara (ayakkabı)
  final bool showVariantColor;  // Renk (ayakkabı / teknoloji)
  final bool showWarranty;      // Garanti süresi (teknoloji)
  final bool warrantyRequired;
  final bool showImei;          // IMEI (teknoloji)
  final bool showCrossRef;      // Çapraz referans (parçacı)
  final bool showBrand;         // Marka alanı
  final bool brandRequired;
  final bool showDescription;   // Açıklama
  final bool showMinStock;      // Minimum stok seviyesi
  final bool showOtv;           // ÖTV alanı (Sprint 2026-05-25 — AUTO_PARTS yaygın)

  const SectorFields({
    this.showOem = false,
    this.oemRequired = false,
    this.showVehicleCompat = false,
    this.showShelf = true,
    this.shelfRequired = false,
    this.showVariantSize = false,
    this.showVariantColor = false,
    this.showWarranty = false,
    this.warrantyRequired = false,
    this.showImei = false,
    this.showCrossRef = false,
    this.showBrand = true,
    this.brandRequired = false,
    this.showDescription = true,
    this.showMinStock = true,
    this.showOtv = false,
  });
}

// ── Ana Konfigürasyon Sınıfı ──────────────────────────────────────────────────
class SectorConfig {
  final SectorType type;
  final SectorLabels labels;
  final SectorFields fields;

  /// Toplu girişte barkod arama hint metni
  final String barcodeHint;

  /// Ürün ekleme wizard'ında ilk adım başlığı
  final String addProductTitle;

  /// Dashboard karşılama mesajı ek metni
  final String dashboardTagline;

  const SectorConfig({
    required this.type,
    required this.labels,
    required this.fields,
    required this.barcodeHint,
    required this.addProductTitle,
    required this.dashboardTagline,
  });

  // ── Fabrika metotlar ────────────────────────────────────────────────────────
  factory SectorConfig.autoParts() => const SectorConfig(
        type: SectorType.autoParts,
        barcodeHint: 'OEM no, barkod veya parça adı girin...',
        addProductTitle: 'Yeni Parça Ekle',
        dashboardTagline: 'Yedek Parça Yönetim Sistemi',
        labels: SectorLabels(
          productName:   'Parça',
          categoryName:  'Parça Grubu',
          oemField:      'OEM Numarası',
          shelfField:    'Raf Kodu',
          variantField:  'Araç Uyumu',
          salePriceLabel:'Satış Fiyatı',
          barcodeLabel:  'Barkod / OEM',
          defaultUnit:   'adet',
        ),
        fields: SectorFields(
          showOem:          true,
          oemRequired:      false,
          showVehicleCompat:true,
          showShelf:        true,
          shelfRequired:    true,
          showCrossRef:     true,
          showBrand:        true,
          brandRequired:    true,
          showMinStock:     true,
          showOtv:          true, // AUTO_PARTS: ÖTV genellikle aktif
        ),
      );

  factory SectorConfig.general() => const SectorConfig(
        type: SectorType.general,
        barcodeHint: 'Barkod okutun veya ürün adı girin...',
        addProductTitle: 'Yeni Ürün Ekle',
        dashboardTagline: 'Perakende Yönetim Sistemi',
        labels: SectorLabels(
          productName:   'Ürün',
          categoryName:  'Kategori',
          oemField:      'Referans No',
          shelfField:    'Depo Konumu',
          variantField:  'Varyant',
          salePriceLabel:'Satış Fiyatı',
          barcodeLabel:  'Barkod',
          defaultUnit:   'adet',
        ),
        fields: SectorFields(
          showOem:   false,
          showShelf: true,
          showBrand: true,
        ),
      );

  factory SectorConfig.technology() => const SectorConfig(
        type: SectorType.technology,
        barcodeHint: 'IMEI, seri no veya ürün adı girin...',
        addProductTitle: 'Yeni Cihaz / Ürün Ekle',
        dashboardTagline: 'Teknoloji Ürünleri Yönetim Sistemi',
        labels: SectorLabels(
          productName:   'Cihaz / Ürün',
          categoryName:  'Ürün Tipi',
          oemField:      'Seri Numarası',
          shelfField:    'Raf',
          variantField:  'Garanti Süresi',
          salePriceLabel:'Satış Fiyatı',
          barcodeLabel:  'Barkod / IMEI',
          defaultUnit:   'cihaz',
        ),
        fields: SectorFields(
          showOem:          true,
          oemRequired:      false,
          showImei:         true,
          showWarranty:     true,
          warrantyRequired: false,
          showVariantColor: true,
          showShelf:        true,
          showBrand:        true,
          brandRequired:    true,
        ),
      );

  factory SectorConfig.footwear() => const SectorConfig(
        type: SectorType.footwear,
        barcodeHint: 'Barkod okutun veya model adı girin...',
        addProductTitle: 'Yeni Model Ekle',
        dashboardTagline: 'Ayakkabı & Tekstil Yönetim Sistemi',
        labels: SectorLabels(
          productName:   'Model',
          categoryName:  'Koleksiyon',
          oemField:      'Model Kodu',
          shelfField:    'Raf',
          variantField:  'Numara / Beden',
          salePriceLabel:'Satış Fiyatı',
          barcodeLabel:  'Barkod',
          defaultUnit:   'çift',
        ),
        fields: SectorFields(
          showVariantSize:  true,
          showVariantColor: true,
          showShelf:        true,
          showBrand:        true,
          brandRequired:    true,
          showOem:          false,
        ),
      );

  /// `sectorType` string'inden config üret
  static SectorConfig fromType(SectorType type) => switch (type) {
        SectorType.autoParts  => SectorConfig.autoParts(),
        SectorType.general    => SectorConfig.general(),
        SectorType.technology => SectorConfig.technology(),
        SectorType.footwear   => SectorConfig.footwear(),
      };
}
