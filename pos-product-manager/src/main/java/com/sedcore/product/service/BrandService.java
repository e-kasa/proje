package com.sedcore.product.service;

import com.sedcore.product.entity.Brand;
import com.sedcore.product.model.BrandRequest;
import com.sedcore.product.model.BrandResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface BrandService extends BaseDbService<Brand> {

    List<BrandResponse> getActiveBrands();

    List<BrandResponse> getAllBrands();

    BrandResponse createBrand(BrandRequest request);

    BrandResponse updateBrand(String id, BrandRequest request);

    void deleteBrand(String id);

    BrandResponse toggleStatus(String id);
}
