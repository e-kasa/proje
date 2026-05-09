# 🚀 POS Tasarım İyileştirmesi - Başlangıç Kılavuzu

**Durum:** ✅ Aşama 1 Tamamlandı | Aşama 2'ye Hazır

---

## 📦 Oluşturulan Dosyalar (Aşama 1)

```
lib/theme/
├── ✅ app_colors.dart          (Light/Dark renk paleti)
├── ✅ app_typography.dart      (Yazı tipi stilleri)
├── ✅ app_spacing.dart         (8px grid spacing)
├── ✅ breakpoints.dart         (Responsive breakpoint'ler)
└── ✅ theme_provider.dart      (Riverpod theme yönetimi)
```

### Ne Yaptığımız

1. **app_colors.dart**
   - Light mode: 15+ renk (primary, success, warning, danger, neutral, etc.)
   - Dark mode: Tüm renklerin dark versiyonu
   - Theme-aware getters (context ile otomatik renk seçimi)

2. **app_typography.dart**
   - 6 headline stili (H1-H6)
   - 3 body text stili (Large, Medium, Small)
   - 3 label stili + caption
   - Special styles (price, button, badge, product)

3. **app_spacing.dart**
   - 8px grid system (4, 8, 16, 24, 32, 48, 64, 80, 96)
   - Component-specific spacing (button, card, modal, etc.)
   - Pre-made EdgeInsets & BorderRadius constants

4. **breakpoints.dart**
   - 3 breakpoint kategorisi (Mobile <768, Tablet 768-1199, Desktop 1200+)
   - ResponsiveHelper class (isMobile, isTablet, isDesktop)
   - Layout-specific helpers (getProductGridColumns, getCartPanelWidth, etc.)
   - MediaQuery extension (context.isMobile, context.isDesktop)

5. **theme_provider.dart**
   - ThemeModeNotifier (Light/Dark mode toggle)
   - createLightTheme() & createDarkTheme()
   - Material 3 tasarım sistemi (Material You)
   - Tüm komponentin (Button, TextField, Card, Dialog) teması

---

## 🎯 Aşama 2: Hemen Yapılacaklar (2-3 hafta)

### Adım 1: Main'de Theme'i Kullan

**Dosya:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'POS',
      theme: createLightTheme(),
      darkTheme: createDarkTheme(),
      themeMode: themeMode,
      home: const HomeScreen(), // Mevcut ana ekran
    );
  }
}
```

### Adım 2: Responsive Layout'a Başla

**Dosya:** `lib/screens/pos/pos_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../theme/breakpoints.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive layout seç
    if (context.isDesktop) {
      return _DesktopLayout();
    } else if (context.isTablet) {
      return _TabletLayout();
    } else {
      return _MobileLayout();
    }
  }

  // Desktop: 70/30 panel
  Widget _DesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 70,
          child: _ProductPanel(),
        ),
        Expanded(
          flex: 30,
          child: _CartPanel(),
        ),
      ],
    );
  }

  // Tablet: 60/40 atau stack
  Widget _TabletLayout() {
    return Column(
      children: [
        Expanded(
          child: _ProductPanel(),
        ),
        Expanded(
          child: _CartPanel(),
        ),
      ],
    );
  }

  // Mobile: Tabbed veya FAB + bottom sheet
  Widget _MobileLayout() {
    return _ProductPanel(); // + FAB with bottom sheet
  }

  Widget _ProductPanel() => const Placeholder();
  Widget _CartPanel() => const Placeholder();
}
```

### Adım 3: Ürün Grid'i Responsive Yap

**Dosya:** `lib/screens/pos/widgets/product_grid.dart`

```dart
import 'package:flutter/material.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/app_spacing.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;

  const ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.getProductGridColumns(context);
    final gap = ResponsiveHelper.getGridGap(context);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}
