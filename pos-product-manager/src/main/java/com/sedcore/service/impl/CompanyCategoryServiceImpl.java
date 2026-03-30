package com.sedcore.service.impl;

import com.sedcore.entity.Category;
import com.sedcore.entity.CompanyCategory;
import com.sedcore.entity.Product;
import com.sedcore.model.*;
import com.sedcore.repository.CategoryRepository;
import com.sedcore.repository.CompanyCategoryRepository;
import com.sedcore.repository.ProductRepository;
import com.sedcore.service.CategoryService;
import com.sedcore.service.CompanyCategoryService;
import com.towpen.base.context.TOpenContextHolder;
import com.towpen.base.security.BaseDbServiceImp;
import com.towpen.base.security.ISessionInstanceService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

@Service
@Slf4j
@Transactional
public class CompanyCategoryServiceImpl extends BaseDbServiceImp<CompanyCategoryRepository, CompanyCategory> implements CompanyCategoryService {

    @PersistenceContext
    private EntityManager entityManager;

    private final CategoryRepository categoryRepository;
    private final CategoryService categoryService;
    private final ISessionInstanceService sessionInstanceService;

    public CompanyCategoryServiceImpl(
            CategoryRepository categoryRepository,
            @Lazy CategoryService categoryService,
            ISessionInstanceService sessionInstanceService) {
        this.categoryRepository = categoryRepository;
        this.categoryService = categoryService;
        this.sessionInstanceService = sessionInstanceService;
    }

    // -----------------------------------------------------------------------
    // Mevcut firmanın companyCode'unu al
    // -----------------------------------------------------------------------
    private String getCurrentCompanyCode() {
        var ctx = TOpenContextHolder.getContext();
        if (ctx != null && ctx.getCompanyCode() != null) {
            return ctx.getCompanyCode();
        }
        return sessionInstanceService.getSelectedCompanyCode();
    }

    // -----------------------------------------------------------------------
    // Firmanın seçtiği kategorileri AĞAÇ yapısında döner
    // Flutter /my-categories → bu method çalışır
    // -----------------------------------------------------------------------
    @Override
    @Transactional(readOnly = true)
    public List<DtoCategory> getMyCategories() {
        // 1) Firmanın seçtiği category_id listesini al
        Set<String> selectedIds = new HashSet<>(dao.findActiveCategoryIds());

        if (selectedIds.isEmpty()) {
            return Collections.emptyList();
        }

        // 2) Tüm global kategori ağacını al, seçili olmayanları filtrele
        List<DtoCategory> fullTree = categoryService.getCategoryTree();
        return filterTree(fullTree, selectedIds);
    }

    // Ağacı recursive olarak filtrele — sadece seçili kategorileri tut
    private List<DtoCategory> filterTree(List<DtoCategory> nodes, Set<String> selectedIds) {
        if (nodes == null) return Collections.emptyList();
        List<DtoCategory> result = new ArrayList<>();
        for (DtoCategory node : nodes) {
            List<DtoCategory> filteredChildren = filterTree(node.getChildren(), selectedIds);
            if (selectedIds.contains(node.getId()) || !filteredChildren.isEmpty()) {
                node.setChildren(filteredChildren);
                result.add(node);
            }
        }
        return result;
    }

