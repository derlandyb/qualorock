# Custom Analytics Tracking Specification

## Problem Statement

AD-009 decided Google Analytics for consumer-facing surfaces and mentioned "first-party engagement data already modeled for the admin dashboard," but no spec defines the actual custom events to fire, and only `landing-page-plans`'s `design.md` details a GA integration (script + cookie-consent gate) today. This spec extends AD-009 with a consistent custom-event taxonomy across all four platform apps (mobile-app, web-app, admin-panel, landing-page-plans), gated by the same consent mechanism AD-008/AD-009 already established.

## Goals

- [ ] Every platform app fires a defined set of GA4 custom events for its key user actions, gated by tracking consent.
- [ ] Web and mobile use the same event/parameter names for shared consumer actions (e.g. `event_view`), so GA4 reports aggregate correctly across platforms.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Replacing Google Analytics with a self-hosted/first-party alternative | Explicit user decision this session — this spec extends GA's own custom-event capability, it does not replace GA or build a new tracking backend. |
| A new first-party event-storage backend (own DB table + admin dashboard reporting) | Same reason — GA4 is the system of record for these events; no duplicate storage is introduced. |
| Landing-page-plans's existing GA script/cookie-consent-banner mechanism | Already specified in `landing-page-plans/design.md` per AD-009 — this spec extends that mechanism to the other three apps, it doesn't re-specify it. |
| Recalling/deleting analytics events already sent to Google after a consent revocation | Google-side data deletion is a separate LGPD data-rights process (AD-008), not a client-side app behavior this spec can enforce. |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Mobile analytics SDK | Firebase Analytics (GA4's mobile SDK) | `gtag.js` (used on web) is a web-only script; Firebase Analytics is Google's own GA4-compatible mobile client | n — flagged for confirmation during this feature's Design phase |
| Starter custom-event taxonomy | `web-app`/`mobile-app`: `event_view`, `favorite_added`, `signup_completed`. `admin-panel`: `event_created`, `promoter_invited`. `landing-page-plans`: `plan_selected`, `checkout_started` | A representative first cut per app's key user actions, covering each app's primary funnel step | n — flagged for refinement with the user during Design |
| GA4 event/parameter limits | Event names ≤40 chars (alphanumeric + underscore, starting with a letter); ≤25 parameters per event; parameter names ≤40 chars (same character rule); parameter values ≤100 chars | Confirmed via Google's current GA4 documentation (Measurement Protocol event limits, Sept 2026) | y |
| Consent mechanism | Reuse `landing-page-plans`'s existing cookie/tracking-consent banner mechanism (AD-008/AD-009) on the other three apps — no new consent UI or storage model | Explicit user decision: this extends the existing consent gate, it isn't a second mechanism | y |
| Mobile "debug build" definition | Same debug/release build flavor `dev-logging` (AD-017) already uses for its `Logger` no-op behavior | Keeps one build-flavor concept instead of two competing definitions | y |

**Open questions:** none — all resolved or logged above.

---

## Implicit-Requirement Dimensions Sweep

| Dimension | Resolution |
| --- | --- |
| Input validation & bounds | ANLY-03/ANLY-04/ANLY-08 (GA4 naming/size limits enforced before every send) |
| Failure / partial-failure states | ANLY-05/ANLY-09 (SDK failures are swallowed, never block/crash the triggering action) |
| Idempotency / retry / duplicate handling | N/A because analytics events are fire-and-forget; the vendor SDK (gtag.js/Firebase) owns its own internal batching and retry, and this app never re-sends an event itself |
| Auth boundaries & rate limits | N/A because event calls go directly from the client to Google's servers via the vendor SDK, not to a project-owned endpoint requiring auth |
| Concurrency / ordering | N/A because GA4 does not require or guarantee strict cross-event ordering; each event carries its own SDK-assigned timestamp |
| Data lifecycle / expiry | N/A because event-data retention is governed entirely by Google Analytics' own retention settings, not by this platform |
| Observability | ANLY-10/ANLY-11 (mobile debug-build visibility into every Firebase Analytics event sent) |
| External-dependency failure | ANLY-05/ANLY-09 (GA script / Firebase SDK failure handling) |
| State-transition integrity | ANLY-01/ANLY-06 (consent-granted vs. consent-not-granted gates event firing; consent revocation stops future events per the Edge Cases) |

---

## User Stories

### P1: Web apps fire a consistent custom-event taxonomy, consent-gated ⭐ MVP

**User Story**: As a product owner, I want `web-app`, `admin-panel`, and `landing-page-plans` to fire a defined set of GA4 custom events for their key user actions — only after a user has granted tracking consent — so that I can see real engagement data across all three web surfaces in one GA4 property.

**Why P1**: This is the concrete gap AD-009 left open — only `landing-page-plans` has a detailed GA integration; `web-app` and `admin-panel` have none, and no app has a *custom*-event definition yet.

**Acceptance Criteria**:

1. WHILE a user has not granted tracking/cookie consent, `web-app`, `admin-panel`, and `landing-page-plans` SHALL NOT fire any GA custom event or load the GA script.
2. WHILE a user has granted tracking/cookie consent, the system SHALL fire GA4 custom events via `gtag('event', name, params)` for: `web-app` — `event_view` (viewing an event's detail page), `favorite_added` (favoriting an event), `signup_completed` (completing signup); `admin-panel` — `event_created` (an organizer publishes an event), `promoter_invited` (an organizer invites a promoter); `landing-page-plans` — `plan_selected` (choosing a plan tier), `checkout_started` (following the external billing link).
3. THE system SHALL validate every custom event name against GA4's naming rule (≤40 characters, alphanumeric and underscore only, starting with a letter) before calling `gtag`, and SHALL reject — log and skip, never send — any event name that violates the rule.
4. THE system SHALL cap every custom event to at most 25 parameters, each with a parameter name ≤40 characters, truncating any parameter value that exceeds 100 characters rather than sending an oversized value.
5. IF the GA script fails to load, or a `gtag` call throws THEN the system SHALL swallow the failure and continue normal app operation — an analytics failure SHALL NOT block or crash the user action that triggered it.

**Independent Test**: With tracking consent granted, trigger `event_view` on `web-app` and confirm the GA4 DebugView shows the event with its parameters; revoke consent and confirm no further events fire.

---

### P2: Mobile app fires the same taxonomy via Firebase Analytics

**User Story**: As a product owner, I want `mobile-app` to fire the same consumer custom events as `web-app`, using Firebase Analytics, so that GA4 reports aggregate consumer engagement across web and mobile in one view.

**Why P2**: Depends on the taxonomy defined in P1 and on `mobile-app`'s own feature spec/tasks existing before this can be implemented — sequenced after the web rollout, not blocking it.

**Acceptance Criteria**:

1. WHILE a user has not granted tracking consent, `mobile-app` SHALL NOT initialize Firebase Analytics or send any event.
2. WHILE a user has granted tracking consent, `mobile-app` SHALL fire `event_view`, `favorite_added`, and `signup_completed` via Firebase Analytics' `logEvent` call, using the same event and parameter names as the web implementation (AC2 of the P1 story).
3. THE system SHALL apply the same GA4 naming and size limits (P1's AC3/AC4) to every Firebase Analytics event fired on mobile.
4. IF the Firebase Analytics SDK fails to initialize, or a `logEvent` call throws THEN the system SHALL swallow the failure and continue normal app operation.

**Independent Test**: With tracking consent granted in a debug build, trigger `favorite_added` on mobile and confirm the same event/parameter shape reaches GA4 DebugView as the web version.

---

### P3: A developer can see every Firebase Analytics event mobile sends, in debug builds

**User Story**: As a developer working on `mobile-app`'s analytics integration, I want every Firebase Analytics event logged to the debug console as it's sent, so that I can verify what's actually being tracked without a network inspector.

**Why P3**: Explicit user ask this session — a debugging/verification aid for the analytics integration itself, not a product-facing capability.

**Acceptance Criteria**:

1. WHILE `mobile-app` is a debug build, THE system SHALL log every Firebase Analytics event it sends — event name and full parameter set — through `dev-logging`'s (AD-017) KMP `Logger.event(tag, name, params)` call, at the point the event is sent.
2. WHILE `mobile-app` is a release build, THE system SHALL rely on `dev-logging`'s `Logger` already being a no-op (per that spec's LOG-12) — `analytics-tracking` SHALL NOT add a second release-mode guard around this logging call.

**Independent Test**: In a debug build, trigger `event_view` and confirm `Logger.event("Analytics", "event_view", {...})`'s output appears in Logcat/Console with the exact parameters sent to Firebase; confirm no such output appears in a release build.

---

## Edge Cases

- IF a user revokes previously granted tracking consent THEN the system SHALL stop firing new events from that point forward; data already sent to Google before revocation is not recalled by this spec (that is a separate Google-side/LGPD data-rights process, out of scope here).
- THE system SHALL only ever pass non-PII, categorical or identifier values as event parameters (e.g. an event's UUID, a plan-tier name) — never free-text user input (a name, an email address, a search query) — since this spec adds no separate PII-redaction step for analytics parameters beyond the taxonomy itself being non-PII by construction.
- IF an app attempts to fire a custom event before the user has made any consent choice (neither granted nor declined) THEN the system SHALL treat that as consent-not-granted and SHALL NOT fire the event, consistent with AC1/AC1 (P1/P2) treating "not granted" as the default safe state.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| ANLY-01 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-02 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-03 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-04 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-05 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-06 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-07 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-08 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-09 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-10 | P3: A developer can see every Firebase Analytics event mobile sends, in debug builds | Tasks | Pending |
| ANLY-11 | P3: A developer can see every Firebase Analytics event mobile sends, in debug builds | Tasks | Pending |

**ID format:** `ANLY-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 11 total, 0 mapped to tasks, 11 unmapped ⚠️

---

## Success Criteria

- [ ] `web-app`, `admin-panel`, and `landing-page-plans` each fire their defined custom events, visible in GA4 DebugView, only after consent is granted.
- [ ] Revoking consent on any app stops further events without a page reload/app restart being required.
- [ ] `mobile-app`'s `event_view`/`favorite_added`/`signup_completed` events match `web-app`'s event/parameter names exactly.
- [ ] Every Firebase Analytics event sent in a mobile debug build has a corresponding `Logger.event` line with the same name and parameters.
- [ ] No custom event anywhere exceeds GA4's 40-character name / 25-parameter / 100-character value limits.
