package com.sedcore.controller;

import com.sedcore.entity.CategoryVariant;
import com.sedcore.enums.AttributeType;
import com.sedcore.model.DtoCategory;
import com.sedcore.model.DtoCategoryUI;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;

import java.util.List;

public interface CategoryController {

    // CRUD Operasyonları
    ResponseEntity<ApiResponse<DtoCategory>> createCategory(DtoCategoryUI dtoCategoryUI);

    ResponseEntity<ApiResponse<DtoCategory>> updateCategory(String id, DtoCategoryUI dtoCategoryUI);

    ResponseEntity<ApiResponse<Void>> deleteCategory(String id);

    ResponseEntity<ApiResponse<DtoCategory>> getCategoryById(String id);

    ResponseEntity<ApiResponse<List<DtoCategory>>> getAllCategories();

    ResponseEntity<ApiResponse<List<DtoCategory>>> getCategoriesByStatus(String status);

    // Hiyerarşik İşlemler
    ResponseEntity<ApiResponse<List<DtoCategory>>> getRootCategories();

    ResponseEntity<ApiResponse<List<DtoCategory>>> getChildCategories(String parentId);

    ResponseEntity<ApiResponse<List<DtoCategory>>> getCategoryTree();

    ResponseEntity<ApiResponse<String>> getCategoryPath(String categoryId);

    // Yardımcı Operasyonlar
    ResponseEntity<ApiResponse<String>> generateSlug(String name);

    ResponseEntity<ApiResponse<Void>> updateSortOrder(String categoryId, Integer newOrder);

    // ===== İlişkisel Operasyonlar =====

    /**
     * Category'yi tüm ilişkileriyle getir
     * Query params: includeChildren, includeVariants, includeAttributes
     */
    ResponseEntity<ApiResponse<DtoCategory>> getCategoryWithRelations(
            String categoryId,
            Boolean includeChildren,
            Boolean includeVariants,
            Boolean includeAttributes
    );

    /**
     * Category tree'yi tüm ilişkileriyle getir (recursive)
     */
    ResponseEntity<ApiResponse<List<DtoCategory>>> getCategoryTreeWithRelations();

    /**
     * Category'yi children'larıyla getir
     * Query param: recursive (true/false)
     */
    ResponseEntity<ApiResponse<DtoCategory>> getCategoryWithChildren(
            String categoryId,
            Boolean recursive
    );

    /**
     * Category'ye varyant ekleme
     * 
     */
    ResponseEntity<ApiResponse<CategoryVariant>> addVariantToCategory(String categoryId, String variantKey,
                                               String variantName, AttributeType variantType);
}
