package com.sedcore.controller;

import com.sedcore.model.ProductCategoryRequest;
import com.sedcore.model.ProductCategoryResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * ProductCategory Controller Interface
 * Ürün-Kategori ilişkileri REST API
 */
public interface ProductCategoryController {

    /**
     * Ürüne kategori ekle
     */
    @PostMapping("/add")
    ResponseEntity<ApiResponse<ProductCategoryResponse>> addCategoryToProduct(
            @RequestBody ProductCategoryRequest request
    );

    /**
     * Üründen kategori çıkar
     */
    @DeleteMapping("/remove")
    ResponseEntity<ApiResponse<Void>> removeCategoryFromProduct(
            @RequestParam String productId,
            @RequestParam String categoryId
    );

    /**
     * Ana kategoriyi değiştir
     */
    @PutMapping("/change-primary")
    ResponseEntity<ApiResponse<Void>> changePrimaryCategory(
            @RequestParam String productId,
            @RequestParam String newPrimaryCategoryId
    );

    /**
     * Ürünün tüm kategorilerini getir
     */
    @GetMapping("/product/{productId}")
    ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getProductCategories(
            @PathVariable String productId
    );

    /**
     * Ürünün ana kategorisini getir
     */
    @GetMapping("/product/{productId}/primary")
    ResponseEntity<ApiResponse<ProductCategoryResponse>> getPrimaryCategory(
            @PathVariable String productId
    );

    /**
     * Kategorideki tüm ürünleri getir
     */
    @GetMapping("/category/{categoryId}/products")
    ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getCategoryProducts(
            @PathVariable String categoryId
    );

    /**
     * Kategorideki öne çıkan ürünleri getir
     */
    @GetMapping("/category/{categoryId}/featured")
    ResponseEntity<ApiResponse<List<ProductCategoryResponse>>> getFeaturedProducts(
            @PathVariable String categoryId
    );

    /**
     * Ürünü kategoride öne çıkar
     */
    @PutMapping("/feature")
    ResponseEntity<ApiResponse<Void>> featureProduct(
            @RequestParam String productId,
            @RequestParam String categoryId,
            @RequestParam Boolean featured
    );

    /**
     * Görüntüleme sırasını güncelle
     */
    @PutMapping("/display-order")
    ResponseEntity<ApiResponse<Void>> updateDisplayOrder(
            @RequestParam String productId,
            @RequestParam String categoryId,
            @RequestParam Integer displayOrder
    );
}
