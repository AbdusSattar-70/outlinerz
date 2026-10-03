# Lean Modular EduOps — Product ও Architecture Blueprint

তারিখ: ৪ অক্টোবর ২০২৬। অবস্থা: নতুন database foundation implemented; app integration pending.

> **২০২৬-১০-০৪ implementation update:** ব্যবহারকারীর নির্দেশে এই branch এখন নতুন fresh database contract ব্যবহার করে। পুরোনো 01–22 migration chain সরানো হয়েছে। নতুন baseline ও পরীক্ষিত capability জানতে [Schema](DATABASE_SCHEMA.md), [Fresh setup](FRESH_DATABASE_SETUP.md) এবং [Handoff](DEVELOPMENT_HANDOFF.md) পড়ুন। নিচের পূর্ণ product design target; database tables থাকা মানেই সব app workflow implemented নয়। Existing app/RPC/types integration এখনো pending।


Branch: `feature/lean-modular-eduops`।
Base: `master@00f11f2358516bc7362e1984836f09584085b4e7`।

## ১. উদ্দেশ্য ও কর্তৃত্ব

Sohoj Academy ERP-এর ব্যবহারযোগ্য domain knowledge ও modules রেখে coaching/tuition business-এর জন্য configurable product তৈরি হবে। Sohoj Academy হবে একটি organization/tenant; brand, batch capacity, programme, fees বা admission rules product-wide hard-code হবে না। মূলনীতি: **Simple by default, powerful when needed — Lean Data Model + Flexible Business Logic + Modular Features।**

এই নথি নতুন branch-এর target direction নির্ধারণ করে। এই branch-এ নতুন schema/RPC contract এসেছে; deployed legacy database পরিবর্তন করা হয়নি। বর্তমান contract জানতে [Schema](DATABASE_SCHEMA.md), [Handoff](DEVELOPMENT_HANDOFF.md), [Guardrails](ERP_IMPLEMENTATION_GUARDRAILS.md) পড়ুন। নতুন design পুরোনো accounting dependency এবং বাধ্যতামূলক admission stages বদলানোর লক্ষ্য রাখে; সেই পরিবর্তন কেবল tested additive migration ও updated consumers-এর মাধ্যমে কার্যকর হবে।

প্রথম product education business-কেন্দ্রিক। Money, assets, purchasing ও people modules পরে অন্য ছোট ব্যবসায় reuse করা যাবে; এই পর্যায়ে retail/POS বা arbitrary industry workflow নির্মাণ scope নয়। Product name, pricing এবং tier packaging এখনো final নয়।

## ২. কী থাকবে

| অংশ | Target আচরণ |
| --- | --- |
| CRM | Enquiry, lead source, follow-up, referral, conversion; public intake without login |
| Admission | Direct admission বা Prospect conversion; একই তথ্য পুনরায় লেখা নয় |
| Courses | এক screen/wizard-এ Programme, Offering, fee এবং optional first batch |
| Students | Permanent ID, guardian details, enrollment ও academic/financial profile |
| Academic | Routine, syllabus/study plan, sessions, attendance, homework, question bank, assessments, progress |
| People | Teacher workload, compensation, staff payment, advances ও payable |
| Money | Cash/bank/MFS, collection, expense, transfer, refunds, receipts |
| Purchasing | Supplier, draft purchase, received items, payment status ও evidence |
| Assets | Register, cost, location, assignee, condition, maintenance, disposal |
| Accounting Pro | Optional COA, balanced journals, reconciliation, accounting periods ও statements |
| Controls | Server/database permissions, tenant isolation, audit, historical snapshots ও duplicate/retry protection |

Assets ও purchasing বাদ যাবে না। Simplification হবে operator workflow-তে; integrity বাদ দেওয়া হবে না। Student/guardian accounts ও digital consent এই baseline-এর scope নয়। Optional physical document/evidence রাখা যায়, কিন্তু consent admission-এর default blocker হবে না। Existing physical evidence migration-এ সংরক্ষিত থাকবে।

## ৩. Product boundary

একই Next.js/Supabase repository-তে modular monolith দিয়ে শুরু হবে; প্রথমে microservices নয়।

