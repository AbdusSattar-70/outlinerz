# Lean Modular EduOps — Database Foundation

This branch rebuilds the database from scratch for configurable coaching/tuition operations. Sohoj Academy becomes an organization, with organization-scoped data and modular Academic/CRM/Finance/Business features. Advanced accounting is optional and downstream.

**Current phase: new database foundation. Existing Next.js pages, modules and types still target the legacy ERP and are not yet compatible. Do not connect the existing deployment to this database.**

Start with [Fresh database setup](docs/architecture/FRESH_DATABASE_SETUP.md), [Schema contract and limits](docs/architecture/DATABASE_SCHEMA.md), [Handoff](docs/architecture/DEVELOPMENT_HANDOFF.md), [Blueprint](docs/architecture/LEAN_EDUOPS_BLUEPRINT.md), [Bangla workflows](docs/architecture/LEAN_EDUOPS_WORKFLOWS_BN.md), and [Roadmap](docs/architecture/LEAN_EDUOPS_IMPLEMENTATION_PLAN.md).

One newly authored baseline: `supabase/migrations/20261004000000_lean_eduops_baseline.sql`. Historical 01–22 migrations and old-contract tests are removed from this branch, preserved in master/Git history. This baseline requires a new empty Supabase project; it is not a legacy upgrade.

Database checks:

```bash
npm --prefix scripts/database ci
npm --prefix scripts/database test
```

PGlite checks cover atomic commands, permissions, tenant references, financial limits, retries and optional accounting; Supabase Auth/Storage are mocked. Hosted installation and frontend compatibility remain pending. Each subsequent feature should update its database contract, app consumers and meaningful validation together.
