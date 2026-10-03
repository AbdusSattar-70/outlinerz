# Lean database implementation guardrails

- Fresh baseline is `01_outlinerz_eduops_baseline.sql`, new empty public schema only. Do not apply to/reset the legacy installation. Future installed changes use additive timestamped migrations.
- Existing app modules/types are legacy until migrated. Do not infer compatibility from TypeScript build success or table names.
- Organization membership from verified Auth identity determines access. RLS, composite tenant references, explicit grants, private file paths and scoped jobs enforce the boundary.
- Editable directory/academic/business data may use the documented RLS writes. Students/enrollments/financial evidence use approved RPCs. Never grant broad direct financial writes to fix a UI error.
- Server-only service credentials stay off clients. Public content returns explicit safe columns; public intake needs server rate limits and no anonymous private table access.
- Operational transaction + linked money + audit/outbox commit atomically. Accounting is optional downstream; source collection/receipt/session/expense must not require ledger configuration.
- Protect identifiers, actor/audit evidence, agreed fee snapshots and posted transactions. No DELETE grants; correct using explicit additional transactions rather than rewriting history.
- Stable request identity stores exact inputs. Changed retry rejects; lock capacity and balances; uncertain outcome requires record inspection.
- Disabled modules prevent new writes but preserve authorized historical reads. Feature enablement never grants user permissions.
- Journals require balanced lines, scoped events/accounts, once-only projection and period controls. Worker accounting policy/cutover/replay must avoid document/movement double posting.
- Do not collapse relational business invariants into a generic JSON setting/event table. Exact monetary columns reject non-finite values.
- Tests must state isolated/mock versus hosted/concurrent/browser evidence. Documented target workflows are not implemented-feature claims.
