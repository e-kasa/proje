package com.sedcore.service.impl;

import com.sedcore.entity.*;
import com.sedcore.enums.StockMovementType;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.PurchaseItemRequest;
import com.sedcore.model.PurchaseRequest;
import com.sedcore.model.PurchaseResponse;
import com.sedcore.repository.PurchaseRepository;
import com.sedcore.service.*;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
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
                    .purchase(purchase)
                    .build();
            movements.add(stockMovementService.saveMovement(movement));
        }
        purchase.setMovements(movements);

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

        log.info("Satin alma tamamlandi: id={}", purchase.getId());
        return mapToResponse(purchase);
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

    // ─── HELPERS ─────────────────────────────────────────────────────────────

    private PurchaseResponse mapToResponse(Purchase purchase) {
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
