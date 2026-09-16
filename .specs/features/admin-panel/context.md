# Admin Panel Context

**Gathered:** 2026-09-15
**Spec:** `.specs/features/admin-panel/spec.md`
**Status:** Ready for design

---

## Feature Boundary

A desktop console for an **approved** organizer to register and manage events, track engagement, manage their venue's public presence, and manage promoters — gated by a Super Admin approval workflow. This session's Discuss pass resolved the two remaining Complex-scope gray areas flagged in the spec (rejection UX, tier/feature-gating boundary) and surfaced one new in-scope capability (Super Admin plan-pricing management) plus the LGPD/security baseline that now applies to every feature.

---

## Implementation Decisions

### Rejection UX (AD-007)

- Keep the spec's existing minimal default: a rejected organizer sees their rejection state and optional reason on login attempt.
- No in-product resubmit/appeal flow is built. A reconsidered rejection would require manual/out-of-band re-onboarding.

### Plan/tier feature-gating boundary (AD-005, AD-007)

- Admin-panel access is otherwise uniform across the Basic and Plus tiers.
- The only enforced difference: a Basic-tier organizer is blocked from transitioning a 5th event to `published` within a calendar month (ADMIN-28). Plus removes this cap entirely. No other feature (promoters, analytics depth, venue management) differs by tier.

### Plan pricing management — new capability (AD-006)

- A Super Admin can edit the Plus tier's price via a form.
- Every price change is preserved as a versioned historical record (not overwritten) — supports future auditability (e.g. grandfathering existing subscribers at their signup-time price, though that logic itself is not built in this pass).
- The landing page reads the *current* price live from this data.

### LGPD & security baseline (AD-008)

- Organizer self-service data export (account, venue, event, promoter data) and account deletion, with a Super Admin override for support cases.
- Deletion deactivates the account, pulls its events from consumer-facing listings, and deletes personal data within a defined retention window; a warning is shown first if the organizer has an upcoming published event.
- Security guardrails apply here same as every feature: Eloquent-only DB access (no raw SQL), Policy/Gate authorization on every owned-resource endpoint (events, venue, promoters, price history), and — since this is a web surface — HttpOnly/Secure/SameSite session cookies instead of localStorage.

### Agent's Discretion

- Exact retention-window length for deleted organizer data (e.g. 30 vs 90 days) — not specified by the user; Design should propose a concrete default.
- Exact price-history data shape (e.g. whether "effective date range" is a start-only timestamp or a start/end pair) — Design's call, consistent with AD-006's intent that no price is ever silently overwritten.

### Declined / Undiscussed Gray Areas → Assumptions

- None outstanding — every gray area flagged in the spec's original "Routes to Discuss" note was resolved this session and is recorded in the spec's Assumptions & Open Questions table (rejection follow-up, tier/feature-gating boundary, Plus tier pricing, LGPD data export/deletion scope).

---

## Specific References

- "Super admin ... form to edit price and keep historical price plans in database" — the user's own words shaping ADMIN-20..23; historical/versioned pricing is a hard requirement, not a nice-to-have.
- LGPD, IDOR, SQL-injection protection, and HttpOnly cookies (not localStorage) were named directly by the user as platform-wide requirements — see AD-008, which governs this feature alongside the other three.

---

## Deferred Ideas

- None — discussion stayed within feature scope. (Multi-seat/staff accounts per organizer remain explicitly out of scope per the spec's existing Edge Cases note, unchanged this session.)
