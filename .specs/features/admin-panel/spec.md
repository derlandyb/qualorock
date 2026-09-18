# Admin Panel (Organizer/Venue Console) Specification

## Problem Statement

Organizers and venues ("Casas de Shows") currently have no dedicated tool to publish events, see who's engaging with them, or manage the promoters they work with — they'd otherwise rely on ad-hoc spreadsheets and DMs. This desktop console gives an approved organizer a single place to register and manage events, track engagement, run their venue's public presence, and manage promoters, while a platform-level Super Admin gatekeeps who gets in.

## Goals

- [ ] An approved organizer can publish a complete event (all required fields) in a single sitting, without leaving the admin panel.
- [ ] An organizer can see, for any of their events, how many people viewed it, favorited it, clicked the ticket link, and marked interest — in one dashboard view.
- [ ] No organizer account can manage events, venue data, or promoters until a Super Admin has explicitly approved it.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
| --- | --- |
| Organizer self-serve signup form and plan/pricing selection | Owned by `.specs/features/landing-page-plans/spec.md` — this spec starts from "an organizer account exists and is pending or approved." |
| In-app ticket purchase / payment processing | PRD §3, §7 — tickets remain an external link even when set up here. |
| Promoter self-service login | PRD §2 — promoters are managed records the organizer creates and edits; they never log in here. |
| Consumer-facing event discovery, favorites, social feed, notifications | Owned by `.specs/features/mobile-app/spec.md` and `.specs/features/web-app/spec.md`. |
| Billing execution for the Plus tier (charging a card, subscription lifecycle) | Owned by `.specs/features/landing-page-plans/spec.md` — billing runs through an external link (AD-005); this spec only enforces the Basic tier's 4-events/month cap and manages the Plus price (see ADMIN-20..23). |
| Tier-based feature gating beyond the Basic event cap | Resolved by AD-007 — admin-panel access is otherwise uniform across tiers; no additional feature-gating is built in this pass. |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear.

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Organizer auth system | Organizers log in through their own dedicated login/signup, entirely separate from the consumer app's social/email login (FR-ACC-01/02) | Explicit user decision this session | y |
| Super Admin provisioning | Super Admin accounts are provisioned out-of-band (e.g. seeded directly, not via any self-service signup) | Super Admin is an internal platform-operator role, not a customer-facing one; no self-serve path was requested for it | n |
| Approval state model | An organizer account has exactly one of three states: `pending`, `approved`, `rejected`; only `approved` organizers can access event/venue/promoter management | Matches the user's "free plan with self-registration but needs super-admin approval" decision; a tri-state (not just approved/not) lets Super Admin distinguish "never reviewed" from "explicitly declined" | y |
| Design status for all FR-ADM screens | No Stitch screens exist yet for any admin-panel requirement (dashboard, event CRUD, venue management, audience relationship, promoter management); six desktop screens are planned per PRD §5 but not yet generated | Confirmed directly against the Stitch project's screen list (30 screens, none titled for the admin panel) during this Specify pass | y |
| Rejection follow-up | A rejected organizer sees a rejection state with a reason (if provided) when they attempt to log in, but no automated appeal/resubmit flow is specified here | Explicit user decision this session (AD-007): keep the minimal default rather than build a resubmission workflow no one asked for | y |
| Event capacity / age range fields (ADMIN-01) | Both are optional free-form fields (capacity: integer; age range: text, e.g. "18+") unless a stricter format is decided in Design | PRD lists them as fields to capture but doesn't define validation rules | n |
| Plan/tier feature-gating boundary | Admin-panel access stays uniform across tiers; only the Basic tier's 4-events/month publish cap is enforced (ADMIN-08) | Explicit user decision this session (AD-007) | y |
| Plus tier pricing | Managed by a Super Admin via a form in this panel, with every change preserved as a versioned historical record (ADMIN-20..23) | Explicit user decision this session (AD-006) — the landing page has no hardcoded price to display otherwise | y |
| LGPD data export/deletion scope for organizers | An organizer can export their own account/venue/event/promoter data and request account deletion; Super Admin can also act on this for support purposes (ADMIN-24..27) | Explicit user decision this session (AD-008) — LGPD right to access/erasure | y |

**Open questions:** none - all resolved or logged above.

**Routes to Discuss before Design:** none remaining — the approval-state model, rejection UX, and plan/tier feature-gating boundary were all resolved this session (AD-005, AD-006, AD-007).

