package com.sedcore.purchase.service.impl;

import com.sedcore.common.enums.ClaimReason;
import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.common.enums.PurchaseStatus;
import com.sedcore.common.enums.StockMovementType;
import com.sedcore.common.enums.TransactionType;
import com.sedcore.common.exception.BusinessException;
import com.sedcore.common.exception.NotFoundException;
import com.sedcore.common.util.PricingCalculator;
import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.finance.service.AccountTransactionService;
import com.sedcore.inventory.entity.StockMovement;
import com.sedcore.inventory.service.StockLevelService;
import com.sedcore.inventory.service.StockMovementService;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.product.service.ProductVariantService;
import com.sedcore.purchase.entity.Purchase;
import com.sedcore.purchase.model.ClaimLineSpec;
import com.sedcore.purchase.model.ClaimResolveRequest;
import com.sedcore.purchase.model.PurchaseDiscountRequest;
import com.sedcore.purchase.model.PurchaseItemRequest;
import com.sedcore.purchase.model.PurchaseRequest;
import com.sedcore.purchase.model.PurchaseResponse;
import com.sedcore.purchase.model.PurchaseReturnItemRequest;
import com.sedcore.purchase.model.PurchaseReturnRequest;
import com.sedcore.purchase.model.PurchaseReturnResponse;
import com.sedcore.purchase.model.SupplierClaimResponse;
import com.sedcore.purchase.repository.PurchaseRepository;
import com.sedcore.purchase.service.PurchaseService;
import com.sedcore.purchase.service.SupplierClaimService;
import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.entity.SupplierAccount;
import com.sedcore.supplier.service.SupplierAccountService;
import com.sedcore.supplier.service.SupplierService;
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
    @Autowired private StockLevelService stockLevelService;
    @Autowired private SupplierClaimService supplierClaimService;

    @Override
    public Class<?> getDTOClassForService() {
        return PurchaseResponse.class;
    }

    // ─── CREATE ──────────────────────────────────────────────────────────────

    /**
     * Satın alma tam akışı:
     * 1. Supplier doğrula
     * 2. Purchase kaydet (invoiceAmount, totalAmount, shortageAmount hesapla)
     * 3. Her kalem için PURCHASE_IN stok hareketi (receivedQty kadar)
     * 4. SupplierAccount debit (totalAmount — sadece gelen mal tutarı)
     * 5. AccountTransaction(PURCHASE) kaydet
     * 6. shortageAmount > 0 ise SupplierClaim otomatik aç
     */
    @Override
    public PurchaseResponse createPurchase(PurchaseRequest request) {
        log.info("Satin alma baslatiliyor - tedarikci={}, fatura={}",
                request.getSupplierId(), request.getInvoiceNumber());

        // 1. Tedarikçi doğrula
        Supplier supplier = supplierService.findById(request.getSupplierId())
                .orElseThrow(() -> new NotFoundException(
                        "Tedarikci bulunamadi: " + request.getSupplierId()));

        // 2. Tutar hesapla: PricingCalculator ile vergi/iskonto dahil aggregate.
        //    invoiceAmount   = Σ(lineTotal × invoiceQty)   — fatura brüt (vergi dahil)
        //    receivedAmount  = Σ(lineTotal × receivedQty)  — gelen mal (vergi dahil, cariye yansır)
        //    totalVat/totalOtv/totalItemDiscount = received bazlı özet
        PurchaseAggregate agg = aggregatePurchase(request.getItems());
        BigDecimal invoiceAmount = agg.invoiceAmount();
        BigDecimal totalAmount   = agg.receivedAmount();
        BigDecimal shortageAmount = invoiceAmount.subtract(totalAmount);

        PurchaseStatus status = shortageAmount.compareTo(BigDecimal.ZERO) > 0
                ? PurchaseStatus.PARTIAL
                : PurchaseStatus.COMPLETED;

        Purchase purchase = Purchase.builder()
                .supplier(supplier)
                .purchaseDate(request.getPurchaseDate())
                .invoiceNumber(request.getInvoiceNumber())
                .deliveryNoteNumber(request.getDeliveryNoteNumber())
                .locationId(request.getLocationId())
                .locationType(request.getLocationType())
                .invoiceAmount(invoiceAmount)
                .totalAmount(totalAmount)
                .shortageAmount(shortageAmount)
                .discountAmount(BigDecimal.ZERO)
                .totalVat(agg.totalVat())
                .totalOtv(agg.totalOtv())
                .totalItemDiscount(agg.totalItemDiscount())
                .paidAmount(BigDecimal.ZERO)
                .purchaseStatus(status)
                .isCancelled(false)
                .notes(request.getNotes())
                .build();
        purchase = save(purchase);
        log.info("Purchase kaydedildi: id={}, invoiceAmount={}, totalAmount={}, shortage={}",
                purchase.getId(), invoiceAmount, totalAmount, shortageAmount);

        // 3. Stok hareketleri — sadece receivedQty kadar
        for (PurchaseItemRequest item : request.getItems()) {
            ProductVariant variant = productVariantService.findById(item.getVariantId())
                    .orElseThrow(() -> new NotFoundException(
                            "Varyant bulunamadi: " + item.getVariantId()));

            int receivedQty = item.resolvedReceivedQty();
            if (receivedQty > 0) {
                stockLevelService.addStock(
                        variant.getId(),
                        request.getLocationId(),
                        request.getLocationType(),
                        receivedQty);

                StockMovement movement = StockMovement.builder()
                        .variant(variant)
                        .locationId(request.getLocationId())
                        .locationType(request.getLocationType())
                        .movementType(StockMovementType.PURCHASE_IN)
                        .quantity(receivedQty)
                        .unitPrice(item.getUnitPrice())
                        .taxRate(item.getTaxRate())
                        .otvRate(item.getOtvRate())
                        .purchase(purchase)
                        .build();
                stockMovementService.saveMovement(movement);
            }
        }

        // 4. Tedarikçi cari: sadece gelen mal tutarı kadar borç
        SupplierAccount account = supplierAccountService.applyDebit(supplier, totalAmount);

        // 5. Cari hareket kaydı
        String desc = "Satin alma - Fatura: " + purchase.getInvoiceNumber();
        if (shortageAmount.compareTo(BigDecimal.ZERO) > 0) {
            desc += " | Eksik teslimat: " + shortageAmount + " TL (claim açıldı)";
        }
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
                .description(desc)
                .transactionDate(LocalDateTime.now())
                .dueDate(dueDateFor(purchase.getPurchaseDate(), supplier.getPaymentTermDays()))
                .isOverdue(false)
                .isCancelled(false)
                .build();
        accountTransactionService.save(tx);

        // 6. Eksik varsa claim otomatik aç (satır detaylı)
        if (shortageAmount.compareTo(BigDecimal.ZERO) > 0) {
            List<ClaimLineSpec> shortageLines = new ArrayList<>();
            for (PurchaseItemRequest item : request.getItems()) {
                if (item.shortageQty() <= 0) continue;
                ProductVariant v = productVariantService.findById(item.getVariantId()).orElse(null);
                if (v == null) continue;
                String name = v.getProduct() != null ? v.getProduct().getName() : v.getName();
                shortageLines.add(new ClaimLineSpec(
                        v,
                        v.getSku(),
                        name,
                        item.resolvedInvoiceQty(),
                        item.resolvedReceivedQty(),
                        item.getUnitPrice(),
                        ClaimReason.SHORTAGE,
                        item.getNotes()
                ));
            }
            if (!shortageLines.isEmpty()) {
                supplierClaimService.openClaim(
                        purchase,
                        shortageLines,
                        "Otomatik - eksik teslimat: " + purchase.getInvoiceNumber()
                                + " | Fatura: " + invoiceAmount + " TL, Gelen: " + totalAmount + " TL"
                );
            }
        }

        Purchase finalPurchase = purchase;
        Purchase saved = findById(purchase.getId())
                .orElseThrow(() -> new NotFoundException("Satin alma bulunamadi: " + finalPurchase.getId()));
        log.info("Satin alma tamamlandi: id={}, status={}", saved.getId(), status);
        return mapToResponse(saved);
    }

    // ─── CANCEL ──────────────────────────────────────────────────────────────

    @Override
    public PurchaseResponse cancelPurchase(String id) {
        Purchase purchase = findById(id)
                .orElseThrow(() -> new NotFoundException("Satin alma bulunamadi: " + id));

        if (Boolean.TRUE.equals(purchase.getIsCancelled())) {
            throw new BusinessException("Bu satin alma zaten iptal edilmis: " + id);
        }

        // PURCHASE_RETURN_OUT — gelen malları stoktan geri çıkar
        List<StockMovement> originals = stockMovementService.findByPurchaseId(id);
        for (StockMovement orig : originals) {
            if (orig.getMovementType() == StockMovementType.PURCHASE_IN) {
                stockLevelService.deductStock(
                        orig.getVariant().getId(),
                        orig.getLocationId(),
                        orig.getQuantity());

                StockMovement reversal = StockMovement.builder()
                        .variant(orig.getVariant())
                        .locationId(orig.getLocationId())
                        .locationType(orig.getLocationType())
                        .movementType(StockMovementType.PURCHASE_RETURN_OUT)
                        .quantity(orig.getQuantity())
                        .purchase(purchase)
                        .build();
                stockMovementService.saveMovement(reversal);
            }
        }

        Purchase finalPurchase = purchase;
        Supplier supplier = supplierService.findById(purchase.getSupplier().getId())
                .orElseThrow(() -> new NotFoundException(
                        "Tedarikci bulunamadi: " + finalPurchase.getSupplier().getId()));
        supplierAccountService.reverseDebit(supplier, purchase.getTotalAmount());

        accountTransactionService.getByPurchase(id).forEach(txResp ->
                accountTransactionService.cancelTransaction(
                        txResp.getId(), "Satin alma iptali: " + id));

        purchase.setIsCancelled(true);
        purchase.setPurchaseStatus(PurchaseStatus.CANCELLED);
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
                .orElseThrow(() -> new NotFoundException("Satin alma bulunamadi: " + id));
        return mapToResponse(purchase);
    }

    // ─── UPDATE ──────────────────────────────────────────────────────────────

    @Override
    public PurchaseResponse updatePurchase(String id, PurchaseRequest request) {
        Purchase purchase = findById(id)
                .orElseThrow(() -> new NotFoundException("Satin alma bulunamadi: " + id));

        if (Boolean.TRUE.equals(purchase.getIsCancelled())) {
            throw new BusinessException("Iptal edilmis satin alma guncellenemez: " + id);
        }

        if (request.getInvoiceNumber() != null) purchase.setInvoiceNumber(request.getInvoiceNumber());
        if (request.getDeliveryNoteNumber() != null) purchase.setDeliveryNoteNumber(request.getDeliveryNoteNumber());
        if (request.getPurchaseDate() != null) purchase.setPurchaseDate(request.getPurchaseDate());
        if (request.getNotes() != null) purchase.setNotes(request.getNotes());

        purchase = save(purchase);
        log.info("Satin alma guncellendi: id={}", id);
        return mapToResponse(purchase);
    }

    // ─── PURCHASE RETURN ─────────────────────────────────────────────────────

    @Override
    public PurchaseReturnResponse createPurchaseReturn(String purchaseId, PurchaseReturnRequest request) {
        log.info("Satin alma iadesi baslatiliyor - purchaseId={}, neden={}",
                purchaseId, request.getReason());

        Purchase purchase = findById(purchaseId)
                .orElseThrow(() -> new NotFoundException("Satin alma bulunamadi: " + purchaseId));

        if (Boolean.TRUE.equals(purchase.getIsCancelled())) {
            throw new BusinessException("Iptal edilmis satin almada iade yapilamaz: " + purchaseId);
        }

        Supplier supplier = supplierService.findById(purchase.getSupplier().getId())
                .orElseThrow(() -> new NotFoundException(
                        "Tedarikci bulunamadi: " + purchase.getSupplier().getId()));

        String originalLocationId   = purchase.getLocationId();
        String originalLocationType = purchase.getLocationType();
        if (originalLocationId == null && purchase.getMovements() != null) {
            for (StockMovement m : purchase.getMovements()) {
                if (m.getMovementType() == StockMovementType.PURCHASE_IN) {
                    originalLocationId   = m.getLocationId();
                    originalLocationType = m.getLocationType();
                    break;
                }
            }
        }

        BigDecimal totalReturnAmount = BigDecimal.ZERO;
        List<PurchaseReturnResponse.ReturnItemResponse> responseItems = new ArrayList<>();

        for (PurchaseReturnItemRequest item : request.getItems()) {
            String variantId = item.getProductId();
            ProductVariant variant = productVariantService.findById(variantId)
                    .orElseThrow(() -> new NotFoundException("Varyant bulunamadi: " + variantId));

            BigDecimal unitPrice = item.getUnitPrice() != null ? item.getUnitPrice() : BigDecimal.ZERO;
            int qty = item.getQuantity() != null ? item.getQuantity() : 0;

            if (originalLocationId != null && qty > 0) {
                stockLevelService.deductStock(variant.getId(), originalLocationId, qty);
            }

            StockMovement movement = StockMovement.builder()
                    .variant(variant)
                    .locationId(originalLocationId)
                    .locationType(originalLocationType)
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
                    .productName(variant.getProduct() != null
                            ? variant.getProduct().getName() : item.getProductName())
                    .quantity(qty)
                    .unitPrice(unitPrice)
                    .lineTotal(lineTotal)
                    .build());
        }

        BigDecimal effectiveReturnAmount = request.getTotalReturnAmount() != null
                ? request.getTotalReturnAmount()
                : totalReturnAmount;

        SupplierAccount account = supplierAccountService.applyCredit(supplier, effectiveReturnAmount);

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

    // ─── APPLY DISCOUNT ──────────────────────────────────────────────────────

    /**
     * Tedarikçi iskontosu / kredi notu uygulama.
     *
     * <p>Finansal model:
     * Eksik kalemler için baştan debit yazılmamıştı (sadece gelen mal tutarı yazıldı).
     * Bu nedenle iskonto uygulandığında SupplierAccount'a ek credit yazılmaz.
     * shortageAmount azaltılır, discountAmount birikir.
     * AccountTransaction(DISCOUNT) yalnızca audit trail amaçlı kayıt tutar.</p>
     */
    @Override
    public PurchaseResponse applyDiscount(String purchaseId, PurchaseDiscountRequest request) {
        Purchase purchase = findById(purchaseId)
                .orElseThrow(() -> new NotFoundException("Satin alma bulunamadi: " + purchaseId));

        if (Boolean.TRUE.equals(purchase.getIsCancelled())) {
            throw new BusinessException("Iptal edilmis satin almada iskonto uygulanamaz: " + purchaseId);
        }
        if (purchase.getShortageAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException("Bu satin almada acik eksik teslimat bulunmuyor: " + purchaseId);
        }
        if (request.getDiscountAmount().compareTo(purchase.getShortageAmount()) > 0) {
            throw new BusinessException(
                    "Iskonto tutari acik eksik miktardan fazla olamaz. Acik: "
                            + purchase.getShortageAmount() + ", Istenen: " + request.getDiscountAmount());
        }

        // shortage azalt, discount birikimli artır
        BigDecimal newShortage  = purchase.getShortageAmount().subtract(request.getDiscountAmount());
        BigDecimal newDiscount  = purchase.getDiscountAmount().add(request.getDiscountAmount());

        purchase.setShortageAmount(newShortage);
        purchase.setDiscountAmount(newDiscount);
        purchase.setPurchaseStatus(
                newShortage.compareTo(BigDecimal.ZERO) == 0
                        ? PurchaseStatus.DISCOUNTED
                        : PurchaseStatus.PARTIAL);
        purchase = save(purchase);

        // Audit transaction — cari bakiyeye etki yok, sadece kayıt
        Supplier supplier = purchase.getSupplier();
        SupplierAccount account = supplierAccountService.getOrCreate(supplier);
        AccountTransaction tx = AccountTransaction.builder()
                .supplier(supplier)
                .purchase(purchase)
                .transactionType(TransactionType.DISCOUNT)
                .debitAmount(BigDecimal.ZERO)
                .creditAmount(request.getDiscountAmount())
                .balance(account.getCurrentBalance())   // bakiye değişmiyor, güncel değer kaydedilir
                .referenceId(purchase.getId())
                .referenceType("PURCHASE_DISCOUNT")
                .referenceNumber(request.getCreditNoteNumber() != null
                        ? request.getCreditNoteNumber() : purchase.getInvoiceNumber())
                .description("Tedarikci iskontosu - Fatura: " + purchase.getInvoiceNumber()
                        + (request.getCreditNoteNumber() != null
                            ? " | KN: " + request.getCreditNoteNumber() : ""))
                .transactionDate(LocalDateTime.now())
                .isOverdue(false)
                .isCancelled(false)
                .build();
        accountTransactionService.save(tx);

        // Mevcut OPEN claim'i DISCOUNT ile kapat (tam kapanma veya kısmi)
        supplierClaimService.listByPurchase(purchaseId).stream()
                .filter(c -> c.getStatus() == ClaimStatus.OPEN)
                .findFirst()
                .ifPresent(c -> {
                    ClaimResolveRequest resolve = ClaimResolveRequest.builder()
                            .resolution(newShortage.compareTo(BigDecimal.ZERO) == 0
                                    ? ClaimStatus.RESOLVED_DISCOUNT
                                    : ClaimStatus.OPEN)      // kısmi: claim açık kalmaya devam eder
                            .resolvedAmount(request.getDiscountAmount())
                            .creditNoteNumber(request.getCreditNoteNumber())
                            .notes(request.getNotes())
                            .build();
                    if (newShortage.compareTo(BigDecimal.ZERO) == 0) {
                        supplierClaimService.resolveClaim(c.getId(), resolve);
                    }
                    // Kısmi iskonto: claim tutarını güncelle (claimAmount azalt)
                    else {
                        supplierClaimService.findById(c.getId()).ifPresent(claim -> {
                            claim.setClaimAmount(newShortage);
                            supplierClaimService.save(claim);
                        });
                    }
                });

        log.info("Iskonto uygulandı: purchaseId={}, iskonto={}, kalanShortage={}",
                purchaseId, request.getDiscountAmount(), newShortage);
        return mapToResponse(purchase);
    }

    // ─── CLAIM DELEGATIONS ───────────────────────────────────────────────────

    @Override
    public List<SupplierClaimResponse> listClaims(String purchaseId) {
        return supplierClaimService.listByPurchase(purchaseId);
    }

    @Override
    public List<SupplierClaimResponse> listClaimsBySupplier(String supplierId, ClaimStatus status) {
        return supplierClaimService.listBySupplier(supplierId, status);
    }

    @Override
    public SupplierClaimResponse resolveClaim(String claimId, ClaimResolveRequest request) {
        return supplierClaimService.resolveClaim(claimId, request);
    }

    // ─── HELPERS ─────────────────────────────────────────────────────────────

    private PurchaseResponse mapToResponse(Purchase purchase) {
        PurchaseResponse dto = toDTO(purchase);

        if (purchase.getSupplier() != null) {
            dto.setSupplierId(purchase.getSupplier().getId());
            dto.setSupplierName(purchase.getSupplier().getName());
        }

        dto.setLocationId(purchase.getLocationId());
        dto.setLocationType(purchase.getLocationType());
        dto.setInvoiceAmount(purchase.getInvoiceAmount());
        dto.setDiscountAmount(purchase.getDiscountAmount());
        dto.setShortageAmount(purchase.getShortageAmount());
        dto.setPurchaseStatus(purchase.getPurchaseStatus());

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
                                .productName(v != null && v.getProduct() != null
                                        ? v.getProduct().getName() : null)
                                .quantity(m.getQuantity())
                                .unitPrice(price)
                                .lineTotal(price.multiply(BigDecimal.valueOf(m.getQuantity())))
                                .build();
                    })
                    .toList();
        }
        dto.setItems(items);
        dto.setItemCount(items.size());
        return dto;
    }

    /**
     * Alış faturası özet hesabı — Sprint 2026-05-25.
     *
     * <p>Her kalem için {@link PricingCalculator} ile lineTotal (KDV+ÖTV dahil) hesaplanır.
     * Tedarikçi cari borcuna **gelen mal tutarı kadar** lineTotal yansır
     * (eksik teslimat varsa fatura tutarından az).
     *
     * <p>Mevcut alanlar:
     * <ul>
     *   <li>{@code invoiceAmount} = Σ(lineTotal × invoiceQty/qty) — fatura brüt (vergi dahil)
     *   <li>{@code receivedAmount} = Σ(lineTotal × receivedQty/qty) — gelen mal (vergi dahil)
     *   <li>{@code totalVat/totalOtv/totalItemDiscount} = received bazlı vergi/iskonto özeti
     * </ul>
     */
    private PurchaseAggregate aggregatePurchase(List<PurchaseItemRequest> items) {
        BigDecimal invoiceAmount = BigDecimal.ZERO;
        BigDecimal receivedAmount = BigDecimal.ZERO;
        BigDecimal totalVat = BigDecimal.ZERO;
        BigDecimal totalOtv = BigDecimal.ZERO;
        BigDecimal totalItemDiscount = BigDecimal.ZERO;

        for (PurchaseItemRequest i : items) {
            int invoiceQty = i.resolvedInvoiceQty();
            int receivedQty = i.resolvedReceivedQty();

            // Fatura tutarı (vergi dahil) — invoiceQty bazında
            if (invoiceQty > 0) {
                PricingCalculator.LineCalculation invCalc = PricingCalculator.calculate(
                        PricingCalculator.LineInput.builder()
                                .unitPrice(i.getUnitPrice())
                                .quantity(invoiceQty)
                                .discountRate(i.getDiscountRate())
                                .otvRate(i.getOtvRate())
                                .vatRate(i.getTaxRate())
                                .vatIncluded(i.getVatIncluded())
                                .build());
                invoiceAmount = invoiceAmount.add(invCalc.getLineTotal());
            }

            // Gelen mal tutarı + vergi/iskonto özeti — receivedQty bazında
            if (receivedQty > 0) {
                PricingCalculator.LineCalculation rcvCalc = PricingCalculator.calculate(
                        PricingCalculator.LineInput.builder()
                                .unitPrice(i.getUnitPrice())
                                .quantity(receivedQty)
                                .discountRate(i.getDiscountRate())
                                .otvRate(i.getOtvRate())
                                .vatRate(i.getTaxRate())
                                .vatIncluded(i.getVatIncluded())
                                .build());
                receivedAmount = receivedAmount.add(rcvCalc.getLineTotal());
                totalVat = totalVat.add(rcvCalc.getVatAmount());
                totalOtv = totalOtv.add(rcvCalc.getOtvAmount());
                totalItemDiscount = totalItemDiscount.add(rcvCalc.getDiscountAmount());
            }
        }

        return new PurchaseAggregate(invoiceAmount, receivedAmount, totalVat, totalOtv, totalItemDiscount);
    }

    /** Alış kalemlerinin vergi/iskonto özeti. */
    private record PurchaseAggregate(
            BigDecimal invoiceAmount,
            BigDecimal receivedAmount,
            BigDecimal totalVat,
            BigDecimal totalOtv,
            BigDecimal totalItemDiscount) {}

    private LocalDate dueDateFor(LocalDate base, Integer termDays) {
        return base.plusDays(termDays != null ? termDays : 30);
    }
}
