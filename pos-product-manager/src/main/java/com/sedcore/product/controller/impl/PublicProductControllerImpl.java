package com.sedcore.product.controller.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.product.model.ProductResponse;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import com.sedcore.common.util.ExceptionMapper;
import com.sedcore.product.service.ProductService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Herkese açık (public) ürün ve kategori endpoint'leri.
 *
 * JWT gerektirmez — API Gateway'den gelen X-Company-Code header'ı
 * ile hangi firmanın verisi döneceği belirlenir.
 *
 * Bu controller'daki tüm metodlar SecurityConfiguration'da
 * permitAll() listesinde yer almalıdır.
 *
 * Örnek akış:
 *   www.bertspot.com → GET /product/api/v1/public/products
 *   Gateway         → X-Company-Code: BERTSPOT ekler
 *   CompanyContextFilter → CompanyContext.set("BERTSPOT")
 *   CompanyHibernateFilterActivator → Hibernate filter aktif
 *   ProductService  → WHERE company_code = 'BERTSPOT'
 *   Response        → Sadece BERTSPOT ürünleri
 */
@Slf4j
@RestController
@RequestMapping("api/v1/public")
@RequiredArgsConstructor
public class PublicProductControllerImpl {

    private final ProductService productService;

    /**
     * Ürün listesi — sayfalı
     * GET /product/api/v1/public/products?page=0&size=20
     */
    @GetMapping("/products")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> listProducts(
            @RequestParam(defaultValue = "0")    int page,
            @RequestParam(defaultValue = "20")   int size,
            @RequestParam(defaultValue = "createTime") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDir
    ) {
        if (!CompanyContext.hasCompany()) {
            log.warn("Public ürün listesi: company_code bulunamadı");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Firma bilgisi bulunamadı"));
        }

        try {
            Sort sort = sortDir.equalsIgnoreCase("ASC")
                    ? Sort.by(sortBy).ascending()
                    : Sort.by(sortBy).descending();
            Pageable pageable = PageRequest.of(page, size, sort);
            Page<ProductResponse> result = productService.listProducts(pageable);
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * Tekil ürün detayı
     * GET /product/api/v1/public/products/{id}
     */
    @GetMapping("/products/{id}")
    public ResponseEntity<ApiResponse<ProductResponse>> getProduct(@PathVariable String id) {
        if (!CompanyContext.hasCompany()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Firma bilgisi bulunamadı"));
        }

        try {
            ProductResponse result = productService.getProduct(id);
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * Ürün arama
     * GET /product/api/v1/public/products/search?keyword=laptop&page=0&size=10
     */
    @GetMapping("/products/search")
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> searchProducts(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        if (!CompanyContext.hasCompany()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("Firma bilgisi bulunamadı"));
        }

        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createTime").descending());
            Page<ProductResponse> result = productService.searchProducts(keyword, pageable);
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }
}
