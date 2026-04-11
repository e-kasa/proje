package com.sedcore.autoparts.repository;

import com.sedcore.autoparts.entity.Vehicle;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VehicleRepository extends BaseDaoRepository<Vehicle> {

    List<Vehicle> findByIsActiveTrueOrderByMakeAscModelAsc();

    List<Vehicle> findAllByOrderByMakeAscModelAsc();

    @Query("SELECT DISTINCT v.make FROM Vehicle v WHERE v.isActive = true ORDER BY v.make")
    List<String> findDistinctMakes();

    @Query("SELECT DISTINCT v.model FROM Vehicle v WHERE v.make = :make AND v.isActive = true ORDER BY v.model")
    List<String> findDistinctModelsByMake(@Param("make") String make);

    @Query("SELECT v FROM Vehicle v WHERE v.isActive = true " +
            "AND (:make IS NULL OR LOWER(v.make) = LOWER(:make)) " +
            "AND (:model IS NULL OR LOWER(v.model) = LOWER(:model)) " +
            "AND (:year IS NULL OR (v.yearStart <= :year AND v.yearEnd >= :year))")
    List<Vehicle> searchVehicles(@Param("make") String make,
                                 @Param("model") String model,
                                 @Param("year") Integer year);
}
