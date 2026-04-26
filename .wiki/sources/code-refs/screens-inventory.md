---
title: SEDCORE POS — Ekran Envanteri (Screen Inventory)
type: source
source: .claude/inventory/screens-inventory.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# SEDCORE POS — Ekran Envanteri (Screen Inventory)

**Tarih:** 2026-04-23  
**Toplam Ekran:** 73  
**Durum:** Live Snapshot

---

## LEGEND

| Symbol | Anlamı |
|--------|--------|
| ✅ | Fully Implemented & Tested |
| 🔄 | Partially Implemented |
| ⚠️ | Work in Progress (WIP) |
| ❌ | Not Started |
| 📍 | Sprint 1 Focus |

**Code Complexity:**
- 0-300 LOC: Basit (List, Detail)
- 300-700 LOC: Orta (Form, CRUD)
- 700+ LOC: Karmaşık (Multi-step, Complex State)

---

## 1️⃣ AUTH MODULE — 2 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **login_screen.dart** | Stateful | 852 | ✅ | Email/Password login, company context |
| **company_registration_screen.dart** | Stateful | 659 | ✅ | New company signup, sector selection |

**Notes:**
- JWT token management implemented
- Multi-tenant context setup
- 2FA planned (Sprint 2)

---

## 2️⃣ DASHBOARD MODULE — 1 Screen

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **modern_dashboard_screen.dart** | Stateful | 877 | ✅ | Summary cards, charts, quick actions |

**Notes:**
- Widget-based layout (sales, stock, revenue summary)
- Real-time data binding
- Role-based visibility

---

## 3️⃣ MENU MODULE — 1 Screen

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **menu_screen.dart** | Stateful | 372 | ✅ | Sidebar navigation, role-based menu items |

**Notes:**
- i18n integrated (TR/EN)
- Feature-based routing (go_router)
- User profile dropdown

---

## 4️⃣ POS (POINT OF SALE) MODULE — 1 Screen 📍

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **pos_screen.dart** | Stateful | 265 | 🔄 | Barcode scan, cart, payment |

**Components:**
- Barcode/OEM scanner integration
- Shopping cart (add, remove, quantity)
- Payment method selection (cash, card, credit)
- Real-time product lookup

**Missing:**
- ❌ Receipt generation (print, email, SMS)
- ❌ Discount management
- ❌ Promotion codes
- ❌ Payment confirmation flow

**Notes:**
- Core POS flow 70% complete
- Receipt feature → Sprint 2

---

## 5️⃣ INVENTORY MODULE — 6 Screens 📍

### 5.1 — Batch Entry (SPRINT 1 FOCUS)

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **batch_product_screen.dart** | Stateful | **6891** | 🔄 | Toplu ürün girişi (tedarikçi alımı) |

**Components:**
- ✅ Header form: Supplier, Invoice, Date, Store, Warehouse
- ✅ Barcode/OEM scanner
- ✅ Manual row entry
- ✅ Variant selection (size, color, barcode)
- ✅ PDF upload widget (file picker, camera, gallery)
- ✅ Status tabs (all, new, existing, error, saved)
- ⚠️ PDF extract result sheet (WIP)
- 🔴 PDF extract backend (VAT, unit, header) — **BLOCKER #1**
- 🔴 Category selection UI — **BLOCKER #2**

**Data Model:**
```dart
BatchEntryState {
  header: {supplierId, invoiceNumber, purchaseDate, storeId, warehouseId}
  rows: [{
    id, status, product, variants, oemNumbers, crossReferences,
    quantity, purchasePrice, salePrice, unitPrice, taxRate
  }]
}
```

**API Calls:**
- `POST /product/api/v1/documents/upload` (PDF analyze)
- `POST /product/api/v1/products/batch` (Submit)

**Sprint 1 Blockers:**
1. Backend: PDF extract VAT%, unit, invoice header
2. Frontend: Category dropdown + validation
3. i18n: batch metinleri add

---

