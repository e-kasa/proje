---
title: VS Code — Geliştirme Ortamı Setup & Plan Implementation
type: source
source: .claude/guides/vscode-setup-implementation.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# VS Code — Geliştirme Ortamı Setup & Plan Implementation

**Tarih:** 2026-04-23  
**Amaç:** Yerel VS Code'da SEDCORE POS geliştirmesi  
**Durum:** Step-by-step ready

---

## ADIM 1: VS Code Workspace Hazırlama

### 1.1 — Proje Folder'ını VS Code'da Aç

```bash
# Terminal'de:
cd /sessions/busy-brave-fermat/mnt/proje

# VS Code aç:
code .
```

**Veya:** File → Open Folder → `/sessions/busy-brave-fermat/mnt/proje` seç

### 1.2 — Gerekli VS Code Extensions İndir

Açılan VS Code penceresinde **Extensions** (Ctrl+Shift+X) seç ve kur:

```
1. Extension Pack for Java (Microsoft)
   - Provides: Java, Maven, Debugger
   - Install: microsoft.vscode-java-pack

2. Dart (Dart Code)
   - Provides: Dart/Flutter support
   - Install: dart-code.dart-code

3. Flutter (Flutter)
   - Provides: Flutter commands, widget preview
   - Install: dart-code.flutter

4. GitLens (GitLens)
   - Git history, blame, branches
   - Install: eamodio.gitlens

5. REST Client (REST Client)
   - API testing (backend endpoints)
   - Install: humao.rest-client

6. Markdown All in One (Markdown All in One)
   - Documentation editing
   - Install: yzhang.markdown-all-in-one
```

### 1.3 — Workspace Settings (Optional)

`.vscode/settings.json` oluştur:

```json
{
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.dart": true
    }
  },
  "[java]": {
    "editor.formatOnSave": true
  },
  "maven.executable.path": "/usr/bin/mvn",
  "java.jdt.ls.vmargs": "-XX:+UseG1GC -XX:+UseStringDeduplication",
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true
}
```

---

## ADIM 2: Backend Environment Setup

### 2.1 — Ön Koşulları Kontrol Et

```bash
# Terminal'de (VS Code içinde: Ctrl+`)

# Java versiyonunu kontrol et
java -version
# Beklenen: Java 25 (veya 21+)

# Maven kontrolü
mvn -v
# Beklenen: Apache Maven 3.8.1+

# PostgreSQL durumu
psql --version
# Beklenen: psql 12+

# PostgreSQL bağlantı
psql -U ekalem -d ekalem -h localhost -c "SELECT 1"
# Beklenen: (1 row)
```

### 2.2 — Core Modülü Build Et

```bash
# Proje root'ta:
cd core
mvn clean install -q

# Output beklenen:
# [INFO] BUILD SUCCESS
# [INFO] Total time: ~30s
```

**Sorun varsa:**
```bash
# Maven cache temizle
mvn clean -q
rm -rf ~/.m2/repository/com/sedcore

# Yeniden dene
mvn install -q
```

### 2.3 — Backend Services'i Run Et

**3 terminal aç (VS Code Terminal):**

**Terminal 1 — Security Service (port 8002):**
```bash
cd security
mvn spring-boot:run

# Beklenen çıktı (~10 saniye sonra):
# Started SecurityServiceApplication in 8.5 seconds
# INFO: Application ready to serve requests on http://localhost:8002
```

**Terminal 2 — Product Manager (port 8001):**
```bash
cd pos-product-manager
mvn spring-boot:run

# Beklenen çıktı (~15 saniye sonra):
# Started PosProductManagerApplication in 14.3 seconds
# INFO: Application ready to serve requests on http://localhost:8001
```

**Terminal 3 — API Gateway (port 8080):**
```bash
cd api-manager
mvn spring-boot:run

# Beklenen çıktı (~10 saniye sonra):
# Started ApiManagerApplication in 9.2 seconds
# INFO: Application ready to serve requests on http://localhost:8080
```

### 2.4 — Health Check

**Terminal 4'te:**
```bash
# Gateway health
curl -s http://localhost:8080/health | jq .

