---
title: SEDCORE POS — Ekran Aksiyonları & Bütünsel Geliştirme Planı
type: source
source: .claude/plans/development-features-roadmap.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# SEDCORE POS — Ekran Aksiyonları & Bütünsel Geliştirme Planı

**Tarih:** 2026-04-23  
**Durum:** Çalışma Halinde (Sprint 1 devam)  
**Son Güncelleme:** Otomatik oluşturuldu

---

## BÖLÜM 1: EKRAN AKSIYON MATRİSİ

Her modülün ekranları, ana aksiyonları ve geliştirilme durumu.

### 1.1 — Auth Modülü (`features/auth`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Login** | Giriş yapı, "Şifremi unuttum", Company seç | ✅ Tamamlandı | Spor 0 |
| **Register** | Yeni firma kaydı, Sector seç | ✅ Tamamlandı | Sprint 0 |
| **2FA** | SMS doğrulama, Token gönder | 🔄 Planlı | Sprint 2 |

---

### 1.2 — Dashboard & Menu Modülü (`features/dashboard`, `features/menu`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Dashboard** | Widget'lar: Satış özeti, Stok uyarıları, Tedarikçi bakiye | ✅ Tamamlandı | Sprint 0 |
| **Sidebar Menu** | Role-based menu, i18n labels | ✅ Tamamlandı | Sprint 0 |
| **Settings** | Locale seç (TR/EN), Theme, User profile | 🔄 Kısmi | Sprint 1 |

---

### 1.3 — POS (Satış) Modülü (`features/pos`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **POS Main** | Barcode tarama, Ürün ara, Sepete ekle, Fiyat override | 🔄 Devam | Sprint 1 |
| **Sale Cart** | Miktar düzenle, İndirim, Hazır indirim paketi, Ödeme türü seç | 🔄 Devam | Sprint 1 |
| **Payment** | Nakit / Kart / Çek / Cari hesap, Para üstü hesapla | 🔄 Devam | Sprint 1 |
| **Sale Receipt** | Fatura yazdır (PDF), E-posta gönder, SMS gönder | ⚠️ Yapılmadı | Sprint 2 |
| **Sale Returns** | İade seç, Quantty, Sebep, Onay | ⚠️ Yapılmadı | Sprint 2 |

---

### 1.4 — Toplu Ürün Girişi Modülü (`features/inventory/batch_entry`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Batch Header** | Supplier seç, Invoice no, Delivery note no, Store, Warehouse, Date | 🔄 Devam | Sprint 1 |
| **Batch Rows** | Barcode tarama, Manual row, OEM seç, Quantity, Price | 🔄 Devam | Sprint 1 |
| **Variant Form** | Size/Color select, Barcode per variant, Price override | ✅ Tamamlandı | Sprint 1 |
| **PDF Upload** | Fatura PDF yükle, Extract lines, Match products | 🔴 Yapılmadı | Sprint 1 |
| **Result Sheet** | Success / Error row'lar, Retry failed | 🔴 Yapılmadı | Sprint 1 |
| **Product Entry Table** | Desktop modunda tablo view (Excel benzeri) | ⚠️ Dead code | Sprint 2 |

---

### 1.5 — Ürün Kataloğu Modülü (`features/catalog`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Product List** | Arama, Filtre (kategori/marka), Sıralama | ✅ Tamamlandı | Sprint 0 |
| **Product Detail** | Variant listesi, Pricing, Barcode, OEM, Cross-ref | ✅ Tamamlandı | Sprint 0 |
| **Add Product Wizard** | Ürün tipi seç, Kategori, Marka, Variant, Pricing | 🔄 Devam | Sprint 1 |
| **Variant Management** | Variant ekle/düzenle, Attribute set, Barcode assign | ✅ Tamamlandı | Sprint 1 |
| **Category Manager** | Kategori listesi, Attribute tanımla, Category-Product map | ⚠️ Yapılmadı | Sprint 2 |

---

