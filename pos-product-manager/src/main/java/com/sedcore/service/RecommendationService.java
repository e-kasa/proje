package com.sedcore.service;

import com.sedcore.enums.ProductRelationType;
import com.sedcore.model.RecommendationResponse;

import java.util.List;
import java.util.Map;

public interface RecommendationService {

    List<RecommendationResponse> getHybridRecommendations(
            List<String> productIds, int limit, List<String> excludeIds);

    List<RecommendationResponse> getFrequentlyBoughtTogether(
            List<String> variantIds, int limit);

    List<RecommendationResponse> getSimilarProducts(
            List<String> productIds, int limit, ProductRelationType relationType);

    List<RecommendationResponse> calculateWeightedScore(
            List<RecommendationResponse> recommendations);

    void invalidateRecommendationCache(String productId);

    void invalidateAllCache();

    Map<String, Object> getRecommendationStats(String productId);

    List<Map<String, Object>> getTopRecommendedProducts(int limit);
}
