package com.sedcore.service.impl;

import com.sedcore.enums.ProductRelationType;
import com.sedcore.entity.ProductRelationship;
import com.sedcore.model.RecommendationResponse;
import com.sedcore.repository.StockMovementRepository;
import com.sedcore.service.ProductRelationshipService;
import com.sedcore.service.RecommendationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(propagation = Propagation.REQUIRED)
@Slf4j
@RequiredArgsConstructor
public class RecommendationServiceImpl implements RecommendationService {

    private final ProductRelationshipService relationshipService;

    private final StockMovementRepository stockMovementRepository;

    @Override
    @Cacheable(value = "recommendations", key = "#productIds.stream().sorted().collect(T(java.util.stream.Collectors).joining(','))")
    public List<RecommendationResponse> getHybridRecommendations(
            List<String> productIds, int limit, List<String> excludeIds) {

        try {
            log.info("Hybrid recommendations hesaplaniyor | Products: {} | Exclude: {}", productIds, excludeIds);

            List<RecommendationResponse> allRecommendations = new ArrayList<>();

            List<RecommendationResponse> frequentlyBought = getFrequentlyBoughtTogether(productIds, limit * 2);
            allRecommendations.addAll(frequentlyBought);

            List<RecommendationResponse> similarProducts = getSimilarProducts(productIds, limit * 2, null);
            allRecommendations.addAll(similarProducts);

            Map<String, RecommendationResponse> deduped = new LinkedHashMap<>();
            for (RecommendationResponse rec : allRecommendations) {
                if (deduped.containsKey(rec.getId())) {
                    RecommendationResponse existing = deduped.get(rec.getId());
                    existing.setRelevanceScore(existing.getRelevanceScore() + rec.getRelevanceScore());
                } else {
                    deduped.put(rec.getId(), rec);
                }
            }

            List<RecommendationResponse> filtered = deduped.values().stream()
                    .filter(r -> !excludeIds.contains(r.getId()))
                    .collect(Collectors.toList());

            List<RecommendationResponse> scored = calculateWeightedScore(filtered);

            return scored.stream().limit(limit).collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Hybrid recommendations hesaplanirken hata", e);
            return Collections.emptyList();
        }
    }

    @Override
    public List<RecommendationResponse> getFrequentlyBoughtTogether(
            List<String> variantIds, int limit) {

        try {
            log.info("Frequently bought together analiz ediliyor | Variants: {}", variantIds);

            List<Object[]> results = stockMovementRepository.findFrequentlyBoughtTogether(variantIds, limit);

            return results.stream()
                    .map(row -> RecommendationResponse.builder()
                            .id((String) row[0])
                            .name((String) row[1])
                            .sku((String) row[2])
                            .recommendationType("FREQUENTLY_BOUGHT_TOGETHER")
                            .reason("Sikca birlikte satilir")
                            .relevanceScore(((Number) row[4]).intValue())
                            .build())
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Frequently bought together hesaplanirken hata", e);
            return Collections.emptyList();
        }
    }

    @Override
    public List<RecommendationResponse> getSimilarProducts(
            List<String> productIds, int limit, ProductRelationType relationType) {

        try {
            log.info("Similar products getiriliyor | Products: {} | Type: {}", productIds, relationType);

            List<ProductRelationship> relationships;

            if (relationType != null) {
                relationships = productIds.stream()
                        .flatMap(pid -> relationshipService
                                .getRelationshipsBySourceProductAndType(pid, relationType).stream())
                        .collect(Collectors.toList());
            } else {
                relationships = productIds.stream()
                        .flatMap(pid -> relationshipService
                                .getRelationshipsBySourceProduct(pid).stream())
                        .collect(Collectors.toList());
            }

            return relationships.stream()
                    .limit(limit)
                    .map(rel -> RecommendationResponse.builder()
                            .id(rel.getTargetProductId())
                            .recommendationType(rel.getRelationType().name() + "_PRODUCT")
                            .reason(rel.getRelationType().getDescription())
                            .relevanceScore(rel.getWeight())
                            .build())
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Similar products getirme hatasi", e);
            return Collections.emptyList();
        }
    }

    @Override
    public List<RecommendationResponse> calculateWeightedScore(
            List<RecommendationResponse> recommendations) {

        recommendations.forEach(rec -> {
            int frequencyScore = (rec.getRelevanceScore() != null ? rec.getRelevanceScore() : 0) * 40 / 100;
            int recencyScore = 20;
            int manualWeight = 10;
            int popularityScore = 10;

            int finalScore = frequencyScore + recencyScore + manualWeight + popularityScore;
            rec.setRelevanceScore(finalScore);
        });

        return recommendations.stream()
                .sorted((a, b) -> b.getRelevanceScore().compareTo(a.getRelevanceScore()))
                .collect(Collectors.toList());
    }

    @Override
    @CacheEvict(value = "recommendations", key = "#productId")
    public void invalidateRecommendationCache(String productId) {
        log.info("Cache temizlendi | Product: {}", productId);
    }

    @Override
    @CacheEvict(value = "recommendations", allEntries = true)
    public void invalidateAllCache() {
        log.info("Tum onerme cache'i temizlendi");
    }

    @Override
    public Map<String, Object> getRecommendationStats(String productId) {
        return new HashMap<>();
    }

    @Override
    public List<Map<String, Object>> getTopRecommendedProducts(int limit) {
        return Collections.emptyList();
    }
}
