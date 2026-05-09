package com.sedcore.sales.repository;

import com.sedcore.sales.entity.Sale;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SaleRepository extends BaseDaoRepository<Sale> {

    Optional<Sale> findBySaleNumber(String saleNumber);

    List<Sale> findByCustomerId(String customerId);

    List<Sale> findByCustomerIdAndIsCancelledFalse(String customerId);

    /**
     * Sprint 11f — Tenant-wide ödenmemiş plakalı satışlar.
     *
     * <p>vehiclePlateSnapshot dolu, isCancelled=false, ve totalAmount > paidAmount
     * olan satışlar; en yeni saleDate üstte. AccountsList plaka modu input
     * boşken bu listeyi gösterir (parçacı sektör senaryosu: kim borçlu plaka
     * sorgusu).</p>
     *
     * <p>customer LEFT JOIN FETCH ile N+1 önlenir (toMap customerName okur).</p>
     */
    @Query("SELECT s FROM Sale s " +
           "LEFT JOIN FETCH s.customer " +
           "WHERE s.isCancelled = false " +
           "  AND s.vehiclePlateSnapshot IS NOT NULL " +
           "  AND s.totalAmount > s.paidAmount " +
           "ORDER BY s.saleDate DESC")
    List<Sale> findOpenWithPlate(Pageable pageable);
}