---

## User Stories

### P1: Organizer access is gated by Super Admin approval ⭐ MVP

**User Story**: As a Super Admin, I want to review and approve or reject pending organizer accounts, so that only vetted organizers/venues can publish events on the platform.

**Why P1**: This is the access-control gate every other admin-panel capability depends on; without it, any self-registered organizer could immediately act.

**Acceptance Criteria**:

1. WHEN a Super Admin opens the pending-organizers list THEN the system SHALL show every organizer account in the `pending` state with the signup details they submitted.
2. WHEN a Super Admin approves a pending organizer THEN the system SHALL set that account's state to `approved` and grant it access to event, venue, and promoter management on next login.
3. WHEN a Super Admin rejects a pending organizer THEN the system SHALL set that account's state to `rejected` and record an optional reason.
4. IF an organizer whose account is `pending` or `rejected` attempts to log in THEN the system SHALL deny access to event/venue/promoter management and show that account's current state (and rejection reason, if any).
5. THE system SHALL restrict the pending-organizers list and the approve/reject actions to Super Admin accounts only.

**Independent Test**: Seed one `pending` organizer, log in as Super Admin, approve it, then log in as that organizer and confirm event management is now reachable; repeat with a `rejected` outcome and confirm it stays blocked.

---

### P1: Register and manage events ⭐ MVP

**User Story**: As an approved organizer, I want to create, edit, and control the status of my events, so that my audience always sees accurate, current information.

**Why P1**: Event publishing is the core value the admin panel exists to deliver.

**Acceptance Criteria**:

1. WHEN an approved organizer submits a new event with featured image, date/time, description, location/address, external ticket link, free/paid type, music category, capacity, age range, and additional info THEN the system SHALL create the event in `draft` status.
2. WHEN an organizer edits one of their own events THEN the system SHALL save the changes and apply them to the event immediately.
3. WHEN an organizer duplicates one of their own events THEN the system SHALL create a new `draft` copy with the same field values, excluding engagement stats.
4. WHEN an organizer deletes one of their own events THEN the system SHALL remove it from all consumer-facing listings.
5. WHEN an organizer changes an event's status THEN the system SHALL accept only the transitions draft→published, published→cancelled, published→closed, and draft→cancelled, and SHALL reject any other transition.
6. IF an organizer attempts to edit or delete an event they don't own THEN the system SHALL deny the action.
7. IF an organizer on the Basic (free) tier attempts to transition a 5th event to `published` within the same calendar month THEN the system SHALL block the transition and identify the Plus-tier upgrade as the way to lift the cap.

**Independent Test**: As an approved organizer, create an event through to `published`, edit a field, duplicate it, then cancel the original — verifying the duplicate is unaffected.

---

### P2: Engagement dashboard

**User Story**: As an approved organizer, I want to see engagement statistics per event and overall, so that I understand what's working.

**Why P2**: Valuable for retention and decision-making, but event publishing works without it.

**Acceptance Criteria**:

1. WHEN an organizer opens an event's statistics view THEN the system SHALL show counts of interested users, views, favorites, and external ticket-link clicks for that event.
2. WHEN an organizer opens the dashboard THEN the system SHALL show performance across all of their events (e.g. relative views/favorites/clicks per event).
3. IF an event has zero recorded activity THEN the system SHALL show explicit zero-value stats rather than omitting the event from the dashboard.

**Independent Test**: Publish an event, generate a view/favorite/click from the consumer side, confirm the counts appear on both the per-event and overall dashboard views.

---

### P2: Manage venue ("Casa de Shows") presence

**User Story**: As an approved organizer, I want to manage my venue's public data and see its agenda and history, so that my venue has an accurate presence on the platform.

**Why P2**: Supports discovery and trust but isn't required to publish a single event.

**Acceptance Criteria**:

1. WHEN an organizer edits their venue's name, description, address, contact, or image THEN the system SHALL save the change and reflect it on the venue's public presence.
2. WHEN an organizer opens the venue agenda view THEN the system SHALL show the venue's upcoming published events.
3. WHEN an organizer opens the venue history view THEN the system SHALL show the venue's past (closed or elapsed) events.

**Independent Test**: Edit venue contact info, publish an event tied to that venue, confirm it appears in the agenda, then move it into the past and confirm it appears in history.

---

### P2: Track audience interest and respond to requests

