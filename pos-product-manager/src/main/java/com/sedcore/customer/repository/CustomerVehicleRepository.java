package com.sedcore.customer.repository;

import com.sedcore.customer.entity.CustomerVehicle;
import com.sedcore.customer.model.VehicleSearchResponse;
import org.springframework.data.domain.Pageable;
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

    /**
     * Sprint 11e — Tenant-wide plaka prefix arama (customerId YOK).
     *
     * <p>AccountsList plaka modu için: müşteri ismi bilinmeden plaka ara →
     * her plaka için müşteri + açık satış özeti tek query'de aggregation.</p>
     *
     * <p>LEFT JOIN Sale: aynı tenant'taki tüm satışlardan
     * {@code vehiclePlateSnapshot} eşleşenlerin {@code (totalAmount - paidAmount) > 0}
     * olanlarını sayar/toplar. Tenant filtresi Hibernate
     * {@code @Filter(filterByCompanyCode)} ile otomatik aktif (her iki entity de
     * {@code TOpenSimpleCompanyEntity}).</p>
     *
     * <p>Performans: tek query, N+1 yok. Plaka boyu kısa (~10 sonuç limit).
     * {@code idx_cv_plate_normalized} ve {@code idx_sales_vehicle_plate_snapshot}
     * (Sprint 9 migration) prefix scan + nested loop join'i hızlandırır.</p>
     */
    @Query("SELECT new com.sedcore.customer.model.VehicleSearchResponse(" +
           "  cv.id, cv.customer.id, cv.customer.name, cv.plateDisplay, cv.plateNormalized, " +
           "  cv.make, cv.model, " +
           "  COUNT(s), COALESCE(SUM(s.totalAmount - s.paidAmount), 0)" +
           ") " +
           "FROM CustomerVehicle cv " +
           "LEFT JOIN com.sedcore.sales.entity.Sale s " +
           "  ON s.vehiclePlateSnapshot = cv.plateNormalized " +
           "  AND s.isCancelled = false " +
           "  AND s.totalAmount > s.paidAmount " +
           "WHERE cv.isActive = true " +
           "  AND LOWER(cv.plateNormalized) LIKE LOWER(CONCAT(:q, '%')) " +
           "GROUP BY cv.id, cv.customer.id, cv.customer.name, cv.plateDisplay, " +
           "         cv.plateNormalized, cv.make, cv.model " +
           "ORDER BY cv.plateDisplay ASC")
    List<VehicleSearchResponse> searchByPlate(@Param("q") String q, Pageable pageable);
}