### 1.6 — Stok Modülü (`features/stock`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Stock Level** | Variant başına Store+Warehouse, Real-time bakiye | ✅ Tamamlandı | Sprint 0 |
| **Stock Movement** | Hareket listesi (Purchase/Sale/Adjustment), Trendler | 🔄 Kısmi | Sprint 1 |
| **Stock Adjustment** | Manual adjust, Sebep, Approval flow | ⚠️ Yapılmadı | Sprint 2 |
| **Stock Alert** | Minimum level warning, Reorder suggestion | ⚠️ Yapılmadı | Sprint 2 |
| **Stock Transfer** | Depo ↔ Mağaza, Approval | ⚠️ Yapılmadı | Sprint 3 |

---

### 1.7 — Satın Alma Modülü (`features/purchases`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Purchase List** | Filtre (Status, Supplier, Date), Sıralama | ✅ Tamamlandı | Sprint 0 |
| **Purchase Detail** | Items, Total, Status, Approval | ✅ Tamamlandı | Sprint 0 |
| **Purchase Entry** | Ürün seç (catalog), Quantity, Unit price, Tax rate | 🔄 Batch'ye taşındı | Sprint 1 |
| **GRN (Goods Receipt)** | Batch entry → GRN generasyon otomatik | 🔄 Devam | Sprint 1 |

---

### 1.8 — Tedarikçi Modülü (`features/suppliers`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Supplier List** | Arama, Active/Inactive, Contact, Account balance | ✅ Tamamlandı | Sprint 0 |
| **Supplier Account** | Payable balance, Payment history, Terms | 🔄 Kısmi | Sprint 1 |
| **Supplier Payment** | Ödeme kaydı (Nakit/Transfer), Partial payment | ⚠️ Yapılmadı | Sprint 2 |
| **Upload & Merge** | CSV yükle, Duplicate check, Bulk update | ⚠️ Yapılmadı | Sprint 3 |

---

### 1.9 — Müşteri Modülü (`features/customers`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Customer List** | Arama, Credit limit, YTD satış | ✅ Tamamlandı | Sprint 0 |
| **Customer Account** | Receivable balance, Payment history, Credit terms | 🔄 Kısmi | Sprint 1 |
| **Customer Payment** | Ödeme kaydı, Partial payment, Netting | ⚠️ Yapılmadı | Sprint 2 |
| **Credit Management** | Limit set, Suspension, Approval flow | ⚠️ Yapılmadı | Sprint 3 |

---

### 1.10 — Raporlar Modülü (`features/reports`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **Sales Report** | Date range, Product/Category filter, Revenue trend | 🔄 Kısmi | Sprint 1 |
| **Purchase Report** | Supplier filter, Cost analysis | 🔄 Kısmi | Sprint 1 |
| **Inventory Report** | Stock valuation, Slow-moving items, ABC analysis | ⚠️ Yapılmadı | Sprint 2 |
| **Account Receivable Aging** | 30/60/90 day buckets, Collection list | ⚠️ Yapılmadı | Sprint 2 |
| **Account Payable Aging** | Payment due, Early payment discount | ⚠️ Yapılmadı | Sprint 2 |

---

### 1.11 — OEM / Araç Uyumluluk Modülü (`features/autoparts`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **OEM Number Search** | OEM no girgile, Match parts, Suppliers | 🔄 Kısmi | Sprint 1 |
| **Vehicle Search** | Marka/Model/Yıl seç, Compatible parts | ⚠️ Yapılmadı | Sprint 2 |
| **Cross Reference** | OEM ↔ Brand mapping, Compatibility matrix | ⚠️ Yapılmadı | Sprint 2 |
| **Vehicle DB Update** | Admin: Make/Model listeleri update | ⚠️ Yapılmadı | Sprint 3 |

---

### 1.12 — Yönetim & Ayarlar Modülü (`features/settings`)

| Ekran | Aksiyonlar | Durum | Sprint |
|-------|-----------|--------|--------|
| **User Management** | Yeni user, Role assign, Store assign | ⚠️ Kısmi | Sprint 1 |
| **Role & Permission** | Role oluştur, Permission assign | ⚠️ Backend var, UI yok | Sprint 2 |
| **Store/Warehouse** | Lokasyon oluştur, Code assign | ✅ Backend | Sprint 1 |
| **Tax Configuration** | Tax rate (18%, 8%, 0%), Special taxes | ⚠️ Yapılmadı | Sprint 2 |
| **Sequence Number** | Invoice/Purchase sequence setup | ⚠️ Yapılmadı | Sprint 3 |

