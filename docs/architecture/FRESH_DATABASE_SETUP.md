# Final academic database model

This branch replaces the experimental history-based baseline. Reviewed final-state migrations are the source of truth; the historical SQL assembler and source migration inputs are removed. The interface still comes from Sohoj Academy, but the database installs only the simplified academic application.

| File | Responsibility |
| --- | --- |
| 01_academic_model.sql | Academic entities, types, identifiers and branch scope columns |
| 02_identity_and_branches.sql | Verified identity, branch ownership, membership and branch opening |
| 03_admissions_and_students.sql | Academic admission, consent, enrollment, transfers and student history |
| 04_teaching_and_assessment.sql | Sessions, attendance, class logs, question bank and assessments |
| 05_crm_and_workforce.sql | Enquiries, directories, offerings, staff and staff attendance/tasks |
| 06_academic_integrity.sql | Primary/unique keys, checks, composite branch foreign keys and indexes |
| 07_access_and_audit.sql | RLS, explicit API grants, stable function ownership and audit triggers |
| 08_operational_roles.sql | Admin, academic director, operator and teacher roles/permissions |
| 09_demo_seed.sql | Opt-in demo students, teachers, classroom and lessons |

There are no financial tables, empty financial views, financial RPCs, invoice helpers, financial role permissions or fee/discount storage fields. A few nullable/empty JSON response keys remain for compatibility with source UI validators; these are not financial database objects and cannot perform financial operations.

One verified account can belong to multiple branches. All operational records have immutable branch scope. RLS also applies inside academic security-definer functions through a non-login, non-bypass executor role. Privileged bootstrap and membership helpers have the explicit stable postgres owner. Anonymous clients can use guarded public directory/catalogue/intake projections, not query operational tables.

Branch opening creates separate academic starter directories. The demo checkbox adds eight enrolled students, two teacher records without fake login accounts, a classroom and four lessons within the same transaction. Demo offerings are published for testing. Unchecking it creates templates without sample people and keeps public intake closed.

This is a fresh-start migration history. Do not push it incrementally over the experimental baseline. For a disposable testing database, use the documented linked reset; otherwise install into a new Supabase project. Hosted databases were not modified during development.

Validation covers a fresh installation without SUPERUSER, stable helper ownership, absence of financial objects, admission and signed paper consent without fee/referral prerequisites, teacher sessions, branch switching, public intake, membership revocation, immutable scope, composite foreign keys and demo isolation. Browser checks also exercise source academic registers, admission detail/printing and language selection. These are local PostgreSQL/API fixtures, not a claim of hosted Supabase validation.

Future finance work must introduce explicit new tables, permissions, migrations and UI contracts one workflow at a time. Source Sohoj workflows remain the reference; branch scope and audit history remain required.
