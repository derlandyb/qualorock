# Mobile App (Consumer) Specification

## Problem Statement

Grande Vitória's live-music scene is fragmented across word-of-mouth, Instagram stories, and venue-specific channels — a fan has no single place to discover nearby shows, see what friends are into, or get to a ticket link fast. Qual o Rock? gives attendees one mobile app to discover events near them, track favorites and friends' interest, and jump straight to an external ticket platform when they're ready to buy.

## Goals

- [ ] A user can go from opening the app to an external ticket-purchase link in 3 taps or fewer (listing → card tap → ticket button).
- [ ] A user can find out which of their friends are interested in an event without leaving the event details screen.
- [ ] A user never has to manually refresh to see new or changed events — the listing stays current on its own.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
| --- | --- |
| In-app ticket purchase / payment processing | PRD §3, §7 — tickets route through an external link/platform; no checkout is built here. |
| Promoter self-service login or app | PRD §2 — promoters are contact records managed by an organizer, not account holders. |
| Push/email delivery infrastructure (the sending pipeline itself) | PRD §3 — only the user-facing preference toggles are in scope; the delivery mechanism is a platform concern, not this app's. |
| Admin/organizer event management, dashboards, promoter management | Owned by `.specs/features/admin-panel/spec.md`. |
| Landing page, subscription plans, super-admin approval | Owned by `.specs/features/landing-page-plans/spec.md` and `.specs/features/admin-panel/spec.md`. |
| Desktop/web presentation of this same functionality | Owned by `.specs/features/web-app/spec.md` — kept as an independent spec per project decision, even though the functional behavior mirrors this one. |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear.

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Event location map (FR-MOB-12) | Ship as an embedded map element inside the event details screen (not a standalone map screen) | PRD §4.1 flags this as a design gap — no dedicated map screen exists across the 9 Stitch pairs; embedding is the minimal interpretation consistent with the mindmap wording "location on a map" | n |
| Real-time listing updates (MOBILE-02) | Poll or subscribe such that a new/changed/removed event appears within 60 seconds without a manual pull-to-refresh | PRD only says "real time"; 60s is a concrete, testable default pending a backend-capability decision in Design | n |
| "Friends interested" visibility (MOBILE-10) | Any of the user's confirmed friends who tapped "interested" on that event are shown by name/avatar on the event details page | PRD says "let a user see which friends are interested" without defining what counts as interest vs. favorite; treating "interested" as its own explicit action (distinct from favoriting) matches the Feed Social screen's "quem vai" language | n |
| Notification categories & actions (MOBILE-19/20) | Five categories (urgent, ticket-batch/pricing, friends, new-event, reminder), filterable tabs, per-item actions (view details, mute, buy ticket, see who's going, access ticket, delete), bulk edit/clear/undo, and a push channel toggle scoped to "favorited shows and friends only" | Directly read from the shipped Notificações (Mobile) Stitch screen (id `3268d4f7227445a1b6a237781fe3316d`) — not invented | y |
| Search radius / address source (MOBILE-15) | User sets one primary address (manual entry or device location permission); search radius is a user-adjustable preference with a sane default (10 km) | PRD says "supporting a primary address, manual updates, and location permission" but doesn't give a default radius | n |
| LGPD consent at signup | Signup requires an explicit, checked consent to data processing before account creation, recorded with a timestamp | Explicit user decision this session (AD-008) | y |
| Self-service data export/deletion source of truth | This capability (MOBILE-24) is owned by `web-app` (WEB-24/25) since the account is shared between mobile and web (WEB-13); the mobile app deep-links into the same underlying flow rather than duplicating the UI | Explicit user decision this session (AD-008): avoid duplicating a shared-account capability across two specs | y |
| Session storage (mobile) | The mobile session token is stored in platform-native secure storage (iOS Keychain / Android Keystore), never in plaintext on-device storage | Explicit user decision this session (AD-008) — the mobile equivalent of "not localStorage" | y |

**Open questions:** none - all resolved or logged above.

---

## User Stories

### P1: Discover and act on nearby events ⭐ MVP

**User Story**: As an event-goer, I want to see a live, ordered list of nearby music events and get straight to a ticket link, so that I can decide what to attend without hunting across apps.

**Why P1**: This is the core discovery-to-ticket loop the whole product exists for; nothing else is demoable without it.

**Acceptance Criteria**:

1. WHEN a user opens the events screen THEN the system SHALL display events ordered by date, nearest first.
2. WHILE the events screen is open the system SHALL reflect event changes (new, edited, removed) within 60 seconds without a manual refresh.
3. WHEN the user scrolls to the end of the currently loaded events THEN the system SHALL load the next page (infinite scroll or pagination).
4. The system SHALL render each event card with a featured image, date/time, short description, location, and a free/paid indicator.
5. WHEN a user taps the favorite icon on an event card THEN the system SHALL add that event to the user's favorited events without leaving the listing.
6. WHEN a user taps an event card THEN the system SHALL navigate to that event's details page.
7. The system SHALL show on the event details page: name, full description, date, time, location, full address, featured image, and music category.
8. The system SHALL provide a button on the event details page that opens the external ticket-purchase link.
9. The system SHALL display a free/paid indicator and a favorite button on the event details page.
10. IF the external ticket link fails to open (e.g. no network, broken URL) THEN the system SHALL show an inline error message and keep the user on the event details page.

**Independent Test**: Open the app, scroll the listing, favorite a card, open an event, and follow the ticket link — all without touching account or social features.

---

### P1: Sign in and manage an account ⭐ MVP

**User Story**: As an event-goer, I want to create an account and sign in with a method I already use, so that my favorites and preferences follow me.

**Why P1**: Every other MVP feature (favorites, friends, notifications) depends on an authenticated user.

**Acceptance Criteria**:

1. WHEN a user chooses Instagram, Facebook, or Google on the login screen THEN the system SHALL complete login via that provider's OAuth flow.
2. WHEN a user submits a valid email/password pair THEN the system SHALL log the user in.
3. IF a user submits an invalid email/password pair THEN the system SHALL reject the attempt and show an error identifying it as an invalid-credentials failure (not which field is wrong).
4. WHEN a new user completes signup THEN the system SHALL create an account and route them into account validation.
5. WHILE an account is unvalidated the system SHALL restrict it to the validation flow (no event/social features) until validation completes.
6. WHEN a user requests password recovery with a registered email THEN the system SHALL send a recovery flow to that email.
7. The system SHALL keep a user's session active across app restarts until they explicitly log out or the session expires.
8. WHEN a user submits the signup form THEN the system SHALL require an explicit, checked consent to data processing before account creation succeeds, and SHALL record the consent with a timestamp.

**Independent Test**: Sign up with email, complete validation, log out, log back in with the same credentials, and separately verify a social-login path reaches the same authenticated state.

---

### P2: Manage profile, preferences, and favorites

**User Story**: As an event-goer, I want to edit my profile, set my search radius and event-type preferences, and manage my favorited events, so that the app surfaces what actually matters to me.

**Why P2**: Improves relevance and retention but the app is usable without it on day one.

**Acceptance Criteria**:

1. WHEN a user edits phone, address, photo, or username in their profile THEN the system SHALL save the change and reflect it immediately in the profile view.
2. WHEN a user sets or updates their address (manually or via location permission) THEN the system SHALL use that address as the basis for "nearby" event ranking.
3. WHEN a user sets favorite event types or a search radius THEN the system SHALL apply those preferences to future event listing results.
4. WHEN a user opens the favorited events list THEN the system SHALL show every event they favorited with the ability to open its details or remove it from favorites.
5. WHEN a user removes an event from favorites THEN the system SHALL remove it from the favorited list without requiring app restart.
6. THE system SHALL provide a privacy-policy link with DPO/encarregado contact information from the profile screen.
7. WHEN a user opens data export or account deletion from their profile THEN the system SHALL route them to the shared web-app flow (WEB-24/25) rather than duplicating that capability natively.

**Independent Test**: Change the address and radius, confirm the listing re-ranks; favorite two events, remove one from the favorites screen, confirm only the other remains.

---

### P2: Social — friends and shared interest

**User Story**: As an event-goer, I want to see what my friends are into and share events with them, so that I can go to shows with people I know.

**Why P2**: Drives engagement and virality but discovery/ticketing works standalone without it.

**Acceptance Criteria**:

1. WHEN a user views their friends list THEN the system SHALL show current friends with the ability to add or remove a friend.
2. THE system SHALL surface friend suggestions to the user.
3. WHEN a user views an event's details THEN the system SHALL show which of their friends marked interest in that event.
4. WHEN a user views their social feed THEN the system SHALL show friends' activity, common events, and events popular among friends.
5. WHEN a user shares an event (from the details page or the social feed) THEN the system SHALL open a share action targeting at least one friend or an external channel.

**Independent Test**: Add a friend, have that friend mark interest in an event, confirm the interest appears on the event details page and in the social feed.

---

### P2: Notifications

**User Story**: As an event-goer, I want to be notified about nearby favorites, friend activity, new events, and event changes, so that I don't miss something I'd want to attend.

**Why P2**: Increases return visits but is not required to complete the core discovery/ticketing loop once.

**Acceptance Criteria**:

1. THE system SHALL notify a user when: a favorited event is nearby, a friend marks interest in an event, a new event appears in their region, an event date approaches, or an event changes or is cancelled.
2. WHEN a user opens the notifications screen THEN the system SHALL show notifications grouped into filterable tabs: All, Unread, Urgent Alerts, Batches & Shows, Friends.
3. WHEN a user taps a notification's contextual action (view details, buy ticket, see who's going, access ticket) THEN the system SHALL navigate to the relevant screen.
4. WHEN a user taps "mute this alert" on a notification THEN the system SHALL stop future notifications of that specific alert without disabling the whole channel.
5. WHEN a user taps "clear all" THEN the system SHALL remove all notifications from the list and offer an undo action.
6. WHEN a user toggles the push channel setting THEN the system SHALL enable or disable push delivery, and, when a scope filter is set, restrict push delivery to favorited shows and friends only.

