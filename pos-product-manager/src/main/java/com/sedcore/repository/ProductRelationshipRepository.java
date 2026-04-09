package com.sedcore.repository;

import com.sedcore.entity.ProductRelationship;
import com.sedcore.enums.ProductRelationType;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Product Relationship Repository
 *
 * Ürün ilişkilerini yönetir (benzer, alternatif, tamamlayıcı ürünler)
 */
@Repository
public interface ProductRelationshipRepository extends BaseDaoRepository<ProductRelationship> {

    /**
     * Kaynak ürüne göre ilişkileri getir (aktif olanlar)
     */
    @Query("SELECT pr FROM ProductRelationship pr " +
           "WHERE pr.sourceProductId = :sourceProductId " +
           "AND pr.isActive = true " +
           "ORDER BY pr.weight DESC")
    List<ProductRelationship> findBySourceProductIdOrderByWeightDesc(
            @Param("sourceProductId") String sourceProductId);

    /**
     * Kaynak ürüne ve tipe göre ilişkileri getir
     */
    @Query("SELECT pr FROM ProductRelationship pr " +
           "WHERE pr.sourceProductId = :sourceProductId " +
           "AND pr.relationType = :relationType " +
           "AND pr.isActive = true " +
           "ORDER BY pr.weight DESC")
    List<ProductRelationship> findBySourceProductIdAndRelationType(
            @Param("sourceProductId") String sourceProductId,
            @Param("relationType") ProductRelationType relationType);

    /**
     * Hedef ürüne göre ilişkileri getir (bu ürün kimin önerisi olarak kullanılıyor?)
     */
    @Query("SELECT pr FROM ProductRelationship pr " +
           "WHERE pr.targetProductId = :targetProductId " +
           "AND pr.isActive = true " +
           "ORDER BY pr.weight DESC")
    List<ProductRelationship> findByTargetProductId(
            @Param("targetProductId") String targetProductId);

    /**
     * Verilen ürün listesinin tümünün ilişkilerini getir
     * (Sepette birden fazla ürün varsa hepsinin önerilerini al)
     */
    @Query("SELECT pr FROM ProductRelationship pr " +
           "WHERE pr.sourceProductId IN :sourceProductIds " +
           "AND pr.isActive = true " +
           "AND pr.targetProductId NOT IN :excludeProductIds " +
           "ORDER BY pr.weight DESC")
    List<ProductRelationship> findRecommendationsForMultipleProducts(
            @Param("sourceProductIds") List<String> sourceProductIds,
            @Param("excludeProductIds") List<String> excludeProductIds);

    /**
     * Belirli türdeki ilişkileri sayfa bazında getir
     * (Admin paneli için sayfalama desteği)
     */
    @Query("SELECT pr FROM ProductRelationship pr " +
           "WHERE pr.relationType = :relationType " +
           "AND pr.isActive = true " +
           "ORDER BY pr.weight DESC, pr.createTime DESC")
    List<ProductRelationship> findByRelationType(
            @Param("relationType") ProductRelationType relationType);

    /**
     * İki ürün arasında ilişki var mı kontrol et
     */
    @Query("SELECT CASE WHEN COUNT(pr) > 0 THEN true ELSE false END " +
           "FROM ProductRelationship pr " +
           "WHERE pr.sourceProductId = :sourceProductId " +
           "AND pr.targetProductId = :targetProductId " +
           "AND pr.isActive = true")
    boolean existsRelation(
            @Param("sourceProductId") String sourceProductId,
            @Param("targetProductId") String targetProductId);

    /**
     * Ürünü silen ürünle ilişkili tüm ilişkileri soft delete (isActive = false)
     */
    @Query("UPDATE ProductRelationship pr " +
           "SET pr.isActive = false " +
           "WHERE (pr.sourceProductId = :productId OR pr.targetProductId = :productId)")
    void deactivateRelationsForProduct(@Param("productId") String productId);
}
