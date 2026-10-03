# Paperless finance and workforce management

Branch: `feature/finance_accounting_management`. Base: redesign_refactor, migration 16. This extends the existing ledger, billing and identity architecture; it does not introduce competing student, staff or accounting records.

## Review findings and ordered delivery plan

| Priority | Area | Existing capability | Gap / required outcome |
| --- | --- | --- | --- |
| P0 | Staff attendance | Approved academic session attendance | Staff daily presence, check-in/out, breaks, absence/leave, corrected evidence and monthly own hours are missing. Student attendance is not staff attendance. |
| P0 | Personal workspace | Teacher class lists and own referral statement | A common staff page for attendance, tasks and financial position; teacher shortcuts must lead directly to student attendance. |
| P0 | Compensation terms | Revenue-share teacher policy and approved runs | Fixed/hourly/hybrid terms, agreed pay day and a clearly labelled estimate. Never present an estimate as approved debt or promise payment. |
| P0 | Tasks and accountability | Academic workflow review | Staff assignments, due dates, progress, blocker explanation, completion submission and admin acceptance. Completion percentage is declared progress, not a salary deduction formula. |
| P0 | Payroll | Migration 19: fixed/hourly/hybrid salary preview, posting, payslips and cash/advance settlement | Historical contract recovery, statutory deduction policies and documented payroll corrections remain. No automatic task/absence deduction or second acquisition accrual. |
| P0 | Daily close | Migration 20: denomination count, statement comparison, variance/recount evidence and stale detection | Receiver acknowledgement, cash ownership/till assignment and opening-float workflow remain. |
| P0 | Month close | Migration 21: monthly P&L, balance sheet, trial balance, cash movement, close/reopen and write guards | Cost-centre/programme filters, classified cash-flow statements and fiscal year-end closing remain. |
| P1 | Expenses and procurement | Vendors, expenses, advances and payables | Inline vendor/category selection, attachments with private storage, reimbursements, recurring rent/utilities, purchase order and receipt matching. |
| P1 | Assets | Permission names exist | Asset register, custody, purchase cost, depreciation, maintenance, disposal and linked ledger evidence. |
| P1 | Collections | Invoices, discounts, scholarships, payment/refund and recurring invoices | Aging buckets, parent statement, arrears tasks, instalment commitments, safe reminders, online payment verification and duplicate transaction protection. |
| P1 | Reporting | Audit day totals and referral net collection | Programme/batch contribution after discounts, teacher expense and referral expense; distinguish accrual profit, collected cash and owner withdrawals. |
| P1 | Reliability | Request IDs, audit, row locks and scoped reads | Bounded paginated registers, recovery after interrupted saves, failed operation visibility, backups and a demonstrated restore procedure. |
| P1 | Paperless consent | Physical consent reference and printable forms | Optional verified digital consent evidence, private document register and retention/access policy. Physical-only consent is still a paper dependency; do not claim it is already paperless. |
| P2 | Planning | Operating policies | Budgets versus actuals, cash runway, cost centres, bank import matching, recurring expense reminders, inventory consumables and supplier statements. |

Implement one coherent feature, commit it, then move to the next. Baseline percentages come from current operating rules and the teacher Revenue Sharing proposal; contract-specific terms must be agreed and recorded, not inferred from job title. Do not reset the live database.

## Daily operation

1. Admin opens workforce operations, records actual staff attendance or absence/leave and assigns work. An attendance correction retains actor, reason and previous values. Staff see only their own data.
2. Each person opens My work: today's record, month present days/hours, assigned tasks, blockers, current agreed compensation basis and actual posted financial statement. Teacher opens My classes → session → student attendance; academic submissions continue through administrative review.
3. Staff reports progress and a blocker note. At 100%, submit completion; the administrator accepts it or returns it with a reason. Reported progress cannot automatically reduce agreed pay.
4. Admission produces the invoice. Cash, bank or mobile money actually received produces a numbered receipt and allocation. Discounts/scholarships are separately labelled reductions, never payments. Due remains due without invented collection.
5. Expense paid now posts cash expense; on-account expense posts payable. Advances remain assets until verified settlement. Referrer reward accrues only on qualifying net tuition collections, with refund corrections.
6. Cashier counts funds and reconciles external statements. Differences stay visible until resolved; no overwriting ledger balances to make a match.

