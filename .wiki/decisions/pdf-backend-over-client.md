---
title: Karar — PDF Backend'de Üretilir (Client'ta Değil)
tags: [decision, pdf, export]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\flows\pdf-statement-export.md
---

# PDF Backend-Side

## Karar

Cari ekstresi PDF export backend'de (PDFBox) üretilir. Flutter mevcut client-side `statement_pdf_service.dart` paralel çalışmaya devam eder; gelecek iterasyon deprecate edecek.

## Gerekçe

- Email gönderimi için backend render şart
- Tutarlı format (tüm client'lar aynı PDF)
- PDFBox zaten pom.xml'de (belge analizi için)

## Sources

- `.claude/wiki/flows/pdf-statement-export.md`
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[syntheses/integration-catalog]]
