package com.sedcore.customer.repository;

import com.sedcore.common.enums.CustomerType;
import com.sedcore.customer.entity.Customer;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerRepository extends BaseDaoRepository<Customer> {

    Optional<Customer> findByBankName(String bankName);

    List<Customer> findAllByOrderByIdAsc();

    // ─── AccountsHub search + stats (DB-side) ──────────────────────────────

    /**
     * Search endpoint — filters in DB, preserves existing controller response shape.
     * :active null → tüm aktiflik durumları; :q null/empty → filtresiz.
     * @EntityGraph(account) — toMap içinde currentBalance okunur, N+1'i önler.
     */
    @EntityGraph(attributePaths = "account")
    @Query("SELECT c FROM Customer c WHERE " +
        "(:active IS NULL OR c.isActive = :active) " +
        "AND (:q IS NULL OR :q = '' " +
        "     OR LOWER(c.name) LIKE LOWER(CONCAT('%', :q, '%')) " +
        "     OR (c.phone IS NOT NULL AND c.phone LIKE CONCAT('%', :q, '%')) " +
        "     OR (c.email IS NOT NULL AND LOWER(c.email) LIKE LOWER(CONCAT('%', :q, '%'))))")
    List<Customer> findBysearch(@Param("q") String q, @Param("active") Boolean active);

    long countByIsActive(Boolean isActive);

    long countByCustomerType(CustomerType type);

}
