---
title: Multi-Firma Per-User Mimarisi (Tenant Leak Değil — Tasarım)
type: concept
date: 2026-04-26
status: clarification
purpose: Hibernate @Filter aktif olmadığı durumun "tenant leak" değil intentional design olduğunu netleştir
supersedes-misinterpretation: syntheses/tenant-leak-controller-direct-repository-2026-04-26
---

# Multi-Firma Per-User Mimarisi

## Önemli Düzeltme — Kullanıcı Geri Bildirimi (2026-04-26)

> **"Yanlış geliştirme yapıldı. Sistemimizde firma bazlı arama yapılır."**

Önceki [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] sentezi `/customers?isActive=true` endpoint'inin SEDCORE+SEDCORE1 karışık dönmesini "tenant leak" (security açığı) olarak yorumladı. **Bu yorum YANLIŞ** — sistem mimarisi:

- **Bir kullanıcı birden fazla firmaya sahip olabilir** (örn. otomotiv yedek parça SEDCORE + butik SEDCORE1)
- Backend endpoint'leri **kullanıcının erişimli olduğu TÜM firmalardan** kayıt döner (default davranış)
- **Firma bazlı arama** → frontend UI'dan kullanıcı firma seçer → `companyCode` query parametresi ile filtre
- Hibernate `@Filter("filterByCompanyCode")` **opsiyonel** — eğer aktive edilirse tek firma, edilmezse tümü

## Geri Alınan Hot-Fix v3 (CustomerController Service'e Yönlendirme)

Sprint 8 hot-fix v3 yanlış varsayım üzerine yapıldı:
- ❌ `CustomerService.search()` interface method
- ❌ `CustomerServiceImpl.search()` impl
- ❌ `CustomerControllerImpl.list` `customerService.search()` çağırma

**Tümü `git checkout HEAD --` ile revert edildi** (2026-04-26 son turda).

Backend Maven compile: **exit 0** ✅ (revert sonrası)

## Doğru Davranış Kuralları

### Endpoint Default Davranışı
| Endpoint | Default | UI Filter Yolu |
|---|---|---|
| `GET /customers` | Tüm firmalar (mevcut, doğru) | `?search=zeynep` (query); `?companyCode=X` (firma seçici varsa, eklenebilir) |
| `GET /accounts/list` | ⚠️ Şu an `selectedCompanyCode` ile filter aktif (tek firma) | `?filter=customer&q=...` (mevcut); `?companyCode=X` eklenebilir |
| `GET /suppliers` | Aynı pattern (tüm firmalar) | benzer |

### Frontend Filter UI

POS Cart Panel ve AccountsHub'da **firma seçici dropdown / chip** olmalı:
- Default: "Tüm firmalar" → endpoint'e companyCode parametresi gönderilmez
- Firma seçilince: `?companyCode=X` parametresi backend'e gider → backend bu parametreyi kullanarak filter eder

## Etkilenen Wiki Sayfaları (Yanlış Yorumun İzleri)

| Sayfa | Durum | Aksiyon |
|---|---|---|
| [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] | ❌ Hatalı yorum | **DEPRECATED** olarak işaretle, "doğru bağlam: bu sayfa" link'i ekle |
| [[syntheses/zeynep-customer-not-in-db-2026-04-26]] | ⚠️ Senaryo B "farklı tenant" yorumu | "Multi-firma per-user normal davranış" not ekle |
| [[concepts/troubleshooting-customer-missing-in-accounts-hub]] | ⚠️ Senaryo #4 multi-tenant | "Firma seçici UI eksikse görünmeyebilir" güncellemesi |
| [[concepts/hibernate-filter-runtime]] | ⚠️ §Critical #4 "sessiz tenant leak" | Yeniden değerlendir — gerçekten "leak" mi yoksa intentional opt-in mi |

## Doğru AccountsListService Davranışı (Açık Soru)

[[entities/accounts-hub-screen]] AccountsListService backend'i `selectedCompanyCode` ile filter aktif (sadece tek firma dönüyor — önceki response'ta 4 SEDCORE only). 

**Soru:** AccountsHub kullanıcı firmalarının **hepsini birden** mi göstermeli (Zeynep + Adem + Moda Butik + Usta Oto), yoksa **tek firma seçilip** o firmanın görünmesi mi?

İki tasarım da geçerli olabilir:
- **A)** Tüm firmalar → kullanıcı UI'dan filtre (`/customers` ile tutarlı)
- **B)** Tek firma → "şu an SEDCORE'dasın" göstergesi + firma değiştirici (mevcut davranış)

**Karar gerekli:** Eğer A doğru ise AccountsListService'in filter aktivasyonu da kaldırılmalı.

## Sources

- Kullanıcı geri bildirimi 2026-04-26: "yanlış geliştirme yapıldı. sistemimizde firma bazlı arama yapılır"
- Backend kanıt 16:24: `/customers?isActive=true` 4 kayıt — 2 SEDCORE + 2 SEDCORE1 (intentional)
- Backend kanıt 16:19: `/accounts/list` 4 kayıt — sadece SEDCORE (filter aktif, tasarım sorgulanır)
- Revert: `git checkout HEAD --` ile 3 dosya geri yüklendi (2026-04-26)
- [[concepts/hibernate-filter-runtime]] (Sprint 7 ingest araştırması)

## Related

- [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] (DEPRECATED — yanlış yorum)
- [[concepts/multi-tenant]]
- [[concepts/multi-tenant-routing]]
- [[concepts/company-context]]
- [[concepts/hibernate-filter-runtime]]
