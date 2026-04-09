package com.sedcore.service.impl;

import com.sedcore.entity.ProductCategory;
import com.sedcore.repository.ProductCategoryRepository;
import com.sedcore.service.ProductCategoryService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@Transactional
public class ProductCategoryServiceImpl extends BaseDbServiceImp<ProductCategoryRepository, ProductCategory>
        implements ProductCategoryService {

    @Override
    public Class<?> getDTOClassForService() {
        return com.sedcore.model.ProductCategoryResponse.class;
    }

    @Override
    public ProductCategory addCategoryToProduct(String productId, String categoryId, Boolean isPrimary) {
        // Zaten varsa hata ver
        if (dao.existsByProductIdAndCategoryId(
                productId, categoryId)) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        // Eğer primary ise, diğer primary'leri kaldır
        if (Boolean.TRUE.equals(isPrimary)) {
            removePrimaryFromOthers(productId);
        }

        ProductCategory productCategory = ProductCategory.builder()
                .productId(productId)
                .categoryId(categoryId)
                .isPrimary(isPrimary != null ? isPrimary : false)
                .isActive(true)
                .isFeatured(false)
                .displayOrder(0)
                .build();

        save(productCategory);
        log.info("Ürün kategoriye eklendi: Product={}, Category={}, Primary={}",
                productId, categoryId, isPrimary);

        return productCategory;
    }

    @Override
    public void removeCategoryFromProduct(String productId, String categoryId) {
        List<ProductCategory> productCategories = dao
                .findByProductIdAndIsActiveOrderByDisplayOrderAsc(productId, true);

        productCategories.stream()
                .filter(pc -> pc.getCategoryId().equals(categoryId))
                .findFirst()
                .ifPresentOrElse(
                        pc -> {
                            pc.setIsActive(false);
                            save(pc);
                            log.info("Ürün kategoriden çıkarıldı: Product={}, Category={}",
                                    productId, categoryId);
                        },
                        () -> {
                            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
                        }
                );
    }

    @Override
    public void changePrimaryCategory(String productId, String newPrimaryCategoryId) {
        // Önce tüm primary'leri kaldır
        removePrimaryFromOthers(productId);

        // Yeni primary'yi ayarla
        List<ProductCategory> productCategories = dao
                .findByProductIdAndIsActiveOrderByDisplayOrderAsc(productId, true);

        productCategories.stream()
                .filter(pc -> pc.getCategoryId().equals(newPrimaryCategoryId))
                .findFirst()
                .ifPresentOrElse(
                        pc -> {
                            pc.setIsPrimary(true);
                            save(pc);
                            log.info("Ana kategori değiştirildi: Product={}, NewPrimary={}",
                                    productId, newPrimaryCategoryId);
                        },
                        () -> {
                            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
                        }
                );
    }

    @Override
    public List<ProductCategory> getProductCategories(String productId) {
        return dao.findByProductIdAndIsActiveOrderByDisplayOrderAsc(productId, true);
    }

    @Override
    public ProductCategory getPrimaryCategory(String productId) {
        return dao.findByProductIdAndIsPrimaryAndIsActive(productId, true, true)
                .orElseThrow(() -> new RuntimeException("Ana kategori bulunamadı"));
    }

    @Override
    public List<ProductCategory> getCategoryProducts(String categoryId) {
        return dao.findByCategoryIdAndIsActiveOrderByDisplayOrderAsc(categoryId, true);
    }

    @Override
    public List<ProductCategory> getFeaturedProductsInCategory(String categoryId) {
        return dao
                .findByCategoryIdAndIsFeaturedAndIsActiveOrderByDisplayOrderAsc(categoryId, true, true);
    }

    @Override
    public void featureProductInCategory(String productId, String categoryId, Boolean featured) {
        List<ProductCategory> productCategories = dao
                .findByProductIdAndIsActiveOrderByDisplayOrderAsc(productId, true);

        productCategories.stream()
                .filter(pc -> pc.getCategoryId().equals(categoryId))
                .findFirst()
                .ifPresentOrElse(
                        pc -> {
                            pc.setIsFeatured(featured);
                            save(pc);
                            log.info("Ürün öne çıkarma durumu güncellendi: Product={}, Category={}, Featured={}",
                                    productId, categoryId, featured);
                        },
                        () -> {
                            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
                        }
                );
    }

    @Override
    public void updateDisplayOrder(String productId, String categoryId, Integer displayOrder) {
        List<ProductCategory> productCategories = dao
                .findByProductIdAndIsActiveOrderByDisplayOrderAsc(productId, true);

        productCategories.stream()
                .filter(pc -> pc.getCategoryId().equals(categoryId))
                .findFirst()
                .ifPresentOrElse(
                        pc -> {
                            pc.setDisplayOrder(displayOrder);
                            save(pc);
                            log.info("Görüntüleme sırası güncellendi: Product={}, Category={}, Order={}",
                                    productId, categoryId, displayOrder);
                        },
                        () -> {
                            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
                        }
                );
    }

    @Override
    public void toggleProductCategoryStatus(String productId, String categoryId, Boolean isActive) {
        List<ProductCategory> productCategories = dao
                .findByProductIdAndIsActiveOrderByDisplayOrderAsc(productId, true);

        productCategories.stream()
                .filter(pc -> pc.getCategoryId().equals(categoryId))
                .findFirst()
                .ifPresentOrElse(
                        pc -> {
                            pc.setIsActive(isActive);
                            save(pc);
                            log.info("Ürün-kategori durumu değiştirildi: Product={}, Category={}, Active={}",
                                    productId, categoryId, isActive);
                        },
                        () -> {
                            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
                        }
                );
    }

    @Override
    public long getProductCountInCategory(String categoryId) {
        return dao.countByCategoryId(categoryId);
    }

    @Override
    public long getCategoryCountForProduct(String productId) {
        return dao.countByProductId(productId);
    }

    @Override
    public boolean isProductInCategory(String productId, String categoryId) {
        return dao.existsByProductIdAndCategoryId(
                productId, categoryId);
    }

    private void removePrimaryFromOthers(String productId) {
        List<ProductCategory> productCategories = dao
                .findByProductIdAndIsActiveOrderByDisplayOrderAsc(productId, true);

        productCategories.stream()
                .filter(ProductCategory::getIsPrimary)
                .forEach(pc -> {
                    pc.setIsPrimary(false);
                    save(pc);
                });
    }

    
}
