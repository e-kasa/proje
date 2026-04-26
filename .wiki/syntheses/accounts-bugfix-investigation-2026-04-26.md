---
title: Cari Hesaplar Hot-Fix Araştırması (2026-04-26)
type: synthesis
date: 2026-04-26
status: applied
sprint: 8
purpose: 2 üretim bug'ı (POS müşteri listesi tutarsızlığı + bakiye refresh) için kök neden + uygulanan düzeltmeler
---

# Cari Hesaplar Hot-Fix Araştırması — 2026-04-26

Kullanıcı 2 üretim bug'ı raporladı. İki paralel Explore agent ile keşif yapıldı, kök nedenler tespit edildi, **3 düzeltme uygulandı** (backend compile geçti).

## Bug A — POS Picker vs AccountsHub Müşteri Listesi Tutarsızlığı

### Belirti
POS satış ekranındaki müşteri seçim listesi (Cart Panel `_CustomerPickerSheet`) AccountsHub müşteri listesinden **farklı görünüyor** — yeni eklenen müşteriler veya alt sıralardakiler "kayıp" gibi algılanıyor.

### Kök Neden
İki ekran **farklı endpoint + farklı sayfalama** stratejisi kullanıyor:

| Ekran | Endpoint | Sayfalama | Görünen |
|---|---|---|---|
| Cart Panel | `GET /customers?isActive=true` | YOK (tüm aktif) | 200+ müşteri tek sayfada |
| AccountsHub | `GET /accounts/list?limit=20&...` | Cursor (20/sayfa) | İlk 20, scroll ile devamı |

**Çelişen filtre/auth değil**: ikisi de `isActive=true`, multi-tenant `X-Company-Code` aynı, soft-delete exclude tutarlı. Tek gerçek fark **pagination + endpoint**.

### Uygulanan Düzeltme — D2 (geçici)
[`accounts_list_provider.dart:94`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart#L94): `_pageLimit` 20 → 50. Backend `Math.min(50, limit)` clamp olduğu için max 50.

> **Sprint 9'a kaydı:** POS Cart Panel'i de paginated yapmak — ya scroll/loadMore ekle, ya da `customer_service.getCustomers` sayfalı versiyon. Veya AccountsListController'ın aynısını kullan (tutarlılık).

## Bug B — Bakiye Refresh Etmiyor

### Belirti
Cari hesapta ödeme/tahsilat sonrası **ekranda bakiyeler güncellenmiyor**. Hot reload ile düzeliyor → backend doğru, frontend stale state.

### Kök Nedenler (3 ayrı)

**1. Backend response'da `currentBalance` eksik** ([`AccountStatementControllerImpl.java:77-83`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java#L77-L83)):
- Response'ta `closingBalance` (transaction'lardan hesaplanan running balance) var
- Denormalize `CustomerAccount.currentBalance` (write-through cache değer) **YOK**
- Frontend bu değeri okumadığı için ödeme sonrası ekranda eski değer kalıyor

**2. AutoDispose race condition** ([`statement_detail_panel.dart:211-216`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart#L211-L216)):
- `_handlePayment()` 4 paralel `notifier.load()` çağırıyor; 3'ü `autoDispose` provider
- Modal kapanınca rebuild → 3 provider dispose → state sıfır → race
- `accountsListProvider.notifier.load()` (Sprint 8 alias) bu race'te miss olabilir

**3. Sprint 8 pagination state reset etkileşimi**: `loadFirst()` `all: []` set eder; subscribe timing'inde flickering riski

### Uygulanan Düzeltmeler

**D1 — `ref.invalidate()` ekle** ([`statement_detail_panel.dart`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart)):
```dart
// Eski: 4 paralel load (race adayı)
await Future.wait([accountStatement, accountSummary, accountsList, paymentList].map((p) => p.notifier.load()));

// Yeni: explicit invalidate + 3 load
ref.invalidate(accountsListProvider);  // autoDispose için race-free
await Future.wait([accountStatement, accountSummary, paymentList].map((p) => p.notifier.load()));
```

**D3 — Backend response'a `currentBalance`** ([`AccountStatementEntry.java`](pos-product-manager/src/main/java/com/sedcore/finance/model/AccountStatementEntry.java) + [`AccountStatementControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java)):
- `AccountStatementEntry.currentBalance: BigDecimal` field eklendi
- Controller `customerAccountService.getOrCreate(customer).getCurrentBalance()` (veya supplier eşdeğeri) ile dolduruyor
- Drift fallback: exception olursa `currentBalance = closingBalance`
- Backend compile **exit 0**

> **Frontend görüntüleme** (Sprint 9'a kaydı): `statement_detail_panel.dart` ekstre header'ında `currentBalance` field'ı render etmeli; `closingBalance != currentBalance` durumda drift göstergesi.

## Verification

### Manuel Test (sen yapacaksın)
1. **Bug A**: 30+ müşterili dev DB'de POS satış + AccountsHub yan yana → liste boyutu yakın (limit 50 ↔ Cart sayfasız)
2. **Bug B**: Vadeli müşteriden tahsilat → AccountsHub liste satırında bakiye **anında değişmeli** (hot reload gereksiz)
3. **Backend response**: `curl http://localhost:8080/product/api/v1/account-statements?accountType=CUSTOMER&accountId=X&startDate=...&endDate=...` → JSON response'ta `"currentBalance": ...` field'ı görünmeli

### Otomatik (Sprint 9)
- Widget test: `_handlePayment()` mock backend ile `accountsListProvider` invalidate edildi mi
- Integration test: `accountStatement.currentBalance` ↔ `customerAccount.currentBalance` consistency

## Sources

- Agent A keşfi: POS Cart Panel vs AccountsList endpoint karşılaştırması
- Agent B keşfi: `_handlePayment` autoDispose race + statement response analizi
- Kod referansları: [`cart_panel.dart:262`](project_pos/lib/features/pos/widgets/cart_panel.dart#L262), [`accounts_list_provider.dart`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart), [`statement_detail_panel.dart`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart), [`AccountStatementControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java)
- Plan dosyası: `C:\Users\Win11\.claude\plans\polymorphic-gathering-flute.md` (Sprint 8 hot-fix bölümü)
- İlgili wiki: [[syntheses/sprint-8-implementation-plan-2026-04-26]] (Sprint 8 ana plan), [[concepts/denormalization-with-reconcile]] (currentBalance write-through), [[concepts/drift]] (closingBalance ↔ currentBalance fark = drift sinyali)

## Sprint 9 Hold-overs (kaydı)

- **B0 frontend** — POS Cart Panel paginated; veya AccountsListController kullan
- **D3 frontend** — `statement_detail_panel.dart` `currentBalance` render + drift göstergesi
- **WP2 kalan 2 panel** — `StatementDetailPanel` + `AccountsSummaryBar` `AccountsErrorView` entegrasyonu
- **WP3 testler** — T2-T4 service-level (@SpringBootTest)
- **B6/B8/B9** — yaşlandırma raporu + overdue notification + activity history

## Related

- [[syntheses/sprint-8-implementation-plan-2026-04-26]]
- [[syntheses/accounts-development-analysis-2026-04-25-v2]]
- [[concepts/denormalization-with-reconcile]]
- [[concepts/drift]]
- [[issues/accounts-pagination-missing]] (B0 takibi)
