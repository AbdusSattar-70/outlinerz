# Outlinerz CRM interface

This feature stays on `feature/organization-onboarding`. It restores the Sohoj public page layout, programme cards, interest/admission enquiry form, searchable prospect queue and master-data editor. The sidebar uses the source UI components with organization membership and role checks. The Sohoj presentation is a reusable template; organization branding and bilingual public copy are configured separately in `/dashboard/crm/website`. EN and বাংলা are separate, persistent language choices. A self-hosted Noto Sans Bengali variable font (SIL Open Font License, included beside the font) keeps Bengali readable without Google font requests or an installed system font.

## Local update

```bash
git switch feature/organization-onboarding
git pull --ff-only origin feature/organization-onboarding
pnpm install --frozen-lockfile
pnpm exec supabase db push
pnpm exec supabase migration list
pnpm dev
```

Keep the installed `01_outlinerz_eduops_baseline.sql` unchanged. The forward migrations are `02_organization_onboarding.sql`, `03_crm_interface.sql` and `04_crm_site_management.sql`. These commands apply pending changes; never run a remote reset.

Public links select an organization explicitly: `/?organization=your-slug` and `/interest?organization=your-slug`. For one organization's default public website, set `NEXT_PUBLIC_ORGANIZATION_SLUG=your-slug` in `.env.local`. Use the existing project's Supabase URL and publishable key. When neither an explicit public slug nor a configured default is present, signed-in visits resolve the selected organization only after verifying the user and active membership. Anonymous visits without either retain the template and empty catalogue; never choose an arbitrary tenant.

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

The database suite runs 95 assertions in isolated PGlite with mocked Auth/Storage. It verifies tenant isolation, controlled roles, stable retries, public projections, capacity/fee results, atomic follow-up, lost reason, immutable history, consent-free enquiries and intake limits.

Browser contracts use a local mocked Supabase HTTP server, never hosted credentials. Ports 54321 and 3100 must be free. Build with the local test settings before running:

```bash
npm --prefix scripts/ui ci --ignore-scripts
npm --prefix scripts/ui exec -- playwright install chromium
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321 NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=local-smoke-key pnpm build
npm --prefix scripts/ui test
```

An existing executable can be supplied with `UI_CHROMIUM_PATH=/path/to/chromium`. The browser suite checks persisted language changes, tenant links, public submission/acknowledgement, queue filtering, profile/follow-up, master editing and mobile layout. The new settings are covered by database permission, idempotency, conflict, audit and public projection checks, plus a mocked browser management-to-public update check. Mock browser sessions test presentation/API contracts, not hosted Auth security. Rebuild with your real local settings before using your Supabase project.

## Remaining scope

The unified course wizard, direct student admission, academic operations, operational finance and other legacy ERP routes need their own fresh-schema ports. Those routes remain redirected to the dashboard. Programme cards display published database offerings; the CRM management dashboard edits publication copy, visibility and intake state for existing offerings. Creating offerings remains part of the course workflow. Hosted signup/email, real multi-user sessions and live migration acceptance still require the user's Supabase environment. No hosted database was changed during development.

## Organization management dashboard

Owner/admin access: `/dashboard/crm/website`. The original Sohoj homepage, About, FAQ and Journal element styling is retained from source commit `00f11f2358516bc7362e1984836f09584085b4e7`; names, original image logo treatment and images are data bindings rather than a new interface. The prospect detail structure and acknowledgement print styling also come from that source. EN/বাংলা remains a persistent language toggle.

Identity fields cover English/Bangla names, full logo and logo mark URLs, classroom and learning images, phone, email and address in both languages. The separate management page contains grouped bilingual editorial fields for the home, About, FAQ, Journal and registration pages, along with programme publication controls. Asset fields accept a local public path or an HTTPS image URL. The source logo/images are the initial template assets; replace them with each organization's assets in management.

`crm_sites` stores one configuration per organization. Only owners/admins can read its management table. Saves check the selected organization on the server and database, require CRM enabled, compare the revision, preserve stable request retries, update the canonical organization name atomically and record audit history. Public visitors use a bounded projection by organization slug; private membership and organization identifiers are excluded. Public page titles use the configured organization name. Contacts appear in the existing footer; no settings controls appear on the public pages.

Existing offering publication edits use an expected-value comparison, scoped row lock and stable command request. They change the display name, bilingual card copy, schedule/requirements/admission policy, website visibility and intake status. Fees, enrollments, capacity and academic references stay with their operational workflows. Directory controls remain at `/dashboard/crm/manage`.

## Management edits and CRM refresh

The bare CRM URL `/` previously ignored the ERP selection cookie and showed the template when `NEXT_PUBLIC_ORGANIZATION_SLUG` was unset. Public pages now resolve the explicit query slug, then configured public default, then the signed-in user's verified active organization selection. The cookie alone is never sufficient authorization. This resolution also applies to About, FAQ, Journal, interest registration, programme data and page titles.

Successful management saves notify open public tabs for the same organization through a same-origin browser channel. Public tabs refresh their server content on that notification and when focused. This updates already-open pages without changing their presentation. Other browsers receive current content on reload or when returning to the page. Public visitors who are not signed in must use the organization-specific Preview website URL or the deployment's configured default slug.

The browser suite now covers the actual failure path: keep `/` open in one tab, save identity/content in the management tab, and verify that the already-open page updates. It also rejects forged organization selection cookies and verifies that explicit public links still take precedence. Twelve browser checks pass; no additional database migration is required for this fix.
