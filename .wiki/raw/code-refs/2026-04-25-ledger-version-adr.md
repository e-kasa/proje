---
title: Ledger Concurrency ADR (pointer)
original-path: C:\Users\Win11\Documents\GitHub\proje\.claude\decisions\2026-04-24-ledger-no-version-accept-reconcile-guard.md
captured-at: 2026-04-25
type: pointer
---

# Pointer → Ledger Concurrency ADR

**Orijinal**: `.claude/decisions/2026-04-24-ledger-no-version-accept-reconcile-guard.md`

AccountTransaction (ledger) için concurrency kararı: **A + D defense-in-depth**. @Version runtime lost-update koruması + periyodik reconcile kümülatif drift düzeltme. İlk sürüm "no @Version" demişti (Sprint 1), Sprint 2'de kod gerçeğine göre revize edildi (@Version zaten vardı). İki katman birbirini tamamlar.