### 5.2 — Product Management

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **add_product_wizard_screen.dart** | Stateful | 524 | ✅ | Multi-step product creation |
| **enhanced_product_list_screen.dart** | Stateful | 1774 | ✅ | Product search, filter, sort |
| **product_detail_screen.dart** | Stateful | 2872 | ✅ | Product detail, variants, pricing, OEM |
| **barcode_management_screen.dart** | Stateful | 738 | ✅ | Barcode assignment, scanning |
| **brands_screen.dart** | Stateful | 574 | 🔄 | Brand master (recently modernized) |
| **units_screen.dart** | Stateful | 715 | 🔄 | Unit master (recently modernized) |

**Components:**
- ✅ Product CRUD with variants
- ✅ Barcode per variant
- ✅ Pricing (purchase, sale, wholesale)
- ✅ OEM number & cross-reference
- ✅ Category & attribute assignment
- ✅ Search & filter (by category, brand, stock)

**Notes:**
- Wizard: Type → Category → Attributes → Variants → Pricing
- Barcode scanner integrated
- Brand/Unit recently refactored (flutter modernization)

---

## 6️⃣ CATALOG MODULE — 3 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **category_list_screen.dart** | Stateful | 588 | ✅ | Category list, search, add |
| **add_category_screen.dart** | Stateful | 408 | ✅ | Category creation with attributes |
| **company_category_screen.dart** | Stateful | 503 | 🔄 | Company ↔ Category mapping |

**Components:**
- ✅ Category CRUD
- ✅ Attribute definition (size, color, etc.)
- ✅ Company-specific category selection
- ⚠️ Category hierarchy (nested) — not yet

**Notes:**
- Multi-tenant: each company can assign different categories
- Batch entry'de category seçimi eksik (BLOCKER #2)

---

## 7️⃣ STOCK MODULE — 8 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **enhanced_stock_screen.dart** | Stateful | 477 | ✅ | Real-time stock levels by location |
| **multi_warehouse_stock_screen.dart** | Stateful | 334 | 🔄 | Stock distribution across stores/warehouses |
| **stock_movement_history_screen.dart** | Stateful | 490 | 🔄 | Purchase/Sale/Adjustment history |
| **stock_alert_screen.dart** | Stateful | 314 | ⚠️ | Low stock warnings (config-based) |
| **stock_transfer_screen.dart** | Stateful | 755 | ⚠️ | Manual stock transfer (store ↔ warehouse) |
| **stock_transfer_review_screen.dart** | Stateful | 762 | ⚠️ | Transfer approval workflow |
| **stock_count_review_screen.dart** | Stateful | 735 | ⚠️ | Physical count verification |
| **stock_value_report_screen.dart** | Stateful | 396 | ⚠️ | Inventory valuation (ABC analysis) |

**Components:**
- ✅ Real-time quantity display (locationId + variantId)
- ✅ Movement history with search
- ⚠️ Concurrent update protection — **BLOCKER #3** (@Version not implemented)
- ⚠️ WebSocket alerts (Sprint 2)

**Notes:**
- Stock level tied to Store/Warehouse via locationId (2026-04-13 decision)
- Concurrent update risk: @Version needed (Sprint 2)
- Transfer/Alert features partially implemented

---

## 8️⃣ PURCHASES MODULE — 4 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **purchase_list_screen.dart** | Stateful | 311 | ✅ | PO list, filter by supplier/date |
| **add_purchase_screen.dart** | Stateful | 861 | 🔄 | Manual PO entry (mostly moved to batch) |
| **purchase_detail_screen.dart** | Stateful | 924 | ✅ | PO detail, status, GRN generation |
| **purchase_return_screen.dart** | Stateful | 690 | 🔄 | Return against PO |

**Components:**
- ✅ PO CRUD
- ✅ Item-level detail
- ✅ GRN (Goods Receipt Note) auto-generation from batch
- ⚠️ Return approval workflow

**Notes:**
- Direct PO entry → batch entry'ye shifted (Sprint 1)
- GRN linked to batch creation

---

## 9️⃣ SALES MODULE — 3 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **sale_list_screen.dart** | Stateful | 546 | ✅ | Invoice list, search, filter |
| **sale_detail_screen.dart** | Stateful | 986 | ✅ | Invoice detail, items, payment |
| **sale_return_screen.dart** | Stateful | 741 | 🔄 | Return processing |

