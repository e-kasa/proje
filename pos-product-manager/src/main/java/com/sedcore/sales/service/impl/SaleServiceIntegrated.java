package com.sedcore.sales.service.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.util.PricingCalculator;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.sales.entity.Sale;
import com.sedcore.sales.entity.SaleItem;
import com.sedcore.sales.entity.SaleReturn;
import com.sedcore.sales.entity.SaleReturnItem;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.customer.entity.CustomerVehicle;
import com.sedcore.customer.service.CustomerVehicleService;
import com.sedcore.inventory.entity.StockMovement;
import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.common.enums.StockMovementType;
import com.sedcore.common.enums.TransactionType;
import com.sedcore.inventory.service.StockLevelService;
import com.sedcore.sales.model.SaleItemRequest;
import com.sedcore.sales.model.SaleRequest;
import com.sedcore.sales.model.SaleReturnItemRequest;
import com.sedcore.sales.model.SaleReturnRequest;
import com.sedcore.sales.model.SaleReturnResponse;
import com.sedcore.sales.repository.SaleItemRepository;
import com.sedcore.sales.repository.SaleRepository;
import com.sedcore.sales.repository.SaleReturnRepository;
import com.sedcore.sales.repository.SaleReturnItemRepository;
import com.sedcore.customer.repository.CustomerRepository;
import com.sedcore.customer.repository.CustomerAccountRepository;
import com.sedcore.product.repository.ProductVariantRepository;
import com.sedcore.inventory.repository.StockMovementRepository;
import com.sedcore.finance.repository.AccountTransactionRepository;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.security.BaseDbServiceImp;
import com.towpen.base.security.ISessionInstanceService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@Slf4j
@Transactional
public class SaleServiceIntegrated
        extends BaseDbServiceImp<SaleRepository, Sale> {

    @Autowired private StockMovementRepository     stockMovementRepository;
    @Autowired private CustomerRepository          customerRepository;
    @Autowired private CustomerAccountRepository   customerAccountRepository;
    @Autowired private AccountTransactionRepository accountTransactionRepository;
    @Autowired private ProductVariantRepository    variantRepository;
    @Autowired private StockLevelService           stockLevelService;
    @Autowired private SaleItemRepository          saleItemRepository;
    @Autowired private SaleReturnRepository        saleReturnRepository;
    @Autowired private SaleReturnItemRepository    saleReturnItemRepository;
    @Autowired private ISessionInstanceService     sessionInstanceService;
    @Autowired private CustomerVehicleService      customerVehicleService;

    @Override
    public Class<?> getDTOClassForService() {
        return Sale.class;
    }

    // ─── SATIŞ OLUŞTUR ───────────────────────────────────────────────────────

    @Transactional
    public Sale createSale(SaleRequest request) {
        if (request.getSaleNumber() == null || request.getSaleNumber().isBlank()) {
            String datePart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
            String randPart = UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase();
            request.setSaleNumber("POS-" + datePart + "-" + randPart);
        }

        log.info("Satış başlatılıyor - Müşteri: {}, No: {}, Lokasyon: {}",
                request.getCustomerId(), request.getSaleNumber(), request.getLocationId());

        // 1. KALEMLERİ HESAPLA (mem'de; henüz save edilmez)
        // Hesap formülü: PricingCalculator (iskonto → ÖTV → KDV, vatIncluded ayrıştırma)
        List<SaleItem> items = new ArrayList<>();
        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal totalDiscount = BigDecimal.ZERO;
        BigDecimal totalTax = BigDecimal.ZERO;
        BigDecimal totalOtv = BigDecimal.ZERO;
        BigDecimal grandTotal = BigDecimal.ZERO;

        for (SaleItemRequest req : request.getItems()) {
            ProductVariant variant = variantRepository.findById(req.getVariantId())
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + req.getVariantId()));

            PricingCalculator.LineCalculation calc = PricingCalculator.calculate(
                    PricingCalculator.LineInput.builder()
                            .unitPrice(req.getUnitPrice())
                            .quantity(req.getQuantity())
                            .discountRate(req.getDiscountRate())
                            .otvRate(req.getOtvRate())
                            .vatRate(req.getTaxRate())
                            .vatIncluded(req.getVatIncluded())
                            .build());

            SaleItem item = SaleItem.builder()
                    .variant(variant)
                    .quantity(req.getQuantity())
                    .unitPrice(req.getUnitPrice())
                    .discountRate(req.getDiscountRate() != null ? req.getDiscountRate() : BigDecimal.ZERO)
                    .discountAmount(calc.getDiscountAmount())
                    .taxRate(req.getTaxRate() != null ? req.getTaxRate() : BigDecimal.ZERO)
                    .taxAmount(calc.getVatAmount())
                    .otvRate(req.getOtvRate() != null ? req.getOtvRate() : BigDecimal.ZERO)
                    .otvAmount(calc.getOtvAmount())
                    .lineTotal(calc.getLineTotal())
                    .returnedQuantity(0)
                    .notes(req.getNotes())
                    .build();
            items.add(item);

            subtotal = subtotal.add(calc.getGross());
            totalDiscount = totalDiscount.add(calc.getDiscountAmount());
            totalTax = totalTax.add(calc.getVatAmount());
            totalOtv = totalOtv.add(calc.getOtvAmount());
            grandTotal = grandTotal.add(calc.getLineTotal());
        }

        // 2. Defansif guard: vadeli satışta müşteri zorunlu.
        BigDecimal paid = request.getPaidAmount() != null
                ? request.getPaidAmount() : BigDecimal.ZERO;
        if (request.getCustomerId() == null && paid.compareTo(grandTotal) < 0) {
            throw new RuntimeException("Vadeli satış için müşteri zorunludur");
        }

        // 3. MÜŞTERİ KONTROL
        Customer customer = null;
        if (request.getCustomerId() != null) {
            customer = customerRepository.findById(request.getCustomerId())
                    .orElseThrow(() -> new RuntimeException("Müşteri bulunamadı: " + request.getCustomerId()));
            checkCreditLimit(customer, grandTotal,
                    Boolean.TRUE.equals(request.getOverrideCreditLimit()));
        }

        // 3b. PLAKA (Sprint 9 — parçacı sektör opsiyonel)
        CustomerVehicle customerVehicle = null;
        String vehiclePlateSnapshot = null;
        if (request.getCustomerVehicleId() != null && !request.getCustomerVehicleId().isBlank()) {
            customerVehicle = customerVehicleService.getEntity(request.getCustomerVehicleId());
            // Tutarlılık: plaka müşteriye mi ait?
            if (customer == null || customerVehicle.getCustomer() == null
                    || !customer.getId().equals(customerVehicle.getCustomer().getId())) {
                throw new RuntimeException("Seçilen plaka bu müşteriye ait değil");
            }
            vehiclePlateSnapshot = customerVehicle.getPlateNormalized();
        }

        // 4. SALE OLUŞTUR
        Sale sale = Sale.builder()
                .customer(customer)
                .customerVehicle(customerVehicle)
                .vehiclePlateSnapshot(vehiclePlateSnapshot)
                .saleNumber(request.getSaleNumber())
                .saleDate(LocalDateTime.now())
                .subtotalAmount(subtotal)
                .totalDiscount(totalDiscount)
                .totalTax(totalTax)
                .totalOtv(totalOtv)
                .totalAmount(grandTotal)
                .paidAmount(paid)
                .locationId(request.getLocationId())
                .locationType(request.getLocationType() != null ? request.getLocationType() : "STORE")
                .isCancelled(false)
                .hasReturn(false)
                .returnedAmount(BigDecimal.ZERO)
                .notes(request.getNotes())
                .build();

        sale = save(sale);
        log.info("Sale kaydedildi: ID={}, Tutar={}", sale.getId(), sale.getTotalAmount());

        // 5. SALE ITEM'LARI SAVE
        List<SaleItem> savedItems = new ArrayList<>();
        for (SaleItem item : items) {
            item.setSale(sale);
            savedItems.add(prepareAndSave(saleItemRepository, item));
        }
        sale.setItems(savedItems);

        // 6. STOK HAREKETLERİ + StockLevel atomic decrement
        String effectiveLocationId = request.getLocationId();
        String effectiveLocationType = request.getLocationType() != null ? request.getLocationType() : "STORE";

        List<StockMovement> movements = new ArrayList<>();
        for (SaleItem item : savedItems) {
            if (effectiveLocationId != null && !effectiveLocationId.isBlank()) {
                stockLevelService.deductStock(item.getVariant().getId(), effectiveLocationId, item.getQuantity());
            }

            StockMovement movement = StockMovement.builder()
                    .variant(item.getVariant())
                    .locationId(effectiveLocationId)
                    .locationType(effectiveLocationType)
                    .movementType(StockMovementType.SALE_OUT)
                    .quantity(item.getQuantity())
                    .unitPrice(item.getUnitPrice())
                    .sale(sale)
                    .build();
            movements.add(prepareAndSave(stockMovementRepository, movement));
        }
        sale.setMovements(movements);

        // 7. VERESİYE: cari hesap + hareket
        if (sale.isOnCredit()) {
            CustomerAccount account = updateCustomerAccount(customer, sale);
            createCustomerTransaction(customer, sale, account);
        }

        log.info("Satış tamamlandı: ID={}", sale.getId());
        return sale;
    }

    // ─── SATIŞ İPTAL ─────────────────────────────────────────────────────────

    @Transactional
    public Sale cancelSale(String saleId, String reason) {
        Sale sale = findById(saleId)
                .orElseThrow(() -> new RuntimeException("Satış bulunamadı: " + saleId));
        if (Boolean.TRUE.equals(sale.getIsCancelled())) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        List<StockMovement> existingMovements = stockMovementRepository.findBySaleId(saleId, CompanyContext.get());
        for (StockMovement mv : existingMovements) {
            if (mv.getMovementType() != StockMovementType.SALE_OUT) continue;

            // StockLevel geri ekle
            if (mv.getLocationId() != null && !mv.getLocationId().isBlank()) {
                stockLevelService.addStock(mv.getVariant().getId(), mv.getLocationId(),
                        mv.getLocationType(), mv.getQuantity());
            }

            StockMovement reversal = StockMovement.builder()
                    .variant(mv.getVariant())
                    .locationId(mv.getLocationId())
                    .locationType(mv.getLocationType())
                    .movementType(StockMovementType.SALE_CANCEL_IN)
                    .quantity(mv.getQuantity())
                    .unitPrice(mv.getUnitPrice())
                    .sale(sale)
                    .build();
            prepareAndSave(stockMovementRepository, reversal);
        }

        if (sale.getCustomer() != null && sale.getRemainingAmount().compareTo(BigDecimal.ZERO) > 0) {
            Customer customer = sale.getCustomer();
            CustomerAccount account = customerAccountRepository.findByCustomer(customer).orElse(null);
            if (account != null) {
                account.setCurrentBalance(account.getCurrentBalance().subtract(sale.getRemainingAmount()));
                BigDecimal newDebt = account.getTotalDebt().subtract(sale.getTotalAmount());
                account.setTotalDebt(newDebt.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : newDebt);
                BigDecimal newCredit = account.getTotalCredit().subtract(sale.getPaidAmount());
                account.setTotalCredit(newCredit.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : newCredit);
                account.setLastTransactionDate(LocalDateTime.now());
                account.updateCalculatedFields();
                prepareAndSave(customerAccountRepository, account);

                AccountTransaction cancelTx = AccountTransaction.builder()
                        .customer(customer).sale(sale)
                        .transactionType(TransactionType.CANCEL)
                        .debitAmount(BigDecimal.ZERO)
                        .creditAmount(sale.getRemainingAmount())
                        .balance(account.getCurrentBalance())
                        .referenceId(sale.getId()).referenceType("SALE_CANCEL")
                        .referenceNumber(sale.getSaleNumber())
                        .description("Satış İptali - No: " + sale.getSaleNumber() + " - Sebep: " + reason)
                        .transactionDate(LocalDateTime.now()).isOverdue(false).isCancelled(false).build();
                prepareAndSave(accountTransactionRepository, cancelTx);

                List<AccountTransaction> origTxs = accountTransactionRepository.findBySaleId(saleId);
                for (AccountTransaction origTx : origTxs) {
                    if (!Boolean.TRUE.equals(origTx.getIsCancelled())
                            && origTx.getTransactionType() == TransactionType.SALE) {
                        origTx.cancel("system");
                        prepareAndSave(accountTransactionRepository, origTx);
                    }
                }
            }
        }

        sale.setIsCancelled(true);
        sale.setCancelReason(reason != null && !reason.isBlank() ? reason : "Belirtilmedi");
        sale.setCancelDate(LocalDateTime.now());
        Sale saved = save(sale);
        log.info("Satış iptal edildi: {}, Sebep: {}", saved.getSaleNumber(), reason);
        return saved;
    }

    // ─── SATIŞ İADESİ ────────────────────────────────────────────────────────

    @Transactional
    public SaleReturnResponse createSaleReturn(String saleId, SaleReturnRequest request) {
        Sale sale = findById(saleId)
                .orElseThrow(() -> new RuntimeException("Satış bulunamadı: " + saleId));
        if (Boolean.TRUE.equals(sale.getIsCancelled())) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        // SaleItem bazlı: returnableQty = quantity - returnedQuantity
        // Tutar hesabı SaleItem.lineTotal üzerinden prorata (indirim + KDV dahil)
        List<SaleItem> saleItems = saleItemRepository.findBySaleId(saleId);
        Map<String, SaleItem> itemByVariant = new HashMap<>();
        for (SaleItem si : saleItems) {
            if (si.getVariant() != null) itemByVariant.put(si.getVariant().getId(), si);
        }

        // Lokasyon: satışın kendi lokasyonu
        String returnLocationId = sale.getLocationId();
        String returnLocationType = sale.getLocationType() != null ? sale.getLocationType() : "STORE";

        BigDecimal totalReturnAmount = BigDecimal.ZERO;
        List<SaleReturnResponse.ReturnItemResponse> responseItems = new ArrayList<>();
        List<SaleReturnItem> returnItemEntities = new ArrayList<>();

        for (SaleReturnItemRequest item : request.getItems()) {
            String variantId = item.getProductId();
            SaleItem saleItem = itemByVariant.get(variantId);
            if (saleItem == null) {
                ProductVariant v = variantRepository.findById(variantId).orElse(null);
                throw new RuntimeException("Bu ürün bu satışta bulunmuyor: "
                        + (v != null ? v.getSku() : variantId));
            }
            ProductVariant variant = saleItem.getVariant();

            int qty = item.getQuantity() != null ? item.getQuantity() : 0;
            int originalSold = saleItem.getQuantity() != null ? saleItem.getQuantity() : 0;
            int alreadyReturned = saleItem.getReturnedQuantity() != null ? saleItem.getReturnedQuantity() : 0;
            int returnableQty = originalSold - alreadyReturned;
            if (qty > returnableQty) {
                throw new RuntimeException(String.format(
                        "İade miktarı fazla! Ürün: %s, İade edilebilir: %d, İstenen: %d",
                        variant.getSku(), returnableQty, qty));
            }

            // Prorata lineTotal üzerinden gerçek iade tutarı (indirim+KDV dahil)
            BigDecimal perUnit = saleItem.getLineTotal()
                    .divide(BigDecimal.valueOf(originalSold), 2, RoundingMode.HALF_UP);
            BigDecimal lineTotal = perUnit.multiply(BigDecimal.valueOf(qty));

            // unitPrice audit için — SaleItem'ın brüt birim fiyatı
            BigDecimal unitPrice = saleItem.getUnitPrice();

            if (returnLocationId != null && !returnLocationId.isBlank()) {
                stockLevelService.addStock(variant.getId(), returnLocationId, returnLocationType, qty);
            }

            StockMovement movement = StockMovement.builder()
                    .variant(variant)
                    .locationId(returnLocationId)
                    .locationType(returnLocationType)
                    .movementType(StockMovementType.SALE_RETURN_IN)
                    .quantity(qty).unitPrice(unitPrice).sale(sale).build();
            prepareAndSave(stockMovementRepository, movement);

            // SaleItem.returnedQuantity güncelle
            saleItem.setReturnedQuantity(alreadyReturned + qty);
            prepareAndSave(saleItemRepository, saleItem);

            totalReturnAmount = totalReturnAmount.add(lineTotal);

            responseItems.add(SaleReturnResponse.ReturnItemResponse.builder()
                    .variantId(variantId).variantSku(variant.getSku())
                    .productName(variant.getProduct() != null ? variant.getProduct().getName() : item.getProductName())
                    .quantity(qty).unitPrice(unitPrice).lineTotal(lineTotal).build());

            returnItemEntities.add(SaleReturnItem.builder()
                    .variant(variant).quantity(qty).unitPrice(unitPrice)
                    .lineTotal(lineTotal).reason(item.getReason()).build());
        }

        BigDecimal effectiveAmount = (request.getTotalReturnAmount() != null
                && request.getTotalReturnAmount().compareTo(BigDecimal.ZERO) > 0)
                ? request.getTotalReturnAmount() : totalReturnAmount;

        String datePart = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String randPart = UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase();
        String returnNumber = "RET-" + datePart + "-" + randPart;

        SaleReturn saleReturn = SaleReturn.builder()
                .returnNumber(returnNumber).sale(sale)
                .reason(request.getReason()).reasonLabel(request.getReasonLabel())
                .notes(request.getNotes()).totalReturnAmount(effectiveAmount)
                .returnDate(LocalDateTime.now()).build();
        SaleReturn savedReturn = prepareAndSave(saleReturnRepository, saleReturn);

        for (SaleReturnItem ri : returnItemEntities) {
            ri.setSaleReturn(savedReturn);
            prepareAndSave(saleReturnItemRepository, ri);
        }

        sale.setReturnedAmount((sale.getReturnedAmount() != null ? sale.getReturnedAmount() : BigDecimal.ZERO).add(effectiveAmount));
        sale.setHasReturn(true);
        save(sale);

        if (sale.getCustomer() != null) {
            Customer customer = sale.getCustomer();
            CustomerAccount account = customerAccountRepository.findByCustomer(customer).orElse(null);
            if (account != null) {
                account.setCurrentBalance(account.getCurrentBalance().subtract(effectiveAmount));
                account.setTotalCredit(account.getTotalCredit().add(effectiveAmount));
                account.updateCalculatedFields();
                prepareAndSave(customerAccountRepository, account);

                AccountTransaction tx = AccountTransaction.builder()
                        .customer(customer).sale(sale).transactionType(TransactionType.RETURN)
                        .debitAmount(BigDecimal.ZERO).creditAmount(effectiveAmount)
                        .balance(account.getCurrentBalance()).referenceId(savedReturn.getId())
                        .referenceType("SALE_RETURN").referenceNumber(returnNumber)
                        .description("Satış iadesi [" + returnNumber + "] - " + request.getReasonLabel())
                        .transactionDate(LocalDateTime.now()).isOverdue(false).isCancelled(false).build();
                prepareAndSave(accountTransactionRepository, tx);
            }
        }

        log.info("Satış iadesi tamamlandı: returnNumber={}, tutar={}", returnNumber, effectiveAmount);
        return SaleReturnResponse.builder()
                .saleId(saleId).saleNumber(sale.getSaleNumber())
                .customerName(sale.getCustomer() != null ? sale.getCustomer().getName() : null)
                .reason(request.getReason()).reasonLabel(request.getReasonLabel())
                .notes(request.getNotes()).totalReturnAmount(effectiveAmount)
                .returnDate(LocalDateTime.now()).items(responseItems)
                .message("Satış iadesi başarıyla oluşturuldu. Stok güncellendi. İade No: " + returnNumber)
                .build();
    }

    // ─── YARDIMCI METODLAR ────────────────────────────────────────────────────

    /**
     * Kredi limiti kontrolü. Sprint 5 (P2.5) — override mekanizması eklendi.
     *
     * Mantık:
     *   1. Limit 0 veya null → check devre dışı (unlimited).
     *   2. Projected balance (currentBalance + saleAmount) > creditLimit:
     *      a) override=false → BUSINESS exception, satış reddedilir.
     *      b) override=true  + kullanıcı ADMIN|STORE_ADMIN → audit log + pass.
     *      c) override=true  + yetkisiz rol → BUSINESS exception (UI zaten göstermemeli; defansif).
     *
     * Not: Authority-based granülarite (CREDIT_LIMIT_OVERRIDE) gelecekteki improvement; şu an
     * JWT filter'ı authority yüklemiyor, role-based çözüm pragmatik.
     */
    private void checkCreditLimit(Customer customer, BigDecimal saleAmount, boolean overrideRequested) {
        if (customer.getCreditLimit() == null || customer.getCreditLimit().compareTo(BigDecimal.ZERO) == 0) return;
        CustomerAccount account = customerAccountRepository.findByCustomer(customer).orElse(null);
        BigDecimal currentBalance = account != null ? account.getCurrentBalance() : BigDecimal.ZERO;
        BigDecimal wouldBe = currentBalance.add(saleAmount);

        if (wouldBe.compareTo(customer.getCreditLimit()) <= 0) {
            return; // limit içinde
        }

        BigDecimal available = customer.getCreditLimit().subtract(currentBalance);
        String limitMsg = String.format(
                "Kredi limiti yetersiz! Kullanılabilir: %s TL, İstenen: %s TL",
                available, saleAmount);

        if (!overrideRequested) {
            throw new RuntimeException(limitMsg + " (ADMIN/STORE_ADMIN override gerekli)");
        }

        if (!currentUserHasCreditLimitOverride()) {
            throw new RuntimeException(limitMsg + " — override yetkisi yok");
        }

        log.warn("Kredi limiti OVERRIDE: customerId={}, kullanici={}, limit={}, projected={}, aşım={}",
                customer.getId(),
                currentUsernameOrSystem(),
                customer.getCreditLimit(),
                wouldBe,
                wouldBe.subtract(customer.getCreditLimit()));
    }

    private boolean currentUserHasCreditLimitOverride() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getAuthorities() == null) return false;
        for (GrantedAuthority a : auth.getAuthorities()) {
            String role = a.getAuthority();
            if ("ROLE_ADMIN".equals(role) || "ROLE_STORE_ADMIN".equals(role)
                    || "CREDIT_LIMIT_OVERRIDE".equals(role)) {
                return true;
            }
        }
        return false;
    }

    private String currentUsernameOrSystem() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null && auth.getName() != null) ? auth.getName() : "SYSTEM";
    }

    private CustomerAccount updateCustomerAccount(Customer customer, Sale sale) {
        CustomerAccount account = customerAccountRepository.findByCustomer(customer)
                .orElseGet(() -> {
                    CustomerAccount na = CustomerAccount.builder().customer(customer)
                            .currentBalance(BigDecimal.ZERO).totalDebt(BigDecimal.ZERO)
                            .totalCredit(BigDecimal.ZERO).overdueAmount(BigDecimal.ZERO)
                            .totalTransactionCount(0L).build();
                    return prepareAndSave(customerAccountRepository, na);
                });
        account.setCurrentBalance(account.getCurrentBalance().add(sale.getRemainingAmount()));
        account.setTotalDebt(account.getTotalDebt().add(sale.getTotalAmount()));
        account.setTotalCredit(account.getTotalCredit().add(sale.getPaidAmount()));
        account.setLastSaleDate(LocalDateTime.now());
        account.setLastTransactionDate(LocalDateTime.now());
        account.setTotalTransactionCount(account.getTotalTransactionCount() + 1);
        account.updateCalculatedFields();
        return prepareAndSave(customerAccountRepository, account);
    }

    private void createCustomerTransaction(Customer customer, Sale sale, CustomerAccount account) {
        AccountTransaction tx = AccountTransaction.builder()
                .customer(customer).sale(sale).transactionType(TransactionType.SALE)
                .debitAmount(sale.getRemainingAmount()).creditAmount(BigDecimal.ZERO)
                .balance(account.getCurrentBalance()).referenceId(sale.getId()).referenceType("SALE")
                .referenceNumber(sale.getSaleNumber())
                .description("Satış - No: " + sale.getSaleNumber())
                .transactionDate(LocalDateTime.now())
                .dueDate(calculateDueDate(sale.getSaleDate().toLocalDate(), customer.getPaymentTermDays()))
                .isOverdue(false).isCancelled(false).build();
        prepareAndSave(accountTransactionRepository, tx);
    }

    private LocalDate calculateDueDate(LocalDate saleDate, Integer paymentTermDays) {
        return saleDate.plusDays(paymentTermDays != null ? paymentTermDays : 30);
    }

    private <E extends TOpenSimpleCompanyEntity> E prepareAndSave(
            org.springframework.data.repository.CrudRepository<E, String> repo, E entity) {
        String companyCode = CompanyContext.get();
        if (companyCode == null || companyCode.isBlank()) companyCode = "SYSTEM";
        if (entity.getCompanyCode() == null || entity.getCompanyCode().isBlank()) entity.setCompanyCode(companyCode);
        if (entity.getCreateTime() == null) entity.setCreateTime(java.util.Calendar.getInstance().getTime());
        if (entity.getCreateUser() == null || entity.getCreateUser().isBlank()) {
            String userCode = null;
            try { userCode = sessionInstanceService.getUserCode(); } catch (Exception ignored) {}
            entity.setCreateUser(userCode != null && !userCode.isBlank() ? userCode : "SYSTEM");
        }
        return repo.save(entity);
    }
}