## Monthly pay workflow

Configure compensation per staff: fixed monthly, hourly, revenue share or hybrid. Record effective date and scheduled pay day (1–28); corrections apply to unposted work only. Historical payroll retains the term snapshot. Attendance records are evidence, not independently computed teaching sessions: approved teaching workload and revenue share remain the existing engine's basis.

Prepare payroll preview → review attendance, leave and approved workload → add explained allowances/deductions → admin posts once → liability and expense journal → settle cash/bank or advance offset → personal itemised payslip and statement. Staff academic completion review remains; authorised admin financial posting does not require a second administrator. A draft estimate, posted entitlement, settled amount and scheduled pay date must have distinct labels. Scheduled pay date is not a bank payment confirmation.

Revenue-share acquisition must be shown once in referral statements. Teaching/retention pay is separate. Salary plus bonus can be shown as a combined total only after both are posted, for the same period and with no overlapping acquisition entries. If fixed/hourly salary has not been posted, say so explicitly; zero recorded payments are not proof that a person was paid.

## Month close and management accounts

Reconcile receipts/refunds, external accounts, expense documents, advances and payables; review payroll/referral expenses; run trial balance; resolve unexplained differences; close the period. A locked period requires a recorded authorised reopen or a correction in an open period. Never edit/delete posted journal lines. Reports must disclose date range, accounting basis, currency, generated time and filters.

## Interface and security

Admin: attendance register, people/tasks, payroll preview, daily close, receivables, payables and reports. Staff: My work first, own attendance/pay statement, task actions and role-specific tools. Secondary forms open by Create/Edit; errors preserve entered values and pending states prevent repeated clicks. Search/filter/page data at the database boundary.

Use verified identity, active staff/account checks, explicit permissions, RLS and controlled RPCs. Staff cannot set their own pay terms, approve attendance, change another person's task, or read other salaries. New definer RPCs schema-qualify relations, use an empty search path, revoke public/anonymous execution and check the caller. Keep credentials server-only. See [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) and [database functions](https://supabase.com/docs/guides/database/functions).

Paperless readiness requires actual end-to-end consent, receipts, payslips, expense evidence, task review, backup restore, notification delivery and external payment verification. Printable exports remain available as a fallback. Financial and employment statutory treatment requires locally confirmed rules before enabling tax/deduction automation.

## Delivery status

- Documentation: committed first.
- Attendance and own workforce workspace: implemented in migration 17, with own-only reads, corrections, overlap checks and retry protection.
- Tasks and completion accountability: implemented in migration 18, with own reports, administrative acceptance/return, cancellation, audit and paginated current/history lists.
- Accounting save recovery: implemented stable request IDs for unchanged retries, inline action forms, preserved invalid input and signed compensation adjustments. The all-time operating result is labelled explicitly.
- Fixed/hourly payroll: implemented in migration 19, with month/staff uniqueness, stale-preview rejection, immutable term/attendance snapshot, balanced expense/liability posting, cash payment, partial settlement, advance recovery and own-only printable payslips.
- Daily close: implemented in migration 20, with immutable count/statement evidence, denomination validation, variance investigation, fresh-count resolution, reopen and changed-ledger detection. Recording a handover recipient is not receiver acknowledgement.
- Monthly accounts and period controls: implemented in migration 21, with posted-date reports, CSV/print, month-end verification checks, immutable close/reopen snapshots and database write guards.
- Assets and other gaps: separate subsequent features; do not label them implemented until their posting and recovery paths exist.

## Start using this delivery

