# Local acceptance: admission desk

Use test identities and a test Supabase project. Apply this branch's actual migration chain; do not repair history by pretending unapplied SQL ran.

1. Sign in as bootstrap ADMIN. Confirm academy/campus, review directory and rules, create an offering, save a positive tuition Fee Plan, select permitted discounts, create a batch, and confirm setup. Earlier steps must reopen; operations must stay blocked until completion.
2. From the public form select an offering and a different class plus unrelated subjects. Submission must succeed as an unverified CRM application. The original selections must be visible; no school/programme master record should be created by the visitor.
3. Convert that enquiry: choose the real offering and batch, correct family details, verify, choose Organic/referrer, print and record physical consent.
4. Start direct staff intake with a new student. Select/create school and relationship. Review, go back, correct, then save. No CRM Prospect should be manufactured. Save draft for later must reopen as a draft.
5. On the case, test blocked future steps, completed-step viewing, referral creation and paper consent with no upload. Correct identity after consent: old consent must remain but no longer satisfy final submission; receive a newly signed corrected form.
6. Choose an allowed discount and reason, add an agreed one-time material charge, mark an erroneous draft charge inactive, and review the totals. An unpermitted percentage must fail at the database boundary.
7. Confirm admission once. Student ID and academy roll must appear. An initial invoice must exist even when no payment was made. A repeat submission must not issue duplicate identity/invoice/discount credits. Failed finalization must leave no half-created accepted student.
8. Post a real partial payment, print its receipt, confirm the due balance, then activate according to the configured policy. Do not post zero or invent a payment to bypass enrollment rules.
9. Follow a financial/setup detour; finish the supported save and confirm automatic return to the originating workflow. The Return link must also work. External `returnTo` URLs must be ignored.
10. Mark a batch/offering inactive. Public/new admission use stops; old cases remain. Correct inactive offering copy, reactivate where eligible. Deactivating staff must suspend that linked profile's ERP access. Permanent deletion must be rejected.
11. Request staff access as TEACHER while also attempting an ADMIN claim. Confirm no permission is granted on submission. Admin verifies TEACHER, sends the Supabase setup link, and the recipient sets a password. Teacher cannot self-promote or call admin mutations. Check teacher submission → admin review.
12. Confirm password recovery and verified email change. Test expired links and invitation retry without creating duplicate staff.
13. Browser print preview: blank and populated applications should occupy two A4 pages with no application chrome. Page 2 must include guardian/student signatures, office placement, charges/discount, actual collection fields and detachable seal receipt. Receipt-only printing must describe an actual posted payment. Check long names and addresses at 100% scale; switch off browser headers/footers.

Emails and real Supabase RLS behavior must be exercised locally; static compilation or an embedded database test does not establish email delivery or production acceptance.

## Operator usability regression checks

- Perform an admin mutation, then find the actor name/role/profile ID/staff ID in Audit. Trace a final submission's correlation and inspect ACCEPT, BILL and FINALIZE together.
- Search billing by name, mobile, Student ID and admission number; click a result and confirm its invoices and balances.
- Withdraw/complete an active enrollment from the student page. Confirm it appears in closed admissions, releases capacity, excludes recurring billing and preserves outstanding invoices.
- Open an invoice print page; return to the same student account. Check black-and-white document print preview.
- Assign and unassign CRM follow-up staff. Confirm referral rewards are independent of responsibility assignment.
- Open/create/edit each master-data type and offering/batch. Cause a validation error and a duplicate code error: values must remain. Successful saves should close the editor and show feedback.
- Open Business Rules, change a supported rule and save; confirm the current values and retained prior history. Anonymous/teacher mutations must remain forbidden.
