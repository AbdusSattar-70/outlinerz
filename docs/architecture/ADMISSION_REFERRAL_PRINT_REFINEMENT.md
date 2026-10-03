# Admission, referral and document refinement

## Reported issues and implementation contract

| Area | Problem | Required behavior |
| --- | --- | --- |
| Requests | Case refresh can hang for five minutes | Shared request client, bounded network deadline, recoverable case error |
| Auth | Cookie session warning | Verify identity with getUser; never authorize from stored session user |
| Compensation | Short reason silently rejected | Field-specific reason validation and persistent input |
| Referral | No dedicated account or register | Admin register, verified account invitation, own-referrals portal enforced in database |
| Reward | External-only/manual first-month award | Unified staff/outsider reward on actual net tuition collection, policy-pinned evidence and refund correction |
| Finance | Discount labelled credit | Show discount/scholarship distinctly; preserve balanced contra-revenue accounting |
| Collection | No instant scholarship | Apply permitted invoice adjustment and payment atomically; never invent money received |
| Staff | Narrow incomplete editor, always-open create | Full inline editor; protected identity/access fields read-only; click-to-create |
| Forms | Inconsistent open states/loading | Explicit action panels, retain invalid input, pending feedback and prevent duplicate submission |
| Admission | Status lacks color | Draft/review amber/blue, active green, cancelled red, closed muted |
| Documents | Branding duplicates letterhead, weak layout | Monochrome typography, letterhead space, separate office area and amount in words |
| Family data | Missing student contact/address detail | Optional student mobile/email, present landmark, same-as-present permanent address |
| Preferences | Too much handwriting | Live offerings/subjects tick list, name boxes and selection controls; public choices stay unverified |

Referrers see only student identity/reference, referred programme, applied discount, collection and their reward/settlement. No guardian/private address or unrelated student data. Accounts are admin-verified; requesting or possessing a referrer role never grants access to another person's records. Staff can use their existing account.

Acquisition reward is based on net collected tuition of the first qualifying billing month, preserving the existing acquisition definition. Partial collections accrue proportionately. Refunds/late discounts reduce entitlement with compensating ledger entries, not silent historical rewrites. Teacher teaching/retention compensation remains separate; acquisition must not be counted again in teacher runs. Profit/loss comes from posted ledger revenue minus contra revenue and expenses including accrued referral reward; settlement is not a second expense.

Online intake and paper share contact/address/support fields. Paper does not collect passwords or unnecessary sensitive IDs. Public preferences are never verified placement. Letterhead space is configurable through print CSS; preview before physical printing.

Next work after this scope: teacher dashboard, question bank, routine/session calendar and academic operations; then assets and the remaining Finance review.

## Operator path

1. Business Rules → Referral and collection settings: save acquisition percentage and permitted collection-time discount/scholarship limits.
2. Referrers: create/edit verified identity; use an existing staff account or save verified email and send secure account setup. Referrer login opens only their portal; staff retains their authorized workspace.
3. Admission: select or create the referrer, record signed paper consent, review placement/fees and finalize. Admission discount is explicitly labelled on the invoice.
4. Admission case or Billing: open Collect payment / discount, select an invoice and actual collection method. An optional discount/scholarship requires its reason and policy limit. A scholarship-only transaction records zero money received.
5. Referrers: inspect collected tuition, earned amount and corrections; record actual settlement against available corrected entitlement. Negative outstanding means recovery/future offset, not another payment. Accounting shows all-time posted operating profit/loss.

## Paper and online field decisions

Names, verified class/placement, guardian relationship/contact and address are core; student mobile/email, date of birth, parent names, school roll, birth registration, previous results and learning/accessibility support are optional. Do not request identity documents/passwords in public intake. Present landmark is free text, area can be typed directly, and permanent address may copy present address. Public preferences are indicative, not eligibility enforcement.

ERP print documents reserve space for preprinted letterhead and contain no repeated academy branding. Blank admission includes live offerings/subjects, capital-letter name boxes, wider address fields, guardian consent and a separate office-only charges/collection section. The last part is a detachable manual money receipt. A zero/unpaid admission does not create a money receipt. Printed payment/invoice amounts include English taka/paisa words; Bangla labels and names remain renderable. Public acknowledgement uses Print / Save PDF rather than the former lossy PDF encoder.

## Validation and boundaries

TypeScript and four isolated SQL fixtures passed. Rendered print previews confirmed two-page blank admission and one-page example invoice/acknowledgement with Bangla text. Large live catalogues or long populated records may legitimately use extra pages instead of clipping data. Verify browser Print Preview, paper margins and your actual letterhead before printing a pad. Account setup requires server-only SUPABASE_SERVICE_ROLE_KEY, NEXT_PUBLIC_SITE_URL, Auth redirect allowlist and working email delivery. The live Supabase service and the reported development-only Performance.measure error were not directly reproduced.
