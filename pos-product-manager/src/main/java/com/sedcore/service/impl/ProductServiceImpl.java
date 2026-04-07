package com.sedcore.service.impl;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.sedcore.entity.Barcode;
import com.sedcore.entity.Category;
import com.sedcore.entity.CrossReference;
import com.sedcore.entity.OemNumber;
import com.sedcore.entity.Supplier;
import com.sedcore.entity.VariantPricing;
import com.sedcore.entity.InventoryView;
import com.sedcore.entity.Product;
import com.sedcore.entity.ProductVariant;
import com.sedcore.entity.Purchase;
import com.sedcore.entity.StockMovement;
import com.sedcore.enums.BarcodeType;
import com.sedcore.enums.ProductStatus;
import com.sedcore.enums.StockMovementType;
import com.sedcore.model.BarcodeRequest;
import com.sedcore.model.BarcodeResponse;
import com.sedcore.model.CreateProductRequest;
import com.sedcore.model.CrossReferenceRequest;
import com.sedcore.model.InitialStocksRequest;
import com.sedcore.model.InventoryResponse;
import com.sedcore.model.OemNumberRequest;
import com.sedcore.model.ProductResponse;
import com.sedcore.model.ProductVariantRequest;
import com.sedcore.model.ProductVariantResponse;
import com.sedcore.repository.BarcodeRepository;
import com.sedcore.repository.CategoryRepository;
import com.sedcore.repository.ProductRepository;
import com.sedcore.repository.ProductVariantRepository;
import com.sedcore.repository.SupplierRepository;
import com.sedcore.service.BarcodeService;
import com.sedcore.service.CategoryService;
import com.sedcore.service.SupplierService;
import com.sedcore.service.InventoryService;
import com.sedcore.service.PricingService;
import com.sedcore.service.ProductService;
import com.sedcore.service.OemNumberService;
import com.sedcore.service.CrossReferenceService;
import com.sedcore.service.ProductVariantAttributeValueService;
import com.sedcore.service.ProductVariantService;
import com.sedcore.service.PurchaseService;
import com.sedcore.service.StockMovementService;
import com.towpen.base.security.BaseDbServiceImp;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;


