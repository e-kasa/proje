package com.sedcore.autoparts.repository;

import com.sedcore.autoparts.entity.CrossReference;
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

    /**
     * Verilen varyant ID'leriyle aynı cross_ref_number'a sahip
     * FARKLI varyantları (ve ürünlerini) bulur.
     *
     * Örnek: Sepetteki ürünün varyantı "BOSCH-0986" koduna sahipse,
     * aynı koda sahip diğer varyantları döndürür → POS önerisi olarak kullanılır.
     *
     * Sonuç sütunları:
     *   [0] product.id        (String)
     *   [1] product.name      (String)
     *   [2] product.sku       (String)
     *   [3] variant.id        (String)  — eşleşen varyant
     *   [4] cross_ref_brand   (String)  — çapraz referans markası (ör: "Bosch")
     *   [5] cross_ref_number  (String)  — ortak parça numarası
     *   [6] match_count       (Long)    — kaç farklı referans eşleştiği (skor için)
     */
    @Query(value = """
        SELECT p.id, p.name, p.sku, pv.id as variantId,
               cr2.cross_ref_brand, cr2.cross_ref_number,
               COUNT(DISTINCT cr2.cross_ref_number) as match_count
        FROM cross_references cr1
        JOIN cross_references cr2
             ON cr1.cross_ref_number = cr2.cross_ref_number
             AND cr1.variant_id != cr2.variant_id
             AND cr1.company_code = cr2.company_code
        JOIN product_variant pv ON cr2.variant_id = pv.id
        JOIN product p ON pv.product_id = p.id
        WHERE cr1.variant_id IN (:variantIds)
          AND cr1.company_code = :companyCode
          AND p.is_deleted = false
        GROUP BY p.id, p.name, p.sku, pv.id, cr2.cross_ref_brand, cr2.cross_ref_number
        ORDER BY match_count DESC, p.name ASC
        """, nativeQuery = true)
    List<Object[]> findCrossReferencedProducts(
            @Param("variantIds") List<String> variantIds,
            @Param("companyCode") String companyCode);
}
