# Fresh Lean EduOps database setup

Branch: `feature/lean-modular-eduops`. This branch now contains one newly authored baseline: `20261004000000_lean_eduops_baseline.sql`. Historical migrations 01–22 and their old-contract test fixtures are removed from this branch. They remain in Git history/master.

**Database contract changed. Existing Next.js pages, modules and `types/database.ts` still target the legacy contract and are not compatible with this database yet. Do not point the current app/production deployment at it.** This phase installs and validates the new database foundation; app integration is a separate next delivery.

## Pull

From your existing repository, preserve any uncommitted changes before switching:

```bash
git status
git fetch origin
git switch feature/lean-modular-eduops
git pull --ff-only origin feature/lean-modular-eduops
pnpm install --frozen-lockfile
```

If the branch does not exist locally, use `git switch --track origin/feature/lean-modular-eduops` instead of the switch command above.

## New hosted project

Create a NEW Supabase project in the Dashboard. This baseline deliberately rejects a nonempty public schema. It is not an upgrade and contains no destructive reset/drop of your old project.

```bash
pnpm exec supabase login
pnpm exec supabase link --project-ref YOUR_NEW_PROJECT_REF
pnpm exec supabase db push --dry-run
pnpm exec supabase db push
pnpm exec supabase migration list
```

The history should contain only `20261004000000`. Stop on errors; do not repair/mark the old migration history to pretend this baseline was applied. Future changes after this baseline is deployed still need normal additive migrations; one clean baseline does not mean forever editing installed SQL.

Copy `.env.example` to a separate development environment file and fill the NEW project's URL and keys when app integration is ready. Do not replace the production environment yet. Secret/service keys stay server-only. This schema creates the private `eduops-documents` storage bucket.

## Local database option

With Docker running:

```bash
pnpm exec supabase start
pnpm exec supabase db reset --local
pnpm exec supabase migration list --local
pnpm exec supabase status
```

`db reset --local` deletes local test database data and rebuilds this baseline. It does not reset the hosted project. Local Studio is normally `http://127.0.0.1:54323`; use the actual address printed by the CLI.

## First organization/owner

Create a confirmed Auth user in the NEW project's Authentication dashboard (or local Studio). Then run this in that project's SQL Editor, replacing the email and organization identity:

```sql
begin;
do $$
declare u uuid; o uuid;
begin
 select id into strict u from auth.users where lower(email)=lower('YOUR_ADMIN_EMAIL');
 perform set_config('request.jwt.claim.sub',u::text,true);
 o := public.create_organization('Sohoj Academy','sohoj-academy');
 insert into public.branches(organization_id,name,code)
 values(o,'Gopalpur','GOPALPUR');
end $$;
commit;
```

This creates ownership only for this new organization. It does not grant platform-wide access. Accounting is disabled by default; CRM/Academic/Finance/Business are enabled. No school-specific fees, classes, programmes, capacity, demo students or chart of accounts are seeded. Re-running this block with the same slug rejects instead of duplicating the organization. Do not use the old `bootstrap_admin` RPC; it no longer exists in this contract.

## Reproducible isolated database checks

From repository root:

```bash
npm --prefix scripts/database ci
npm --prefix scripts/database test
```

The validator installs the baseline in an isolated PGlite PostgreSQL engine with mocked Supabase Auth/Storage tables. It exercises authorization, tenant references, atomic course/admission, capacity rejection, stable retries, accounting-off operational finance, refunds/advances/assets, teacher sessions, assessment integrity and accounting projection controls. It also simulates Supabase's auto-granted public table defaults and verifies explicit revocation.

Hosted Supabase Auth, real Storage HTTP uploads, CLI installation, multiple concurrent connections and frontend acceptance remain required before release. Passing isolated tests does not establish app compatibility.
