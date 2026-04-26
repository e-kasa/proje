---
title: AppColors — Flutter tasarım sistem paleti
type: concept
source: project_pos/lib/core/theme/app_colors.dart
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# AppColors Palette

## Tanım

Tüm Flutter ekranlarının tek renk kaynağı (constants holder). **Theme switcher değil** — tasarım sistemi paleti, dark/light mode geçişi yok.

## Kod Konumu

- `project_pos/lib/core/theme/app_colors.dart:3`

## Renk Grupları

### Primary
- `primary` `0xFF667eea`
- `primaryDark`, `primaryLight`
- `secondary` `0xFF8b5cf6`

### Status
- `success` `0xFF10b981`
- `warning` `0xFFf59e0b`
- `danger` `0xFFef4444`
- `info` `0xFF3b82f6`

### Neutral
- `dark`, `light`, `white`, `bgWhite`
- `border` `0xFFe5e7eb`

### Text
- `textPrimary` `0xFF111827`
- `textSecondary`, `textMuted`

### Background
- `bgLight`, `bgSuccess`, `bgWarning`, `bgDanger`, `bgInfo`

### Accent
- `purple`, `pink`, `indigo`, `teal`, `orange`, `cyan`

### Gradient
- `gradientStart` `0xFF667eea` → `gradientEnd` `0xFF764ba2`

## Kullanım

```dart
import 'package:project_pos/core/theme/app_colors.dart';

Container(color: AppColors.bgLight, child: ...);
Text('...', style: TextStyle(color: AppColors.textPrimary));
```

Statik referans — runtime tema değişimi yok. Yeni ekran yazılırken hardcoded `Colors.X` yerine `AppColors.X` kullan.

## Related

- [[entities/project-pos]]
- [[entities/accounts-hub-screen]]
- [[concepts/batch-row-status]] — chip rengi seçimi
