# Fresh database setup

This branch replaces the old migration history. All existing application data is test data and its reset is authorized. The earlier project implementation exists on another branch; this branch contains no archive.

## Get the branch

```bash
git fetch origin
git switch feature/redesign_refactor
git pull --ff-only
pnpm install
cp .env.example .env.local
```

Fill your project URL, publishable key, site origin and server-only secret key (or legacy service-role key). Never commit .env.local.

## Choose your database installation

For a brand-new Supabase project, link it and install the baseline:

```bash
pnpm exec supabase link --project-ref YOUR_PROJECT_REF
pnpm exec supabase db push
```

For your existing test project, link the intended project and reset its application schema from this branch:

```bash
pnpm exec supabase link --project-ref YOUR_PROJECT_REF
pnpm exec supabase db reset --linked
pnpm exec supabase migration list
```

The linked reset is destructive for application data. Do not use db push against the old schema, or mark old/new files applied via migration repair. All local migration files (01–16) should match the new remote history after a fresh install. If a CLI reset reports an error, stop and inspect it before bootstrapping.

Supabase-managed Auth identities and Storage contents are separate from the application schema. Delete unwanted test Auth users and unused uploaded-consent objects/buckets through their Supabase management APIs/dashboard if a completely empty service is required. Custom database roles may also survive a remote reset. Alternatively a newly created project starts without these leftovers. Never manually delete Storage metadata while leaving its objects behind.

Local-only development: start Docker, then run pnpm exec supabase start and pnpm exec supabase db reset (without --linked). Use the local project credentials shown by the CLI.

## Updating an already installed clean baseline

If migrations 01–13 are already applied, keep the database and run `pnpm exec supabase db push` to apply migrations 14–15. Do not reset the database for this refinement. It preserves admissions, posted charges/payments, journals and previous referral evidence. Configure `/dashboard/governance/rules` and manage verified accounts through `/dashboard/referrals`.

## Bootstrap and operate

Create your own Auth user in Supabase Authentication. In the project's SQL Editor run:

```sql
select public.bootstrap_admin('YOUR_ADMIN_EMAIL', 'YOUR_NAME');
```

Sign in, complete /dashboard/setup, then operate admissions. Create academic years/classes/subjects/programmes yourself; multiple academic years may be active. Configure standard fees, permitted discounts and batches before admitting students.

Staff requests access through /auth/sign-up. Verify their actual responsibilities, assign permissions and send the server-side Supabase invitation. Configure Site URL and allowed redirects <origin>/auth/confirm and <origin>/auth/update-password. Invite/recovery templates can use /auth/confirm?token_hash={{ .TokenHash }}&type=invite or type=recovery. Keep secure email-change confirmation enabled.

```bash
pnpm build
pnpm dev
```

Follow [Local acceptance](REDESIGN_LOCAL_ACCEPTANCE.md). No live project reset, email delivery or printer validation was performed by this cleanup.

Official references: [Supabase CLI](https://supabase.com/docs/reference/cli/supabase-db-reset), [Migrations](https://supabase.com/docs/guides/deployment/database-migrations).

For account email setup, follow [Secure account setup](ACCOUNT_SETUP_CONFIGURATION.md). Do not reset a clean installed database for migrations 14–15.
