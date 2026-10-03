# Secure account setup and staff responsibilities

## Server configuration

Both staff and referral-partner account setup use one server-only Auth client. Invalid API key means the configured server credential is rejected by the selected project; changing the person's role will not repair it.

1. Open the exact Supabase project used by NEXT_PUBLIC_SUPABASE_URL. In Settings → API Keys, obtain its secret key (`sb_secret_...`). Set `SUPABASE_SECRET_KEY` on the server. A legacy `service_role` key may instead use `SUPABASE_SERVICE_ROLE_KEY`; it must be a service-role JWT for that same project. A publishable/anon key is insufficient. When both are set, SUPABASE_SECRET_KEY takes precedence.
2. Keep NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY and NEXT_PUBLIC_SUPABASE_URL from the same project. Do not use a Supabase personal access token, database password, another project's key or a masked key copied from the dashboard.
3. Set NEXT_PUBLIC_SITE_URL to the actual application origin. On local development, use the port you are running, e.g. http://localhost:3000. On deployment configure the correct environment (Preview/Production) and redeploy after changing values. Restart the local development process after editing .env.local.
4. In Authentication → URL Configuration, configure Site URL and allowed redirects for `<origin>/auth/confirm` and `<origin>/auth/update-password`. Add each authorized local/production origin. Do not use an unrestricted production wildcard.
5. Configure email delivery and invite/recovery templates. Preserve the authenticated confirmation URL/token mechanism; a plain link to the password page does not establish a session. Test with one verified recipient, then complete password setup and sign-in. Keep secure email-change confirmation enabled.

Secret keys must never use NEXT_PUBLIC_ names, appear in GitHub/client code, or be pasted into help requests. The server validates key type and, for legacy JWTs, project reference before sending. Never bypass RLS or role verification to mask configuration failures. The credential cannot be repaired from application code: replace the incorrect environment value using project settings.

Official sources: https://supabase.com/docs/guides/getting-started/api-keys and https://supabase.com/docs/guides/auth/redirect-urls.

## Staff workflow

1. A staff member submits the intended role and purpose at /auth/sign-up. This creates an access request, not an authorized account.
2. An authorized administrator opens People → Staff → Staff access requests. Verify the real person's identity, email ownership and responsibilities. Every person should use their own email; do not reuse the bootstrap administrator's email for another person.
3. Select the permitted role and verify it. If the choice changes, verify again before sending account setup. ADMIN grants administrative responsibilities; use TEACHER for teaching, OPERATOR for permitted operations and ACCOUNTANT for permitted finance. Requesting a role never grants it automatically.
4. Send account setup instructions. Existing verified email accounts receive secure password recovery rather than a second identity. Assignment uses the verified request role, not an unverified button selection. If delivery succeeds but assignment fails, the interface reports that distinction; inspect the same request before retrying.
5. After sign-in, configure Settings → Staff access for the permitted roles and People → Staff for teaching subject/batch responsibilities. Do not give ADMIN just to overcome a missing assignment. Teachers see only authorized work; their submissions still require the academy's academic review.

## Referral partners

Save and verify the person/email in Referrers, then send account setup instructions. Existing staff use their own linked account. External referral accounts are restricted to their own referrals, relevant collections and reward/settlement evidence. They receive no Student Register, Finance or staff permissions merely by being a referrer.

## Audit activity

Audit retains immutable correlation/change evidence internally, but the operator interface shows only Time, Action, Entity, Person/role/ID and Reason. Search and page size 25 are applied in the database. Person search includes captured names and IDs. Dates use Bangladesh time. Today's completed admissions, issued invoice count/original charges, actual collections and actual refund payouts come from posted records, not a count of matching search text. Daily cards respect the corresponding operational permissions. Invoice activity includes initial bills and recurring billing runs. These are daily activity totals, not profit or all outstanding balances.
