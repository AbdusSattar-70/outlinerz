# Lean EduOps — Fresh Database ও App Delivery Plan

তারিখ: ৪ অক্টোবর ২০২৬। Branch: `feature/lean-modular-eduops`।
[Blueprint](LEAN_EDUOPS_BLUEPRINT.md) | [Schema](DATABASE_SCHEMA.md) | [Setup](FRESH_DATABASE_SETUP.md)

## Scope update

ব্যবহারকারীর নির্দেশ: 01–22 installation নয়; নতুন database code from scratch। তাই legacy upgrade/reuse-schema strategy এই branch-এর জন্য superseded। Existing master/production data untouched; নতুন baseline শুধুমাত্র নতুন empty project-এ। Once installed, ভবিষ্যৎ পরিবর্তন additive timestamped migration হবে। এক baseline মানে পরে installed SQL edit করা নয়।

## Current delivery status

| ধাপ | অবস্থা | Completion evidence / next gate |
| --- | --- | --- |
| Product blueprint ও operator target workflow | Complete | Documentation baseline previously committed |
| নতুন relational database baseline | Complete at foundation level | 55 public + 2 private tables; 01–22 replaced by one authored baseline |
| Tenant/security/financial/academic isolated checks | Complete within stated test scope | 46 assertions in PGlite; mocked Auth/Storage; hosted and real concurrent acceptance pending |
| Hosted fresh project install | Pending user environment acceptance | CLI migration list must show only 20261004000000; real Auth/Storage verify |
| Existing frontend contract compatibility | Pending | Existing modules/types/RPCs still legacy; app cannot operate on new DB yet |

## Ordered feature commits

| পরবর্তী ক্রম | কাজ | Done হওয়ার শর্ত |
| --- | --- | --- |
| 1 | Organization-aware auth/setup/onboarding | New generated DB types, memberships/module context, founder/setup, tenant A/B tests; legacy bootstrap removed from consumers |
| 2 | Unified course screen/wizard | Existing programme reuse, offering/fee/batch command wired; invalid inputs retained; zero fee/draft/intake/public controls |
| 3 | Simple CRM/admission | Rate-limited public enquiry server API, follow-up, direct/Prospect conversion, existing student choice, receipt-independent enrollment |
| 4 | Operational fees/collection | Invoice, partial payment, discount/refund, receipt and due UI; accounting-disabled acceptance; split allocations/unallocated credit only with explicit new contract |
| 5 | Academic planning/lesson UX | Study plan/routine, assigned teacher roster API, topics/attendance/homework draft and completion, temporal/batch integrity |
| 6 | Assessment/progress/work | Reviewed questions, immutable assessment snapshots after use, topic marks, evidence-based progress, teacher reviews/tasks APIs |
| 7 | Teacher/staff compensation | Effective contracts, fixed/hourly/work/revenue-share calculation, hybrid rules, immutable term snapshots, once-only liabilities and advance/payable UI |
| 8 | Business operations/assets | Money/expenses/purchases/register UI, supplier/document evidence, returns/corrections/asset-sale commands, no duplicate outflows |
| 9 | Accounting Pro integration | Worker event mapping, cutover/opening balance, retries/reconciliation, period exceptions, source-policy validation; never block operational transaction |
| 10 | Daily/monthly owner workspace | Actionable mobile dashboard, cash count/reconciliation and reports, cash-vs-profit labels, branding/module visibility |
| 11 | Release acceptance | Hosted Auth/Storage, concurrent last seat/payment/settlement, multi-tenant jobs/files/exports, backup/recovery, browser/print checks |

## প্রতি feature-এর নিয়ম

Behaviour/acceptance লিখুন → একটি coherent feature implement করুন → migration/types/consumers একসঙ্গে → meaningful SQL/domain/UI checks → diff review → handoff update → এক feature এক commit। Table উপস্থিত থাকা workflow completion evidence নয়। Stable client request IDs, retained invalid inputs, pending state ও uncertain-outcome record inspection বজায় থাকবে।

New DB-এ exact current contracts DATABASE_SCHEMA.md-এ। Old docs historical context; কোনো old migration repair, wrapper reinstatement বা production reset দিয়ে compatibility দেখানো যাবে না। New project acceptance-এর পরও বর্তমান app-কে নতুন credentials দেওয়া যাবে কেবল affected consumers সত্যিকার অর্থে migrated হলে।

## Validation limits

PGlite checks fresh installation, RLS/grants including simulated hosted defaults, tenant references, course rollback/retries, admission/capacity/siblings, accounting-off finance, amount/refund/settlement limits, advances, purchase/assets, teachers, marked results, balanced/idempotent/closed-period accounting, private storage policy and nonempty-schema rejection। এটি hosted CLI installation বা true concurrent connections/browser/email/upload acceptance নয়।
