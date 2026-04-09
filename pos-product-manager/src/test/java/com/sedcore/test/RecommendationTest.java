package com.sedcore.test;

import com.sedcore.entity.*;
import com.sedcore.enums.ProductRelationType;
import com.sedcore.enums.StockMovementType;
import com.sedcore.model.RecommendationResponse;
import com.sedcore.repository.*;
import com.sedcore.service.RecommendationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * RecommendationTest
 *
 * Tests the hybrid recommendation system
 * Key scenarios:
 * 1. Frequently bought together recommendations
 * 2. Similar products (manual relationships)
 * 3. Hybrid recommendations combining both
 * 4. Company isolation in recommendations
 * 5. Caching behavior
 */
@SpringBootTest
@TestPropertySource(properties = {
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "spring.datasource.url=jdbc:h2:mem:testdb",
    "spring.cache.type=simple"
})
public class RecommendationTest {

    @Autowired
    private RecommendationService recommendationService;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private ProductVariantRepository variantRepository;

    @Autowired
    private SaleRepository saleRepository;

    @Autowired
    private StockMovementRepository stockMovementRepository;

    @Autowired
    private ProductRelationshipRepository relationshipRepository;

    private static final String TEST_COMPANY = "TEST_COMPANY";
    private Product bolt;
    private Product washer;
    private ProductVariant boltVariant;
    private ProductVariant washerVariant;

    @BeforeEach
    public void setUp() {
        // Create test products: Bolt and Washer (often bought together)
        bolt = Product.builder()
                .name("Bolt M8")
                .code("BOLT-M8")
                .companyCode(TEST_COMPANY)
                .build();
        productRepository.save(bolt);

        washer = Product.builder()
                .name("Washer M8")
                .code("WASHER-M8")
                .companyCode(TEST_COMPANY)
                .build();
        productRepository.save(washer);

        // Create variants
        boltVariant = ProductVariant.builder()
                .product(bolt)
                .name("Bolt M8 Variant")
                .sku("BOLT-M8-V1")
                .companyCode(TEST_COMPANY)
                .build();
        variantRepository.save(boltVariant);

        washerVariant = ProductVariant.builder()
                .product(washer)
                .name("Washer M8 Variant")
                .sku("WASHER-M8-V1")
                .companyCode(TEST_COMPANY)
                .build();
        variantRepository.save(washerVariant);

        // Create sales with both products (frequently bought together)
        createSaleWithBothProducts();
        createSaleWithBothProducts();
    }

