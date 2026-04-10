package com.sedcore.controller.impl;

import com.sedcore.controller.ProductCategoryController;
import com.sedcore.entity.ProductCategory;
import com.sedcore.model.ProductCategoryRequest;
import com.sedcore.model.ProductCategoryResponse;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.service.ProductCategoryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/product-category")
@RequiredArgsConstructor
@Slf4j
public class ProductCategoryControllerImpl implements ProductCategoryController {

    private final ProductCategoryService productCategoryService;

    @Override
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> addCategoryToProduct(
            ProductCategoryRequest request) {
        try {
            ProductCategory result = productCategoryService.addCategoryToProduct(
                    request.getProductId(),
                    request.getCategoryId(),
                    request.getIsPrimary()
            );
            return ResponseEntity.ok(ApiResponse.success(
                    "Ürün kategoriye eklendi",
                    toResponse(result)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> removeCategoryFromProduct(
            String productId, String categoryId) {
        try {
            productCategoryService.removeCategoryFromProduct(productId, categoryId);
            return ResponseEntity.ok(ApiResponse.success("Kategori üründen kaldırıldı", null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> changePrimaryCategory(
            String productId, String newPrimaryCategoryId) {
        try {
            productCategoryService.changePrimaryCategory(productId, newPrimaryCategoryId);
            return ResponseEntity.ok(ApiResponse.success("Ana kategori değiştirildi", null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getProductCategories(
            String productId) {
        try {
            List<ProductCategory> categories = productCategoryService.getProductCategories(productId);
            List<ProductCategoryResponse> response = categories.stream()
                    .map(this::toResponse)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success("Ürün kategorileri getirildi", response));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> getPrimaryCategory(
            String productId) {
        try {
            ProductCategory primary = productCategoryService.getPrimaryCategory(productId);
            return ResponseEntity.ok(ApiResponse.success(
                    "Ana kategori getirildi",
                    toResponse(primary)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getCategoryProducts(
            String categoryId) {
        try {
            List<ProductCategory> products = productCategoryService.getCategoryProducts(categoryId);
            List<ProductCategoryResponse> response = products.stream()
                    .map(this::toResponse)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success("Kategori ürünleri getirildi", response));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getFeaturedProducts(
            String categoryId) {
        try {
            List<ProductCategory> featured = productCategoryService
                    .getFeaturedProductsInCategory(categoryId);
            List<ProductCategoryResponse> response = featured.stream()
                    .map(this::toResponse)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success("Öne çıkan ürünler getirildi", response));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> featureProduct(
            String productId, String categoryId, Boolean featured) {
        try {
            productCategoryService.featureProductInCategory(productId, categoryId, featured);
            return ResponseEntity.ok(ApiResponse.success("Ürün öne çıkarma güncellendi", null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> updateDisplayOrder(
            String productId, String categoryId, Integer displayOrder) {
        try {
            productCategoryService.updateDisplayOrder(productId, categoryId, displayOrder);
            return ResponseEntity.ok(ApiResponse.success("Görüntüleme sırası güncellendi", null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    private ProductCategoryResponse toResponse(ProductCategory entity) {
        return ProductCategoryResponse.builder()
                .id(entity.getId())
                .productId(entity.getProductId())
                .categoryId(entity.getCategoryId())
                .isPrimary(entity.getIsPrimary())
                .isFeatured(entity.getIsFeatured())
                .displayOrder(entity.getDisplayOrder())
                .customName(entity.getCustomName())
                .customDescription(entity.getCustomDescription())
                .isActive(entity.getIsActive())
                .build();
    }
}