**Independent Test**: Trigger a friend-interest and a new-event-in-region notification, confirm both appear under the correct filter tab, mute one, clear all, and confirm undo restores the cleared list.

---

### P3: Accessibility and event context

**User Story**: As an event-goer with accessibility needs, I want to see accessibility information and event rules before I go, so that I know what to expect at the venue.

**Why P3**: Valuable but a small subset of event details, not required for the core loop.

**Acceptance Criteria**:

1. THE system SHALL display accessibility information and event rules/observations on the event details page, when the organizer provided them.
2. THE system SHALL provide an intuitive, responsive interface across device sizes.
3. THE system SHALL support a dark-mode-first interface consistent with the design system.
4. THE system SHALL meet screen-reader support, adequate color contrast, and adjustable font size for accessibility.

---

## Edge Cases

- IF an event has no favorites, friends interested, or promoters THEN the system SHALL show an explicit empty state rather than a blank section.
- IF a user's location permission is denied THEN the system SHALL fall back to their manually-entered primary address for "nearby" ranking.
- IF the notifications list is empty THEN the system SHALL show the "all clear" empty state with an option to restore recently cleared items (per the Notificações screen's "restaurar notificações" affordance).
- WHEN a user's account is not yet validated THEN the system SHALL block navigation into event/social/notification screens and route back to validation.
- IF an OAuth provider login fails or is cancelled THEN the system SHALL return the user to the login screen with a visible, non-blocking error.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| MOBILE-01 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-02 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-03 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-04 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-05 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-06 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-07 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-08 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-09 | P1: Discover and act on nearby events | Design | Pending |
| MOBILE-10 | P1: Sign in and manage an account | Design | Pending |
| MOBILE-11 | P1: Sign in and manage an account | Design | Pending |
| MOBILE-12 | P1: Sign in and manage an account | Design | Pending |
| MOBILE-13 | P1: Sign in and manage an account | Design | Pending |
| MOBILE-14 | P2: Manage profile, preferences, and favorites | Design | Pending |
| MOBILE-15 | P2: Manage profile, preferences, and favorites | Design | Pending |
| MOBILE-16 | P2: Manage profile, preferences, and favorites | Design | Pending |
| MOBILE-17 | P2: Social — friends and shared interest | Design | Pending |
| MOBILE-18 | P2: Social — friends and shared interest | Design | Pending |
| MOBILE-19 | P2: Notifications | Design | Pending |
| MOBILE-20 | P2: Notifications | Design | Pending |
| MOBILE-21 | P3: Accessibility and event context | Design | Pending |
| MOBILE-22 | P1: Sign in and manage an account (LGPD consent capture) | Design | Pending |
| MOBILE-23 | P2: Manage profile, preferences, and favorites (privacy-policy link) | Design | Pending |
| MOBILE-24 | P2: Manage profile, preferences, and favorites (deep link to shared export/deletion, WEB-24/25) | Design | Pending |

**ID format:** `MOBILE-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 24 total, 0 mapped to tasks, 24 unmapped ⚠️

---

## Success Criteria

- [ ] A new user can go from opening the app to tapping the external ticket link in under 3 taps, measured on the P1 discovery flow.
- [ ] The events listing reflects a backend change (new/edited/removed event) within 60 seconds without a manual refresh, in at least 95% of observed updates.
- [ ] Zero crashes or unhandled errors when favoriting, viewing details, and following a ticket link across 3 consecutive events.
- [ ] Zero signups succeed without a recorded, timestamped consent.
- [ ] The session token is never found in plaintext on-device storage outside the platform-native secure store (Keychain/Keystore).
