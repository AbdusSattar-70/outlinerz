# ERP interaction standard

Registers open as compact tables. Create/edit actions open one inline form; successful saves close it and show localized feedback. Failed saves retain input and explain the affected field. Every input needs a visible label, business helper text and explicit required/optional indication.

Prefer selection over typing. Offer authorized inline creation for missing reusable directory records and referrers. Never turn public free-text preferences into verified ERP foreign keys automatically.

Admission work stays on one case: verify identity/placement, referral, paper consent, review and finalize, payment, enrollment. Current/completed step headings are actionable; unavailable future steps explain prerequisites. Public conversion starts with correction; direct intake already collects full details. Acceptance and initial invoice commit atomically; unpaid amounts stay due. Receipts represent actual money received only.

Detours use a validated same-origin returnTo and return to the case after success. The ERP shell remains mounted. Avoid full reloads, global loading overlays and opening all forms at once.

Authorized admin financial and lifecycle changes need permission, impact confirmation and audit evidence, not a second approval queue. Teacher submissions retain administrative review.

Operational settings live beside their domain registers with Settings providing discovery. Show current values, not JSON/version management as the primary editing interface. Internally preserve the terms that governed historical transactions.

Repeat critical validation in controlled RPCs. Use safe support references for unexpected failures; do not expose private database data or credentials.