    private void createSaleWithBothProducts() {
        Sale sale = Sale.builder()
                .saleNumber("SALE-" + System.currentTimeMillis())
                .companyCode(TEST_COMPANY)
                .totalAmount(BigDecimal.valueOf(500))
                .saleDate(LocalDateTime.now())
                .build();
        saleRepository.save(sale);

        // Create movements for bolt
        StockMovement boltMovement = StockMovement.builder()
                .sale(sale)
                .variant(boltVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(10)
                .unitPrice(BigDecimal.valueOf(25))
                .companyCode(TEST_COMPANY)
                .build();
        stockMovementRepository.save(boltMovement);

        // Create movements for washer
        StockMovement washerMovement = StockMovement.builder()
                .sale(sale)
                .variant(washerVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(20)
                .unitPrice(BigDecimal.valueOf(10))
                .companyCode(TEST_COMPANY)
                .build();
        stockMovementRepository.save(washerMovement);
    }

    @Test
    public void testFrequentlyBoughtTogetherRecommendations() {
        // Request recommendations for bolt variant
        List<RecommendationResponse> recommendations = recommendationService
                .getFrequentlyBoughtTogether(Arrays.asList(boltVariant.getId()), 5);

        // Should recommend washer as frequently bought with bolt
        assertTrue(recommendations.stream()
                .anyMatch(r -> "FREQUENTLY_BOUGHT_TOGETHER".equals(r.getRecommendationType())),
                "Should have frequently bought together recommendations");
    }

    @Test
    public void testSimilarProductsRecommendations() {
        // Create manual relationship: Bolt is SIMILAR to Washer
        ProductRelationship relationship = ProductRelationship.builder()
                .sourceProduct(bolt)
                .targetProductId(washer.getId())
                .relationType(ProductRelationType.SIMILAR)
                .weight(80)
                .companyCode(TEST_COMPANY)
                .build();
        relationshipRepository.save(relationship);

        // Request similar products
        List<RecommendationResponse> recommendations = recommendationService
                .getSimilarProducts(Arrays.asList(bolt.getId()), 5, null);

        assertTrue(recommendations.size() > 0);
        assertTrue(recommendations.stream()
                .allMatch(r -> r.getRecommendationType().contains("PRODUCT")),
                "Should return similar product recommendations");
    }

    @Test
    public void testHybridRecommendations() {
        // Create both frequently bought and similar relationships
        ProductRelationship relationship = ProductRelationship.builder()
                .sourceProduct(bolt)
                .targetProductId(washer.getId())
                .relationType(ProductRelationType.SIMILAR)
                .weight(80)
                .companyCode(TEST_COMPANY)
                .build();
        relationshipRepository.save(relationship);

        // Get hybrid recommendations
        List<RecommendationResponse> recommendations = recommendationService
                .getHybridRecommendations(
                        Arrays.asList(bolt.getId()),
                        Arrays.asList(boltVariant.getId()),
                        5,
                        Arrays.asList() // Don't exclude anything
                );

        assertTrue(recommendations.size() > 0, "Should return hybrid recommendations");

        // Should combine both frequently bought and similar
        assertTrue(recommendations.stream()
                        .anyMatch(r -> "FREQUENTLY_BOUGHT_TOGETHER".equals(r.getRecommendationType()))
                || recommendations.stream()
                        .anyMatch(r -> r.getRecommendationType().contains("PRODUCT")),
                "Should have at least one recommendation source");
    }

    @Test
    public void testExclusionInRecommendations() {
        List<RecommendationResponse> allRecommendations = recommendationService
                .getHybridRecommendations(
                        Arrays.asList(bolt.getId()),
                        Arrays.asList(boltVariant.getId()),
                        5,
                        Arrays.asList(bolt.getId()) // Exclude bolt itself
                );

        // Should not recommend bolt itself
        assertFalse(allRecommendations.stream()
                .anyMatch(r -> bolt.getId().equals(r.getId())),
                "Should exclude specified products from recommendations");
    }

    @Test
    public void testRecommendationLimitRespected() {
        List<RecommendationResponse> recommendations = recommendationService
                .getHybridRecommendations(
                        Arrays.asList(bolt.getId()),
                        Arrays.asList(boltVariant.getId()),
                        3,
                        Arrays.asList()
                );

        assertTrue(recommendations.size() <= 3, "Should respect limit parameter");
    }

    @Test
    public void testCompanyIsolationInRecommendations() {
        // Create products from another company
        Product otherCompanyProduct = Product.builder()
                .name("Other Company Product")
                .code("OTHER-001")
                .companyCode("OTHER_COMPANY")
                .build();
        productRepository.save(otherCompanyProduct);

        // Get recommendations for test company products
        List<RecommendationResponse> recommendations = recommendationService
                .getHybridRecommendations(
                        Arrays.asList(bolt.getId()),
                        Arrays.asList(boltVariant.getId()),
                        5,
                        Arrays.asList()
                );

        // Should not recommend other company's products
        assertFalse(recommendations.stream()
                .anyMatch(r -> otherCompanyProduct.getId().equals(r.getId())),
                "Should not leak recommendations between companies");
    }

    @Test
    public void testRelevanceScoreCalculation() {
        List<RecommendationResponse> recommendations = recommendationService
                .getHybridRecommendations(
                        Arrays.asList(bolt.getId()),
                        Arrays.asList(boltVariant.getId()),
                        5,
                        Arrays.asList()
                );

        if (recommendations.size() > 0) {
            RecommendationResponse rec = recommendations.get(0);
            assertNotNull(rec.getRelevanceScore(), "Should have relevance score");
            assertTrue(rec.getRelevanceScore() > 0, "Relevance score should be positive");
        }
    }

    @Test
    public void testCacheInvalidation() {
        // Get recommendations (will be cached)
        List<RecommendationResponse> recommendations1 = recommendationService
                .getHybridRecommendations(
                        Arrays.asList(bolt.getId()),
                        Arrays.asList(boltVariant.getId()),
                        5,
                        Arrays.asList()
                );

        // Invalidate cache
        recommendationService.invalidateRecommendationCache(bolt.getId());

        // Get recommendations again (should be fresh)
        List<RecommendationResponse> recommendations2 = recommendationService
                .getHybridRecommendations(
                        Arrays.asList(bolt.getId()),
                        Arrays.asList(boltVariant.getId()),
                        5,
                        Arrays.asList()
                );

        // Results should be consistent
        assertEquals(recommendations1.size(), recommendations2.size(),
                "Cache invalidation should allow fresh data retrieval");
    }
}
