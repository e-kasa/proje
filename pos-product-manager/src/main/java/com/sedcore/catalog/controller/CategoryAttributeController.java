package com.sedcore.catalog.controller;

import com.sedcore.catalog.model.CategoryAttributeRequest;
import com.sedcore.catalog.model.CategoryAttributeResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * CategoryAttribute Controller Interface
 * Kategori Özellik Tanımları REST API
 */
public interface CategoryAttributeController {

    @PostMapping
    ResponseEntity<ApiResponse<CategoryAttributeResponse>> createAttribute(
            @RequestBody CategoryAttributeRequest request
    );

    @PutMapping("/{id}")
    ResponseEntity<ApiResponse<CategoryAttributeResponse>> updateAttribute(
            @PathVariable String id,
            @RequestBody CategoryAttributeRequest request
    );

    @DeleteMapping("/{id}")
    ResponseEntity<ApiResponse<Void>> deleteAttribute(@PathVariable String id);

    @GetMapping("/category/{categoryId}")
    ResponseEntity<ApiResponse<List<CategoryAttributeResponse>>> getCategoryAttributes(
            @PathVariable String categoryId
    );

    @GetMapping("/category/{categoryId}/required")
    ResponseEntity<ApiResponse<List<CategoryAttributeResponse>>> getRequiredAttributes(
            @PathVariable String categoryId
    );

    @GetMapping("/category/{categoryId}/filterable")
    ResponseEntity<ApiResponse<List<CategoryAttributeResponse>>> getFilterableAttributes(
            @PathVariable String categoryId
    );
}
