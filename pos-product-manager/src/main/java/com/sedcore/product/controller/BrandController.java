package com.sedcore.product.controller;

import com.sedcore.product.model.BrandRequest;
import com.sedcore.product.model.BrandResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

public interface BrandController {

    ResponseEntity<ApiResponse<List<BrandResponse>>> getActiveBrands();

    ResponseEntity<ApiResponse<List<BrandResponse>>> getAllBrands();

    ResponseEntity<ApiResponse<BrandResponse>> createBrand(@RequestBody BrandRequest request);

    ResponseEntity<ApiResponse<BrandResponse>> updateBrand(@PathVariable String id, @RequestBody BrandRequest request);

    ResponseEntity<ApiResponse<Void>> deleteBrand(@PathVariable String id);

    ResponseEntity<ApiResponse<BrandResponse>> toggleStatus(@PathVariable String id);
}
