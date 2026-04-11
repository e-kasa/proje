package com.sedcore.catalog.repository;

import com.sedcore.catalog.entity.CompanyCategory;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Hibernate @Filter otomatik çalışır: tüm sorgular company_code'a göre filtrelenir.
 * Manuel company_code parametresi gerekmez.
 */
@Repository
public interface CompanyCategoryRepository extends BaseDaoRepository<CompanyCategory> {

    // Firma'nın aktif kategorilerini getir — category + parentCategory JOIN FETCH ile N+1 önler
    @EntityGraph(attributePaths = {"category", "category.parentCategory"})
    List<CompanyCategory> findByIsActiveTrueOrderByDisplayOrderAsc();

    // Firma'nın tüm kategorilerini getir (aktif + pasif)
    List<CompanyCategory> findAllByOrderByDisplayOrderAsc();

    // Belirli bir kategori var mı? (company_code Hibernate filter'dan gelir)
    Optional<CompanyCategory> findByCategoryId(String categoryId);

    // Sadece category_id listesi çek — ağaç oluşturmak için
    @Query("SELECT cc.categoryId FROM CompanyCategory cc WHERE cc.isActive = true")
    List<String> findActiveCategoryIds();

    // company_code + categoryId ile bul (filter bypass için @Query kullanılır)
    @Query("SELECT cc FROM CompanyCategory cc WHERE cc.companyCode = :companyCode AND cc.categoryId = :categoryId")
    Optional<CompanyCategory> findByCompanyCodeAndCategoryId(
            @Param("companyCode") String companyCode,
            @Param("categoryId") String categoryId
    );

    // Belirli firma'nın seçtiği category_id'leri getir (filter bypass)
    @Query("SELECT cc.categoryId FROM CompanyCategory cc WHERE cc.companyCode = :companyCode AND cc.isActive = true")
    List<String> findActiveCategoryIdsByCompanyCode(@Param("companyCode") String companyCode);
}
