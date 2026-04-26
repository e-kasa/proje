---
title: Sprint 7 Implementation Plan — Cari İşlemler (B1 + T1-T4 + I2)
type: synthesis
date: 2026-04-25
status: actionable
based-on: syntheses/accounts-development-analysis-2026-04-25-v2
sprint: 7
duration: 1 hafta (~5-6 gün net iş)
purpose: v2 analizindeki Sprint 7 önceliklerini adım adım uygulama planı — dosya yolu + done kriteri + risk + bağımlılık
---

# Sprint 7 Implementation Plan — Cari İşlemler

[[syntheses/accounts-development-analysis-2026-04-25-v2]] Sprint 7'sini somut adımlara böler. Her iş paketi için: açılış checklist, dosya listesi, kabul kriteri, risk, paralellik. Sürekli wiki güncelleme zorunlu (Done kriteri).

## İş Paketi Özeti

| WP | Konu | Efor | Bağımlılık | Hedef Sprint Günü |
|---|---|---|---|---|
| **WP1** | Backend: PaymentAllocation entity + service | 1 gün | — | 1-1.5 |
| **WP2** | Backend: T1-T4 kritik path testleri | 1.6 gün | WP1 (kısmi) | 1.5-3 (WP1 ile paralel) |
| **WP3** | Frontend: Service + provider katmanı | 0.5 gün | WP1 | 3 |
| **WP4** | Frontend: PaymentRecordModal — sale picker | 1 gün | WP3 | 3.5-4.5 |
| **WP5** | Frontend: i18n + error boundary (I2) | 1.5 gün | bağımsız | 4.5-6 |
| **WP6** | Wiki + smoke test | 0.5 gün | hepsi | 6 |

**Net iş: ~6 gün** + buffer. B5 (hızlı tahsilat butonu) opsiyonel — buffer'a sığarsa.

---

## WP1 — Backend: PaymentAllocation Entity (1 gün)

