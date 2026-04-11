package com.sedcore.autoparts.repository;

import com.sedcore.autoparts.entity.VehicleCompatibility;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VehicleCompatibilityRepository extends BaseDaoRepository<VehicleCompatibility> {

    List<VehicleCompatibility> findByVariantId(String variantId);

    List<VehicleCompatibility> findByVehicleId(String vehicleId);

    @Query("""
            SELECT vc FROM VehicleCompatibility vc JOIN vc.vehicle v
            WHERE (:make IS NULL OR LOWER(v.make) = LOWER(:make))
            AND (:model IS NULL OR LOWER(v.model) = LOWER(:model))
            AND (:year IS NULL OR (v.yearStart <= :year AND v.yearEnd >= :year))
            """)
    List<VehicleCompatibility> searchByVehicle(@Param("make") String make,
                                                @Param("model") String model,
                                                @Param("year") Integer year);
}
