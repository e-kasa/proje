---
title: Birleşik Müşteri+Tedarikçi Listesi (Split Değil)
tags: [decision, ux, list]
date: 2026-04-21
status: active
---

# Birleşik Müşteri+Tedarikçi Listesi

## Karar
[[entities/accounts-list-panel]] müşterileri ve tedarikçileri **tek liste** olarak gösterir. Filter tabs (tümü / müşteri / tedarikçi / vadesi geçen) ile alt grup görünür.

## Neden
- Çoğu kullanıcı hem müşteri hem tedarikçi bakiyesi kontrol ediyor — tek tıklama erişim
- İki tab UI'ı (ayrı liste) = daha fazla navigasyon + scroll durumu kaybı
- Filter "tümü" default → genel bakış hızlı
- "Vadesi geçen" filter her iki taraftan aynı ekranda gösterir (ödenmedikleri iş akışı)

## Uygulama
`accountsListProvider` — merged list:
```
/customers + /suppliers → 2 paralel fetch → merge → accountType ile zenginleştir
```

Her satırda `StatementArgs` (accountType + accountId + accountName) → seçimde `selectedAccountProvider` set.

## Related
- [[entities/accounts-list-panel]]
- [[decisions/rename-balance-to-currentbalance]] (DTO simetrisi bu karar için gerekli)
- `.claude/wiki/flows/accounts-hub-load.md`
