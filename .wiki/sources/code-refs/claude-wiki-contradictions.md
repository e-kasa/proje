---
title: Contradictions Log (claude-wiki)
type: source
source: .claude/wiki/contradictions.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Contradictions Log

Dokümantasyon, kod ve gözlem arasındaki çelişki kayıtları. Ajan yeni bir çelişki tespit ettiğinde buraya girdi açar.

> **Girdi formatı**:
> ```
> ## YYYY-MM-DD — Kısa Başlık
> - **Kaynak A**: [dosya:satir](path)
> - **Kaynak B**: [dosya:satir](path)
> - **Çelişki**: iki kaynak ne der
> - **Gözlem / Karar**: hangisi doğru kabul edildi, neden
> - **Status**: open | resolved | ignored
> ```

---

## 2026-04-24 — AccountTransaction @Version: ADR vs Kod [RESOLVED]

- **Kaynak A** (ADR, karar): `.claude/decisions/2026-04-24-ledger-no-version-accept-reconcile-guard.md`
- **Kaynak B** (gerçek kod): `pos-product-manager/src/main/java/com/sedcore/finance/entity/AccountTransaction.java:122-124` — `@Version` **zaten var**
- **Çelişki (orijinal)**: ADR "eklenmeyecek" diyordu; kod "zaten eklenmiş".
- **Çözüm (2026-04-24 revize)**: ADR kod gerçeğine göre yeniden yazıldı. Karar "A-only yerine **A + D** (defense-in-depth)" olarak çerçevelendi: `@Version` runtime lost-update koruması + reconcile kümülatif drift düzeltme. İki katman birbirini tamamlar. ADR başlığı/içeriği güncel.
- **Status**: **resolved** (2026-04-24)

---

## Aktif Çelişki Yok

Şimdilik hiçbir açık çelişki yok. Yeni girdi eklenirken **en yeni üste** gelir.
