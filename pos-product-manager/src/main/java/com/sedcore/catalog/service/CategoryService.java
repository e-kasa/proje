package com.sedcore.catalog.service;

import com.sedcore.catalog.entity.Category;
import com.sedcore.common.enums.ProductStatus;
import com.sedcore.catalog.model.DtoCategory;
import com.sedcore.catalog.model.DtoCategoryUI;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface CategoryService extends BaseDbService<Category> {

    // CRUD Operasyonları
    DtoCategory createCategory(DtoCategoryUI dtoCategoryUI);

    DtoCategory updateCategory(String id, DtoCategoryUI dtoCategoryUI);

    void deleteCategory(String id);

    DtoCategory getCategoryById(String id);

    List<DtoCategory> getAllCategories();

    List<DtoCategory> getCategoriesByStatus(ProductStatus status);

    // Hiyerarşik İşlemler
    List<DtoCategory> getRootCategories();

    List<DtoCategory> getChildCategories(String parentId);

    List<DtoCategory> getCategoryTree();

    String getCategoryPath(String categoryId);

    // Yardımcı Metodlar
    String generateSlug(String name);

    void updateSortOrder(String categoryId, Integer newOrder);

    boolean existsBySlug(String slug);

    boolean existsBySlug(String slug, String excludeId);

    // ===== İlişkisel Metodlar =====

    /**
     * Category'yi tüm ilişkileriyle getir (children, variants, attributes)
     */
    DtoCategory getCategoryWithRelations(String categoryId, boolean includeChildren,
                                        boolean includeVariants, boolean includeAttributes);

    /**
     * Category tree'yi tüm ilişkileriyle getir
     */
    List<DtoCategory> getCategoryTreeWithRelations();

    /**
     * Parent category'yi children'larıyla getir
     */
    DtoCategory getCategoryWithChildren(String categoryId, boolean recursive);
}