# Product Manager health
curl -s http://localhost:8001/health | jq .

# Security health
curl -s http://localhost:8002/health | jq .

# Beklenen: {"status":"UP"}
```

---

## ADIM 3: Flutter Setup

### 3.1 — Flutter SDK Kontrol

```bash
# Flutter versiyonu
flutter --version

# Beklenen: Flutter 3.x+ (minimum 3.10)

# Pub get
cd project_pos
flutter pub get

# Beklenen: Running "flutter pub get" in project_pos
# [INFO] + 150 packages installed
```

### 3.2 — Chrome Device Setup

```bash
# Flutter devices
flutter devices

# Beklenen çıktı:
# Chrome (web) • chrome • web-javascript • Google Chrome
```

**Eğer Chrome görünmüyorsa:**
```bash
# Chrome'u enable et
flutter config --enable-web

# Tekrar kontrol et
flutter devices
```

### 3.3 — VS Code'da Flutter Run

**VS Code Terminal'de:**
```bash
cd project_pos
flutter run -d chrome

# Beklenen çıktı (~30 saniye):
# Flutter Web
# ✓ Build successful
# [Chrome] Opening http://localhost:port ...
```

**Veya:** VS Code Command Palette (Ctrl+Shift+P) → "Flutter: Run" seç

---

## ADIM 4: VS Code Folder Structure Navigation

### 4.1 — Explorer Açı (Ctrl+Shift+E)

```
proje/
├── core/                         ← Shared library
│   ├── src/main/java/com/sedcore/
│   │   ├── common/               ← Base classes
│   │   ├── entity/               ← TOpenDbEntity (inheritance base)
│   │   └── ...
│   └── pom.xml
│
├── security/                     ← Auth service (port 8002)
│   ├── src/main/java/com/sedcore/security/
│   │   ├── controller/
│   │   ├── service/
│   │   └── entity/
│   ├── src/main/resources/data.sql    ← i18n + users seed
│   └── pom.xml
│
├── pos-product-manager/          ← Business logic (port 8001)
│   ├── src/main/java/com/sedcore/
│   │   ├── product/              ← Product CRUD, PDF extract
│   │   │   ├── controller/
│   │   │   ├── service/
│   │   │   ├── model/
│   │   │   └── entity/
│   │   ├── inventory/            ← Stock management
│   │   ├── catalog/              ← Categories
│   │   ├── finance/              ← Payments, accounts
│   │   └── ...
│   ├── src/main/resources/data.sql    ← Master data seed
│   └── pom.xml
│
├── api-manager/                  ← API Gateway (port 8080)
│   ├── src/main/java/com/sedcore/apimanager/
│   │   ├── config/
│   │   └── filter/
│   └── pom.xml
│
├── project_pos/                  ← Flutter app
│   ├── lib/
│   │   ├── core/                 ← App infrastructure
│   │   │   ├── api/api_client.dart
│   │   │   ├── config/
│   │   │   ├── di/
│   │   │   ├── router/app_router.dart
│   │   │   ├── theme/app_colors.dart
│   │   │   └── widgets/
│   │   ├── shared/               ← Cross-feature providers
│   │   │   ├── providers/
│   │   │   ├── models/
│   │   │   └── services/
│   │   └── features/             ← 21 business domains
│   │       ├── auth/
│   │       ├── pos/
│   │       ├── inventory/
│   │       │   ├── screens/
│   │       │   │   ├── batch_entry/      ← Sprint 1 focus
│   │       │   │   │   ├── batch_product_screen.dart
│   │       │   │   │   ├── models/
│   │       │   │   │   ├── providers/
│   │       │   │   │   └── widgets/
│   │       │   │   ├── add_product/
│   │       │   │   └── ...
│   │       │   ├── services/
│   │       │   └── di/
│   │       ├── sales/
│   │       ├── purchases/
│   │       └── ...
│   ├── pubspec.yaml
│   └── pubspec.lock
│
├── template/                     ← React admin (minimal)
├── .claude/                      ← Documentation
│   ├── INDEX.md
│   ├── CLAUDE.md (root)
│   ├── plans/
│   │   └── development-features-roadmap.md
│   ├── status/
│   │   ├── sprint.md
│   │   └── live-status-2026-04-23.md
│   ├── reference/
│   ├── runbooks/
│   └── decisions/
│
└── .git/
```

### 4.2 — Hızlı Dosya Açma

**Ctrl+P** (Go to File) kullan:

```
Yazı: "batch_entry_provider"
Seç: project_pos/lib/features/inventory/screens/batch_entry/providers/batch_entry_provider.dart
```

---

## ADIM 5: Sprint 1 Blocker'ları Fix Etmek

### 5.1 — Blocker #1: PDF Extract (VAT, Unit, Header)

**Lokasyon:** Backend

```bash
# Dosya aç (Ctrl+P):
pos-product-manager/src/main/java/com/sedcore/product/service/impl/DocumentAnalyzeServiceImpl.java
```

**Görev:**
```java
// Şu metodu implement et:
private double extractVatRate(String text) {
    // Regex: "KDV %18" → 18.0
    // Regex: "KDV %8" → 8.0
    // Return: extracted value or default (18.0)
}

