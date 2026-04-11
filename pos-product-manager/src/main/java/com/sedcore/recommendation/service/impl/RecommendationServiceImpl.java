package com.sedcore.recommendation.service.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.enums.ProductRelationType;
import com.sedcore.inventory.entity.InventoryView;
import com.sedcore.product.entity.ProductRelationship;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.product.entity.VariantPricing;
import com.sedcore.recommendation.model.RecommendationResponse;
import com.sedcore.autoparts.repository.CrossReferenceRepository;
import com.sedcore.inventory.repository.InventoryRepository;
import com.sedcore.product.repository.ProductVariantRepository;
import com.sedcore.inventory.repository.StockMovementRepository;
import com.sedcore.product.service.ProductRelationshipService;
import com.sedcore.recommendation.service.RecommendationService;
import lombok.RequiredArgsConstructor;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import org.springframework.data.domain.PageRequest;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class RecommendationServiceImpl implements RecommendationService {

    private final ProductRelationshipService relationshipService;
    private final StockMovementRepository stockMovementRepository;
    private final CrossReferenceRepository crossReferenceRepository;
    private final ProductVariantRepository productVariantRepository;
    private final InventoryRepository inventoryRepository;

    @Override
    @Cacheable(value = "recommendations", key = "#productIds.stream().sorted().collect(T(java.util.stream.Collectors).joining(','))")
    public List<RecommendationResponse> getHybridRecommendations(
            List<String> productIds, List<String> variantIds, int limit, List<String> excludeIds) {

        try {
            log.info("Hybrid recommendations hesaplaniyor | Products: {} | Variants: {} | Exclude: {}", productIds, variantIds, excludeIds);

            // variantIds boş/null ise productIds'i kullan (sisteminiz her ürünü varyant olarak kabul ediyor)
            List<String> effectiveVariantIds = variantIds;
            if (effectiveVariantIds == null || effectiveVariantIds.isEmpty()) {
                effectiveVariantIds = productIds;
                log.info("variantIds boş, productIds kullanılıyor: {}", productIds);
            }

            List<RecommendationResponse> allRecommendations = new ArrayList<>();

            // Frequently bought together → variant ID'lerini kullanır (satış hareketi bazlı)
            List<RecommendationResponse> frequentlyBought = getFrequentlyBoughtTogether(effectiveVariantIds, limit * 2);
            allRecommendations.addAll(frequentlyBought);

            // Similar products → product ID'lerini kullanır (ilişki bazlı)
            List<RecommendationResponse> similarProducts = getSimilarProducts(productIds, limit * 2, null);
            allRecommendations.addAll(similarProducts);

            // Cross-referenced products → aynı OEM/parça numarasına sahip alternatif ürünler
            List<RecommendationResponse> crossRefProducts = getCrossReferencedProducts(effectiveVariantIds, limit * 2);
            allRecommendations.addAll(crossRefProducts);

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

            List<RecommendationResponse> result = scored.stream().limit(limit).collect(Collectors.toList());

            // Fiyat, stok ve kâr bilgilerini zenginleştir
            enrichRecommendations(result);

            return result;

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

            String companyCode = CompanyContext.get();
            if (companyCode == null || companyCode.isBlank()) companyCode = "SYSTEM";

            List<Object[]> results = stockMovementRepository.findFrequentlyBoughtTogether(variantIds, companyCode, PageRequest.of(0, limit));

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
                        .flatMap(pid -> {
                            List<ProductRelationship> rels = relationshipService
                                    .getRelationshipsBySourceProductAndType(pid, relationType);
                            log.info("getSimilarProducts | pid={} | type={} | found={}", pid, relationType, rels.size());
                            return rels.stream();
                        })
                        .collect(Collectors.toList());
            } else {
                relationships = productIds.stream()
                        .flatMap(pid -> {
                            List<ProductRelationship> rels = relationshipService
                                    .getRelationshipsBySourceProduct(pid);
                            log.info("getSimilarProducts | pid={} | found={}", pid, rels.size());
                            return rels.stream();
                        })
                        .collect(Collectors.toList());
            }

            log.info("Total similar products relationships found: {}", relationships.size());

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
    public List<RecommendationResponse> getCrossReferencedProducts(
            List<String> variantIds, int limit) {

        try {
            if (variantIds == null || variantIds.isEmpty()) {
                return Collections.emptyList();
            }

            log.info("Cross-reference oneriler hesaplaniyor | Variants: {}", variantIds);

            String companyCode = CompanyContext.get();
            if (companyCode == null || companyCode.isBlank()) companyCode = "SYSTEM";

            List<Object[]> results = crossReferenceRepository.findCrossReferencedProducts(
                    variantIds, companyCode);

            log.info("Cross-reference eslesme sayisi: {}", results.size());

            return results.stream()
                    .limit(limit)
                    .map(row -> {
                        String crossRefBrand = row[4] != null ? (String) row[4] : "";
                        String crossRefNumber = row[5] != null ? (String) row[5] : "";
                        int matchCount = row[6] != null ? ((Number) row[6]).intValue() : 1;

                        String reason = "Capraz referans: " + crossRefNumber;
                        if (!crossRefBrand.isEmpty()) {
                            reason += " (" + crossRefBrand + ")";
                        }

                        return RecommendationResponse.builder()
                                .id((String) row[0])
                                .name((String) row[1])
                                .sku((String) row[2])
                                .recommendationType("CROSS_REFERENCE")
                                .reason(reason)
                                .relevanceScore(8 + matchCount)  // OEM eşleşmesi yüksek güvenilirlik
                                .build();
                    })
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Cross-reference oneriler hesaplanirken hata", e);
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

    /**
     * Önerileri fiyat, maliyet, stok ve kâr bilgileriyle zenginleştirir.
     * VariantPricing'den purchasePrice (maliyet) ve salePrice (satış fiyatı),
     * InventoryView'dan stok miktarı alınır.
     */
    private void enrichRecommendations(List<RecommendationResponse> recommendations) {
        for (RecommendationResponse rec : recommendations) {
            try {
                // ID, frequently_bought/cross-ref'te variantId, similar products'ta productId olabilir
                // Önce doğrudan variant olarak ara
                ProductVariant variant = null;
                var variantOpt = productVariantRepository.findById(rec.getId());
                if (variantOpt.isPresent()) {
                    variant = variantOpt.get();
                } else {
                    // Bulunamadıysa productId olarak kabul et — ilk aktif varyantı al
                    List<ProductVariant> variants = productVariantRepository
                            .findByProductIdAndIsDeleted(rec.getId(), false);
                    if (!variants.isEmpty()) {
                        variant = variants.get(0);
                        // rec.id'yi variantId ile güncelle (sepete ekleme için gerekli)
                        rec.setId(variant.getId());
                    }
                }

                if (variant != null) {
                    // Ürün adı (variant adı boşsa product adından al)
                    if (rec.getName() == null || rec.getName().isBlank()) {
                        if (variant.getProduct() != null) {
                            rec.setName(variant.getProduct().getName());
                        }
                    }
                    // SKU
                    if (rec.getSku() == null || rec.getSku().isBlank()) {
                        rec.setSku(variant.getSku());
                    }
                    // Fiyat: VariantPricing'den
                    List<VariantPricing> pricings = variant.getVariantPricings();
                    if (pricings != null && !pricings.isEmpty()) {
                        VariantPricing pricing = pricings.get(0);
                        if (pricing.getSalePrice() != null) {
                            rec.setBasePrice(pricing.getSalePrice().doubleValue());
                        }
                        if (pricing.getPurchasePrice() != null) {
                            rec.setCostPrice(pricing.getPurchasePrice().doubleValue());
                        }
                    }
                    // Stok: InventoryView'dan tüm lokasyonların toplamı
                    List<InventoryView> invList = inventoryRepository.findByVariantId(variant.getId());
                    int totalStock = invList.stream()
                            .mapToInt(iv -> iv.getPhysicalQuantity() != null ? iv.getPhysicalQuantity() : 0)
                            .sum();
                    rec.setStock(totalStock);
                    rec.setStockStatus(totalStock <= 0 ? "OUT_OF_STOCK" : totalStock <= 5 ? "LOW_STOCK" : "IN_STOCK");
                    // Barkod (sepete hızlı ekleme)
                    if (variant.getBarcodes() != null && !variant.getBarcodes().isEmpty()) {
                        rec.setBarcode(variant.getBarcodes().get(0).getBarcodeCode());
                    }
                }
            } catch (Exception e) {
                log.warn("Recommendation enrichment hatasi id={}: {}", rec.getId(), e.getMessage());
            }
        }
    }
}