1. Apply migrations 17 and 18 without resetting the database.
2. Admin opens People → Staff attendance & terms, chooses the person and month, then records actual attendance and agreed pay terms. Present hours require completed start/end times; corrections require a reason.
3. On the same page choose Assign task, confirm responsibility, instructions and deadline.
4. Staff sign in to My work, inspect their own attendance and posted financial position, update progress/blocker and submit completed work. Teachers use My classes to take student attendance.
5. Admin selects the same person, accepts submitted completion or returns it with an explanation. Completed and cancelled tasks remain in history.
6. Accounting actions open inline; failed validation retains input. After an uncertain network outcome inspect the record; an unchanged retry keeps the same database request identity.

Local acceptance still needed: hosted Supabase Auth/RLS integration, real browser form behaviour, mobile/tablet layout, and complete accounting posting/settlement against your development database. Isolated SQL fixtures cover own-only reads, attendance hour arithmetic, permission denial, idempotent task creation and completion review. TypeScript checks cover the added routes and contracts. No live database has been changed.

## Monthly fixed/hourly payroll (migration 19)

Open Finance → Payroll & payslips → Prepare monthly payroll. Select staff and month; optional allowances and explained earning corrections appear separately. Fixed base is prorated by eligible calendar days from the later of the current agreement or join date. Hourly pay uses recorded PRESENT intervals less breaks. Missing records and task progress do not cause automatic deductions. Corrections reduce remuneration expense; tax, loan liability and advance recovery must not be entered as earning corrections.

Current-month preview is provisional. Post a completed month only after reviewing the frozen preview; changed attendance/terms require a fresh preview. One staff/month can be posted once. Posting creates salary expense and salary payable, not a cash payment. Previously posted evidence cannot be edited/deleted. If the currently configured agreement does not cover the month, stop and resolve historical terms rather than extrapolating a newer salary backwards.

Record actual cash/bank payment and an optional paid staff advance offset in one transaction. Partial payment leaves the remainder due. Paid advances must belong to this staff member and have enough remaining balance. Salary payment debits the payable, not salary expense again. The printable black/white payslip includes earnings, corrections, amount in words, actual payments, offsets and remaining balance; no branding header is printed over letterhead.

FIXED/HOURLY contracts are excluded from teaching-pool remuneration; HYBRID explicitly allows both agreed salary and teaching pool. Acquisition and retention remain separate rewards. Existing teaching-pool posting blocks conflicting fixed/hourly salary posting for the same period. A staff advance creation defect from a nonexistent staff.organization_id reference is corrected by checking branch scope. Payroll records and teaching/referral evidence retain separate detail views. My work combines their posted outstanding liabilities once and shows advances separately; do not add cash and offset totals indiscriminately.

Before production: verify real browser navigation/printing and hosted auth permissions. Isolated tests exercise stale preview rejection, once-only posting, balanced journal creation, partial cash plus advance recovery, unchanged retries and teacher privilege denial. Payroll correction/reversal and historic agreement restoration need a separate controlled feature; do not rewrite posted records.

## Daily cash and statement close (migration 20)

Finance → Daily cash & statement close → Count cash / match statement → choose account/date → review opening, debits, credits and expected closing → enter actual cash denomination counts or actual statement balance → explain differences and record reference, optional recipient and note → save. This creates evidence only; no balancing journal is invented. Ledger-derived debits/credits include financial transfers, not only student receipts or expenses.

A second verified count remains a new immutable record. Add investigation notes, resolve after a fresh matching count/statement, or reopen with a reason. Notes do not erase the latest resolved/reopened state. Backdated ledger postings invalidate both count evidence and a previously resolved balance; review again. Inactive account history stays readable. Original evidence is never overwritten/deleted.

This daily close does not freeze financial posting or create a period lock. A stated handover recipient is recorded by the closing actor; authenticated recipient acknowledgement and cashier/till ownership are still separate remaining workflows. External bank/mobile statements are referenced manually; automatic transaction import/matching is not implemented.