private String extractUnit(String text) {
    // Lookup: "ADET", "KG", "MT", "METRE", "LITRE"
    // Return: standard unit code
}

private InvoiceHeader extractInvoiceHeader(Document pdfDoc) {
    // Extract: Invoice number, date from header
    // Return: InvoiceHeader { invoiceNo, invoiceDate }
}
```

**Bağlantılı Dosyalar:**
- `DocumentItemResult.java` (model — VAT, unit, totalPrice alanları)
- `DocumentAnalyzeResponse.java` (response wrapper)
- `DocumentAnalyzeController.java` (endpoint)

**Test:**
```bash
# Real PDF ile manual test
curl -X POST http://localhost:8001/product/api/v1/documents/upload \
  -F "file=@invoice.pdf" \
  | jq '.data.items[] | {name, unit, vatRate, totalPrice}'

# Beklenen çıktı:
# {
#   "name": "Yağlı Filtre",
#   "unit": "ADET",
#   "vatRate": 18.0,
#   "totalPrice": 150.00
# }
```

---

### 5.2 — Blocker #2: Category Requirement UI (Flutter)

**Lokasyon:** Frontend batch entry screen

```bash
# Dosya aç:
project_pos/lib/features/inventory/screens/batch_entry/batch_product_screen.dart
```

**Görev:**
```dart
// batch_product_screen.dart içinde şu widget'ı ekle:

// 1. Header form'a category field ekle
Widget _buildCategoryField() {
  return DropdownButton<String>(
    value: state.header.categoryId,
    items: categories.map((cat) => 
      DropdownMenuItem(value: cat.id, child: Text(cat.name))
    ).toList(),
    onChanged: (id) => ref.read(batchEntryProvider.notifier)
        .updateCategory(id),
    hint: Text(t('batch.select_category')),
  );
}

// 2. submitAll() çağrıdan önce validation
if (state.header.categoryId == null) {
  AppToast.warning(context, t('batch.category_required'));
  return;
}

// 3. backend'e gönder
BatchCreateRequest(
  ...
  categoryId: state.header.categoryId,  // ← yeni
  ...
)
```

**i18n Keys Ekle** (security/data.sql):
```sql
INSERT INTO message_definitions (id, key, value_tr, value_en) VALUES
('bnd-BT016-0000-0000-NNNNNNNNNNNN', 'batch.select_category', 'Kategori Seç', 'Select Category'),
('bnd-BT016-0000-0000-NNNNNNNNNNNN', 'batch.category_required', 'Kategori zorunlu', 'Category is required');
```

**Test:**
```bash
# Flutter run
flutter run -d chrome

# Batch entry'ye git
# Header'da "Category" field'ı görmeli
# Submit'e tıkla, category seçilmezse warning
```

---

### 5.3 — Blocker #3: Concurrent Stock Safety (@Version)

**Lokasyon:** Backend entity + repository

```bash
# Dosya aç:
pos-product-manager/src/main/java/com/sedcore/inventory/entity/StockLevel.java
```

**Görev:**
```java
@Entity
@Table(name = "stock_level")
public class StockLevel extends TOpenSimpleCompanyEntity {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @ManyToOne
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;
    