[[syntheses/accounts-development-analysis-2026-04-25-v2#4-b1-yeniden-tasarımı--paymentallocation-baştan-c4-düzeltme]] gereği many-to-many tasarım baştan.

### Açılış Checklist
- [ ] Mevcut [`Payment.java:41`](pos-product-manager/src/main/java/com/sedcore/finance/entity/Payment.java#L41) `saleId` FK'sini deprecated/kaldırılacak işaretle (ama kaldırma — geriye uyum için kalsın geçiş süresince)
- [ ] [`PaymentRequest.saleId`](pos-product-manager/src/main/java/com/sedcore/finance/model/PaymentRequest.java#L33) deprecated → yerine `List<AllocationRequest> allocations`

### Yeni Dosyalar

**`pos-product-manager/src/main/java/com/sedcore/finance/entity/PaymentAllocation.java`**
```java
@Entity
@Table(name = "payment_allocations",
       indexes = {
         @Index(name="idx_pa_payment", columnList="payment_id"),
         @Index(name="idx_pa_sale", columnList="sale_id"),
         @Index(name="idx_pa_company", columnList="company_code")
       })
public class PaymentAllocation extends TOpenSimpleCompanyEntity {
    @ManyToOne(fetch=LAZY) @JoinColumn(name="payment_id", nullable=false)
    private Payment payment;

    @ManyToOne(fetch=LAZY) @JoinColumn(name="sale_id")  // nullable: "genel ödeme"
    private Sale sale;

    @Column(precision=15, scale=2, nullable=false)
    private BigDecimal amount;

    @Column(name="allocated_at", nullable=false)
    private LocalDateTime allocatedAt;

    @Version
    private Long version;  // ⚠️ data.sql seed yazılırsa version=0 zorunlu
}
```

**`pos-product-manager/.../finance/repository/PaymentAllocationRepository.java`**
- `findByPaymentId(String paymentId)`
- `findBySaleId(String saleId)`
- `sumBySaleId(String saleId)` — Sale.paidAmount = SUM(allocations.amount)

**`pos-product-manager/.../finance/model/AllocationRequest.java`**
```java
@Data
public class AllocationRequest {
    private String saleId;  // null = genel ödeme
    private BigDecimal amount;
}
```

### Mevcut Dosya Değişimleri

**`PaymentServiceImpl.java`** — `createPayment()` içinde:
1. Payment insert sonrası `request.allocations` boşsa: 1 allocation oluştur (`sale=null, amount=payment.amount`) → "genel ödeme"
2. Doluysa: her birini insert et, toplam = payment.amount kontrolü
3. Geriye uyum: `request.saleId` doluysa allocation listesine 1 öğe ekle

**`SaleServiceIntegrated.java`** veya yeni helper:
- `recalculateSalePaidAmount(saleId)` — `paidAmount = SUM(PaymentAllocation.amount WHERE sale_id=X)` → `Sale` denormalize update

### Migration — `pos-product-manager/src/main/resources/data.sql`
- Yeni tablo Hibernate `ddl-auto=create` ile otomatik oluşur
- **Mevcut Payment kayıtları için backfill**: data.sql'de `INSERT INTO payment_allocations SELECT ... FROM payments WHERE sale_id IS NOT NULL` (her payment için 1 allocation)
- ⚠️ Memory'deki `project_ddl_strategy.md` 3. tuzak: `version=0` set et insert'te

### Done Kriteri (WP1)
- 🟢 Kod build geçer (`mvn clean compile`)
- 🟢 Repository unit test (CRUD)
- 🟢 Service test: createPayment → 1 allocation oluşturur (genel ödeme); allocation listesi ile çağrı → N allocation
- 🟢 Migration: pre-existing 5 Payment kaydı için 5 allocation oluşturulur
- 🟢 Wiki: `entities/payment-allocation.md` + `concepts/payment-allocation-pattern.md` yazıldı
- 🟢 ADR: `decisions/payment-allocation-from-day-1.md` (B1↔B3 bağımlılık kararı)

### Risk
- **R-WP1**: PaymentAllocation insert sırasında `Payment.companyCode` kopyalanmazsa multi-tenant filter kırılır → `prepareAndSave()` helper kullan ([`SaleServiceIntegrated.java:416`](pos-product-manager/src/main/java/com/sedcore/sales/service/impl/SaleServiceIntegrated.java#L416))
- **R-WP1**: `Sale.paidAmount` denormalize artık SUM allocations → reconcile job (`ReconcileScheduledJob`) güncellemeli, T2 testi bunu kapsasın

---

## WP2 — Backend: T1-T4 Kritik Path Testleri (1.6 gün)

[[syntheses/accounts-development-analysis-2026-04-25-v2#2-test-stratejisi-c1-düzeltme--yeni-p1]]

### Test Dosyaları

**T1 — `pos-product-manager/src/test/java/.../finance/PaymentCreationIntegrationTest.java`** (0.5 gün)
- `createPayment_happyPath_singleAllocation` — saleId verilmiş, 1 allocation oluştu
- `createPayment_happyPath_multiAllocation` — 2 satışa böl, allocation count=2, sum=payment.amount
- `createPayment_genericPayment_nullSaleAllocation` — allocation listesi boş, 1 null-sale allocation
- `createPayment_idempotent` — aynı request 2x → tek payment (idempotency key kontrolü)
- `createPayment_invalidAllocation_sumMismatch` → 400

**T2 — `pos-product-manager/src/test/java/.../finance/ReconcileDriftDetectionTest.java`** (0.5 gün)
- `reconcile_detectsDrift_whenDenormalizeManuallyChanged` — `CustomerAccount.currentBalance` SQL ile bozuldu → reconcile çağır → drift saptandı, fix uygulandı, `ReconcileAuditLog` yazıldı
- `reconcile_idempotent_noDriftNoOp` — drift yok → audit log boş, denormalize değişmedi

**T3 — `pos-product-manager/src/test/java/.../sales/CreditLimitGuardTest.java`** (0.3 gün)
- `checkCreditLimit_belowLimit_passes`
- `checkCreditLimit_atLimit_passes`
- `checkCreditLimit_overLimit_throws`
- `checkCreditLimit_zeroLimit_skipped` (limit=0 → kontrol yok)
- `checkCreditLimit_overrideRole_bypasses` ([[decisions/credit-limit-override-role-based]])

**T4 — `pos-product-manager/src/test/java/.../finance/SalePaymentFkIntegrityTest.java`** (0.3 gün)
- `cancelSale_existingPayments_preventOrLogDrift` — cancel sonrası ne olur? (kararlı davranış doğrula)
- `partialPayment_remainingAmountCorrect` — Sale.totalAmount=1000, allocation=300 → remainingAmount=700
- `multiplePayments_sumEqualsPaidAmount` — 3 farklı payment, Sale.paidAmount = SUM allocations

### Done Kriteri (WP2)
- 🟢 Tüm 4 test green (CI)
- 🟢 Test coverage raporu: finance package %50+ (kritik path)
- 🟢 PR template'e checklist: "Finance modülü değişikliği var mı? → kritik path testi yazıldı/güncellendi"
- 🟢 Wiki: [[issues/test-coverage-unknown]] güncellensin (P1 → kritik path COMPLETED, geniş kapsam P2'de devam)
- 🟢 Yeni `concepts/finance-test-strategy.md` sayfası

### Risk
- **R-WP2**: Test DB Spring Boot @SpringBootTest yavaş → @DataJpaTest + Testcontainers tercih
- **R-WP2**: Reconcile job test'i transactional rollback ile kirlenir → test scope izolasyonu

---

## WP3 — Frontend: Service + Provider (0.5 gün)

### Dosya Değişimleri

**[`payment_service.dart`](project_pos/lib/features/accounts/services/payment_service.dart)** — generic `Map<String,dynamic>` olduğu için backend değişikliği frontend'i kırmaz, ama tip güvenliği için yeni helper:
```dart
Future<Map<String, dynamic>> createPaymentWithAllocations({
  required String customerId,
  required double amount,
  required String paymentType,
  String? bankName,
  String? referenceNo,
  String? description,
  required List<AllocationData> allocations,
}) async { ... }
```

**Yeni: `project_pos/lib/features/accounts/providers/customer_open_sales_provider.dart`**
```dart
@riverpod
Future<List<Map<String, dynamic>>> customerOpenSales(
  CustomerOpenSalesRef ref, String customerId,
) async {
  final sales = await ref.read(salesServiceProvider).getSales(
    customerId: customerId, paymentStatus: 'pending');
  return sales..sort((a, b) => DateTime.parse(b['saleDate'])
      .compareTo(DateTime.parse(a['saleDate'])));  // yeniden eskiye
}
```

> Sıralama yeniden→eskiye (kullanıcı son satışı önce görür). FIFO için tersine çevrilebilir, opsiyonel.

### Done Kriteri (WP3)
- 🟢 Service helper eklendi
- 🟢 Provider yazıldı, refresh test edildi
- 🟢 Wiki: scoped wiki entity sayfası (`accounts-notifiers.md` veya yeni `customer-open-sales-provider.md`) güncel

---

## WP4 — Frontend: PaymentRecordModal Sale Picker (1 gün)

[`payment_record_modal.dart`](project_pos/lib/features/accounts/screens/payment_record_modal.dart) güncelleme.

### UI Yapısı

```
┌─ Payment Modal ───────────────────────────────────┐
│ [Account adı]                                      │
│                                                    │
│ Tutar: [____________]                              │
│ Ödeme türü: [CASH ▼]                              │
│ ...                                                │
│                                                    │
│ ── Hangi alışverişe? ────────────────────────────  │
│ ◉ Genel ödeme (cari bakiyeye)                     │
│ ○ Belirli alışverişe                              │
│   ├─ [Yükleniyor...] / [Açık alışveriş yok]      │
│   └─ Liste:                                        │
│      ☑ #POS-20260420-A1B2C3 · 850 TL kalan ·     │
│        20 Nisan · "Plaka: 34ABC123 ..."           │
│      ☐ #POS-20260418-X9Y8Z7 · 450 TL kalan       │
│   [+ Başka satış ekle (Sprint 8)]  ← disabled    │
│                                                    │
│ Plaka, Açıklama, vb. (mevcut)                     │
│                                                    │
│ [İptal] [Kaydet]                                   │
└────────────────────────────────────────────────────┘
```

### State Genişlemesi

```dart
class _PaymentRecordContentState extends ConsumerState<...> {
  String? _customerId;  // widget'ta param olarak gelir
  String _allocationMode = 'GENERAL';  // 'GENERAL' | 'SPECIFIC'
  String? _selectedSaleId;
  double? _selectedSaleRemaining;

  ...

  void _onSaleSelected(Map<String, dynamic> sale) {
    setState(() {
      _selectedSaleId = sale['id'];
      _selectedSaleRemaining = (sale['remainingAmount'] as num).toDouble();
      _amountCtrl.text = _selectedSaleRemaining!.toStringAsFixed(2);
    });
  }
}
```

### Submit Map'i

```dart
final allocations = _allocationMode == 'SPECIFIC' && _selectedSaleId != null
  ? [{'saleId': _selectedSaleId, 'amount': double.parse(_amountCtrl.text)}]
  : [{'saleId': null, 'amount': double.parse(_amountCtrl.text)}];

Navigator.pop(context, {
  'amount': double.parse(_amountCtrl.text),
  'paymentType': _paymentType,
  'bankName': ..., 'referenceNo': ..., 'description': desc,
  'allocations': allocations,
  // Geriye uyum: saleId sadece tek allocation varsa
  'saleId': _selectedSaleId,
});
```

### Caller Güncelleme

`statement_detail_panel.dart` `_handlePayment()` çağrısında `customerId` aktarmalı:
```dart
final result = await PaymentRecordModal.show(
  context, isCustomer: ..., accountName: selected.accountName,
  customerId: selected.accountId,  // NEW
);
```

### Done Kriteri (WP4)
- 🟢 Modal yeni section ile çalışıyor
- 🟢 customerId null ise picker hidden (geriye uyum)
- 🟢 `flutter analyze` 0 warning
- 🟢 Manuel test: 3 farklı müşteriye 5 ödeme akışı (genel + spesifik mix) → backend'de allocation kayıtları doğru
- 🟢 Wiki: scoped `entities/payment-record-modal.md` (yeni veya güncel) yazıldı

### Risk
- **R-WP4**: Açık satış listesi >20 olursa modal yüksekliği bozulur → max 5 göster + "Tümü"nü göster butonu (B0 pagination önce gerekirse)
- **R-WP4**: customerId tip uyumsuzluğu (backend String, Flutter int) — sales_service.dart'ta `int? customerId` var ama gerçek backend String UUID → düzelt

---

## WP5 — Frontend: i18n + Error Boundary (1.5 gün)

### i18n — `security/src/main/resources/data.sql`

Yeni anahtarlar (TR + EN):
```
accounts.payment_target              → "Hangi Alışverişe?" / "Payment Target"
accounts.general_payment             → "Genel ödeme (cari bakiyeye)" / "General payment"
accounts.specific_sale_payment       → "Belirli alışverişe" / "Specific sale"
accounts.no_open_sales               → "Açık alışveriş yok" / "No open sales"
accounts.sale_remaining              → "kalan" / "remaining"
accounts.add_another_sale            → "Başka satış ekle (yakında)" / "Add another sale (coming soon)"
accounts.allocation_sum_mismatch     → "Toplam tutarlar eşleşmiyor" / "Allocation totals don't match"
```

7 anahtar × 2 dil = 14 satır data.sql ekleme. ID'ler `bnd-XXNNN-...` formatında (modül kodu açıklama için ai17-ai23 önerisi).

### Error Boundary (I2)

Yeni: `project_pos/lib/features/accounts/widgets/accounts_error_boundary.dart`
```dart
class AccountsErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? fallbackMessage;
  ...
  @override
  Widget build(BuildContext context) {
    return ErrorWidgetBuilder(
      builder: (error, stack) => _buildFallback(error),
      child: child,
    );
  }
}
```

Kullanım: `AccountsHubScreen` içinde `Expanded(child: AccountsErrorBoundary(child: AccountsListPanel(...)))`

Pattern: provider hatası (`AsyncValue.error`) yakalanır, kullanıcıya retry butonu + log AppLogger.error.

### Done Kriteri (WP5)
- 🟢 7 i18n anahtarı backend'de seed
- 🟢 `i18nOf(ref)('accounts.payment_target')` Flutter'da resolve oluyor
- 🟢 ErrorBoundary 3 yerde kullanılıyor: AccountsListPanel, StatementDetailPanel, AccountsSummaryBar
- 🟢 Manuel hata enjeksiyonu: backend 500 → ekran patlamıyor, retry button çalışıyor
- 🟢 Wiki: `entities/accounts-error-boundary.md` yazıldı

---

## WP6 — Wiki + Smoke Test (0.5 gün)

### Wiki Güncelleme (Done kriterlerinin parçası, ama final pass)

| Sayfa | Eylem |
|---|---|
| `entities/payment-allocation.md` | YENİ |
| `concepts/payment-allocation-pattern.md` | YENİ |
| `decisions/payment-allocation-from-day-1.md` | YENİ ADR |
| `concepts/finance-test-strategy.md` | YENİ |
| `decisions/test-required-for-finance-merge.md` | YENİ ADR |
| `entities/accounts-error-boundary.md` | YENİ |
| `entities/payment.md` | UPDATE — saleId deprecated, allocations önerilir |
| `entities/sale.md` | UPDATE — paidAmount derived from PaymentAllocation |
| `entities/payment-record-modal` | YENİ ana wiki entity (sadece scoped'da vardı) |
| [[issues/test-coverage-unknown]] | UPDATE — P1 status + WP2 sonucu |
| `index.md` | yeni 5+ link |
| `log.md` | sprint 7 entry |

### Smoke Test (gerçek DB, real data)

1. Bir vadeli müşteri seç → AccountsHub
2. Tahsilat butonu → Modal aç
3. customerId loaded → "Açık Alışverişler" listesi görünür
4. Satış seç → tutar otomatik 850
5. Tutar elle değiştir → 500 (kısmi ödeme)
6. Kaydet
7. Backend log: `Payment {amount:500}`, `PaymentAllocation {sale_id:X, amount:500}`, `AccountTransaction {sale_id:X, debit:0, credit:500}`
8. Statement panel'i yenile → yeni Payment görünür, ekstrede satışın `remainingAmount=350`
9. Reconcile job'u manuel çalıştır → drift = 0 (allocation sum doğru hesaplandı)
10. v2'deki R6 (PaymentAllocation → reconcile job) doğrula

### Done Kriteri (WP6)
- 🟢 Tüm Sprint 7 madde checkbox doldu
- 🟢 Smoke test full akış geçti
- 🟢 `git status` temiz, tek commit `feat(accounts): sale-payment allocation many-to-many + critical path tests + error boundary`
- 🟢 PR açıldı, T1-T4 CI'da geçti

---

## Paralellik Diyagramı

```
Gün:    1   2   3   4   5   6
WP1:    ████████░░
WP2:        ░░██████░░
WP3:                ████░░
WP4:                    ████████░░
WP5:                ░░░░██████████   (bağımsız, ne zaman olsa)
WP6:                            ░░██
```

- WP1 + WP2 paralel (WP2 WP1 kısmen biten kısmı test eder)
- WP3 sıkı sıralı WP1 sonrası
- WP4 sıkı sıralı WP3 sonrası
- WP5 bağımsız — Gün 3+ herhangi yerde
- WP6 son

## Risk Konsolide Matrisi

| Risk | WP | Önlem |
|---|---|---|
| R-WP1 (companyCode kopyalanmaz) | 1 | `prepareAndSave()` helper kullan |
| R-WP1 (reconcile job güncellenmez) | 1 | T2 testi reconcile + allocation kapsamına |
| R-WP2 (test DB yavaş) | 2 | @DataJpaTest + Testcontainers |
| R-WP4 (modal liste taşması) | 4 | Max 5 + "Tümü" buton (Sprint 8'e atılabilir) |
| R-WP4 (customerId tip uyumsuzluğu) | 4 | sales_service.dart `customerId` String'e güncelle |
| R-WP5 (i18n cache invalidation) | 5 | Manuel `loadTranslations()` çağırılır (root CLAUDE.md drift'i, ayrı task) |

## Bağımlılıklar (v2 R1-R6 referansı)

- B1↔B3: PaymentAllocation many-to-many ✅ (WP1'de baştan çözüldü)
- T1-T4: B1 ile zorunlu ✅ (WP2)
- I2: B0 (pagination) öncesi ✅ (WP5'te aynı sprint)
- B6 (yaşlandırma) → B8 (notification): bu sprint scope dışı, Sprint 8

## Açık Karar Noktaları (PR review'da)

1. Açık satış listesi sıralama: yeniden→eskiye (default) vs FIFO toggle
2. Bölünmüş ödeme (B3) için "+ satış ekle" butonu Sprint 7'de disabled mı, hidden mi (UI hint vs sürpriz)
3. PaymentRequest geriye uyum: `saleId` deprecated yorumu mu, hard-removal mı (1 sprint mi 2 sprint mi geçiş)
4. Test DB stratejisi: H2 (hızlı) vs Postgres Testcontainers (gerçekçi) — finance için Postgres öneriyorum

## Çıkış Kontrolü

Sprint 7 sonu kullanıcıya rapor:
- 13/13 done kriteri ✅
- Wiki sayfa sayısı: önceki + 6 yeni
- CI metrik: finance test coverage %0 → %X
- Demo: 5 dakika smoke test video/GIF

## Sources

- [[syntheses/accounts-development-analysis-2026-04-25-v2]] — Sprint 7 önceliği + B1 yeniden tasarım
- [[syntheses/accounts-development-analysis-2026-04-25]] (v1) — sprint tarihçesi (superseded)
- [[entities/payment]], [[entities/sale]], [[entities/customer-account]]
- [[decisions/credit-limit-override-role-based]] (T3 testi için)
- [[concepts/drift]], [[decisions/idempotent-reconcile-no-op-guard]] (T2 testi için)
- Memory: `project_ddl_strategy.md` (PaymentAllocation seed `version=0` zorunlu)
- Kod: [`PaymentServiceImpl.java`](pos-product-manager/src/main/java/com/sedcore/finance/service/impl/PaymentServiceImpl.java), [`payment_record_modal.dart`](project_pos/lib/features/accounts/screens/payment_record_modal.dart), [`sales_service.dart`](project_pos/lib/features/sales/services/sales_service.dart)

## Related

- [[syntheses/accounts-development-analysis-2026-04-25-v2]] (parent — neden + öncelik)
- [[syntheses/accounts-hub-production-readiness]] (üst yapı)
- [[syntheses/lint-action-plan-2026-04-25]] (paralel iş — wiki sağlık)
- [[issues/test-coverage-unknown]] (WP2 ile P1 status update)
