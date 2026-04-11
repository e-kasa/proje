package com.sedcore.recommendation.controller;

import com.sedcore.common.enums.ProductRelationType;
import com.sedcore.product.model.ProductRelationshipRequest;
import com.sedcore.recommendation.model.RecommendationResponse;
import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Recommendation Controller Interface
 *
 * Hybrid product recommendation system combining:
 * - Frequently bought together (sales history analysis)
 * - Similar products (manual relationships)
 * - Weighted relevance scoring
 * - Multi-tenant data isolation
 * - Redis caching with TTL
 *
 * POS önerme sistemi REST endpoint'leri
 */
@RestController
@RequestMapping("api/v1/recommendations")
@Tag(name = "Recommendations", description = "Product recommendation endpoints")
@SecurityRequirement(name = "Bearer Authentication")
public interface RecommendationController {

    /**
     * HYBRID RECOMMENDATIONS - Main Endpoint
     *
     * Combines frequently bought together and similar products recommendations
     * Scored by weighted relevance (frequency: 40%, recency: 20%, popularity: 10%, manual: 10%)
     *
     * @param productIds Comma-separated product IDs for similar products analysis
     * @param variantIds Comma-separated variant IDs for frequently bought analysis
     * @param limit Number of recommendations to return (default: 6)
     * @param excludeIds Comma-separated IDs to exclude from results (e.g., cart items)
     * @return List of recommended products with scores
     */
    @GetMapping("/hybrid")
    @Operation(
            summary = "Get hybrid product recommendations",
            description = "Returns product recommendations combining frequently bought together and similar products analysis"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Recommendations retrieved successfully",
                    content = @Content(schema = @Schema(implementation = RecommendationResponse.class))),
            @ApiResponse(responseCode = "400", description = "Invalid parameters"),
            @ApiResponse(responseCode = "401", description = "Unauthorized"),
            @ApiResponse(responseCode = "500", description = "Internal server error")
    })
    ResponseEntity<?> getHybridRecommendations(
            @Parameter(description = "Product IDs (comma-separated)")
            @RequestParam String productIds,
            @Parameter(description = "Variant IDs (comma-separated)")
            @RequestParam(required = false) String variantIds,
            @Parameter(description = "Number of recommendations to return")
            @RequestParam(defaultValue = "6") int limit,
            @Parameter(description = "Product IDs to exclude (comma-separated)")
            @RequestParam(required = false) String excludeIds);

    /**
     * Frequently Bought Together Recommendations
     *
     * Analyzes sales history to find products frequently purchased together
     * Based on variant IDs from the shopping cart
     */
    @GetMapping("/frequently-bought")
    @Operation(
            summary = "Get frequently bought together recommendations",
            description = "Returns products frequently purchased together based on sales history"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Recommendations retrieved successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid parameters"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    ResponseEntity<?> getFrequentlyBoughtTogether(
            @Parameter(description = "Variant IDs to analyze (comma-separated)")
            @RequestParam String variantIds,
            @Parameter(description = "Maximum number of recommendations")
            @RequestParam(defaultValue = "4") int limit);

    /**
     * Similar Products Recommendations
     *
     * Returns manually defined product relationships (SIMILAR, COMPATIBLE, etc.)
     * Based on product catalog relationships
     */
    @GetMapping("/similar")
    @Operation(
            summary = "Get similar product recommendations",
            description = "Returns products with manual relationships (similar, compatible, accessories, etc.)"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Similar products retrieved successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid product IDs")
    })
    ResponseEntity<?> getSimilarProducts(
            @Parameter(description = "Product IDs to find similar products for (comma-separated)")
            @RequestParam String productIds,
            @Parameter(description = "Filter by relationship type (SIMILAR, COMPATIBLE, ACCESSORY)")
            @RequestParam(required = false) ProductRelationType type,
            @Parameter(description = "Maximum number of results")
            @RequestParam(defaultValue = "4") int limit);

    /**
     * ─── ADMIN: RELATIONSHIP MANAGEMENT ───
     */

    /**
     * Create New Product Relationship
     *
     * Defines manual product relationships (SIMILAR, COMPATIBLE, ACCESSORY, etc.)
     */
    @PostMapping("/relationships")
    @Operation(
            summary = "Create product relationship",
            description = "Creates a new relationship between two products for recommendations"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Relationship created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid request body"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    ResponseEntity<?> createRelationship(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Product relationship details",
                    required = true
            )
            @RequestBody ProductRelationshipRequest request);

    /**
     * Update Product Relationship
     *
     * Modifies an existing product relationship
     */
    @PutMapping("/relationships/{id}")
    @Operation(summary = "Update product relationship")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Relationship updated successfully"),
            @ApiResponse(responseCode = "404", description = "Relationship not found"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    ResponseEntity<?> updateRelationship(
            @Parameter(description = "Relationship ID")
            @PathVariable String id,
            @RequestBody ProductRelationshipRequest request);

    /**
     * Delete Product Relationship
     *
     * Removes a product relationship
     */
    @DeleteMapping("/relationships/{id}")
    @Operation(summary = "Delete product relationship")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Relationship deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Relationship not found"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    ResponseEntity<?> deleteRelationship(
            @Parameter(description = "Relationship ID")
            @PathVariable String id);

    /**
     * Get All Product Relationships
     *
     * Retrieves relationships for a specific product or all relationships
     */
    @GetMapping("/relationships")
    @Operation(summary = "Get product relationships")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Relationships retrieved successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    ResponseEntity<?> getRelationships(
            @Parameter(description = "Source product ID to filter by")
            @RequestParam(required = false) String sourceProductId,
            @Parameter(description = "Relationship type filter")
            @RequestParam(required = false) ProductRelationType type);

    /**
     * Bulk Import Relationships
     *
     * Creates multiple product relationships in one operation
     * Useful for initial data load or bulk updates
     */
    @PostMapping("/relationships/bulk-import")
    @Operation(
            summary = "Bulk import product relationships",
            description = "Creates multiple relationships in a single request"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Relationships imported successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid relationships in request"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    ResponseEntity<?> bulkImportRelationships(
            @RequestBody List<ProductRelationshipRequest> requests);

    /**
     * Clear Recommendation Cache
     *
     * Invalidates cached recommendations (Redis TTL: 30 minutes)
     * Can clear all or specific product recommendations
     */
    @PostMapping("/cache/clear")
    @Operation(
            summary = "Clear recommendation cache",
            description = "Invalidates Redis cache for recommendations"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Cache cleared successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    ResponseEntity<?> clearCache(
            @Parameter(description = "Optional: specific product ID to clear")
            @RequestParam(required = false) String productId);

    /**
     * Get Recommendation Statistics
     *
     * Retrieves analytics about recommendation system performance
     */
    @GetMapping("/stats")
    @Operation(
            summary = "Get recommendation statistics",
            description = "Returns metrics about recommendation system usage and effectiveness"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Statistics retrieved successfully"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    ResponseEntity<?> getStats(
            @Parameter(description = "Optional: specific product ID to get stats for")
            @RequestParam(required = false) String productId);
}
