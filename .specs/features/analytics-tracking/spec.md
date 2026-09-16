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
`landing-page-plans/design.md`'s original conditional-script-load description | Superseded by AD-019 (Consent Mode v2, confirmed this session) — that file's text is not re-litigated here beyond noting it needs a follow-up amendment to match. |
| Recalling/deleting analytics events already sent to Google after a consent revocation | Google-side data deletion is a separate LGPD data-rights process (AD-008), not a client-side app behavior this spec can enforce. |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Mobile analytics SDK | Firebase Analytics via Kotlin `expect`/`actual` wrapping the native Android/iOS Firebase SDKs directly (AD-020) — no third-party KMP wrapper library | Confirmed this session: no official Google-maintained KMP Firebase SDK exists; expect/actual matches `dev-logging`'s `Logger` pattern (AD-017) | y |
| Starter custom-event taxonomy | `web-app`/`mobile-app`: `event_view`, `favorite_added`, `signup_completed`. `admin-panel`: `event_created`, `promoter_invited`. `landing-page-plans`: `plan_selected`, `checkout_started` | A representative first cut per app's key user actions, covering each app's primary funnel step | n — carried forward as-is into Design; still open for refinement in a future pass |
| GA4 event/parameter limits | Event names ≤40 chars (alphanumeric + underscore, starting with a letter); ≤25 parameters per event; parameter names ≤40 chars (same character rule); parameter values ≤100 chars | Confirmed via Google's current GA4 documentation (Measurement Protocol event limits, Sept 2026) | y |
| Consent mechanism | Google Analytics 4 Consent Mode v2 (`gtag('consent', 'default'/'update', {...})`) across all four apps (AD-019) — supersedes `landing-page-plans/design.md`'s originally-specified conditional-script-load mechanism | Explicit user decision this session: align with Google's current (June 2026) guidance rather than keep the older mechanism | y |
| Consent-for-tracking UI on web-app/admin-panel/mobile-app | New scope for this feature (AD-020) — each app gets its own cookie-consent banner (web, per-app copy per AD-004) or one-time in-app prompt (mobile); not assumed to pre-exist | Confirmed this session: these three apps have no tracking-consent UI today, only AD-008's separate account-data consent checkbox | y |
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