    @Column(name = "location_id", nullable = false)
    private String locationId;  // STORE-01, WH-01
    
    @Column(name = "quantity", nullable = false)
    private Integer quantity;
    
    // ← ADD THIS:
    @Version
    private Long version;  // optimistic lock
    
    // getter/setter
}
```

**Repository'de retry logic ekle:**
```java
@Repository
public interface StockLevelRepository extends JpaRepository<StockLevel, UUID> {
    Optional<StockLevel> findByVariantIdAndLocationId(UUID variantId, String locationId);
}

// Service'te:
@Transactional
public void updateStock(UUID variantId, String locationId, int quantityDelta) {
    for (int retry = 0; retry < 3; retry++) {
        try {
            StockLevel stock = repo.findByVariantIdAndLocationId(variantId, locationId)
                .orElseThrow();
            stock.setQuantity(stock.getQuantity() + quantityDelta);
            repo.save(stock);
            return;
        } catch (OptimisticLockingFailureException e) {
            if (retry == 2) throw e;
            Thread.sleep(100);
        }
    }
}
```

**Test:**
```bash
# Concurrent update test (JUnit)
@Test
public void testConcurrentStockUpdate() throws Exception {
    // 2 thread'de aynı stock update et
    // @Version sayısı increment olmalı
    // Ikincisi retry'dan sonra başarılı olmalı
}
```

---

## ADIM 6: Sık Kullanılan VS Code Komutları

### 6.1 — Terminal Shortcuts

| Kısayol | Açıklama |
|---------|----------|
| **Ctrl+`** | Terminal aç/kapat |
| **Ctrl+Shift+`** | Yeni terminal |
| **Ctrl+J** | Terminal/Bottom panel toggle |

### 6.2 — Search & Navigation

| Kısayol | Açıklama |
|---------|----------|
| **Ctrl+P** | Dosya aç |
| **Ctrl+Shift+F** | Proje içinde ara |
| **Ctrl+F** | Dosya içinde ara |
| **Ctrl+H** | Find & Replace |
| **Ctrl+G** | Satıra git |

### 6.3 — Debugging

| Kısayol | Açıklama |
|---------|----------|
| **F5** | Run/Debug |
| **F9** | Toggle breakpoint |
| **F10** | Step over |
| **F11** | Step into |

### 6.4 — Git Integration

| Kısayol | Açıklama |
|---------|----------|
| **Ctrl+Shift+G** | Git panel |
| **Ctrl+K Ctrl+O** | Commit |
| **Ctrl+Shift+P** → "Git: Push" | Push |

---

## ADIM 7: REST API Testing (VS Code)

### 7.1 — REST Client Extension Kullan

`requests.rest` dosyası oluştur:

```rest
### Health Check
GET http://localhost:8080/health

### Login
POST http://localhost:8002/security/api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@test.com",
  "password": "123456"
}

### Get Products
GET http://localhost:8080/product/api/v1/products
Authorization: Bearer {{token}}

### Upload PDF for Analysis
POST http://localhost:8001/product/api/v1/documents/upload
Content-Type: multipart/form-data; boundary=----FormBoundary

------FormBoundary
Content-Disposition: form-data; name="file"; filename="invoice.pdf"
Content-Type: application/pdf

< ./invoice.pdf
------FormBoundary--

### Batch Create (Product + Stock)
POST http://localhost:8001/product/api/v1/products/batch
Content-Type: application/json
Authorization: Bearer {{token}}
X-Company-Code: COMPANY-001

{
  "supplierId": "supplier-001",
  "invoiceNumber": "INV-2026-001",
  "purchaseDate": "2026-04-23",
  "storeId": "STORE-01",
  "newProducts": [
    {
      "tempId": "temp-1",
      "name": "Yağlı Filtre",
      "categoryId": "cat-1",
      "variants": [
        {
          "sku": "YF-001",
          "barcode": "8690000000000",
          "quantity": 100,
          "purchasePrice": 50.00
        }
      ]
    }
  ]
}
```

**Kullanım:**
- İmleci request'e koy
- "Send Request" butonuna tıkla (response açılacak)

---

## ADIM 8: Common Issues & Fixes

### Issue #1: "port 8080 already in use"

```bash
# Process'i bul
lsof -i :8080

