---
title: Sprint 8 Implementation Plan — Pagination + Hold-overs + Yönetim Görünürlüğü
type: synthesis
date: 2026-04-26
status: actionable
based-on: syntheses/accounts-development-analysis-2026-04-25-v2 + sprint-7-implementation-plan-2026-04-25
sprint: 8
duration: 1 hafta (~5-6 gün net iş)
---

# Sprint 8 Implementation Plan

[[syntheses/accounts-development-analysis-2026-04-25-v2]] Sprint 8 = "Yönetim Görünürlüğü" + Sprint 7 hold-overs. Sıra:

| WP | Konu | Efor | Öncelik |
|---|---|---|---|
| **WP1** | B0 Pagination (accounts list) | 4-5 gün | P1 |
| **WP2** | ErrorBoundary 3 panel yaygın entegrasyon (Sprint 7 hold) | 1.5 saat | P1 |
| **WP3** | T2-T4 service-level testler (@SpringBootTest) | 1.6 gün | P1 |
| **WP4** | B8 Overdue notification (eski I3) | 3 gün | P2 |
| **WP5** | B9 Activity history (eski I4) | 1.5-2 gün | P2 |
| **WP6** | B6 Yaşlandırma raporu | 3-4 gün | P2 |

**Net iş:** Sprint 8'de tamamı sığmaz. **Önerilen alt-küme: WP1 + WP2 + WP3** (~7 gün). WP4/WP5/WP6 Sprint 9'a.

---

## WP1 — B0 Pagination (4-5 gün)

### Mevcut Durum (kod tarama 2026-04-26)

