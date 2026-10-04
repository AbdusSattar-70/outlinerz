# Outlinerz

Organization-aware coaching and tuition operations built with Next.js and Supabase.

The applied baseline is `supabase/migrations/01_outlinerz_eduops_baseline.sql`; it is preserved. See [Organization onboarding](docs/architecture/OUTLINERZ_ONBOARDING.md) and [CRM interface and local update](docs/architecture/OUTLINERZ_CRM.md) for implementation and forward migration instructions.

Implemented entry flow: owner sign-up/sign-in → organization creation or selection → first branch → setup academic years/classes/subjects → scoped dashboard. The Sohoj public/CRM layouts, EN/বাংলা toggle, enquiry intake, prospect follow-up and master-data editor now use the fresh tenant schema. Owners/admins can manage bilingual organization identity, logos/images, public page copy and programme publication at `/dashboard/crm/website` while preserving the source presentation. Other legacy ERP modules are awaiting migration; their dashboard routes redirect to the dashboard. No database reset is needed.

Database checks:

```bash
npm --prefix scripts/database ci
npm --prefix scripts/database test
```

PGlite checks cover atomic commands, permissions, tenant references, financial limits, retries and optional accounting; Supabase Auth/Storage are mocked. Hosted installation and Auth acceptance remain pending. Database and mocked browser checks cover the migrated consumers. Each subsequent feature should update its database contract, app consumers and meaningful validation together.
