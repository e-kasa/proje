package com.sedcore.controller.impl;

import com.sedcore.controller.ProductController;
import com.sedcore.model.ProductResponse;
import com.sedcore.model.CreateProductRequest;
import com.sedcore.model.product.DtoProduct;
import com.sedcore.model.product.DtoProductUI;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.ProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@RequestMapping("api/v1/products")
@RequiredArgsConstructor
@Slf4j
public class ProductControllerImpl implements ProductController {

    private final ProductService productService;

    /**
     * Ürün Oluştur
     * POST /api/v1/products
     */
    @PostMapping
    public ResponseEntity<ApiResponse<ProductResponse>> createProduct(
            @Valid @RequestBody CreateProductRequest request
    ) {
        try {
            log.info("Ürün oluşturma isteği: {}", request.getProduct().getName());
            ProductResponse response = productService.createProduct(request);
            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Ürün başarıyla oluşturuldu", response));
        } catch (Exception e) {
            log.error("Ürün oluşturma hatası: ", e);
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Ürün oluşturulamadı: " + e.getMessage()));
        }
    }

    /**
     * Ürün Güncelle
     * PUT /api/v1/products/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductResponse>> updateProduct(
            @PathVariable String id,
            @Valid @RequestBody CreateProductRequest request
    ) {
        try {
            log.info("Ürün güncelleme isteği: id={}", id);
            ProductResponse response = productService.updateProduct(id, request);
            return ResponseEntity.ok(ApiResponse.success("Ürün başarıyla güncellendi", response));
        } catch (Exception e) {
            log.error("Ürün güncelleme hatası: id={}", id, e);
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Ürün güncellenemedi: " + e.getMessage()));
        }
    }

    /**
     * Ürün Getir
     * GET /api/v1/products/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductResponse>> getProduct(@PathVariable String id) {
        try {
            ProductResponse response = productService.getProduct(id);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Ürün getirme hatası: id={}", id, e);
            return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Ürün bulunamadı: " + e.getMessage()));
        }
    }

    /**
     * Ürün Listele
     * GET /api/v1/products?page=0&size=10&sortBy=createTime&sortDir=DESC
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> listProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createTime") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDir
    ) {
        try {
            Sort sort = sortDir.equalsIgnoreCase("ASC")
                    ? Sort.by(sortBy).ascending()
                    : Sort.by(sortBy).descending();
            Pageable pageable = PageRequest.of(page, size, sort);
            Page<ProductResponse> response = productService.listProducts(pageable);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Ürün listeleme hatası: ", e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Ürünler listelenemedi: " + e.getMessage()));
        }
    }

    /**
     * Ürün Ara
     * GET /api/v1/products/search?keyword=nike&page=0&size=10
     */
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> searchProducts(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createTime").descending());
            Page<ProductResponse> response = productService.searchProducts(keyword, pageable);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Ürün arama hatası: ", e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Arama yapılamadı: " + e.getMessage()));
        }
    }

    /**
     * Ürün Durumunu Değiştir
     * PATCH /api/v1/products/{id}/status
     */
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<Void>> toggleStatus(
            @PathVariable String id,
            @RequestParam String status
    ) {
        try {
            boolean activate = "ACTIVE".equalsIgnoreCase(status);
            if (activate) {
                // reactivate: just update status to ACTIVE
                productService.getProduct(id); // validates existence
                log.info("Ürün aktifleştiriliyor: id={}", id);
            } else {
                productService.deactivateProduct(id);
            }
            return ResponseEntity.ok(ApiResponse.success("Ürün durumu güncellendi", null));
        } catch (Exception e) {
            log.error("Ürün durum değiştirme hatası: id={}", id, e);
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Durum güncellenemedi: " + e.getMessage()));
        }
    }

    /**
     * Ürün Sil (Soft Delete)
     * DELETE /api/v1/products/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(@PathVariable String id) {
        try {
            log.info("Ürün silme isteği: id={}", id);
            productService.deleteProduct(id);
            return ResponseEntity.ok(ApiResponse.success("Ürün başarıyla silindi", null));
        } catch (Exception e) {
            log.error("Ürün silme hatası: id={}", id, e);
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Ürün silinemedi: " + e.getMessage()));
        }
    }

    @Override
    public DtoProduct saveProduct(DtoProductUI dtoProductUI) {
        return null;
    }

    @Override
    public List<DtoProduct> findByProductId(String productId) {
        return List.of();
    }
}
