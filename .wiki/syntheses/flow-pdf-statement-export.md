---
title: Flow — PDF Statement Export
type: synthesis
source: .claude/wiki/flows/pdf-statement-export.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# PDF Statement Export

## Amaç

Müşteri veya tedarikçi hesabının tarih aralıklı ekstresini server-side PDF olarak indirilebilir format'ta üretir. Client-side PDF (`statement_pdf_service.dart`) ile paralel — server-side email/fax/arşiv için temel.

## Endpoint

```
GET /product/api/v1/account-statements/pdf
  ?accountType=CUSTOMER|SUPPLIER
  &accountId=...
  &startDate=yyyy-MM-dd
  &endDate=yyyy-MM-dd
```

Response: `application/pdf`, `Content-Disposition: attachment; filename="statement-customer-<id>-<today>.pdf"`.

## Call Chain

```
GET /account-statements/pdf
  → AccountStatementPdfControllerImpl.getStatementPdf(params)
  → customerRepo/supplierRepo.findById(accountId)         (name için)
  → accountTransactionRepository.find{Customer|Supplier}Statement(id, start, end)
  → accountTransactionRepository.{customer|supplier}OpeningBalance(id, start)
  → renderPdf(...) — PDFBox, in-memory ByteArrayOutputStream
  → byte[] + PDF headers
```

## PDF Format (Minimum Viable)

```
┌──────────────────────────────────────────────────────┐
│ Hesap Ekstresi                                       │ 16pt bold
│ Musteri: Acme Ltd                                    │ 11pt
│ Tarih araligi: 01.04.2026 - 24.04.2026               │ 10pt
│                                                      │
│ Acilis bakiye: 5000.00 TL                            │ 11pt bold
│                                                      │
│ Tarih           Aciklama    Borc    Alacak   Bakiye  │ tablo
│ 05.04 14:30  Satis-POS-X  2500.00   0.00   7500.00  │
│                                                      │
│ Toplam borc: X | Toplam alacak: Y | Kapanis: Z       │ 10pt bold
└──────────────────────────────────────────────────────┘
```

A4 portrait, multi-page (row bitince yeni sayfa).

## Türkçe Karakter Tuzağı

PDFBox Standard14 fontlar (Helvetica) **WinAnsi** encoding — `ğşıç` render'da `Could not encode` throw eder. Geçici çözüm: `sanitize()` ASCII'ye downgrade. **Gelecek iterasyon**: `PDType0Font.load(doc, NotoSans-Regular.ttf)` — TTF embed edilir.

## Email Endpoint — POST /email (2026-04-24 mini-sprint)

```
POST /product/api/v1/account-statements/email
  ?accountType=...&accountId=...&startDate=...&endDate=...&to=<email>&subject=...
```

Response (ApiResponse wrap):
```json
{ "success": true, "data": { "sent": true|false, "to": "...", "subject": "...", "attachmentSize": 12345, "reason": "mail_disabled" } }
```

### Çalışma Mantığı

```
POST /email → emailStatement(...)
  → buildStatementPdf(...)   ← /pdf endpoint'iyle ortak helper
  → EmailService.sendWithAttachment(to, subject, body, filename, bytes)
      → mail.enabled=false  → no-op + sent=false (log.warn, 200 döner)
      → mail.enabled=true   → JavaMailSender.send → sent=true
      → exception           → log.error + sent=false
```

### Config

```properties
mail.enabled=true
mail.from=noreply@sedcore.com
spring.mail.host=smtp.example.com
spring.mail.port=587
spring.mail.username=apikey
spring.mail.password=${SPRING_MAIL_PASSWORD:}
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
```

### Tuzaklar

- **`@Async` yok** — endpoint 10-15 saniye bloke edebilir
- **Rate limit yok** — IP/user başı throttle gerekir (Bucket4j)
- **Attachment size** — PDF > 10 MB SMTP limitine takılabilir

## Güvenlik

Mevcut `SecurityConfiguration` — `anyRequest().authenticated()` kapsamında. İdeal: `@PreAuthorize("hasAnyRole('ADMIN','STORE_ADMIN','CASHIER')")`.

## Sources

- `pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementPdfControllerImpl.java`
- `pos-product-manager/src/main/java/com/sedcore/common/notification/EmailService.java`
- `pos-product-manager/src/main/java/com/sedcore/finance/repository/AccountTransactionRepository.java`
- `pos-product-manager/pom.xml` (pdfbox 3.0.3 + spring-boot-starter-mail)

## Related

- [[entities/account-transaction]]
- [[syntheses/flow-accounts-hub-load]]
- [[syntheses/accounts-hub-production-readiness]] (P2.3)
