package com.sedcore.catalog.controller;

import com.sedcore.catalog.model.DtoCategory;
import com.sedcore.catalog.model.CompanyCategoryRequest;
import com.sedcore.catalog.model.CompanyCategoryResponse;
import com.sedcore.catalog.model.CompanyCategoryBulkRequest;
import com.sedcore.catalog.model.DtoCategoryUI;
import com.towpen.base.exceptions.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RequestMapping("/api/company-category")
public interface CompanyCategoryController {

    /**
     * Mevcut firmanın kategorilerini AĞAÇ yapısında döner.
     * Flutter / React bu endpoint'i çağırır — login olan firmanın kategorileri gelir.
     *
     * GET /product/api/company-category/my-categories
     */
    @GetMapping("/my-categories")
    ResponseEntity<ApiResponse<List<DtoCategory>>> getMyCategories();

    /**
     * Mevcut firmanın kategorilerini düz liste olarak döner.
     *
     * GET /product/api/company-category/list
     */
    @GetMapping("/list")
    ResponseEntity<ApiResponse<List<CompanyCategoryResponse>>> getMyCategoryList();

    /**
     * Global kategori havuzunu döner — hangileri seçili bilgisiyle.
     * "Kategori Tanımla" ekranı bu endpoint'i kullanır.
     *
     * GET /product/api/company-category/all-with-selection
     */
    @GetMapping("/all-with-selection")
    ResponseEntity<ApiResponse<List<DtoCategory>>> getAllCategoriesWithSelection();

    /**
     * Firmaya tek bir kategori ekle.
     *
     * POST /product/api/company-category
     */
    @PostMapping
    ResponseEntity<ApiResponse<CompanyCategoryResponse>> addCategory(
            @Valid @RequestBody CompanyCategoryRequest request
    );

    /**
     * Firmadan tek bir kategoriyi kaldır.
     *
     * DELETE /product/api/company-category/{categoryId}
     */
    @DeleteMapping("/{categoryId}")
    ResponseEntity<ApiResponse<Void>> removeCategory(@PathVariable String categoryId);

    /**
     * Firmanın tüm kategori seçimini toplu güncelle.
     * "Kaydet" butonuna basıldığında çağrılır.
     *
     * PUT /product/api/company-category/bulk
     */
    @PutMapping("/bulk")
    ResponseEntity<ApiResponse<List<CompanyCategoryResponse>>> bulkSetCategories(
            @Valid @RequestBody CompanyCategoryBulkRequest request
    );
}