**Components:**
- ✅ Sales CRUD
- ✅ Invoice detail with items
- ✅ Payment tracking
- ⚠️ Return approval
- ❌ Receipt generation (print, email) — Sprint 2

**Notes:**
- POS → Sale automation exists
- Manual invoice entry also available

---

## 🔟 SUPPLIERS MODULE — 4 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **supplier_list_screen.dart** | Stateful | 489 | ✅ | Supplier list, search, contact |
| **add_supplier_screen.dart** | Stateful | 1047 | ✅ | Supplier creation with account setup |
| **supplier_account_detail_screen.dart** | Stateful | 935 | 🔄 | Payable balance, payment history |
| **supplier_upload_wizard_screen.dart** | Stateful | 938 | 🔄 | Bulk supplier import (CSV), dedup |

**Components:**
- ✅ Supplier CRUD
- ✅ Contact & payment terms
- ✅ Account balance tracking
- ⚠️ @Version for concurrent updates (Sprint 2)
- ⚠️ Bulk import (CSV) — Sprint 3

**Notes:**
- Account (@Version): pending concurrent lock implementation
- Upload wizard: CSV → dedup → match → bulk insert

---

## 1️⃣1️⃣ CUSTOMERS MODULE — 3 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **customer_list_screen.dart** | Stateful | 418 | ✅ | Customer list, credit limit, YTD sales |
| **add_customer_screen.dart** | Stateful | 420 | ✅ | Customer creation, credit terms |
| **customer_account_detail_screen.dart** | Stateful | 586 | 🔄 | AR balance, payment history, credit |

**Components:**
- ✅ Customer CRUD
- ✅ Credit limit & terms
- ✅ Account balance
- ⚠️ @Version for concurrent updates (Sprint 2)
- ⚠️ Credit suspension workflow

**Notes:**
- AR tied to SaleAccount entity
- @Version needed for concurrent payment posting

---

## 1️⃣2️⃣ ACCOUNTS MODULE — 1 Screen

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **accounts_hub_screen.dart** | Stateful | 138 | ⚠️ | AR/AP summary dashboard |

**Components:**
- ⚠️ Payable/Receivable summary
- ⚠️ Aging report (30/60/90 days)
- ⚠️ Collection list

**Notes:**
- Minimal implementation
- Detailed accounting → Reports module

---

## 1️⃣3️⃣ FINANCE MODULE — 6 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **finance_dashboard_screen.dart** | Stateful | 432 | 🔄 | Revenue, expense, cash position |
| **add_income_screen.dart** | Stateful | 278 | 🔄 | Income entry (sales-based auto-populate) |
| **add_expense_screen.dart** | Stateful | 353 | 🔄 | Expense entry, category |
| **expense_list_screen.dart** | Stateful | 438 | 🔄 | Expense history, filter |
| **cash_flow_screen.dart** | Stateful | 418 | ⚠️ | Cash flow forecast |
| **payment_list_screen.dart** | Stateful | (linked) | 🔄 | Payment history |

**Components:**
- 🔄 Basic income/expense tracking
- 🔄 Payment recording
- ⚠️ Cash flow forecasting
- ⚠️ Financial reports integration

**Notes:**
- Finance → Reports duplication risk
- Reconciliation features → Sprint 3

---

## 1️⃣4️⃣ REPORTS MODULE — 6 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **reports_screen.dart** | Stateful | 492 | 🔄 | Reports hub, report selection |
| **daily_summary_screen.dart** | Stateful | 407 | 🔄 | Daily sales/purchase summary |
| **sales_summary_screen.dart** | Stateful | 398 | 🔄 | Sales by product/customer, trend |
| **product_sales_analysis_screen.dart** | Stateful | 333 | 🔄 | Product performance (ABC analysis) |
| **customer_sales_analysis_screen.dart** | Stateful | 299 | 🔄 | Customer segmentation, loyalty |
| **profit_overview_screen.dart** | Stateful | 241 | ⚠️ | Profit margin, cost analysis |

