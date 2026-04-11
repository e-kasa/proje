package com.sedcore.catalog.controller.impl;

import com.sedcore.catalog.controller.CompanyCategoryController;
import com.sedcore.catalog.model.DtoCategory;
import com.sedcore.catalog.model.CompanyCategoryRequest;
import com.sedcore.catalog.model.CompanyCategoryResponse;
import com.sedcore.catalog.model.CompanyCategoryBulkRequest;
import com.sedcore.catalog.model.DtoCategoryUI;
import com.sedcore.catalog.service.CompanyCategoryService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.common.util.ExceptionMapper;

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
                    ApiResponse.success("Firma kategorileri getirildi", categories));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/company-category/list
    @Override
    @GetMapping("/list")
    public ResponseEntity<ApiResponse<List<CompanyCategoryResponse>>> getMyCategoryList() {
        try {
            List<CompanyCategoryResponse> list = companyCategoryService.getMyCategoryList();
            return ResponseEntity.ok(
                    ApiResponse.success("Kategori listesi getirildi", list));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/company-category/all-with-selection
    @Override
    @GetMapping("/all-with-selection")
    public ResponseEntity<ApiResponse<List<DtoCategory>>> getAllCategoriesWithSelection() {
        try {
            List<DtoCategory> categories = companyCategoryService.getAllCategoriesWithSelection();
            return ResponseEntity.ok(
                    ApiResponse.success("Global kategoriler getirildi", categories));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // POST /product/api/company-category
    @Override
    @PutMapping("/company-category")
    public ResponseEntity<ApiResponse<CompanyCategoryResponse>> addCategory(CompanyCategoryRequest request) {
        try {
            CompanyCategoryResponse response = companyCategoryService.addCategory(request);
            return ResponseEntity.ok(
                    ApiResponse.success("Kategori firmaya eklendi", response));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }

    // DELETE /product/api/company-category/{categoryId}
    @Override
    public ResponseEntity<ApiResponse<Void>> removeCategory(String categoryId) {
        try {
            companyCategoryService.removeCategory(categoryId);
            return ResponseEntity.ok(
                    ApiResponse.success("Kategori firmadan kaldırıldı", null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
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
                    ));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error", e);
            throw ExceptionMapper.map(e);
        }
    }
}
