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

There is one migration: `01_simplified_baseline.sql`. The application uses the default `public` schema. No additional exposed-schema setting is required. `academy_private` stays private. No database reset, repair, role cleanup, migration squash or old migrations are needed for the new project.

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
pnpm typecheck
pnpm lint
pnpm build
```

The SQL validation applies the baseline to an empty PostgreSQL database under a migration administrator without SUPERUSER, then exercises branch isolation, finance-free admissions, teacher sessions, public intake and demo seeding. It never connects to your hosted project.

The source UI is pinned to Sohoj Academy commit `00f11f2358516bc7362e1984836f09584085b4e7`. `scripts/simplified/source-sql` holds reviewed assembly inputs, not migrations to run individually. `python scripts/simplified/assemble.py` regenerates the single baseline. Temporary upstream finance definitions are removed before the baseline transaction completes; no financial stores or financial RPC access remain in the resulting database. Future finance workflows will be ported gradually from Sohoj.
