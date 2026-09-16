# Landing Page & Plans Context

**Gathered:** 2026-09-15
**Spec:** `.specs/features/landing-page-plans/spec.md`
**Status:** Ready for design

---

## Feature Boundary

A public landing page that markets the platform to organizers/venues, shows the plan comparison, and lets a prospect self-register for a `pending` organizer account on the free tier. This session's Discuss pass resolved the two Complex-scope gray areas flagged in the spec: the exact plan tiers/pricing/features, and the paid-tier billing mechanism.

---

## Implementation Decisions

### Plan tiers (AD-005)

- **Basic** (free): up to 4 published events/month, enforced downstream in admin-panel (ADMIN-28) — not merely descriptive copy on this page.
- **Plus** (paid): unlimited event publishing. No other feature differs from Basic — the event cap is the sole differentiator.
- The comparison table shows both tiers side by side; Plus's price is not static copy — it's read live from the Super-Admin-managed current price (admin-panel's ADMIN-20/21, AD-006).

### Billing mechanism (AD-005)

- External link, mirroring the existing ticket-purchase pattern. No in-app checkout, no PCI scope.
- Selecting Plus at signup does not route to billing immediately — signup always lands the account on Basic/`pending` first (PLAN-03); the external billing link is only reached after Super Admin approval (PLAN-11).

### LGPD consent & privacy surface (AD-008)

- Signup requires an explicit, checked consent checkbox recorded with a timestamp (PLAN-12) before submission succeeds.
- A privacy-policy page with DPO/encarregado contact info is linked from the footer and the signup form (PLAN-13). The legal text itself is not authored in this pass — it's an implementation prerequisite the user will supply.

### Agent's Discretion

- Exact comparison-table layout/visual design (already loosely constrained by the existing Stitch design system, but no specific mockup exists for this page yet) — Design's call.
- Exact retention/format of the "status-check page" the spec's existing Assumptions table already defaults to (unconfirmed, `n`) — not revisited this session; Design may propose a concrete mechanism (e.g. a tokenized link) consistent with that existing default.

### Declined / Undiscussed Gray Areas → Assumptions

- None outstanding from this session's Discuss pass — plan tiers/pricing and billing mechanism are both resolved and recorded in the spec's Assumptions & Open Questions table. The pre-existing "rejection/stuck-pending follow-up" assumption (unconfirmed, `n`) was not revisited — it stays as the spec's already-recorded minimal default (a status-check page, no automated re-notification).

---

## Specific References

- "Basic: Its free and allow register 4 events per month" / "Plus: (paid) unlimited events registration." — the user's own tier definitions, verbatim basis for AD-005.
- "It should be managed by super admin in panel by form to edit price and keep historical price plans in database" — directly shaped AD-006 and PLAN-01's live-price requirement.
- "External link (like ticket purchase)" — directly shaped the billing-mechanism decision, explicitly anchored to the PRD's existing ticket-purchase pattern.

---

## Deferred Ideas

- Multi-tier pricing beyond Basic/Plus (e.g. a third "Pro" tier) — not raised this session; out of scope unless requested later.
- Automated re-notification for pending/rejected prospects — the spec's existing minimal default (status-check page only) stands; a push/email notification pipeline was not requested.
