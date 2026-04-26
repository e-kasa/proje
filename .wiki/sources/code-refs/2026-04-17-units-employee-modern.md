---
title: Units + Employee List Modernizasyon
type: source
source: .claude/wiki/sources/code-refs/2026-04-17-units-employee-modern.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Units + Employee List Modernizasyon

## Amaç
`UnitsScreen` (Birimler) ve `EmployeeListScreen` ekranlarını modern list + detail paneli ve standart CRUD pattern'ine taşımak.

## Ne Yapıldı

1. **UnitsScreen**: Eski form tabanlı ekran → BaseEntityListScreen türevi
2. **EmployeeListScreen**: Liste + detay panel ayrımı, standart filter + search
3. Her iki ekran da `base_entity_list_screen` soyut widget'ını kullanıyor

## Değişen Dosyalar

- project_pos/lib/features/settings/screens/units_screen.dart
- project_pos/lib/features/hrm/screens/employee_list_screen.dart

## Raw Pointer

`commit: 88a8e08` — `refactor(flutter-ui): units_screen + employee_list_screen modernizasyonu`

## Kararlar

- [[decisions/base-entity-list-screen-adoption]] — Tüm CRUD ekranları ortak abstract widget'a migrate

## İlgili

- [[concepts/pattern-base-entity-list-screen]] — abstract pattern
