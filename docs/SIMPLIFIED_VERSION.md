# Fresh simplified version

Use a new Supabase project. One migration installs the academic application in `public`; the previous Outlinerz migration chain is retired on this branch. This is an intentional fresh-start change, not an upgrade migration for populated databases.

The original Sohoj website, language switcher and academic interface remain. Financial modules and admission fee requirements are removed. Branch opening installs independent starter academic directories. Verified owner accounts control membership, and branch scope is checked in SQL including inside security-definer workflows.

The branch-opening demo checkbox defaults on. Each demo branch creates eight enrolled students, two teachers without fabricated accounts, a classroom and four lessons. Public programmes are immediately available for testing. Unchecking demo creates academic templates without sample people and keeps public intake closed. Seed operations share the branch-opening transaction and idempotency key; failure rolls back the entire branch.

Validation: 51 SQL checks cover a fresh non-superuser installation, real admission enrollment, teacher sessions, public intake, membership revocation, composite foreign keys and separate demo records. See README for exact new-project setup commands.

Later finance work: introduce student fees/receipts first, teacher remuneration next, then expenses and optional accounting. Use existing Sohoj workflows as the reference and preserve branch scope/audit history.
