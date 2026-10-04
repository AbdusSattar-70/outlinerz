# Development handoff

The current branch is `feature/redesign_refactor`. This is a fresh-install schema, not an upgrade replay. Read [Workflow](REDESIGN_REFACTOR_WORKFLOW.md), [Database schema](DATABASE_SCHEMA.md), [Fresh setup](FRESH_DATABASE_SETUP.md), and [Interaction standard](ERP_INTERACTION_WORKFLOW_STANDARD.md).

There are 15 ordered migrations, 92 application tables and 126 functions. Files 01–13 are the clean baseline; 14 is a forward upgrade for already installed projects. Historical concatenated migrations, dynamic function patches, parallel wrapper RPCs, obsolete public application tables, uploaded-consent storage contracts, public content version queues and generic setting registries are removed. Previous implementations are not archived in this branch.

Admin-authorized financial posting, compensation, student transfers and duplicate correction run directly with permission checks and audit evidence. Teacher academic review remains. Public submissions are unverified preferences; direct staff admissions never fabricate a Prospect. Academic directory records are created during setup, not supplied as demo seeds.

The UI uses domain modules, controlled RPC writes and permission-scoped reads. Keep existing public visual styling. Do not add client service-role access or bypass prerequisites to mask errors.

Validation completed during cleanup: all 13 migrations applied in isolated PostgreSQL-compatible PGlite; the three rollback-only SQL fixtures passed; Next route generation and TypeScript passed. This does not establish hosted Supabase Auth/Storage behavior, production build success or browser acceptance. Follow the local acceptance checklist before deployment.

## Current refinement

Read [Admission/referral/print contract](ADMISSION_REFERRAL_PRINT_REFINEMENT.md) and [Form inventory](ERP_FORM_INVENTORY.md). Referrers have scoped accounts, first-month net-collection acquisition evidence and corrected settlement limits. Collection-time discount/scholarship and payment are one transaction. Staff edit is inline; secondary forms open on demand with pending feedback and preserved invalid input.

The server shares a request-scoped Supabase client, verifies cookie identity with getUser, and bounds each fetch at 20 seconds without automatically retrying financial writes. Refresh failure must prompt record inspection before retrying a mutation. A Next development Performance.measure warning cannot be assumed fixed without reproducing it locally.

Current verification: all 14 files applied in isolated PGlite; four rollback fixtures passed, including actual refund payout, corrected acquisition balances, immutable/balanced accounting and own-referrer permission checks. TypeScript passed. Actual React print components were rendered and visually inspected: two-page blank admission, one-page example invoice and one-page Bangla acknowledgement. Hosted Auth/email delivery, browser navigation and physical letterhead alignment still require local acceptance. No live database was reset or migrated.

## Staff access and audit usability

Read [Secure account setup](ACCOUNT_SETUP_CONFIGURATION.md). Staff requests are verified inside the Staff page; the previous Settings request route redirects there. Setup/recovery uses a shared server-only secret-key client with credential checks and professional locale-specific feedback. Wrong live credentials still require the project administrator to correct the environment and restart/redeploy.

Migration 15 adds audit search, bounded pagination and permission-scoped Bangladesh-day operational totals. Correlation and raw change payloads stay in immutable records, not the operator table. Five isolated SQL fixtures now pass, including paged search/no overlap and protected totals.

## Staff onboarding and own compensation statements

Apply migration 16 to existing installations without resetting data. See [Referral accounts and staff onboarding](REFERRAL_ACCOUNT_AND_STAFF_ONBOARDING.md). Staff onboarding is request-only; completed account setup appears in request history. Teachers and referrers have own-only financial statements. Manual Staff creation is removed from the UI and revoked at the RPC boundary. Existing ambiguous identities require review; they are never automatically merged.

## Paperless finance and workforce branch

Branch `feature/finance_accounting_management` extends migration 16. Read [Paperless finance and workforce](PAPERLESS_FINANCE_AND_WORKFORCE.md) before further work. Migration 17 provides actual staff attendance and agreed compensation terms; migration 18 provides assigned work and administrative completion acceptance. My work is the first workspace for non-admin staff, with own-only attendance, tasks and approved finance summaries. Migration 19 now supplies fixed/hourly payroll posting and payslips. Migration 20 supplies daily cash/statement evidence; migration 21 supplies monthly accounts and period controls. Advanced reporting, assets and the other documented gaps remain. Do not confuse configured salary or estimates with posted liabilities.

Accounting action forms now open inline. Client-owned request IDs survive unchanged retries; the server does not generate a new key for every accounting attempt. Validation retains inputs, pending saves prevent closing the form, and signed adjustments can be entered. Uncertain outcomes require checking the record before changing inputs.

## Monthly payroll and payslips

Migration 19 implements fixed/hourly salary preview, once-only posting, immutable snapshots, own payslips and partial cash/advance settlement. Read the monthly payroll section of [Paperless finance and workforce](PAPERLESS_FINANCE_AND_WORKFORCE.md). Fixed/hourly teaching contracts are excluded from the teaching pool; hybrid participation is explicit. A staff advance creation reference to the removed organization_id column is fixed. Current-month payroll remains provisional, and statutory deductions/historical contract restoration/posted payroll correction are separate remaining work.

## Daily close evidence

Migration 20 adds cash denomination counts, statement comparison, explained variance, investigation notes, recount-based resolution, reopen and stale detection after later ledger postings. No ledger amount is overwritten and no accounting period is locked by this workflow. Handover receiver acknowledgement and assigned tills remain separate work. See the daily close section of [Paperless finance and workforce](PAPERLESS_FINANCE_AND_WORKFORCE.md).

## Monthly accounts and period lock

Migration 21 supplies monthly P&L, balance sheet, trial balance, cash movement, CSV/print and audited close/reopen. Posting guards enforce closed months on journal headers and lines. Fixed payroll expense is dated at month end; payments retain actual payment dates. Month-end cash/bank/mobile verification and balanced reports are required before close. Read the period-control section of [Paperless finance and workforce](PAPERLESS_FINANCE_AND_WORKFORCE.md).


### Next committed delivery: purchases and supplier expense workflow

Migration `22_purchase_drafts_receipt_and_expense_posting.sql` and `/dashboard/finance/purchases` add a paginated/searchable purchase register. On-demand draft creation/edit/cancellation, inline supplier creation, verified full receipt, paid-now expense or supplier payable, and partial supplier payment reuse the current ledger engine. Drafts do not post; finalized evidence cannot be overwritten. Stable request identities, revision checks, active-account permission boundaries and normalized supplier invoice uniqueness protect posting.

SQL fixture `12_purchasing_receipt_supplier_settlement.sql` checks retry safety, stale revision rejection, receipt journals, partial-payment balance, overpayment rejection, duplicate invoice rollback, paid-now treatment, edit/cancel and outsider denial. No live database reset or mutation is part of this delivery.

Next: private expense-document evidence and supplier/category maintenance; then procurement returns/corrections and staff reimbursements. Asset register/capitalization/depreciation follows as a distinct workflow. Monthly period locks already apply to the expense/payable journal calls.
