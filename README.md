# Outlinerz — simplified Sohoj Academy

Working branch: `feature/simplified_version`. The public website, language toggle and academic ERP come from Sohoj Academy master (`00f11f2358516bc7362e1984836f09584085b4e7`). Finance, accounting, fee plans, payment collection, referral rewards and payroll are excluded from the active application.

## Run locally

```bash
git clone https://github.com/AbdusSattar-70/outlinerz.git
cd outlinerz
git switch feature/simplified_version
pnpm install --frozen-lockfile
cp .env.example .env.local
pnpm exec supabase start
pnpm exec supabase db push --local
pnpm dev
```

Set the local Supabase URL and publishable key in `.env.local`. Use the Supabase CLI output for their actual values. The local API exposes the `academy` schema through `supabase/config.toml`.

For an existing checkout:

```bash
git fetch origin
git switch --track origin/feature/simplified_version
git pull --ff-only
pnpm install --frozen-lockfile
```

If the local branch already exists, use `git switch feature/simplified_version` instead of `--track`.

## Hosted Supabase

Link this checkout to the intended Outlinerz project, then push the forward migrations:

```bash
pnpm exec supabase link --project-ref YOUR_PROJECT_REF
pnpm exec supabase db push
pnpm exec supabase migration list
```

In Supabase **Project Settings → Data API**, include `academy` in **Exposed schemas**. Keep the existing exposed schemas. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` to that project’s values. Restart the application after environment changes.

Migrations 01–04 and the installed `public` data are preserved. This version adds migrations 05–10 in a separate `academy` schema. It does not import live Sohoj student/teacher records, reset a database, or require a 22-file migration chain. Migration 05 consolidates the pinned source definitions; migration 06 removes financial stores and installs branch isolation. Typed empty views retain some legacy read response contracts; they store no financial data and accept no financial writes. Financial RPCs are disabled.

## Start operating

1. Sign up and verify your email. Open `/branches` and create your first branch with the institution name.
2. Select the branch. Review its classes, subjects, programmes, offerings and 12-seat starter batches. Every branch receives separate editable records.
3. Add verified staff accounts to that branch. Create their staff records and teaching assignments through the existing Sohoj screens.
4. Review the website/application controls on each offering. Starter offerings are active for internal academic work but hidden from the website, with public intake closed.
5. Share `/?branch=YOUR_BRANCH_SLUG`. The branch selection persists through the website and enquiry form. Optionally set `NEXT_PUBLIC_BRANCH_SLUG` for a single default public campus.
6. Receive applicants through the public form or staff intake. Verify the admission draft, mark it ready, then confirm academic enrollment. No fee plan, invoice or payment is required.

Student, staff, enquiry, admission, batch, session, attendance, assessment, directory and audit records are isolated by database policies and composite foreign keys. A shared login can belong to multiple branches. Changing branch selection never moves or shares operational records.

Future student fees and teacher remuneration will be ported from Sohoj one workflow at a time, with branch scope and audit history.

## Verify

```bash
npm ci --prefix scripts/database
node scripts/simplified/validate.mjs
pnpm typecheck
pnpm lint
pnpm build
```

Database validation runs real PostgreSQL functions and RLS through PGlite with local Supabase identity/storage fixtures. It never connects to a hosted database. The browser integration suite uses a local HTTP adapter backed by the same migrated database; it requires a Chromium executable and the Playwright dependency under `scripts/ui`.
