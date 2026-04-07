package com.sedcore.service.impl;

import com.sedcore.entity.*;
import com.sedcore.enums.StockMovementType;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.PurchaseItemRequest;
import com.sedcore.model.PurchaseRequest;
import com.sedcore.model.PurchaseResponse;
import com.sedcore.model.PurchaseReturnItemRequest;
import com.sedcore.model.PurchaseReturnRequest;
import com.sedcore.model.PurchaseReturnResponse;
import com.sedcore.repository.PurchaseRepository;
import com.sedcore.service.*;
import com.sedcore.service.StockMovementService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
public class PurchaseServiceImpl
        extends BaseDbServiceImp<PurchaseRepository, Purchase>
        implements PurchaseService {

    @Autowired private SupplierService supplierService;
    @Autowired private SupplierAccountService supplierAccountService;
    @Autowired private AccountTransactionService accountTransactionService;
    @Autowired private StockMovementService stockMovementService;
    @Autowired private ProductVariantService productVariantService;

    @Override
    public Class<?> getDTOClassForService() {
        return PurchaseResponse.class;
    }

    // ─── CREATE ──────────────────────────────────────────────────────────────

    /**
     * Satın alma tam akışı:
     * 1. Supplier doğrula
     * 2. Purchase kaydet
     * 3. Her kalem için StockMovement(PURCHASE_IN)
     * 4. SupplierAccount güncelle (applyDebit)
     * 5. AccountTransaction(PURCHASE) kaydet
     */
    @Override
    public PurchaseResponse createPurchase(PurchaseRequest request) {
        log.info("Satin alma baslatiliyor - tedarikci={}, fatura={}",
                request.getSupplierId(), request.getInvoiceNumber());

        // 1. Tedarikçi doğrula
        Supplier supplier = supplierService.findById(request.getSupplierId())
                .orElseThrow(() -> new RuntimeException(
                        "Tedarikci bulunamadi: " + request.getSupplierId()));

        // 2. Purchase oluştur
        BigDecimal totalAmount = calculateTotal(request.getItems());
        Purchase purchase = Purchase.builder()
                .supplier(supplier)
                .purchaseDate(request.getPurchaseDate())
                .invoiceNumber(request.getInvoiceNumber())
                .deliveryNoteNumber(request.getDeliveryNoteNumber())
                .totalAmount(totalAmount)
                .paidAmount(BigDecimal.ZERO)
                .isCancelled(false)
                .notes(request.getNotes())
                .build();
        purchase = save(purchase);
        log.info("Purchase kaydedildi: id={}, tutar={}", purchase.getId(), totalAmount);

        // 3. Stok hareketleri (PURCHASE_IN)
        List<StockMovement> movements = new ArrayList<>();
        for (PurchaseItemRequest item : request.getItems()) {
            ProductVariant variant = productVariantService.findById(item.getVariantId())
                    .orElseThrow(() -> new RuntimeException(
                            "Varyant bulunamadi: " + item.getVariantId()));

            StockMovement movement = StockMovement.builder()
                    .variant(variant)
                    .storeId(request.getStoreId())
                    .warehouseId(request.getWarehouseId())
                    .movementType(StockMovementType.PURCHASE_IN)
                    .quantity(item.getQuantity())
                    .unitPrice(item.getUnitPrice())
                    .purchase(purchase)
                    .build();
            movements.add(stockMovementService.saveMovement(movement));
        }

        // 4. Tedarikçi cari hesap: borç ekle (currentBalance ↑, totalDebt ↑)
        SupplierAccount account = supplierAccountService.applyDebit(supplier, totalAmount);

        // 5. Cari hareket kaydı
        AccountTransaction tx = AccountTransaction.builder()
                .supplier(supplier)
                .purchase(purchase)
                .transactionType(TransactionType.PURCHASE)
                .debitAmount(totalAmount)
                .creditAmount(BigDecimal.ZERO)
                .balance(account.getCurrentBalance())
                .referenceId(purchase.getId())
                .referenceType("PURCHASE")
                .referenceNumber(purchase.getInvoiceNumber())
                .description("Satin alma - Fatura No: " + purchase.getInvoiceNumber())
                .transactionDate(LocalDateTime.now())
                .dueDate(dueDateFor(purchase.getPurchaseDate(), supplier.getPaymentTermDays()))
                .isOverdue(false)
                .isCancelled(false)
                .build();
        accountTransactionService.save(tx);

        // DB'den yeniden yükle — Hibernate movements collection'ı doğru şekilde yüklesin
        Purchase saved = findById(purchase.getId())
                .orElseThrow(() -> new RuntimeException("Satin alma bulunamadi: " ));

        log.info("Satin alma tamamlandi: id={}", saved.getId());
        return mapToResponse(saved);
    }

    // ─── CANCEL ──────────────────────────────────────────────────────────────

    /**
     * Satın alma iptali:
     * 1. Zaten iptal mi kontrol
     * 2. PURCHASE_RETURN_OUT stok hareketleri
     * 3. SupplierAccount ters kayıt (reverseDebit)
     * 4. İlgili AccountTransaction'ları iptal et
     * 5. Purchase.isCancelled = true
     */
    @Override
    public PurchaseResponse cancelPurchase(String id) {
        Purchase purchase = findById(id)
                .orElseThrow(() -> new RuntimeException("Satin alma bulunamadi: " + id));

        if (Boolean.TRUE.equals(purchase.getIsCancelled())) {
            throw new RuntimeException("Satin alma zaten iptal edilmis: " + id);
        }

        // 2. PURCHASE_RETURN_OUT hareketleri (mevcut PURCHASE_IN satırları için)
        List<StockMovement> originals = stockMovementService.findByPurchaseId(id);
        for (StockMovement orig : originals) {
            if (orig.getMovementType() == StockMovementType.PURCHASE_IN) {
                StockMovement reversal = StockMovement.builder()
                        .variant(orig.getVariant())
                        .storeId(orig.getStoreId())
                        .warehouseId(orig.getWarehouseId())
                        .movementType(StockMovementType.PURCHASE_RETURN_OUT)
                        .quantity(orig.getQuantity())
                        .purchase(purchase)
                        .build();
                stockMovementService.saveMovement(reversal);
            }
        }

        // 3. Tedarikçi cari hesap: borç geri al (currentBalance ↓, totalDebt ↓)
        Purchase finalPurchase = purchase;
        Supplier supplier = supplierService.findById(purchase.getSupplier().getId())
                .orElseThrow(() -> new RuntimeException(
                        "Tedarikci bulunamadi: " + finalPurchase.getSupplier().getId()));
        supplierAccountService.reverseDebit(supplier, purchase.getTotalAmount());

        // 4. Bağlı AccountTransaction'ları iptal et
        accountTransactionService.getByPurchase(id).forEach(txResp ->
                accountTransactionService.cancelTransaction(
                        txResp.getId(), "Satin alma iptali: " + id));

        // 5. Purchase iptal et
        purchase.setIsCancelled(true);
        purchase = save(purchase);
        log.info("Satin alma iptal edildi: id={}, tedarikci={}", id, supplier.getName());

        return mapToResponse(purchase);
    }

    // ─── LIST / GET ───────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<PurchaseResponse> listPurchases(String supplierId, Boolean isCancelled) {
        List<Purchase> purchases;

        if (supplierId != null && isCancelled != null) {
            purchases = dao.findBySupplierIdAndIsCancelled(supplierId, isCancelled);
        } else if (supplierId != null) {
            purchases = dao.findBySupplierId(supplierId);
        } else if (isCancelled != null) {
            purchases = dao.findByIsCancelled(isCancelled);
        } else {
            purchases = (List<Purchase>) dao.findAll();
        }

        return purchases.stream()
                .sorted(Comparator.comparing(Purchase::getPurchaseDate,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public PurchaseResponse getPurchase(String id) {
        Purchase purchase = findById(id)
                .orElseThrow(() -> new RuntimeException("Satin alma bulunamadi: " + id));
        return mapToResponse(purchase);
    }

    // ─── UPDATE ──────────────────────────────────────────────────────────────

    @Override
    public PurchaseResponse updatePurchase(String id, PurchaseRequest request) {
        Purchase purchase = findById(id)
                .orElseThrow(() -> new RuntimeException("Satin alma bulunamadi: " + id));

        if (Boolean.TRUE.equals(purchase.getIsCancelled())) {
            throw new RuntimeException("Iptal edilmis satin alma guncellenemez: " + id);
        }

        // Belge bilgilerini güncelle
        if (request.getInvoiceNumber() != null) {
            purchase.setInvoiceNumber(request.getInvoiceNumber());
        }
        if (request.getDeliveryNoteNumber() != null) {
            purchase.setDeliveryNoteNumber(request.getDeliveryNoteNumber());
        }
        if (request.getPurchaseDate() != null) {
            purchase.setPurchaseDate(request.getPurchaseDate());
        }
        if (request.getNotes() != null) {
            purchase.setNotes(request.getNotes());
        }

        purchase = save(purchase);
        log.info("Satin alma guncellendi: id={}", id);
        return mapToResponse(purchase);
    }

    // ─── PURCHASE RETURN ─────────────────────────────────────────────────────

    /**
     * Kısmi iade akışı:
     * 1. Purchase doğrula (iptal edilmemiş olmalı)
     * 2. Her kalem için PURCHASE_RETURN_OUT StockMovement
     * 3. SupplierAccount alacak kaydı (applyCredit)
     * 4. AccountTransaction(SUPPLIER_RETURN) kaydet
     */
    @Override
    public PurchaseReturnResponse createPurchaseReturn(String purchaseId, PurchaseReturnRequest request) {
        log.info("Satin alma iadesi baslatiliyor - purchaseId={}, neden={}",
                purchaseId, request.getReason());

        // 1. Purchase doğrula
        Purchase purchase = findById(purchaseId)
                .orElseThrow(() -> new RuntimeException("Satin alma bulunamadi: " + purchaseId));

        if (Boolean.TRUE.equals(purchase.getIsCancelled())) {
            throw new RuntimeException("Iptal edilmis satin alma iade edilemez: " + purchaseId);
        }

        Supplier supplier = supplierService.findById(purchase.getSupplier().getId())
                .orElseThrow(() -> new RuntimeException(
                        "Tedarikci bulunamadi: " + purchase.getSupplier().getId()));

        // 2. Stok hareketleri (PURCHASE_RETURN_OUT)
        BigDecimal totalReturnAmount = BigDecimal.ZERO;
        List<PurchaseReturnResponse.ReturnItemResponse> responseItems = new ArrayList<>();

        for (PurchaseReturnItemRequest item : request.getItems()) {
            // productId aslında variantId olarak gelir (Flutter mapping)
            String variantId = item.getProductId();
            ProductVariant variant = productVariantService.findById(variantId)
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + variantId));

            BigDecimal unitPrice = item.getUnitPrice() != null ? item.getUnitPrice() : BigDecimal.ZERO;
            int qty = item.getQuantity() != null ? item.getQuantity() : 0;

            StockMovement movement = StockMovement.builder()
                    .variant(variant)
                    .storeId(null)
                    .warehouseId(null)
                    .movementType(StockMovementType.PURCHASE_RETURN_OUT)
                    .quantity(qty)
                    .unitPrice(unitPrice)
                    .purchase(purchase)
                    .build();
            stockMovementService.saveMovement(movement);

            BigDecimal lineTotal = unitPrice.multiply(BigDecimal.valueOf(qty));
            totalReturnAmount = totalReturnAmount.add(lineTotal);

            responseItems.add(PurchaseReturnResponse.ReturnItemResponse.builder()
                    .variantId(variantId)
                    .variantSku(variant.getSku())
                    .productName(variant.getProduct() != null ? variant.getProduct().getName() : item.getProductName())
                    .quantity(qty)
                    .unitPrice(unitPrice)
                    .lineTotal(lineTotal)
                    .build());
        }

        // totalReturnAmount: request'ten geleni kullan, yoksa hesapladığımızı kullan
        BigDecimal effectiveReturnAmount = request.getTotalReturnAmount() != null
                ? request.getTotalReturnAmount()
                : totalReturnAmount;

        // 3. SupplierAccount alacak kaydı (borcumuz azalır)
        SupplierAccount account = supplierAccountService.applyCredit(supplier, effectiveReturnAmount);

        // 4. AccountTransaction(SUPPLIER_RETURN) kaydet
        AccountTransaction tx = AccountTransaction.builder()
                .supplier(supplier)
                .purchase(purchase)
                .transactionType(TransactionType.SUPPLIER_RETURN)
                .debitAmount(BigDecimal.ZERO)
                .creditAmount(effectiveReturnAmount)
                .balance(account.getCurrentBalance())
                .referenceId(purchase.getId())
                .referenceType("PURCHASE_RETURN")
                .referenceNumber(purchase.getInvoiceNumber())
                .description("Satin alma iadesi - " + request.getReasonLabel()
                        + " - Fatura: " + purchase.getInvoiceNumber())
                .transactionDate(LocalDateTime.now())
                .isOverdue(false)
                .isCancelled(false)
                .build();
        accountTransactionService.save(tx);

        log.info("Satin alma iadesi tamamlandi - purchaseId={}, tutar={}", purchaseId, effectiveReturnAmount);

        return PurchaseReturnResponse.builder()
                .purchaseId(purchaseId)
                .supplierName(supplier.getName())
                .reason(request.getReason())
                .reasonLabel(request.getReasonLabel())
                .notes(request.getNotes())
                .totalReturnAmount(effectiveReturnAmount)
                .returnDate(LocalDateTime.now())
                .items(responseItems)
                .message("Iade basariyla olusturuldu. Stok ve cari hesap guncellendi.")
                .build();
    }

    // ─── HELPERS ─────────────────────────────────────────────────────────────

    private PurchaseResponse mapToResponse(Purchase purchase) {
        List<PurchaseResponse.PurchaseItemResponse> items = new ArrayList<>();
        if (purchase.getMovements() != null) {
            items = purchase.getMovements().stream()
                    .filter(m -> m != null && m.getMovementType() == StockMovementType.PURCHASE_IN)
                    .map(m -> {
                        ProductVariant v = m.getVariant();
                        BigDecimal price = m.getUnitPrice() != null ? m.getUnitPrice() : BigDecimal.ZERO;
                        return PurchaseResponse.PurchaseItemResponse.builder()
                                .movementId(m.getId())
                                .variantId(v != null ? v.getId() : null)
                                .variantSku(v != null ? v.getSku() : null)
                                .variantName(v != null ? v.getName() : null)
                                .productName(v != null && v.getProduct() != null ? v.getProduct().getName() : null)
                                .quantity(m.getQuantity())
                                .unitPrice(price)
                                .lineTotal(price.multiply(BigDecimal.valueOf(m.getQuantity())))
                                .build();
                    })
                    .collect(Collectors.toList());
        }

        return PurchaseResponse.builder()
                .id(purchase.getId())
                .supplierId(purchase.getSupplier() != null ? purchase.getSupplier().getId() : null)
                .supplierName(purchase.getSupplier() != null ? purchase.getSupplier().getName() : null)
                .invoiceNumber(purchase.getInvoiceNumber())
                .deliveryNoteNumber(purchase.getDeliveryNoteNumber())
                .purchaseDate(purchase.getPurchaseDate())
                .totalAmount(purchase.getTotalAmount())
                .paidAmount(purchase.getPaidAmount())
                .remainingDebt(purchase.getRemainingDebt())
                .isCancelled(purchase.getIsCancelled())
                .notes(purchase.getNotes())
                .items(items)
                .itemCount(items.size())
                .build();
    }

    private BigDecimal calculateTotal(List<PurchaseItemRequest> items) {
        return items.stream()
                .map(i -> i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private LocalDate dueDateFor(LocalDate base, Integer termDays) {
        return base.plusDays(termDays != null ? termDays : 30);
    }
}
