package com.sedcore.controller.impl;

import com.sedcore.controller.ProductCategoryController;
import com.sedcore.entity.ProductCategory;
import com.sedcore.model.ProductCategoryRequest;
import com.sedcore.model.ProductCategoryResponse;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.ProductCategoryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
                    toResponse(result)
            ));
        } catch (Exception e) {
            log.error("Ürün kategoriye eklenirken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> removeCategoryFromProduct(
            String productId, String categoryId) {
        try {
            productCategoryService.removeCategoryFromProduct(productId, categoryId);
            return ResponseEntity.ok(ApiResponse.success("Ürün kategoriden çıkarıldı",null));
        } catch (Exception e) {
            log.error("Ürün kategoriden çıkarılırken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> changePrimaryCategory(
            String productId, String newPrimaryCategoryId) {
        try {
            productCategoryService.changePrimaryCategory(productId, newPrimaryCategoryId);
            return ResponseEntity.ok(ApiResponse.success( "Ana kategori değiştirildi",null));
        } catch (Exception e) {
            log.error("Ana kategori değiştirilirken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
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
            return ResponseEntity.ok(ApiResponse.success( "Kategoriler getirildi",response));
        } catch (Exception e) {
            log.error("Kategoriler getirilirken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<ProductCategoryResponse>> getPrimaryCategory(
            String productId) {
        try {
            ProductCategory primary = productCategoryService.getPrimaryCategory(productId);
            return ResponseEntity.ok(ApiResponse.success(
                    "Ana kategori getirildi",
                    toResponse(primary)
            ));
        } catch (Exception e) {
            log.error("Ana kategori getirilirken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
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
            return ResponseEntity.ok(ApiResponse.success( "Ürünler getirildi",response));
        } catch (Exception e) {
            log.error("Ürünler getirilirken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
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
            return ResponseEntity.ok(ApiResponse.success( "Öne çıkan ürünler getirildi",response));
        } catch (Exception e) {
            log.error("Öne çıkan ürünler getirilirken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> featureProduct(
            String productId, String categoryId, Boolean featured) {
        try {
            productCategoryService.featureProductInCategory(productId, categoryId, featured);
            return ResponseEntity.ok(ApiResponse.success( "Öne çıkarma durumu güncellendi",null));
        } catch (Exception e) {
            log.error("Öne çıkarma güncellenirken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> updateDisplayOrder(
            String productId, String categoryId, Integer displayOrder) {
        try {
            productCategoryService.updateDisplayOrder(productId, categoryId, displayOrder);
            return ResponseEntity.ok(ApiResponse.success( "Görüntüleme sırası güncellendi",null));
        } catch (Exception e) {
            log.error("Görüntüleme sırası güncellenirken hata: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Hata: " + e.getMessage()));
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
