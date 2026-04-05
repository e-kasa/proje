package com.sedcore.service.impl;

import com.sedcore.context.CompanyContext;
import com.sedcore.entity.*;
import com.sedcore.enums.StockMovementType;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.SaleItemRequest;
import com.sedcore.model.SaleRequest;
import com.sedcore.repository.*;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

@Service
@Slf4j
@Transactional
public class SaleServiceIntegrated
        extends BaseDbServiceImp<SaleRepository, Sale> {

    @Autowired private StockMovementRepository stockMovementRepository;
    @Autowired private CustomerRepository customerRepository;
    @Autowired private CustomerAccountRepository customerAccountRepository;
    @Autowired private AccountTransactionRepository accountTransactionRepository;
    @Autowired private ProductVariantRepository variantRepository;
    @Autowired private InventoryRepository inventoryRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return Sale.class;
    }

    @Transactional
    public Sale createSale(SaleRequest request) {
        log.info("Satis islemi - Musteri: {}, No: {}", request.getCustomerId(), request.getSaleNumber());

        BigDecimal totalAmount = calculateTotalAmount(request.getItems());

        // 1. MUSTERI KONTROL (null = pesin satis)
        Customer customer = null;
        if (request.getCustomerId() != null) {
            customer = customerRepository.findById(request.getCustomerId())
                    .orElseThrow(() -> new RuntimeException("Musteri bulunamadi: " + request.getCustomerId()));
            checkCreditLimit(customer, totalAmount);
        }

        // 2. SALE OLUSTUR
        Sale sale = Sale.builder()
                .customer(customer)
                .saleNumber(request.getSaleNumber())
                .saleDate(LocalDateTime.now())
                .totalAmount(totalAmount)
                .paidAmount(request.getPaidAmount() != null ? request.getPaidAmount() : BigDecimal.ZERO)
                .isCancelled(false)
                .notes(request.getNotes())
                .build();

        sale = save(sale);  // BaseDbServiceImp.save() → prepareForInsert() → companyCode set
        log.info("Sale kaydedildi: ID={}, Tutar={}", sale.getId(), sale.getTotalAmount());

        // 3. STOK HAREKETLERI
        List<StockMovement> movements = new ArrayList<>();
        for (SaleItemRequest item : request.getItems()) {
            ProductVariant variant = variantRepository.findById(item.getVariantId())
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + item.getVariantId()));

            checkStockAvailability(variant.getId(), request.getStoreId(),
                    request.getWarehouseId(), item.getQuantity());

            StockMovement movement = StockMovement.builder()
                    .variant(variant)
                    .storeId(request.getStoreId())
                    .warehouseId(request.getWarehouseId())
                    .movementType(StockMovementType.SALE_OUT)
                    .quantity(item.getQuantity())
                    .sale(sale)
                    .build();

            movements.add(prepareAndSave(stockMovementRepository, movement));
            log.info("Stok hareketi: Variant={}, Miktar={}", variant.getSku(), item.getQuantity());
        }

        sale.setMovements(movements);

        // 4. VERESIYE ISE: cari hesap + hareket
        if (sale.isOnCredit()) {
            CustomerAccount account = updateCustomerAccount(customer, sale);
            createCustomerTransaction(customer, sale, account);
        }

        log.info("Satis tamamlandi - Sale ID: {}", sale.getId());
        return sale;
    }

    /**
     * Kredi limiti kontrolu.
     * Limit tanimli degilse veya 0 ise kontrol yapilmaz.
     */
    private void checkCreditLimit(Customer customer, BigDecimal saleAmount) {
        if (customer.getCreditLimit() == null
                || customer.getCreditLimit().compareTo(BigDecimal.ZERO) == 0) {
            return;
        }
        CustomerAccount account = customerAccountRepository.findByCustomer(customer).orElse(null);
        BigDecimal currentBalance = account != null ? account.getCurrentBalance() : BigDecimal.ZERO;
        BigDecimal wouldBe = currentBalance.add(saleAmount);
        if (wouldBe.compareTo(customer.getCreditLimit()) > 0) {
            BigDecimal available = customer.getCreditLimit().subtract(currentBalance);
            throw new RuntimeException(String.format(
                    "Kredi limiti yetersiz! Kullanilabilir: %s TL, Istenen: %s TL",
                    available, saleAmount));
        }
    }

    /**
     * Stok kontrolu.
     * InventoryView read-only (DB view, @Immutable) - sadece okuma yapilir.
     */
    private void checkStockAvailability(String variantId, String storeId,
                                        String warehouseId, Integer quantity) {
        InventoryView inventory = inventoryRepository
                .findByVariantIdAndStoreIdAndWarehouseId(variantId, storeId, warehouseId)
                .orElseThrow(() -> new RuntimeException("Stok bulunamadi - Variant: " + variantId));

        int available = inventory.getPhysicalQuantity() != null ? inventory.getPhysicalQuantity() : 0;
        if (available < quantity) {
            throw new RuntimeException(String.format(
                    "Stok yetersiz! Mevcut: %d, Istenen: %d", available, quantity));
        }
    }

    /**
     * Musteri cari hesap guncelleme.
     * Hesap yoksa otomatik olusturulur.
     * Donus: guncellenen CustomerAccount (createCustomerTransaction icin)
     */
    private CustomerAccount updateCustomerAccount(Customer customer, Sale sale) {
        CustomerAccount account = customerAccountRepository.findByCustomer(customer)
                .orElseGet(() -> {
                    CustomerAccount na = CustomerAccount.builder()
                            .customer(customer)
                            .currentBalance(BigDecimal.ZERO)
                            .totalDebt(BigDecimal.ZERO)
                            .totalCredit(BigDecimal.ZERO)
                            .overdueAmount(BigDecimal.ZERO)
                            .totalTransactionCount(0L)
                            .build();
                    return prepareAndSave(customerAccountRepository, na);
                });

        account.setCurrentBalance(account.getCurrentBalance().add(sale.getRemainingAmount()));
        account.setTotalDebt(account.getTotalDebt().add(sale.getTotalAmount()));
        account.setTotalCredit(account.getTotalCredit().add(sale.getPaidAmount()));
        account.setLastSaleDate(LocalDateTime.now());
        account.setLastTransactionDate(LocalDateTime.now());
        account.setTotalTransactionCount(account.getTotalTransactionCount() + 1);
        account.updateCalculatedFields();

        CustomerAccount saved = prepareAndSave(customerAccountRepository, account);
        log.info("Musteri bakiyesi guncellendi - {}, Bakiye: {}",
                customer.getName(), saved.getCurrentBalance());
        return saved;
    }

    /**
     * Cari hesap hareketi kaydet.
     * CustomerAccount parametre olarak alinir - Lazy load NPE onlenir.
     */
    private void createCustomerTransaction(Customer customer, Sale sale, CustomerAccount account) {
        AccountTransaction tx = AccountTransaction.builder()
                .customer(customer)
                .sale(sale)
                .transactionType(TransactionType.SALE)
                .debitAmount(sale.getRemainingAmount())
                .creditAmount(BigDecimal.ZERO)
                .balance(account.getCurrentBalance())
                .referenceId(sale.getId())
                .referenceType("SALE")
                .referenceNumber(sale.getSaleNumber())
                .description("Satis - No: " + sale.getSaleNumber())
                .transactionDate(LocalDateTime.now())
                .dueDate(calculateDueDate(sale.getSaleDate().toLocalDate(), customer.getPaymentTermDays()))
                .isOverdue(false)
                .isCancelled(false)
                .build();

        prepareAndSave(accountTransactionRepository, tx);
        log.info("Cari hareket kaydedildi - Tutar: {}, Vade: {}",
                tx.getDebitAmount(), tx.getDueDate());
    }

    private BigDecimal calculateTotalAmount(List<SaleItemRequest> items) {
        return items.stream()
                .map(i -> i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private LocalDate calculateDueDate(LocalDate saleDate, Integer paymentTermDays) {
        return saleDate.plusDays(paymentTermDays != null ? paymentTermDays : 30);
    }

    /**
     * BaseDbServiceImp.save() sadece Sale entity'si icin calisir.
     * Diger entity'lere (StockMovement, CustomerAccount, AccountTransaction)
     * companyCode ve createTime bilgilerini manuel set eder.
     */
    private <E extends TOpenSimpleCompanyEntity> E prepareAndSave(
            org.springframework.data.repository.CrudRepository<E, String> repo, E entity) {
        // companyCode: CompanyContext (ThreadLocal) → fallback "syste"
        String companyCode = CompanyContext.get();
        if (companyCode == null || companyCode.isBlank()) {
            companyCode = "syste";
        }
        if (entity.getCompanyCode() == null || entity.getCompanyCode().isBlank()) {
            entity.setCompanyCode(companyCode);
        }
        if (entity.getCreateTime() == null) {
            entity.setCreateTime(Calendar.getInstance().getTime());
        }
        return repo.save(entity);
    }
}
