package com.sedcore.catalog.service.impl;

import com.sedcore.catalog.entity.Category;
import com.sedcore.catalog.entity.CategoryAttribute;
import com.sedcore.catalog.entity.CategoryVariant;
import com.sedcore.common.enums.ProductStatus;
import com.sedcore.catalog.model.CategoryAttributeResponse;
import com.sedcore.catalog.model.CategoryVariantResponse;
import com.sedcore.catalog.model.DtoCategory;
import com.sedcore.catalog.model.DtoCategoryUI;
import com.sedcore.catalog.repository.CategoryRepository;
import com.sedcore.catalog.service.CategoryAttributeService;
import com.sedcore.catalog.service.CategoryService;
import com.sedcore.catalog.service.CategoryVariantService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
public class CategoryServiceImpl extends BaseDbServiceImp<CategoryRepository, Category> implements CategoryService {

    @Autowired(required = false)
    @org.springframework.context.annotation.Lazy
    private CategoryVariantService categoryVariantService;

    @Autowired(required = false)
    @org.springframework.context.annotation.Lazy
    private CategoryAttributeService categoryAttributeService;

    @Override
    public Class<?> getDTOClassForService() {
        return DtoCategory.class;
    }

    @Override
    public DtoCategory createCategory(DtoCategoryUI dtoCategoryUI) {
        // Slug oluştur veya var olanı kullan
        String slug = StringUtils.hasText(dtoCategoryUI.getSlug())
                ? dtoCategoryUI.getSlug()
                : generateSlug(dtoCategoryUI.getName());

        // Slug benzersizliğini kontrol et
        if (dao.existsBySlug(slug)) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        // Level ve path hesapla
        Integer level = 0;
        String path = "/" + slug;
        Category parent = null;
        if (StringUtils.hasText(dtoCategoryUI.getParentId())) {
             parent = dao.findById(dtoCategoryUI.getParentId())
                    .orElseThrow(() -> new RuntimeException("Üst kategori bulunamadı: " + dtoCategoryUI.getParentId()));
            level = parent.getLevel() + 1;
            path = parent.getPath() + "/" + slug;
        }

        Category category = Category.builder()
                .name(dtoCategoryUI.getName())
                .slug(slug)
                .description(dtoCategoryUI.getDescription())
                .parentCategory(parent)
                .imageUrl(dtoCategoryUI.getImageUrl())
                .icon(dtoCategoryUI.getIcon())
                .status(dtoCategoryUI.getStatus() != null ? dtoCategoryUI.getStatus() : ProductStatus.ACTIVE)
                .sortOrder(dtoCategoryUI.getSortOrder() != null ? dtoCategoryUI.getSortOrder() : 0)
                .level(level)
                .path(path)
                .isSoftDeleted(dtoCategoryUI.getIsSoftDeleted() != null ? dtoCategoryUI.getIsSoftDeleted() : false)
                .metadata(dtoCategoryUI.getMetadata())
                .metaTitle(dtoCategoryUI.getMetaTitle())
                .metaDescription(dtoCategoryUI.getMetaDescription())
                .metaKeywords(dtoCategoryUI.getMetaKeywords())
                .build();

        save(category);
        log.info("Kategori oluşturuldu: {} (ID: {})", category.getName(), category.getId());

        // Varyantları kaydet
        if (dtoCategoryUI.getVariants() != null && !dtoCategoryUI.getVariants().isEmpty()) {
            List<CategoryVariant> varList = new ArrayList<>();
            log.info("Kategoriye {} adet varyant ekleniyor", dtoCategoryUI.getVariants().size());
            for (var variantRequest : dtoCategoryUI.getVariants()) {
                // Null-safe handling: options boş liste olarak başlatıldı
                CategoryVariant variant = CategoryVariant.builder()
                        .category(category)
                        .variantKey(variantRequest.getVariantKey())
                        .variantName(variantRequest.getVariantName())
                        .variantNameEn(variantRequest.getVariantNameEn())
                        .variantType(variantRequest.getVariantType())
                        .isRequired(variantRequest.getIsRequired() != null ? variantRequest.getIsRequired() : false)
                        .displayOrder(variantRequest.getDisplayOrder() != null ? variantRequest.getDisplayOrder() : 0)
                        .options(variantRequest.getOptions() != null ? variantRequest.getOptions() : new ArrayList<>())
                        .isActive(true) // Frontend'den gelmiyorsa default true
                        .build();

                if (categoryVariantService != null) {
                    categoryVariantService.save(variant);
                    varList.add(variant);
                    log.info("Varyant eklendi: {} ({})", variant.getVariantName(), variant.getVariantKey());
                }
            }
            category.setVariants(varList);
        }

        return toDTO(category);
    }



