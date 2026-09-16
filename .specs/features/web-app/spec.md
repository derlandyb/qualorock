# Web App (Consumer, Desktop) Specification

## Problem Statement

Not every attendee discovers events from their phone — someone planning a night out from a laptop, or sharing a link in a desktop browser, needs the same discovery-to-ticket experience Qual o Rock? offers on mobile. This spec covers the desktop/web companion to the mobile consumer app, tracked independently so a web-only gap (like the missing desktop notifications screen) never silently blocks or gets absorbed into the mobile spec.

## Goals

- [ ] A desktop user reaches the same external ticket-purchase link in 3 clicks or fewer (listing → card click → ticket button).
- [ ] Every consumer capability available on mobile (discovery, account, social, favorites) is available on desktop, except where a screen genuinely doesn't exist yet (tracked as a gap below).

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
| --- | --- |
| In-app ticket purchase / payment processing | PRD §3, §7 — tickets route through an external link/platform; no checkout is built here. |
| Promoter self-service login or app | PRD §2 — promoters are contact records managed by an organizer, not account holders. |
| Push/email delivery infrastructure (the sending pipeline itself) | Only user-facing preference toggles are in scope. |
| Admin/organizer event management, dashboards, promoter management | Owned by `.specs/features/admin-panel/spec.md`. |
| Landing page, subscription plans, super-admin approval | Owned by `.specs/features/landing-page-plans/spec.md` and `.specs/features/admin-panel/spec.md`. |
| Mobile-specific presentation (this app's own mobile counterpart) | Owned by `.specs/features/mobile-app/spec.md` — kept as an independent spec per project decision, even though the functional behavior mirrors this one. |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear.

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Desktop notifications screen | No dedicated desktop notifications screen has been designed; ship the mobile Notificações layout responsively reflowed for desktop rather than waiting on a new Stitch screen | The Stitch project has a mobile-only "Notificações" screen (id `3268d4f7227445a1b6a237781fe3316d`) and no desktop pair; blocking the whole web spec on a new screen would stall every other desktop requirement | n |
| Event location map (WEB-12) | Ship as an embedded map element inside the event details page (not a standalone map page) | Mirrors the same PRD §4.1 gap and interpretation used in the mobile-app spec, for consistency across platforms | n |
| Real-time listing updates (WEB-02) | A new/changed/removed event appears within 60 seconds without a manual page refresh | Same rationale as mobile-app spec — concrete, testable default pending a backend-capability decision in Design | n |
| "Friends interested" visibility (WEB-10) | Any of the user's confirmed friends who tapped "interested" on that event are shown by name/avatar on the event details page | Mirrors the mobile-app spec's interpretation for consistency | n |
| Search radius / address source (WEB-15) | User sets one primary address (manual entry; desktop has no device-location permission prompt) with a user-adjustable search radius, default 10 km | Desktop browsers can request geolocation but the PRD's "location permission" language reads as a mobile-native affordance; manual address entry is the reliable desktop default | n |
| LGPD consent at signup | Signup requires an explicit, checked consent to data processing before account creation, recorded with a timestamp | Explicit user decision this session (AD-008) | y |
| Self-service data export/deletion source of truth | `web-app` owns the full export/deletion UI (WEB-24/25) since the account is shared with mobile (WEB-13); `mobile-app` deep-links here rather than duplicating it | Explicit user decision this session (AD-008): avoid duplicating a shared-account capability across two specs | y |
| Session storage (web) | The web session uses an HttpOnly, Secure, SameSite cookie, never localStorage or a JS-readable token | Explicit user decision this session (AD-008) | y |

**Open questions:** none - all resolved or logged above.

---

## User Stories

### P1: Discover and act on nearby events ⭐ MVP

**User Story**: As an event-goer on desktop, I want to see a live, ordered list of nearby music events and get straight to a ticket link, so that I can decide what to attend without hunting across apps.

**Why P1**: Core discovery-to-ticket loop; mirrors the mobile MVP so the platform has parity from day one.

**Acceptance Criteria**:

1. WHEN a user opens the events page THEN the system SHALL display events ordered by date, nearest first.
2. WHILE the events page is open the system SHALL reflect event changes (new, edited, removed) within 60 seconds without a manual page refresh.
3. WHEN the user scrolls to the end of the currently loaded events THEN the system SHALL load the next page (infinite scroll or pagination).
4. The system SHALL render each event card with a featured image, date/time, short description, location, and a free/paid indicator.
5. WHEN a user clicks the favorite icon on an event card THEN the system SHALL add that event to the user's favorited events without a full page reload.
6. WHEN a user clicks an event card THEN the system SHALL navigate to that event's details page.
7. The system SHALL show on the event details page: name, full description, date, time, location, full address, featured image, and music category.
8. The system SHALL provide a button on the event details page that opens the external ticket-purchase link in a new tab.
9. The system SHALL display a free/paid indicator and a favorite button on the event details page.
10. IF the external ticket link fails to open THEN the system SHALL show an inline error message and keep the user on the event details page.

**Independent Test**: Open the site, scroll the listing, favorite a card, open an event, and follow the ticket link — all without touching account or social features.

---

### P1: Sign in and manage an account ⭐ MVP

**User Story**: As an event-goer on desktop, I want to create an account and sign in with a method I already use, so that my favorites and preferences follow me across devices.

**Why P1**: Every other MVP feature (favorites, friends, notifications) depends on an authenticated user, and the account must be shared with the mobile app.

**Acceptance Criteria**:

1. WHEN a user chooses Instagram, Facebook, or Google on the login page THEN the system SHALL complete login via that provider's OAuth flow.
2. WHEN a user submits a valid email/password pair THEN the system SHALL log the user in.
3. IF a user submits an invalid email/password pair THEN the system SHALL reject the attempt and show an error identifying it as an invalid-credentials failure (not which field is wrong).
4. WHEN a new user completes signup THEN the system SHALL create an account and route them into account validation.
5. WHILE an account is unvalidated the system SHALL restrict it to the validation flow (no event/social features) until validation completes.
6. WHEN a user requests password recovery with a registered email THEN the system SHALL send a recovery flow to that email.
7. The system SHALL keep a user's session active across browser restarts until they explicitly log out or the session expires.
8. THE system SHALL share the same underlying account/session as the mobile app — a user logged in on mobile SHALL see the same favorites, friends, and preferences on the web, and vice versa.
9. WHEN a user submits the signup form THEN the system SHALL require an explicit, checked consent to data processing before account creation succeeds, and SHALL record the consent with a timestamp.

**Independent Test**: Sign up on the web, complete validation, log in with the same credentials on mobile, and confirm favorites set on one appear on the other.

---

### P2: Manage profile, preferences, and favorites

**User Story**: As an event-goer on desktop, I want to edit my profile, set my search radius and event-type preferences, and manage my favorited events, so that the site surfaces what actually matters to me.

**Why P2**: Improves relevance and retention but the site is usable without it on day one.

**Acceptance Criteria**:

1. WHEN a user edits phone, address, photo, or username in their profile THEN the system SHALL save the change and reflect it immediately in the profile view.
2. WHEN a user sets or updates their address THEN the system SHALL use that address as the basis for "nearby" event ranking.
3. WHEN a user sets favorite event types or a search radius THEN the system SHALL apply those preferences to future event listing results.
4. WHEN a user opens the favorited events page THEN the system SHALL show every event they favorited with the ability to open its details or remove it from favorites.
5. WHEN a user removes an event from favorites THEN the system SHALL remove it from the favorited list without requiring a page reload.
6. THE system SHALL provide a privacy-policy link with DPO/encarregado contact information from the profile page footer.
7. WHEN a user requests a data export from their profile THEN the system SHALL generate a downloadable export of their account, favorites, friends, and preferences data.
8. WHEN a user requests account deletion from their profile THEN the system SHALL deactivate the account across both web and mobile, and delete the user's personal data within a defined retention window.
9. IF a user's account has state that would be lost on deletion (e.g. unresolved friend requests) THEN the system SHALL warn them of the consequence before confirming deletion.

**Independent Test**: Change the address and radius, confirm the listing re-ranks; favorite two events, remove one from the favorites page, confirm only the other remains.

---

### P2: Social — friends and shared interest

**User Story**: As an event-goer on desktop, I want to see what my friends are into and share events with them, so that I can go to shows with people I know.

**Why P2**: Drives engagement and virality but discovery/ticketing works standalone without it.

**Acceptance Criteria**:

1. WHEN a user views their friends list THEN the system SHALL show current friends with the ability to add or remove a friend.
2. THE system SHALL surface friend suggestions to the user.
3. WHEN a user views an event's details THEN the system SHALL show which of their friends marked interest in that event.
4. WHEN a user views their social feed THEN the system SHALL show friends' activity, common events, and events popular among friends.
5. WHEN a user shares an event (from the details page or the social feed) THEN the system SHALL open a share action (copy link, or an external channel) targeting at least one friend.

**Independent Test**: Add a friend, have that friend mark interest in an event, confirm the interest appears on the event details page and in the social feed.

---

### P2: Notifications

**User Story**: As an event-goer on desktop, I want to be notified about nearby favorites, friend activity, new events, and event changes, so that I don't miss something I'd want to attend.

**Why P2**: Increases return visits but is not required to complete the core discovery/ticketing loop once. No desktop-specific Stitch screen exists yet — see Assumptions.

**Acceptance Criteria**:

1. THE system SHALL notify a user when: a favorited event is nearby, a friend marks interest in an event, a new event appears in their region, an event date approaches, or an event changes or is cancelled.
2. WHEN a user opens the notifications page THEN the system SHALL show notifications grouped into filterable tabs: All, Unread, Urgent Alerts, Batches & Shows, Friends.
3. WHEN a user clicks a notification's contextual action (view details, buy ticket, see who's going, access ticket) THEN the system SHALL navigate to the relevant page.
4. WHEN a user clicks "mute this alert" on a notification THEN the system SHALL stop future notifications of that specific alert without disabling the whole channel.
5. WHEN a user clicks "clear all" THEN the system SHALL remove all notifications from the list and offer an undo action.
6. WHEN a user toggles the push/email channel setting THEN the system SHALL enable or disable delivery for that channel, and, when a scope filter is set, restrict delivery to favorited shows and friends only.

