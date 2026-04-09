package com.sedcore.controller.impl;

import com.sedcore.controller.CategoryAttributeController;
import com.sedcore.entity.CategoryAttribute;
import com.sedcore.model.CategoryAttributeRequest;
import com.sedcore.model.CategoryAttributeResponse;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.service.CategoryAttributeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/category-attribute")
@RequiredArgsConstructor
@Slf4j
public class CategoryAttributeControllerImpl implements CategoryAttributeController {

    private final CategoryAttributeService categoryAttributeService;

    @Override
    public ResponseEntity<ApiResponse<CategoryAttributeResponse>> createAttribute(
            CategoryAttributeRequest request) {
        try {
            CategoryAttribute result = categoryAttributeService.addAttributeToCategory(
                   // request.getCategoryId(),
                    request.getAttributeKey(),
                    request.getAttributeName(),
                    null, request.getAttributeType()
            );
            return ResponseEntity.ok(ApiResponse.success(
                    "Özellik oluşturuldu",
                    toResponse(result)
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<CategoryAttributeResponse>> updateAttribute(
            String id, CategoryAttributeRequest request) {
        try {
            CategoryAttribute updates = CategoryAttribute.builder()
                    .attributeName(request.getAttributeName())
                    .attributeNameEn(request.getAttributeNameEn())
                    .attributeType(request.getAttributeType())
                    .isRequired(request.getIsRequired())
                    .isFilterable(request.getIsFilterable())
                  //  .isSearchable(request.getIsSearchable())
                   // .isComparable(request.getIsComparable())
                   // .displayOrder(request.getDisplayOrder())
                  //  .unit(request.getUnit())
                   // .options(request.getOptions())
                   // .validationRegex(request.getValidationRegex())
                   // .minValue(request.getMinValue())
                   // .maxValue(request.getMaxValue())
                    .build();

            CategoryAttribute result = categoryAttributeService.updateCategoryAttribute(id, updates);
            return ResponseEntity.ok(ApiResponse.success(
                    "Özellik güncellendi",
                    toResponse(result)
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> deleteAttribute(String id) {
        try {
            categoryAttributeService.deleteCategoryAttribute(id);
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<List<CategoryAttributeResponse>>> getCategoryAttributes(
            String categoryId) {
        try {
            List<CategoryAttribute> attributes = categoryAttributeService
                    .getCategoryAttributes(categoryId);
            List<CategoryAttributeResponse> response = attributes.stream()
                    .map(this::toResponse)
                    .collect(Collectors.toList());
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<List<CategoryAttributeResponse>>> getRequiredAttributes(
            String categoryId) {
        try {
            List<CategoryAttribute> attributes = categoryAttributeService
                    .getRequiredAttributes(categoryId);
            List<CategoryAttributeResponse> response = attributes.stream()
                    .map(this::toResponse)
                    .collect(Collectors.toList());
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    @Override
    public ResponseEntity<ApiResponse<List<CategoryAttributeResponse>>> getFilterableAttributes(
            String categoryId) {
        try {
            List<CategoryAttribute> attributes = categoryAttributeService
                    .getFilterableAttributes(categoryId);
            List<CategoryAttributeResponse> response = attributes.stream()
                    .map(this::toResponse)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success(
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    private CategoryAttributeResponse toResponse(CategoryAttribute entity) {
        return CategoryAttributeResponse.builder()
                .id(entity.getId())
              //  .categoryId(entity.getCategoryId())
                .attributeKey(entity.getAttributeKey())
                .attributeName(entity.getAttributeName())
                .attributeNameEn(entity.getAttributeNameEn())
                .attributeType(entity.getAttributeType())
                .isRequired(entity.getIsRequired())
                .isFilterable(entity.getIsFilterable())
               // .isSearchable(entity.getIsSearchable())
               // .isComparable(entity.getIsComparable())
               // .displayOrder(entity.getDisplayOrder())
              //  .unit(entity.getUnit())
               // .options(entity.getOptions())
               // .validationRegex(entity.getValidationRegex())
              //  .minValue(entity.getMinValue())
               // .maxValue(entity.getMaxValue())
               // .placeholder(entity.getPlaceholder())
              //  .helpText(entity.getHelpText())
                .isActive(entity.getIsActive())
              //  .inheritFromParent(entity.getInheritFromParent())
                .build();
    }
}
