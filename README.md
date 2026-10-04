# Outlinerz — simplified Sohoj Academy

Fresh database version on `feature/simplified_version`. Sohoj's website, academic ERP and English/বাংলা toggle are retained. Accounting, fees, billing, payroll and referral rewards are excluded. Academic enrollment requires no financial setup.

## Start with a new Supabase project

Do not use this migration history against the previous Outlinerz database. Create a new Supabase project first.

```bash
cd ~/all-projects/outlinerz
git fetch origin
git switch feature/simplified_version
git pull --ff-only
pnpm install --frozen-lockfile
pnpm exec supabase link --project-ref YOUR_NEW_PROJECT_REF
pnpm exec supabase db push
pnpm exec supabase migration list
```

The schema now has focused, final-state migrations (01–09), rather than replaying Sohoj's history. They define academic tables, branch identity, admissions/students, teaching, CRM/workforce, constraints/indexes, access/audit, operational roles and the separate demo seed function. Financial tables, empty financial views, financial functions and financial storage columns are not installed. The application uses `public`; `academy_private` stays private.

### If you already installed the previous experimental baseline

This is a replacement migration history, not an incremental upgrade. **Do not run `db push` over that schema.** For a disposable testing project, pull this branch and rebuild it:

```bash
pnpm exec supabase projects list
pnpm exec supabase db reset --linked --no-seed
pnpm exec supabase migration list
```

The reset erases application data. Check the linked project before confirming. The custom executor role is reused, so no manual role cleanup is required. Demo data is created when you open a branch again. Use a new project instead if you need to retain the old project's data. No reset is needed when installing into a genuinely empty project.

Update `.env.local` with the **new project's** URL and publishable key:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_NEW_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_NEW_PROJECT_PUBLISHABLE_KEY
```

Set the new project's Auth Site URL to `http://localhost:3000` and allow `http://localhost:3000/auth/confirm` as a redirect URL for local email confirmation. Start the application:

```bash
pnpm dev
```

## Test immediately

1. Sign up using your own email and verify it (accounts in the old project do not transfer).
2. Open `/branches`, enter the institution name, branch name and unique slug.
3. Leave **Include demo students, teachers and lessons** checked. Create the branch.
4. Inspect the dashboard, student register, admission records, staff register, batches, programme directory and academic lessons.
5. Visit `/?branch=YOUR_SLUG` and `/interest?branch=YOUR_SLUG` to test the public website and enquiry form.
6. Open a second branch to check that data stays separate. Uncheck demo data for an empty operational branch.

Every branch receives six classes, eleven subjects, four programmes (Junior Scholarship, SSC, HSC, Job Preparation), four offerings and four 12-seat batches. With demo enabled it also gets **eight enrolled students, two teacher records, one classroom and four scheduled lessons**. Demo names are clearly marked. Demo offerings are published and open for intake. Without demo, offerings start hidden and intake closed.

Demo data is seeded **atomically during branch creation**, after a verified owner exists. It is available immediately when the dashboard opens. This avoids fabricated Auth users, shared passwords and ownerless demo branches. Demo teachers are staff records, not login accounts; sign up and add a real verified account to test teacher login. Demo consent values and addresses are test fixtures, not evidence for real people. Do not operate a live academy using demo records.

Each branch receives its own records and IDs. Database RLS, function guards and composite foreign keys isolate student, teacher, admission, session, attendance, assessment and directory data. Shared login identity and immutable role definitions are global.

## Local Supabase alternative

```bash
cp .env.example .env.local
pnpm exec supabase start
pnpm exec supabase db reset --local
pnpm dev
```

Set `.env.local` using the URL and key shown by the local CLI. The same branch-opening seed works locally.

## Verification and source

```bash
npm ci --prefix scripts/database
node scripts/simplified/validate.mjs
node scripts/database/generate-types.mjs
pnpm typecheck
pnpm lint
pnpm build
```

The SQL validation applies the baseline to an empty PostgreSQL database under a migration administrator without SUPERUSER, then exercises branch isolation, finance-free admissions, teacher sessions, public intake and demo seeding. It never connects to your hosted project.

The source UI is pinned to Sohoj Academy commit `00f11f2358516bc7362e1984836f09584085b4e7`. Reviewed SQL migrations are now the source of truth. The historical migration assembler and its SQL inputs have been removed. Some source UI response keys remain nullable/empty during this interface transition; they have no corresponding financial database objects. Future finance requires new explicit migrations and UI contracts.
