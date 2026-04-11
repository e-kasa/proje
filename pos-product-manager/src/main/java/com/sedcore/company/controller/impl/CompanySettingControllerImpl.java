package com.sedcore.company.controller.impl;

import com.sedcore.company.service.CompanySettingService;
import com.sedcore.common.util.ExceptionMapper;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("api/v1/company/settings")
@RequiredArgsConstructor
@Slf4j
public class CompanySettingControllerImpl {

    private final CompanySettingService companySettingService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSettings() {
        try {
            return ResponseEntity.ok(ApiResponse.success(companySettingService.getSettings()));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Firma ayarları okuma hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    @PutMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateSettings(@RequestBody Map<String, Object> data) {
        try {
            return ResponseEntity.ok(ApiResponse.success(companySettingService.updateSettings(data)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Firma ayarları güncelleme hatası", e);
            throw ExceptionMapper.map(e);
        }
    }
}