    @Override
    public DtoCategory updateCategory(String id, DtoCategoryUI dtoCategoryUI) {
        Category category = dao.findByIdAndIsSoftDeleted(id, false)
                .orElseThrow(() -> new RuntimeException("Kategori bulunamadı: " + id));

        // Slug güncelleme kontrolü
        if (StringUtils.hasText(dtoCategoryUI.getSlug()) && !dtoCategoryUI.getSlug().equals(category.getSlug())) {
            if (dao.existsBySlugAndIdNot(dtoCategoryUI.getSlug(), id)) {
                throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
            }
            category.setSlug(dtoCategoryUI.getSlug());
        }

        // Temel alanları güncelle
        if (StringUtils.hasText(dtoCategoryUI.getName())) {
            category.setName(dtoCategoryUI.getName());
        }
        if (StringUtils.hasText(dtoCategoryUI.getDescription())) {
            category.setDescription(dtoCategoryUI.getDescription());
        }
        if (StringUtils.hasText(dtoCategoryUI.getImageUrl())) {
            category.setImageUrl(dtoCategoryUI.getImageUrl());
        }
        if (StringUtils.hasText(dtoCategoryUI.getIcon())) {
            category.setIcon(dtoCategoryUI.getIcon());
        }
        if (dtoCategoryUI.getStatus() != null) {
            category.setStatus(dtoCategoryUI.getStatus());
        }
        if (dtoCategoryUI.getSortOrder() != null) {
            category.setSortOrder(dtoCategoryUI.getSortOrder());
        }
        if (dtoCategoryUI.getMetadata() != null) {
            category.setMetadata(dtoCategoryUI.getMetadata());
        }
        if (StringUtils.hasText(dtoCategoryUI.getMetaTitle())) {
            category.setMetaTitle(dtoCategoryUI.getMetaTitle());
        }
        if (StringUtils.hasText(dtoCategoryUI.getMetaDescription())) {
            category.setMetaDescription(dtoCategoryUI.getMetaDescription());
        }
        if (StringUtils.hasText(dtoCategoryUI.getMetaKeywords())) {
            category.setMetaKeywords(dtoCategoryUI.getMetaKeywords());
        }

        // Parent değişikliğini kontrol et
        String currentParentId = category.getParentCategory() != null ? category.getParentCategory().getId() : null;
        if (dtoCategoryUI.getParentId() != null && !dtoCategoryUI.getParentId().equals(currentParentId)) {
            updateCategoryHierarchy(category, dtoCategoryUI.getParentId());
        }

        save(category);
        log.info("Kategori güncellendi: {} (ID: {})", category.getName(), category.getId());

        return toDTO(category);
    }

    @Override
    public void deleteCategory(String id) {
        Category category = dao.findByIdAndIsSoftDeleted(id, false)
                .orElseThrow(() -> new RuntimeException("Kategori bulunamadı: " + id));

        // Alt kategorileri kontrol et
        List<Category> children = dao.findByParentCategoryAndIsDeletedOrderBySortOrderAsc(
                id,  false
        );

        if (!children.isEmpty()) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        // Soft delete
      //  category.setIsDeleted(true);
        save(category);
        log.info("Kategori silindi: {} (ID: {})", category.getName(), category.getId());
    }

    @Override
    public DtoCategory getCategoryById(String id) {
        Category category = dao.findByIdAndIsSoftDeleted(id, false)
                .orElseThrow(() -> new RuntimeException("Kategori bulunamadı: " + id));
        return toCategoryDtoWithParent(category);
    }

    @Override
    public List<DtoCategory> getAllCategories() {
        List<Category> categories = dao.findByIsSoftDeletedOrderBySortOrderAsc(false);
        return categories.stream().map(this::toCategoryDtoWithParent).collect(Collectors.toList());
    }

    @Override
    public List<DtoCategory> getCategoriesByStatus(ProductStatus status) {
        List<Category> categories = dao.findByStatusAndIsSoftDeletedOrderBySortOrderAsc(status, false);
        return categories.stream().map(this::toCategoryDtoWithParent).collect(Collectors.toList());
    }

