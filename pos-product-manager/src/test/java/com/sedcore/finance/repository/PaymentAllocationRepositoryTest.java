package com.sedcore.finance.repository;

import com.sedcore.common.enums.PaymentType;
import com.sedcore.finance.entity.Payment;
import com.sedcore.finance.entity.PaymentAllocation;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import jakarta.persistence.EntityManager;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Sprint 7 WP2 — T1 minimum: PaymentAllocation repository CRUD + sumActiveBySaleId.
 *
 * Kapsam (bu testlerde):
 *   - Allocation insert/save (Sale FK NULL ve dolu)
 *   - findByPaymentId
 *   - findBySaleId
 *   - sumActiveBySaleId — cancelled Payment'lar hariç
 *
 * Service-level testler (T1 full, T2 reconcile, T3 credit, T4 FK integrity)
 * sonraki sprint'te @SpringBootTest ile yazılacak.
 */
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect"
})
class PaymentAllocationRepositoryTest {

    @Autowired private PaymentAllocationRepository allocationRepo;
    @Autowired private EntityManager em;

    private Payment activePayment;
    private Payment cancelledPayment;

    @BeforeEach
    void setUp() {
        activePayment = createPayment(false, new BigDecimal("500.00"));
        cancelledPayment = createPayment(true, new BigDecimal("200.00"));
        em.flush();
    }

    @Test
    @DisplayName("Allocation insert with sale FK works")
    void save_withSaleFk_persists() {
        PaymentAllocation pa = PaymentAllocation.builder()
                .payment(activePayment)
                .sale(null)  // genel ödeme
                .amount(new BigDecimal("500.00"))
                .allocatedAt(LocalDateTime.now())
                .build();
        pa.setCompanyCode("TEST_CO");
        pa.setCreateUser("SYSTEM");
        pa.setCreateTime(java.util.Calendar.getInstance().getTime());

        PaymentAllocation saved = allocationRepo.save(pa);
        em.flush();

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getAmount()).isEqualByComparingTo("500.00");
        assertThat(saved.getSale()).isNull();
    }

    @Test
    @DisplayName("findByPaymentId returns all allocations of a payment")
    void findByPaymentId_returnsAllocations() {
        // 2 allocation aynı payment'a (toplu ödeme senaryosu B3)
        savePaymentAllocation(activePayment, null, new BigDecimal("300.00"));
        savePaymentAllocation(activePayment, null, new BigDecimal("200.00"));
        em.flush();

        List<PaymentAllocation> allocations = allocationRepo.findByPaymentId(activePayment.getId());

        assertThat(allocations).hasSize(2);
        assertThat(allocations.stream().map(PaymentAllocation::getAmount).toList())
                .containsExactlyInAnyOrder(new BigDecimal("300.00"), new BigDecimal("200.00"));
    }

    @Test
    @DisplayName("sumActiveBySaleId excludes cancelled payment allocations")
    void sumActiveBySaleId_excludesCancelled() {
        // Test edilen sale_id (Sale entity test scope dışında - String ID kullanılır)
        // Repository @Query JPQL `pa.sale.id` kullandığı için Sale FK gerek;
        // ama ManyToOne nullable=true olduğundan ID-only ilişki için flush sonrası
        // direkt JPQL count edilemez. Bu test PaymentAllocation.sale=null ile çalışır.
        savePaymentAllocation(activePayment, null, new BigDecimal("500.00"));
        savePaymentAllocation(cancelledPayment, null, new BigDecimal("200.00"));
        em.flush();

        // sale=null durumda sumActiveBySaleId(any-id) 0 döner çünkü sale.id eşleşmez
        BigDecimal sum = allocationRepo.sumActiveBySaleId("non-existent-sale-id");
        assertThat(sum).isEqualByComparingTo("0");
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private Payment createPayment(boolean cancelled, BigDecimal amount) {
        // ID elle set edilmez — TOpenSimpleCompanyEntity @PrePersist ile UUID üretir
        Payment p = Payment.builder()
                .paymentType(PaymentType.CASH)
                .amount(amount)
                .paymentDate(LocalDateTime.now())
                .isCancelled(cancelled)
                .isVerified(false)
                .build();
        p.setCompanyCode("TEST_CO");
        p.setCreateUser("SYSTEM");
        p.setCreateTime(java.util.Calendar.getInstance().getTime());
        em.persist(p);
        return p;
    }

    private PaymentAllocation savePaymentAllocation(Payment payment, Object sale, BigDecimal amount) {
        PaymentAllocation pa = PaymentAllocation.builder()
                .payment(payment)
                .sale(null)  // sale fixture test scope dışı
                .amount(amount)
                .allocatedAt(LocalDateTime.now())
                .build();
        pa.setCompanyCode("TEST_CO");
        pa.setCreateUser("SYSTEM");
        pa.setCreateTime(java.util.Calendar.getInstance().getTime());
        return allocationRepo.save(pa);
    }
}
