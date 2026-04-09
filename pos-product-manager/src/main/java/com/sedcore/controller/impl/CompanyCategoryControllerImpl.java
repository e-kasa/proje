package com.sedcore.controller.impl;

import com.sedcore.controller.CompanyCategoryController;
import com.sedcore.model.*;
import com.sedcore.service.CompanyCategoryService;
import com.sedcore.se.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;
import org.springframework.web.bind.annotation.PutMapping;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;
import org.springframework.web.bind.annotation.RequestMapping;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;
import org.springframework.web.bind.annotation.RestController;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("/api/company-category")
public class CompanyCategoryControllerImpl implements CompanyCategoryController {

    private final CompanyCategoryService companyCategoryService;

    // GET /product/api/company-category/my-categories
    @Override
    @GetMapping("/my-categories")
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getMyCategories() {
        try {
            List<DtoCategory> categories = companyCategoryService.getMyCategories();
            return ResponseEntity.ok(
                    ApiResponse.success("Firma kategorileri getirildi", categories)
            );
        } catch (Exception e) {
            log.error("Firma kategorileri getirilirken hata: {}", e);
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("Firma kategorileri getirilemedi: " + e)
            );
        }
    }

    // GET /product/api/company-category/list
    @Override
    @GetMapping("/list")
    public ResponseEntity<ApiResponse<List<CompanyCategoryResponse>>> getMyCategoryList() {
        try {
            List<CompanyCategoryResponse> list = companyCategoryService.getMyCategoryList();
            return ResponseEntity.ok(
                    ApiResponse.success("Kategori listesi getirildi", list)
            );
        } catch (Exception e) {
            log.error("Kategori listesi getirilirken hata: {}", e);
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("Kategori listesi getirilemedi: " + e)
            );
        }
    }

    // GET /product/api/company-category/all-with-selection
    @Override
    @GetMapping("/all-with-selection")
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getAllCategoriesWithSelection() {
        try {
            List<DtoCategory> categories = companyCategoryService.getAllCategoriesWithSelection();
            return ResponseEntity.ok(
                    ApiResponse.success("Global kategoriler getirildi", categories)
            );
        } catch (Exception e) {
            log.error("Global kategoriler getirilirken hata: {}", e);
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("Global kategoriler getirilemedi: " + e)
            );
        }
    }

    // POST /product/api/company-category
    @Override
    @PutMapping("/company-category")
    public ResponseEntity<ApiResponse<CompanyCategoryResponse>> addCategory(CompanyCategoryRequest request) {
        try {
            CompanyCategoryResponse response = companyCategoryService.addCategory(request);
            return ResponseEntity.ok(
                    ApiResponse.success("Kategori firmaya eklendi", response)
            );
        } catch (Exception e) {
            log.error("Kategori eklenirken hata: {}", e);
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("Kategori eklenemedi: " + e)
            );
        }
    }

    // DELETE /product/api/company-category/{categoryId}
    @Override
    public ResponseEntity<ApiResponse<Void>> removeCategory(String categoryId) {
        try {
            companyCategoryService.removeCategory(categoryId);
            return ResponseEntity.ok(
                    ApiResponse.success("Kategori firmadan kaldırıldı", null)
            );
        } catch (Exception e) {
            log.error("Kategori kaldırılırken hata: {}", e);
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("Kategori kaldırılamadı: " + e)
            );
        }
    }

    // PUT /product/api/company-category/bulk
    @Override
    @PutMapping("/bulk")
    public ResponseEntity<ApiResponse<List<CompanyCategoryResponse>>> bulkSetCategories(CompanyCategoryBulkRequest request) {
        try {
            List<CompanyCategoryResponse> result = companyCategoryService.bulkSetCategories(request);
            return ResponseEntity.ok(
                    ApiResponse.success(
                            result.size() + " kategori seçimi kaydedildi",
                            result
                    )
            );
        } catch (Exception e) {
            log.error("Toplu kategori güncellenirken hata: {}", e);
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("Kategori seçimi kaydedilemedi: " + e)
            );
        }
    }
}
