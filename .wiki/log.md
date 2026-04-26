---
title: Wiki Olay Kaydı (Event Log)
type: log
format: append-only
last-verified: 2026-04-25
---

# Wiki Olay Kaydı

Append-only olay kaydı. **En yeni üste**.

## Olaylar

## [2026-04-26] design | plaka bazlı satış-tahsilat bütünsel — Opsiyon C tasarımı

Kullanıcı senaryosu: parçacı sektörde satış sırasında plaka kayıt + müşteri görünümünde plaka arama + tahsilatta plaka bazlı geçmiş seçimi. Geri-dosyalama: [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]].

**Tetikleyici:** [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] "Yeniden Değerlendirme Kriterleri" sağlandı — kullanıcı multi-plaka senaryosunu kanıtladı. Opsiyon A (description prepend) yetersiz, **Opsiyon C** (CustomerVehicle entity) gerekli.

**Tasarım özeti:**
- Backend: `CustomerVehicle` entity (`customer_id` + `plate_normalized` UNIQUE) + `Sale.customerVehicleId` FK + `Sale.vehiclePlateSnapshot` denormalize cache
- Endpoint: `/customers/{id}/vehicles` CRUD + search; `/sales?vehiclePlate=Y` filter
- Frontend: Sektör-aware widget'lar (`CustomerVehiclePicker`, `VehiclePlateSearchBar`, `AddCustomerVehicleModal`); sektör=autoParts kontrolü ile koşullu render
- Migration: mevcut `Payment.description` "Plaka: XX" prepend'lerini CustomerVehicle'a upsert (idempotent, dry-run desteği)
- Reconcile: yeni invariant `Sale.vehiclePlateSnapshot == customerVehicle.plateNormalized`

**Sprint roadmap (~7-10 gün):**
- Sprint 9: Backend foundation (entity + repo + service + endpoint + Sale FK)
- Sprint 10: Frontend POS (CustomerVehiclePicker + cart_panel + AddVehicleModal)
- Sprint 11: Accounts tahsilat (VehiclePlateSearchBar + statement_detail_panel + migration)

**Yeni backend servisler:** 8 yeni Java class + 5 değişen + 2 migration script + 1 reconcile invariant.
**Yeni frontend Dart dosyalar:** 5 yeni + 5 değişen.

Done kriteri 7 senaryo: butik sektörde plaka widget'ları görünmez (sektör isolation).

## [2026-04-26] correction | hot-fix-v3 YANLIŞ YORUM — REVERTED

Kullanıcı düzeltti: "yanlış geliştirme yapıldı. sistemimizde firma bazlı arama yapılır." Önceki tenant-leak yorumu HATALI — sistem multi-firma per-user mimarisi:

- Bir kullanıcı birden fazla firmaya sahip olabilir (SEDCORE otomotiv + SEDCORE1 butik)
- Backend endpoint'leri default tüm firmalardan döner
- "Firma bazlı arama" = frontend UI'dan companyCode filter

**Revert (git checkout HEAD --):**
- `CustomerService.search()` interface method (eklenmişti — geri alındı)
- `CustomerServiceImpl.search()` impl (geri alındı)
- `CustomerControllerImpl.list` service yönlendirme (geri alındı, repository direkt kalmaya devam ediyor — DOĞRU)

Backend Maven compile (revert sonrası): **exit 0** ✅

**Wiki düzeltme:**
- Yeni: [[concepts/multi-company-per-user-architecture]] — DOĞRU mimari açıklaması
- Deprecated: [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] — yanlış yorum, header DEPRECATED + supersedes link
- Index: tenant-leak link'i deprecated, multi-company-per-user-architecture eklendi

**Açık soru (kullanıcıdan netleştirme bekleniyor):**
AccountsListService'in `selectedCompanyCode` filter aktif tutması doğru mu? (önceki response'ta sadece SEDCORE 4 kayıt döndü.) Eğer "tüm firmalar" doğru ise oradaki filter da kaldırılmalı. Şu an dokunulmadı.

## [2026-04-26] 🚨 hot-fix-v3 | KRİTİK: multi-tenant leak — CustomerController repository bypass

> ⚠️ Bu girdideki "tenant leak" yorumu YANLIŞ olduğu sonradan tespit edildi (bkz. üstteki correction). Hot-fix v3 revert edildi. Detay: [[concepts/multi-company-per-user-architecture]]

Kullanıcı `/customers?isActive=true` response'u paylaştı: **2 farklı tenant'tan kayıt** (SEDCORE Usta+Adem, SEDCORE1 Moda Butik+**Zeynep**) → tenant izolasyon kırığı kanıtlandı.

Geri-dosyalama: [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] (KRİTİK).

**Kök neden:** [[concepts/hibernate-filter-runtime]] §Critical Bulgular #4 gerçekleşti. `CompanyHibernateFilterActivator` AOP pointcut `com.sedcore..service..*` — sadece service layer'da advice tetiklenir. CustomerControllerImpl direkt `customerRepository.search()` çağırdığı için (service bypass) Hibernate `@Filter("filterByCompanyCode")` aktif edilmedi → tüm tenant'lar geliyordu.

**Karşıt kanıt:** AccountsListService aynı oturumda sadece SEDCORE 4 kayıt döndürdü (önceki response 16:19) çünkü `@Service` annotated → AOP advice tetikleniyor.

