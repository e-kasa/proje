package com.sedcore.controller;

import com.sedcore.entity.Product;
import com.sedcore.model.product.DtoProduct;
import com.sedcore.model.product.DtoProductUI;

import java.util.List;

public interface ProductController {
    DtoProduct saveProduct(DtoProductUI dtoProductUI);
    List<DtoProduct> findByProductId(String productId);
}
