package com.sedcore.finance.repository;

import com.sedcore.finance.entity.AccountTransaction;
import com.sedcore.common.enums.TransactionType;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AccountTransactionRepository extends BaseDaoRepository<AccountTransaction> {

    List<AccountTransaction> findBySupplierId(String supplierId);

    List<AccountTransaction> findBySupplierIdAndTransactionType(String supplierId, TransactionType type);

    List<AccountTransaction> findByPurchaseId(String purchaseId);

    List<AccountTransaction> findByCustomerId(String customerId);

    // Satış bazlı hareketler (iptal sırasında orijinal SALE tx'i bulmak için)
    @Query("SELECT t FROM AccountTransaction t WHERE t.sale.id = :saleId")
    List<AccountTransaction> findBySaleId(@Param("saleId") String saleId);

    // ─── AccountsHub summary / overdue / statement — DB-side aggregate ──────

    /**
     * Özet için 5 scalar değeri tek sorguda döner.
     * Index: idx_overdue_hot (is_cancelled, is_overdue, due_date)
     *
     * Tuple sırası:
     *  [0] totalCustomerReceivable (BigDecimal)
     *  [1] totalSupplierPayable    (BigDecimal)
     *  [2] totalOverdueAmount      (BigDecimal)
     *  [3] overdueTransactionCount (Long)
     *  [4] totalTransactionCount   (Long)
     */
    @Query("SELECT " +
        "  COALESCE(SUM(CASE WHEN t.customer IS NOT NULL THEN t.debitAmount - t.creditAmount ELSE 0 END), 0), " +
        "  COALESCE(SUM(CASE WHEN t.supplier IS NOT NULL THEN t.debitAmount - t.creditAmount ELSE 0 END), 0), " +
        "  COALESCE(SUM(CASE WHEN (t.isOverdue = true OR (t.dueDate IS NOT NULL AND t.dueDate < CURRENT_DATE AND t.debitAmount > 0)) " +
        "                    THEN t.debitAmount - t.creditAmount ELSE 0 END), 0), " +
        "  SUM(CASE WHEN (t.isOverdue = true OR (t.dueDate IS NOT NULL AND t.dueDate < CURRENT_DATE AND t.debitAmount > 0)) THEN 1L ELSE 0L END), " +
        "  COUNT(t) " +
        "FROM AccountTransaction t WHERE t.isCancelled = false")
    Object[] fetchSummaryAggregates();

    /**
     * Vadesi geçmiş hareketler — DB-side filter + sort + LAZY association fetch.
     * Index: idx_overdue_hot + idx_customer_date / idx_supplier_date
     *
     * accountType: null=both | 'CUSTOMER' | 'SUPPLIER'
     */
    @Query("SELECT t FROM AccountTransaction t " +
        "LEFT JOIN FETCH t.customer LEFT JOIN FETCH t.supplier " +
        "WHERE t.isCancelled = false " +
        "AND (t.isOverdue = true OR (t.dueDate IS NOT NULL AND t.dueDate < CURRENT_DATE AND t.debitAmount > 0)) " +
        "AND (:accountType IS NULL " +
        "     OR (:accountType = 'CUSTOMER' AND t.customer IS NOT NULL) " +
        "     OR (:accountType = 'SUPPLIER' AND t.supplier IS NOT NULL)) " +
        "ORDER BY t.dueDate ASC NULLS LAST")
    List<AccountTransaction> findOverdue(@Param("accountType") String accountType);

    /**
     * Müşteri ekstresi — DB-side filter + sort.
     * Index: idx_customer_cancel_date
     */
    @Query("SELECT t FROM AccountTransaction t " +
        "WHERE t.isCancelled = false AND t.customer.id = :id " +
        "AND t.transactionDate >= :start AND t.transactionDate <= :end " +
        "ORDER BY t.transactionDate ASC")
    List<AccountTransaction> findCustomerStatement(
        @Param("id") String id,
        @Param("start") LocalDateTime start,
        @Param("end") LocalDateTime end);

    /**
     * Tedarikçi ekstresi — DB-side filter + sort.
     * Index: idx_supplier_date (prefix)
     */
    @Query("SELECT t FROM AccountTransaction t " +
        "WHERE t.isCancelled = false AND t.supplier.id = :id " +
        "AND t.transactionDate >= :start AND t.transactionDate <= :end " +
        "ORDER BY t.transactionDate ASC")
    List<AccountTransaction> findSupplierStatement(
        @Param("id") String id,
        @Param("start") LocalDateTime start,
        @Param("end") LocalDateTime end);

    /** Açılış bakiyesi (startDate'ten önceki tüm hareketlerin net'i) — müşteri */
    @Query("SELECT COALESCE(SUM(t.debitAmount - t.creditAmount), 0) " +
        "FROM AccountTransaction t WHERE t.isCancelled = false " +
        "AND t.customer.id = :id AND t.transactionDate < :before")
    BigDecimal customerOpeningBalance(
        @Param("id") String id,
        @Param("before") LocalDateTime before);

    /** Açılış bakiyesi (startDate'ten önceki tüm hareketlerin net'i) — tedarikçi */
    @Query("SELECT COALESCE(SUM(t.debitAmount - t.creditAmount), 0) " +
        "FROM AccountTransaction t WHERE t.isCancelled = false " +
        "AND t.supplier.id = :id AND t.transactionDate < :before")
    BigDecimal supplierOpeningBalance(
        @Param("id") String id,
        @Param("before") LocalDateTime before);

    // ─── Drift reconciliation ──────────────────────────────────────────────

    /**
     * Müşteri için ledger'dan hesaplanan totaller.
     * Tuple sırası:
     *  [0] currentBalance    (SUM debit-credit)
     *  [1] totalDebt         (SUM debit)
     *  [2] totalCredit       (SUM credit)
     *  [3] transactionCount  (COUNT)
     *  [4] overdueAmount     (vadesi geçmiş hareketlerin net tutarı — fetchSummaryAggregates ile tutarlı)
     */
    @Query("SELECT COALESCE(SUM(t.debitAmount - t.creditAmount), 0), " +
        "COALESCE(SUM(t.debitAmount), 0), " +
        "COALESCE(SUM(t.creditAmount), 0), " +
        "COUNT(t), " +
        "COALESCE(SUM(CASE WHEN (t.isOverdue = true OR (t.dueDate IS NOT NULL AND t.dueDate < CURRENT_DATE AND t.debitAmount > 0)) " +
        "                   THEN t.debitAmount - t.creditAmount ELSE 0 END), 0) " +
        "FROM AccountTransaction t WHERE t.isCancelled = false AND t.customer.id = :id")
    Object[] ledgerTotalsForCustomer(@Param("id") String customerId);

    /** Tedarikçi için ledger'dan hesaplanan totaller. Tuple: bkz. ledgerTotalsForCustomer. */
    @Query("SELECT COALESCE(SUM(t.debitAmount - t.creditAmount), 0), " +
        "COALESCE(SUM(t.debitAmount), 0), " +
        "COALESCE(SUM(t.creditAmount), 0), " +
        "COUNT(t), " +
        "COALESCE(SUM(CASE WHEN (t.isOverdue = true OR (t.dueDate IS NOT NULL AND t.dueDate < CURRENT_DATE AND t.debitAmount > 0)) " +
        "                   THEN t.debitAmount - t.creditAmount ELSE 0 END), 0) " +
        "FROM AccountTransaction t WHERE t.isCancelled = false AND t.supplier.id = :id")
    Object[] ledgerTotalsForSupplier(@Param("id") String supplierId);
}