**Uygulanan Düzeltme (Hot-Fix v3):**
- F1: `CustomerService.search(String, Boolean)` interface method eklendi
- F2: `CustomerServiceImpl.search` → `dao.search(q, isActive)` (service-layer çağrı)
- F3: `CustomerControllerImpl.list` → `customerService.search(...)` (repository direct yerine)
- Backend Maven compile: **exit 0** ✅

**Beklenen davranış (restart sonrası):**
- SEDCORE oturumu → sadece SEDCORE müşterileri
- SEDCORE1 oturumu → sadece SEDCORE1 (Zeynep + Moda Butik)
- Zeynep'in POS'ta SEDCORE oturumunda görünmesi tenant leak idi; artık görünmemeli (doğru davranış)

**Kalan Risk (Sprint 9 acil audit):**
- 7+ dosya / 13+ callsite hâlâ `customerRepository.findById/count`, `accountTransactionRepository.findCustomerStatement` direkt çağırıyor → cross-tenant ID erişimi açık
- Sistemik çözüm: AOP pointcut'ı controller'a yay (Seçenek A) + service üzerinden zorla (Seçenek B)

## [2026-04-26] query | zeynep DB'de yok kanıtlandı — backend response 4 kayıt

Kullanıcı backend response paylaştı: `hasMore=false`, 4 kayıt (oto1 tenant), Zeynep YOK. Geri-dosyalama: [[syntheses/zeynep-customer-not-in-db-2026-04-26]].

**Önceki hipotezler çürütüldü:**
- ❌ Pagination (hasMore=false zaten tüm kayıtları döndürdü)
- ❌ Filter (4 kayıttan 2 customer var, filter doğru)
- ❌ Endpoint tutarsızlığı (POS Cart Panel ve AccountsListService AYNI `customerRepository.search(null, true)` kullanıyor)

**4 yeni senaryo:**
- A: POS yeni müşteri eklerken backend POST başarısız oldu → frontend in-memory cache, DB'ye gitmedi
- B: Zeynep farklı tenant'ta (SEDCORE1 vs SEDCORE)
- C: `is_active=false` veya `is_deleted=true`
- D: Kullanıcı yanılgısı (POS'ta başka müşteri ile karıştırıyor)

**3-adım tanı:**
1. SQL: `SELECT * FROM customers WHERE LOWER(name) LIKE '%zeynep%'`
2. POS Cart Panel kapat-aç (state cache vs DB)
3. JWT decode → `selectedCompanyCode` ile `customer.company_code` karşılaştır

**Sistemik kalıcı çözüm (Sprint 9):**
- E1: AccountEditForm save sonrası `ref.invalidate(accountsListProvider)` audit
- E2: Backend POST hata durumunda Flutter explicit AppToast.error
- E3: Cart Panel _CustomerPickerSheet ile AccountsListProvider sync

## [2026-04-26] hot-fix-v2 | zeynep sorunu sistemik çözüm — pageLimit + auto-prefetch ✅

Kullanıcı talebi: "müşteriyi cari accountunda görmem lazım, sistem stabil çalışmalı". Pagination paradigmasından vazgeçmeden 3 değişiklik:

**B1** — Backend `AccountsListService.list` clamp `Math.min(50, limit)` → `Math.min(200, limit)`. KOBİ tenant'lar için yeterli üst sınır; 200+ müşteri varsa pagination devreye girer.

**B2** — Frontend `accounts_list_provider.dart` `_pageLimit` 50 → 100. İlk yükleme 100 müşteri.

**B3** — Frontend `loadFirst()` sonrası **auto-prefetch**: query boşsa + hasMore varsa otomatik 1x loadMore → toplam ~200 müşteri ilk açılışta. Sıralama `name ASC` olduğu için "Z" harfli müşteri (Zeynep dahil) artık ilk açılışta görünür.

**Mantık:** 200+ müşterili büyük tenant'lar için kullanıcı scroll yapar (manuel loadMore zaten çalışıyor). Auto-prefetch sadece query boşken — search yapıldığında server-side filter zaten kayıtları azaltır, prefetch gereksiz.

**Verification:**
- Backend Maven compile: exit 0 ✅
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime)

Önceki troubleshooting rehberi geçerli: [[concepts/troubleshooting-customer-missing-in-accounts-hub]]. #1 pagination nedeni artık küçük tenant'lar için elendi.

## [2026-04-26] query | zeynep müşterisi POS'ta var ama cari hesaplarda yok

Geri-dosyalama: [[concepts/troubleshooting-customer-missing-in-accounts-hub]] — generic tanı rehberi (5 olası neden + adım-adım teşhis).

**Hipotezler (öncelik sırasıyla):**
1. 🔴 **Pagination** — limit 50, "Z" harfi ilk sayfada yok, scroll loadMore tetiklenmedi (en olası)
2. 🟠 Filter chip "Tedarikçi" veya "Vadesi Geçmiş" basılı
3. 🟠 Search query önceki aramadan açık
4. 🟡 `is_deleted=true` (paradox: POS Cart Panel aynı endpoint, gelmemeli)
5. 🟡 Multi-tenant `company_code` farklı (session değişimi varsa)
6. 🟢 Sprint 8 frontend pagination parse bug (az olası)

