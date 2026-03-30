package com.sedcore.controller.impl;

import com.sedcore.controller.BrandController;
import com.sedcore.model.BrandRequest;
import com.sedcore.model.BrandResponse;
import com.sedcore.service.BrandService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("/api/brand")
public class BrandControllerImpl implements BrandController {

    private final BrandService brandService;

    // GET /product/api/brand
    @Override
    @GetMapping
    public ResponseEntity<ApiResponse<List<BrandResponse>>> getActiveBrands() {
        try {
            return ResponseEntity.ok(ApiResponse.success("Markalar getirildi", brandService.getActiveBrands()));
        } catch (Exception e) {
            log.error("Markalar getirilirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Markalar getirilemedi: " + e.getMessage()));
        }
    }

    // GET /product/api/brand/all
    @Override
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<BrandResponse>>> getAllBrands() {
        try {
            return ResponseEntity.ok(ApiResponse.success("Tüm markalar getirildi", brandService.getAllBrands()));
        } catch (Exception e) {
            log.error("Tüm markalar getirilirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Markalar getirilemedi: " + e.getMessage()));
        }
    }

    // POST /product/api/brand
    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<BrandResponse>> createBrand(@RequestBody BrandRequest request) {
        try {
            BrandResponse response = brandService.createBrand(request);
            return ResponseEntity.ok(ApiResponse.success("Marka oluşturuldu", response));
        } catch (Exception e) {
            log.error("Marka oluşturulurken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Marka oluşturulamadı: " + e.getMessage()));
        }
    }

    // PUT /product/api/brand/{id}
    @Override
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<BrandResponse>> updateBrand(@PathVariable String id, @RequestBody BrandRequest request) {
        try {
            BrandResponse response = brandService.updateBrand(id, request);
            return ResponseEntity.ok(ApiResponse.success("Marka güncellendi", response));
        } catch (Exception e) {
            log.error("Marka güncellenirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Marka güncellenemedi: " + e.getMessage()));
        }
    }

    // DELETE /product/api/brand/{id}
    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBrand(@PathVariable String id) {
        try {
            brandService.deleteBrand(id);
            return ResponseEntity.ok(ApiResponse.success("Marka silindi", null));
        } catch (Exception e) {
            log.error("Marka silinirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Marka silinemedi: " + e.getMessage()));
        }
    }

    // PATCH /product/api/brand/{id}/toggle-status
    @Override
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<BrandResponse>> toggleStatus(@PathVariable String id) {
        try {
            BrandResponse response = brandService.toggleStatus(id);
            return ResponseEntity.ok(ApiResponse.success("Marka durumu değiştirildi", response));
        } catch (Exception e) {
            log.error("Marka durumu değiştirilirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Durum değiştirilemedi: " + e.getMessage()));
        }
    }
}
