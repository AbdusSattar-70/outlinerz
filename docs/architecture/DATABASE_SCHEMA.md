# Lean EduOps fresh schema contract

Baseline: `supabase/migrations/20261004000000_lean_eduops_baseline.sql`.
Status: database foundation implemented and isolated validation passed; legacy app integration pending.

This is a new relational model, not 01–22 concatenated or renamed. There are 55 public application tables, 2 private command/counter tables, and no organization/demo/COA seeds. Public tables do not mean anonymous visibility: every public application table has RLS enabled. Private Supabase storage is organization-prefixed.

| Domain | Tables |
| --- | --- |
| Platform | organizations, memberships, organization_modules, branches, audit_events |
| Academic directory | academic_years, class_levels, class_groups, subjects, people, programmes |
| Course delivery | offerings, offering_subjects, fee_terms, batches, routine_slots, topics, study_plan_items, sessions, session_topics, attendance, homework, homework_reviews |
| Assessment/work | questions, assessments, assessment_items, assessment_results, marks, work_items, compensation_terms |
| CRM/students | prospects, followups, students, enrollments |
| Student finance | invoices, invoice_credits, payments, payment_allocations, refunds |
| Business/money | money_accounts, money_movements, expenses, purchases, payables, settlements, staff_advances, advance_clearings, assets, asset_maintenance, documents |
| Optional accounting | outbox_events, accounting_accounts, accounting_periods, journals, journal_lines |
| Private mechanics | app_private.command_results, app_private.counters |

## Tenancy and access

Organization is the tenant boundary; branch is location. Composite organization/id foreign keys prohibit cross-tenant references. Tenant/id/created_at are immutable. Membership comes from `auth.uid()`; client organization IDs alone confer no authority. OWNER/ADMIN, ACADEMIC, FINANCE, OPERATOR and TEACHER presets have explicit read/write boundaries. Tenant setup and editable academic/business records use narrowly granted RLS writes; financial evidence/students/enrollment and money movements require controlled RPCs. There are no client delete grants/policies.

Teacher has no generic student/finance table read. `teacher_sessions` returns assigned sessions; `complete_session` checks assignment and commits attendance/topic/homework atomically. Detailed teacher roster/homework/task submission read/write APIs will be added during app integration. Anonymous users can read only `public_courses`; public enquiry submission must be added through a rate-limited server endpoint, not direct anonymous table grants.

Disabled modules stop direct domain mutation and module commands; authorized historical reads remain. Accounting periods constrain projection only, not operational collection/expense.

## Implemented controlled commands

- Organization: create_organization, set_member (last owner protected), set_module.
- Courses/admission: create_course, admit_student, issue_invoice.
- Student money: collect_payment, credit_invoice, refund_payment.
- Business money: opening_balance, record_expense, transfer_money, record_payable, settle_payable, give_advance, clear_advance, receive_purchase.
- Teaching: teacher_sessions, complete_session.
- Public: public_courses (explicit public columns).
- Accounting: set_accounting_period and server-only project_journal.

Mutable tenant directory/academic/business records have role/module-scoped INSERT/UPDATE policies. Posted financial evidence, audit, outbox, journals and lines reject UPDATE/DELETE even through trusted service credentials. Financial RPC payloads use stable request UUIDs with exact stored inputs; unchanged retry returns previous result, changed input rejects. Calls run in one database transaction; capacity and balance checks lock relevant rows. Actual multi-connection concurrency acceptance is pending.

## Finance rules and deliberate first-contract limits

Money uses exact two-decimal numeric amounts; NaN/Infinity rejected. A payment in this first contract targets one invoice and is fully allocated; overpayment/unallocated student credit and split-invoice collection are not implemented yet. Refunds reverse allocated paid value and restore invoice due; a tuition cancellation additionally uses an authorized invoice credit. Credits cannot exceed current outstanding due.

Admission snapshots the applicable fee and creates the first invoice without an accounting/consent gate. Free courses create an explicit zero invoice. Direct admission never fabricates a prospect. Siblings sharing a phone remain distinct. First/recurring invoice uniqueness is per enrollment/billing month. Automated recurring billing jobs, changed-fee agreements, withdrawal/transfer commands and richer discount rules are next app/domain slices.

Money movements reference canonical payment/refund/expense/settlement/advance sources. Transfers require two balanced legs. Purchase receipt creates a payable; use settlement to pay it, without creating a second expense/outflow. Assets allocated from a received ASSET purchase cannot exceed total purchase cost; basic location/assignee/condition/disposal tracking is present. Asset sale cash command, procurement returns, asset depreciation and paid-document attachment verification are pending.

Compensation terms/work quantities are relational foundations. `record_payable` supports authorized manual liability and accepted work/component uniqueness; automated salary/hourly/revenue-share calculation and effective-term snapshots are not yet a payroll engine. Advance offsets consume payable and advance balances without a second cash payout.

## Accounting independence

Source transactions atomically emit immutable outbox events whether Accounting is enabled or not. No journal/COA prerequisite exists in operational RPCs. A trusted downstream consumer may call `project_journal` with explicit mapping; tenant event/account checks, unique event projection, unchanged replay, balanced lines and closed-month controls apply. No worker, cutover/opening ledger configuration, retry scheduler or accounting reconciliation UI is shipped in this database-only change.

Outbox includes both business-document and money-movement events. A future consumer must map accrual and cash events deliberately and never post every snapshot as independent revenue/cash. The projection RPC validates balancing, tenancy and identity; the worker is responsible for accounting policy and source-amount mapping. Do not automatically replay all events or equate operational opening cash with new revenue.

## Current app compatibility

Existing `modules/*` RPC consumers and `types/database.ts` are legacy contracts. No compatibility views/wrappers were generated to recreate the old ERP. They must be replaced by feature slices against this schema before starting the app with new database credentials. Old documentation is historical context only; [fresh setup](FRESH_DATABASE_SETUP.md), this schema and [handoff](DEVELOPMENT_HANDOFF.md) are the current installation authority.
