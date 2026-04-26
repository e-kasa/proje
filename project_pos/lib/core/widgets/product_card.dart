import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/sector_config.dart';
import '../theme/app_colors.dart';
import '../utils/i18n_helper.dart';
import 'app_badge.dart';

/// Sprint 12 — POS + Inventory için ortak ürün kartı.
///
/// Mode'a göre 3 layout: [posSale] (sepete ekleme grid),
/// [inventoryListView] (yatay row), [inventoryGridView] (dikey kart).
///
/// Sektör config'e göre OEM/variant/brand rozetleri otomatik gösterilir
/// veya gizlenir.
enum ProductCardMode { posSale, inventoryListView, inventoryGridView }

/// Karta render edilecek tüm veri tek struct.
///
/// Map'ten oluşturmak için [ProductCardData.fromMap] kullan.
class ProductCardData {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final double? price;
  final int stock;
  final String? brand;
  final String? categoryName;
  final String? imageUrl;
  final String? status; // ACTIVE | DRAFT | INACTIVE | OUT_OF_STOCK
  final int? minStockLevel; // null → app config default
  final String? oemNumber; // autoParts
  final String? variantSize; // footwear (numara/beden)
  final String? variantColor;
  final String? warranty; // technology
  // POS-spesifik:
  final int? myStoreStock;
  final bool availableElsewhere;

  const ProductCardData({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.price,
    this.stock = 0,
    this.brand,
    this.categoryName,
    this.imageUrl,
    this.status,
    this.minStockLevel,
    this.oemNumber,
    this.variantSize,
    this.variantColor,
    this.warranty,
    this.myStoreStock,
    this.availableElsewhere = false,
  });

