CRM content refresh fix: bare public URLs resolve the verified selected organization when no public slug/default is given. Successful management saves refresh same-organization public tabs; public pages also reload on focus. Anonymous deployments still require an explicit public URL or configured default slug. No new migration.

Current CRM organization management: `/dashboard/crm/website` preserves the original Sohoj presentation and configures bilingual identity/content, image assets, contacts and offering publication. Apply `04_crm_site_management.sql` after the existing migrations. Database validation: 95 checks. UI validation: 12 mocked browser checks; build/typecheck pass and lint has 16 existing warnings.

# Outlinerz current handoff

See [Organization onboarding](OUTLINERZ_ONBOARDING.md) for the current implementation and local commands. Applied baseline: `01_outlinerz_eduops_baseline.sql` (unchanged). Forward migration: `02_organization_onboarding.sql`. Active feature branch: `feature/organization-onboarding`.

Public pages, auth, organization selection/onboarding, dashboard/setup and CRM consumers are wired to the new schema. See [CRM interface](OUTLINERZ_CRM.md) for `03_crm_interface.sql`, public slug configuration and validation. Other legacy modules/types remain for later feature slices; their dashboard routes redirect to the implemented home. Do not reset or rename the applied baseline. The validator now discovers the actual migration filenames and exercises the forward migration.

The following is historical database-foundation context, with original repository/filename assumptions. Current Outlinerz instructions above take precedence.

# Lean EduOps development handoff

Active branch: `feature/lean-modular-eduops`.

The user explicitly requested a database written from scratch instead of installing 01–22. This branch removes that historical migration/test set and installs one newly authored `20261004000000_lean_eduops_baseline.sql`. Master/Git history preserve the old ERP. Do not reset or upgrade a deployed legacy database with this baseline.

Read [Fresh setup](FRESH_DATABASE_SETUP.md), [New schema and implemented limits](DATABASE_SCHEMA.md), [Product blueprint](LEAN_EDUOPS_BLUEPRINT.md), [Target workflows](LEAN_EDUOPS_WORKFLOWS_BN.md), and [Implementation plan](LEAN_EDUOPS_IMPLEMENTATION_PLAN.md).

## Implemented database foundation

55 public tenant-owned/application tables plus 2 private helper tables. Organization memberships/module presets, relational academic/CRM/student/business foundations, role/RLS boundaries, composite tenant foreign keys, private storage policy, audit, immutable financial evidence, atomic course/admission, fee payments/refunds, operational expenses/transfers/advances/payables/purchases/assets, teacher session completion and optional event-to-journal projection.

Accounting is OFF by default; operational transactions work without journals. No hard-coded school programme, branch capacity or fee. No digital consent model or admission consent gate. No legacy function patches, renamed wrapper RPCs or concatenated migrations.

## Validation

Run `npm --prefix scripts/database ci` then `npm --prefix scripts/database test`. The final validator applies the complete baseline and runs 45 assertions in isolated PGlite, with Supabase Auth/Storage mocked. Default hosted public-table grants are simulated then explicitly revoked. These checks are not hosted Auth/Storage/CLI validation, real concurrent-connection testing, browser acceptance or production deployment. No live project was migrated/reset.

## App compatibility — must resolve next

**The current Next.js app and generated `types/database.ts` still use the old schema/RPCs. They will not operate against this baseline.** Do not change existing deployment credentials. Build success of that app would not prove compatibility with this new database.

Next feature: inspect legacy auth/setup and create new organization-aware session/context/onboarding against create_organization, memberships, branches and directory policies. Generate the new TypeScript database contract from a disposable Supabase install, replace affected consumers and verify tenant A/B behavior. Then course UI, direct admission/CRM conversion, operational fee collection and academic/business slices proceed independently. Update roadmap with actual completed app contracts, not merely table presence.

Remaining API/product gaps are listed in DATABASE_SCHEMA.md. Specifically: public enquiry endpoint/rate limiting, full teacher roster/reviews/tasks APIs, recurring job, transfer/withdrawal, multi-invoice/unallocated payments, compensation calculation, purchase correction/asset sale, accounting worker/cutover/reconciliation, daily close/reports and full owner UX. Foundations are not claims of completed SaaS functionality.

## Evolution

Only new EMPTY public schemas can install the baseline; it fails before changing a nonempty public schema. Once this baseline is installed anywhere, append new timestamped migrations for future changes; never silently edit that installation's applied baseline. Hosted CLI/Auth/Storage acceptance and recovery rehearsal must precede release.
