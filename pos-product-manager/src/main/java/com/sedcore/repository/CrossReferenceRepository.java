package com.sedcore.repository;

import com.sedcore.entity.CrossReference;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CrossReferenceRepository extends BaseDaoRepository<CrossReference> {

    List<CrossReference> findByVariantIdOrderByCrossRefBrandAsc(String variantId);

    @Query("SELECT cr FROM CrossReference cr WHERE LOWER(cr.crossRefNumber) LIKE LOWER(CONCAT('%', :q, '%'))")
    List<CrossReference> searchByCrossRefNumber(@Param("q") String q);

    List<CrossReference> findByCrossRefNumberIgnoreCase(String crossRefNumber);
}