    @Override
    public List<DtoCategory> getRootCategories() {
        List<Category> categories = dao.findRootCategories();
        return categories.stream().map(this::toCategoryDtoWithParent).collect(Collectors.toList());
    }

    @Override
    public List<DtoCategory> getChildCategories(String parentId) {
        List<Category> categories = dao.findByParentCategoryAndIsDeletedOrderBySortOrderAsc(
                parentId, false
        );
        return categories.stream().map(this::toCategoryDtoWithParent).collect(Collectors.toList());
    }

    /**
     * Kategori ağacını tam hiyerarşik yapıda getir - OPTIMIZED
     * Tüm kategorileri tek query'de çeker, memory'de ağaç oluşturur (N+1 problem yok!)
     *
     * @return Tam ağaç yapısında kategori listesi
     */
    @Override
    public List<DtoCategory> getCategoryTree() {
        log.info("Kategori ağacı oluşturuluyor - Optimized single query");
        long startTime = System.currentTimeMillis();

        // 1. TÜM KATEGORİLERİ TEK QUERY'DE ÇEK (isSoftDeleted = false olanlar)
        List<Category> allCategories = dao.findByIsSoftDeletedOrderBySortOrderAsc(false);
        log.info("Toplam {} kategori tek query'de çekildi", allCategories.size());

        // 2. TÜM VARIANTS'LARI BATCH QUERY İLE ÇEK
        Map<String, List<CategoryVariant>> variantsByCategory = new HashMap<>();
        if (categoryVariantService != null && !allCategories.isEmpty()) {
            List<String> categoryIds = allCategories.stream()
                    .map(Category::getId)
                    .collect(Collectors.toList());

            // Tüm varyantları tek seferde çek
            List<CategoryVariant> allVariants = categoryVariantService.findByCategoryIds(categoryIds);

            // Category ID'ye göre grupla
            variantsByCategory = allVariants.stream()
                    .collect(Collectors.groupingBy(v -> v.getCategory().getId()));

            log.info("Toplam {} varyant batch query ile çekildi", allVariants.size());
        }

        // 3. TÜM ATTRIBUTES'LARI BATCH QUERY İLE ÇEK
        Map<String, List<CategoryAttribute>> attributesByCategory = new HashMap<>();
        if (categoryAttributeService != null && !allCategories.isEmpty()) {
            List<String> categoryIds = allCategories.stream()
                    .map(Category::getId)
                    .collect(Collectors.toList());

            // Tüm attribute'ları tek seferde çek
            List<CategoryAttribute> allAttributes = categoryAttributeService.findByCategoryIds(categoryIds);

            // Category ID'ye göre grupla
            attributesByCategory = allAttributes.stream()
                    .collect(Collectors.groupingBy(a -> a.getCategory().getId()));

            log.info("Toplam {} attribute batch query ile çekildi", allAttributes.size());
        }

        // 4. MEMORY'DE AĞAÇ OLUŞTUR
        Map<String, DtoCategory> categoryMap = new HashMap<>();
        Map<String, List<DtoCategory>> childrenMap = new HashMap<>();

        // Tüm kategorileri DTO'ya çevir ve map'e ekle
        for (Category category : allCategories) {
            DtoCategory dto = toDTO(category);

            // Variants ekle (cache'den)
            List<CategoryVariant> variants = variantsByCategory.get(category.getId());
            if (variants != null && !variants.isEmpty()) {
                dto.setVariants(variants.stream()
                        .map(this::toVariantResponse)
                        .collect(Collectors.toList()));
            }

            // Attributes ekle (cache'den)
            List<CategoryAttribute> attributes = attributesByCategory.get(category.getId());
            if (attributes != null && !attributes.isEmpty()) {
                dto.setAttributes(attributes.stream()
                        .map(this::toAttributeResponse)
                        .collect(Collectors.toList()));
            }

            categoryMap.put(category.getId(), dto);

            // Parent-child ilişkisini kur
            if (category.getParentCategory() != null) {
                String parentId = category.getParentCategory().getId();
                dto.setParentId(parentId); // Frontend hiyerarşi için gerekli
                childrenMap.computeIfAbsent(parentId, k -> new ArrayList<>()).add(dto);
            }
        }

        // Children'ları parent'lara ata
        for (Map.Entry<String, List<DtoCategory>> entry : childrenMap.entrySet()) {
            DtoCategory parent = categoryMap.get(entry.getKey());
            if (parent != null) {
                parent.setChildren(entry.getValue());
            }
        }

        // Root kategorileri bul (parentCategory == null olanlar)
        List<DtoCategory> tree = allCategories.stream()
                .filter(c -> c.getParentCategory() == null)
                .map(c -> categoryMap.get(c.getId()))
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        long endTime = System.currentTimeMillis();
        log.info("Kategori ağacı başarıyla oluşturuldu - {} root kategori, {} ms",
                tree.size(), (endTime - startTime));

        return tree;
    }

