package com.sedcore.service.impl;

import com.sedcore.entity.CategoryAttribute;
import com.sedcore.enums.AttributeType;
import com.sedcore.model.CategoryAttributeResponse;
import com.sedcore.repository.CategoryAttributeRepository;
import com.sedcore.service.CategoryAttributeService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;

@Service
@Slf4j
@Transactional
public class CategoryAttributeServiceImpl extends BaseDbServiceImp<CategoryAttributeRepository, CategoryAttribute>
        implements CategoryAttributeService {

    @Override
    public Class<?> getDTOClassForService() {
        return CategoryAttributeResponse.class;
    }

    @Override
    public CategoryAttribute addAttributeToCategory(String categoryId, String attributeKey,
                                                    String attributeName, AttributeType attributeType) {
        // Aynı key varsa hata ver
        if (dao.existsByCategoryIdAndAttributeKey(
                categoryId, attributeKey)) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        CategoryAttribute attribute = CategoryAttribute.builder()
                //.categoryId(categoryId)
                .attributeKey(attributeKey)
                .attributeName(attributeName)
                .attributeType(attributeType)
                .isRequired(false)
                .isFilterable(true)
               // .isSearchable(false)
               // .isComparable(false)
                .isActive(true)
                //.inheritFromParent(true)
               // .displayOrder(0)
                .build();

        save(attribute);
        log.info("Kategoriye özellik eklendi: Category={}, Key={}, Type={}",
                categoryId, attributeKey, attributeType);

        return attribute;
    }

    @Override
    public CategoryAttribute updateCategoryAttribute(String attributeId, CategoryAttribute updates) {
        CategoryAttribute attribute = dao.findById(attributeId)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeId));

        // Güncelle
        if (StringUtils.hasText(updates.getAttributeName())) {
            attribute.setAttributeName(updates.getAttributeName());
        }
        if (StringUtils.hasText(updates.getAttributeNameEn())) {
            attribute.setAttributeNameEn(updates.getAttributeNameEn());
        }
        if (updates.getAttributeType() != null) {
            attribute.setAttributeType(updates.getAttributeType());
        }
        if (updates.getIsRequired() != null) {
            attribute.setIsRequired(updates.getIsRequired());
        }
        if (updates.getIsFilterable() != null) {
            attribute.setIsFilterable(updates.getIsFilterable());
        }
       

        save(attribute);
        log.info("Kategori özelliği güncellendi: ID={}", attributeId);

        return attribute;
    }

    @Override
    public void deleteCategoryAttribute(String attributeId) {
        CategoryAttribute attribute = dao.findById(attributeId)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeId));

        attribute.setIsActive(false);
        save(attribute);
        log.info("Kategori özelliği silindi: ID={}", attributeId);
    }

    @Override
    public List<CategoryAttribute> getCategoryAttributes(String categoryId) {
        return dao.findByCategoryIdAndIsActiveOrderByDisplayOrderAsc(categoryId, true);
    }

    @Override
    public List<CategoryAttribute> getRequiredAttributes(String categoryId) {
        return dao
                .findByCategoryIdAndIsRequiredAndIsActiveOrderByDisplayOrderAsc(categoryId, true, true);
    }

    @Override
    public List<CategoryAttribute> getFilterableAttributes(String categoryId) {
        return dao
                .findByCategoryIdAndIsFilterableAndIsActiveOrderByDisplayOrderAsc(categoryId, true, true);
    }

    @Override
    public CategoryAttribute getAttributeByKey(String categoryId, String attributeKey) {
        return dao.findByCategoryIdAndAttributeKey(
                        categoryId, attributeKey)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeKey));
    }

    @Override
    public void updateAttributeOptions(String attributeId, List<String> options) {
        CategoryAttribute attribute = dao.findById(attributeId)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeId));

      //  attribute.setOptions(options);
        save(attribute);
        log.info("Özellik seçenekleri güncellendi: ID={}, Options={}", attributeId, options.size());
    }

    @Override
    public void toggleRequired(String attributeId, Boolean isRequired) {
        CategoryAttribute attribute = dao.findById(attributeId)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeId));

        attribute.setIsRequired(isRequired);
        save(attribute);
        log.info("Özellik zorunluluk durumu değiştirildi: ID={}, Required={}", attributeId, isRequired);
    }

    @Override
    public void toggleFilterable(String attributeId, Boolean isFilterable) {
        CategoryAttribute attribute = dao.findById(attributeId)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeId));

        attribute.setIsFilterable(isFilterable);
        save(attribute);
        log.info("Özellik filtreleme durumu değiştirildi: ID={}, Filterable={}", attributeId, isFilterable);
    }

    @Override
    public void toggleSearchable(String attributeId, Boolean isSearchable) {
        CategoryAttribute attribute = dao.findById(attributeId)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeId));

    //    attribute.setIsSearchable(isSearchable);
        save(attribute);
        log.info("Özellik arama durumu değiştirildi: ID={}, Searchable={}", attributeId, isSearchable);
    }

    @Override
    public void updateDisplayOrder(String attributeId, Integer displayOrder) {
        CategoryAttribute attribute = dao.findById(attributeId)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeId));

      //  attribute.setDisplayOrder(displayOrder);
        save(attribute);
        log.info("Özellik sırası güncellendi: ID={}, Order={}", attributeId, displayOrder);
    }

    @Override
    public boolean attributeExists(String categoryId, String attributeKey) {
        return dao.existsByCategoryIdAndAttributeKey(
                categoryId, attributeKey);
    }

    @Override
    public long getAttributeCountForCategory(String categoryId) {
        return dao.countByCategoryId(categoryId);
    }

    /**
     * Batch query: Birden fazla kategori için tüm özellikleri tek sorguda getir
     * N+1 query problemi çözümü için
     */
    @Override
    public List<CategoryAttribute> findByCategoryIds(List<String> categoryIds) {
        if (categoryIds == null || categoryIds.isEmpty()) {
            return List.of();
        }
        log.debug("Batch query: {} kategori için özellikler getiriliyor", categoryIds.size());
        return dao.findByCategoryIdIn(categoryIds);
    }
}