[`accounts_list_provider.dart:83-131`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart#L83-L131):
```dart
Future<void> load() async {
  final results = await Future.wait([
    _ref.read(customerServiceProvider).getCustomers(),  // TÜM müşteriler
    _ref.read(supplierServiceProvider).getSuppliers(),  // TÜM tedarikçiler
  ]);
  // client-side merge + sort
}
```

**Sorun:** 100+ kayıt için:
- Backend: full table scan, büyük JSON response (1-3 MB)
- Network: yavaş initial load
- Frontend: tüm liste memory'de, filter/search hızlı ama initial render gecikir

### Tasarım Kararı: Backend Birleşik Endpoint + Cursor

**Önceki:** 2 ayrı endpoint (customers + suppliers) → frontend merge.
**Yeni:** Birleşik endpoint `GET /accounts?cursor=X&limit=20&filter=overdue&q=ALI`:
- Backend zaten merged sorting yapıyor (single query'de UNION + ORDER BY name).
- Cursor-based: `cursor=name|type|id` → "where (name, type, id) > cursor LIMIT 20".
- Filter + query parametreleri backend'e taşınır (server-side filter daha güçlü).

**Trade-off:** Yeni endpoint = backend iş. Alternatif: mevcut 2 endpoint'e pagination param + frontend merge. Daha az risk ama daha kötü UX (page sınırı 2 koleksiyon arası kaybı).

### Backend (1.5 gün)

**Yeni endpoint:** `GET /api/v1/accounts/list`
- Query params: `cursor` (opaque base64 → `name|type|id`), `limit` (default 20, max 100), `filter` (`all|overdue|customer|supplier`), `q` (search)
- Response: `{items: [...], nextCursor: "..."|null, total: ...?}`

**Backend implementasyon:**
- `AccountsListController` (yeni)
- `AccountsListService.list(cursor, limit, filter, query)` — JPQL UNION query
- Cursor decode/encode helper
- Index: `(name, id)` müşteri + tedarikçi tablolarında — perf için

### Frontend (2.5 gün)

**Provider değişimi:**
```dart
class AccountsListState {
  final List<AccountListItem> all;
  final String? nextCursor;        // YENİ
  final bool isLoadingMore;        // YENİ
  final bool hasReachedEnd;        // YENİ
  ...
}

class AccountsListNotifier extends StateNotifier<AccountsListState> {
  Future<void> loadFirst() async { ... }      // initial load
  Future<void> loadMore() async { ... }       // append
  Future<void> refresh() async { ... }        // pull-to-refresh
  void setFilter(...) { loadFirst(); }        // server-side filter
  void setQuery(...) { _debounceLoadFirst(); } // debounced search
}
```

**Widget değişimi (`accounts_list_panel.dart`):**
- `ScrollController` → bottom 200px → `loadMore()`
- Loading footer (CircularProgressIndicator)
- Empty/error states
- Pull-to-refresh `RefreshIndicator`

### Search Debounce

Server-side query: kullanıcı yazarken her keystroke'ta backend çağırma → 300ms debounce.

### Done Kriteri

- 🟢 Backend cursor pagination (offset-based fallback opsiyonel)
- 🟢 Backend index'ler eklendi (EXPLAIN ANALYZE ile doğrulandı)
- 🟢 Frontend infinite scroll çalışıyor (200+ kayıt smooth)
- 🟢 Filter + query server-side, debounced search
- 🟢 Pull-to-refresh
- 🟢 Loading/empty/error states
- 🟢 Wiki: `concepts/cursor-pagination-pattern.md` + `entities/accounts-list-controller.md`

### Risk

- **R1:** Customer + Supplier ayrı tablolar, UNION query plan optimizatörü kötü davranabilir → composite index + EXPLAIN
- **R2:** `accountSummaryProvider.overdueList` ile `hasOverdue` join client-side yapılıyor → sayfa-başı join eksik kalır. Backend response'a `hasOverdue: bool` doğrudan ekle.
- **R3:** Cursor base64 encode/decode JSON serializability → `Cursor` POJO test edilmeli
- **R4:** Mevcut `accountsListProvider` callsite'lar (statement_detail_panel `_handlePayment` 4 provider refresh) `loadFirst()` çağırmalı, `load()` API kırılır → migration

---

## WP2 — ErrorBoundary 3 Panel Entegrasyonu (1.5 saat)

Sprint 7'de minimal `AccountsErrorView` widget yazıldı. Sprint 8 başında 3 panel'e entegre:

| Panel | Async Provider | Eylem |
|---|---|---|
| `AccountsListPanel` | `accountsListProvider` | `state.error != null` → `AccountsErrorView` (retry: `loadFirst()`) |
| `StatementDetailPanel` | `accountStatementProvider` | aynı |
| `AccountsSummaryBar` | `accountSummaryProvider` | aynı |

### Done

- 🟢 3 panel `AccountsErrorView` kullanıyor
- 🟢 Manuel hata enjeksiyonu (backend 500 mock) ile test edildi
- 🟢 Wiki: `entities/accounts-error-view.md`

---

## WP3 — T2-T4 Service-Level Testler (1.6 gün)

Sprint 7'de WP2 minimum (PaymentAllocationRepositoryTest, 3 method) tamam. Şimdi service-level testler.

### T1 (Sprint 7'de minimum) → Genişlet
**Yeni:** `PaymentCreationIntegrationTest` (`@SpringBootTest`):
- `createPayment_singleAllocation_specificSale`
- `createPayment_emptyAllocations_genericPayment`
- `createPayment_multipleAllocations_sumValidation`
- `createPayment_invalidSum_throwsException`

### T2 ReconcileDriftDetectionTest

- `reconcile_detectsDrift_whenDenormalizeManuallyChanged`
- `reconcile_idempotent_noDriftNoOp`
- `reconcile_paymentAllocation_sumMatches` — Sale.paidAmount = SUM(allocations) doğrula

### T3 CreditLimitGuardTest

- Boundary cases (limit=0/eşit/üzeri)
- Override role bypass

### T4 SalePaymentFkIntegrityTest

- `cancelSale_existingAllocations_behaviorVerified`
- `partialPayment_remainingAmountCorrect`
- `multiplePayments_sumEqualsPaidAmount`

### Test DB Stratejisi

Mevcut H2 PostgreSQL mode + `@DataJpaTest` Sprint 7'den. Service test'ler için `@SpringBootTest` — full Spring context.

**Risk:** `@SpringBootTest` yavaş (~10s startup). Mockito ile fake `CompanyContext` ThreadLocal set edilmeli (ThreadLocal test izolasyonu zor).

---

## Sprint 8 Önerilen Sıra

```
Gün:    1   2   3   4   5
WP2:    █░░░  (1.5 saat — ısınma)
WP1:    ████████████░░  (frontend + backend paralel)
WP3:           ░░██████  (WP1 backend bittikçe)
```

**Toplam:** 6-7 gün — sprint kapasitesi. WP4/5/6 Sprint 9'a kaydı.

## Kritik Dosyalar

| Dosya | WP |
|---|---|
| **Yeni:** `pos-product-manager/.../finance/controller/AccountsListController.java` | WP1 |
| **Yeni:** `pos-product-manager/.../finance/service/AccountsListService.java` | WP1 |
| **Update:** `project_pos/.../accounts_list_provider.dart` (paginated state) | WP1 |
| **Update:** `project_pos/.../accounts_list_panel.dart` (infinite scroll) | WP1 |
| **Update:** `project_pos/.../accounts_hub_screen.dart` + 2 panel | WP2 |
| **Yeni:** `pos-product-manager/src/test/java/.../sales/CreditLimitGuardTest.java` vb | WP3 |

## Açık Sorular — CEVAPLANDI (2026-04-26)

1. **Cursor format:** `JSON` (transparent, base64 wrap'siz — debug edilebilir)
2. **Limit upper bound:** `50` (default 20)
3. **Filter + query:** ikisi birlikte (`AND`) — örn: `filter=overdue&q=ALI`
4. **Initial loader:** `CircularProgress` (skeleton tercih edilmedi — basit + hızlı)
5. **Pull-to-refresh:** `scroll-top` (manuel button yok)

## Sources

- v2 analiz: [[syntheses/accounts-development-analysis-2026-04-25-v2]] (Sprint 8 öncelik)
- Sprint 7 plan: [[syntheses/sprint-7-implementation-plan-2026-04-25]]
- Sprint 7 sonuç: [[log]] 2026-04-25 + 2026-04-26
- Mevcut kod: [`accounts_list_provider.dart`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart), [`accounts_list_panel.dart`](project_pos/lib/features/accounts/widgets/accounts_list_panel.dart)
- Issues: [[issues/accounts-pagination-missing]] (artık B0), [[issues/accounts-error-boundary-missing]] (WP2)

## Related

- [[syntheses/sprint-7-implementation-plan-2026-04-25]] (parent — hold-overs kaynağı)
- [[syntheses/accounts-development-analysis-2026-04-25-v2]] (önceliklendirme)
- [[concepts/denormalization-with-reconcile]] (T2 testi için)
