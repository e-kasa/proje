package com.sedcore.customer.repository;

import com.sedcore.customer.entity.CustomerVehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Sprint 9 — CustomerVehicle repository.
 * Multi-tenant filter (filterByCompanyCode) Hibernate @Filter ile otomatik
 * (TOpenSimpleCompanyEntity inherited).
 */
@Repository
public interface CustomerVehicleRepository extends JpaRepository<CustomerVehicle, String> {

    /** Bir müşterinin tüm aktif plakaları, plaka adına göre sıralı. */
    List<CustomerVehicle> findByCustomerIdAndIsActiveOrderByPlateDisplay(
            String customerId, Boolean isActive);

    /**
     * Plaka prefix arama (autocomplete).
     * Sadece aktif kayıtlar; case-insensitive normalized contains.
     */
    @Query("SELECT cv FROM CustomerVehicle cv " +
           "WHERE cv.customer.id = :customerId " +
           "  AND cv.isActive = true " +
           "  AND LOWER(cv.plateNormalized) LIKE LOWER(CONCAT('%', :q, '%')) " +
           "ORDER BY cv.plateDisplay ASC")
    List<CustomerVehicle> searchByCustomer(@Param("customerId") String customerId,
                                            @Param("q") String q);

    /** Idempotent upsert için: aynı plaka + müşteri varsa döner. */
    Optional<CustomerVehicle> findByCustomerIdAndPlateNormalized(
            String customerId, String plateNormalized);
}