**Components:**
- 🔄 Summary reports with date range
- 🔄 Charts (fl_chart integration)
- 🔄 Export to PDF (Spring 2)
- ⚠️ Custom report builder

**Notes:**
- All reports: date range filter + graph + export
- Event-driven reporting → Sprint 4 (Kafka)

---

## 1️⃣5️⃣ SETTINGS MODULE — 5 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **settings_screen.dart** | Stateful | 1035 | 🔄 | Main settings hub |
| **user_management_screen.dart** | Stateful | 910 | 🔄 | User list, role assignment, store assign |
| **company_settings_screen.dart** | Stateful | 339 | 🔄 | Company details, sector, locale |
| **sector_settings_screen.dart** | Stateful | 273 | 🔄 | Sector-specific config (autoParts, footwear) |
| **profile_screen.dart** | Stateful | 275 | ✅ | User profile, password change |

**Components:**
- 🔄 User CRUD, role assignment
- 🔄 Store/Warehouse assignment per user
- 🔄 Company profile
- 🔄 Sector selection (immutable after setup)
- ❌ Permission matrix UI
- ❌ Sequence number setup
- ❌ Tax rate configuration

**Notes:**
- User role management backend ready, UI partial
- Permission matrix → Sprint 3
- Sector immutable (decision: 2026-04-13)

---

## 1️⃣6️⃣ AUTOPARTS (OEM/VEHICLE) MODULE — 3 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **part_search_screen.dart** | Stateful | 482 | 🔄 | OEM number search, supplier lookup |
| **vehicle_compatibility_screen.dart** | Stateful | 322 | ⚠️ | Vehicle ↔ Part compatibility matrix |
| **vehicle_list_screen.dart** | Stateful | 478 | ⚠️ | Vehicle master (make/model/year) |

**Components:**
- 🔄 OEM lookup (product matching)
- ⚠️ Vehicle DB (make/model/year filtering)
- ⚠️ Cross-reference (OEM ↔ Brand mapping)

**Notes:**
- OEM search: partial (lookup works, UI refinement needed)
- Vehicle DB: mock data only, needs real data + update process
- Auto parts sector-specific feature

---

## 1️⃣7️⃣ IMPORT MODULE — 4 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **bulk_import_upload_screen.dart** | Stateful | 1131 | ✅ | Bulk file upload (CSV/Excel) |
| **supplier_import_upload_screen.dart** | Stateful | 528 | 🔄 | Supplier file upload |
| **supplier_import_review_screen.dart** | Stateful | 948 | 🔄 | Import preview, dedup, mapping |
| **barcode_scanner_screen.dart** | Stateful | 426 | ✅ | Barcode scanning for import/merge |

**Components:**
- ✅ File picker (CSV, Excel, PDF)
- ✅ Barcode scanner (mobile_scanner)
- 🔄 Import preview & validation
- 🔄 Deduplication logic
- ⚠️ Batch processing (async jobs)

**Notes:**
- Supplier merge/dedup → Sprint 3
- Scanner: QR code support added

---

## 1️⃣8️⃣ HRM MODULE — 2 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **employee_list_screen.dart** | Stateful | 431 | 🔄 | Employee list (recently modernized) |
| **add_employee_screen.dart** | Stateful | 363 | 🔄 | Employee creation, assignment |

**Components:**
- 🔄 Employee CRUD
- 🔄 Department/role assignment
- 🔄 Store/Warehouse assignment
- ⚠️ Payroll integration

**Notes:**
- Minimal feature (future expansion planned)
- Recently refactored (Flutter modernization)

---

## 1️⃣9️⃣ STORE MODULE — 2 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **store_list_screen.dart** | Stateful | 308 | ✅ | Store location list |
| **add_store_screen.dart** | Stateful | 355 | ✅ | Store creation, code assignment |

**Components:**
- ✅ Store CRUD (soft delete only)
- ✅ Location code (STORE-01 format)
- ✅ Active/Inactive toggle

**Notes:**
- Physical delete prohibited (soft delete only)
- Code format: STORE-XX (immutable)

---