Isolated tests exercise duplicate-count retries, unexplained variance protection, matching recount resolution, notes after resolution, late-posting stale detection, immutable ledger balance and denial of teacher access to academy-wide cash accounts. Hosted browser/mobile and actual bank statement workflows still require local acceptance.

## Monthly reports and period controls (migration 21)

Finance → Monthly accounts & period close → choose month → P&L / balance sheet / trial balance / cash movement. Reports include posted journals only, by accounting date. Opening balances carry all earlier postings; month movements cover that month; balance sheet includes accumulated unclosed result separately from posted equity. Cash movement groups posted source types and excludes net-zero internal transfers; it is not yet an operating/investing/financing cash-flow classification. CSV exports the full trial balance; print uses the selected report without an academy branding header.

Fixed/hourly payroll expense is now dated at the earned month's end, while its settlement remains on the actual payment date. If that earned month was closed, the entire attempted payroll posting rolls back. Revenue-share/referral reward recognition continues under the collection-driven existing engine, independently from fixed payroll.

Before CLOSE, verify all currently active cash/bank/mobile accounts against a matching, current-token month-end count/statement; review payroll, receipts/refunds, expense evidence and outstanding balances. Open receivables/payables/advances may carry legitimately; do not manufacture settlement just to close. The completed-month report must balance and all posted journals must balance. A refreshed preview is mandatory if evidence changes.

CLOSE stores an immutable snapshot and blocks new journal headers and additional journal lines in that month, including controlled financial RPCs and service-role writes through normal triggers. Posting takes a shared month lock; close takes the exclusive lock, so normal concurrent transactions cannot slip through the close boundary. An authorised REOPEN records actor/reason and restores posting, with history preserved. No silent unlock or deletion exists.

Remaining reporting work: cost-centre/programme contribution, budgets, classified cash flow, fiscal year-end transfer of accumulated result, payroll correction/reversal, historical contract restoration, external payment import, handover acknowledgement and assets. Isolated tests verify reporting arithmetic, rejected unverified close, one-time close, blocked backdated posting, authorised reopen and teacher access denial. Hosted concurrency and browser acceptance still need local verification.


## Purchase draft, receipt and supplier settlement — delivery 22

Finance → Purchases & supplier expenses starts a purchase register, filtered/searchable and paginated at 25 records. Create a draft, select supplier and expense category, enter item quantities/unit prices and optional expected delivery. Add a missing supplier within the draft without navigating away or clearing the draft. Saving is a planning record only: no cash, expense or payable is created. Edit unused drafts; cancel unused drafts rather than delete them. Concurrent stale revisions are rejected.

When the full goods/service delivery is verified, open Receive & post, compare quantities and total with the invoice, record the actual receipt/expense date and supplier invoice reference, and select paid now or payable later. Correct the draft before posting if the invoice differs. Paid-now receipt requires payment permission. Posting reuses the existing expense, balanced journal and supplier-payable engine; it does not create a competing ledger. The same normalized supplier invoice reference cannot be posted twice within this purchase register. Closed-period guards apply and a failed receipt rolls back the purchase, expense and journal together.

For an unpaid purchase, Pay supplier records actual partial/full cash or bank payment on this same register. Each payment needs a reference and cannot exceed the current payable balance. It clears liability, not a second expense. Request identities make unchanged retries safe; posted/cancelled purchase evidence is immutable and actor-attributed audit history is retained. Forms close on success, preserve values on errors and disable controls while saving.

Scope: operating expenses and consumables with a single full receipt. Durable assets must not be disguised as operating expenses. Partial goods receipts, purchase returns/credit notes, expense corrections, recurring expenses, staff reimbursements, supplier edit/inactivation, category maintenance, private scanned evidence and actual asset capitalization remain separate upcoming work. Current invoice references are recorded evidence references, not uploaded documents; this milestone alone does not establish paperless evidence retention. Existing direct-expense screens can still post outside this register; invoice uniqueness here does not claim to cover those historical/direct expenses.