- Platform: organization, branch, membership, roles, settings ও module enablement।
- Growth: CRM, follow-up, referral ও admission।
- Academic: programme/offering/batch, curriculum, sessions, work, assessment ও progress।
- Student finance: fee agreement, invoice, allocation, discount, refund ও receipt।
- Business operations: money movement, purchases, assets, staff/teacher liabilities ও settlement।
- Accounting adapter: operational events গ্রহণ করে optional journal projection তৈরি করবে।

Academic এবং business modules common organization, people ও money account references ব্যবহার করবে। Common references মানে accounting prerequisite নয়। Operational domain নিজের invariant রক্ষা করবে; accounting downstream থাকবে।

## ৪. Lean data model

Table count কোনো success metric নয়। Relational keys, transaction safety বা history হারিয়ে একটি generic JSON/EAV table-এ সব domain ঢোকানো যাবে না। Indexed scalar columns-এ tenant, amount, status, date ও সম্পর্ক; bounded JSON শুধু configuration বা immutable snapshot-এর জন্য।

| সম্পর্ক | অর্থ |
| --- | --- |
| Organization → Branch | Tenant বনাম তার location; default single branch |
| Organization → Academic Year | একাধিক active year অনুমোদনযোগ্য |
| Programme → Offering | Reusable identity বনাম year/branch/eligibility-specific delivery |
| Offering → Batch | Delivery group, teacher/routine/capacity |
| Student → Enrollment → Offering/Batch | একজন student একাধিক course নিতে পারে |
| Prospect → Admission → Student/Enrollment | Conversion reference; direct admission-এ fake Prospect নয় |
| Batch/Subject → Study Plan → Topic | Planned syllabus ও target dates |
| Batch → Session → Attendance/Homework | বাস্তবে কী হয়েছে এবং কার অংশগ্রহণ |
| Assessment → Question/Topic marks | Overall ফল ও evidence-based topic analysis |
| Invoice → Allocation ← Payment | Partial payment, multiple invoices, overpayment handling |
| Purchase → Asset/Expense/Payable | Item অনুযায়ী operational classification; duplicate outflow নয় |
| Approved work → Compensation item → Settlement | Earned liability ও actual payment আলাদা |

নতুন table/RPC naming ও exact schema প্রথম inventory milestone-এ স্থির হবে। Existing models যাচাই ছাড়া parallel payment/admission tables যোগ করা যাবে না। Cached totals authoritative source নয়; rebuildable projection হবে।

## ৫. Tenant ও authorization contract

প্রতিটি tenant-owned record organization scope বহন করবে; child references একই tenant-এর হতে হবে। Branch tenant boundary নয়। Authentication থেকে membership যাচাই করে scope নেওয়া হবে; client পাঠানো organization ID একা বিশ্বাসযোগ্য নয়।

RLS, controlled RPC, server-side authorization, composite tenant references/constraints, private file paths এবং background worker scope একই boundary মানবে। Public course/intake organization-scoped হবে; anonymous visitor private records পড়তে পারবে না। Service-role worker explicit tenant ও source identity নিয়ে কাজ করবে।

Owner/admin, academic coordinator, teacher, finance/operator roles permission presets হবে। শিক্ষক নিজের assigned class/tasks; money access আলাদা grant। Module enabled থাকলেই permission পাওয়া যায় না। Module বন্ধ করলে history মুছে যাবে না; entitlement read access ও permitted writes স্পষ্টভাবে নিয়ন্ত্রণ করবে।

## ৬. Programme ও Offering: দুই model, এক workflow

Programme reusable নাম/template; Offering নির্দিষ্ট year, branch, class/group, subjects ও intake instance। এটি UI-তে দুই বাধ্যতামূলক setup menu হবে না।

Create Course wizard:
নাম বা existing programme → year/branch/eligibility/subjects → fee terms → optional batch/routine → review → save draft অথবা open admission।

এক command প্রয়োজনমতো Programme reuse/create, Offering, fee agreement ও optional batch atomically তৈরি করবে। Validation failure-এ partial course থাকবে না; unchanged retry নতুন course বানাবে না। Existing programme reuse explicit selection/tenant-scoped uniqueness দিয়ে হবে, শুধু নাম মিলিয়ে automatic merge নয়।

Free course অনুমোদিত; fee 0 একটি valid explicit configuration। Fee না দেওয়া ও free course আলাদা। Existing enrollments-এর agreed fees snapshot থাকবে; current fee edit পুরোনো invoices বদলাবে না। Intake open/closed, delivery active/archived ও public visibility পৃথক অর্থ বহন করবে।

