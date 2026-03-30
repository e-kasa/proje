package com.sedcore.service.impl;

import com.sedcore.entity.CategoryVariant;
import com.sedcore.enums.AttributeType;
import com.sedcore.model.CategoryVariantResponse;
import com.sedcore.repository.CategoryVariantRepository;
import com.sedcore.service.CategoryService;
import com.sedcore.service.CategoryVariantService;
import com.towpen.base.security.BaseDbServiceImp;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Locale.Category;
import java.util.Optional;

@Service
@Slf4j
@Transactional
public class CategoryVariantServiceImpl extends BaseDbServiceImp<CategoryVariantRepository, CategoryVariant>
        implements CategoryVariantService {

    private final CategoryService categoryService;

    @Autowired
    public CategoryVariantServiceImpl(@Lazy CategoryService categoryService) {
        this.categoryService = categoryService;
    }    

    @Override
    public Class<?> getDTOClassForService() {
        return CategoryVariantResponse.class;
    }

    @Override
    public CategoryVariant addVariantToCategory(String categoryId, String variantKey,
                                               String variantName, AttributeType variantType) {
        // Aynı key varsa hata ver
        if (dao.existsByCategoryIdAndVariantKey(
                categoryId, variantKey)) {
            throw new RuntimeException("Bu varyant anahtarı zaten kullanılıyor: " + variantKey);
        }

        Optional<com.sedcore.entity.Category> category = Optional.ofNullable(categoryService.findById(categoryId).orElseThrow(
            () -> new RuntimeException("Üst kategori bulunamadı: " )
        ));

        CategoryVariant variant = CategoryVariant.builder()
                .category(category.get())
                .variantKey(variantKey)
                .variantName(variantName)
                .variantType(variantType)
                .isRequired(false)
              //  .affectsPrice(false)
               // .affectsStock(true)
               // .showInProductList(true)
               // .enableImagePerVariant(false)
              //  .isActive(true)
              //  .inheritFromParent(true)
                .displayOrder(0)
                .build();

        save(variant);
        log.info("Kategoriye varyant eklendi: Category={}, Key={}, Type={}",
                categoryId, variantKey, variantType);

        return variant;
    }

    @Override
    public CategoryVariant updateCategoryVariant(String variantId, CategoryVariant updates) {
        CategoryVariant variant = dao.findById(variantId)
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + variantId));

        // Güncelle
        if (StringUtils.hasText(updates.getVariantName())) {
            variant.setVariantName(updates.getVariantName());
        }
        if (StringUtils.hasText(updates.getVariantNameEn())) {
            variant.setVariantNameEn(updates.getVariantNameEn());
        }
        if (updates.getVariantType() != null) {
            variant.setVariantType(updates.getVariantType());
        }
        if (updates.getIsRequired() != null) {
            variant.setIsRequired(updates.getIsRequired());
        }
        if (updates.getDisplayOrder() != null) {
            variant.setDisplayOrder(updates.getDisplayOrder());
        }
        if (updates.getOptions() != null) {
            variant.setOptions(updates.getOptions());
        }
       

        save(variant);
        log.info("Kategori varyantı güncellendi: ID={}", variantId);

        return variant;
    }

    @Override
    public void deleteCategoryVariant(String variantId) {
        CategoryVariant variant = dao.findById(variantId)
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + variantId));

      //  variant.setIsActive(false);
        save(variant);
        log.info("Kategori varyantı silindi: ID={}", variantId);
    }

    @Override
    public List<CategoryVariant> getCategoryVariants(String categoryId) {
        return dao.findByCategoryIdAndIsActiveOrderByDisplayOrderAsc(categoryId, true);
    }

    @Override
    public List<CategoryVariant> getRequiredVariants(String categoryId) {
        return dao
                .findByCategoryIdAndIsRequiredAndIsActiveOrderByDisplayOrderAsc(categoryId, true, true);
    }

    @Override
    public CategoryVariant getVariantByKey(String categoryId, String variantKey) {
        return dao.findByCategoryIdAndVariantKey(
                        categoryId, variantKey)
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + variantKey));
    }

    @Override
    public void updateVariantOptions(String variantId, List<String> options) {
        CategoryVariant variant = dao.findById(variantId)
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + variantId));

        variant.setOptions(options);
        save(variant);
        log.info("Varyant seçenekleri güncellendi: ID={}, Options={}", variantId, options.size());
    }

    @Override
    public List<CategoryVariant> getPriceAffectingVariants(String categoryId) {
        return null; // dao                .findByCategoryIdAndAffectsPriceAndIsActiveOrderByDisplayOrderAsc(categoryId, true, true);
    }

    @Override
    public List<CategoryVariant> getStockAffectingVariants(String categoryId) {
        return null;//dao                .findByCategoryIdAndAffectsStockAndIsActiveOrderByDisplayOrderAsc(categoryId, true, true);
    }

    @Override
    public void toggleRequired(String variantId, Boolean isRequired) {
        CategoryVariant variant = dao.findById(variantId)
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + variantId));

        variant.setIsRequired(isRequired);
        save(variant);
        log.info("Varyant zorunluluk durumu değiştirildi: ID={}, Required={}", variantId, isRequired);
    }

    @Override
    public void updateDisplayOrder(String variantId, Integer displayOrder) {
        CategoryVariant variant = dao.findById(variantId)
                .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + variantId));

        variant.setDisplayOrder(displayOrder);
        save(variant);
        log.info("Varyant sırası güncellendi: ID={}, Order={}", variantId, displayOrder);
    }

    @Override
    public boolean variantExists(String categoryId, String variantKey) {
        return dao.existsByCategoryIdAndVariantKey(
                categoryId, variantKey);
    }

    @Override
    public long getVariantCountForCategory(String categoryId) {
        return dao.countByCategoryId(categoryId);
    }

    /**
     * Batch query: Birden fazla kategori için tüm varyantları tek sorguda getir
     * N+1 query problemi çözümü için
     */
    @Override
    public List<CategoryVariant> findByCategoryIds(List<String> categoryIds) {
        if (categoryIds == null || categoryIds.isEmpty()) {
            return List.of();
        }
        log.debug("Batch query: {} kategori için varyantlar getiriliyor", categoryIds.size());
        return dao.findByCategoryIdIn(categoryIds);
    }
}
