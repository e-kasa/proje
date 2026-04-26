---
title: JWT Authentication
tags: [concept, auth, security]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
date: 2026-04-25
status: stub
---

# JWT Auth

[[entities/security]] servisi login sonrası JWT issue eder. Token içinde `userId`, `companyCode`, `roles` bulunur. [[entities/api-manager]] gateway her istekte token doğrulanır, thread-local `CompanyContext` set edilir (bkz. [[concepts/multi-tenant]]).

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]
- `.claude/reference/jwt-payload.md`

## Related

- [[entities/api-manager]]
- [[entities/security]]
- [[concepts/multi-tenant]]
