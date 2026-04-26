---
title: AccountEditForm UX — Inline vs Popup Kararı
type: synthesis
source: .claude/wiki/syntheses/account-edit-form-ux.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# AccountEditForm UX — Inline vs Popup Kararı

Cari Hesaplar hub'ında müşteri/tedarikçi oluşturma ve düzenleme formu (`AccountEditForm`) sunum şeklinin gerekçeli analizi. Mevcut `create=inline + edit=modal` asimetrisi → `create=modal + edit=modal` simetrisine geçiş kararı.

## Bağlam

[`AccountEditForm`](../../project_pos/lib/features/accounts/widgets/account_edit_form.dart), customer ve supplier için polimorfik CRUD formudur: `initialType` (CUSTOMER/SUPPLIER), opsiyonel `editingId` + `initialData` ile create/edit ikili modda çalışır. 11 alan barındırır (name, phone, email, address, taxNumber, taxOffice, contactName, website, creditLimit, paymentTermDays, notes).

Bu form iki farklı yerde çağrılır:

| Yer | Dosya | Sunum Şekli |
|-----|-------|-------------|
| Yeni cari (create) | [`accounts_list_panel.dart`](../../project_pos/lib/features/accounts/widgets/accounts_list_panel.dart) | **Inline** `AnimatedSize` expand/collapse |
| Cari düzenle (edit) | [`statement_detail_panel.dart`](../../project_pos/lib/features/accounts/widgets/statement_detail_panel.dart) | **Modal** `showModalBottomSheet` |

Bu asimetri wiki'ye [[syntheses/accounts-hub-production-readiness#P2.1]] altında "ingest gap" olarak kayıtlı (kaynak [[sources/code-refs/2026-04-21-accounts-hub-screens]] 2026-04-21 tarihli commit `c1a44fe` sonrası eklenmiş).

## Karar: Create de Modal Olsun

Create flow da `showModalBottomSheet` ile açılır. Inline path kaldırılır.

### Gerekçeler

1. **CRUD simetrisi** — Aynı form, aynı sunum. Edit zaten modal — Create'in ayrı davranması öğrenme yükü yaratır.

2. **Dar ekran UX** — `AccountsHubScreen._wideBreakpoint=800` altında liste full-screen. Inline form liste kaydırmasını bozar; modal bottom sheet dar ekranda tam yükseklik açılır (standart Flutter davranışı).

3. **Panel genişliği** — Geniş ekranda liste paneli 360px sabit. 11 alanlı form bu genişlikte sıkışır; modal 600-800px genişlikle form layout'u rahatlatır.

4. **Focus yönetimi** — Modal, backdrop ile form dışına tıklamayı yakalar; inline expand'de kullanıcı form açıkken alttaki listeye tıklayabilir → validation kaybolur.

5. **State sadeleştirme** — `accounts_list_panel.dart` içindeki `_showNewForm` state ve `_NewAccountButton` expand/close ikon mantığı kaldırılır; `_NewAccountButton` tek durumlu kalır.

## Uygulama Planı

### 1. `accounts_list_panel.dart` — inline kaldır
- `_showNewForm` state'i sil, `AnimatedSize` bloğunu sil
- `_NewAccountButton.onTap` → `_openCreateModal(context)` çağır
- `_NewAccountButton.expanded` alanı kaldır (tek durum)

### 2. Yeni metod: `_openCreateModal`

```dart
Future<void> _openCreateModal(BuildContext context) async {
  final initialType = _defaultTypeForFilter(
      ref.read(accountsListProvider).filter);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: AccountEditForm(
        initialType: initialType,
        onSuccess: () => Navigator.of(ctx).pop(),
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}
```

### 3. `AccountEditForm` içi değişiklik yok

Form bu yeni senaryoyu destekliyor (kanıt: edit tarafı aynı API ile çalışıyor). `onSuccess` / `onCancel` callback kontratı korunur.

## Riskler ve Mitigation

| Risk | Mitigation |
|------|------------|
| Modal açıkken geniş ekranda liste seçimi kaybolur mu? | Modal geçici overlay; liste state korunur. Kullanıcı dismiss edince `accountsListProvider.refresh()` yeterli. |
| Mobile'da keyboard ile form overflow | `Padding(bottom: MediaQuery.viewInsets.bottom)` zaten üst örnekte var. |
| Form açıkken yeni cari seçilemesin isteği | Modal dismiss olana kadar parent inert — beklenen davranış. |

## Kapsam Dışı

- `AccountEditForm` alan şemasında değişiklik (alan ekle/çıkar)
- Validation kuralları değişikliği
- Backend endpoint değişikliği

## İlgili

- [[syntheses/accounts-overview]]
- [[syntheses/accounts-hub-production-readiness]] (P2.1 gap maddesi kapatılır)
- [[syntheses/flow-accounts-hub-load]]

## Sources

- [[sources/code-refs/2026-04-21-accounts-hub-screens]]
- Kullanıcı talebi 2026-04-24 — "ekleme kartını popup olarak açılmasını istiyoruz"
