package com.sedcore.common.config;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.context.annotation.Configuration;

/**
 * Metrics Configuration for POS Product Manager
 *
 * Defines custom metrics for monitoring:
 * - Sales operations (creation, returns, cancellations)
 * - Stock movements (sales out, purchases, transfers, adjustments)
 * - Product recommendations (hits, cache effectiveness)
 * - API endpoint performance
 *
 * Metrics exposed at: /actuator/prometheus
 * Prometheus scrape config example:
 * {
 *   "job_name": "pos-product-manager",
 *   "static_configs": [{"targets": ["localhost:8080"]}],
 *   "metrics_path": "/actuator/prometheus"
 * }
 */
@Configuration
public class MetricsConfiguration {

    // ====================================================================
    // SALES METRICS
    // ====================================================================

    public static final String SALES_CREATED = "sales.created.total";
    public static final String SALES_RETURNED = "sales.returned.total";
    public static final String SALES_CANCELLED = "sales.cancelled.total";
    public static final String SALES_AMOUNT_TOTAL = "sales.amount.total";
    public static final String SALES_PROCESSING_TIME = "sales.processing.seconds";

    // ====================================================================
    // STOCK MOVEMENT METRICS
    // ====================================================================

    public static final String MOVEMENTS_CREATED = "movements.created.total";
    public static final String MOVEMENTS_SALE_OUT = "movements.sale_out.total";
    public static final String MOVEMENTS_PURCHASE_IN = "movements.purchase_in.total";
    public static final String MOVEMENTS_ADJUSTMENT = "movements.adjustment.total";
    public static final String MOVEMENTS_PROCESSING_TIME = "movements.processing.seconds";

    // ====================================================================
    // RECOMMENDATION METRICS
    // ====================================================================

    public static final String RECOMMENDATIONS_REQUESTED = "recommendations.requested.total";
    public static final String RECOMMENDATIONS_CACHE_HIT = "recommendations.cache.hits.total";
    public static final String RECOMMENDATIONS_CACHE_MISS = "recommendations.cache.misses.total";
    public static final String RECOMMENDATIONS_RESPONSE_TIME = "recommendations.response.seconds";

    // ====================================================================
    // PRODUCT METRICS
    // ====================================================================

    public static final String PRODUCTS_TOTAL = "products.total";
    public static final String VARIANTS_TOTAL = "variants.total";

    /**
     * Register custom metrics with MeterRegistry
     */
    public MetricsConfiguration(MeterRegistry meterRegistry) {
        // Sales counters
        Counter.builder(SALES_CREATED)
                .description("Total number of sales created")
                .register(meterRegistry);

        Counter.builder(SALES_RETURNED)
                .description("Total number of sales with returns")
                .register(meterRegistry);

        Counter.builder(SALES_CANCELLED)
                .description("Total number of cancelled sales")
                .register(meterRegistry);

        // Stock movement counters
        Counter.builder(MOVEMENTS_CREATED)
                .description("Total stock movements created")
                .register(meterRegistry);

        Counter.builder(MOVEMENTS_SALE_OUT)
                .description("Total SALE_OUT movements")
                .register(meterRegistry);

        Counter.builder(MOVEMENTS_PURCHASE_IN)
                .description("Total PURCHASE_IN movements")
                .register(meterRegistry);

        Counter.builder(MOVEMENTS_ADJUSTMENT)
                .description("Total stock adjustments")
                .register(meterRegistry);

        // Recommendation metrics
        Counter.builder(RECOMMENDATIONS_REQUESTED)
                .description("Total recommendation requests")
                .register(meterRegistry);

        Counter.builder(RECOMMENDATIONS_CACHE_HIT)
                .description("Recommendation cache hits")
                .register(meterRegistry);

        Counter.builder(RECOMMENDATIONS_CACHE_MISS)
                .description("Recommendation cache misses")
                .register(meterRegistry);

        // Gauges and timers are registered via @Timed annotation
    }
}
