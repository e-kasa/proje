package com.sedcore.service.impl;

import com.sedcore.entity.CategoryAttribute;
import com.sedcore.entity.ProductCategoryAttribute;
import com.sedcore.enums.AttributeType;
import com.sedcore.repository.CategoryAttributeRepository;
import com.sedcore.repository.ProductCategoryAttributeRepository;
import com.sedcore.service.ProductCategoryAttributeService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
@RequiredArgsConstructor
public class ProductCategoryAttributeServiceImpl
        extends BaseDbServiceImp<ProductCategoryAttributeRepository, ProductCategoryAttribute>
        implements ProductCategoryAttributeService {

    private final CategoryAttributeRepository categoryAttributeRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return com.sedcore.model.ProductCategoryAttributeResponse.class;
    }

    @Override
    public ProductCategoryAttribute setProductAttribute(String productId, String categoryId,
                                                        String categoryAttributeId, Object value) {
        // Özellik tanımını al
        CategoryAttribute categoryAttribute = categoryAttributeRepository.findById(categoryAttributeId)
                .orElseThrow(() -> new RuntimeException("Özellik tanımı bulunamadı: " + categoryAttributeId));

        // Mevcut değeri bul veya yeni oluştur
        ProductCategoryAttribute productAttribute = dao
                .findByProductIdAndCategoryIdAndCategoryAttributeId(productId, categoryId, categoryAttributeId)
                .orElse(ProductCategoryAttribute.builder()
                        .productId(productId)
                        .categoryId(categoryId)
                        .categoryAttributeId(categoryAttributeId)
                        .attributeKey(categoryAttribute.getAttributeKey())
                        .attributeName(categoryAttribute.getAttributeName())
              //          .unit(categoryAttribute.getUnit())
                        .isVerified(false)
                  //      .sortOrder(categoryAttribute.getDisplayOrder())
                        .build());

        // Değeri tipine göre ata
        setAttributeValue(productAttribute, categoryAttribute.getAttributeType(), value);

        save(productAttribute);
        log.info("Ürün özelliği kaydedildi: Product={}, Category={}, Attribute={}",
                productId, categoryId, categoryAttribute.getAttributeKey());

        return productAttribute;
    }

    @Override
    public void deleteProductAttribute(String productId, String categoryId, String categoryAttributeId) {
        ProductCategoryAttribute attribute = dao
                .findByProductIdAndCategoryIdAndCategoryAttributeId(productId, categoryId, categoryAttributeId)
                .orElseThrow(() -> new RuntimeException("Ürün özelliği bulunamadı"));

        delete(attribute);
        log.info("Ürün özelliği silindi: Product={}, Category={}, Attribute={}",
                productId, categoryId, categoryAttributeId);
    }

    @Override
    public List<ProductCategoryAttribute> getProductAttributesInCategory(String productId, String categoryId) {
        return dao.findByProductIdAndCategoryIdOrderBySortOrderAsc(productId, categoryId);
    }

    @Override
    public List<ProductCategoryAttribute> getAllProductAttributes(String productId) {
        return dao.findByProductIdOrderBySortOrderAsc(productId);
    }

    @Override
    public List<ProductCategoryAttribute> getCategoryProductAttributes(String categoryId) {
        return dao.findByCategoryIdOrderBySortOrderAsc(categoryId);
    }

    @Override
    public ProductCategoryAttribute getAttributeByKey(String productId, String categoryId, String attributeKey) {
        return dao.findByProductIdAndCategoryIdAndAttributeKey(productId, categoryId, attributeKey)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeKey));
    }

    @Override
    public void verifyAttribute(String attributeId, Boolean isVerified) {
        ProductCategoryAttribute attribute = dao.findById(attributeId)
                .orElseThrow(() -> new RuntimeException("Özellik bulunamadı: " + attributeId));

        attribute.setIsVerified(isVerified);
        save(attribute);
        log.info("Özellik doğrulama durumu güncellendi: ID={}, Verified={}", attributeId, isVerified);
    }

    @Override
    public void bulkSetAttributes(String productId, String categoryId, Map<String, String> attributes) {
        attributes.forEach((attributeKey, value) -> {
            try {
                CategoryAttribute categoryAttribute = categoryAttributeRepository
                        .findByCategoryIdAndAttributeKey(
                                categoryId, attributeKey)
                        .orElseThrow(() -> new RuntimeException("Özellik tanımı bulunamadı: " + attributeKey));

                setProductAttribute(productId, categoryId, categoryAttribute.getId(), value);
            } catch (Exception e) {
                log.error("Özellik ayarlanırken hata: Key={}, Error={}", attributeKey, e.getMessage());
            }
        });

        log.info("Toplu özellik güncellendi: Product={}, Category={}, Count={}",
                productId, categoryId, attributes.size());
    }

    @Override
    public List<String> filterProductsByAttribute(String categoryId, String attributeKey, Object value) {
        List<ProductCategoryAttribute> attributes = dao
                .findByCategoryAndAttributeKeyAndValue(categoryId, attributeKey, value.toString());

        return attributes.stream()
                .map(ProductCategoryAttribute::getProductId)
                .distinct()
                .collect(Collectors.toList());
    }

    @Override
    public List<String> filterProductsByNumberRange(String categoryId, String attributeKey,
                                                    Double minValue, Double maxValue) {
        List<ProductCategoryAttribute> attributes = dao
                .findByCategoryAndAttributeKeyAndNumberRange(categoryId, attributeKey, minValue, maxValue);

        return attributes.stream()
                .map(ProductCategoryAttribute::getProductId)
                .distinct()
                .collect(Collectors.toList());
    }

    @Override
    public long getAttributeCountForProduct(String productId, String categoryId) {
        return dao.countByProductIdAndCategoryId(productId, categoryId);
    }

    /**
     * Özellik değerini tipine göre ata
     */
    private void setAttributeValue(ProductCategoryAttribute productAttribute,
                                   AttributeType attributeType, Object value) {
        if (value == null) {
            return;
        }

        switch (attributeType) {
            case TEXT, URL, EMAIL, PHONE -> {
                productAttribute.setValueText(value.toString());
                productAttribute.setDisplayValue(value.toString());
            }
            case NUMBER -> {
                Double numValue = convertToDouble(value);
                productAttribute.setValueNumber(numValue);
                productAttribute.setDisplayValue(numValue + (productAttribute.getUnit() != null ?
                        " " + productAttribute.getUnit() : ""));
            }
            case BOOLEAN -> {
                Boolean boolValue = Boolean.parseBoolean(value.toString());
                productAttribute.setValueBoolean(boolValue);
                productAttribute.setDisplayValue(boolValue ? "Evet" : "Hayır");
            }
            case DATE -> {
                LocalDate dateValue = LocalDate.parse(value.toString());
                productAttribute.setValueDate(dateValue);
                productAttribute.setDisplayValue(dateValue.toString());
            }
            case SELECT -> {
                productAttribute.setValueText(value.toString());
                productAttribute.setDisplayValue(value.toString());
            }
            case MULTI_SELECT -> {
                if (value instanceof List) {
                    @SuppressWarnings("unchecked")
                    List<String> listValue = (List<String>) value;
                    productAttribute.setValueSelect(listValue);
                    productAttribute.setDisplayValue(String.join(", ", listValue));
                }
            }
            case COLOR -> {
                productAttribute.setValueText(value.toString());
                productAttribute.setDisplayValue(value.toString());
            }
            case RANGE -> {
                if (value instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String, String> rangeValue = (Map<String, String>) value;
                    productAttribute.setValueMin(convertToDouble(rangeValue.get("min")));
                    productAttribute.setValueMax(convertToDouble(rangeValue.get("max")));
                    productAttribute.setDisplayValue(
                            productAttribute.getValueMin() + " - " + productAttribute.getValueMax() +
                                    (productAttribute.getUnit() != null ? " " + productAttribute.getUnit() : "")
                    );
                }
            }
        }
    }

    private Double convertToDouble(Object value) {
        if (value instanceof Number) {
            return ((Number) value).doubleValue();
        }
        try {
            return Double.parseDouble(value.toString());
        } catch (NumberFormatException e) {
            throw new RuntimeException("Geçersiz sayı formatı: " + value);
        }
    }

   
}
