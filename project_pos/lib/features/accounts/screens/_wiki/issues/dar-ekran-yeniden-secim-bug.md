---
title: Dar Ekranda Aynı Hesaba Yeniden Tıklama Detay Açmıyor (Fixed)
tags: [issue, resolved, flutter, riverpod]
date: 2026-04-24
status: resolved
---

# Dar Ekranda Aynı Hesaba Yeniden Tıklama

## Belirti (Potansiyel)
Dar ekran mode'da kullanıcı liste → hesap seçer → detay push olur → geri → **aynı** hesaba tekrar tıklarsa: `selectedAccountProvider` aynı ID'yi tutuyor, state değişmiyor → provider tetiklenmez → detay açılmaz.

## Kök Neden
`Navigator.push` sonrası pop'ta state kalmış:
- `selectedAccountProvider.state = args` → değeri `X`
- Pop → widget ağacı güncel
- Kullanıcı aynı satıra tekrar tıklar → `selectedAccountProvider.state = args` → değer yine `X`
- Riverpod "same value = no listener notification" → detay widget rebuild olmaz

## Fix
[[entities/accounts-hub-screen]] `_selectFromList` dar ekran branch'inde push `.then((_) → selectedAccountProvider.state = null)`:

```dart
Navigator.of(context).push(MaterialPageRoute(builder: (_) => _AccountDetailPage()))
  .then((_) {
    // Detail kapanınca seçimi temizle (yeni cari seçilebilsin)
    ref.read(selectedAccountProvider.notifier).state = null;
  });
```

Pop sonrası `null`'a çekilir → tekrar tıklama artık farklı değer → listener notify edilir.

## Related
- [[entities/accounts-hub-screen]]
- [[concepts/master-detail-layout]]
- [[entities/selected-account-provider]]