## 2️⃣0️⃣ WAREHOUSE MODULE — 2 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **warehouse_list_screen.dart** | Stateful | 572 | ✅ | Warehouse location list |
| **add_warehouse_screen.dart** | Stateful | 374 | ✅ | Warehouse creation, code assignment |

**Components:**
- ✅ Warehouse CRUD (soft delete only)
- ✅ Location code (WH-XX format)
- ✅ Stock level management

**Notes:**
- Unified with Store via locationId (2026-04-13 decision)

---

## 2️⃣1️⃣ SUPPLIER CLAIMS MODULE — 2 Screens

| Screen | Type | LOC | Status | Durum |
|--------|------|-----|--------|--------|
| **supplier_claims_list_screen.dart** | Stateful | 211 | ✅ | Claim list, status tracking |
| **supplier_claim_detail_screen.dart** | Stateful | 371 | ✅ | Claim detail, resolution, follow-up |

**Components:**
- ✅ Claim CRUD
- ✅ Status workflow (open, in-progress, resolved)
- ✅ Notes & documentation

**Notes:**
- Warranty/damage claim tracking
- Simple feature (minimal complexity)

---

## 📊 SUMMARY STATISTICS

### By Status
```
✅ Fully Complete    : ~25 screens (34%)
🔄 Partially Done    : ~35 screens (48%)
⚠️ Work in Progress  : ~12 screens (16%)
❌ Not Started       : ~1 screen (1%)
```

### By Complexity
```
0-300 LOC (Simple)    : 20 screens
300-700 LOC (Medium)  : 35 screens
700+ LOC (Complex)    : 18 screens
  └─ batch_product_screen: 6,891 LOC (!!)
```

### Top 5 Largest Screens
```
1. batch_product_screen.dart      — 6,891 LOC (Batch entry giant)
2. product_detail_screen.dart     — 2,872 LOC (Complex product UI)
3. enhanced_product_list_screen   — 1,774 LOC (Search + filter)
4. bulk_import_upload_screen      — 1,131 LOC (Import logic)
5. settings_screen.dart           — 1,035 LOC (Settings hub)
```

---

## 🎯 SPRINT 1 FOCUS

### Critical (BLOCKERS)

| Screen | Blocker | Action | Est. |
|--------|---------|--------|------|
| **batch_product_screen.dart** | PDF extract (VAT, unit, header) | Backend: DocumentAnalyzeServiceImpl | 8-10h |
| **batch_product_screen.dart** | Category dropdown + validation | Frontend: add DropdownButton + logic | 2-3h |
| **data.sql** | i18n keys for batch | Add message_definitions rows | 0.5h |

### Medium Priority

| Screen | Work | Action | Sprint |
|--------|------|--------|--------|
| **pos_screen.dart** | Receipt generation | Print, email, SMS | 2 |
| **all screens** | @Version concurrent safety | StockLevel, Account entities | 2 |
| **stock_alert_screen.dart** | WebSocket alerts | Real-time notifications | 2 |

---

## 📝 NOTES

### High Code Complexity Screens

**batch_product_screen.dart (6,891 LOC)** ⚠️
- Consolidated: header + rows + PDF + result sheet + tabs in ONE file
- **Recommendation:** Split into modular components (Sprint 3 architecture refactor)
  - batch_header_form.dart (extract)
  - batch_rows_table.dart (extract)
  - pdf_upload_widget.dart (extract)
  - result_sheet.dart (extract)

**product_detail_screen.dart (2,872 LOC)** ⚠️
- Tabs: variants, pricing, OEM, cross-ref
- **Recommendation:** Tab-based modularization

---

## ✨ RECENTLY REFACTORED (Flutter Modernization)

As of 2026-04-22:
- units_screen.dart — modernized
- employee_list_screen.dart — modernized
- brands_screen.dart — modernized
- add_category_screen.dart — modernized

**Pattern:** Riverpod 2.x StateNotifier → AsyncNotifier (gradual migration, Sprint 3)

---

**Last Updated:** 2026-04-23  
**Source:** Live grep on project_pos/lib/features/**/*_screen.dart  
**Next Review:** Sprint 1 completion (est. 2026-05-03)
