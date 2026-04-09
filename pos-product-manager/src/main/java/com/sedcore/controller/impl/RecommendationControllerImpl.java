package com.sedcore.controller.impl;

import com.sedcore.controller.RecommendationController;
import com.sedcore.entity.ProductRelationship;
import com.sedcore.enums.ProductRelationType;
import com.sedcore.model.ProductRelationshipRequest;
import com.sedcore.model.RecommendationResponse;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.ProductRelationshipService;
import com.sedcore.service.RecommendationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
@Slf4j
@RequestMapping("api/v1/recommendations")
public class RecommendationControllerImpl implements RecommendationController {

    private final RecommendationService recommendationService;

    private final ProductRelationshipService relationshipService;

    /**
     * HYBRID RECOMMENDATIONS - Ana endpoint
     *
     * Kasiyerin sepetine eklediği ürünlere göre akıllı öneriler
     */
    @Override
    public ResponseEntity<?> getHybridRecommendations(
            String productIds,
            String variantIds,
            int limit,
            String excludeIds) {

        try {
            log.info("Hybrid önerileri getiriliyor | Products: {} | Variants: {} | Limit: {}", productIds, variantIds, limit);

            List<String> productIdList = Arrays.stream(productIds.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());

            // variantIds yoksa productIds'i variant olarak da kullan
            List<String> variantIdList = (variantIds != null && !variantIds.isEmpty())
                    ? Arrays.stream(variantIds.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList())
                    : productIdList;

            List<String> excludeIdList = excludeIds != null && !excludeIds.isEmpty()
                    ? Arrays.stream(excludeIds.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList())
                    : List.of();

            List<RecommendationResponse> recommendations =
                    recommendationService.getHybridRecommendations(productIdList, variantIdList, limit, excludeIdList);

            log.info("Hybrid öneriler başarıyla getirildi | Count: {}", recommendations.size());

            return ResponseEntity.ok(
                    ApiResponse.success("Önerilecek ürünler başarıyla getirildi", recommendations)
            );
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * Frequently Bought Together
     */
    @Override
    public ResponseEntity<?> getFrequentlyBoughtTogether(
            String variantIds,
            int limit) {

        try {
            log.info("Frequently bought together getiriliyor | Variants: {}", variantIds);

            List<String> variantIdList = Arrays.stream(variantIds.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());

            List<RecommendationResponse> recommendations =
                    recommendationService.getFrequentlyBoughtTogether(variantIdList, limit);

            return ResponseEntity.ok(
                    ApiResponse.success("Sıkça satılan ürünler getirildi", recommendations)
            );
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * Similar Products
     */
    @Override
    public ResponseEntity<?> getSimilarProducts(
            String productIds,
            ProductRelationType type,
            int limit) {

        try {
            log.info("Benzer ürünler getiriliyor | Products: {} | Type: {}", productIds, type);

            List<String> productIdList = Arrays.stream(productIds.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());

            List<RecommendationResponse> recommendations =
                    recommendationService.getSimilarProducts(productIdList, limit, type);

            return ResponseEntity.ok(
                    ApiResponse.success("Benzer ürünler getirildi", recommendations)
            );
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * ─── ADMIN: Create Relationship ───
     */
    @Override
    public ResponseEntity<?> createRelationship(ProductRelationshipRequest request) {

        try {
            log.info("Yeni ilişki oluşturuluyor | Source: {} | Target: {}",
                    request.getSourceProductId(), request.getTargetProductId());

            ProductRelationship relationship = relationshipService.createRelationship(request);

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("İlişki başarıyla oluşturuldu", relationship));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * ─── ADMIN: Update Relationship ───
     */
    @Override
    public ResponseEntity<?> updateRelationship(String id, ProductRelationshipRequest request) {

        try {
            log.info("İlişki güncelleniyor | ID: {}", id);

            ProductRelationship relationship = relationshipService.updateRelationship(id, request);

            return ResponseEntity.ok(
                    ApiResponse.success("İlişki başarıyla güncellendi", relationship)
            );
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * ─── ADMIN: Delete Relationship ───
     */
    @Override
    public ResponseEntity<?> deleteRelationship(String id) {

        try {
            log.info("İlişki siliniyor | ID: {}", id);

            relationshipService.deactivateRelationship(id);

            return ResponseEntity.ok(
                    ApiResponse.success("İlişki başarıyla silindi", null)
            );
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * ─── ADMIN: Get Relationships ───
     */
    @Override
    public ResponseEntity<?> getRelationships(
            String sourceProductId,
            ProductRelationType type) {

        try {
            log.info("İlişkiler getiriliyor | Source: {} | Type: {}", sourceProductId, type);

            List<ProductRelationship> relationships;

            if (sourceProductId != null && !sourceProductId.isEmpty()) {
                if (type != null) {
                    relationships = relationshipService.getRelationshipsBySourceProductAndType(
                            sourceProductId, type);
                } else {
                    relationships = relationshipService.getRelationshipsBySourceProduct(sourceProductId);
                }
            } else {
                relationships = relationshipService.getRelationshipsBySourceProduct("");
            }

            return ResponseEntity.ok(
                    ApiResponse.success("İlişkiler başarıyla getirildi", relationships)
            );
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * ─── ADMIN: Bulk Import ───
     */
    @Override
    public ResponseEntity<?> bulkImportRelationships(List<ProductRelationshipRequest> requests) {

        try {
            log.info("Toplu ilişki import başlıyor | Count: {}", requests.size());

            List<ProductRelationship> imported = relationshipService.bulkImportRelationships(requests);

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(
                            "Toplu import tamamlandı | İçe aktarılan: " + imported.size(),
                            imported
                    ));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * ─── Cache Management ───
     */
    @Override
    public ResponseEntity<?> clearCache(String productId) {

        try {
            if (productId != null && !productId.isEmpty()) {
                recommendationService.invalidateRecommendationCache(productId);
                log.info("Ürün cache'i temizlendi | Product: {}", productId);
            } else {
                recommendationService.invalidateAllCache();
                log.info("Tüm cache temizlendi");
            }

            return ResponseEntity.ok(
                    ApiResponse.success("Cache başarıyla temizlendi", null)
            );
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * ─── Statistics ───
     */
    @Override
    public ResponseEntity<?> getStats(String productId) {

        try {
            if (productId == null || productId.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("productId parametresi zorunlu"));
            }

            var stats = recommendationService.getRecommendationStats(productId);

            return ResponseEntity.ok(
                    ApiResponse.success("İstatistikler getirildi", stats)
            );
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }}