    /**
     * Belirli bir kategori için recursive olarak tam ağaç yapısı oluşturur
     * Children, variants ve attributes dahil
     *
     * @param category Ağaç oluşturulacak kategori
     * @return Tam detaylı DtoCategory
     */
    private DtoCategory buildFullCategoryTree(Category category) {
        log.debug("Kategori ağacı oluşturuluyor: {} (Level: {})", category.getName(), category.getLevel());

        // Category'yi DTO'ya çevir
        DtoCategory dto = toDTO(category);

        // Alt kategorileri getir ve recursive olarak işle
        List<Category> children = dao.findByParentCategoryAndIsDeletedOrderBySortOrderAsc(
                category.getId(), false
        );

        if (!children.isEmpty()) {
            List<DtoCategory> childrenDtos = children.stream()
                    .map(this::buildFullCategoryTree)  // Recursive çağrı
                    .collect(Collectors.toList());
            dto.setChildren(childrenDtos);
            log.debug("Kategori '{}' için {} alt kategori eklendi", category.getName(), childrenDtos.size());
        }

        // Varyantları ekle
        if (categoryVariantService != null) {
            List<CategoryVariant> variants = categoryVariantService.getCategoryVariants(category.getId());
            if (!variants.isEmpty()) {
                List<CategoryVariantResponse> variantResponses = variants.stream()
                        .map(this::toVariantResponse)
                        .collect(Collectors.toList());
                dto.setVariants(variantResponses);
                log.debug("Kategori '{}' için {} varyant eklendi", category.getName(), variantResponses.size());
            }
        }

        // Attribute'ları ekle
        if (categoryAttributeService != null) {
            List<CategoryAttribute> attributes = categoryAttributeService.getCategoryAttributes(category.getId());
            if (!attributes.isEmpty()) {
                List<CategoryAttributeResponse> attributeResponses = attributes.stream()
                        .map(this::toAttributeResponse)
                        .collect(Collectors.toList());
                dto.setAttributes(attributeResponses);
                log.debug("Kategori '{}' için {} attribute eklendi", category.getName(), attributeResponses.size());
            }
        }

        return dto;
    }

    @Override
    public String getCategoryPath(String categoryId) {
        Category category = dao.findByIdAndIsSoftDeleted(categoryId, false)
                .orElseThrow(() -> new RuntimeException("Kategori bulunamadı: " + categoryId));
        return category.getPath();
    }

    @Override
    public String generateSlug(String name) {
        if (!StringUtils.hasText(name)) {
            throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
        }

        // Türkçe karakterleri dönüştür
        String normalized = name.toLowerCase()
                .replace('ı', 'i')
                .replace('ğ', 'g')
                .replace('ü', 'u')
                .replace('ş', 's')
                .replace('ö', 'o')
                .replace('ç', 'c')
                .replace('İ', 'i')
                .replace('Ğ', 'g')
                .replace('Ü', 'u')
                .replace('Ş', 's')
                .replace('Ö', 'o')
                .replace('Ç', 'c');

        // Unicode karakterleri normalize et
        normalized = Normalizer.normalize(normalized, Normalizer.Form.NFD);
        normalized = normalized.replaceAll("[^\\p{ASCII}]", "");

        // Slug formatına dönüştür
        String slug = normalized
                .trim()
                .replaceAll("[^a-z0-9\\s-]", "")
                .replaceAll("\\s+", "-")
                .replaceAll("-+", "-")
                .replaceAll("^-|-$", "");

        // Benzersizlik için suffix ekle
        String originalSlug = slug;
        int counter = 1;
        while (dao.existsBySlug(slug)) {
            slug = originalSlug + "-" + counter;
            counter++;
        }

        return slug;
    }