---

## BÖLÜM 2: BÜTÜNSEL İŞ AKIŞLARI (END-TO-END FLOWS)

### Flow A: Tedarikçiden Ürün Alımı → Stok Güncelleme

```
┌─────────────────────────────────────────────────┐
│ 1. BATCH ENTRY SCREEN (Kasiyerin İşi)          │
│    - Header: Supplier, Invoice, Date, Store     │
│    - Rows: Barcode tara / Manual / PDF upload   │
│    - Submit: BatchCreateRequest                 │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│ 2. POST /product/api/v1/products/batch          │
│    Backend: Ürün oluştur, Variant oluştur       │
│    → StockLevel update, Purchase record create  │
│    → BatchCreateResponse { results[] }          │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│ 3. Result Sheet (Frontend)                      │
│    - Show success rows (saved, product ID)      │
│    - Show error rows (missing category, etc)    │
│    - Retry button for failed items              │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│ 4. Stock Level Updated                          │
│    - Variant_Quantity[Store-01, Variant-XYZ]   │
│    - Supplier Account: Payable += total         │
└─────────────────────────────────────────────────┘
```

**Kritik Aksiyonlar:**
- Batch header validasyon (supplier required, store required)
- Barcode/OEM match (system lookup)
- Category match (user approval veya auto-assign)
- Unit/Tax rate extract (PDF'den veya manual)
- Concurrent stock update (@Version, optimistic lock)

---

### Flow B: POS Satış

```
┌──────────────────────────────────────────────┐
│ 1. POS SCREEN (Kasiyerin İşi)               │
│    - Barcode tara / Manual arama             │
│    - Sepete ekle, Quantity düzenle           │
│    - Discount ekle, Payment method seç       │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ 2. POST /product/api/v1/sales                │
│    Backend: Sale record, SaleItems, Tax calc │
│    → StockLevel decrement (@Version)         │
│    → CustomerAccount update (if credit)      │
│    → Receipt generate                        │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ 3. Receipt Screen                            │
│    - Invoice no, Total, Tax, Change          │
│    - Print / Email / SMS                     │
│    - Save or new sale                        │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ 4. Stock + Customer Account Updated           │
│    - Inventory: real-time reduced            │
│    - AR: customer balance updated            │
└──────────────────────────────────────────────┘
```

**Kritik Aksiyonlar:**
- Stock availability check (prevent oversell)
- Real-time price lookup (tier pricing, promo)
- Tax calculation (category/tax rate)
- Customer credit check (AR limit)
- Concurrent stock + AR update

---

### Flow C: PDF Fatura Analizi (Sprint 1 — Devam)

```
┌──────────────────────────────────────────────┐
│ 1. BATCH SCREEN: PDF Upload                  │
│    - File picker, Validation (format, size)  │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ 2. POST /product/api/v1/documents/upload     │
│    Backend: PDFBox extract                   │
│    → Lines:  [Name, Unit, Qty, Price, Tax%] │
│    → Header: [InvoiceNo, Date]               │
│    → Response: DocumentItemResult[]          │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ 3. Batch Screen: Merge PDF Results           │
│    - Product name match → existing product   │
│    - Unit/Tax/Price populate row             │
│    - User review + approve                   │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ 4. Standard Batch Flow (Flow A)              │
│    - submitAll() → BatchCreateRequest        │
└──────────────────────────────────────────────┘
```

**Kritik Aksiyonlar (Sprint 1 Eksik):**
- ❌ Backend: KDV oranı extract (text detection)
- ❌ Backend: Birim extract ("ADET", "KG" vb.)
- ❌ Backend: Fatura başlığı extract (invoice no, date)
- ❌ Frontend: PDF loading spinner
- ❌ Frontend: NAME match confirmation dialog
- ❌ Frontend: Error handling (unsupported format, corrupted)

---

## BÖLÜM 3: VERI İLİŞKİLERİ & TENANT CONTEXT

### 3.1 — Tenant Akışı

```
Login (Email + Password)
  ↓ JWT Token (JWT decode: userId, companyCode)
  ↓
ApiClient Interceptor: X-Company-Code header
  ↓
Backend Filter: @Filter("filterCompany") — WHERE company_code = ?
  ↓
All queries TENANT-SCOPED
```

**Kritik:** `companyCode` JWT'den gelir, controller'da **yazılmaz**.  
`UserDefAccess` query: `findByUserDefAndCompanyCode(user, user.getCompanyCode())`

---

### 3.2 — Domain Hiyerarşisi (Çok Kiracı)

```
Company
  ├─ Users (UserDef, UserRole)
  │   └─ UserDefAccess (Store assign)
  │
  ├─ Catalog
  │   ├─ Category (GLOBAL, but CompanyCategory maps it)
  │   └─ CategoryAttribute
  │
  ├─ Products
  │   ├─ ProductVariant
  │   │   ├─ Barcode
  │   │   ├─ OemNumber
  │   │   ├─ CrossReference
  │   │   ├─ VehicleCompatibility
  │   │   └─ VariantPricing
  │   └─ ProductImage
  │
  ├─ Locations
  │   ├─ Store (code: "STORE-01")
  │   └─ Warehouse (code: "WH-01")
  │
  ├─ Suppliers
  │   ├─ Supplier
  │   └─ SupplierAccount (@Version — concurrent safe)
  │
  ├─ Customers
  │   ├─ Customer
  │   └─ CustomerAccount (@Version)
  │
  ├─ Transactions
  │   ├─ Purchase
  │   │   └─ StockMovement
  │   │
  │   ├─ Sale
  │   │   ├─ SaleItem
  │   │   └─ StockMovement
  │   │
  │   └─ StockLevel (locationId + variantId, @Version)
  │
  └─ Reports
      ├─ SalesReport
      ├─ PurchaseReport
      └─ InventoryReport
```

**Lokasyon Standardı (2026-04-13 karar):**
```dart
'locationId':   'STORE-01' // Store.code veya Warehouse.code
'locationType': 'STORE'    // 'STORE' | 'WAREHOUSE'
```

NOT: User.storeId hâlâ mevcut (kasiyerin mağazası), ama stok hareketleri `locationId + locationType` kullanır.

---

## BÖLÜM 4: TEKNIK SENARYOLAR (SPRINT BAZLI)

### Sprint 1 — PDF Analizi (Devam)

**Durum:** PDFBox base infrastructure ✅, Flutter upload button ✅, backend endpoint ✅  
**Eksik:**

| Senaryo | Teknik Aksiyonlar | Önem |
|---------|------------------|------|
| **Extract VAT Rate** | Text detection "KDV %18", "KDV %8" → enum → `DocumentItemResult.vatRate` | 🔴 BLOCK |
| **Extract Unit** | "ADET", "KG", "MT" regex → `DocumentItemResult.unit` | 🔴 BLOCK |
| **Extract Invoice Header** | Invoice No, Date → PDF metadata/text → Response wrapper | 🔴 BLOCK |
| **Loading Dialog** | Flutter: FutureBuilder → showDialog(CircularProgressIndicator) | 🟠 NICE |
| **Product Name Match** | Frontend: Extracted name vs. System product list → confirmation UI | 🟠 NICE |
| **Error Handling** | Invalid PDF format, corrupted file, unsupported structure → Toast | 🟠 NICE |
| **Concurrent Update** | StockLevel @Version → optimistic lock retry | 🔴 BLOCK |

**Tahmini Çalışma:** 15-20 saat (backend 10h, frontend 5-8h, test 2-3h)

---

### Sprint 2 — Optimistic Locking & Advanced Features

| Senaryo | Teknik Aksiyonlar | Önem |
|---------|------------------|------|
| **Optimistic Locking (@Version)** | Hibernate @Version → StockLevel, SupplierAccount, CustomerAccount | 🔴 CRITICAL |
| **Redis Cache** | Category, Brand, Unit listleri → TTL 1 hour | 🔴 CRITICAL |
| **Async PDF Analysis** | Backend: Batch endpoint → async job (JobName, polling) | 🟠 IMPORTANT |
| **Tesseract OCR** | Fallback: PDFBox fails → Tesseract (scanned PDF) | 🟠 IMPORTANT |
| **WebSocket Stock Alert** | Backend: Publish `/topic/stock/{companyCode}` | 🟠 IMPORTANT |
| **Tax Rate per Category** | Product.category → default tax rate | 🟠 NICE |
| **Desktop Table (product_entry_table.dart)** | Web: responsive table, row edit inline | 🟠 NICE |

---

### Sprint 3 — Architecture Migration

| Senaryo | Teknik Aksiyonlar | Önem |
|---------|------------------|------|
| **Flutter Feature Migration** | `lib/screens/` → `lib/features/` (batch_entry + wizard) | 🟠 REFACTOR |
| **AsyncNotifier Transition** | `StateNotifier` → `AsyncNotifier` (all providers) | 🟠 REFACTOR |
| **Freezed Data Classes** | Add `@freezed` → `copyWith` + equality | 🟠 REFACTOR |
| **Repository Layer** | Services → Repository → API (abstraction) | 🟠 REFACTOR |
| **PostgreSQL RLS** | Double-safety: Hibernate @Filter + DB row-level security | 🔴 SECURITY |
| **User Mgmt UI** | Settings: User list, role assign, store assign | 🟠 FEATURE |
| **Role & Permission Manager** | Settings: Permission matrix, approval workflow | 🟠 FEATURE |

---

### Sprint 4 — LLM & Advanced

| Senaryo | Teknik Aksiyonlar | Önem |
|---------|------------------|------|
| **LLM Fallback** | PDFBox/OCR fail → Claude/GPT-4o (or Ollama) | 🟠 NICE |
| **Offline Sync** | sqflite + conflict resolution | 🟠 NICE |
| **Event-Driven Reporting** | Kafka: Sale → event → aggregator | 🟠 NICE |
| **Full CQRS** | Command bus + Event store + Projections | 🟠 FUTURE |

---

## BÖLÜM 5: i18n — Gerekli Metinler

Batch Entry ve PDF Upload için yeni keys (security/data.sql'e eklenecek):

```
bnd-BT001-0000-0000-NNNNNNNNNNNN    "Batch Entry"
bnd-BT002-0000-0000-NNNNNNNNNNNN    "Select Supplier"
bnd-BT003-0000-0000-NNNNNNNNNNNN    "Invoice Number"
bnd-BT004-0000-0000-NNNNNNNNNNNN    "Delivery Note"
bnd-BT005-0000-0000-NNNNNNNNNNNN    "Store"
bnd-BT006-0000-0000-NNNNNNNNNNNN    "Warehouse"
bnd-BT007-0000-0000-NNNNNNNNNNNN    "Purchase Date"
bnd-BT008-0000-0000-NNNNNNNNNNNN    "Add Row"
bnd-BT009-0000-0000-NNNNNNNNNNNN    "Barcode Scan"
bnd-BT010-0000-0000-NNNNNNNNNNNN    "Upload PDF"
bnd-BT011-0000-0000-NNNNNNNNNNNN    "PDF Loading..."
bnd-BT012-0000-0000-NNNNNNNNNNNN    "Extracting Invoice Data..."
bnd-BT013-0000-0000-NNNNNNNNNNNN    "Match Product"
bnd-BT014-0000-0000-NNNNNNNNNNNN    "Confirm Match"
bnd-BT015-0000-0000-NNNNNNNNNNNN    "Product Not Found"
bnd-BT016-0000-0000-NNNNNNNNNNNN    "Select Category"
bnd-BT017-0000-0000-NNNNNNNNNNNN    "Unit"
bnd-BT018-0000-0000-NNNNNNNNNNNN    "Quantity"
bnd-BT019-0000-0000-NNNNNNNNNNNN    "Unit Price"
bnd-BT020-0000-0000-NNNNNNNNNNNN    "VAT Rate"
bnd-BT021-0000-0000-NNNNNNNNNNNN    "Total Price"
bnd-BT022-0000-0000-NNNNNNNNNNNN    "Submit All"
bnd-BT023-0000-0000-NNNNNNNNNNNN    "Batch Saving..."
bnd-BT024-0000-0000-NNNNNNNNNNNN    "Success"
bnd-BT025-0000-0000-NNNNNNNNNNNN    "Error"
bnd-BT026-0000-0000-NNNNNNNNNNNN    "Retry Failed"
bnd-BT027-0000-0000-NNNNNNNNNNNN    "File Format Not Supported"
bnd-BT028-0000-0000-NNNNNNNNNNNN    "Clear All"
bnd-BT029-0000-0000-NNNNNNNNNNNN    "Row Saved"
bnd-BT030-0000-0000-NNNNNNNNNNNN    "Row Error: {reason}"
```

---

## BÖLÜM 6: CRITICAL PATH — P1 GÖREVLER

Projeyi "market-ready" yapmak için **blokleyen** görevler:

### P1.A — Stock Concurrent Safety
- **Status:** ⚠️ Eksik
- **Impact:** Lost update riski (iki Kasiyerin aynı ürünü satarsa)
- **Teknik:** StockLevel @Version → optimistic lock
- **Sprint:** 2
- **Est:** 4h

### P1.B — PDF Extract (VAT + Unit + Header)
- **Status:** 🔄 Kısmi
- **Impact:** Batch entry koluna insan emeği (manual VAT/Unit giriş)
- **Teknik:** Backend logic, text detection
- **Sprint:** 1 (SON)
- **Est:** 8h

### P1.C — Product Creation Category Requirement
- **Status:** ⚠️ Yazılmadı
- **Impact:** Kategori zorunlu olması gerekiyor (batch entry'de), UI uyarı
- **Teknik:** Validation + error message
- **Sprint:** 1 (SON)
- **Est:** 2h

### P1.D — Tenant Leak Prevention
- **Status:** ✅ Backend @Filter
- **Impact:** Multi-tenant sızıntı (company A ürünü company B'de görse)
- **Teknik:** @Filter("filterCompany"), PostgreSQL RLS (sprint 3)
- **Sprint:** 1-3
- **Est:** Already done (continue verify)

### P1.E — Supplier Account Balance Consistency
- **Status:** ⚠️ Partial
- **Impact:** Payable amount wrong → reconciliation issue
- **Teknik:** @Version + Transaction rollback
- **Sprint:** 2
- **Est:** 3h

---

## BÖLÜM 7: SPRINT ROADMAP (DETAYLI)

### Sprint 1 — PDF Analizi (2 hafta)

**Hedef:** Batch entry'den PDF fatura yükleme, otomatik line extract

```
Week 1:
  [ ] Backend: VAT rate detection (regex/ML)
  [ ] Backend: Unit extraction (lookup table)
  [ ] Backend: Invoice header (no, date)
  [ ] Backend: DocumentItemResult model update
  [ ] Test: Sample PDF (real invoice)

Week 2:
  [ ] Frontend: PDF upload file picker
  [ ] Frontend: Loading spinner dialog
  [ ] Frontend: Product name match confirmation
  [ ] Frontend: Error toast (unsupported format)
  [ ] Frontend: Result sheet integration
  [ ] Test: E2E with real PDF
```

**Blokleyen:** P1.B (PDF extract), P1.C (category requirement)

---

### Sprint 2 — Concurrent Safety & Cache

**Hedef:** @Version optimistic lock, Redis cache, Advanced features başlama

```
Week 1:
  [ ] Backend: @Version on StockLevel, SupplierAccount, CustomerAccount
  [ ] Backend: Optimistic lock exception handling + retry logic
  [ ] Backend: Redis setup (Spring Data Redis)
  [ ] Backend: Category/Brand/Unit cache (TTL 1h)
  [ ] Test: Concurrent stock update (2 threads)

Week 2:
  [ ] Backend: Async PDF job (polling endpoint)
  [ ] Backend: Tesseract OCR fallback
  [ ] Backend: Tax rate per category
  [ ] Frontend: Desktop table (product_entry_table.dart) enable
  [ ] Frontend: WebSocket stock alert listener
  [ ] Test: Slow PDF, OCR fallback, WebSocket broadcast
```

---

### Sprint 3 — Architecture & Security

**Hedef:** Flutter migrate, AsyncNotifier, PostgreSQL RLS

```
Week 1-2:
  [ ] Flutter: lib/screens/ → lib/features/ migration
  [ ] Flutter: StateNotifier → AsyncNotifier (all providers)
  [ ] Flutter: Freezed @freezed data classes
  [ ] Backend: Repository layer (Services wrap)
  [ ] Backend: PostgreSQL RLS policies
  [ ] Frontend: User Mgmt UI (Settings)
  [ ] Frontend: Role & Permission manager
  [ ] Test: Tenant isolation (RLS verify)
```

---

### Sprint 4 — LLM & Advanced

**Hedef:** Optional features, Future roadmap

```
[ ] Backend: LLM fallback (Claude/GPT-4o/Ollama)
[ ] Frontend: Offline sync (sqflite)
[ ] Backend: Event-driven reporting (Kafka)
[ ] Future: Full CQRS
```

---

## BÖLÜM 8: ÖZETLENMIŞ EKRAN AKSIYON CHECKLIST

```
Auth
  [✅] Login
  [✅] Register
  [🔄] 2FA

Dashboard
  [✅] Main dashboard
  [✅] Menu sidebar
  [🔄] Settings (partial)

POS (Point of Sale)
  [🔄] Main screen (barcode scan, product search)
  [🔄] Cart (quantity, discount)
  [🔄] Payment (cash, card, credit)
  [❌] Receipt (print, email, SMS)
  [❌] Sales returns

Batch Entry (Toplu Ürün Girişi)
  [🔄] Header (supplier, invoice, store, date)
  [🔄] Manual row entry
  [✅] Variant form (size, color, barcode)
  [❌] PDF upload & extract
  [❌] Result sheet

Catalog (Ürün)
  [✅] Product list
  [✅] Product detail
  [🔄] Add product wizard
  [✅] Variant management
  [❌] Category manager

Inventory (Stok)
  [✅] Stock level
  [🔄] Stock movement
  [❌] Stock adjustment
  [❌] Stock alert
  [❌] Stock transfer

Purchases (Satın Alma)
  [✅] Purchase list
  [✅] Purchase detail
  [🔄] GRN (Goods receipt)

Suppliers (Tedarikçi)
  [✅] Supplier list
  [🔄] Supplier account
  [❌] Supplier payment
  [❌] Bulk upload & merge

Customers (Müşteri)
  [✅] Customer list
  [🔄] Customer account
  [❌] Customer payment
  [❌] Credit management

Reports (Raporlar)
  [🔄] Sales report (partial)
  [🔄] Purchase report (partial)
  [❌] Inventory valuation
  [❌] AR aging
  [❌] AP aging

OEM / Autoparts
  [🔄] OEM search (partial)
  [❌] Vehicle search
  [❌] Cross reference

Settings
  [🔄] User management (partial)
  [❌] Role & permission
  [✅] Store/Warehouse
  [❌] Tax configuration
  [❌] Sequence numbers
```

---

## BÖLÜM 9: DEĞERLENDİRME & METRIKLER

### Completion Rate
- **Sprint 0:** ✅ ~95% (Auth, Dashboard, Core CRUD)
- **Sprint 1 (mevcut):** 🔄 ~60% (POS active, Batch entry core, PDF extract pending)
- **Sprint 2 (planlı):** Advanced features, concurrency safety
- **Sprint 3 (planlı):** Architecture migration, security hardening
- **Sprint 4 (planlı):** LLM, offline, event-driven

### Kritik Risk'ler
1. **Concurrent Stock Update:** @Version zorunlu (sprint 2)
2. **PDF Extract Kalitesi:** Tesseract fallback gerekebilir (sprint 2)
3. **Multi-Tenant Sızıntı:** Test coverage önemli (sprint 1-3)
4. **Performance:** Cache + indexing gerekli (sprint 2+)

---

**Son Güncelleme:** 2026-04-23 (Otomatik)  
**Next Review:** Sprint 1 bitişinde (est. 2026-05-03)
