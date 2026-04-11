package com.sedcore.product.controller;

import com.sedcore.product.entity.Product;
import com.sedcore.product.model.DtoProduct;
import com.sedcore.product.model.DtoProductUI;

import java.util.List;

public interface ProductController {
    DtoProduct saveProduct(DtoProductUI dtoProductUI);
    List<DtoProduct> findByProductId(String productId);
}