1. WHEN a user visits `web-app`, `admin-panel`, or `landing-page-plans` with no stored consent choice THEN the system SHALL display a cookie-consent banner offering to accept or decline tracking, distinct from AD-008's account-data consent checkbox.
2. WHEN a user makes a choice on the cookie-consent banner THEN the system SHALL persist that choice client-side (e.g. `localStorage`) so the banner does not reappear on a later visit.
3. WHEN `web-app`, `admin-panel`, or `landing-page-plans` loads THEN the system SHALL call `gtag('consent', 'default', {analytics_storage: 'denied', ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied'})` before any custom event is fired (Consent Mode v2, AD-019), then immediately re-apply a previously stored `'granted'` choice via `gtag('consent', 'update', ...)` if one exists.
4. WHILE `analytics_storage` has not been updated to `'granted'`, `web-app`, `admin-panel`, and `landing-page-plans` SHALL NOT call `gtag('event', ...)` for any custom event defined in this spec.
5. WHEN a user accepts the cookie-consent banner THEN the system SHALL call `gtag('consent', 'update', {analytics_storage: 'granted'})`, and from that point on SHALL fire GA4 custom events via `gtag('event', name, params)` for: `web-app` — `event_view` (viewing an event's detail page), `favorite_added` (favoriting an event), `signup_completed` (completing signup); `admin-panel` — `event_created` (an organizer publishes an event), `promoter_invited` (an organizer invites a promoter); `landing-page-plans` — `plan_selected` (choosing a plan tier), `checkout_started` (following the external billing link).
6. THE system SHALL keep `ad_storage`, `ad_user_data`, and `ad_personalization` permanently `'denied'` — no user action in this spec ever updates them to `'granted'` (no Google Ads integration exists to justify it).
7. THE system SHALL validate every custom event name against GA4's naming rule (≤40 characters, alphanumeric and underscore only, starting with a letter) before calling `gtag`, and SHALL reject — log and skip, never send — any event name that violates the rule.
8. THE system SHALL cap every custom event to at most 25 parameters, each with a parameter name ≤40 characters, truncating any parameter value that exceeds 100 characters rather than sending an oversized value.
9. IF the GA script fails to load, or a `gtag` call throws THEN the system SHALL swallow the failure and continue normal app operation — an analytics failure SHALL NOT block or crash the user action that triggered it.

**Independent Test**: With `analytics_storage` granted, trigger `event_view` on `web-app` and confirm the GA4 DebugView shows the event with its parameters; revoke consent (update `analytics_storage` back to `'denied'`) and confirm no further custom events fire.

---

### P2: Mobile app fires the same taxonomy via Firebase Analytics

**User Story**: As a product owner, I want `mobile-app` to fire the same consumer custom events as `web-app`, using Firebase Analytics, so that GA4 reports aggregate consumer engagement across web and mobile in one view.

**Why P2**: Depends on the taxonomy defined in P1 and on `mobile-app`'s own feature spec/tasks existing before this can be implemented — sequenced after the web rollout, not blocking it.

**Acceptance Criteria**:

1. WHEN a user opens `mobile-app` for the first time (no stored consent choice) THEN the system SHALL display a one-time tracking-consent prompt, distinct from AD-008's account-data consent, and persist the user's choice on-device so it is not shown again on later launches.
2. WHILE the stored consent choice is not `granted`, `mobile-app` SHALL call Firebase Analytics' `setAnalyticsCollectionEnabled(false)` and SHALL NOT call `logEvent` for any custom event.
3. WHEN a user grants tracking consent THEN `mobile-app` SHALL call `setAnalyticsCollectionEnabled(true)`, and from that point on SHALL fire `event_view`, `favorite_added`, and `signup_completed` via `logEvent`, using the same event and parameter names as the web implementation (P1's AC5).
4. THE system SHALL apply the same GA4 naming and size limits (P1's AC7/AC8) to every Firebase Analytics event fired on mobile.
5. IF the Firebase Analytics SDK fails to initialize, or a `logEvent` call throws THEN the system SHALL swallow the failure and continue normal app operation.

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
- IF an app attempts to fire a custom event before the user has made any consent choice (neither granted nor declined) THEN the system SHALL treat that as consent-not-granted and SHALL NOT fire the event, consistent with P1's AC4 and P2's AC2 treating "not granted" as the default safe state.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| ANLY-01 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-02 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-03 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-04 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-05 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-06 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-07 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-08 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-09 | P1: Web apps fire a consistent custom-event taxonomy, consent-gated | Tasks | Pending |
| ANLY-10 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-11 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-12 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-13 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-14 | P2: Mobile app fires the same taxonomy via Firebase Analytics | Tasks | Pending |
| ANLY-15 | P3: A developer can see every Firebase Analytics event mobile sends, in debug builds | Tasks | Pending |
| ANLY-16 | P3: A developer can see every Firebase Analytics event mobile sends, in debug builds | Tasks | Pending |

**ID format:** `ANLY-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 16 total, 0 mapped to tasks, 16 unmapped ⚠️

---

## Success Criteria

- [ ] `web-app` and `admin-panel` each show a working cookie-consent banner (landing-page-plans's is amended to Consent Mode v2 by a follow-up to its own `design.md`), and `mobile-app` shows a one-time in-app tracking-consent prompt, none of which existed before this feature.
- [ ] `web-app`, `admin-panel`, and `landing-page-plans` each fire their defined custom events, visible in GA4 DebugView, only after consent is granted.
- [ ] Revoking consent on any app stops further events without a page reload/app restart being required.
- [ ] `mobile-app`'s `event_view`/`favorite_added`/`signup_completed` events match `web-app`'s event/parameter names exactly.
- [ ] Every Firebase Analytics event sent in a mobile debug build has a corresponding `Logger.event` line with the same name and parameters.
- [ ] No custom event anywhere exceeds GA4's 40-character name / 25-parameter / 100-character value limits.
