# Implementation guardrails

- Keep business behavior in domain modules and database workflows; UI forms orchestrate commands.
- Database permissions, RLS, constraints and row locks are security boundaries. Server checks improve error messages but cannot replace them.
- Anonymous callers may submit unverified applications and read explicitly public content only. They never assign verified academic placement.
- Service-role credentials stay server-only. Staff roles follow verified access requests; a requested role grants nothing.
- Authorized admin actions complete directly. Retain independent administrative review for teacher academic submissions.
- Preserve audit, permanent identifiers and posted financial evidence. Use inactive flags, authorized withdrawal, adjustments and refunds rather than deletion.
- Fees and rules are simple editable settings in the UI. Historical transactions retain internal snapshots; administrators do not operate version queues.
- Use explicit actor identity and role in audit events. A correlation ID groups related events for investigation; it is not an actor or a secret authorization token.
- Maintain balanced journals, allocation limits, capacity checks and retry protection.
- Add future schema changes as new ordered migrations after 13. Never silently edit a baseline already used by a production installation.
