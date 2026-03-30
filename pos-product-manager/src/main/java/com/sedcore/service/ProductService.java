package com.sedcore.service;

import com.sedcore.entity.Product;
import com.sedcore.model.CreateProductRequest;
import com.sedcore.model.ProductResponse;
import com.towpen.base.security.BaseDbService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface ProductService extends BaseDbService<Product> {

    ProductResponse createProduct(@Valid CreateProductRequest request);

    ProductResponse updateProduct(String id, @Valid CreateProductRequest request);

    ProductResponse getProduct(String id);

    Page<ProductResponse> listProducts(Pageable pageable);

    Page<ProductResponse> searchProducts(String keyword, Pageable pageable);

    void deactivateProduct(String id);

    void deleteProduct(String id);
}
