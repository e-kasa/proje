---
title: Customer/Supplier Activity Log Yok (OPEN)
tags: [issue, open, audit]
date: 2026-04-25
status: open
priority: low
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
---

# Activity History Missing (P2.6)

Customer/Supplier düzenlemelerinin tarihsel kaydı yok. "creditLimit'i geçen hafta kim değiştirdi?" cevabı yok.

**Aksiyon**: Hibernate Envers (`@Audited`) veya custom `AuditLog` entity.

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[entities/customer]]
- [[entities/supplier]]
