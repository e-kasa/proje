package com.sedcore.service;

import com.sedcore.entity.CompanyCategory;
import com.sedcore.entity.VariantPricing;
import com.sedcore.model.CompanyCategoryBulkRequest;
import com.sedcore.model.CompanyCategoryRequest;
import com.sedcore.model.CompanyCategoryResponse;
import com.sedcore.model.DtoCategory;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface CompanyCategoryService extends BaseDbService<CompanyCategory> {

    /**
     * Mevcut firmanın seçtiği kategorileri döner (Hibernate filter otomatik çalışır).
     * Flutter/React /my-categories çağrısında kullanılır.
     * Ağaç yapısında (parent-child) döner.
     */
    List<DtoCategory> getMyCategories();

    /**
     * Mevcut firmanın seçtiği kategorileri düz liste olarak döner.
     */
    List<CompanyCategoryResponse> getMyCategoryList();

    /**
     * Firmaya tek bir kategori ekle.
     */
    CompanyCategoryResponse addCategory(CompanyCategoryRequest request);

    /**
     * Firmadan tek bir kategoriyi kaldır.
     */
    void removeCategory(String categoryId);

    /**
     * Firmanın tüm kategori seçimini toplu olarak güncelle.
     * Mevcut seçimler silinir, yeni liste kaydedilir.
     */
    List<CompanyCategoryResponse> bulkSetCategories(CompanyCategoryBulkRequest request);

    /**
     * Firmanın belirli bir kategoriye sahip olup olmadığını kontrol et.
     */
    boolean hasCategory(String categoryId);

    /**
     * Global kategori havuzunu döner — "Kategori Tanımla" ekranı için.
     * Hangileri seçili olduğunu isSelected alanıyla belirtir.
     */
    List<DtoCategory> getAllCategoriesWithSelection();
}
