# Landing Page & Plans Specification

## Problem Statement

Organizers and venues have no way to learn about Qual o Rock? or sign up without someone manually onboarding them. This public landing page sells the platform to promoters and venues, shows what each plan tier includes, and lets a prospect self-register for a free-tier organizer account — subject to Super Admin approval before they can actually use it.

## Goals

- [ ] A prospective organizer can go from landing on the page to submitting a signup in a single visit, with no manual sales step required for the free tier.
- [ ] A prospective organizer understands, from the plan comparison alone, what they get on the free tier versus a paid tier.
- [ ] Every self-registered account lands in a `pending` state that only a Super Admin can move forward — no signup grants immediate platform access.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
| --- | --- |
| Payment processing / billing execution for paid tiers | Resolved (AD-005): billing routes through an external link, mirroring the ticket-purchase pattern — this pass does not implement any in-app charge flow. |
| Super Admin's approve/reject action itself | Owned by `.specs/features/admin-panel/spec.md` — this spec only produces the `pending` organizer account and signup data; the review UI lives in the admin panel. |
| Organizer's post-approval event/venue/promoter management | Owned by `.specs/features/admin-panel/spec.md`. |
| Consumer-facing (attendee) marketing or signup | Owned by `.specs/features/mobile-app/spec.md` and `.specs/features/web-app/spec.md` — this page targets organizers/venues, not attendees. |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear.

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Plan tiers shown | Two tiers: **Basic** (free) — up to 4 published events/month, enforced by admin-panel (ADMIN-28); **Plus** (paid) — unlimited event publishing, no other feature differs from Basic | Explicit user decision this session (AD-005) | y |
| Plus tier price | Not a fixed number in this spec — read live from the price a Super Admin currently has set in admin-panel (ADMIN-20..23), including its historical record | Explicit user decision this session (AD-006): pricing must be Super-Admin-managed and versioned, not hardcoded copy | y |
| Signup outcome | Selecting any tier and completing signup always creates the organizer account on the **Basic (free)** tier first; nothing charges at signup time | Explicit user decision: "start with free plan with self registration" | y |
| Post-signup state | The account is created immediately but flagged `pending`; the prospect sees a confirmation screen explaining that a Super Admin must approve before they can log in and manage events | Explicit user decision: needs super-admin approval to start using the platform | y |
| Paid-tier billing mechanism | External link, mirroring the existing ticket-purchase pattern — no in-app checkout/PCI scope | Explicit user decision this session (AD-005) | y |
| Rejection / stuck-pending follow-up for the prospect | The prospect can return to a status-check page (e.g. via a link sent at signup) to see `pending`/`approved`/`rejected`, but no automated re-notification is specified here | Not covered by the PRD or user decisions; a minimal, safe default rather than inventing a notification pipeline | n |
| Signup form fields | Organization/venue name, contact name, email, phone, and password (for the separate organizer auth), plus an explicit LGPD consent checkbox with a recorded timestamp | Keeps the landing-page signup short (higher conversion) and avoids duplicating the venue-management fields already scoped to `admin-panel`; consent checkbox is required per AD-008 | y (consent requirement) / n (exact field validation rules) |
| LGPD consent & privacy surface | Signup requires explicit consent (PLAN-11); a privacy-policy page is linked from the landing page footer/signup with DPO/encarregado contact info; legal copy itself is supplied by the user later | Explicit user decision this session (AD-008) | y (mechanism) / n (legal text) |

**Open questions:** none - all resolved or logged above.

**Routes to Discuss before Design:** none remaining — plan tiers/pricing structure and the paid-tier billing mechanism were resolved this session (AD-005, AD-006).

---

## User Stories

### P1: Compare plans and self-register ⭐ MVP

**User Story**: As a promoter or venue owner evaluating the platform, I want to see what each plan offers and sign up myself, so that I can get started without waiting on a sales conversation.

**Why P1**: This is the entire purpose of the page — without it there is no self-serve organizer acquisition at all.

**Acceptance Criteria**:

1. WHEN a prospect opens the landing page THEN the system SHALL display a comparison of the Basic (free, 4 events/month) and Plus (paid, unlimited events) tiers, showing the Plus price fetched live from the Super-Admin-managed current price (ADMIN-20..21).
2. WHEN a prospect selects a plan and starts signup THEN the system SHALL collect organization name, contact name, email, phone, and a password for the separate organizer auth.
3. WHEN a prospect submits a complete, valid signup form THEN the system SHALL create an organizer account in the `pending` state on the Basic (free) tier, regardless of which plan was selected.
4. IF a prospect submits a signup with a missing required field or an email already registered as an organizer THEN the system SHALL reject the submission and identify the specific problem.
5. WHEN signup succeeds THEN the system SHALL show a confirmation screen stating the account is pending Super Admin approval, before any login is possible.
6. IF an organizer whose account is still `pending` (or `rejected`) attempts to log in THEN the system SHALL deny access and show the current account state, consistent with `.specs/features/admin-panel/spec.md`'s approval gate.
7. IF a prospect selects the Plus tier during signup THEN the system SHALL direct them to the external billing link only after their account is `approved` — signup itself never routes through billing.
8. WHEN a prospect submits the signup form THEN the system SHALL require an explicit, checked consent to data processing before submission succeeds, and SHALL record the consent with a timestamp.

**Independent Test**: Complete signup from the landing page with valid data, confirm the resulting account is `pending` (checkable from the admin panel's Super Admin view), and confirm login is denied until approved.

---

### P2: Understand the value proposition

**User Story**: As a promoter or venue owner unfamiliar with the platform, I want to understand what running events through Qual o Rock? gets me, so that I can decide whether to sign up at all.

**Why P2**: Improves conversion but the page is minimally functional (can still collect signups) without persuasive content.

**Acceptance Criteria**:

1. THE system SHALL present the platform's value proposition (event management, audience analytics, promoter tools) above or alongside the plan comparison.
2. THE system SHALL provide a way to reach the signup flow from any point on the page (not only from the plan comparison section).
3. THE system SHALL render the page responsively across desktop and mobile browser widths.
4. THE system SHALL link a privacy-policy page with DPO/encarregado contact information from the page footer and from the signup form itself.

---

### P3: Check signup status after leaving the page

**User Story**: As a prospect who already signed up, I want to check whether my account has been approved, so that I know when I can start using the platform.

**Why P3**: A convenience on top of the core signup flow; the confirmation screen at signup time already communicates the pending state once.

**Acceptance Criteria**:

1. WHEN a prospect with a `pending` account revisits a status-check link THEN the system SHALL show the account's current state (pending, approved, or rejected).

---

## Edge Cases

- IF a prospect abandons signup partway through THEN the system SHALL NOT create a partial organizer account.
- IF a prospect selects a Paid tier THEN the system SHALL make clear, before submission, that no charge occurs at signup and the account starts on the free tier pending approval.
- IF a prospect re-submits signup with the same email while a `pending` account already exists THEN the system SHALL reject the duplicate rather than creating a second account.
- IF a prospect's account was `rejected` and they attempt to sign up again with the same email THEN the system SHALL surface the prior rejection rather than silently creating a new pending account.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| PLAN-01 | P1: Compare plans and self-register | Design | Pending |
| PLAN-02 | P1: Compare plans and self-register | Design | Pending |
| PLAN-03 | P1: Compare plans and self-register | Design | Pending |
| PLAN-04 | P1: Compare plans and self-register | Design | Pending |
| PLAN-05 | P1: Compare plans and self-register | Design | Pending |
| PLAN-06 | P1: Compare plans and self-register | Design | Pending |
| PLAN-07 | P2: Understand the value proposition | Design | Pending |
| PLAN-08 | P2: Understand the value proposition | Design | Pending |
| PLAN-09 | P2: Understand the value proposition | Design | Pending |
| PLAN-10 | P3: Check signup status after leaving the page | Design | Pending |
| PLAN-11 | P1: Compare plans and self-register (external billing routing) | Design | Pending |
| PLAN-12 | P1: Compare plans and self-register (LGPD consent capture) | Design | Pending |
| PLAN-13 | P2: Understand the value proposition (privacy-policy/DPO link) | Design | Pending |

**ID format:** `PLAN-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 13 total, 0 mapped to tasks, 13 unmapped ⚠️

---

## Success Criteria

- [ ] A prospect can complete signup in a single visit with no manual intervention, landing in a verifiably `pending` state.
- [ ] Zero organizer accounts reach any state other than `pending` immediately after self-service signup (no accidental auto-approval).
- [ ] The plan comparison and signup CTA are both reachable within one scroll/click from page load.
- [ ] The displayed Plus price always matches the current Super-Admin-set price (ADMIN-20..21) — zero drift between admin panel and landing page.
- [ ] Zero signups succeed without a recorded, timestamped consent.