    @Override
    public void updateSortOrder(String categoryId, Integer newOrder) {
        Category category = dao.findByIdAndIsSoftDeleted(categoryId, false)
                .orElseThrow(() -> new RuntimeException("Kategori bulunamadı: " + categoryId));

        category.setSortOrder(newOrder);
        save(category);
        log.info("Kategori sıralaması güncellendi: {} -> {}", category.getName(), newOrder);
    }

    @Override
    public boolean existsBySlug(String slug) {
        return dao.existsBySlug(slug);
    }

    @Override
    public boolean existsBySlug(String slug, String excludeId) {
        return dao.existsBySlugAndIdNot(slug, excludeId);
    }

    private void updateCategoryHierarchy(Category category, String newParentId) {
        Integer newLevel;
        String newPath;
        Category newParent;

        if (!StringUtils.hasText(newParentId)) {
            // Ana kategori yapılıyor
            newLevel = 0;
            newPath = "/" + category.getSlug();
            newParent=null;
        } else {
            // Alt kategori yapılıyor
             newParent = dao.findByIdAndIsSoftDeleted(newParentId, false)
                    .orElseThrow(() -> new RuntimeException("Üst kategori bulunamadı: " + newParentId));

            // Döngüsel referans kontrolü
            if (isDescendant(newParent, category.getId())) {
                throw new TOpenException(new TOpenMessage(TMessageType.UNEXPECTED_ERROR_9999));
            }

            newLevel = newParent.getLevel() + 1;
            newPath = newParent.getPath() + "/" + category.getSlug();
        }

        category.setParentCategory(newParent);
        category.setLevel(newLevel);
        category.setPath(newPath);

        // Alt kategorilerin path'lerini güncelle
        updateChildrenPaths(category);
    }

    private void updateChildrenPaths(Category parent) {
        List<Category> children = dao.findByParentCategoryAndIsDeletedOrderBySortOrderAsc(
                parent.getId(),  false
        );

        for (Category child : children) {
            child.setLevel(parent.getLevel() + 1);
            child.setPath(parent.getPath() + "/" + child.getSlug());
            save(child);
            updateChildrenPaths(child);
        }
    }

    private boolean isDescendant(Category category, String ancestorId) {
        if (category.getParentCategory() == null) {
            return false;
        }
        if (category.getParentCategory().getId().equals(ancestorId)) {
            return true;
        }
        Category parent = dao.findById(category.getParentCategory().getId()).orElse(null);
        return parent != null && isDescendant(parent, ancestorId);
    }

   

    // ===== İlişkisel Metodlar =====

    @Override
    public DtoCategory getCategoryWithRelations(String categoryId, boolean includeChildren,
                                               boolean includeVariants, boolean includeAttributes) {
        Category category = dao.findByIdAndIsSoftDeleted(categoryId, false)
                .orElseThrow(() -> new RuntimeException("Kategori bulunamadı: " + categoryId));

        DtoCategory dto = toCategoryDtoWithParent(category);

        // Alt kategorileri ekle
        if (includeChildren) {
            List<Category> children = dao
                    .findByParentCategoryAndIsDeletedOrderBySortOrderAsc(
                            categoryId, false
                    );
            dto.setChildren(toDTOList(children));
           // dto.setChildrenCount(children.size());
        }

        // Varyantları ekle
        if (includeVariants && categoryVariantService != null) {
            List<CategoryVariant> variants = categoryVariantService.getCategoryVariants(categoryId);
            dto.setVariants(variants.stream()
                    .map(this::toVariantResponse)
                    .collect(Collectors.toList()));
           // dto.setVariantCount(variants.size());
        }

        // Attribute'ları ekle
        if (includeAttributes && categoryAttributeService != null) {
            List<CategoryAttribute> attributes = categoryAttributeService.getCategoryAttributes(categoryId);
            dto.setAttributes(attributes.stream()
                    .map(this::toAttributeResponse)
                    .collect(Collectors.toList()));
           // dto.setAttributeCount(attributes.size());
        }

        log.info("Category ilişkilerle getirildi: {}, Children={}, Variants={}, Attributes={}",
                categoryId, includeChildren, includeVariants, includeAttributes);

        return dto;
    }

