---
title: Vadesi Geçen Bildirim Yok (RESOLVED)
tags: [issue, resolved, notification, integration]
date: 2026-04-25
resolved: 2026-05-06
status: resolved
priority: medium
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
---

# Overdue Notification Missing (P2.4) — RESOLVED

`overdueAmount > 0` tespit edilip kullanıcıya bildirim gönderilmiyor. Profesyonel POS için SMS/email/WhatsApp otomatik hatırlatma beklentisi.

## Çözüm — Sprint 30

| Bileşen | Konum | Görev |
|---|---|---|
| `OverdueNotificationScheduledJob` | [`finance/job/`](pos-product-manager/src/main/java/com/sedcore/finance/job/OverdueNotificationScheduledJob.java) | Multi-tenant cron (Pzt-Cum 09:00 default), feature flag `overdue.notification.enabled=false` |
| `CustomerAccountRepository.findOverdueWithContact` | [`customer/repository/`](pos-product-manager/src/main/java/com/sedcore/customer/repository/CustomerAccountRepository.java) | JOIN FETCH ile `overdueAmount > 0` + email/phone dolu |
| `AdminOverdueNotificationControllerImpl` | [`finance/controller/impl/`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AdminOverdueNotificationControllerImpl.java) | `POST /api/v1/admin/notifications/overdue/scan` (ROLE_ADMIN, manuel tetik) |
| Frontend hook | [`accounts_summary_bar.dart`](project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart) | Vadesi geçen tile'a tap → confirm dialog → backend tetikle |
| `NotificationService.triggerOverdueScan` | [`services/notification/`](project_pos/lib/services/notification/notification_service.dart) | Dart client metodu |
| application.properties | `pos-product-manager` | `overdue.notification.enabled` + `overdue.notification.cron` config |

**Kanal seçimi**: müşteri email varsa EMAIL preferred (zengin içerik + maliyet), yoksa phone varsa SMS fallback. İkisi de yoksa repository sorgusu zaten filtreliyor.

**Mesaj formatı**:
- EMAIL: full TR template (subject + body) — vadesi geçen tutar + güncel bakiye
- SMS: ASCII-safe kısa mesaj (Twilio karakter limiti)

## Kullanım

```bash
# 1. Manuel test
curl -X POST -H "X-Company-Code: SEDCORE" \
     http://localhost:8001/product/api/v1/admin/notifications/overdue/scan
# → {"data": {"queued": 5, "skipped": 2}}

# 2. Cron'u aktive et
echo "overdue.notification.enabled=true" >> application-prod.properties
```

Frontend: AccountsHub üst bar'da vadesi geçen tile'a tıkla → onay dialog → "Şimdi gönder".

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]
- [[syntheses/notifications-system-design]] — Sprint 25-28 notifications mimari sentezi

## Related

- [[syntheses/integration-catalog]]
- [[entities/customer-account]]
- [[syntheses/integrations-hub-architecture]] — Sprint 23 hub