**Independent Test**: Trigger a friend-interest and a new-event-in-region notification, confirm both appear under the correct filter tab, mute one, clear all, and confirm undo restores the cleared list.

---

### P3: Accessibility and event context

**User Story**: As an event-goer with accessibility needs, I want to see accessibility information and event rules before I go, so that I know what to expect at the venue.

**Why P3**: Valuable but a small subset of event details, not required for the core loop.

**Acceptance Criteria**:

1. THE system SHALL display accessibility information and event rules/observations on the event details page, when the organizer provided them.
2. THE system SHALL provide an intuitive, responsive interface across desktop viewport sizes (down to tablet breakpoints).
3. THE system SHALL support a dark-mode-first interface consistent with the design system.
4. THE system SHALL meet screen-reader support, adequate color contrast, and adjustable font size for accessibility.

---

## Edge Cases

- IF an event has no favorites, friends interested, or promoters THEN the system SHALL show an explicit empty state rather than a blank section.
- IF browser geolocation is denied or unavailable THEN the system SHALL fall back to the user's manually-entered primary address for "nearby" ranking.
- IF the notifications list is empty THEN the system SHALL show the "all clear" empty state with an option to restore recently cleared items.
- WHEN a user's account is not yet validated THEN the system SHALL block navigation into event/social/notification pages and route back to validation.
- IF an OAuth provider login fails or is cancelled THEN the system SHALL return the user to the login page with a visible, non-blocking error.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| WEB-01 | P1: Discover and act on nearby events | Design | Pending |
| WEB-02 | P1: Discover and act on nearby events | Design | Pending |
| WEB-03 | P1: Discover and act on nearby events | Design | Pending |
| WEB-04 | P1: Discover and act on nearby events | Design | Pending |
| WEB-05 | P1: Discover and act on nearby events | Design | Pending |
| WEB-06 | P1: Discover and act on nearby events | Design | Pending |
| WEB-07 | P1: Discover and act on nearby events | Design | Pending |
| WEB-08 | P1: Discover and act on nearby events | Design | Pending |
| WEB-09 | P1: Discover and act on nearby events | Design | Pending |
| WEB-10 | P1: Sign in and manage an account | Design | Pending |
| WEB-11 | P1: Sign in and manage an account | Design | Pending |
| WEB-12 | P1: Sign in and manage an account | Design | Pending |
| WEB-13 | P1: Sign in and manage an account | Design | Pending |
| WEB-14 | P2: Manage profile, preferences, and favorites | Design | Pending |
| WEB-15 | P2: Manage profile, preferences, and favorites | Design | Pending |
| WEB-16 | P2: Manage profile, preferences, and favorites | Design | Pending |
| WEB-17 | P2: Social — friends and shared interest | Design | Pending |
| WEB-18 | P2: Social — friends and shared interest | Design | Pending |
| WEB-19 | P2: Notifications | Design | Pending |
| WEB-20 | P2: Notifications | Design | Pending |
| WEB-21 | P3: Accessibility and event context | Design | Pending |
| WEB-22 | P1: Sign in and manage an account (LGPD consent capture) | Design | Pending |
| WEB-23 | P2: Manage profile, preferences, and favorites (privacy-policy link) | Design | Pending |
| WEB-24 | P2: Manage profile, preferences, and favorites (LGPD data export) | Design | Pending |
| WEB-25 | P2: Manage profile, preferences, and favorites (LGPD account/data deletion) | Design | Pending |

**ID format:** `WEB-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 25 total, 0 mapped to tasks, 25 unmapped ⚠️

---

## Success Criteria

- [ ] A new user can go from opening the site to clicking the external ticket link in under 3 clicks, measured on the P1 discovery flow.
- [ ] The events listing reflects a backend change (new/edited/removed event) within 60 seconds without a manual refresh, in at least 95% of observed updates.
- [ ] A user's favorites and preferences set on mobile are visible on the web (and vice versa) within one session refresh.
- [ ] Zero signups succeed without a recorded, timestamped consent.
- [ ] A user can export their data and delete their account without contacting support, and a deleted account is unusable on both web and mobile immediately after deletion.
- [ ] The session token is never present in `localStorage`/`sessionStorage` — verified via a browser devtools check finding only the HttpOnly cookie.
