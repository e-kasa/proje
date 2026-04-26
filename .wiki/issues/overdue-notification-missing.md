---
title: Vadesi Geçen Bildirim Yok (OPEN)
tags: [issue, open, notification, integration]
date: 2026-04-25
status: open
priority: medium
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
---

# Overdue Notification Missing (P2.4)

`overdueAmount > 0` tespit edilip kullanıcıya bildirim gönderilmiyor. Profesyonel POS için SMS/email/WhatsApp otomatik hatırlatma beklentisi.

**Aksiyon**: Scheduled job + NotificationService + sektör bazlı template.

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[syntheses/integration-catalog]]
- [[entities/customer-account]]
