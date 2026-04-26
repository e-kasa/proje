---
title: Integration — Prometheus + Micrometer
type: synthesis
source: .claude/wiki/integrations/prometheus-micrometer.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Prometheus + Micrometer

## Genel

Spring Boot Actuator + Micrometer registry + Prometheus scrape endpoint. Dependency `pom.xml`'de zaten var:

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

## Endpoint

```
GET /product/actuator/prometheus
```

`application.properties`:
```properties
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.endpoint.prometheus.enabled=true
management.metrics.export.prometheus.enabled=true
```

## Custom Metrics

`MetricsConfiguration.java` sabitleri:

### Reconcile (Sprint 3, P1.4)

| Metric | Tip | Tag'ler |
|---|---|---|
| `reconcile.runs.total` | Counter | `entity_type`, `scope` (SINGLE\|ALL), `status` (ok\|drift\|error) |
| `reconcile.drift.total` | Counter | `entity_type` |
| `reconcile.duration.seconds` | Timer | `entity_type`, `scope` |

Kayıt noktaları:
- `CustomerAccountServiceImpl.reconcile` / `reconcileAll` — try/finally ile her çağrıda counter + timer
- `SupplierAccountServiceImpl` — simetrik

### Domain (Pre-existing)

- `sales.created.total`, `sales.cancelled.total`, `sales.returned.total`
- `movements.created.total`, `movements.sale_out.total`, `movements.purchase_in.total`
- `recommendations.*`

## Örnek PromQL

```promql
# Drift tespit oranı (5dk pencere)
rate(reconcile_runs_total{status="drift"}[5m])

# p95 reconcile süresi
histogram_quantile(0.95, rate(reconcile_duration_seconds_bucket[5m]))

# Kümülatif drift count (customer + supplier)
sum by (entity_type) (reconcile_drift_total)

# Hata oranı
rate(reconcile_runs_total{status="error"}[5m])
```

## Scrape Config (Prometheus)

```yaml
scrape_configs:
  - job_name: pos-product-manager
    static_configs:
      - targets: ['localhost:8001']
    metrics_path: /product/actuator/prometheus
    scrape_interval: 30s
```

## Virtual Threads Uyarısı

`spring.threads.virtual.enabled=true` — Java 25 Project Loom aktif. Micrometer bazı timer'ları thread-local context'e bağlar; virtual thread'de çoğu `Timer.record(...)` API zaten thread-safe ancak custom tag'ler dynamic oluşturuluyorsa kontrol et.

## Tuzaklar

- **Metric name hyphen → underscore**: Prometheus export'ta `reconcile.runs.total` → `reconcile_runs_total` olur
- **Yüksek cardinality tag**: `customer_id` gibi tag koyma — metric patlaması. Scope (SINGLE/ALL) gibi düşük cardinality OK
- **Virtual thread timer**: `Timer.Sample.start` / `.stop` pattern virtual thread'de sorunsuz

## Sources

- `pos-product-manager/pom.xml` (dependencies)
- `pos-product-manager/src/main/java/com/sedcore/common/config/MetricsConfiguration.java`
- `pos-product-manager/src/main/resources/application.properties` (actuator config)

## Related

- [[syntheses/flow-drift-reconciliation]] (reconcile metrics kaynağı)
- [[syntheses/integration-slack-webhook]] (alert mechanism)
