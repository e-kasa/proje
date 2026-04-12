package com.sedcore.product.service.impl;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.sedcore.product.entity.Barcode;
import com.sedcore.catalog.entity.Category;
import com.sedcore.autoparts.entity.CrossReference;
import com.sedcore.autoparts.entity.OemNumber;
import com.sedcore.supplier.entity.Supplier;
import com.sedcore.product.entity.VariantPricing;
import com.sedcore.inventory.entity.InventoryView;
import com.sedcore.product.entity.Product;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.purchase.entity.Purchase;
import com.sedcore.inventory.entity.StockMovement;
import com.sedcore.common.enums.BarcodeType;
import com.sedcore.common.enums.ProductStatus;
import com.sedcore.common.enums.StockMovementType;
import com.sedcore.product.model.BatchCreateRequest;
import com.sedcore.product.model.BatchCreateResponse;
import com.sedcore.product.model.BatchExistingItem;
import com.sedcore.product.model.BatchItemResult;
import com.sedcore.product.model.BatchProductItem;
import com.sedcore.product.model.BarcodeRequest;
import com.sedcore.product.model.BarcodeResponse;
import com.sedcore.product.model.CreateProductRequest;
import com.sedcore.autoparts.model.CrossReferenceRequest;
import com.sedcore.inventory.model.InitialStocksRequest;
import com.sedcore.inventory.model.InventoryResponse;
import com.sedcore.autoparts.model.OemNumberRequest;
import com.sedcore.product.model.ProductRequest;
import com.sedcore.product.model.ProductResponse;
import com.sedcore.product.model.ProductVariantRequest;
import com.sedcore.product.model.ProductVariantResponse;
import com.sedcore.product.repository.BarcodeRepository;
import com.sedcore.catalog.repository.CategoryRepository;
import com.sedcore.product.repository.ProductRepository;
import com.sedcore.product.repository.ProductVariantRepository;
import com.sedcore.supplier.repository.SupplierRepository;
import com.sedcore.product.service.BarcodeService;
import com.sedcore.catalog.service.CategoryService;
import com.sedcore.supplier.service.SupplierService;
import com.sedcore.inventory.service.InventoryService;
import com.sedcore.product.service.PricingService;
import com.sedcore.product.service.ProductService;
import com.sedcore.autoparts.service.OemNumberService;
import com.sedcore.autoparts.service.CrossReferenceService;
import com.sedcore.product.service.ProductVariantAttributeValueService;
import com.sedcore.product.service.ProductVariantService;
import com.sedcore.purchase.service.PurchaseService;
import com.sedcore.inventory.service.StockMovementService;
import com.towpen.base.security.BaseDbServiceImp;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
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

    // ─────────────────────────────────────────────────────────────────────────
    // TOPLU ÜRÜN GİRİŞİ
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Toplu ürün girişi — tek Purchase altında N yeni + M mevcut ürün.
     *
     * <p>Akış:
     * <ol>
     *   <li>Tedarikçi doğrulanır.</li>
     *   <li>Ortak Purchase başlığı oluşturulur (henüz totalAmount=0).</li>
     *   <li>Her yeni ürün bağımsız işlenir → başarılı/başarısız sonuç toplanır.</li>
     *   <li>Her mevcut ürün için StockMovement + SupplierAccount kaydı oluşturulur.</li>
     *   <li>Purchase.totalAmount güncellenir.</li>
     * </ol>
     */
    @Override
    @Transactional
    public BatchCreateResponse batchCreateProducts(BatchCreateRequest req) {
        log.info("Toplu ürün girişi başladı — yeni:{}, mevcut:{}",
                req.getNewProducts() != null ? req.getNewProducts().size() : 0,
                req.getExistingProducts() != null ? req.getExistingProducts().size() : 0);

        // 1. Tedarikçi
        Supplier supplier = supplierService.findById(req.getSupplierId())
                .orElseThrow(() -> new RuntimeException("Tedarikçi bulunamadı: " + req.getSupplierId()));

        // 2. Purchase başlığını oluştur
        Purchase purchase = new Purchase();
        purchase.setSupplier(supplier);
        purchase.setInvoiceNumber(req.getInvoiceNumber());
        if (req.getDeliveryNoteNumber() != null) {
            purchase.setDeliveryNoteNumber(req.getDeliveryNoteNumber());
        }
        purchase.setPurchaseDate(req.getPurchaseDate());
        purchase.setTotalAmount(BigDecimal.ZERO);
        purchase.setPaidAmount(BigDecimal.ZERO);
        purchase.setIsCancelled(false);
        purchaseService.save(purchase);
        log.info("Purchase oluşturuldu: id={}", purchase.getId());

        List<BatchItemResult> results = new ArrayList<>();
        BigDecimal totalAmount = BigDecimal.ZERO;

        // 3. Yeni ürünler
        if (req.getNewProducts() != null) {
            for (BatchProductItem item : req.getNewProducts()) {
                try {
                    // Mevcut createProduct mantığını yeniden kullan
                    CreateProductRequest cpr = CreateProductRequest.builder()
                            .product(item.getProduct())
                            .variants(item.getVariants())
                            .oemNumbers(item.getOemNumbers())
                            .crossReferences(item.getCrossReferences())
                            .build();

                    // Purchase referansını variant'lara ekle (StockMovement için)
                    if (item.getVariants() != null) {
                        for (ProductVariantRequest vr : item.getVariants()) {
                            if (vr.getInitialStocks() != null) {
                                for (var stock : vr.getInitialStocks()) {
                                    // storeId / warehouseId request'ten gelir
                                    if (stock.getStoreId() == null) {
                                        stock = com.sedcore.inventory.model.InitialStocksRequest.builder()
                                                .storeId(req.getStoreId())
                                                .warehouseId(req.getWarehouseId())
                                                .quantity(stock.getQuantity())
                                                .build();
                                    }
                                }
                            }
                        }
                    }

                    ProductResponse created = _createProductWithPurchase(cpr, purchase);

                    // Toplam tutara ekle
                    if (item.getVariants() != null) {
                        for (ProductVariantRequest vr : item.getVariants()) {
                            BigDecimal price = (vr.getPricing() != null && vr.getPricing().getPurchasePrice() != null)
                                    ? vr.getPricing().getPurchasePrice() : BigDecimal.ZERO;
                            int qty = 0;
                            if (vr.getInitialStocks() != null) {
                                for (var s : vr.getInitialStocks()) qty += s.getQuantity();
                            }
                            totalAmount = totalAmount.add(price.multiply(BigDecimal.valueOf(qty)));
                        }
                    }

                    String firstVariantId = (created.getVariants() != null && !created.getVariants().isEmpty())
                            ? created.getVariants().get(0).getId() : null;

                    results.add(BatchItemResult.builder()
                            .tempId(item.getTempId())
                            .success(true)
                            .productId(created.getId())
                            .variantId(firstVariantId)
                            .build());

                    log.info("Yeni ürün kaydedildi: tempId={}, productId={}", item.getTempId(), created.getId());

                } catch (Exception e) {
                    log.warn("Yeni ürün kaydedilemedi: tempId={}, hata={}", item.getTempId(), e.getMessage());
                    results.add(BatchItemResult.builder()
                            .tempId(item.getTempId())
                            .success(false)
                            .message(e.getMessage())
                            .build());
                }
            }
        }

        // 4. Mevcut ürünler (sadece stok + cari)
        if (req.getExistingProducts() != null) {
            for (BatchExistingItem item : req.getExistingProducts()) {
                try {
                    ProductVariant variant = variantService.findById(item.getVariantId())
                            .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + item.getVariantId()));

                    StockMovement sm = new StockMovement();
                    sm.setVariant(variant);
                    sm.setStoreId(req.getStoreId());
                    sm.setWarehouseId(req.getWarehouseId());
                    sm.setMovementType(StockMovementType.PURCHASE_IN);
                    sm.setQuantity(item.getQuantity());
                    sm.setPurchase(purchase);
                    stockMovementService.save(sm);

                    BigDecimal lineTotal = item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
                    totalAmount = totalAmount.add(lineTotal);

                    results.add(BatchItemResult.builder()
                            .tempId(item.getTempId())
                            .success(true)
                            .variantId(item.getVariantId())
                            .build());

                    log.info("Mevcut ürün stok güncellendi: tempId={}, variantId={}", item.getTempId(), item.getVariantId());

                } catch (Exception e) {
                    log.warn("Mevcut ürün işlenemedi: tempId={}, hata={}", item.getTempId(), e.getMessage());
                    results.add(BatchItemResult.builder()
                            .tempId(item.getTempId())
                            .success(false)
                            .message(e.getMessage())
                            .build());
                }
            }
        }

        // 5. Purchase toplam tutar güncelle
        purchase.setTotalAmount(totalAmount);
        purchaseService.save(purchase);
        log.info("Purchase toplam güncellendi: id={}, total={}", purchase.getId(), totalAmount);

        long successCount = results.stream().filter(BatchItemResult::isSuccess).count();
        long failCount = results.size() - successCount;

        log.info("Toplu giriş tamamlandı — başarılı:{}, başarısız:{}", successCount, failCount);

        return BatchCreateResponse.builder()
                .purchaseId(purchase.getId())
                .invoiceNumber(purchase.getInvoiceNumber())
                .successCount((int) successCount)
                .failCount((int) failCount)
                .totalAmount(totalAmount)
                .results(results)
                .build();
    }

    /**
     * createProduct mantığını Purchase referansıyla çalıştırır.
     * Purchase kaydını tekrar oluşturmaz — mevcut purchase'ı kullanır.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    private ProductResponse _createProductWithPurchase(CreateProductRequest dto, Purchase purchase) {
        // 1. Product entity
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
        product = save(product);

        // 2. Variants
        if (dto.getVariants() != null) {
            for (ProductVariantRequest v : dto.getVariants()) {
                ProductVariant variant = new ProductVariant();
                variant.setSku(v.getSku());
                variant.setName(v.getName());
                variant.setAttributes(v.getAttributes());
                variant.setProduct(product);
                if (v.getShelfLocationCode() != null && !v.getShelfLocationCode().isBlank()) {
                    variant.setShelfLocationCode(v.getShelfLocationCode());
                }
                variantService.save(variant);

                if (v.getPricing() != null) {
                    VariantPricing pricing = new VariantPricing();
                    pricing.setVariant(variant);
                    pricing.setPurchasePrice(v.getPricing().getPurchasePrice());
                    pricing.setSalePrice(v.getPricing().getSalePrice());
                    pricing.setVatRate(v.getPricing().getVatRate() != null ? v.getPricing().getVatRate() : BigDecimal.ZERO);
                    pricing.setVatIncluded(v.getPricing().getVatIncluded() != null ? v.getPricing().getVatIncluded() : false);
                    pricing.setSpecialTaxRate(v.getPricing().getSpecialTaxRate());
                    pricing.setWithholdingTaxRate(v.getPricing().getWithholdingTaxRate());
                    pricing.setTaxExempt(v.getPricing().getTaxExempt() != null ? v.getPricing().getTaxExempt() : false);
                    pricingService.save(pricing);
                }

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

        // 3. OEM
        if (dto.getOemNumbers() != null && !dto.getOemNumbers().isEmpty()) {
            Product reloaded = productRepository.findById(product.getId()).orElse(product);
            ProductVariant firstVariant = (reloaded.getVariants() != null && !reloaded.getVariants().isEmpty())
                    ? reloaded.getVariants().get(0) : null;
            if (firstVariant != null) {
                for (OemNumberRequest o : dto.getOemNumbers()) {
                    if (o.getOemNumber() == null || o.getOemNumber().isBlank()) continue;
                    oemNumberService.save(OemNumber.builder()
                            .variant(firstVariant).oemNumber(o.getOemNumber())
                            .manufacturer(o.getManufacturer())
                            .isPrimary(o.getIsPrimary() != null ? o.getIsPrimary() : false)
                            .build());
                }
            }
        }

        // 4. CrossRef
        if (dto.getCrossReferences() != null && !dto.getCrossReferences().isEmpty()) {
            Product reloaded = productRepository.findById(product.getId()).orElse(product);
            ProductVariant firstVariant = (reloaded.getVariants() != null && !reloaded.getVariants().isEmpty())
                    ? reloaded.getVariants().get(0) : null;
            if (firstVariant != null) {
                for (CrossReferenceRequest c : dto.getCrossReferences()) {
                    if (c.getCrossRefNumber() == null || c.getCrossRefNumber().isBlank()) continue;
                    crossReferenceService.save(CrossReference.builder()
                            .variant(firstVariant).crossRefNumber(c.getCrossRefNumber())
                            .crossRefBrand(c.getCrossRefBrand()).notes(c.getNotes())
                            .build());
                }
            }
        }

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
     * Ürün Aktifleştir
     */
    @Override
    public void activateProduct(String id) {
        log.info("Ürün aktifleştiriliyor: id={}", id);
        Product product = productRepository.findByIdAndIsDeleted(id, false)
                .orElseThrow(() -> new RuntimeException("Ürün bulunamadı: " + id));
        product.setStatus(ProductStatus.ACTIVE);
        save(product);
        log.info("Ürün aktifleştirildi: id={}", id);
    }

    /**
     * Ürün Pasife Al (Soft Delete)
     */
    @Override
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

        // toDTO(): id, name, slug, description, sector, categoryId, brand, unit, sku, status, metadata kopyalanır
        ProductResponse dto = toDTO(product);
        // Manuel supplement: hesaplanan / join / nested alanlar
        dto.setCategoryName(categoryName);
        dto.setBasePrice(basePrice);
        dto.setVariants(variantResponses);
        return dto;
    }

    /**
     * ProductVariant Entity → ProductVariantResponse mapping
     * Temel alan kopyalaması productVariantService.mapToResponse() (toDTO tabanlı) üzerinden yapılır.
     * Bu metot yalnızca ProductServiceImpl'e özgü inventory enrichment'ı ekler.
     */
    private ProductVariantResponse mapVariantToResponse(ProductVariant variant) {
        // Temel mapping: toDTO tabanlı — barcodes ve salePrice dahil
        ProductVariantResponse dto = variantService.mapToResponse(variant);

        // Inventory enrichment — ProductVariantService'de InventoryService inject yok
        InventoryResponse inventoryResponse = null;
        List<InventoryResponse> inventoryList = new ArrayList<>();
        try {
            List<InventoryView> inventories = inventoryService.findByVariantIdSafe(variant.getId());
            if (!inventories.isEmpty()) {
                int totalQty = inventories.stream()
                        .mapToInt(iv -> iv.getPhysicalQuantity() != null ? iv.getPhysicalQuantity() : 0)
                        .sum();
                InventoryView first = inventories.getFirst();
                inventoryResponse = InventoryResponse.builder()
                        .id(first.getId())
                        .variantId(first.getVariantId())
                        .warehouseId(first.getWarehouseId())
                        .storeId(first.getStoreId())
                        .physicalQuantity(totalQty)
                        .minStockLevel(variant.getMinStockLevel())
                        .build();
                inventoryList = inventories.stream()
                        .map(iv -> InventoryResponse.builder()
                                .variantId(iv.getVariantId())
                                .storeId(iv.getStoreId())
                                .warehouseId(iv.getWarehouseId())
                                .physicalQuantity(iv.getPhysicalQuantity() != null ? iv.getPhysicalQuantity() : 0)
                                .minStockLevel(variant.getMinStockLevel())
                                .build())
                        .toList();
            }
        } catch (Exception e) {
            log.warn("Stok bilgisi alınamadı variant={}: {}", variant.getId(), e.getMessage());
        }
        dto.setInventory(inventoryResponse);
        dto.setInventories(inventoryList);
        return dto;
    }

    @Override
    public Class<?> getDTOClassForService() {
        return ProductResponse.class;
    }
}
