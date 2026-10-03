# Redesign and operational workflow

Branch: `feature/redesign_refactor`, fresh database baseline.
This document is the current workflow contract. Do not restore a parallel MVP schema or generic second-person admission approval.

## Data boundaries

- Public interest/admission is an unverified application, without account creation.
- Catalogue choices are preferences. Wrong class/programme/subject combinations do not reject an otherwise valid application.
- Public requests retain an `application_snapshot`. They do not assign verified class, offering, subject, programme or school foreign keys, and do not create master schools.
- CRM displays the original choices as unverified. Authorized conversion chooses actual placement and records who verified it. Original statements remain available.
- Names, valid Bangladesh contact numbers, consent, field sizes and duplicate-submission protection remain mandatory.

## First login

Super admin first confirms academy/campus identity, then reviews academic directory, operating rules, offering, standard fees/allowed discounts, and admission-ready batches. Earlier steps can be reopened. Later steps stay locked until prerequisites exist. Explicit completion opens operations. Seeded values do not replace the required identity confirmation.

Setup is available again from Settings. An inactive record stops new use while existing history stays available.

## Staff access

1. Request access on `/auth/sign-up`: name, email, mobile, requested role and purpose. No password or ERP privilege is created by this request.
2. Super admin sees requests in Action Center and Settings → Staff access requests.
3. Verify identity and responsibilities; choose the actual ADMIN, OPERATOR, TEACHER or ACCOUNTANT role. Role permissions are configured through Access & Security.
4. Send a Supabase invitation/setup link. Authorization is assigned only after verification. Invitations are server-side; the service key never enters browser code.
5. The verified person sets a password through Supabase. My account provides secure password recovery and email-change confirmation.
6. Teacher submissions continue to require the existing administrative academic review. Authorized admission personnel complete admissions directly; there is no separate admission approver.

## Admission desk

- Online family: public application → CRM verification → admission conversion.
- Walk-in with staff assistance: ERP direct intake → draft case. It never manufactures a CRM Prospect.
- Busy desk: print the two-page A4 application. Family completes page 1 and signs page 2. Staff enters the paper later through direct intake.

Staff intake offers a dedicated review before saving, and Save draft for later. Schools and guardian relationships can be selected or created inline. The case presents clickable completed/current steps; future steps cannot run early.

### Case sequence

1. Verify/correct full student and guardian information and placement. Prospect conversions expose correction first; direct intake already collected the details.
2. Record Organic or select/create a referrer on the case.
3. Receive guardian-signed paper consent; store the original physically and record its date/location. No upload is required.
4. Review charges and saved tuition discount, tick the verification checklist, then confirm admission. Acceptance and the initial invoice are one database transaction. Failure rolls back both.
5. Record actual money received, if any, and issue the receipt. An unpaid invoice remains due.
6. Activate enrollment under the configured payment and capacity policy. A policy that permits credit enrollment does not require inventing a payment.

Student ID and academy roll are issued by the database at student creation. Receipt numbers are issued only for actual recorded payments. A manually detached receipt must be entered with its paper reference; do not charge or record the same money twice.

Edits remain audited. Correcting identity before submission returns the application to Draft. Previously signed consent stays in history, but a new receipt for the corrected identity revision is needed. After finalization, dedicated identity correction preserves invoices and payments.

## Fees and discounts

The product shows current Fee Plans, editable on the same day. Internal fee snapshots protect historical admissions; operators do not manage version numbers.

For each offering, configure permitted tuition discount percentages: 5, 10, 15, 20, 25, 30. No selected percentages means no admission discount. Staff selects an allowed percentage and a recorded reason (hardship, sibling, merit, launch offer, staff family or other verified circumstance). Policy is enforced again on final submission.

Additional one-time registration, exam, material or other agreed charges can be added on the case before final submission. Draft charges can be marked inactive; once invoiced, corrections use financial records. Additional charges and standard lines post together so the ledger stays balanced.

The admission discount applies to tuition from the first billing month through the academic year's end, including recurring invoices in that period. It does not discount admission, exam or material charges. Existing invoice lines stay intact; discounts are ledger credits.

## Corrections and record preservation

Academic master registers already provide edit and active/inactive controls. Offerings and batches now expose inactive/reactivate controls; inactive offering names can be corrected without rewriting used academic context. Staff details can be edited and staff access suspended. Student lifecycle controls require proper withdrawal before deactivating an actively enrolled student.

Posted invoices, payments, journals and signed consent are evidence, not editable settings: use recorded financial adjustments, refunds, withdrawal or a new consent receipt. Database deletion guards preserve permanent identities and financial evidence. Canonical student/staff/batch writes use controlled RPCs, with RLS on reads and authorization/audit on mutations.

## Detours

Setup and admission links carry a validated same-origin `returnTo`. Successful supported setup/financial saves return to the original workflow. A persistent Return link allows an intentional return without another save. Core admission actions stay on the case.

## Deployment

Install the new migrations `01–13` on an empty application schema. For the authorized test-data reset, follow [Fresh database setup](FRESH_DATABASE_SETUP.md). Do not push this replacement baseline onto the old schema or repair history to pretend it was applied.

Server environment:

- Existing public Supabase URL and publishable key.
- `SUPABASE_SERVICE_ROLE_KEY` (server only, staff invitations).
- `NEXT_PUBLIC_SITE_URL` (the real origin, including localhost for development).

Supabase Auth configuration:

- Add `<origin>/auth/confirm` and `<origin>/auth/update-password` to allowed redirect URLs.
- For cross-browser invite/recovery, configure email templates to use `<origin>/auth/confirm?token_hash={{ .TokenHash }}&type=invite` (invite) or `type=recovery` (recovery). The callback verifies the one-time token and then opens password setup.
- Keep secure email change confirmation enabled. For email-change templates use the token confirmation callback with `type=email_change`.
- Use production SMTP before relying on staff delivery. Email delivery was not exercised against a live project during implementation.

## Verification

The SQL regression fixture covers mismatched public preferences, no public school creation, verified conversion, no fabricated Prospect on direct intake, setup prerequisites, allowed/forbidden discounts, atomic acceptance + invoice, system identifiers, unpaid balances, deletion protection and inactive batches. Additional fixtures cover staff authorization and renewed consent after identity correction.

Run locally after applying the branch:
`pnpm build`, then test desk flows using the supplied manual test instructions. Print the application using A4, 100% scale, browser headers/footers off; printer margins may require adjustment.

## Draft placement recovery

The case verification panel can correct an unconfirmed offering/batch or refresh its current fee plan without creating another admission. This returns the case to Draft, clears the selected discount, marks earlier supplemental charges inactive, and requires renewed paper consent. Accepted placements use the direct authorized enrollment transfer workflow; historic invoices are never rewritten. Staff can request password recovery from the sign-in page without changing their assigned permissions.
