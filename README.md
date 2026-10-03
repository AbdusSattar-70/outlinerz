# Outlinerz

Organization-aware coaching and tuition operations built with Next.js and Supabase.

The applied baseline is `supabase/migrations/01_outlinerz_eduops_baseline.sql`; it is preserved. Start with [Organization onboarding and review](docs/architecture/OUTLINERZ_ONBOARDING.md) for the current app slice and forward migration instructions.

Implemented entry flow: owner sign-up/sign-in → organization creation or selection → first branch → setup academic years/classes/subjects → scoped dashboard. Legacy modules are awaiting migration; their dashboard routes are held behind the new entry flow. No database reset is needed.

Database checks:

```bash
npm --prefix scripts/database ci
npm --prefix scripts/database test
```

PGlite checks cover atomic commands, permissions, tenant references, financial limits, retries and optional accounting; Supabase Auth/Storage are mocked. Hosted installation and frontend compatibility remain pending. Each subsequent feature should update its database contract, app consumers and meaningful validation together.