    /**
     * Kategori ağacını ilişkileriyle birlikte getir
     * getCategoryTree() ile aynı işlevi görür (backward compatibility için)
     *
     * @return Tam ağaç yapısında kategori listesi (variants ve attributes dahil)
     */
    @Override
    public List<DtoCategory> getCategoryTreeWithRelations() {
        log.info("Kategori ağacı ilişkilerle getiriliyor");
        return getCategoryTree(); // Artık getCategoryTree zaten ilişkileri içeriyor
    }

    /**
     * Belirli bir kategoriyi children'larıyla birlikte getir
     *
     * @param categoryId Kategori ID
     * @param recursive  Recursive olarak tüm alt ağacı getir mi?
     * @return Category ve children'ları
     */
    @Override
    public DtoCategory getCategoryWithChildren(String categoryId, boolean recursive) {
        log.info("Kategori children'larıyla getiriliyor: categoryId={}, recursive={}", categoryId, recursive);

        Category category = dao.findByIdAndIsSoftDeleted(categoryId, false)
                .orElseThrow(() -> new RuntimeException("Kategori bulunamadı: " + categoryId));

        if (recursive) {
            // Recursive - Tam ağaç yapısı
            return buildFullCategoryTree(category);
        } else {
            // Sadece 1 seviye - Direkt children'ları getir
            return getCategoryWithRelations(categoryId, true, false, false);
        }
    }

    /**
     * Category entity'yi DtoCategory'ye çevirir ve parentId'yi set eder.
     * ModelMapper parentCategory.id → parentId mapping'ini otomatik yapmadığı için
     * burada açıkça set ediyoruz.
     */
    private DtoCategory toCategoryDtoWithParent(Category category) {
        DtoCategory dto = toDTO(category);
        if (category.getParentCategory() != null) {
            dto.setParentId(category.getParentCategory().getId());
        }
        return dto;
    }

    /**
     * CategoryVariant entity'yi Response DTO'ya dönüştür
     */
    private CategoryVariantResponse toVariantResponse(CategoryVariant entity) {
        return CategoryVariantResponse.builder()
             //   .id(entity.getId())
              //  .categoryId(entity.getCategory() != null ? entity.getCategory().getId() : null)
                .variantKey(entity.getVariantKey())
                .variantName(entity.getVariantName())
                .variantNameEn(entity.getVariantNameEn())
                .variantType(entity.getVariantType())
                .isRequired(entity.getIsRequired())
                .displayOrder(entity.getDisplayOrder())
                .options(entity.getOptions())
               // .optionDetails(entity.getOptionDetails())
               // .unit(entity.getUnit())
               // .affectsPrice(entity.getAffectsPrice())
               // .affectsStock(entity.getAffectsStock())
               // .showInProductList(entity.getShowInProductList())
               // .enableImagePerVariant(entity.getEnableImagePerVariant())
               // .isActive(entity.getIsActive())
               // .inheritFromParent(entity.getInheritFromParent())
               // .createdAt(entity.getCreatedAt() != null ? entity.getCreatedAt().toString() : null)
              //  .updatedAt(entity.getUpdatedAt() != null ? entity.getUpdatedAt().toString() : null)
                .build();
    }

    /**
     * CategoryAttribute entity'yi Response DTO'ya dönüştür
     */
    private CategoryAttributeResponse toAttributeResponse(CategoryAttribute entity) {
        return CategoryAttributeResponse.builder()
                .id(entity.getId())
              //  .categoryId(entity.getCategoryId())
                .attributeKey(entity.getAttributeKey())
                .attributeName(entity.getAttributeName())
                .attributeNameEn(entity.getAttributeNameEn())
                .attributeType(entity.getAttributeType())
                .isRequired(entity.getIsRequired())
                .isFilterable(entity.getIsFilterable())
               // .isSearchable(entity.getIsSearchable())
               // .isComparable(entity.getIsComparable())
               // .displayOrder(entity.getDisplayOrder())
                //.unit(entity.getUnit())
               // .options(entity.getOptions())
                //.validationRegex(entity.getValidationRegex())
               // .minValue(entity.getMinValue())
               // .maxValue(entity.getMaxValue())
                //.placeholder(entity.getPlaceholder())
               // .helpText(entity.getHelpText())
                .isActive(entity.getIsActive())
                //.inheritFromParent(entity.getInheritFromParent())
                //.createdAt(entity.getCreatedAt() != null ? entity.getCreatedAt().toString() : null)
               // .updatedAt(entity.getUpdatedAt() != null ? entity.getUpdatedAt().toString() : null)
                .build();
    }
}
