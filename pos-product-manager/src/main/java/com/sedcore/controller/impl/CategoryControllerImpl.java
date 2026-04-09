package com.sedcore.controller.impl;

import com.sedcore.controller.CategoryController;
import com.sedcore.entity.CategoryVariant;
import com.sedcore.enums.AttributeType;
import com.sedcore.enums.ProductStatus;
import com.sedcore.model.CategoryVariantResponse;
import com.sedcore.model.DtoCategory;
import com.sedcore.model.DtoCategoryUI;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.CategoryService;
import com.sedcore.service.CategoryVariantService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.List;

@RestController
@RequestMapping("/api/category")
@RequiredArgsConstructor
@Slf4j
public class CategoryControllerImpl implements CategoryController {

    private final CategoryService categoryService;
    private final CategoryVariantService categoryVariantService;

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<DtoCategory>> createCategory(@RequestBody DtoCategoryUI dtoCategoryUI) {
        try {
            log.info("Kategori oluşturma isteği alındı: {}", dtoCategoryUI.getName());
            DtoCategory category = categoryService.createCategory(dtoCategoryUI);
            return ResponseEntity.ok(ApiResponse.success("Kategori başarıyla oluşturuldu",category));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kategori oluşturma hatası: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<DtoCategory>> updateCategory(
            @PathVariable String id,
            @RequestBody DtoCategoryUI dtoCategoryUI) {
        try {
            log.info("Kategori güncelleme isteği alındı: {}", id);
            DtoCategory category = categoryService.updateCategory(id, dtoCategoryUI);
            return ResponseEntity.ok(ApiResponse.success("Kategori başarıyla güncellendi",category));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kategori güncelleme hatası: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(@PathVariable String id) {
        try {
            log.info("Kategori silme isteği alındı: {}", id);
            categoryService.deleteCategory(id);
            return ResponseEntity.ok(ApiResponse.success( "Kategori başarıyla silindi",null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kategori silme hatası: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DtoCategory>> getCategoryById(@PathVariable String id) {
        try {
            log.info("Kategori detay isteği alındı: {}", id);
            DtoCategory category = categoryService.getCategoryById(id);
            return ResponseEntity.ok(ApiResponse.success( "Kategori başarıyla getirildi",category));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kategori getirme hatası: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getAllCategories() {
        try {
            log.info("Tüm kategoriler listeleme isteği alındı");
            List<DtoCategory> categories = categoryService.getAllCategories();
            return ResponseEntity.ok(ApiResponse.success(
                    categories.size() + " kategori başarıyla getirildi",categories));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kategoriler listeleme hatası: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getCategoriesByStatus(@PathVariable String status) {
        try {
            log.info("Duruma göre kategori listeleme isteği alındı: {}", status);
            ProductStatus productStatus = ProductStatus.valueOf(status.toUpperCase());
            List<DtoCategory> categories = categoryService.getCategoriesByStatus(productStatus);
            return ResponseEntity.ok(ApiResponse.success(
                    categories.size() + " kategori başarıyla getirildi",categories));
        } catch (IllegalArgumentException e) {
            log.error("Geçersiz durum parametresi: {}", status);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Geçersiz durum parametresi: " + status));
        } catch (Exception e) {
            log.error("Kategoriler listeleme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Kategoriler listelenirken hata oluştu: " + e));
        }
    }

    @Override
    @GetMapping("/root")
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getRootCategories() {
        try {
            log.info("Ana kategoriler listeleme isteği alındı");
            List<DtoCategory> categories = categoryService.getRootCategories();
            return ResponseEntity.ok(ApiResponse.success(
                    categories.size() + " ana kategori başarıyla getirildi", categories));
        } catch (Exception e) {
            log.error("Ana kategoriler listeleme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Ana kategoriler listelenirken hata oluştu: " + e));
        }
    }

    @Override
    @GetMapping("/children/{parentId}")
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getChildCategories(@PathVariable String parentId) {
        try {
            log.info("Alt kategoriler listeleme isteği alındı: {}", parentId);
            List<DtoCategory> categories = categoryService.getChildCategories(parentId);
            return ResponseEntity.ok(ApiResponse.success(
                    categories.size() + " alt kategori başarıyla getirildi",categories));
        } catch (Exception e) {
            log.error("Alt kategoriler listeleme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Alt kategoriler listelenirken hata oluştu: " + e));
        }
    }

    @Override
    @GetMapping("/tree")
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getCategoryTree() {
        try {
            log.info("Kategori ağacı listeleme isteği alındı");
            List<DtoCategory> tree = categoryService.getCategoryTree();
            return ResponseEntity.ok(ApiResponse.success("Kategori ağacı başarıyla getirildi",tree));
        } catch (Exception e) {
            log.error("Kategori ağacı listeleme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Kategori ağacı listelenirken hata oluştu: " + e));
        }
    }

    @Override
    @GetMapping("/path/{categoryId}")
    public ResponseEntity<ApiResponse<String>> getCategoryPath(@PathVariable String categoryId) {
        try {
            log.info("Kategori yolu getirme isteği alındı: {}", categoryId);
            String path = categoryService.getCategoryPath(categoryId);
            return ResponseEntity.ok(ApiResponse.success( "Kategori yolu başarıyla getirildi",path));
        } catch (Exception e) {
            log.error("Kategori yolu getirme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Kategori yolu getirilirken hata oluştu: " + e));
        }
    }

    @Override
    @GetMapping("/generate-slug")
    public ResponseEntity<ApiResponse<String>> generateSlug(@RequestParam String name) {
        try {
            log.info("Slug oluşturma isteği alındı: {}", name);
            String slug = categoryService.generateSlug(name);
            return ResponseEntity.ok(ApiResponse.success(slug, "Slug başarıyla oluşturuldu"));
        } catch (Exception e) {
            log.error("Slug oluşturma hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Slug oluşturulurken hata oluştu: " + e));
        }
    }

    @Override
    @PutMapping("/{categoryId}/sort-order")
    public ResponseEntity<ApiResponse<Void>> updateSortOrder(
            @PathVariable String categoryId,
            @RequestParam Integer newOrder) {
        try {
            log.info("Sıralama güncelleme isteği alındı: {} -> {}", categoryId, newOrder);
            categoryService.updateSortOrder(categoryId, newOrder);
            return ResponseEntity.ok(ApiResponse.success("Sıralama başarıyla güncellendi",null));
        } catch (Exception e) {
            log.error("Sıralama güncelleme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Sıralama güncellenirken hata oluştu: " + e));
        }
    }

    @Override
    @GetMapping("/{categoryId}/with-relations")
    public ResponseEntity<ApiResponse<DtoCategory>> getCategoryWithRelations(
            @PathVariable String categoryId,
            @RequestParam(required = false, defaultValue = "false") Boolean includeChildren,
            @RequestParam(required = false, defaultValue = "false") Boolean includeVariants,
            @RequestParam(required = false, defaultValue = "false") Boolean includeAttributes) {
        try {
            log.info("Category ilişkilerle getirme isteği: {}, Children={}, Variants={}, Attributes={}",
                    categoryId, includeChildren, includeVariants, includeAttributes);
            DtoCategory category = categoryService.getCategoryWithRelations(
                    categoryId, includeChildren, includeVariants, includeAttributes
            );
            return ResponseEntity.ok(ApiResponse.success("Kategori ilişkileriyle başarıyla getirildi", category));
        } catch (Exception e) {
            log.error("Kategori ilişkileriyle getirme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Kategori getirilirken hata oluştu: " + e));
        }
    }

    @Override
    @GetMapping("/tree-with-relations")
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getCategoryTreeWithRelations() {
        try {
            log.info("Kategori ağacı ilişkilerle listeleme isteği alındı");
            List<DtoCategory> tree = categoryService.getCategoryTreeWithRelations();
            return ResponseEntity.ok(ApiResponse.success("Kategori ağacı ilişkileriyle başarıyla getirildi", tree));
        } catch (Exception e) {
            log.error("Kategori ağacı ilişkilerle listeleme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Kategori ağacı listelenirken hata oluştu: " + e));
        }
    }

   /*  @Override
    @GetMapping("/{categoryId}/with-children")
    public ResponseEntity<ApiResponse<DtoCategory>> getCategoryWithChildren(
            @PathVariable String categoryId,
            @RequestParam(required = false, defaultValue = "false") Boolean recursive) {
        try {
            log.info("Category children ile getirme isteği: {}, Recursive={}", categoryId, recursive);
            DtoCategory category = categoryService.getCategoryWithChildren(categoryId, recursive);
            
        } catch (Exception e) {
          
        }
    }*/

    @Override
    public ResponseEntity<ApiResponse<CategoryVariant>> addVariantToCategory(String categoryId,
            String variantKey, String variantName, AttributeType variantType) {
        
        try {
            CategoryVariant categoryVariant = categoryVariantService.addVariantToCategory(categoryId, variantKey, variantName, variantType);
           return ResponseEntity.ok(ApiResponse.success("Kategori alt kategorileriyle başarıyla getirildi", categoryVariant));
        } catch (Exception e) {
              log.error("Kategoriye varyanat ekleme hatası: {}", e, e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Kategoriye varyanat ekleme hatası: " + e));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<DtoCategory>> getCategoryWithChildren(String categoryId, Boolean recursive) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'getCategoryWithChildren'");
    }
}