    // -----------------------------------------------------------------------
    // Düz liste (ağaç değil)
    // -----------------------------------------------------------------------
    @Override
    @Transactional(readOnly = true)
    public List<CompanyCategoryResponse> getMyCategoryList() {
        List<CompanyCategory> entries = dao.findByIsActiveTrueOrderByDisplayOrderAsc();

        return entries.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // -----------------------------------------------------------------------
    // Tek kategori ekle
    // -----------------------------------------------------------------------
    @Override
    public CompanyCategoryResponse addCategory(CompanyCategoryRequest request) {
        String companyCode = getCurrentCompanyCode();

        // Zaten var mı kontrol et
        dao.findByCompanyCodeAndCategoryId(companyCode, request.getCategoryId())
                .ifPresent(existing -> {
                    throw new RuntimeException("Bu kategori zaten tanımlı: " + request.getCategoryId());
                });

        // Kategori global havuzda var mı?
        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Kategori bulunamadı: " + request.getCategoryId()));

        CompanyCategory entry = CompanyCategory.builder()
                .categoryId(request.getCategoryId())
                .isActive(true)
                .displayOrder(request.getDisplayOrder())
                .build();
        entry.setCompanyCode(companyCode);  // TOpenSimpleCompanyEntity'den miras

        CompanyCategory saved = dao.save(entry);
        saved.setCategory(category);

        log.info("Firma [{}] kategoriye eklendi: {} ({})", companyCode, category.getName(), request.getCategoryId());
        return toResponse(saved);
    }

    // -----------------------------------------------------------------------
    // Tek kategori kaldır
    // -----------------------------------------------------------------------
    @Override
    public void removeCategory(String categoryId) {
        String companyCode = getCurrentCompanyCode();

        CompanyCategory entry = dao
                .findByCompanyCodeAndCategoryId(companyCode, categoryId)
                .orElseThrow(() -> new RuntimeException("Bu kategoriye ait kayıt bulunamadı: " + categoryId));

        dao.delete(entry);
        log.info("Firma [{}] kategoriden çıkarıldı: {}", companyCode, categoryId);
    }

    // -----------------------------------------------------------------------
    // Toplu güncelleme — "Kategori Tanımla" ekranındaki Kaydet butonu
    // -----------------------------------------------------------------------
    @Override
    public List<CompanyCategoryResponse> bulkSetCategories(CompanyCategoryBulkRequest request) {
        String companyCode = getCurrentCompanyCode();

        // 1) Mevcut seçimleri sil
        List<CompanyCategory> existing = dao.findAllByOrderByDisplayOrderAsc();
        if (!existing.isEmpty()) {
            dao.deleteAll(existing);
            entityManager.flush(); // DELETE'leri DB'ye hemen gönder; INSERT öncesi constraint ihlalini önler
        }

        // 2) Yeni listeyi kaydet
        if (request.getCategoryIds() == null || request.getCategoryIds().isEmpty()) {
            log.info("Firma [{}] tüm kategorileri temizledi", companyCode);
            return Collections.emptyList();
        }

        Set<String> validIds =
                StreamSupport.stream(
                                categoryRepository.findAllById(request.getCategoryIds()).spliterator(),
                                false
                        )
                        .map(Category::getId)
                        .collect(Collectors.toSet());

        List<CompanyCategory> newEntries = new ArrayList<>();
        for (int i = 0; i < request.getCategoryIds().size(); i++) {
            String catId = request.getCategoryIds().get(i);
            if (!validIds.contains(catId)) {
                log.warn("Geçersiz kategori ID atlandı: {}", catId);
                continue;
            }
            CompanyCategory entry = CompanyCategory.builder()
                    .categoryId(catId)
                    .isActive(true)
                    .displayOrder(i)
                    .build();
            entry.setCompanyCode(companyCode);
            newEntries.add(entry);
        }

        List<CompanyCategory> saved = (List<CompanyCategory>) saveAll(newEntries);

        log.info("Firma [{}] kategori seçimi güncellendi: {} kategori", companyCode, saved.size());

        return saved.stream().map(this::toResponse).collect(Collectors.toList());
    }

    // -----------------------------------------------------------------------
    // Firmanın bu kategoriye sahip olup olmadığını kontrol et
    // -----------------------------------------------------------------------
    @Override
    @Transactional(readOnly = true)
    public boolean hasCategory(String categoryId) {
        return dao.findByCategoryId(categoryId).isPresent();
    }

    // -----------------------------------------------------------------------
    // "Kategori Tanımla" ekranı için — tüm global kategoriler + hangisi seçili?
    // -----------------------------------------------------------------------
    @Override
    @Transactional(readOnly = true)
    public List<DtoCategory> getAllCategoriesWithSelection() {
        // Tüm global kategoriler
        List<DtoCategory> allCategories = categoryService.getCategoryTree();

        // Firmanın seçtikleri
        Set<String> selectedIds = new HashSet<>(dao.findActiveCategoryIds());

        // Her kategoriye isSelected flag'i ekle (metadata alanı kullanılır)
        markSelected(allCategories, selectedIds);

        return allCategories;
    }

    // -----------------------------------------------------------------------
    // Yardımcı: kategorilere isSelected flag işaretle (recursive)
    // -----------------------------------------------------------------------
    private void markSelected(List<DtoCategory> categories, Set<String> selectedIds) {
        if (categories == null) return;
        for (DtoCategory cat : categories) {
            cat.setIsSelected(selectedIds.contains(cat.getId()));
            markSelected(cat.getChildren(), selectedIds);
        }
    }


    // -----------------------------------------------------------------------
    // Entity → Response DTO dönüşümü
    // -----------------------------------------------------------------------
    private CompanyCategoryResponse toResponse(CompanyCategory entity) {
        CompanyCategoryResponse.CompanyCategoryResponseBuilder builder = CompanyCategoryResponse.builder()
                .id(entity.getId())
                .companyCode(entity.getCompanyCode())
                .categoryId(entity.getCategoryId())
                .isActive(entity.getIsActive())
                .displayOrder(entity.getDisplayOrder());

        // Kategori detayları join ile geldiyse ekle
        if (entity.getCategory() != null) {
            Category cat = entity.getCategory();
            builder.categoryName(cat.getName())
                    .categorySlug(cat.getSlug())
                    .categoryPath(cat.getPath())
                    .categoryLevel(cat.getLevel())
                    .categoryParentId(cat.getParentCategory() != null ? cat.getParentCategory().getId() : null)
                    .categoryImageUrl(cat.getImageUrl())
                    .categoryIcon(cat.getIcon())
                    .categoryStatus(cat.getStatus() != null ? cat.getStatus().name() : null);
        } else {
            // Lazy load — sadece id var, detay yok
            builder.categoryName("—");
        }

        return builder.build();
    }

    @Override
    public Class<?> getDTOClassForService() {
        return CompanyCategoryResponse.class;
    }
}