**User Story**: As an approved organizer, I want to see who's interested in my event, mutual friends attending, and respond to info/update requests, so that I can engage my audience directly.

**Why P2**: Deepens engagement but is not required for the core publish-and-measure loop.

**Acceptance Criteria**:

1. WHEN an organizer opens an event's audience view THEN the system SHALL show the count and list of users who marked interest.
2. WHEN an organizer opens an interested user's detail THEN the system SHALL show any mutual friends of that user who are also attending, where available.
3. WHEN a user submits an info/update request on an event THEN the system SHALL surface that request to the organizer with the ability to respond.

**Independent Test**: Have a consumer mark interest and submit an info request; confirm both appear in the organizer's audience view and the organizer can respond.

---

### P2: Manage promoters

**User Story**: As an approved organizer, I want to register promoters and link them to events, so that attendees know who to contact.

**Why P2**: Supports the promoter-contact feature on the consumer side but isn't required to publish an event.

**Acceptance Criteria**:

1. WHEN an organizer registers a promoter with name, contact phone, email, Instagram link, and TikTok link THEN the system SHALL save the promoter as a record owned by that organizer.
2. WHEN an organizer links a promoter to one of their events THEN the system SHALL make that promoter visible on the event's consumer-facing promoter list.
3. WHEN an organizer edits or removes a promoter THEN the system SHALL apply the change to every event that promoter is linked to.
4. WHEN an organizer opens an event's promoter list THEN the system SHALL show every promoter currently linked to that event.

**Independent Test**: Register a promoter, link them to a published event, confirm they appear on that event's consumer-facing details page, then remove the link and confirm they no longer appear.

---

### P2: Manage plan pricing

**User Story**: As a Super Admin, I want to set the Plus tier's price and see its history, so that pricing changes are deliberate and auditable rather than a silent edit.

**Why P2**: Not required for the approval gate or core event-publishing loop, but the landing page has no real price to show without it.

**Acceptance Criteria**:

1. WHEN a Super Admin submits a new price for the Plus tier THEN the system SHALL save it as the current price and preserve every prior price as a historical record with its effective date range.
2. WHEN a Super Admin opens the plan-pricing view THEN the system SHALL show the current Plus price and its full price history.
3. IF a Super Admin submits an invalid price (non-numeric, negative, or zero) THEN the system SHALL reject the submission and identify the problem.
4. THE system SHALL restrict plan-pricing management to Super Admin accounts only.

**Independent Test**: As Super Admin, set an initial Plus price, change it a second time, and confirm the pricing view shows the current price plus both historical entries with their effective dates.

---

### P2: Organizer data export and deletion (LGPD)

**User Story**: As an approved organizer, I want to export my own data and request my account's deletion, so that I can exercise my LGPD rights without contacting support.

**Why P2**: Not required to publish a first event, but mandatory for LGPD compliance (AD-008) before real organizer data is collected in production.

**Acceptance Criteria**:

1. WHEN an organizer requests a data export THEN the system SHALL generate a downloadable export of their account, venue, event, and promoter data.
2. WHEN an organizer requests account deletion THEN the system SHALL deactivate the account, remove their events from consumer-facing listings, and delete their personal data within a defined retention window.
3. IF an organizer's account has an upcoming published event at the time of a deletion request THEN the system SHALL warn them of the consequence before confirming deletion.
4. THE system SHALL restrict an organizer's data export/deletion actions to that organizer's own account, with a Super Admin override available for support cases.

**Independent Test**: As an approved organizer with at least one published event, request a data export and confirm it contains that event; then request deletion, confirm the event disappears from consumer listings, and confirm login is no longer possible.

---

## Edge Cases