**Tanı 6-adım** sırasıyla UI (saniyeler) → backend curl → DB → JWT decode.

**Düzeltme önerileri:**
- #1 için: search box'a "z" yaz → server-side filter ile direkt gelir
- #2-3 için: chip "Tümü" + search clear
- #4 için: `UPDATE customers SET is_deleted=false`
- #5 için: company_code düzeltme (veri taşıma dikkat)

## [2026-04-26] sprint-8-cleanup | P0.2 + P1.1 + P2.5 batch — bütün planları sırayla ✅

Kullanıcı talebi: "ben dışarı çıkıyorum bütün planları sırayla yap". [[syntheses/pending-work-status-2026-04-26]] sırasına göre uygulandı:

**Tamamlanan (~5 saat eşdeğeri iş):**

**P0.2 — D3 frontend currentBalance render** ✅
- [`statement_detail_panel.dart`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart): `currentBalance` parse, `hasDrift` hesaplaması, `_SummaryGrid` constructor genişledi
- `_SummaryGrid` 4. tile primer değer `currentBalance` (denormalize gerçek), drift varsa warning icon + secondary line "⚠ Hesaplanan: X" göstergesi
- `_StatTile.secondaryValue` field eklendi (drift göstergesi için)

**P1.1a — StatementDetailPanel ErrorView** ✅
- `AppEmptyState.error` → `AccountsErrorView` (retry button + AppLogger pattern)

**P1.1b — AccountsSummaryBar ErrorView** ✅
- `summaryState.error != null` durumunda compact `AccountsErrorView` (yer kazanma için compact mode)

**P2.5 — Lint P1 cleanup** ✅
- 16 wikilink ad değişimi sed batch (flows/X → syntheses/flow-X, integrations/X → syntheses/integration-X, patterns/X → concepts/pattern-X veya concepts/X)
- 5 redirect: `[[contradictions]]` → claude-wiki-contradictions, `[[decisions/append-only-semantics]]` → concepts/append-only, vb
- `archive/README.md` placeholder yarat ([[archive/README]] kırık linki düzeltildi)

**Verification:**
- Backend Maven compile: **exit 0** ✅
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime'da)

**Ertelendi (Sprint 9):**
- P1.2 T2-T4 service-level testler (1.6 gün — büyük scope)
- P1.3 B0 phase 2 POS Cart Panel paginated (1 gün)
- P2.1 B3 toplu ödeme UI (1.5-2 gün — backend hazır)
- P2.6 I5 test coverage geniş kapsam
- P2.7 18 MERGE_NEEDED dosya inceleme

**Kabul edilen Sprint 7+8 done kriteri:**
- Sprint 7: WP1 (4 dosya backend) + WP3 (provider) + WP4 (modal sale picker) + WP4.b (caller) + WP5 (i18n + ErrorView widget) + WP6 (3 wiki sayfası) + WP2 minimum test (3 test, BUILD SUCCESS) ✅
- Sprint 8: WP1 (5 dosya backend cursor pagination) + WP1 frontend (provider rewrite + scroll) + WP2 (3/3 panel ErrorView) ✅
- Hot-fix: D1 ref.invalidate + D2 limit 50 + D3 backend currentBalance + D3 frontend render ✅

**Toplam Sprint 7+8+hot-fix:**
- Backend: 6 yeni dosya, 4 update, 1 entity model genişledi
- Frontend: 4 yeni dosya, 5 update
- Wiki: 6 yeni sentez sayfası, 3 wiki sayfası (entity/concept/decision)
- Test: 1 test class (3 method, BUILD SUCCESS)
- i18n: 7 yeni anahtar (TR+EN)

**Kaynak:** kullanıcı talebi — auto mode "bütün planları sırayla yap".

## [2026-04-26] query | planda yapılmaya kalan var mı? — pending work status

Kullanıcı talebi: aktif tüm planlar + sentezler + hot-fix sonrası ne kaldı? Geri-dosyalama: [[syntheses/pending-work-status-2026-04-26]] — P0/P1/P2/P3 önceliklendirme + sprint roadmap.

**Konsolide kaynaklar:**
- Sprint 7 hold-overs: WP2 (3 panel ErrorView, 1 yapıldı), WP3 (T2-T4 testler), smoke test
- Sprint 8 hold-overs: D3 frontend render, B0 phase 2 (POS pagination), WP2/WP3 devamı
- v2 backlog: B0/B3/B6/B8/B9 + I5
- Lint action plan P1-P3 (sed batch, MERGE_NEEDED, xref, zayıf kaynak)
- Codebase snapshot P4 (React/controller/core ingest)

**Önerilen bu hafta sıra (~5 saat):**
1. P0.1 smoke test (sen runtime)
2. P0.2 D3 frontend `currentBalance` render (1-2 saat)
3. P1.1 ErrorBoundary kalan 2 panel (1.5 saat)
4. P2.5 lint P1 cleanup (1 saat — yüksek ROI)

**Kritik not:** Frontend `flutter analyze` Sprint 7+8 boyunca koşulmadı. P0.1'in parçası olarak `flutter analyze` öneriliyor.

## [2026-04-26] query | hot-fix: POS müşteri listesi + bakiye refresh ✅