# Kill et
kill -9 <PID>

# Spring boot'u yeniden başlat
```

### Issue #2: "Flutter pub get fails"

```bash
cd project_pos
flutter pub cache clean
flutter pub get --verbose
```

### Issue #3: "PostgreSQL connection refused"

```bash
# PostgreSQL status
sudo systemctl status postgresql

# Start et (Linux)
sudo systemctl start postgresql

# macOS
brew services start postgresql
```

### Issue #4: "Java compilation error"

```bash
# Maven clean
mvn clean compile

# Specific module
cd pos-product-manager
mvn clean compile -DskipTests
```

### Issue #5: "Batch entry PDF extract returns null"

```bash
# Check PDF format (valid PDF mi?)
file invoice.pdf

# Backend logs kontrol
# Dosya format'ı hatalı ise: "Unsupported PDF structure"
# Corrupted ise: "PDF parsing failed"

# OCR service çalışıyor mu?
curl http://localhost:5000/health
```

---

## ADIM 9: Development Workflow (Daily)

### Morning Standup (5 min)

```bash
# Branch status kontrol et
git status

# Latest changes görmek
git log --oneline -5

# Sprint status görmek
cat .claude/status/live-status-2026-04-23.md
```

### Coding Session (2-4 hours)

```bash
# 1. Yeni branch aç
git checkout -b feature/pdf-extract-vat

# 2. VS Code'da edit
# - Dosya aç (Ctrl+P)
# - Kod yazı, test yap

# 3. Build & test
mvn clean compile -DskipTests
flutter run -d chrome

# 4. Commit
git add .
git commit -m "feat(pdf-extract): VAT rate detection"

# 5. Push
git push origin feature/pdf-extract-vat
```

### End of Day (5 min)

```bash
# WIP ile bitir (uncommitted olmasa bile)
git status

# Yarın başlayabilir miyim kontrolü
mvn clean compile
flutter pub get
```

---

## ADIM 10: Checkpoint — Sprint 1 Completion

### Checklist

```
BACKEND
  [ ] PDF extract VAT rate (regex/text detection)
  [ ] PDF extract unit (lookup table)
  [ ] PDF extract invoice header (number, date)
  [ ] DocumentItemResult model updated (unit + vatRate fields)
  [ ] DocumentAnalyzeResponse wrapper complete
  [ ] Test: 5+ real PDF'ler ile passed

FRONTEND
  [ ] Category field added to batch header form
  [ ] Category validation before submit
  [ ] i18n keys (batch.select_category, batch.category_required)
  [ ] Flutter compile & run successful
  [ ] E2E test: PDF upload → extract → merge → submit

DATABASE
  [ ] i18n seed data updated (security/data.sql)
  [ ] No migration needed (@Version sprint 2'ye)

DOCUMENTATION
  [ ] Runbook updated (batch entry flow)
  [ ] Known issues logged
  [ ] Next sprint prep (concurrent safety planning)

GIT
  [ ] All commits pushed
  [ ] No uncommitted changes
  [ ] Branch merged to main/develop
```

---

## ADIM 11: Sonraki Sprint Hazırlık (Sprint 2)

### Sprint 2 Preview — Concurrent Safety

```
Planlı:
  - @Version on StockLevel, SupplierAccount, CustomerAccount
  - Optimistic lock exception handling
  - Retry logic (3 attempts)
  - Redis cache (Category, Brand, Unit)
  
Frontend:
  - Desktop table (product_entry_table.dart)
  - WebSocket stock alert listener
  - Async PDF job polling
  
Teknoloji:
  - Spring Data Redis
  - Tesseract OCR fallback
  - PostgreSQL RLS (Sprint 3)
```

---

**Çıktı:** Fully functional VS Code development environment  
**Beklenen Zaman:** 30-45 min (setup + first build)  
**Support:** See `.claude/CLAUDE.md` for project rules

🚀 **Başlamaya hazır mısın?**
