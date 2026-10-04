# Simplified Sohoj Academy version

Branch: `feature/simplified_version` in Outlinerz. Source: Sohoj Academy master, commit `00f11f2358516bc7362e1984836f09584085b4e7`.

This version restores the Sohoj interface as the base. Finance, accounting, payroll, fee plans, payments and billing workflows are excluded. Admission and programme activation must not depend on a financial setup.

One verified login can select an authorized branch. Branch separation applies to directories, programmes, students, admissions, batches, teacher records, attendance, assessments and audit history. Shared account identity and immutable role templates are not operational branch records. Opening a branch copies editable starter academic records into that branch; it never shares their IDs or creates fictional students, teachers, payments or financial balances.

The new academy schema is separate from the already-installed Outlinerz public schema. Existing migrations and data remain intact. Supabase must expose the academy schema to its Data API. Local configuration includes it; hosted configuration must include academy under API exposed schemas before using this branch.

Future finance work will use the existing Sohoj source as a reference, added one workflow at a time: student fees and receipts; teacher remuneration; expenses and liabilities; optional accounting. All future records must carry branch scope and preserve audit history.

## Validation

46 database checks cover real admission enrollment, teacher/session workflows, branch opening and switching, membership revocation, cross-branch foreign keys, public intake and blocked financial operations. Type checking and the production build pass; lint reports no errors. Browser integration covers branch opening, starter directories, switching and the original English/Bengali toggle against the migrated database. Hosted Supabase has not been modified by these checks.
