---
title: Master-Detail Layout Pattern
tags: [concept, ui, responsive]
date: 2026-04-24
status: verified
---

# Master-Detail Layout

## Tanım
İki bölmeli UI: sol (veya üst) liste = **master**, sağ (veya alt/sonraki ekran) = **detail**. Geniş ekranda yanyana, dar ekranda navigation push.

## SEDCORE'da
[[entities/accounts-hub-screen]] ana örnek:
- Master: [[entities/accounts-list-panel]] (360px fixed genişlik)
- Detail: [[entities/statement-detail-panel]] (expanded)
- Breakpoint: 800px

## Responsive Davranış
- **Geniş**: Row[master | divider | detail]. Seçim detail'i günceller, aynı ekranda.
- **Dar**: Master full screen. Satır tap → `Navigator.push` ile detail. Pop → selection clear (aynı karta tekrar tıklanabilsin).

## State Bridge
İki panel arasında `selectedAccountProvider` (Riverpod StateProvider) köprü — listenin seçtiği, detay'ın watch ettiği tek kaynak. Detay'ın kendi ID parametresi yok.

## Faydası
- Geniş ekranda context-switch maliyeti sıfır
- Dar ekranda standard mobile UX
- Tek provider state = iki panelden de erişim

## Tuzaklar
- Dar ekranda `selectedAccountProvider` pop sonrası temizlenmezse bir sonraki tap "aynı ID" gördüğünde provider tetiklenmez — detail yenilenmez. [[entities/accounts-hub-screen]] `.then((_) → state = null)` ile önlüyor.
- Geniş/dar geçişinde (rotate) provider state korunur → davranış beklenmedik olabilir

## Related
- [[entities/accounts-hub-screen]]
- [[decisions/master-detail-800px-breakpoint]]