@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ProductServiceImpl extends BaseDbServiceImp<ProductRepository, Product> implements ProductService {

    private final ProductVariantService variantService;
    private final ProductRepository productRepository;
    private final SupplierService supplierService;
    private final PurchaseService purchaseService;
    private final PricingService pricingService;
    private final StockMovementService stockMovementService;
    private final BarcodeService barcodeService;
    private final CategoryService categoryService;
    private final InventoryService inventoryService;
    private final OemNumberService oemNumberService;
    private final CrossReferenceService crossReferenceService;

    /**
     * Ürün Oluştur (Tüm Detaylarıyla)
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public ProductResponse createProduct(CreateProductRequest dto) {
        log.info("Ürün oluşturuluyor: name={}", dto.getProduct().getName());

        // 1. Product entity oluştur
        Product product = Product.builder()
                .sku(dto.getProduct().getSku())
                .name(dto.getProduct().getName())
                .brand(dto.getProduct().getBrand())
                .unit(dto.getProduct().getUnit())
                .categoryId(dto.getProduct().getCategoryId())
                .description(dto.getProduct().getDescription())
                .sector(dto.getProduct().getSector())
                .metadata(dto.getProduct().getMetadata())
                .status(ProductStatus.ACTIVE)
                .isDeleted(false)
                .build();

        // 2. Product'ı kaydet (variants'tan önce - FK constraint için)
        product = save(product);
        log.info("Ürün kaydedildi: id={}", product.getId());

        // 3. PURCHASE
        Purchase purchase = null;
        if (dto.getPurchase() != null) {
            Supplier supplier = supplierService
                    .findById(dto.getPurchase().getSupplierId())
                    .orElseThrow(() -> new RuntimeException("Tedarikçi bulunamadı: " + dto.getPurchase().getSupplierId()));

            // Toplam tutarı variant fiyat * adet üzerinden hesapla
            BigDecimal totalAmount = BigDecimal.ZERO;
            if (dto.getVariants() != null) {
                for (ProductVariantRequest v : dto.getVariants()) {
                    BigDecimal price = (v.getPricing() != null && v.getPricing().getPurchasePrice() != null)
                            ? v.getPricing().getPurchasePrice()
                            : BigDecimal.ZERO;
                    int qty = 0;
                    if (v.getInitialStocks() != null) {
                        for (InitialStocksRequest stock : v.getInitialStocks()) {
                            qty += stock.getQuantity();
                        }
                    }
                    totalAmount = totalAmount.add(price.multiply(BigDecimal.valueOf(qty)));
                }
            }

            purchase = new Purchase();
            purchase.setSupplier(supplier);
            purchase.setInvoiceNumber(dto.getPurchase().getInvoiceNumber());
            purchase.setPurchaseDate(dto.getPurchase().getPurchaseDate());
            purchase.setTotalAmount(totalAmount);
            purchase.setPaidAmount(BigDecimal.ZERO);
            purchase.setIsCancelled(false);
            purchaseService.save(purchase);
        }

        // 4. VARIANTS
        if (dto.getVariants() != null) {
            for (ProductVariantRequest v : dto.getVariants()) {
                ProductVariant variant = new ProductVariant();
                variant.setSku(v.getSku());
                variant.setName(v.getName());
                variant.setAttributes(v.getAttributes());
                variant.setProduct(product);
                // Raf konumu (oto parça için)
                if (v.getShelfLocationCode() != null && !v.getShelfLocationCode().isBlank()) {
                    variant.setShelfLocationCode(v.getShelfLocationCode());
                }
                variantService.save(variant);

                // PRICING
                if (v.getPricing() != null) {
                    VariantPricing pricing = new VariantPricing();
                    pricing.setVariant(variant);
                    pricing.setPurchasePrice(v.getPricing().getPurchasePrice());
                    pricing.setSalePrice(v.getPricing().getSalePrice());
                    // Vergi alanları
                    pricing.setVatRate(v.getPricing().getVatRate() != null ? v.getPricing().getVatRate() : BigDecimal.ZERO);
                    pricing.setVatIncluded(v.getPricing().getVatIncluded() != null ? v.getPricing().getVatIncluded() : false);
                    pricing.setSpecialTaxRate(v.getPricing().getSpecialTaxRate());
                    pricing.setWithholdingTaxRate(v.getPricing().getWithholdingTaxRate());
                    pricing.setTaxExempt(v.getPricing().getTaxExempt() != null ? v.getPricing().getTaxExempt() : false);
                    pricingService.save(pricing);
                }

                // BARCODES
                if (v.getBarcodes() != null) {
                    for (BarcodeRequest b : v.getBarcodes()) {
                        Barcode barcode = new Barcode();
                        barcode.setBarcodeCode(b.getCode());
                        barcode.setBarcodeType(b.getType() != null ? b.getType() : BarcodeType.CODE128);
                        barcode.setIsPrimary(b.getIsPrimary() != null ? b.getIsPrimary() : false);
                        barcode.setIsActive(true);
                        barcode.setUsageCount(0L);
                        barcode.setVariant(variant);
                        barcodeService.save(barcode);
                    }
                }

                // INITIAL STOCK → STOCK MOVEMENT
                if (v.getInitialStocks() != null) {
                    for (InitialStocksRequest stock : v.getInitialStocks()) {
                        StockMovement sm = new StockMovement();
                        sm.setVariant(variant);
                        sm.setStoreId(stock.getStoreId());
                        sm.setWarehouseId(stock.getWarehouseId());
                        sm.setMovementType(StockMovementType.PURCHASE_IN);
                        sm.setQuantity(stock.getQuantity());
                        sm.setPurchase(purchase);
                        stockMovementService.save(sm);
                    }
                }
            }
        }

        // 5. OEM NUMBERS — ilk varyanta bağla (parçacı sektörü)
        if (dto.getOemNumbers() != null && !dto.getOemNumbers().isEmpty()) {
            ProductVariant firstVariant = product.getVariants() != null && !product.getVariants().isEmpty()
                    ? product.getVariants().get(0)
                    : null;
            if (firstVariant == null) {
                // Varyantları DB'den yeniden yükle
                Product reloaded = productRepository.findById(product.getId()).orElse(product);
                firstVariant = reloaded.getVariants() != null && !reloaded.getVariants().isEmpty()
                        ? reloaded.getVariants().get(0) : null;
            }
            if (firstVariant != null) {
                for (OemNumberRequest oemReq : dto.getOemNumbers()) {
                    if (oemReq.getOemNumber() == null || oemReq.getOemNumber().isBlank()) continue;
                    OemNumber oem = OemNumber.builder()
                            .variant(firstVariant)
                            .oemNumber(oemReq.getOemNumber())
                            .manufacturer(oemReq.getManufacturer())
                            .isPrimary(oemReq.getIsPrimary() != null ? oemReq.getIsPrimary() : false)
                            .build();
                    oemNumberService.save(oem);
                }
                log.info("OEM numaraları kaydedildi: {} adet", dto.getOemNumbers().size());
            }
        }

        // 6. CROSS REFERENCES — ilk varyanta bağla
        if (dto.getCrossReferences() != null && !dto.getCrossReferences().isEmpty()) {
            ProductVariant firstVariant = product.getVariants() != null && !product.getVariants().isEmpty()
                    ? product.getVariants().get(0)
                    : null;
            if (firstVariant == null) {
                Product reloaded = productRepository.findById(product.getId()).orElse(product);
                firstVariant = reloaded.getVariants() != null && !reloaded.getVariants().isEmpty()
                        ? reloaded.getVariants().get(0) : null;
            }
            if (firstVariant != null) {
                for (CrossReferenceRequest crReq : dto.getCrossReferences()) {
                    if (crReq.getCrossRefNumber() == null || crReq.getCrossRefNumber().isBlank()) continue;
                    CrossReference cr = CrossReference.builder()
                            .variant(firstVariant)
                            .crossRefNumber(crReq.getCrossRefNumber())
                            .crossRefBrand(crReq.getCrossRefBrand())
                            .notes(crReq.getNotes())
                            .build();
                    crossReferenceService.save(cr);
                }
                log.info("Çapraz referanslar kaydedildi: {} adet", dto.getCrossReferences().size());
            }
        }

        log.info("Ürün başarıyla oluşturuldu: id={}, name={}", product.getId(), product.getName());
        return mapToResponse(product);
    }

    /**
     * Ürün Güncelle
     */
    public ProductResponse updateProduct(String id, CreateProductRequest dto) {
        log.info("Ürün güncelleniyor: id={}", id);

        Product product = productRepository.findByIdAndIsDeleted(id, false)
                .orElseThrow(() -> new RuntimeException("Ürün bulunamadı: " + id));

        if (dto.getProduct() != null) {
            if (dto.getProduct().getName() != null) product.setName(dto.getProduct().getName());
            if (dto.getProduct().getBrand() != null) product.setBrand(dto.getProduct().getBrand());
            if (dto.getProduct().getUnit() != null) product.setUnit(dto.getProduct().getUnit());
            if (dto.getProduct().getCategoryId() != null) product.setCategoryId(dto.getProduct().getCategoryId());
            if (dto.getProduct().getSku() != null) product.setSku(dto.getProduct().getSku());
            if (dto.getProduct().getDescription() != null) product.setDescription(dto.getProduct().getDescription());
            if (dto.getProduct().getSector() != null) product.setSector(dto.getProduct().getSector());
            if (dto.getProduct().getMetadata() != null) product.setMetadata(dto.getProduct().getMetadata());
        }

        product = save(product);
        log.info("Ürün güncellendi: id={}", product.getId());
        return mapToResponse(product);
    }

    /**
     * Ürün Pasife Al (Soft Delete)
     */
    public void deactivateProduct(String id) {
        log.info("Ürün pasife alınıyor: id={}", id);
        Product product = productRepository.findByIdAndIsDeleted(id, false)
                .orElseThrow(() -> new RuntimeException("Ürün bulunamadı: " + id));
        product.setStatus(ProductStatus.INACTIVE);
        save(product);
        log.info("Ürün pasife alındı: id={}", id);
    }

    /**
     * Ürün Sil (Soft Delete - isDeleted = true)
     */
    public void deleteProduct(String id) {
        log.info("Ürün siliniyor (soft): id={}", id);
        Product product = productRepository.findByIdAndIsDeleted(id, false)
                .orElseThrow(() -> new RuntimeException("Ürün bulunamadı: " + id));
        product.setIsDeleted(true);
        product.setStatus(ProductStatus.INACTIVE);
        save(product);
        log.info("Ürün silindi: id={}", id);
    }

    /**
     * Ürün Getir
     */
    @Transactional(readOnly = true)
    public ProductResponse getProduct(String id) {
        log.info("Ürün getiriliyor: id={}", id);
        Product product = productRepository.findByIdAndIsDeleted(id, false)
                .orElseThrow(() -> new RuntimeException("Ürün bulunamadı: " + id));
        return mapToResponse(product);
    }

    /**
     * Ürün Listele
     */
    @Transactional(readOnly = true)
    public Page<ProductResponse> listProducts(Pageable pageable) {
        Page<Product> products = productRepository.findByIsDeleted(false, pageable);
        return products.map(this::mapToResponse);
    }

    /**
     * Ürün Ara
     */
    @Transactional(readOnly = true)
    public Page<ProductResponse> searchProducts(String keyword, Pageable pageable) {
        log.info("Ürün aranıyor: keyword={}", keyword);
        Page<Product> products = productRepository.searchProducts(keyword, pageable);
        return products.map(this::mapToResponse);
    }

    /**
     * Slug oluştur veya validate et
     */
    private String generateOrValidateSlug(String inputSlug, String name) {
        String slug = inputSlug;

        if (slug == null || slug.trim().isEmpty()) {
            slug = name.toLowerCase()
                    .replaceAll("[^a-z0-9\\s-]", "")
                    .replaceAll("\\s+", "-")
                    .replaceAll("-+", "-")
                    .trim();
        }

        if (productRepository.existsBySlug(slug)) {
            slug = slug + "-" + System.currentTimeMillis();
        }

        return slug;
    }

    /**
     * Product Entity → ProductResponse mapping
     */
    private ProductResponse mapToResponse(Product product) {
        String categoryName = null;
        try {
            if (product.getCategoryId() != null) {
                Category category = categoryService.findById(product.getCategoryId()).orElse(null);
                if (category != null) categoryName = category.getName();
            }
        } catch (Exception e) {
            log.warn("Kategori bilgisi alınamadı: {}", product.getCategoryId());
        }

        // Varyantları map'le
        List<ProductVariantResponse> variantResponses = new ArrayList<>();
        if (product.getVariants() != null && !product.getVariants().isEmpty()) {
            variantResponses = product.getVariants().stream()
                    .filter(v -> !Boolean.TRUE.equals(v.getIsDeleted()))
                    .map(this::mapVariantToResponse)
                    .toList();
        }

        // basePrice: ilk varyantın salePrice'ından al, yoksa 0
        BigDecimal basePrice = BigDecimal.ZERO;
        if (!variantResponses.isEmpty() && variantResponses.get(0).getSalePrice() != null) {
            basePrice = variantResponses.get(0).getSalePrice();
        }

        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .description(product.getDescription())
                .sector(product.getSector())
                .metadata(product.getMetadata())
                .categoryId(product.getCategoryId())
                .categoryName(categoryName)
                .brand(product.getBrand())
                .unit(product.getUnit())
                .sku(product.getSku())
                .basePrice(basePrice)
                .status(product.getStatus())
                .variants(variantResponses)
                .build();
    }

    /**
     * ProductVariant Entity → ProductVariantResponse mapping
     */
    private ProductVariantResponse mapVariantToResponse(ProductVariant variant) {
        // Barkodları map'le
        List<BarcodeResponse> barcodeResponses = new ArrayList<>();
        if (variant.getBarcodes() != null && !variant.getBarcodes().isEmpty()) {
            barcodeResponses = variant.getBarcodes().stream()
                    .filter(b -> Boolean.TRUE.equals(b.getIsActive()))
                    .map(b -> BarcodeResponse.builder()
                            .id(b.getId())
                            .barcodeCode(b.getBarcodeCode())
                            .barcodeType(b.getBarcodeType() != null ? b.getBarcodeType().name() : null)
                            .isPrimary(b.getIsPrimary())
                            .isActive(b.getIsActive())
                            .usageCount(b.getUsageCount())
                            .build())
                    .toList();
        }

        // Inventory: InventoryView'dan tüm depoları topla
        InventoryResponse inventoryResponse = null;
        try {
            List<InventoryView> inventories = inventoryService.findByVariantIdSafe(variant.getId());
            if (!inventories.isEmpty()) {
                int totalQty = inventories.stream()
                        .mapToInt(iv -> iv.getPhysicalQuantity() != null ? iv.getPhysicalQuantity() : 0)
                        .sum();
                InventoryView first = inventories.get(0);
                inventoryResponse = InventoryResponse.builder()
                        .id(first.getId())
                        .variantId(first.getVariantId())
                        .warehouseId(first.getWarehouseId())
                        .storeId(first.getStoreId())
                        .physicalQuantity(totalQty)
                        .minStockLevel(variant.getMinStockLevel())
                        .build();
            }
        } catch (Exception e) {
            log.warn("Stok bilgisi alınamadı variant={}: {}", variant.getId(), e.getMessage());
        }

        // Pricing — variantPricings listesinden en son fiyat
        BigDecimal salePrice = null;
        if (variant.getVariantPricings() != null && !variant.getVariantPricings().isEmpty()) {
            salePrice = variant.getVariantPricings()
                    .get(variant.getVariantPricings().size() - 1)
                    .getSalePrice();
        }

        return ProductVariantResponse.builder()
                .id(variant.getId())
                .sku(variant.getSku())
                .name(variant.getName())
                .additionalPrice(variant.getAdditionalPrice())
                .salePrice(salePrice)
                .attributes(variant.getAttributes())
                .barcodes(barcodeResponses)
                .inventory(inventoryResponse)
                .build();
    }

    @Override
    public Class<?> getDTOClassForService() {
        return null;
    }
}