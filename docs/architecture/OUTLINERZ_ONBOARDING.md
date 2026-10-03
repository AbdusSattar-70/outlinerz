# Outlinerz: review and organization onboarding

Branch: `feature/organization-onboarding`.

## Review decisions

The repository combines the newly installed Outlinerz baseline with legacy Sohoj pages, types and RPC consumers. The owner dashboard previously depended on `my_erp_context`, which is absent from the new schema. The validator also referenced the earlier migration filename instead of the deployed `01_outlinerz_eduops_baseline.sql`.

The first vertical feature replaces the public landing/account entry/dashboard/setup path with an organization-aware foundation. Keep the applied baseline unchanged. Add a forward migration for atomic, retry-safe organization and first-branch onboarding. Membership is verified from Auth identity and RLS on every request. A cookie only selects among verified active memberships; it is never authorization. Multiple memberships require selection; invalid/revoked selection returns to the picker. Accounting is optional and not a setup prerequisite.

Use a narrow typed Supabase contract in `modules/organizations/database.ts` for this slice. Legacy `types/database.ts` remains for unmigrated consumers; full generated schema types and subsequent feature migration remain pending. No service-role client is used by these user workflows.

## What works in this slice

Owner sign-up/confirmation/sign-in → create organization and first branch → OWNER membership → setup academic years/classes/subjects → organization-scoped dashboard. Existing manually bootstrapped owners can sign in without creating another organization. Multiple organizations can be selected/switched. Sign out clears the selector; proxy keeps refreshed/cleared Auth cookies on redirects. Suspended/revoked membership cannot use another organization's data.

Onboarding carries one request UUID for unchanged retries; database creation, membership, modules and branch commit together. Changed inputs with the same successfully used request are rejected. Setup name uniqueness prevents duplicate class/subject/year creation. This UI currently adds records; edit/deactivate/invites/courses are future slices.

Legacy dashboard URLs redirect to the implemented home before their incompatible pages execute. Existing server action authorization/RLS remains; the proxy is UX routing, not the security boundary. Legacy public academy content outside the new landing and account entry is still pending cleanup. Fee/CRM/academic/business navigation is not exposed as working features merely because tables exist.

## Local commands

```bash
git switch feature/organization-onboarding
pnpm install --frozen-lockfile
pnpm exec supabase db push --dry-run
pnpm exec supabase db push
pnpm exec supabase migration list
npm --prefix scripts/database ci
npm --prefix scripts/database test
pnpm typecheck
pnpm lint
pnpm build
pnpm dev
```

Do not reset your deployed project. Migration history should contain `01` and `20261004003000`. Fill `.env.local` with the current Outlinerz project's URL/publishable key, and configure localhost Site URL plus `/auth/confirm` and `/auth/update-password` redirects in Supabase. Owner sign-up follows your project's email confirmation policy. Native Auth signup rate limits/email delivery are hosted acceptance responsibilities.

The validator discovers ordered SQL filenames and checks baseline plus forward migration. Added scenarios cover founder ownership, atomic branch creation, unchanged retry, changed inputs, slug collision and outsider membership invisibility. PGlite mocks Auth/Storage; real signup/email/refresh/multi-connection tests are still required locally against your Supabase project.

Dependency review found the lockfile selected lucide-react 1.51.0 inside the environment's release-age quarantine. Pinning the already requested 1.47.0 with its registry integrity lets the unchanged supply-chain policy pass. The optional unrs-resolver build script is explicitly disabled; no approval policy or release-age threshold is relaxed.

Next: unified course wizard, including programme reuse, offering/fee/optional batch against `create_course`. Broader teacher/CRM/fees/business workflows follow in separate feature commits.

Build review: remote Google font loading was intermittent and failed inside the Next font loader on repeat builds. The new product entry uses local system font stacks, including Bengali fallbacks, so compilation no longer needs Google font downloads. Full hosted Auth/email/browser acceptance is still separate.

## Verification result for this delivery

- 52 isolated PostgreSQL assertions passed, including the forward onboarding migration.
- Full TypeScript check passed; production build passed after removing remote font loading.
- Lint passed with 21 existing warnings in legacy modules and no errors. Two existing blocking lint errors were repaired while verifying the auth/entry slice.
- Seven local HTTP smoke checks passed: public landing/sign-in/sign-up return 200; anonymous onboarding/organization/dashboard/legacy-dashboard requests reach sign-in. These used dummy local connection settings without real Auth sessions.
- Browser visual/interaction QA could not run because no Chromium executable is installed. Real signup/email, signed-in hosted navigation, cookie refresh and concurrent sessions remain acceptance work.
- The initial GitHub write denial was resolved after permission was granted; onboarding was published as `a8d295d` on `feature/organization-onboarding`.

For the subsequent Sohoj CRM interface port, language toggle and browser verification, see [CRM interface](OUTLINERZ_CRM.md).
