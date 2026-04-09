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
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;

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
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Markalar getirilirken hata", e);
            throw new TOpenException(new TOpenMessage(TMessageType.BRAND_LIST_ERROR_1300));
        }
    }

    // GET /product/api/brand/all
    @Override
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<BrandResponse>>> getAllBrands() {
        try {
            return ResponseEntity.ok(ApiResponse.success("Tüm markalar getirildi", brandService.getAllBrands()));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Tüm markalar getirilirken hata", e);
            throw new TOpenException(new TOpenMessage(TMessageType.BRAND_LIST_ERROR_1300));
        }
    }

    // POST /product/api/brand
    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<BrandResponse>> createBrand(@RequestBody BrandRequest request) {
        try {
            BrandResponse response = brandService.createBrand(request);
            return ResponseEntity.ok(ApiResponse.success("Marka oluşturuldu", response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Marka oluşturulurken hata", e);
            throw new TOpenException(new TOpenMessage(TMessageType.BRAND_CREATE_ERROR_1301));
        }
    }

    // PUT /product/api/brand/{id}
    @Override
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<BrandResponse>> updateBrand(@PathVariable String id, @RequestBody BrandRequest request) {
        try {
            BrandResponse response = brandService.updateBrand(id, request);
            return ResponseEntity.ok(ApiResponse.success("Marka güncellendi", response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Marka güncellenirken hata", e);
            throw new TOpenException(new TOpenMessage(TMessageType.BRAND_UPDATE_ERROR_1302));
        }
    }

    // DELETE /product/api/brand/{id}
    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBrand(@PathVariable String id) {
        try {
            brandService.deleteBrand(id);
            return ResponseEntity.ok(ApiResponse.success("Marka silindi", null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Marka silinirken hata", e);
            throw new TOpenException(new TOpenMessage(TMessageType.BRAND_DELETE_ERROR_1303));
        }
    }

    // PATCH /product/api/brand/{id}/toggle-status
    @Override
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<BrandResponse>> toggleStatus(@PathVariable String id) {
        try {
            BrandResponse response = brandService.toggleStatus(id);
            return ResponseEntity.ok(ApiResponse.success("Marka durumu değiştirildi", response));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Marka durumu değiştirilirken hata", e);
            throw new TOpenException(new TOpenMessage(TMessageType.BRAND_UPDATE_ERROR_1302));
        }
    }
}