## ৭. Accounting independence

Invoice issue, fee payment, receipt, refund, class completion, expense, purchase, asset registration এবং teacher settlement accounting disabled/unconfigured/unavailable থাকলেও operationally complete হবে।

Operational money record-এ direction, account, exact decimal amount, currency, date, source, actor ও stable request identity থাকবে। Student payment এবং cash movement একই transaction-এ তৈরি/linked হবে; fee collection পুনরায় manual income হিসেবে লেখা যাবে না। Transfer-এর linked out/in এক transaction; expense, purchase payment, teacher settlement-এর outflow একবারই হবে। Due ও payable accrual actual cash নয়।

Operational transaction-এর সঙ্গে durable outbox event একই DB transaction-এ সংরক্ষিত হবে। Accounting consumer পরে journal তৈরি করবে; unique tenant/source/event/revision identity duplicate posting আটকাবে। Worker failure-এ pending/error status, retry এবং reconciliation থাকবে; source transaction rollback হবে না। Correction/refund নতুন event; posted evidence overwrite নয়।

Accounting enablement-এ cutover date, reconciled opening balances এবং replay range ঠিক হবে। Historical transactions ও opening balances একই value দুইবার post করা যাবে না। Accounting period close operational date lock নয়; late operational event projection exception হিসেবে review হবে, অনুমতি ছাড়া বন্ধ period reopen/post নয়।

Cash report actual inflow/outflow দেখাবে। Earned revenue, receivable, payable ও cash surplus এক নামের total নয়। Dashboard-এর “cash surplus” profit দাবি করবে না; asset purchase cash কমায় কিন্তু পুরো purchase cost recurring operating expense হিসেবে ধরা যাবে না।

## ৮. Academic delivery contract

Topic coverage actual teaching evidence থেকে, শুধু session complete flag থেকে নয়। Cancelled/rescheduled classes syllabus বা earned compensation বাড়াবে না। Attendance missing এবং absent আলাদা; homework unreviewed এবং not done আলাদা।

Study plan → routine/session → taught coverage → homework/review → assessment → student progress।
Teacher এক session-এ attendance, covered topics, homework ও note দ্রুত save করবে; partial draft permitted। Session completion payroll configuration-এর ওপর নির্ভর করবে না।

Question bank-এ class/subject/topic/type/difficulty/marks; reusable questions-এর assessment snapshot থাকবে। AI future extension; teacher-reviewed draft ছাড়া publication নয়। Topic performance শুধু topic-tagged marked evidence থেকে; insufficient data হলে “পর্যাপ্ত তথ্য নেই”। Weighted coverage/progress formula ও denominator UI/help-এ স্পষ্ট হবে।

Compensation rules effective-date snapshot বহন করবে: fixed, hourly, per class, per script, per question set, hybrid বা revenue sharing। এক work item একই remuneration component-এ একবার accrue হবে। Completion ও approval criteria rule-ভিত্তিক; configured salary estimate posted payable নয়।

## ৯. UX ও owner controls

Primary workspaces: Home | Students | Academic | Finance | More।
Students-এর মধ্যে Enquiries/CRM, Admission, Batches ও Progress; Academic-এ Courses, Study Plan, Routine, Lessons, Homework, Tests, Question Bank, Workload।
Finance-এ Fees/Dues, Money, Teacher/Staff payments, Expenses, Purchases; Assets ও setup More-এ; advanced accounting enabled হলে finance-এর advanced area।

Single teacher owner একাধিক role নিতে পারবেন। Default year/branch/pre-filled choices, dropdowns, inline create, retained invalid inputs, pending feedback ও stable retry keys থাকবে। Dashboard warning actionable link দেবে; unavailable module-এর empty metric 0 দেখাবে না। Bangla-first understandable labels; mobile থেকে মূল daily actions করা যাবে।

## ১০. Delivery ও acceptance

[Operator workflow](LEAN_EDUOPS_WORKFLOWS_BN.md) এবং [implementation roadmap](LEAN_EDUOPS_IMPLEMENTATION_PLAN.md) এই blueprint-এর companion। Database baseline complete মানে পূর্ণ SaaS/app integration complete নয়। Tenant isolation, accounting-disabled workflow, retries এবং history-preserving migration acceptance না পেরিয়ে shared multi-tenant deployment হবে না।

