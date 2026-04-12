package com.sedcore.product.service;

import com.sedcore.product.entity.Product;
import com.sedcore.product.model.BatchCreateRequest;
import com.sedcore.product.model.BatchCreateResponse;
import com.sedcore.product.model.CreateProductRequest;
import com.sedcore.product.model.ProductResponse;
import com.towpen.base.security.BaseDbService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface ProductService extends BaseDbService<Product> {

    ProductResponse createProduct(@Valid CreateProductRequest request);

    /**
     * Toplu ürün girişi — tek Purchase kaydı altında N yeni + M mevcut ürün.
     * Her kalem bağımsız işlenir; bir ürün başarısız olsa diğerleri etkilenmez.
     */
    BatchCreateResponse batchCreateProducts(@Valid BatchCreateRequest request);

    ProductResponse updateProduct(String id, @Valid CreateProductRequest request);

    ProductResponse getProduct(String id);

    Page<ProductResponse> listProducts(Pageable pageable);

    Page<ProductResponse> searchProducts(String keyword, Pageable pageable);

    void activateProduct(String id);

    void deactivateProduct(String id);

    void deleteProduct(String id);
}
