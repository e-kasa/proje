---
title: Entegrasyon Kataloğu
tags: [synthesis, integration, external-services]
date: 2026-04-25
status: draft
covers:
  - "[[entities/slack-notifier]]"
  - "[[concepts/typed-api-contract]]"
  - "[[decisions/pdf-backend-over-client]]"
  - "[[decisions/openapi-incremental-migration]]"
---

# Entegrasyon Kataloğu

SEDCORE POS'un dış servislerle iletişim katalogu. Her entegrasyon kanal bazlı; sektör bağımsız — hepsi tüm tenant'lara açık.

## Mevcut Entegrasyonlar

| Entegrasyon | Durum | Modül |
|---|---|---|
| Slack Webhook | ✅ Sprint 3 | [[entities/slack-notifier]] — scheduled reconcile alert |
| PDFBox (PDF üretim) | ✅ Sprint 5 | [[decisions/pdf-backend-over-client]] — ekstre export |
| Email (SMTP) | ✅ Sprint 5 mini | JavaMailSender + no-op fallback, ekstre email |
| OpenAPI → Dart | ✅ Sprint 4 infra | [[concepts/typed-api-contract]] — codegen pipeline |
| Micrometer + Prometheus | ✅ Sprint 3 | `/actuator/prometheus`, reconcile metrics |
| Actuator Health/Info | ✅ | `/actuator/health`, `/actuator/info` |
| Tesseract OCR | 🟠 Planlı Sprint 4 | Fatura/irsaliye OCR (ayrı servis :8003) |

## Planlı (Sektör-Agnostik)

| Entegrasyon | Kullanım | Önceliğ |
|---|---|---|
| e-Fatura / e-Arşiv | Türkiye GIB entegrasyonu | Yüksek |
| Trendyol API | Pazaryeri ürün/sipariş sync | Yüksek |
| Hepsiburada API | Aynı | Orta |
| N11 API | Aynı | Orta |
| Kargo firmaları (Yurtiçi, Aras, MNG) | Barkod + tracking | Orta |
| WhatsApp Business API | Vadesi geçen bildirim | Orta ([[issues/overdue-notification-missing]]) |
| SMS Gateway | Bildirim alternatif | Orta |
| Banka POS | Sanal POS gateway | Yüksek |
| Muhasebe programı export (Logo, Mikro, Nebim) | e-Fatura entegrasyonuna gerek olmayan muhasebe akışı | Orta |
| Barkod yazıcı | ZPL/ESC-POS | Orta |
| Terazi cihazları | Serial/TCP | Düşük (tartım sektörleri) |

## Config Pattern

Entegrasyonlar **flag-kontrollü no-op fallback** ile (dev'de hata atmaz):
- `slack.webhook.url=` (boş → no-op, bkz. [[entities/slack-notifier]])
- `mail.enabled=false` (default → send'ler no-op)
- `reconcile.scheduled.enabled=false` (default → cron skip)

## Sources

- [[raw/code-refs/2026-04-25-openapi-codegen-pattern]]
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[syntheses/pos-module-map]]
- [[syntheses/sector-agnostic-architecture]]
