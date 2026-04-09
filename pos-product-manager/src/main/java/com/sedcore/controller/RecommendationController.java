package com.sedcore.controller;

import com.sedcore.enums.ProductRelationType;
import com.sedcore.model.ProductRelationshipRequest;
import com.sedcore.model.RecommendationResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Recommendation Controller Interface
 *
 * POS önerme sistemi REST endpoint'leri
 */
@RestController
@RequestMapping("api/v1/recommendations")
public interface RecommendationController {

    /**
     * HYBRID RECOMMENDATIONS - Ana endpoint
     *
     * GET /api/v1/recommendations/hybrid?productIds=123,456&limit=6&excludeIds=789
     *
     * @param productIds Sepetteki ürün ID'leri (comma-separated)
     * @param limit Kaç ürün (default: 6)
     * @param excludeIds Gösterilmeyecek ürün ID'leri (sepet ürünleri)
     * @return Önerilecek ürünler
     */
    @GetMapping("/hybrid")
    ResponseEntity<?> getHybridRecommendations(
            @RequestParam String productIds,
            @RequestParam(defaultValue = "6") int limit,
            @RequestParam(required = false) String excludeIds);

    /**
     * Satış verisi tabanlı öneriler
     *
     * GET /api/v1/recommendations/frequently-bought?variantIds=123,456&limit=4
     */
    @GetMapping("/frequently-bought")
    ResponseEntity<?> getFrequentlyBoughtTogether(
            @RequestParam String variantIds,
            @RequestParam(defaultValue = "4") int limit);

    /**
     * Manuel ilişkilere dayalı öneriler
     *
     * GET /api/v1/recommendations/similar?productIds=123&type=SIMILAR&limit=4
     */
    @GetMapping("/similar")
    ResponseEntity<?> getSimilarProducts(
            @RequestParam String productIds,
            @RequestParam(required = false) ProductRelationType type,
            @RequestParam(defaultValue = "4") int limit);

    /**
     * ─── ADMIN: RELATIONSHIP YÖNETIMI ───
     */

    /**
     * Yeni ilişki oluştur
     *
     * POST /api/v1/recommendations/relationships
     */
    @PostMapping("/relationships")
    ResponseEntity<?> createRelationship(
            @RequestBody ProductRelationshipRequest request);

    /**
     * İlişkiyi güncelle
     *
     * PUT /api/v1/recommendations/relationships/{id}
     */
    @PutMapping("/relationships/{id}")
    ResponseEntity<?> updateRelationship(
            @PathVariable String id,
            @RequestBody ProductRelationshipRequest request);

    /**
     * İlişkiyi sil
     *
     * DELETE /api/v1/recommendations/relationships/{id}
     */
    @DeleteMapping("/relationships/{id}")
    ResponseEntity<?> deleteRelationship(@PathVariable String id);

    /**
     * Ürüne ait tüm ilişkileri getir
     *
     * GET /api/v1/recommendations/relationships?sourceProductId=123
     */
    @GetMapping("/relationships")
    ResponseEntity<?> getRelationships(
            @RequestParam(required = false) String sourceProductId,
            @RequestParam(required = false) ProductRelationType type);

    /**
     * Toplu ilişki ekleme
     *
     * POST /api/v1/recommendations/relationships/bulk-import
     */
    @PostMapping("/relationships/bulk-import")
    ResponseEntity<?> bulkImportRelationships(
            @RequestBody List<ProductRelationshipRequest> requests);

    /**
     * Cache temizle
     *
     * POST /api/v1/recommendations/cache/clear
     */
    @PostMapping("/cache/clear")
    ResponseEntity<?> clearCache(
            @RequestParam(required = false) String productId);

    /**
     * İstatistikler
     *
     * GET /api/v1/recommendations/stats?productId=123
     */
    @GetMapping("/stats")
    ResponseEntity<?> getStats(
            @RequestParam(required = false) String productId);
}
