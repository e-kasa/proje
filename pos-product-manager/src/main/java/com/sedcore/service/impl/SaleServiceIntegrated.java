package com.sedcore.service.impl;

import com.sedcore.context.CompanyContext;
import com.sedcore.entity.*;
import com.sedcore.enums.StockMovementType;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.SaleItemRequest;
import com.sedcore.model.SaleRequest;
import com.sedcore.model.SaleReturnItemRequest;
import com.sedcore.model.SaleReturnRequest;
import com.sedcore.model.SaleReturnResponse;
import com.sedcore.repository.*;
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
    @Autowired private InventoryRepository         inventoryRepository;
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
        // saleNumber gönderilmemişse otomatik üret
        if (request.getSaleNumber() == null || request.getSaleNumber().isBlank()) {
            String datePart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
            String randPart = UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase();
            request.setSaleNumber("POS-" + datePart + "-" + randPart);
        }

        log.info("Satis islemi - Musteri: {}, No: {}", request.getCustomerId(), request.getSaleNumber());

        BigDecimal totalAmount = calculateTotalAmount(request.getItems());

        // 1. MÜŞTERİ KONTROL (null = peşin satış)
        Customer customer = null;
        if (request.getCustomerId() != null) {
            customer = customerRepository.findById(request.getCustomerId())
                    .orElseThrow(() -> new RuntimeException("Musteri bulunamadi: " + request.getCustomerId()));
            checkCreditLimit(customer, totalAmount);
        }

        // 2. SALE OLUŞTUR
        Sale sale = Sale.builder()
                .customer(customer)
                .saleNumber(request.getSaleNumber())
                .saleDate(LocalDateTime.now())
                .totalAmount(totalAmount)
                .paidAmount(request.getPaidAmount() != null ? request.getPaidAmount() : BigDecimal.ZERO)
                .isCancelled(false)
                .hasReturn(false)
                .returnedAmount(BigDecimal.ZERO)
                .notes(request.getNotes())
                .build();

        sale = save(sale);  // BaseDbServiceImp.save() → prepareForInsert() → companyCode set
        log.info("Sale kaydedildi: ID={}, Tutar={}", sale.getId(), sale.getTotalAmount());

        // 3. STOK HAREKETLERİ
        List<StockMovement> movements = new ArrayList<>();
        for (SaleItemRequest item : request.getItems()) {
            ProductVariant variant = variantRepository.findById(item.getVariantId())
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + item.getVariantId()));

            // storeId/warehouseId null gelirse (yönetici mağazaya bağlı değilse),
            // bu varyantın envanter kaydındaki lokasyonu kullan.
            // Aksi halde SALE_OUT hareketi inventory_view'da ayrı bir NULL grubuna
            // düşer ve stok görünümü güncellenmez.
            String effectiveStoreId     = request.getStoreId();
            String effectiveWarehouseId = request.getWarehouseId();
            if (effectiveStoreId == null || effectiveStoreId.isBlank()
                    || effectiveWarehouseId == null || effectiveWarehouseId.isBlank()) {
                // Önce bu varyantın envanter kaydından bul
                List<InventoryView> invList = inventoryRepository.findByVariantId(variant.getId());
                if (!invList.isEmpty()) {
                    // Stoku 0'dan büyük olan kaydı tercih et
                    InventoryView bestInv = invList.stream()
                            .filter(iv -> iv.getPhysicalQuantity() != null && iv.getPhysicalQuantity() > 0)
                            .findFirst()
                            .orElse(invList.get(0));
                    if (effectiveStoreId == null || effectiveStoreId.isBlank()) {
                        if (bestInv.getStoreId() != null && !bestInv.getStoreId().isBlank()) {
                            effectiveStoreId = bestInv.getStoreId();
                        }
                    }
                    if (effectiveWarehouseId == null || effectiveWarehouseId.isBlank()) {
                        if (bestInv.getWarehouseId() != null && !bestInv.getWarehouseId().isBlank()) {
                            effectiveWarehouseId = bestInv.getWarehouseId();
                        }
                    }
                }
                // Hâlâ null ise: bu varyantın ilk PURCHASE_IN hareketinden store/warehouse al
                if (effectiveStoreId == null || effectiveStoreId.isBlank()) {
                    var purchaseOpt = stockMovementRepository
                            .findFirstByVariantIdAndMovementType(variant.getId(), StockMovementType.PURCHASE_IN);
                    if (purchaseOpt.isPresent()) {
                        StockMovement pm = purchaseOpt.get();
                        if (pm.getStoreId() != null && !pm.getStoreId().isBlank()) {
                            effectiveStoreId = pm.getStoreId();
                        }
                        if (pm.getWarehouseId() != null && !pm.getWarehouseId().isBlank()) {
                            effectiveWarehouseId = pm.getWarehouseId();
                        }
                    }
                }
            }

            // Stok kontrolünü effective lokasyonla yap (null storeId hatası önlenir)
            checkStockAvailability(variant.getId(), effectiveStoreId,
                    effectiveWarehouseId, item.getQuantity());

            StockMovement movement = StockMovement.builder()
                    .variant(variant)
                    .storeId(effectiveStoreId)
                    .warehouseId(effectiveWarehouseId)
                    .movementType(StockMovementType.SALE_OUT)
                    .quantity(item.getQuantity())
                    .unitPrice(item.getUnitPrice())
                    .sale(sale)
                    .build();

            movements.add(prepareAndSave(stockMovementRepository, movement));
            log.info("Stok hareketi: Variant={}, Miktar={}, Magaza={}, Depo={}",
                    variant.getSku(), item.getQuantity(), effectiveStoreId, effectiveWarehouseId);
        }

        sale.setMovements(movements);

        // 4. VERESİYE İSE: cari hesap + hareket
        if (sale.isOnCredit()) {
            CustomerAccount account = updateCustomerAccount(customer, sale);
            createCustomerTransaction(customer, sale, account);
        }

        log.info("Satis tamamlandi - Sale ID: {}", sale.getId());
        return sale;
    }

    // ─── SATIŞ İPTAL ─────────────────────────────────────────────────────────

    /**
     * Satış iptali tam akışı:
     * 1. Doğrulama (zaten iptal mi?)
     * 2. Her SALE_OUT için SALE_CANCEL_IN stok hareketi (stok geri al)
     * 3. Müşteri cari hesap güncelle (veresiye satışlar için)
     * 4. AccountTransaction(CANCEL) oluştur
     * 5. Orijinal SALE transaction'ı iptal et
     * 6. Sale.isCancelled = true, cancelReason, cancelDate
     */
    @Transactional
    public Sale cancelSale(String saleId, String reason) {
        // 1. Bul ve doğrula
        Sale sale = findById(saleId)
                .orElseThrow(() -> new RuntimeException("Satis bulunamadi: " + saleId));
        if (Boolean.TRUE.equals(sale.getIsCancelled())) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        // 2. Her SALE_OUT için SALE_CANCEL_IN oluştur (stok geri al)
        List<StockMovement> existingMovements = stockMovementRepository.findBySaleId(saleId, CompanyContext.get());
        for (StockMovement mv : existingMovements) {
            if (mv.getMovementType() != StockMovementType.SALE_OUT) continue;
            StockMovement reversal = StockMovement.builder()
                    .variant(mv.getVariant())
                    .storeId(mv.getStoreId())
                    .warehouseId(mv.getWarehouseId())
                    .movementType(StockMovementType.SALE_CANCEL_IN)
                    .quantity(mv.getQuantity())
                    .unitPrice(mv.getUnitPrice())
                    .sale(sale)
                    .build();
            prepareAndSave(stockMovementRepository, reversal);
            log.info("Iptal stok hareketi: Variant={}, Miktar={}",
                    mv.getVariant().getSku(), mv.getQuantity());
        }

        // 3. Müşteri cari hesabı güncelle (sadece veresiye borç varsa)
        if (sale.getCustomer() != null
                && sale.getRemainingAmount().compareTo(BigDecimal.ZERO) > 0) {

            Customer customer = sale.getCustomer();
            CustomerAccount account = customerAccountRepository
                    .findByCustomer(customer).orElse(null);

            if (account != null) {
                // Satışta eklenen kısmı tam geri al
                account.setCurrentBalance(
                        account.getCurrentBalance().subtract(sale.getRemainingAmount()));
                BigDecimal newDebt = account.getTotalDebt().subtract(sale.getTotalAmount());
                account.setTotalDebt(newDebt.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : newDebt);
                BigDecimal newCredit = account.getTotalCredit().subtract(sale.getPaidAmount());
                account.setTotalCredit(newCredit.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : newCredit);
                account.setLastTransactionDate(LocalDateTime.now());
                account.updateCalculatedFields();
                prepareAndSave(customerAccountRepository, account);
                log.info("Musteri bakiyesi iptal guncellendi - {}, Bakiye: {}",
                        customer.getName(), account.getCurrentBalance());

                // İptal cari hareketi
                AccountTransaction cancelTx = AccountTransaction.builder()
                        .customer(customer)
                        .sale(sale)
                        .transactionType(TransactionType.CANCEL)
                        .debitAmount(BigDecimal.ZERO)
                        .creditAmount(sale.getRemainingAmount())
                        .balance(account.getCurrentBalance())
                        .referenceId(sale.getId())
                        .referenceType("SALE_CANCEL")
                        .referenceNumber(sale.getSaleNumber())
                        .description("Satis Iptali - No: " + sale.getSaleNumber()
                                + " - Sebep: " + reason)
                        .transactionDate(LocalDateTime.now())
                        .isOverdue(false)
                        .isCancelled(false)
                        .build();
                prepareAndSave(accountTransactionRepository, cancelTx);

                // Orijinal SALE transaction'ını iptal et
                List<AccountTransaction> origTxs =
                        accountTransactionRepository.findBySaleId(saleId);
                for (AccountTransaction origTx : origTxs) {
                    if (!Boolean.TRUE.equals(origTx.getIsCancelled())
                            && origTx.getTransactionType() == TransactionType.SALE) {
                        origTx.cancel("system");
                        prepareAndSave(accountTransactionRepository, origTx);
                    }
                }
            }
        }

        // 4. Sale güncelle
        sale.setIsCancelled(true);
        sale.setCancelReason(reason != null && !reason.isBlank() ? reason : "Belirtilmedi");
        sale.setCancelDate(LocalDateTime.now());
        Sale saved = save(sale);
        log.info("Satis iptal edildi: {}, Sebep: {}", saved.getSaleNumber(), reason);
        return saved;
    }

    // ─── SATIŞ İADESİ ────────────────────────────────────────────────────────

    /**
     * Satış iadesi tam akışı:
     * 1. Sale doğrula
     * 2. Her kalem için miktar doğrulaması (sold - already_returned >= requested)
     * 3. SALE_RETURN_IN stok hareketi — orijinal storeId/warehouseId ile
     * 4. SaleReturn + SaleReturnItem kayıtları oluştur
     * 5. Sale.returnedAmount ve hasReturn güncelle
     * 6. Müşteri cari hesap: alacak kaydı
     * 7. AccountTransaction(RETURN) oluştur
     */
    @Transactional
    public SaleReturnResponse createSaleReturn(String saleId, SaleReturnRequest request) {
        log.info("Satis iadesi baslatiliyor - saleId={}, neden={}", saleId, request.getReason());

        // 1. Sale doğrula
        Sale sale = findById(saleId)
                .orElseThrow(() -> new RuntimeException("Satis bulunamadi: " + saleId));
        if (Boolean.TRUE.equals(sale.getIsCancelled())) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        // Orijinal tüm hareketleri tek seferde çek
        List<StockMovement> allMovements = stockMovementRepository.findBySaleId(saleId, CompanyContext.get());

        // Orijinal satış miktarları (SALE_OUT)
        Map<String, Integer>       soldQty          = new HashMap<>();
        Map<String, StockMovement> saleOutByVariant = new HashMap<>();
        for (StockMovement mv : allMovements) {
            if (mv.getMovementType() == StockMovementType.SALE_OUT && mv.getVariant() != null) {
                soldQty.merge(mv.getVariant().getId(),
                        mv.getQuantity() != null ? mv.getQuantity() : 0, Integer::sum);
                saleOutByVariant.put(mv.getVariant().getId(), mv);
            }
        }

        // Daha önce iade edilmiş miktarlar (SALE_RETURN_IN)
        Map<String, Integer> alreadyReturnedQty = new HashMap<>();
        for (StockMovement mv : allMovements) {
            if (mv.getMovementType() == StockMovementType.SALE_RETURN_IN
                    && mv.getVariant() != null) {
                alreadyReturnedQty.merge(mv.getVariant().getId(),
                        mv.getQuantity() != null ? mv.getQuantity() : 0, Integer::sum);
            }
        }

        // 2-3. Her kalem için doğrulama + stok hareketi
        BigDecimal totalReturnAmount = BigDecimal.ZERO;
        List<SaleReturnResponse.ReturnItemResponse> responseItems = new ArrayList<>();
        List<SaleReturnItem> returnItemEntities = new ArrayList<>();

        for (SaleReturnItemRequest item : request.getItems()) {
            String variantId = item.getProductId();
            ProductVariant variant = variantRepository.findById(variantId)
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadi: " + variantId));

            BigDecimal unitPrice = item.getUnitPrice() != null
                    ? item.getUnitPrice() : BigDecimal.ZERO;
            int qty = item.getQuantity() != null ? item.getQuantity() : 0;

            // Miktar doğrulama
            int originalSold  = soldQty.getOrDefault(variantId, 0);
            if (originalSold == 0) {
                throw new RuntimeException(
                        "Bu urun bu satista bulunmuyor: " + variant.getSku());
            }
            int alreadyReturned = alreadyReturnedQty.getOrDefault(variantId, 0);
            int returnableQty   = originalSold - alreadyReturned;
            if (qty > returnableQty) {
                throw new RuntimeException(String.format(
                        "Iade miktari fazla! Urun: %s, Iade edilebilir: %d, Istenen: %d",
                        variant.getSku(), returnableQty, qty));
            }

            // Orijinal satıştan lokasyon al (NULL sorunu düzeltildi)
            StockMovement originalOut = saleOutByVariant.get(variantId);
            String returnStoreId     = originalOut != null ? originalOut.getStoreId()     : null;
            String returnWarehouseId = originalOut != null ? originalOut.getWarehouseId() : null;

            StockMovement movement = StockMovement.builder()
                    .variant(variant)
                    .storeId(returnStoreId)
                    .warehouseId(returnWarehouseId)
                    .movementType(StockMovementType.SALE_RETURN_IN)
                    .quantity(qty)
                    .unitPrice(unitPrice)
                    .sale(sale)
                    .build();
            prepareAndSave(stockMovementRepository, movement);

            BigDecimal lineTotal = unitPrice.multiply(BigDecimal.valueOf(qty));
            totalReturnAmount    = totalReturnAmount.add(lineTotal);

            responseItems.add(SaleReturnResponse.ReturnItemResponse.builder()
                    .variantId(variantId)
                    .variantSku(variant.getSku())
                    .productName(variant.getProduct() != null
                            ? variant.getProduct().getName() : item.getProductName())
                    .quantity(qty)
                    .unitPrice(unitPrice)
                    .lineTotal(lineTotal)
                    .build());

            returnItemEntities.add(SaleReturnItem.builder()
                    .variant(variant)
                    .quantity(qty)
                    .unitPrice(unitPrice)
                    .lineTotal(lineTotal)
                    .reason(item.getReason())
                    .build());
        }

        // totalReturnAmount override kontrolü
        BigDecimal effectiveAmount = (request.getTotalReturnAmount() != null
                && request.getTotalReturnAmount().compareTo(BigDecimal.ZERO) > 0)
                ? request.getTotalReturnAmount() : totalReturnAmount;

        // 4. SaleReturn ana kaydı + kalemleri
        String datePart    = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String randPart    = UUID.randomUUID().toString().replace("-", "").substring(0, 6).toUpperCase();
        String returnNumber = "RET-" + datePart + "-" + randPart;

        SaleReturn saleReturn = SaleReturn.builder()
                .returnNumber(returnNumber)
                .sale(sale)
                .reason(request.getReason())
                .reasonLabel(request.getReasonLabel())
                .notes(request.getNotes())
                .totalReturnAmount(effectiveAmount)
                .returnDate(LocalDateTime.now())
                .build();
        SaleReturn savedReturn = prepareAndSave(saleReturnRepository, saleReturn);

        for (SaleReturnItem ri : returnItemEntities) {
            ri.setSaleReturn(savedReturn);
            prepareAndSave(saleReturnItemRepository, ri);
        }

        // 5. Sale.returnedAmount + hasReturn güncelle
        BigDecimal newReturnedAmount =
                (sale.getReturnedAmount() != null ? sale.getReturnedAmount() : BigDecimal.ZERO)
                        .add(effectiveAmount);
        sale.setReturnedAmount(newReturnedAmount);
        sale.setHasReturn(true);
        save(sale);

        // 6-7. Müşteri cari hesap: alacak kaydı
        if (sale.getCustomer() != null) {
            Customer customer = sale.getCustomer();
            CustomerAccount account = customerAccountRepository
                    .findByCustomer(customer).orElse(null);
            if (account != null) {
                account.setCurrentBalance(
                        account.getCurrentBalance().subtract(effectiveAmount));
                account.setTotalCredit(
                        account.getTotalCredit().add(effectiveAmount));
                account.updateCalculatedFields();
                prepareAndSave(customerAccountRepository, account);

                AccountTransaction tx = AccountTransaction.builder()
                        .customer(customer)
                        .sale(sale)
                        .transactionType(TransactionType.RETURN)
                        .debitAmount(BigDecimal.ZERO)
                        .creditAmount(effectiveAmount)
                        .balance(account.getCurrentBalance())
                        .referenceId(savedReturn.getId())
                        .referenceType("SALE_RETURN")
                        .referenceNumber(returnNumber)
                        .description("Satis iadesi [" + returnNumber + "] - "
                                + request.getReasonLabel()
                                + " - Satis No: " + sale.getSaleNumber())
                        .transactionDate(LocalDateTime.now())
                        .isOverdue(false)
                        .isCancelled(false)
                        .build();
                prepareAndSave(accountTransactionRepository, tx);
                log.info("Musteri cari iadesi kaydedildi - musteri={}, tutar={}",
                        customer.getName(), effectiveAmount);
            }
        }

        log.info("Satis iadesi tamamlandi - returnNumber={}, saleId={}, tutar={}",
                returnNumber, saleId, effectiveAmount);

        return SaleReturnResponse.builder()
                .saleId(saleId)
                .saleNumber(sale.getSaleNumber())
                .customerName(sale.getCustomer() != null
                        ? sale.getCustomer().getName() : null)
                .reason(request.getReason())
                .reasonLabel(request.getReasonLabel())
                .notes(request.getNotes())
                .totalReturnAmount(effectiveAmount)
                .returnDate(LocalDateTime.now())
                .items(responseItems)
                .message("Satis iadesi basariyla olusturuldu. Stok guncellendi. "
                        + "Iade No: " + returnNumber)
                .build();
    }

    // ─── YARDIMCI METODLAR ────────────────────────────────────────────────────

    private void checkCreditLimit(Customer customer, BigDecimal saleAmount) {
        if (customer.getCreditLimit() == null
                || customer.getCreditLimit().compareTo(BigDecimal.ZERO) == 0) {
            return;
        }
        CustomerAccount account = customerAccountRepository
                .findByCustomer(customer).orElse(null);
        BigDecimal currentBalance = account != null
                ? account.getCurrentBalance() : BigDecimal.ZERO;
        BigDecimal wouldBe = currentBalance.add(saleAmount);
        if (wouldBe.compareTo(customer.getCreditLimit()) > 0) {
            BigDecimal available = customer.getCreditLimit().subtract(currentBalance);
            throw new RuntimeException(String.format(
                    "Kredi limiti yetersiz! Kullanilabilir: %s TL, Istenen: %s TL",
                    available, saleAmount));
        }
    }

    private void checkStockAvailability(String variantId, String storeId,
                                        String warehouseId, Integer quantity) {
        int available;
        if (storeId != null && !storeId.isBlank()
                && warehouseId != null && !warehouseId.isBlank()) {
            InventoryView inventory = inventoryRepository
                    .findByVariantIdAndStoreIdAndWarehouseId(variantId, storeId, warehouseId)
                    .orElseThrow(() -> new RuntimeException(
                            "Stok bulunamadi - Variant: " + variantId));
            available = inventory.getPhysicalQuantity() != null
                    ? inventory.getPhysicalQuantity() : 0;
        } else {
            List<InventoryView> inventories = inventoryRepository.findByVariantId(variantId);
            if (inventories.isEmpty()) {
                throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
            }
            available = inventories.stream()
                    .mapToInt(inv -> inv.getPhysicalQuantity() != null
                            ? inv.getPhysicalQuantity() : 0)
                    .sum();
        }
        if (available < quantity) {
            throw new RuntimeException(String.format(
                    "Stok yetersiz! Mevcut: %d, Istenen: %d", available, quantity));
        }
    }

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

        account.setCurrentBalance(
                account.getCurrentBalance().add(sale.getRemainingAmount()));
        account.setTotalDebt(
                account.getTotalDebt().add(sale.getTotalAmount()));
        account.setTotalCredit(
                account.getTotalCredit().add(sale.getPaidAmount()));
        account.setLastSaleDate(LocalDateTime.now());
        account.setLastTransactionDate(LocalDateTime.now());
        account.setTotalTransactionCount(account.getTotalTransactionCount() + 1);
        account.updateCalculatedFields();

        CustomerAccount saved = prepareAndSave(customerAccountRepository, account);
        log.info("Musteri bakiyesi guncellendi - {}, Bakiye: {}",
                customer.getName(), saved.getCurrentBalance());
        return saved;
    }

    private void createCustomerTransaction(Customer customer, Sale sale,
                                           CustomerAccount account) {
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
                .dueDate(calculateDueDate(sale.getSaleDate().toLocalDate(),
                        customer.getPaymentTermDays()))
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
     * Herhangi bir entity için audit alanları + companyCode set ederek kaydeder.
     * BaseDbServiceImp.save() yalnızca Sale için çalışır; diğer entity'ler için bu metod kullanılır.
     */
    private <E extends TOpenSimpleCompanyEntity> E prepareAndSave(
            org.springframework.data.repository.CrudRepository<E, String> repo, E entity) {
        String companyCode = CompanyContext.get();
        if (companyCode == null || companyCode.isBlank()) companyCode = "SYSTEM";
        if (entity.getCompanyCode() == null || entity.getCompanyCode().isBlank()) {
            entity.setCompanyCode(companyCode);
        }
        if (entity.getCreateTime() == null) {
            entity.setCreateTime(java.util.Calendar.getInstance().getTime());
        }
        if (entity.getCreateUser() == null || entity.getCreateUser().isBlank()) {
            String userCode = null;
            try { userCode = sessionInstanceService.getUserCode(); } catch (Exception ignored) {}
            entity.setCreateUser(userCode != null && !userCode.isBlank() ? userCode : "SYSTEM");
        }
        return repo.save(entity);
    }
}
