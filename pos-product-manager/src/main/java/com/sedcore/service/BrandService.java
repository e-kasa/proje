package com.sedcore.service;

import com.sedcore.entity.Brand;
import com.sedcore.model.BrandRequest;
import com.sedcore.model.BrandResponse;
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