  factory ProductCardData.fromMap(Map<String, dynamic> map) {
    return ProductCardData(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sku: map['sku']?.toString(),
      barcode: map['barcode']?.toString(),
      price: (map['sellingPrice'] as num?)?.toDouble() ??
          (map['basePrice'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble(),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      brand: map['brand']?.toString(),
      categoryName: map['categoryName']?.toString() ?? map['category']?.toString(),
      imageUrl: map['imageUrl']?.toString() ?? map['image']?.toString(),
      status: map['status']?.toString(),
      minStockLevel: (map['minStockLevel'] as num?)?.toInt(),
      oemNumber: map['oemNumber']?.toString() ?? map['oem']?.toString(),
      variantSize: map['variantSize']?.toString() ?? map['size']?.toString(),
      variantColor: map['variantColor']?.toString() ?? map['color']?.toString(),
      warranty: map['warranty']?.toString(),
      myStoreStock: (map['myStoreStock'] as num?)?.toInt(),
      availableElsewhere: map['availableElsewhere'] == true,
    );
  }
}

class ProductCard extends ConsumerWidget {
  final ProductCardMode mode;
  final ProductCardData data;
  final SectorConfig sector;
  final NumberFormat? currencyFormat;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  /// Stok eşiği — null ise [data.minStockLevel] veya default 5 kullanılır.
  final int? lowStockThreshold;

  const ProductCard({
    super.key,
    required this.mode,
    required this.data,
    required this.sector,
    this.currencyFormat,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
    this.lowStockThreshold,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    return switch (mode) {
      ProductCardMode.posSale => _buildPosSale(context, t),
      ProductCardMode.inventoryListView => _buildInventoryList(context, t),
      ProductCardMode.inventoryGridView => _buildInventoryGrid(context, t),
    };
  }

  // ── Hesaplanmış değerler ──────────────────────────────────────────────────

  int get _effectiveStock => data.myStoreStock ?? data.stock;

  bool get _isOutOfStock => _effectiveStock <= 0 && !data.availableElsewhere;

  bool get _isTransferOnly => _effectiveStock <= 0 && data.availableElsewhere;

  int get _threshold => lowStockThreshold ?? data.minStockLevel ?? 5;

  bool get _isLowStock => _effectiveStock > 0 && _effectiveStock <= _threshold;

  NumberFormat get _money =>
      currencyFormat ?? NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  // ── POS Sepete Ekleme Grid Kartı ──────────────────────────────────────────

  Widget _buildPosSale(BuildContext context, String Function(String) t) {
    final price = data.price ?? 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _isOutOfStock
                ? AppColors.bgLight.withValues(alpha: 0.7)
                : _isTransferOnly
                    ? AppColors.bgWarning.withValues(alpha: 0.3)
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isTransferOnly
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: thumbnail + isim + stok badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnail(36),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isOutOfStock
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildStockBadge(t),
                ],
              ),
              const Spacer(),
              // Sektör-spesifik rozet (OEM / beden / IMEI)
              ..._buildSectorBadges(),
              // Kategori chip
              if (data.categoryName != null && data.categoryName!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgInfo,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data.categoryName!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (data.sku != null && data.sku!.isNotEmpty)
                Text(
                  data.sku!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                _money.format(price),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _isOutOfStock
                      ? AppColors.textMuted
                      : _isTransferOnly
                          ? AppColors.warning
                          : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Inventory List Görünüm ────────────────────────────────────────────────

  Widget _buildInventoryList(BuildContext context, String Function(String) t) {
    final price = data.price ?? 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selectionMode) ...[
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
              ],
              _buildThumbnail(56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (data.sku != null && data.sku!.isNotEmpty)
                          Text(
                            data.sku!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        if (data.categoryName != null &&
                            data.categoryName!.isNotEmpty)
                          AppBadge(
                            text: data.categoryName!,
                            variant: BadgeVariant.info,
                          ),
                        ..._buildSectorBadges(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStockBadge(t),
                  const SizedBox(height: 8),
                  Text(
                    _money.format(price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Inventory Grid Görünüm ────────────────────────────────────────────────

  Widget _buildInventoryGrid(BuildContext context, String Function(String) t) {
    final price = data.price ?? 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildThumbnail(double.infinity, square: false),
                      if (selectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? AppColors.primary
                                : Colors.white,
                            size: 22,
                          ),
                        ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildStockBadge(t),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 4,
                        children: _buildSectorBadges(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _money.format(price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ortak Yardımcılar ─────────────────────────────────────────────────────

  Widget _buildThumbnail(dynamic size, {bool square = true}) {
    final hasImage = data.imageUrl != null && data.imageUrl!.isNotEmpty;
    if (hasImage) {
      // TODO(sprint12-w4): cached_network_image entegrasyonu — slow network
      // için placeholder + errorWidget. Şimdilik Image.network fallback.
      return Image.network(
        data.imageUrl!,
        width: square ? size : null,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildIconFallback(size),
      );
    }
    return _buildIconFallback(size);
  }

  Widget _buildIconFallback(dynamic size) {
    final boxSize = size is double ? size : null;
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: _isOutOfStock
            ? AppColors.bgLight
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: boxSize != null && boxSize.isFinite ? boxSize / 2 : 24,
        color: _isOutOfStock ? AppColors.textMuted : AppColors.primary,
      ),
    );
  }

  Widget _buildStockBadge(String Function(String) t) {
    if (_isOutOfStock) {
      return AppBadge.danger(t('stock.depleted'));
    }
    if (_isTransferOnly) {
      return AppBadge.warning(t('stock.in_transit'));
    }
    if (_isLowStock) {
      return AppBadge.warning('$_effectiveStock');
    }
    return AppBadge.success('$_effectiveStock');
  }

  /// Sektör config'e göre OEM/beden/renk/garanti rozetleri.
  List<Widget> _buildSectorBadges() {
    final badges = <Widget>[];
    if (sector.fields.showOem &&
        data.oemNumber != null &&
        data.oemNumber!.isNotEmpty) {
      badges.add(AppBadge(
        text: data.oemNumber!,
        variant: BadgeVariant.secondary,
        icon: Icons.tag,
      ));
    }
    if (sector.fields.showVariantSize &&
        data.variantSize != null &&
        data.variantSize!.isNotEmpty) {
      badges.add(AppBadge(
        text: data.variantSize!,
        variant: BadgeVariant.info,
        icon: Icons.straighten,
      ));
    }
    if (sector.fields.showVariantColor &&
        data.variantColor != null &&
        data.variantColor!.isNotEmpty) {
      badges.add(AppBadge(
        text: data.variantColor!,
        variant: BadgeVariant.secondary,
      ));
    }
    if (sector.fields.showWarranty &&
        data.warranty != null &&
        data.warranty!.isNotEmpty) {
      badges.add(AppBadge(
        text: data.warranty!,
        variant: BadgeVariant.info,
        icon: Icons.shield_outlined,
      ));
    }
    return badges;
  }
}
