package com.sedcore.sales.service.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.sales.entity.Sale;
import com.sedcore.sales.entity.SaleReturn;
import com.sedcore.sales.entity.SaleReturnItem;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
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
    @Autowired private SaleReturnRepository        saleReturnRepository;
    @Autowired private SaleReturnItemRepository    saleReturnItemRepository;
    @Autowired private ISessionInstanceService     sessionInstanceService;

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

        BigDecimal totalAmount = calculateTotalAmount(request.getItems());

        // 1. MÜŞTERİ KONTROL
        Customer customer = null;
        if (request.getCustomerId() != null) {
            customer = customerRepository.findById(request.getCustomerId())
                    .orElseThrow(() -> new RuntimeException("Müşteri bulunamadı: " + request.getCustomerId()));
            checkCreditLimit(customer, totalAmount);
        }

        // 2. SALE OLUŞTUR
        Sale sale = Sale.builder()
                .customer(customer)
                .saleNumber(request.getSaleNumber())
                .saleDate(LocalDateTime.now())
                .totalAmount(totalAmount)
                .paidAmount(request.getPaidAmount() != null ? request.getPaidAmount() : BigDecimal.ZERO)
                .locationId(request.getLocationId())
                .locationType(request.getLocationType() != null ? request.getLocationType() : "STORE")
                .isCancelled(false)
                .hasReturn(false)
                .returnedAmount(BigDecimal.ZERO)
                .notes(request.getNotes())
                .build();

        sale = save(sale);
        log.info("Sale kaydedildi: ID={}, Tutar={}", sale.getId(), sale.getTotalAmount());

        // 3. STOK HAREKETLERİ + StockLevel atomic decrement
        String effectiveLocationId = request.getLocationId();
        String effectiveLocationType = request.getLocationType() != null ? request.getLocationType() : "STORE";

        List<StockMovement> movements = new ArrayList<>();
        for (SaleItemRequest item : request.getItems()) {
            ProductVariant variant = variantRepository.findById(item.getVariantId())
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + item.getVariantId()));

            // StockLevel atomic deduct — pessimistic lock ile race condition önlenir
            if (effectiveLocationId != null && !effectiveLocationId.isBlank()) {
                stockLevelService.deductStock(variant.getId(), effectiveLocationId, item.getQuantity());
            }

            // Audit kaydı
            StockMovement movement = StockMovement.builder()
                    .variant(variant)
                    .locationId(effectiveLocationId)
                    .locationType(effectiveLocationType)
                    .movementType(StockMovementType.SALE_OUT)
                    .quantity(item.getQuantity())
                    .unitPrice(item.getUnitPrice())
                    .sale(sale)
                    .build();
            movements.add(prepareAndSave(stockMovementRepository, movement));

            log.info("Stok hareketi: Variant={}, Miktar={}, Lokasyon={}",
                    variant.getSku(), item.getQuantity(), effectiveLocationId);
        }

        sale.setMovements(movements);

        // 4. VERESİYE: cari hesap + hareket
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

        List<StockMovement> allMovements = stockMovementRepository.findBySaleId(saleId, CompanyContext.get());

        Map<String, Integer> soldQty = new HashMap<>();
        Map<String, StockMovement> saleOutByVariant = new HashMap<>();
        for (StockMovement mv : allMovements) {
            if (mv.getMovementType() == StockMovementType.SALE_OUT && mv.getVariant() != null) {
                soldQty.merge(mv.getVariant().getId(), mv.getQuantity() != null ? mv.getQuantity() : 0, Integer::sum);
                saleOutByVariant.put(mv.getVariant().getId(), mv);
            }
        }

        Map<String, Integer> alreadyReturnedQty = new HashMap<>();
        for (StockMovement mv : allMovements) {
            if (mv.getMovementType() == StockMovementType.SALE_RETURN_IN && mv.getVariant() != null) {
                alreadyReturnedQty.merge(mv.getVariant().getId(), mv.getQuantity() != null ? mv.getQuantity() : 0, Integer::sum);
            }
        }

        BigDecimal totalReturnAmount = BigDecimal.ZERO;
        List<SaleReturnResponse.ReturnItemResponse> responseItems = new ArrayList<>();
        List<SaleReturnItem> returnItemEntities = new ArrayList<>();

        for (SaleReturnItemRequest item : request.getItems()) {
            String variantId = item.getProductId();
            ProductVariant variant = variantRepository.findById(variantId)
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + variantId));

            BigDecimal unitPrice = item.getUnitPrice() != null ? item.getUnitPrice() : BigDecimal.ZERO;
            int qty = item.getQuantity() != null ? item.getQuantity() : 0;

            int originalSold = soldQty.getOrDefault(variantId, 0);
            if (originalSold == 0) throw new RuntimeException("Bu ürün bu satışta bulunmuyor: " + variant.getSku());
            int alreadyReturned = alreadyReturnedQty.getOrDefault(variantId, 0);
            int returnableQty = originalSold - alreadyReturned;
            if (qty > returnableQty) {
                throw new RuntimeException(String.format("İade miktarı fazla! Ürün: %s, İade edilebilir: %d, İstenen: %d",
                        variant.getSku(), returnableQty, qty));
            }

            // Orijinal satışın lokasyonunu kullan
            StockMovement originalOut = saleOutByVariant.get(variantId);
            String returnLocationId  = originalOut != null ? originalOut.getLocationId()  : null;
            String returnLocationType = originalOut != null ? originalOut.getLocationType() : "STORE";

            // StockLevel geri ekle
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

            BigDecimal lineTotal = unitPrice.multiply(BigDecimal.valueOf(qty));
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

    private void checkCreditLimit(Customer customer, BigDecimal saleAmount) {
        if (customer.getCreditLimit() == null || customer.getCreditLimit().compareTo(BigDecimal.ZERO) == 0) return;
        CustomerAccount account = customerAccountRepository.findByCustomer(customer).orElse(null);
        BigDecimal currentBalance = account != null ? account.getCurrentBalance() : BigDecimal.ZERO;
        BigDecimal wouldBe = currentBalance.add(saleAmount);
        if (wouldBe.compareTo(customer.getCreditLimit()) > 0) {
            BigDecimal available = customer.getCreditLimit().subtract(currentBalance);
            throw new RuntimeException(String.format(
                    "Kredi limiti yetersiz! Kullanılabilir: %s TL, İstenen: %s TL", available, saleAmount));
        }
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

    private BigDecimal calculateTotalAmount(List<SaleItemRequest> items) {
        return items.stream()
                .map(i -> i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
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
