package com.sedcore.controller.impl;

import com.sedcore.controller.OemNumberController;
import com.sedcore.model.OemNumberRequest;
import com.sedcore.model.OemNumberResponse;
import com.sedcore.service.OemNumberService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("/api/oem-number")
public class OemNumberControllerImpl implements OemNumberController {

    private final OemNumberService oemNumberService;

    @Override
    @GetMapping("/variant/{variantId}")
    public ResponseEntity<ApiResponse<List<OemNumberResponse>>> getByVariantId(@PathVariable String variantId) {
        try {
            return ResponseEntity.ok(ApiResponse.success("OEM numaralari getirildi", oemNumberService.getByVariantId(variantId)));
        } catch (Exception e) {
            log.error("OEM numaralari getirilirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("OEM numaralari getirilemedi: " + e.getMessage()));
        }
    }

    @Override
    @PostMapping
    public ResponseEntity<ApiResponse<OemNumberResponse>> createOemNumber(@RequestBody OemNumberRequest request) {
        try {
            OemNumberResponse response = oemNumberService.createOemNumber(request);
            return ResponseEntity.ok(ApiResponse.success("OEM numarasi eklendi", response));
        } catch (Exception e) {
            log.error("OEM numarasi eklenirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("OEM numarasi eklenemedi: " + e.getMessage()));
        }
    }

    @Override
    @PostMapping("/bulk/{variantId}")
    public ResponseEntity<ApiResponse<List<OemNumberResponse>>> bulkCreate(
            @PathVariable String variantId, @RequestBody List<OemNumberRequest> requests) {
        try {
            List<OemNumberResponse> responses = oemNumberService.bulkCreate(variantId, requests);
            return ResponseEntity.ok(ApiResponse.success("OEM numaralari toplu eklendi", responses));
        } catch (Exception e) {
            log.error("OEM numaralari toplu eklenirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Toplu ekleme basarisiz: " + e.getMessage()));
        }
    }

    @Override
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteOemNumber(@PathVariable String id) {
        try {
            oemNumberService.deleteOemNumber(id);
            return ResponseEntity.ok(ApiResponse.success("OEM numarasi silindi", null));
        } catch (Exception e) {
            log.error("OEM numarasi silinirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("OEM numarasi silinemedi: " + e.getMessage()));
        }
    }

    @Override
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<OemNumberResponse>>> searchByOemNumber(@RequestParam String q) {
        try {
            return ResponseEntity.ok(ApiResponse.success("Arama sonuclari", oemNumberService.searchByOemNumber(q)));
        } catch (Exception e) {
            log.error("OEM aranirken hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Arama yapilamadi: " + e.getMessage()));
        }
    }
}
