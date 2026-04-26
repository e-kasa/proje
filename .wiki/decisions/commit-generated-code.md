---
title: Karar — Generated Kod Commit'lenir (Git Ignore Değil)
tags: [decision, openapi, ci, git]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\openapi-codegen-flutter.md
---

# Generated Code Commit

## Karar

`lib/api/generated/` git'e commit edilir. `.gitignore`'a eklenmez.

## Gerekçe

- CI reproducibility — build için ek step gerekmez
- Code review'da generated diff görülür (backend schema değişikliği kimin etkisi net)
- Faz A/B/C migration takibi commit'ler üzerinden

## Trade-off

- ❌ Repo boyutu büyür
- ✅ Build süresi azalır (her pipeline'da regen yok)

## Sources

- [[raw/code-refs/2026-04-25-openapi-codegen-pattern]]

## Related

- [[decisions/openapi-incremental-migration]]
