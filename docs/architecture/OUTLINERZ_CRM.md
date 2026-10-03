# Outlinerz CRM interface

This feature stays on `feature/organization-onboarding`. It restores the Sohoj public page layout, programme cards, interest/admission enquiry form, searchable prospect queue and master-data editor. The sidebar uses the source UI components with organization membership and role checks. Branding is Outlinerz; EN and বাংলা are separate, persistent language choices. A self-hosted Noto Sans Bengali variable font (SIL Open Font License, included beside the font) keeps Bengali readable without Google font requests or an installed system font.

## Local update

```bash
git switch feature/organization-onboarding
git pull --ff-only origin feature/organization-onboarding
pnpm install --frozen-lockfile
pnpm exec supabase db push
pnpm exec supabase migration list
pnpm dev
```

Keep the installed `01_outlinerz_eduops_baseline.sql` unchanged. The forward migrations are `20261004003000_organization_onboarding.sql` and `20261004010000_crm_interface.sql`. These commands apply pending changes; never run a remote reset.

Public links select an organization explicitly: `/?organization=your-slug` and `/interest?organization=your-slug`. For one organization's default public website, set `NEXT_PUBLIC_ORGANIZATION_SLUG=your-slug` in `.env.local`. Use the existing project's Supabase URL and publishable key. A missing slug shows an empty catalogue and unavailable registration, rather than choosing an arbitrary tenant.

## Implemented behavior

- Owner/admin maintain academic years, classes, groups, subjects, reusable programmes, schools, lead sources and guardian relationships. Deactivation preserves linked history. Stable mutation IDs reject changed retries.
- Owner/admin/operator record follow-up, update NEW / CONTACTED / INTERESTED / LOST, schedule the next task and assign active tenant members. Academic staff can read prospects. Only actual admission can create ADMITTED.
- The profile preserves original application preferences, student/contact details and follow-up history. Completed history cannot be overwritten.
- Public catalogue reads explicit safe projections, current effective fees and actual batch capacity. Public academic choices and schools are checked against the selected tenant.
- Public form creates a prospect and printable acknowledgement, without a login, invoice, student account or required digital consent. Reusing a request does not duplicate it. Database-enforced rate limits allow three enquiries per phone per hour and 100 public enquiries per tenant per calendar hour; these also protect direct RPC calls.
- Disabled CRM blocks writes and public intake/catalogue while authorized staff can read history.

The applied schema's programme, offering, class and subject models remain separate. Four normalized CRM directories and prospect/follow-up fields are added by the forward migration. Legacy tables, stages and permission RPCs are not reintroduced.

## Validation

```bash
npm --prefix scripts/database ci --ignore-scripts
npm --prefix scripts/database test
pnpm typecheck
pnpm lint
pnpm build
```

The database suite runs 79 assertions in isolated PGlite with mocked Auth/Storage. It verifies tenant isolation, controlled roles, stable retries, public projections, capacity/fee results, atomic follow-up, lost reason, immutable history, consent-free enquiries and intake limits.

Browser contracts use a local mocked Supabase HTTP server, never hosted credentials. Ports 54321 and 3100 must be free. Build with the local test settings before running:

```bash
npm --prefix scripts/ui ci --ignore-scripts
npm --prefix scripts/ui exec -- playwright install chromium
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321 NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=local-smoke-key pnpm build
npm --prefix scripts/ui test
```

An existing executable can be supplied with `UI_CHROMIUM_PATH=/path/to/chromium`. The browser suite checks persisted language changes, tenant links, public submission/acknowledgement, queue filtering, profile/follow-up, master editing and mobile layout. The production build, TypeScript check, 79 database assertions and nine browser checks passed. Lint has no errors and 16 existing warnings. Desktop/mobile screenshots were reviewed with Bengali glyphs rendered. Mock browser sessions test presentation/API contracts, not hosted Auth security. Rebuild with your real local settings before using your Supabase project.

## Remaining scope

The unified course wizard, direct student admission, academic operations, operational finance and other legacy ERP routes need their own fresh-schema ports. Those routes remain redirected to the dashboard. Programme cards display published database offerings; this commit does not introduce an offering publication editor. Hosted signup/email, real multi-user sessions and live migration acceptance still require the user's Supabase environment. No hosted database was changed during development.
