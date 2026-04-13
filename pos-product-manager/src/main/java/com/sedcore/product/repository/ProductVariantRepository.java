package com.sedcore.product.repository;

import com.sedcore.product.entity.ProductVariant;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductVariantRepository extends BaseDaoRepository<ProductVariant> {

    // ── Tekil erişim ──────────────────────────────────────────────────────────

    /** Hibernate @Filter companyCode izolasyonunu otomatik sağlar; soft-delete filtresi ile birlikte */
    Optional<ProductVariant> findByIdAndIsDeleted(String id, Boolean isDeleted);

    /** companyCode + id — double safety (tenant sızıntısı koruması) */
    Optional<ProductVariant> findByIdAndCompanyCodeAndIsDeletedFalse(String id, String companyCode);

    // ── SKU sorguları ─────────────────────────────────────────────────────────

    @Query("SELECT pv FROM ProductVariant pv WHERE pv.sku = :sku AND pv.isDeleted = :isDeleted")
    Optional<ProductVariant> findBySkuAndIsDeleted(@Param("sku") String sku, @Param("isDeleted") Boolean isDeleted);

    /** SKU ile firma içinde arama — double safety */
    Optional<ProductVariant> findBySkuAndCompanyCodeAndIsDeletedFalse(String sku, String companyCode);

    // ── Ürüne ait varyantlar ──────────────────────────────────────────────────

    List<ProductVariant> findByProductIdAndIsDeleted(String productId, Boolean isDeleted);

    /** Ürüne ait aktif varyantlar — companyCode double safety ile */
    List<ProductVariant> findByProductIdAndCompanyCodeAndIsDeletedFalse(String productId, String companyCode);

    // ── Firma geneli liste ────────────────────────────────────────────────────

    /** Firmaya ait tüm aktif varyantlar (Hibernate @Filter + açık companyCode) */
    List<ProductVariant> findByCompanyCodeAndIsDeletedFalse(String companyCode);

    // ── Benzersizlik kontrolleri ──────────────────────────────────────────────

    /** Güncelleme sırasında SKU çakışma kontrolü — global (Hibernate @Filter filtreler) */
    boolean existsBySkuAndIdNot(String sku, String id);

    /** SKU çakışma kontrolü — firma kapsamında double safety */
    boolean existsBySkuAndCompanyCodeAndIdNot(String sku, String companyCode, String id);

    /** Yeni oluşturma sırasında SKU çakışma kontrolü */
    boolean existsBySkuAndCompanyCode(String sku, String companyCode);
}
