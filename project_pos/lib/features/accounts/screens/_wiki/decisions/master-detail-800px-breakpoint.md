---
title: Master-Detail Breakpoint 800px
tags: [decision, ui, responsive]
date: 2026-04-24
status: active
---

# Master-Detail Breakpoint 800px

## Karar
[[entities/accounts-hub-screen]] responsive layout breakpoint = **800px**. `≥800` → row (liste 360px + detail expanded), `<800` → liste full screen + tap'te detail push.

## Neden
- 800px standart tablet landscape (iPad mini 768 aslında dar sayılır ama yeterli, çoğu tablet 810+)
- 360px liste genişliği — customer/supplier ismi + bakiye okunabilir min (trial-and-error)
- Dar ekranda push akışı standart Flutter mobile UX

## Alternatifler
- 600px — fazla dar, iki panel sıkışık
- 1024px — desktop-only eşik; 768 tabletlerde push UX mantıksız
- Kullanıcı config — overkill

## Related
- [[entities/accounts-hub-screen]]
- [[concepts/master-detail-layout]]
