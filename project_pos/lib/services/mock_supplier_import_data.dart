import '../models/supplier_import_models.dart';

/// Backend'den gelecek tedarikçi import verisi - MOCK
class MockSupplierImportData {
  static SupplierImportResponse getMockSupplierImport() {
    return SupplierImportResponse(
      productCount: 4,
      products: [
        // 1. TEDARİKÇİ: "kod gömlek" - 2 benzer ürün bulundu
        SupplierProductItem(
          readProductName: 'kod gömlek',
          readStock: 5,
          readPrice: 150.00,
          readBarcode: '8699018449926',
          readBrand: 'Adidas',
          forProduct: [
            // Benzer Ürün 1: kot gömlek
            SystemProduct(
              productId: 'prod-123',
              sku: 'SKU-520856579',
              name: 'kot gömlek',
              slug: 'kot-gomlek',
              categoryId: '4708c8ba-ee15-4924-a810-bb8acaafaa21',
              brand: 'adidas',
              unit: 'Adet',
              description: 'Erkek kot gömlek',
              variants: [
                ProductVariant(
                  variantId: 'var-001',
                  sku: 'PROD-KIR-3917',
                  name: 'Kırmızı',
                  attributes: {'Renk': 'Kırmızı'},
                  pricing: VariantPricing(
                    purchasePrice: 140.00,
                    salePrice: 200.00,
                    taxRate: 18.0,
                  ),
                  initialStocks: [
                    VariantStock(
                      storeId: 'store-1',
                      warehouseId: 'WH-001',
                      quantity: 10,
                    ),
                  ],
                  barcodes: [
                    VariantBarcode(
                      code: '8699018449926',
                      type: 'EAN13',
                      primary: true,
                    ),
                  ],
                ),
                ProductVariant(
                  variantId: 'var-002',
                  sku: 'PROD-SIY-3917',
                  name: 'Siyah',
                  attributes: {'Renk': 'Siyah'},
                  pricing: VariantPricing(
                    purchasePrice: 140.00,
                    salePrice: 200.00,
                    taxRate: 18.0,
                  ),
                  initialStocks: [
                    VariantStock(
                      storeId: 'store-1',
                      warehouseId: 'WH-001',
                      quantity: 8,
                    ),
                  ],
                  barcodes: [
                    VariantBarcode(
                      code: '8699116620551',
                      type: 'EAN13',
                      primary: true,
                    ),
                  ],
                ),
              ],
            ),
            // Benzer Ürün 2: Kot Gömlek XL
            SystemProduct(
              productId: 'prod-456',
              sku: 'SKU-789456',
              name: 'Kot Gömlek XL',
              slug: 'kot-gomlek-xl',
              categoryId: '4708c8ba-ee15-4924-a810-bb8acaafaa21',
              brand: 'Nike',
              unit: 'Adet',
              description: 'Büyük beden kot gömlek',
              variants: [
                ProductVariant(
                  variantId: 'var-003',
                  sku: 'PROD-MAVI-789',
                  name: 'Mavi',
                  attributes: {'Renk': 'Mavi', 'Beden': 'XL'},
                  pricing: VariantPricing(
                    purchasePrice: 160.00,
                    salePrice: 220.00,
                    taxRate: 18.0,
                  ),
                  initialStocks: [
                    VariantStock(
                      storeId: 'store-1',
                      warehouseId: 'WH-001',
                      quantity: 5,
                    ),
                  ],
                  barcodes: [
                    VariantBarcode(
                      code: '8699018449999',
                      type: 'EAN13',
                      primary: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // 2. TEDARİKÇİ: "spor ayakkabı" - 1 benzer ürün
        SupplierProductItem(
          readProductName: 'spor ayakkabı',
          readStock: 12,
          readPrice: 450.00,
          readBarcode: '8699118888888',
          readBrand: 'Nike',
          forProduct: [
            SystemProduct(
              productId: 'prod-777',
              sku: 'SKU-SPORT-123',
              name: 'Spor Ayakkabı Air Max',
              slug: 'spor-ayakkabi-air-max',
              categoryId: 'cat-shoes-123',
              brand: 'Nike',
              unit: 'Çift',
              description: 'Nike Air Max spor ayakkabı',
              variants: [
                ProductVariant(
                  variantId: 'var-shoe-001',
                  sku: 'SHOE-42-BLK',
                  name: '42 Numara Siyah',
                  attributes: {'Renk': 'Siyah', 'Numara': '42'},
                  pricing: VariantPricing(
                    purchasePrice: 420.00,
                    salePrice: 600.00,
                    taxRate: 18.0,
                  ),
                  initialStocks: [
                    VariantStock(
                      storeId: 'store-1',
                      warehouseId: 'WH-001',
                      quantity: 3,
                    ),
                  ],
                  barcodes: [
                    VariantBarcode(
                      code: '8699118888888',
                      type: 'EAN13',
                      primary: true,
                    ),
                  ],
                ),
                ProductVariant(
                  variantId: 'var-shoe-002',
                  sku: 'SHOE-43-WHT',
                  name: '43 Numara Beyaz',
                  attributes: {'Renk': 'Beyaz', 'Numara': '43'},
                  pricing: VariantPricing(
                    purchasePrice: 420.00,
                    salePrice: 600.00,
                    taxRate: 18.0,
                  ),
                  initialStocks: [
                    VariantStock(
                      storeId: 'store-1',
                      warehouseId: 'WH-001',
                      quantity: 5,
                    ),
                  ],
                  barcodes: [
                    VariantBarcode(
                      code: '8699118888889',
                      type: 'EAN13',
                      primary: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // 3. TEDARİKÇİ: "iPhone 15 Pro" - Sistemde YOK (yeni ürün)
        SupplierProductItem(
          readProductName: 'iPhone 15 Pro 256GB',
          readStock: 8,
          readPrice: 45000.00,
          readBarcode: '1234567890123',
          readBrand: 'Apple',
          forProduct: [], // BOŞ - Sistemde benzer ürün yok
        ),

        // 4. TEDARİKÇİ: "Samsung Kulaklık" - 2 benzer ürün
        SupplierProductItem(
          readProductName: 'Samsung Kulaklık',
          readStock: 20,
          readPrice: 250.00,
          readBarcode: '8699119999999',
          readBrand: 'Samsung',
          readCategory: 'Elektronik',
          forProduct: [
            SystemProduct(
              productId: 'prod-888',
              sku: 'SKU-SAMS-EAR-001',
              name: 'Samsung Galaxy Buds Pro',
              slug: 'samsung-galaxy-buds-pro',
              categoryId: 'cat-electronics-456',
              brand: 'Samsung',
              unit: 'Adet',
              description: 'Samsung kablosuz kulaklık',
              variants: [
                ProductVariant(
                  variantId: 'var-ear-001',
                  sku: 'BUDS-BLK',
                  name: 'Siyah',
                  attributes: {'Renk': 'Siyah'},
                  pricing: VariantPricing(
                    purchasePrice: 230.00,
                    salePrice: 350.00,
                    taxRate: 18.0,
                  ),
                  initialStocks: [
                    VariantStock(
                      storeId: 'store-1',
                      warehouseId: 'WH-001',
                      quantity: 15,
                    ),
                  ],
                  barcodes: [
                    VariantBarcode(
                      code: '8699119999999',
                      type: 'EAN13',
                      primary: true,
                    ),
                  ],
                ),
              ],
            ),
            SystemProduct(
              productId: 'prod-999',
              sku: 'SKU-SAMS-EAR-002',
              name: 'Samsung AKG Kulaklık',
              slug: 'samsung-akg-kulaklik',
              categoryId: 'cat-electronics-456',
              brand: 'Samsung',
              unit: 'Adet',
              description: 'Samsung AKG kablolu kulaklık',
              variants: [
                ProductVariant(
                  variantId: 'var-ear-002',
                  sku: 'AKG-WHT',
                  name: 'Beyaz',
                  attributes: {'Renk': 'Beyaz'},
                  pricing: VariantPricing(
                    purchasePrice: 50.00,
                    salePrice: 80.00,
                    taxRate: 18.0,
                  ),
                  initialStocks: [
                    VariantStock(
                      storeId: 'store-1',
                      warehouseId: 'WH-001',
                      quantity: 50,
                    ),
                  ],
                  barcodes: [
                    VariantBarcode(
                      code: '8699119999998',
                      type: 'EAN13',
                      primary: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
