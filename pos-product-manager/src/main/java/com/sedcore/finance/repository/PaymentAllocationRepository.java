package com.sedcore.finance.repository;

import com.sedcore.finance.entity.PaymentAllocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

/**
 * PaymentAllocation repository.
 *
 * Multi-tenant filter (filterByCompanyCode) Hibernate @Filter ile otomatik —
 * native query'lerde manuel WHERE company_code eklenir.
 */
@Repository
public interface PaymentAllocationRepository extends JpaRepository<PaymentAllocation, String> {

    /** Bir payment'a ait tüm allocation kayıtları (tipik 1, B3 sonrası N). */
    List<PaymentAllocation> findByPaymentId(String paymentId);

    /** Bir satışa yapılmış tüm ödeme allocation'ları. */
    List<PaymentAllocation> findBySaleId(String saleId);

    /**
     * Bir satışa yapılan toplam ödeme tutarı (Sale.paidAmount derivasyonu için).
     * İptal edilmiş Payment'lar hariç.
     */
    @Query("""
            SELECT COALESCE(SUM(pa.amount), 0)
            FROM PaymentAllocation pa
            WHERE pa.sale.id = :saleId
              AND (pa.payment.isCancelled IS NULL OR pa.payment.isCancelled = false)
            """)
    BigDecimal sumActiveBySaleId(@Param("saleId") String saleId);
}