- IF a Super Admin account itself is deactivated or doesn't exist THEN the system SHALL ensure no organizer can self-approve (no path bypasses the approval gate).
- IF two organizer staff accounts (future multi-user org, not in this pass) — N/A: PRD and user decisions describe one account per organizer/venue; multi-seat access is not specified.
- IF an organizer tries to publish an event missing a required field (image, date/time, location, ticket link, free/paid type) THEN the system SHALL block the status transition to `published` and identify the missing fields.
- IF an organizer's account is approved mid-session (they were logged in as `pending`) THEN the system SHALL require them to re-authenticate before granting management access, rather than upgrading a live session silently.
- WHEN an organizer deletes a promoter that is linked to a published event THEN the system SHALL remove the promoter from that event's public list without deleting the event itself.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| ADMIN-01 | P1: Organizer access is gated by Super Admin approval | Execute | Verified (backend, T9; no frontend deliverable in scope — see Phase 8 validation Finding 3) |
| ADMIN-02 | P1: Organizer access is gated by Super Admin approval | Design | Pending |
| ADMIN-03 | P1: Organizer access is gated by Super Admin approval | Design | Pending |
| ADMIN-04 | P1: Organizer access is gated by Super Admin approval | Execute | Verified (T10 backend + T23/T24 frontend) |
| ADMIN-05 | P1: Organizer access is gated by Super Admin approval | Execute | Verified (T9 backend verified; T23 frontend route guard implemented and verified — see Phase 8 re-verify iteration 1) |
| ADMIN-06 | P1: Register and manage events | Execute | Verified (T14 backend + T25/T26 frontend — Phase 9 validation, AC1) |
| ADMIN-07 | P1: Register and manage events | Execute | Verified (T14 backend + T25 frontend edit-save path now tested — Phase 9 re-verify iteration 1, AC2) |
| ADMIN-08 | P1: Register and manage events | Design | Pending |
| ADMIN-09 | P1: Register and manage events | Execute | Verified (T14 backend + T25 frontend delete UI now implemented and tested — Phase 9 re-verify iteration 1, AC4) |
| ADMIN-10 | P1: Register and manage events | Execute | Verified (T14 backend + T25/T26 frontend — Phase 9 validation, AC6) |
| ADMIN-11 | P2: Engagement dashboard | Execute | Verified (T17 backend + T27/T28 frontend — Phase 10 validation, AC1/AC2/AC3) |
| ADMIN-12 | P2: Engagement dashboard | Execute | Verified (T17 backend + T27/T28 frontend — Phase 10 validation, AC2) |
| ADMIN-13 | P2: Manage venue ("Casa de Shows") presence | Design | Pending |
| ADMIN-14 | P2: Manage venue ("Casa de Shows") presence | Design | Pending |
| ADMIN-15 | P2: Track audience interest and respond to requests | Design | Blocked — needs `event_interests`/`friendships`, both owned entirely by `web-app`/`mobile-app` (not built here by explicit user rule, see `.specs/STATE.md` AD-023); not merely a scheduling gap |
| ADMIN-16 | P2: Track audience interest and respond to requests | Execute | Verified (T19 backend + T27/T28 frontend — Phase 10 validation, AC3) |
| ADMIN-17 | P2: Manage promoters | Design | Pending |
| ADMIN-18 | P2: Manage promoters | Design | Pending |
| ADMIN-19 | P2: Manage promoters | Design | Pending |
| ADMIN-20 | P2: Manage plan pricing | Execute | Done (T20) |
| ADMIN-21 | P2: Manage plan pricing | Execute | Done (T20) |
| ADMIN-22 | P2: Manage plan pricing | Execute | Done (T20) |
| ADMIN-23 | P2: Manage plan pricing | Execute | Done (T20) |
| ADMIN-24 | P2: Organizer data export and deletion (LGPD) | Execute | Verified (T21) |
| ADMIN-25 | P2: Organizer data export and deletion (LGPD) | Execute | Verified (T22) |
| ADMIN-26 | P2: Organizer data export and deletion (LGPD) | Execute | Verified (T22) |
| ADMIN-27 | P2: Organizer data export and deletion (LGPD) | Execute | Verified (T22) |
| ADMIN-28 | P1: Register and manage events (Basic-tier event-cap enforcement, AD-005) | Execute | Verified (T14 backend + T25/T26 frontend — Phase 9 validation, AC7) |

**ID format:** `ADMIN-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 28 total, 0 mapped to tasks, 28 unmapped ⚠️

---

## Success Criteria

- [ ] An organizer account cannot reach event/venue/promoter management in any state other than `approved`, verified against all three states.
- [ ] An approved organizer can take a new event from creation to `published` in one sitting, with all PRD-listed fields captured.
- [ ] Every FR-ADM-01..10 requirement from the PRD has at least one corresponding ADMIN-* acceptance criterion above.
- [ ] A Basic-tier organizer is blocked from publishing a 5th event within a calendar month; a Plus-tier organizer is not.
- [ ] A Super Admin can change the Plus price and every prior price remains visible in history — zero price changes are ever overwritten without a trace.
- [ ] An organizer can export their own data and request deletion without Super Admin intervention, and a deleted account can no longer log in.
