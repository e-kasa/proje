package com.sedcore.repository;

import com.sedcore.entity.OemNumber;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OemNumberRepository extends BaseDaoRepository<OemNumber> {

    List<OemNumber> findByVariantIdOrderByIsPrimaryDesc(String variantId);

    @Query("SELECT o FROM OemNumber o WHERE LOWER(o.oemNumber) LIKE LOWER(CONCAT('%', :q, '%'))")
    List<OemNumber> searchByOemNumber(@Param("q") String q);

    List<OemNumber> findByOemNumberIgnoreCase(String oemNumber);
}