```

### Adım 4: Ürün Kartını Modernize Et

**Dosya:** `lib/screens/pos/widgets/product_card.dart`

```dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          // Ürünü sepete ekle veya varyant seç
        },
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: _isHovered ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.radiusLG,
              side: BorderSide(
                color: _isHovered 
                  ? AppColors.primary 
                  : AppColors.getBorder(context),
              ),
            ),
            child: Padding(
              padding: AppSpacing.paddingMD,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stock Badge
                  Align(
                    alignment: Alignment.topRight,
                    child: _StockBadge(widget.product.stock),
                  ),

                  SizedBox(height: AppSpacing.sm),

                  // Product Icon/Image
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.radiusMD,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.shopping_bag),
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Product Name (clamped to 2 lines)
                  Text(
                    widget.product.name,
                    style: AppTypography.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: AppSpacing.xs),

                  // SKU
                  Text(
                    'SKU: ${widget.product.sku}',
                    style: AppTypography.productSku.copyWith(
                      color: AppColors.getTextTertiary(context),
                    ),
                  ),

                  SizedBox(height: AppSpacing.sm),

                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: AppSpacing.radiusSM,
                    ),
                    child: Text(
                      widget.product.category,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Price
                  Text(
                    '₺${widget.product.price.toStringAsFixed(2)}',
                    style: AppTypography.price.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;

  const _StockBadge(this.stock);

  @override
  Widget build(BuildContext context) {
    late Color bgColor;
    late Color textColor;
    String label;

    if (stock > 10) {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      label = 'Stok: $stock';
    } else if (stock > 0) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
      label = 'Az: $stock';
    } else {
      bgColor = AppColors.dangerLight;
      textColor = AppColors.danger;
      label = 'Tükendi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.radiusSM,
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(color: textColor),
      ),
    );
  }
}
```

---

## ✅ Kontrol Listesi - Aşama 2

- [ ] `lib/main.dart`'da theme provider'ı import et
- [ ] MaterialApp'e createLightTheme() ve createDarkTheme() ekle
- [ ] `pos_screen.dart`'ı responsive layout'a refactor et
- [ ] ResponsiveHelper'ı import et ve kullan
- [ ] Product grid'i responsive columns ile düzenle
- [ ] ProductCard'ı modernize et (colors, spacing, elevation)
- [ ] Stock badge'ini renk kodu ile tasarla
- [ ] Hover/press states ekle
- [ ] Desktop 1920×1080'de test et
- [ ] Tablet 1024×768'de test et
- [ ] Mobil 375×812'de test et

---

## 🔧 Faydalı Komutlar

```bash
# Kod formatını düzenle
flutter format lib/

# Lint kontrol et
flutter analyze lib/

# Tüm dosyaları kontrol et
dart fix --apply lib/

# Belirtilen genişlikte test et
flutter run -d chrome --web-renderer=canvaskit
```

---

## 🎨 Renk Kullanımı

```dart
// Light mode (otomatik)
Text('Merhaba', style: TextStyle(
  color: AppColors.lightTextPrimary,
))

// Theme-aware (tavsiye edilen)
Text('Merhaba', style: TextStyle(
  color: AppColors.getTextPrimary(context),
))

// Material 3 color scheme
Container(
  color: Theme.of(context).colorScheme.primary,
)
```

---

## 📱 Responsive Kullanımı

```dart
// Simple check
if (context.isMobile) {
  // Mobile layout
} else if (context.isTablet) {
  // Tablet layout
} else {
  // Desktop layout
}

// Helper method
int columns = ResponsiveHelper.getProductGridColumns(context);

// Extension
double width = context.screenWidth;
bool isLandscape = context.isLandscape;
```

---

## 🎯 Sonraki Hedefler

1. ✅ **Aşama 1:** Design System kurulumu
2. 🔄 **Aşama 2:** Responsive layout (Şu an buradayız)
3. ⏳ **Aşama 3:** UX & Animasyonlar
4. ⏳ **Aşama 4:** Widget Refinement
5. ⏳ **Aşama 5:** Testing & QA

---

## 📞 Destek & Sorular

- Renk seçimi: `lib/theme/app_colors.dart`
- Spacing: `lib/theme/app_spacing.dart`
- Responsive: `lib/theme/breakpoints.dart`
- Typography: `lib/theme/app_typography.dart`

---

**Başarı! 🎉 Aşama 1 tamamlandı. Aşama 2'ye başlamaya hazır mısınız?**

Bir sonraki adım: `pos_screen.dart`'ı responsive layout'a refactor etmek.
