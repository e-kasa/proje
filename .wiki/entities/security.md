---
title: security (Auth Servisi)
tags: [entity, service, auth, jwt, spring]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
date: 2026-04-25
status: stub
---

# security

Kimlik doğrulama, kullanıcı yönetimi, rol tanımı ve i18n anahtarlarını barındıran auth servisi.

- **Port**: 8002
- **Context path**: `/security`
- **Sorumluluk**: Login, JWT issue, UserDef/Role/UserDefAccess, menu_items, message_definitions (i18n)
- **Seed**: `security/src/main/resources/data.sql` — kullanıcı + rol + i18n her başlatmada yüklenir

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]
- `security/CLAUDE.md`

## Related

- [[entities/api-manager]]
- [[concepts/jwt-auth]]
- [[concepts/i18n]]
- [[concepts/multi-tenant]]
