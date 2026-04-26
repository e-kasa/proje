---
title: Karar — Dart-Dio Generator Seçimi
tags: [decision, openapi, flutter, dio]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\openapi-codegen-flutter.md
---

# Dart-Dio Generator

## Karar

OpenAPI generator seçenekleri arasından `dart-dio` tercih edildi. Alternatifler: `dart` (vanilla HTTP), `dart-dio-next` (stable değil).

## Gerekçe

`project_pos/pubspec.yaml` içinde `dio: ^5.4.3` zaten mevcut — aynı HTTP stack ile uyumlu.

## Sources

- [[raw/code-refs/2026-04-25-openapi-codegen-pattern]]

## Related

- [[decisions/openapi-incremental-migration]]