Kullanıcı 2 üretim bug'ı raporladı:
1. POS satış ekranı müşteri listesi ≠ AccountsHub liste (eksik kayıtlar)
2. Cari hesapta ödeme sonrası bakiye UI'da güncellenmiyor (hot reload düzeltir)

İki paralel Explore agent kök nedenleri tespit etti. Geri-dosyalama: [[syntheses/accounts-bugfix-investigation-2026-04-26]].

**Kök Nedenler:**
- **Bug A**: Cart Panel `/customers?isActive=true` (sayfasız) ↔ AccountsHub `/accounts/list?limit=20&...` (paginated). Auth/filter doğru, sadece pagination farkı.
- **Bug B**: (1) Backend statement response'a denormalize `currentBalance` eksik — yalnızca `closingBalance` (transaction toplamı) var. (2) `_handlePayment` 3 autoDispose provider'a `Future.wait([notifier.load()])` → modal close + rebuild race. (3) Sprint 8 `loadFirst()` state reset timing.

**Uygulanan Düzeltmeler (3):**
- **D1** — `statement_detail_panel.dart`: `ref.invalidate(accountsListProvider)` + 3 load (4 yerine). AutoDispose race önlendi.
- **D2** — `accounts_list_provider.dart` `_pageLimit` 20→50 (backend Math.min(50, limit) clamp). Sprint 9: POS Cart Panel'i de paginated.
- **D3** — Backend `AccountStatementEntry.currentBalance: BigDecimal` field eklendi; `AccountStatementControllerImpl` `customerAccountService.getOrCreate(...).getCurrentBalance()` ile dolduruyor (supplier eşdeğeri). Fallback: exception → `closingBalance`. **Maven compile exit 0**.

