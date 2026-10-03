# Referral accounts and request-only staff onboarding

Staff enter through the public access request. An administrator verifies identity and responsibilities, then sends secure account setup instructions. There is no separate ERP Create Staff Identity form or client-callable creation RPC. Bootstrap remains the initial administrator exception.

Invitation reuses a linked identity, or an unlinked identity with the same verified email. A mobile-only match also requires an exact normalized name. Ambiguous matches stop the workflow. Similar names are not proof of identity: existing records remain intact and require staff review before marking any duplicate inactive.

ACTIVE staff lifecycle means employed/available, not that an invitation was accepted. Requests remain INVITED until the verified account accesses the ERP; completed requests move to history. The transition is audited once. Previously signed-in accounts are recognized during migration. Linked referrers do not show the account setup invitation button.

Every active account-linked Staff identity obtains a referral identity. Existing staff/profile referral identities are reused. An ambiguous external mobile match requires identity review rather than automatic merging. Teachers and external referral partners receive only their own statement; admin can inspect the directory and defaults to their own statement.

## Compensation disclosure

The attached teacher Revenue Sharing proposal describes the following defaults; the UI reads current operating rules rather than hard-coding these percentages:

- Acquisition: 50% of actual net tuition collected for the first qualifying billing month, once per student. Admission/exam/material fees are excluded; discounts and scholarships reduce the basis; refunds correct entitlement.
- Teaching pool: 30%, review limit 40%. The pool is distributed by approved teaching workload, not paid in full to each teacher.
- Teacher-referred retention: qualifying third/sixth month net tuition at 15%/20%, subject to continuous active paid enrollment.
- Growth milestone adjustments are discretionary academy decisions, not guaranteed automatic rewards.

Each student's pinned acquisition percentage is shown separately from the current policy. Teaching and retention statements include only approved runs, payment history, advance offsets and outstanding advances. Historical mixed settlements are attributed proportionately to non-acquisition earnings so acquisition is not counted twice. Statements disclose neither other persons' earnings nor unrestricted academy finance accounts.

## Deploy

Pull feature/redesign_refactor and run `pnpm exec supabase db push` to apply `16_request_onboarding_and_own_compensation.sql`. Do not reset the database. Refresh/sign in as the teacher, open My referrals and financial statement, and verify own-only scope. Review completed staff requests in history.
