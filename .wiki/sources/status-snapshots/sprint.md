---
title: Sprint Durumu
type: source
source: .claude/status/sprint.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Sprint Durumu

**Son güncelleme:** 2026-04-16

---

## Sprint 1 — PDF Fatura Analizi (DEVAM)

**Mevcut:** PDFBox altyapısı, Flutter servis, result sheet, upload butonu.

**Eksik:**
- [ ] Backend: KDV oranı extract (%18, %8)
- [ ] Backend: Birim extract ("ADET", "KG", "MT")
- [ ] Backend: `DocumentItemResult` modeline `unit + vatRate + vatIncluded + totalPrice`
- [ ] Backend: Fatura başlık bilgisi (fatura no, tarih)
- [ ] Flutter: `addFromDocumentItems()` → KDV/birim aktarımı
- [ ] Flutter: Loading spinner dialog
- [ ] Flutter: NAME match kullanıcı onay UI
- [ ] Flutter: Yükleme hatası detaylı mesaj
- [ ] Test: Gerçek fatura PDF ile uçtan uca

---

## Sprint 2 — Planlı

- Optimistic locking `@Version` (stok concurrent update)
- Redis cache (kategori/marka/birim listeleri, tenant-aware)
- Async PDF analiz (polling)
- Tesseract OCR fallback (taranmış PDF)
- WebSocket stok alarm (`/topic/stock/{companyCode}`), SSE fallback
- taxExempt / specialTaxRate batch modele
- `ProductEntryTable` desktop aktifleştir

---

## Sprint 3 — Planlı

- `lib/screens/` → `lib/features/` migration (batch_entry + wizard)
- `AsyncNotifier` geçişi
- `freezed` paketi (copyWith boilerplate)
- Repository Layer (Services → Repo → API)
- PostgreSQL RLS double-safety

---

## Sprint 4 — Uzun Vade

- LLM fallback (PDFBox başarısız → Claude/GPT-4o, tercihen self-hosted Ollama)
- Offline sync (sqflite + conflict resolution)
- Event-Driven raporlama (Kafka)
- Full CQRS

---

## Sürekli Açık — P1 Kritik

- [ ] Mevcut ürün `purchasePrice` = 0 edge case testi (batch entry)
- [ ] PDF aktarımında `categoryId` zorunluluk UI'si
- [ ] Stok concurrent update (lost update riski)