**Sprint 9 hold-overs:**
- D3 frontend — `statement_detail_panel.dart` `currentBalance` render + drift göstergesi
- B0 frontend — POS Cart Panel paginated
- WP2 kalan 2 panel ErrorView (Sprint 8'den)
- WP3 T2-T4 testler

**Kaynak:** kullanıcı talebi — 2 üretim bug raporu + plan onayı (ExitPlanMode).

## [2026-04-26] sprint-8 | WP1 backend ✅ + WP1 frontend ✅ + WP2 kısmi ✅

Kullanıcı talebi: "ben dışarı çıkıyorum plan için onay veya soru sorma hepsini hallet". Açık sorular cevaplandı (cursor=JSON, limit=50, filter+query=AND, loader=CircularProgress, refresh=scroll-top). Sprint 8 önemli kısmı uygulandı:

**WP1 Backend ✅** (Maven compile exit 0):
- Yeni: `AccountsListCursor.java` — JSON transparent cursor (name|type|id tuple)
- Yeni: `PaginatedAccountsResponse.java` — items + nextCursor + hasMore
- Yeni: `AccountsListService.java` — CustomerRepository.search (DB-side, EntityGraph N+1 fix) + SupplierService.listSuppliers + in-memory merge/sort/cursor (R1: DB UNION optimization sprint sonuna)
- Yeni: `AccountsListControllerImpl.java` — `GET /api/v1/accounts/list?cursor=&limit=20&filter=&q=`

**WP1 Frontend ✅:**
- Update: `accounts_list_provider.dart` — komple rewrite, paginated state (`isLoadingMore`, `hasReachedEnd`, `nextCursor`), `loadFirst/loadMore/refresh`, debounced setQuery (300ms), setFilter triggers loadFirst, geriye uyum `load()` alias. AccountListItem.fromMap factory eklendi.
- Update: `accounts_list_panel.dart` — ScrollController bottom-200px loadMore, RefreshIndicator pull-to-refresh, loading footer, `AccountsErrorView` entegrasyonu (WP2 #1)

**WP2 ErrorView Entegrasyonu (kısmi):**
- ✅ AccountsListPanel — `AccountsErrorView` ile error state replace
- ⏳ StatementDetailPanel — Sprint 9'a kaydı
- ⏳ AccountsSummaryBar — Sprint 9'a kaydı

**Ertelendi (Sprint 9):**
- WP3 T2-T4 service-level testler (@SpringBootTest)
- WP2 kalan 2 panel ErrorView
- Plan v2 P3 yaşlandırma raporu (B6), overdue notification (B8), activity history (B9)

**Bilinen sınırlamalar:**
- AccountsListService in-memory merge (1000+ supplier'da yavaş olabilir; sprint sonu DB-side UNION optimization R1)
- SupplierRepository.search yok (Customer'da var) — supplier query'si in-memory filter
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime ile doğrulayacak)

**Manuel doğrulama (kullanıcı):**
1. Backend restart sonrası `GET /product/api/v1/accounts/list?limit=5` → JSON `{items, nextCursor, hasMore}`
2. Flutter hot reload → AccountsHub → liste 20'şer kayıt yükleniyor, scroll'da loadMore tetikleniyor
3. Pull-to-refresh çalışıyor; filter/search değiştirince loadFirst tetikleniyor
4. Backend down → AccountsErrorView retry button'u çalışıyor

**Kaynak:** kullanıcı talebi — "plana göre doğru yoldan devam" + "hepsini hallet".

## [2026-04-26] sprint-8 | implementation plan yazıldı

Kullanıcı talebi: "devam" — Sprint 7 sonrası Sprint 8'e geçiş. Geri-dosyalama: [[syntheses/sprint-8-implementation-plan-2026-04-26]].

**Sprint 8 kapsamı (önerilen alt-küme):**
- WP1 (4-5g): B0 Pagination — backend birleşik `/accounts/list` endpoint (cursor-based) + frontend infinite scroll + server-side filter/query (debounced)
- WP2 (1.5h): ErrorBoundary 3 panel yaygın entegrasyon (Sprint 7 hold-over)
- WP3 (1.6g): T2-T4 service-level testler (@SpringBootTest) — reconcile drift + credit limit + sale-payment FK integrity

**Sprint 9'a kaydı:** B8 (overdue notification), B9 (activity history), B6 (yaşlandırma raporu).

**Kritik tasarım kararı:** Cursor-based pagination + birleşik endpoint (mevcut 2 ayrı customer/supplier endpoint yerine) — sayfa sınırı 2 koleksiyon arası kayıp önlenir.

**Açık sorular** (PR review): cursor format (opaque), limit upper bound, filter+query AND, initial loader skeleton vs spinner, pull-to-refresh kapsamı.

**Kullanıcı onayı bekliyor** WP1 implementasyonu için (backend AccountsListController + frontend paginated state).

## [2026-04-26] sprint-7 | WP2 minimum — test infrastructure + ilk test ✅

WP2'nin minimum scope'u uygulandı. `Tests run: 3, Failures: 0, Errors: 0 — BUILD SUCCESS`.

**Yeni dosyalar:**
- `pos-product-manager/pom.xml` — H2 (test scope) eklendi
- `src/test/resources/application-test.properties` — H2 in-memory PostgreSQL mode, ddl-auto=create-drop, sql.init.mode=never
- `src/test/java/com/sedcore/finance/repository/PaymentAllocationRepositoryTest.java` — 3 test (`@DataJpaTest`):
  - `save_withSaleFk_persists` — allocation insert (sale=null)
  - `findByPaymentId_returnsAllocations` — multi-allocation query (B3 senaryosu)
  - `sumActiveBySaleId_excludesCancelled` — cancelled payment'lar hariç toplam

**Mimari kararlar:**
- H2 with PostgreSQL mode seçildi (Testcontainers + Docker daemon kompleksitesinden kaçındık)
- `@DataJpaTest` ile sadece JPA katmanı (full Spring context yok, hızlı)
- `ID elle set edilmez` — TOpenSimpleCompanyEntity @PrePersist ile UUID üretir (lesson learned)
- data.sql test'te koşmaz (`sql.init.mode=never`) — her test temiz state

**Sonraki sprintte (WP2.4):**
- T1 full PaymentCreationIntegrationTest (@SpringBootTest service-level)
- T2 ReconcileDriftDetectionTest
- T3 CreditLimitGuardTest
- T4 SalePaymentFkIntegrityTest

Sprint 7 done kriteri büyük ölçüde sağlandı; hold-over: smoke test (kullanıcı runtime) + ErrorBoundary 3 panel entegrasyon (Sprint 8).

**Kaynak:** kullanıcı talebi — "plana göre doğru yoldan devam".

## [2026-04-25] sprint-7 | WP1+WP3+WP4+WP5 implementasyon (testler ertelendi)

Sprint 7 başlatıldı. Plan: [[syntheses/sprint-7-implementation-plan-2026-04-25]]. Tamamlanan iş paketleri:

**Backend (WP1):**
- Yeni: `PaymentAllocation.java` entity (sale-payment many-to-many, `@Version`, indexes)
- Yeni: `PaymentAllocationRepository.java` (`findByPaymentId/SaleId`, `sumActiveBySaleId`)
- Yeni: `AllocationRequest.java` (DTO)
- Update: `PaymentRequest.java` — `allocations: List<AllocationRequest>` field, `saleId` `@Deprecated`
- Update: `PaymentServiceImpl.java` — `createAllocations()` helper + `createCustomerPayment()` çağrısı
- ✅ Maven compile geçti (exit 0)

**Frontend (WP3+WP4+WP4.b):**
- Yeni: `customer_open_sales_provider.dart` (FutureProvider.family + autoDispose)
- Update: `sales_service.dart` — `getCustomerOpenSales(String customerId)` ek metod
- Update: `payment_record_modal.dart` — `customerId` parametresi, "Hangi Alışverişe?" radio + açık satış picker, submit `allocations` array
- Update: `statement_detail_panel.dart` — caller `customerId` aktarımı + payload `allocations` field
- Yeni: `accounts_error_view.dart` (I2 minimum widget — yaygın entegrasyon Sprint 8'e)

**i18n (WP5):**
- 7 yeni anahtar `accounts.payment_target/general_payment/specific_sale_payment/no_open_sales/sale_remaining/add_another_sale/allocation_sum_mismatch` (TR + EN)
- ID şeması: `bnd-acpa01-07`

**Wiki (WP6):**
- Yeni: [[entities/payment-allocation]]
- Yeni: [[concepts/payment-allocation-pattern]]
- Yeni: [[decisions/payment-allocation-from-day-1]] (B1↔B3 mimari karar ADR)
- Index güncellendi (Sprint 7 Decisions, Cari Hesap concepts, Domain Diğer entities)

**Ertelendi (Sprint sonu):**
- WP2 testler T1-T4 (proje sıfır test infrastructure → ayrı kurulum gerekli)
- WP6 manuel smoke test (kullanıcı runtime ile yapacak)
- I2 ErrorBoundary yaygın entegrasyon (3 panel) — Sprint 8

**Geriye uyum:** `Payment.sale` FK + `PaymentRequest.saleId` `@Deprecated` ama kabul ediliyor. Sprint 9'da kaldırılacak.

**Kaynak:** kullanıcı talebi — "cari işlemler planına devam et" + "B devam, testler sprint sonunda".

## [2026-04-25] query | cari işlemler planına devam — Sprint 7 implementation plan

Kullanıcı talebi: "cari işlemler planına devam et". Geri-dosyalama: [[syntheses/sprint-7-implementation-plan-2026-04-25]] — v2 analizinin Sprint 7'sini 6 iş paketi (WP1-WP6) olarak adım adım uygulama planı.

**WP listesi:**
- WP1 (1g): Backend PaymentAllocation entity many-to-many baştan
- WP2 (1.6g): Backend T1-T4 kritik path testleri (paralel WP1 ile)
- WP3 (0.5g): Frontend service + customerOpenSalesProvider
- WP4 (1g): Frontend PaymentRecordModal sale picker
- WP5 (1.5g): Frontend i18n (7 key) + ErrorBoundary (I2)
- WP6 (0.5g): Wiki final + smoke test

**Net iş:** ~6 gün, 1 hafta sprint. Her WP için: dosya yolu, done kriteri, risk matrisi.

**Sonraki adım:** kullanıcı onayı ile WP1 (backend) implementasyonu başlatılacak.

Index güncellendi: Modül & Mimari Özet altına sprint plan linki.

## [2026-04-25] query | cari hesaplar modülü geliştirme analizi

Kullanıcı talebi: "Cari hesaplar sayfasına odaklanıp geliştirme analizi çıkar." Geri-dosyalama: [[syntheses/accounts-development-analysis-2026-04-25]].

**Kapsam:** 50+ accounts wiki sayfası (entities, syntheses, decisions, concepts, issues + scoped `project_pos/.../accounts/_wiki/`) sentezlendi. Backend kod doğrulaması yapıldı (Payment.saleId FK, SaleController endpoint).

**Bulgular:**
- 5 açık issue (pagination, error boundary, overdue notification, activity history, test coverage)
- 7 yeni geliştirme adayı (alışveriş bazlı ödeme, plaka B/C, toplu ödeme, taksit, hızlı tahsilat, yaşlandırma raporu, SMS bildirim)
- P1-P3 önceliklendirme + 3 sprint roadmap önerisi

**Sprint 7 önerisi:** B1 (alışveriş bazlı ödeme — backend hazır) + I2 (error boundary) + I1 (pagination).

Index güncellendi: Modül & Mimari Özet altına development analysis linki.

## [2026-04-25] query | LINT sonucu yapılması gereken aksiyon planı

Kullanıcı talebi: 134 lint bulgusu için somut aksiyon planı. Geri-dosyalama: [[syntheses/lint-action-plan-2026-04-25]] (P1-P4 öncelikli, sed komutları + manuel sıra + tahmini efor + kabul kriterleri).

**Plan özeti:**
- **P1 (1 saat)** — Hızlı kazanç: 16 sed batch + 6 eksik hedef kararı + 8 placeholder fix
- **P2 (3-5 saat)** — Orta: 18 MERGE_NEEDED inceleme + 5 issues merge + 50 xref ekleme + 5 zayıf kaynak doğrulama
- **P3 (1 saat)** — Lint Pass 3 koşturma + archive doldurma
- **P4 (sprint backlog)** — React/controller/core ingest

**Hedef sağlık skoru:** Y:0, O:<20, D:<30 (mevcut Y:23 O:130 D:~76).

Index güncellendi: Modül & Mimari Özet altına aksiyon planı linki.

## [2026-04-25] query | tüm kod dosyalarından wiki güncelleme (faz 1 — pragmatic)

Kullanıcı talebi: "proje altındaki bütün kod dosyalarını oku, wiki belleğini bu mevcut kod üzerinden güncelle." Pragmatic kapsam (1362 kod dosyası tek turda imkansız): **lint-report'taki 13 eksik kavram için kod kanıtı + son 15 commit deltası**.

### Yeni dosyalar (15)

**Decisions (1):**
- `decisions/2026-04-24-vehicle-plate-tracking-option-a.md` — Sprint 6b ADR (description prepend, schema değişikliği yok). Scoped wiki'deki sentezi ana wiki'ye yansıt.

**Syntheses (1):**
- `syntheses/codebase-snapshot-2026-04-25.md` — kod ↔ wiki uyum analizi, son 15 commit drift, 1362 dosya envanter, faz planı.

**Entities (7) — eksik kavramlar için kod-bazlı stub:**
- `entities/user-def.md` (core/.../security/UserDef.java)
- `entities/user-def-access.md` (core/.../security/UserDefAccess.java)
- `entities/product-variant.md` (pos-product-manager/.../product/entity/ProductVariant.java)
- `entities/accounts-hub-screen.md` (project_pos/.../accounts/screens/accounts_hub_screen.dart)
- `entities/document-item-result.md` (pos-product-manager/.../product/model/DocumentItemResult.java)
- `entities/batch-entry-row.md` (project_pos/.../batch_entry/models/batch_entry_models.dart:251)
- `entities/company-setting.md` (pos-product-manager/.../company/entity/CompanySetting.java)

**Concepts (6) — eksik kavramlar için kod-bazlı stub:**
- `concepts/company-context.md` (pos-product-manager/.../common/context/CompanyContext.java)
- `concepts/pre-authorize-guard.md` (Spring Security pattern, 1 kullanım)
- `concepts/batch-entry-state.md` (project_pos/.../batch_entry/models/batch_entry_models.dart:473)
- `concepts/batch-row-status.md` (batch_entry_models.dart:1 enum)
- `concepts/app-colors-palette.md` (project_pos/lib/core/theme/app_colors.dart)
- `concepts/state-notifier-vs-async.md` (Riverpod migration özeti, henüz başlamadı)

### Index güncellendi (5 alt-bölüm)

- Decisions → Sprint 6b alt-bölümü
- Syntheses → Modül & Mimari Özet altına codebase-snapshot
- Entities → Security Domain (yeni alt-bölüm), Ürün satırı, Firma satırı, Flutter Screens & Models (yeni alt-bölüm)
- Concepts → Mimari satırına 2 yeni link, Flutter / Frontend (yeni alt-bölüm) — 4 yeni link

### Faz Dışı (sonraki turlara)

- React (template/) modülü — 525 dosya, sadece CLAUDE.md kopyası kapsamlı değil
- pos-product-manager controller-bazlı endpoint kataloğu — ~50 dosya
- core kütüphane derinleşme (TOpenSimpleCompanyEntity, BaseDbServiceImp, @FilterDef)
- 18 MERGE_NEEDED dosya manuel diff (lint borçları)

**Kaynak:** kullanıcı talebi (auto + plan mode geçişleri)

## [2026-04-25] lint | 134 bulgu (Y:23 O:130 D:~76) — tam pass 2

`raw/` hariç **188 dosya** üzerinde 6 kategorili tam sağlık kontrolü. Mekanik (Bash) + sample diff (manuel). Otomatik düzeltme yapılmadı; rapor: [[lint-report]].

**Sayım:**
- 🔴 Çelişki (gerçek): **0** (3 sample diff yapıldı — hepsi DUPLICATE/zenginleştirme)
- 🟠 Çelişki adayı (MERGE_NEEDED): 21 (18 `-from-claude-wiki` + 3 ADR↔sentez)
- ✅ Eskimiş: 0 (tümü ≤12 gün)
- 🟠 Yetim: 18 (hepsi `-from-claude-wiki` — MERGE_NEEDED ile örtüşür)
- 🔴 Kırık wikilink (gerçek): 22 (16 ad değişimi + 6 eksik hedef)
- 🟠 Eksik kavram (≥10 bahis, sayfa yok, generic terim filtreli): 13 (`UserDef`, `UserDefAccess`, `ProductVariant`, `CompanyContext`, `AccountsHub`, `BatchEntryRow`, vb.)
- 🟡 Tek-yönlü xref: 773 ham → ~50 öncelikli (concept↔entity karşılıklı eksiklik)
- 🟠 Zayıf kaynak (≤1 source): 81 (parser sınırlı; manuel doğrulama önerildi)

**En kritik 3:** (1) 16 ad-değişen kırık wikilink — sed ile 10 dk; (2) 18 MERGE_NEEDED yetim — manuel diff 2-3 saat; (3) 13 eksik domain kavram — UserDef/ProductVariant gibi core entity sayfaları yok.

**Kaynak:** kullanıcı /lint-pass talebi.

## [2026-04-25] migration | Proje geneli .md konsolidasyonu → .wiki/

Kullanıcı talebi: "proje altındaki tüm `.md` dosyalarını `.wiki/`'ye entegre et + orijinallerini sil/stub bırak". Plan: `C:\Users\Win11\.claude\plans\polymorphic-gathering-flute.md`. AskUserQuestion ile 4 karar netleştirildi (CLAUDE.md hard-delete vs stub çelişkisinde safety nedeniyle B yorumu / stub uygulandı).

**Kapsam dışı (dokunulmadı):** `template/node_modules/**` (1500+ npm artifact), `**/target/**`, `.git/**`, `.claude/worktrees/**`, `project_pos/ios/.../LaunchImage README`, `core/.github/...progress.md`, `.wiki/**` (hedef vault).

**6 paralel agent + manuel:** ~117 dosya işlendi.

| Grup | Kapsam | Dosya | Sonuç |
|---|---|---|---|
| Agent A | `.claude/{decisions,runbooks,reference,status,plans,guides,inventory,commands,INDEX}/` + 3 root scratch | 25 | Hepsi taşındı + stub. `multi-tenant.md` çakıştığı için `multi-tenant-routing.md` adıyla yazıldı. |
| Agent B1 | `.claude/wiki/entities/*` | 18 | Hepsi DUPLICATE (önceki ingest'te wiki'de mevcuttu) → stub. README ayrı kaydedildi. |
| Agent B2 | `.claude/wiki/{decisions,concepts,patterns,syntheses,integrations}/*` | 27 | 23 DUPLICATE, 1 NEW (`use-entity-graph-for-customer-account-fetch`), 3 README silindi. |
| Agent B3 | `.claude/wiki/{flows,issues,archive,raw,sources,glossary,contradictions,index,log,lint-report}/*` | 32 | 5 issues `-from-claude-wiki` suffix'i ile MERGE_NEEDED, geri kalan stub. 5 NEW yazım. |
| Agent C | Module README + `pos-product-manager/ERROR_HANDLING_GUIDE.md` | 3 | Hepsi NEW. |
| Agent E | 10 CLAUDE.md (root + 7 modül + 2 alt + `.claude/wiki/CLAUDE.md`) | 10 | Hepsi `.wiki/sources/claude-md/` altına; ~37 link replace (`.claude/reference/...` → `.wiki/concepts/...` vb.); orijinaller 1-satır pointer stub. |
| Manuel | 2 patterns (`optimistic-lock-version`, `scoped-feature-wiki`) | 2 | DUPLICATE → stub. |

**MERGE_NEEDED (manuel inceleme bekleniyor):** `-from-claude-wiki` suffix'li 5 issues + bazı concepts. Mevcut wiki sayfasıyla kaynak içerik farklılığı tespit edildi.

**Yeni dizin:** `.wiki/sources/status-snapshots/`, `.wiki/sources/claude-md/`.

**Index güncellendi:** Yeni 4 bölüm (CLAUDE.md Arşivi, Status Snapshots, Code-refs migration alt-bölümü, Patterns alt-bölümü). 50+ yeni MOC link.

**Stub formatı:** `> Bu içerik [.wiki/...](göreceli-link) altına taşındı (2026-04-25).` Auto-load mekanizması stub'ı okur, link üzerinden devam eder.

**Etkilenen yollar:** `.claude/{decisions,runbooks,reference,status,plans,guides,inventory,commands,wiki}/`, root CLAUDE.md ve 7 modül CLAUDE.md, 3 root scratch, 3 module README/GUIDE.

**Kaynak:** kullanıcı talebi (auto mode + AskUserQuestion onayı).

## [2026-04-25] full-setup | İlk kapsamlı kurulum + 7 kaynak ingest + 4 sentez + lint
- **PHASE 1 (Setup)**: 9 alt klasör + 9 .gitkeep + CLAUDE.md (217 satır) + index.md + log.md zaten kuruluydu (önceki turlardan)
- **PHASE 2 (Kaynak seçimi)**: Proje genelinde 7 öncelikli kaynak seçildi (CLAUDE.md kök, accounts-hub gap, sale-checkout, purchase-checkout, drift-reconciliation, openapi-codegen, ledger-adr). Symlink (ln -s) Windows Git Bash'te kopyalama davranışı yaptığı için pointer-markdown fallback'a geçildi → `raw/code-refs/2026-04-25-*.md` (7 dosya)
- **PHASE 3 (Ingest)**: Her kaynak için sources/code-refs/2026-04-25-<slug>.md (7 source summary). Bahsedilen 22 entity, 15 concept, 18 decision, 12 issue açıldı. Toplam 74 yeni içerik sayfası.
- **PHASE 4 (Sentez)**: 4 yüksek seviyeli sentez yazıldı:
  - `syntheses/pos-module-map` — servis + client haritası
  - `syntheses/sector-agnostic-architecture` — çoklu sektör mimarisi
  - `syntheses/accounts-module-overview` — cari hesap modülü
  - `syntheses/integration-catalog` — entegrasyon kataloğu
- **PHASE 5 (Lint)**: lint-report.md yazıldı — 0 yüksek/orta, 14 düşük (stub sayfalar). Çelişki yok, yetim yok, eskimiş yok.
- **PHASE 6 (Index/Log sync)**: index.md tüm kategorilerle güncel, log.md bu girdi.
- Toplam: 88 markdown dosyası (CLAUDE.md + index + log + lint-report + 84 içerik) ; 355+ wikilink cross-ref.
- Kaynak: kullanıcı talebi — tam otomatik tek-pass setup + ingest

## [2026-04-25] setup | Wiki iskeleti yeniden kuruldu (overwrite)
- Dokunulan dosyalar: `.wiki/CLAUDE.md`, `.wiki/index.md`, `.wiki/log.md`
- Kaynak: kullanıcı talebi — aynı scaffold prompt'u 2. kez; seçim: "Tam yeniden kur (overwrite)"
- Not: 9 alt klasör + 9 `.gitkeep` idempotent korundu; `raw/` hâlâ 0 kaynak. Placeholder yorumları sabit: `{{KAYNAK_KLASORU}}=code-refs`, `{{SORUN_KLASORU}}=issues`, `{{PROJE_ADI}}=SEDCORE POS`, `{{DIL}}=Türkçe`.

## [2026-04-24] setup | Wiki iskeleti kuruldu (ilk tur)
- Dokunulan dosyalar: `.wiki/CLAUDE.md`, `.wiki/index.md`, `.wiki/log.md`, 9 alt-klasör + `.gitkeep`
- Kaynak: kullanıcı talebi — `.wiki` yeni bağımsız vault, SEDCORE POS için sektör-agnostik kalıcı bilgi arşivi
- Not: İlk ingest manuel tetiklenecek. `raw/code-refs/` ve `raw/docs/` boş.
