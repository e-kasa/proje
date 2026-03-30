package com.sedcore.controller.impl;

import com.sedcore.controller.UnitController;
import com.sedcore.model.UnitRequest;
import com.sedcore.model.UnitResponse;
import com.sedcore.service.UnitService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("/api/unit")
public class UnitControllerImpl implements UnitController {

    private final UnitService unitService;

    // GET /product/api/unit
    @Override
    @GetMapping
    public ResponseEntity<ApiResponse<List<UnitResponse>>> getActiveUnits() {
        try {
            return ResponseEntity.ok(ApiResponse.success("Birimler getirildi", unitService.getActiveUnits()));
        } catch (Exception e) {
            log.error("Birimler getirilirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Birimler getirilemedi: " + e.getMessage()));
        }
    }

    // GET /product/api/unit/all
    @Override
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<UnitResponse>>> getAllUnits() {
        try {
            return ResponseEntity.ok(ApiResponse.success("Tüm birimler getirildi", unitService.getAllUnits()));
        } catch (Exception e) {
            log.error("Tüm birimler getirilirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Birimler getirilemedi: " + e.getMessage()));
        }
    }

    // POST /product/api/unit
    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<UnitResponse>> createUnit(@RequestBody UnitRequest request) {
        try {
            UnitResponse response = unitService.createUnit(request);
            return ResponseEntity.ok(ApiResponse.success("Birim oluşturuldu", response));
        } catch (Exception e) {
            log.error("Birim oluşturulurken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Birim oluşturulamadı: " + e.getMessage()));
        }
    }

    // PUT /product/api/unit/{id}
    @Override
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UnitResponse>> updateUnit(@PathVariable String id, @RequestBody UnitRequest request) {
        try {
            UnitResponse response = unitService.updateUnit(id, request);
            return ResponseEntity.ok(ApiResponse.success("Birim güncellendi", response));
        } catch (Exception e) {
            log.error("Birim güncellenirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Birim güncellenemedi: " + e.getMessage()));
        }
    }

    // DELETE /product/api/unit/{id}
    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteUnit(@PathVariable String id) {
        try {
            unitService.deleteUnit(id);
            return ResponseEntity.ok(ApiResponse.success("Birim silindi", null));
        } catch (Exception e) {
            log.error("Birim silinirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Birim silinemedi: " + e.getMessage()));
        }
    }

    // PATCH /product/api/unit/{id}/toggle-status
    @Override
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<UnitResponse>> toggleStatus(@PathVariable String id) {
        try {
            UnitResponse response = unitService.toggleStatus(id);
            return ResponseEntity.ok(ApiResponse.success("Birim durumu değiştirildi", response));
        } catch (Exception e) {
            log.error("Birim durumu değiştirilirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Durum değiştirilemedi: " + e.getMessage()));
        }
    }
}
