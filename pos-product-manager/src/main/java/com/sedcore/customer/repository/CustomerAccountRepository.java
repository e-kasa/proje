package com.sedcore.customer.repository;

import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerAccountRepository extends BaseDaoRepository<CustomerAccount> {

    Optional<CustomerAccount> findByCustomer(Customer customer);

    Optional<CustomerAccount> findByCustomerId(String customerId);

    /**
     * Sprint 30 — Overdue notification scheduled job kaynağı.
     *
     * <p>Tetikleyici tenant scope'unda (Hibernate @Filter aktif) çalışır:
     * {@code overdueAmount > 0}, müşteri aktif/silinmemiş, en az bir iletişim
     * kanalı (email veya phone) dolu olanlar.
     *
     * <p>JOIN FETCH ile customer eager → N+1 önler.
     */
    @Query("SELECT a FROM CustomerAccount a "
            + "JOIN FETCH a.customer c "
            + "WHERE a.overdueAmount > 0 "
            + "AND c.isActive = true "
            + "AND c.isDeleted = false "
            + "AND ((c.email IS NOT NULL AND c.email <> '') "
            + "  OR (c.phone IS NOT NULL AND c.phone <> '')) "
            + "ORDER BY a.overdueAmount DESC")
    List<CustomerAccount> findOverdueWithContact();
}
