# Analytics-Tracking Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Design**: `.specs/features/analytics-tracking/design.md`
**Status**: Draft

---

**Prerequisite notes (read before Execute):**

1. Every web/mobile component below targets a real Vite/KMP application skeleton that does not exist yet - `web-app`/`admin-panel`/`landing-page-plans`/`mobile-app`'s own Execute passes haven't started, so `website/`, `admin/`, `landingpage/` contain only `infrastructure`'s Dockerfile, and `mobile/` doesn't exist at all. Same DEFERRED-gate situation `infrastructure`'s T1-T4 and `dev-logging`'s tasks already hit.
2. T7/T8 (mobile `AnalyticsTracker`) call `dev-logging`'s KMP `Logger.event(...)` (LOG-11) for debug visibility. `dev-logging`'s own tasks haven't executed either, so this is a second, cross-feature DEFERRED dependency until `dev-logging`'s `Logger` exists - not just the missing `mobile/` skeleton.
3. This feature also implements the actual named events (`event_view`, `favorite_added`, etc.) as callable constants/functions, but wiring them into real screens (e.g. calling `analyticsTracker.track('event_view', ...)` from `EventDetailPage`) is out of scope here - those screens don't exist yet and are owned by each platform feature's own `tasks.md`. This feature delivers the reusable tracking infrastructure; each platform feature's own Execute pass is expected to call it once its screens exist.

---

## Test Coverage Matrix

> Guidelines found: `.specs/STATE.md` AD-010 (Jest+RTL web, `kotlin.test` for the shared KMP module, Compose UI tests / XCTest for platform UI, GIVEN/WHEN/THEN test names, >=80% coverage). No test files exist yet for any of the three toolchains - the commands below are the standard entrypoints for the tools AD-010 already mandates.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------- | --------------------- | ----------------- | ----------- |
| Web `useTrackingConsent` / `analyticsTracker` (Infrastructure) | unit | All branches: granted/denied/unset states, name/param validation, truncation, swallowed `gtag` failure, GIVEN/WHEN/THEN named | `website/src/infrastructure/analytics/*.test.ts` (+ `admin/`, `landingpage/` equivalents) | `npm --prefix website test`, `npm --prefix admin test`, `npm --prefix landingpage test` |
| Web `ConsentBanner` (Presentation) | unit | Renders only when consent is unset; calls grant/deny on user choice, GIVEN/WHEN/THEN named | `website/src/presentation/components/*.test.tsx` (+ per-app equivalents) | `npm --prefix website test` (+ per-app equivalents) |
| Mobile `ConsentStore` / `AnalyticsTracker` (KMP shared, Infrastructure) | unit | Persistence round-trip, collection-enabled toggling, event validation/truncation, debug-mode `Logger.event` call, swallowed SDK failure, GIVEN/WHEN/THEN named | `mobile/shared/src/commonTest/.../analytics/*Test.kt` | `./gradlew :shared:test` |
| Mobile `TrackingConsentPrompt` (Presentation) | ui | Shown only when consent is unset; calls `ConsentStore`/`AnalyticsTracker` on the user's choice | `mobile/androidApp/.../TrackingConsentPromptTest.kt` (Compose UI test), `mobile/iosApp/.../TrackingConsentPromptTests.swift` (XCTest) | `./gradlew :androidApp:connectedDebugAndroidTest`, `xcodebuild test` (iOS) |
| `landing-page-plans/design.md` amendment | none | - (build gate only): text matches Consent Mode v2 (AD-019), not the superseded conditional-script-load description | `landing-page-plans/design.md` | `grep -qi 'consent mode' landing-page-plans/design.md` |
| Developer documentation | none | - (build gate only): every consumer app's `docs/*/architecture.md` states its analytics-tracking behavior | `docs/{web-app,admin-panel,landing-page-plans,mobile}/architecture.md` | `grep -qi 'analytics' docs/web-app/architecture.md` (repeated per stack) |

## Gate Check Commands

> Generated from AD-010/AD-011 - confirm before Execute once each stack's own skeleton exists (per this file's Prerequisite notes above).

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After tasks with unit tests only (hooks, tracker, ConsentStore) | `npm --prefix <app> test` (web tasks) / `./gradlew :shared:test` (mobile shared tasks) |
| Full | After tasks with UI tests (ConsentBanner, TrackingConsentPrompt) | `npm --prefix <app> test` / `./gradlew :androidApp:connectedDebugAndroidTest && xcodebuild test` |
| Build | After phase completion or doc/config-only tasks | `npm --prefix website test && npm --prefix admin test && npm --prefix landingpage test && ./gradlew :shared:test` |

---

## Execution Plan

Phases are ordered and run sequentially - each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Web consent + tracking infrastructure

```
T1 -> T2
T1 -> T3
```

### Phase 2: Cross-feature follow-up

```
T4
```

### Phase 3: Mobile consent + tracking infrastructure

```
T5 -> T6
T5 -> T7
T7 -> T8
T5 -> T9
T7 -> T9
```

### Phase 4: Documentation (AD-014)

```
T2 -> T10
T3 -> T10
T9 -> T11
```

---

## Task Breakdown

### T1: Create `useTrackingConsent` hook (website, admin, landingpage)

**What**: A hook per app that reads/writes the persisted consent choice (`localStorage`) and calls `gtag('consent', 'default'/'update', ...)` accordingly (Consent Mode v2, AD-019).
**Where**: `website/src/infrastructure/analytics/useTrackingConsent.ts`, `admin/src/infrastructure/analytics/useTrackingConsent.ts`, `landingpage/src/infrastructure/analytics/useTrackingConsent.ts`
**Depends on**: None
**Reuses**: none
**Requirement**: ANLY-01, ANLY-02, ANLY-03, ANLY-06

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN no stored consent choice WHEN the app loads THEN `gtag('consent', 'default', {analytics_storage: 'denied', ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied'})` is called
- [ ] GIVEN a stored `'granted'` choice WHEN the app loads THEN `gtag('consent', 'update', {analytics_storage: 'granted'})` is called immediately after the default call
- [ ] GIVEN `grant()` is called WHEN invoked THEN the choice is persisted as `'granted'` and `gtag('consent', 'update', {analytics_storage: 'granted'})` fires
- [ ] GIVEN `deny()` is called WHEN invoked THEN the choice is persisted as `'denied'` and no `'update'` call grants `analytics_storage`
- [ ] `ad_storage`/`ad_user_data`/`ad_personalization` are never set to `'granted'` by any code path in this hook
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `npm --prefix website test && npm --prefix admin test && npm --prefix landingpage test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(analytics): add useTrackingConsent hook`

---

### T2: Create `analyticsTracker` (website, admin, landingpage)

**What**: A tracker per app that validates a custom event's name/params against GA4's limits and fires `gtag('event', ...)` only while consent is granted, swallowing any failure.
**Where**: `website/src/infrastructure/analytics/analyticsTracker.ts`, `admin/src/infrastructure/analytics/analyticsTracker.ts`, `landingpage/src/infrastructure/analytics/analyticsTracker.ts`
**Depends on**: T1
**Reuses**: `useTrackingConsent`'s current choice
**Requirement**: ANLY-04, ANLY-05, ANLY-07, ANLY-08, ANLY-09

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN `analytics_storage` is not `'granted'` WHEN `track(name, params)` is called THEN no `gtag('event', ...)` call is made
- [ ] GIVEN `analytics_storage` is `'granted'` WHEN `track(name, params)` is called with a valid name/params THEN `gtag('event', name, params)` is called
- [ ] GIVEN an event name that fails GA4's naming rule (>40 chars, non-alphanumeric/underscore, or doesn't start with a letter) WHEN `track()` is called THEN the event is rejected (logged, not sent) - never reaches `gtag`
- [ ] GIVEN more than 25 parameters, or a parameter name >40 chars, WHEN `track()` is called THEN the event is rejected the same way
- [ ] GIVEN a parameter value >100 chars WHEN `track()` is called THEN the value is truncated to 100 chars before the `gtag` call, not rejected
- [ ] GIVEN `window.gtag` throws WHEN `track()` is called THEN the exception is swallowed and the caller's flow continues uninterrupted
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `npm --prefix website test && npm --prefix admin test && npm --prefix landingpage test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(analytics): add analyticsTracker`

---

### T3: Create `ConsentBanner` component (website, admin, landingpage)

**What**: A banner component per app, shown only when no consent choice is stored, offering accept/decline, wired to `useTrackingConsent`.
**Where**: `website/src/presentation/components/ConsentBanner.tsx`, `admin/src/presentation/components/ConsentBanner.tsx`, `landingpage/src/presentation/components/ConsentBanner.tsx`
**Depends on**: T1
**Reuses**: `useTrackingConsent`
**Requirement**: ANLY-01, ANLY-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN no stored consent choice WHEN the app renders THEN the banner is shown
- [ ] GIVEN a stored consent choice (either value) WHEN the app renders THEN the banner is NOT shown
- [ ] GIVEN the user clicks "Accept" WHEN clicked THEN `useTrackingConsent().grant()` is called and the banner disappears
- [ ] GIVEN the user clicks "Decline" WHEN clicked THEN `useTrackingConsent().deny()` is called and the banner disappears
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `npm --prefix website test && npm --prefix admin test && npm --prefix landingpage test`

**Tests**: unit
**Gate**: full

**Commit**: `feat(analytics): add ConsentBanner component`

---

### T4: Amend `landing-page-plans/design.md` for Consent Mode v2

**What**: Replace `landing-page-plans/design.md`'s existing "GA script tag is conditionally loaded only after a separate cookie-consent banner is accepted" description with the Consent Mode v2 mechanism (AD-019): the script always loads; the existing cookie-consent banner instead drives `gtag('consent', 'default'/'update', ...)`, matching this feature's `useTrackingConsent`/`analyticsTracker` pattern.
**Where**: `landing-page-plans/design.md`
**Depends on**: None
**Reuses**: none - a targeted text amendment to another feature's file, per the Risk flagged in `analytics-tracking/design.md`
**Requirement**: none (AD-019 documentation consistency)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] The "conditionally loaded" language is replaced with a description matching Consent Mode v2's `default`/`update` mechanism
- [ ] The doc references AD-019 by ID
- [ ] `grep -qi 'consent mode' landing-page-plans/design.md` succeeds
- [ ] No other content in `landing-page-plans/design.md` is changed beyond this section (surgical edit, per the Scope Guardrail)

**Tests**: none
**Gate**: build

**Commit**: `docs(landing-page-plans): amend GA mechanism to Consent Mode v2 (AD-019)`

---

### T5: Create `ConsentStore` (commonMain expect + Android actual)

**What**: KMP `expect class ConsentStore` with `getChoice()`/`setChoice()`, and its Android `actual` backed by `SharedPreferences`.
**Where**: `mobile/shared/src/commonMain/kotlin/.../infrastructure/analytics/ConsentStore.kt`, `mobile/shared/src/androidMain/kotlin/.../ConsentStore.android.kt`
**Depends on**: None
**Reuses**: none
**Requirement**: ANLY-10, ANLY-11

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN no prior choice WHEN `getChoice()` is called THEN it returns `unset`
- [ ] GIVEN `setChoice(granted)` was called WHEN `getChoice()` is called afterward (including after process restart, on Android via `SharedPreferences` persistence) THEN it returns `granted`
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `./gradlew :shared:test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(analytics): add KMP ConsentStore (commonMain + Android)`

---

### T6: Create iOS `actual` `ConsentStore`

**What**: The iOS `actual` implementation of `ConsentStore` from T5, backed by `NSUserDefaults`.
**Where**: `mobile/shared/src/iosMain/kotlin/.../ConsentStore.ios.kt`
**Depends on**: T5
**Reuses**: `ConsentStore`'s `expect` contract from T5
**Requirement**: ANLY-10, ANLY-11

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN `setChoice(granted)` was called WHEN `getChoice()` is called afterward THEN it returns `granted`, persisted via `NSUserDefaults`
- [ ] Unit tests written per the Test Coverage Matrix (the shared `commonTest` suite exercises both platform actuals), GIVEN/WHEN/THEN named
- [ ] Gate check passes: `./gradlew :shared:test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(analytics): add KMP iOS actual ConsentStore`

---

### T7: Create `AnalyticsTracker` (commonMain expect + Android actual)

**What**: KMP `expect class AnalyticsTracker` wrapping Firebase Analytics' `setAnalyticsCollectionEnabled`/`logEvent`, applying GA4 naming/size limits, checking `ConsentStore` before every `track()`, and logging every sent event through `dev-logging`'s `Logger.event(...)` in debug builds. Android `actual` uses `com.google.firebase.analytics.FirebaseAnalytics`.
**Where**: `mobile/shared/src/commonMain/kotlin/.../infrastructure/analytics/AnalyticsTracker.kt`, `mobile/shared/src/androidMain/kotlin/.../AnalyticsTracker.android.kt`
**Depends on**: T5
**Reuses**: `ConsentStore` (T5), `dev-logging`'s `Logger.event` (LOG-11, AD-017) - DEFERRED if `dev-logging` hasn't executed yet, per this file's Prerequisite note 2
**Requirement**: ANLY-12, ANLY-13, ANLY-14, ANLY-15, ANLY-16

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN `ConsentStore.getChoice()` is not `granted` WHEN `track(name, params)` is called THEN `setAnalyticsCollectionEnabled(false)` state holds and no `logEvent` call is made
- [ ] GIVEN `ConsentStore.getChoice()` is `granted` WHEN `track(name, params)` is called with a valid name/params THEN `setAnalyticsCollectionEnabled(true)` and `logEvent(name, params)` are called
- [ ] GIVEN an event name/param set exceeding GA4's limits (same rules as T2) WHEN `track()` is called THEN it is rejected/truncated the same way as the web `analyticsTracker`
- [ ] GIVEN a debug build WHEN `track()` sends an event THEN `Logger.event("Analytics", name, params)` is called with the identical name/params - DEFERRED (no runnable `dev-logging` `Logger` yet; write the call site and its unit test against a test double/interface, per this file's Prerequisite note 2)
- [ ] GIVEN the Firebase SDK throws WHEN `track()` is called THEN the exception is swallowed and the caller's flow continues uninterrupted
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `./gradlew :shared:test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(analytics): add KMP AnalyticsTracker (commonMain + Android)`

---

### T8: Create iOS `actual` `AnalyticsTracker`

**What**: The iOS `actual` implementation of `AnalyticsTracker` from T7, using the Firebase iOS SDK via cinterop.
**Where**: `mobile/shared/src/iosMain/kotlin/.../AnalyticsTracker.ios.kt`
**Depends on**: T7
**Reuses**: `AnalyticsTracker`'s `expect` contract from T7
**Requirement**: ANLY-12, ANLY-13, ANLY-14

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Same criteria as T7's Done-when, verified against the iOS actual (via the shared `commonTest` suite)
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `./gradlew :shared:test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(analytics): add KMP iOS actual AnalyticsTracker`

---

### T9: Create `TrackingConsentPrompt` (Android Compose + iOS SwiftUI)

**What**: A one-time in-app prompt shown only when `ConsentStore.getChoice()` is `unset`, calling `ConsentStore.setChoice(...)` and `AnalyticsTracker.setCollectionEnabled(...)` on the user's choice.
**Where**: `mobile/androidApp/.../TrackingConsentPrompt.kt`, `mobile/iosApp/.../TrackingConsentPrompt.swift`
**Depends on**: T5, T7
**Reuses**: `ConsentStore`, `AnalyticsTracker`
**Requirement**: ANLY-10

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN `ConsentStore.getChoice()` is `unset` WHEN the app's entry screen renders THEN the prompt is shown
- [ ] GIVEN `ConsentStore.getChoice()` is already `granted` or `denied` WHEN the app's entry screen renders THEN the prompt is NOT shown
- [ ] GIVEN the user grants consent WHEN chosen THEN `ConsentStore.setChoice(granted)` and `AnalyticsTracker.setCollectionEnabled(true)` are both called
- [ ] GIVEN the user denies consent WHEN chosen THEN `ConsentStore.setChoice(denied)` and `AnalyticsTracker.setCollectionEnabled(false)` are both called
- [ ] UI tests written per the Test Coverage Matrix (Compose UI test on Android, XCTest on iOS)
- [ ] Gate check passes: `./gradlew :androidApp:connectedDebugAndroidTest && xcodebuild test` - DEFERRED (no Android emulator/iOS simulator harness wired up yet; write the tests, note the run as DEFERRED per this file's Prerequisite note 1)

**Tests**: ui
**Gate**: full

**Commit**: `feat(analytics): add TrackingConsentPrompt (Android + iOS)`

---

### T10: Update `docs/{web-app,admin-panel,landing-page-plans}/architecture.md`

**What**: Add an "Analytics tracking" subsection to each of the three web feature docs: the Consent Mode v2 flow, the taxonomy of events that app fires, and a pointer to `analytics-tracking/design.md`.
**Where**: `docs/web-app/architecture.md`, `docs/admin-panel/architecture.md`, `docs/landing-page-plans/architecture.md`
**Depends on**: T2, T3
**Reuses**: existing doc structure from each platform feature's own Execute pass (or created fresh here if that pass hasn't happened yet, matching `dev-logging`'s T13 precedent)
**Requirement**: none (AD-014 documentation convention)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Each of the three files has an "Analytics tracking" section naming its app's specific events and the consent flow
- [ ] `grep -qi 'analytics' docs/web-app/architecture.md` (repeated per file) succeeds for all three

**Tests**: none
**Gate**: build

**Commit**: `docs(analytics): add analytics-tracking sections to web feature docs`

---

### T11: Update `docs/mobile/architecture.md`

**What**: Add an "Analytics tracking" subsection describing `ConsentStore`, `AnalyticsTracker`, `TrackingConsentPrompt`, and the debug-visibility reuse of `dev-logging`'s `Logger`.
**Where**: `docs/mobile/architecture.md`
**Depends on**: T9
**Reuses**: existing doc structure (or created fresh here, same as T10)
**Requirement**: none (AD-014 documentation convention)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] The file has an "Analytics tracking" section covering the three mobile components and the `dev-logging` reuse
- [ ] `grep -qi 'analytics' docs/mobile/architecture.md` succeeds

**Tests**: none
**Gate**: build

**Commit**: `docs(analytics): add analytics-tracking section to mobile docs`

---

## Phase Execution Map

Visual representation of task ordering. Phases run in sequence, and tasks within a phase run in order:

```
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4

Phase 1:  T1 ------> T2
Phase 1:  T1 ------> T3
Phase 2:  T4
Phase 3:  T5 ------> T6
Phase 3:  T5 ------> T7
Phase 3:  T7 ------> T8
Phase 3:  T5 ------> T9
Phase 3:  T7 ------> T9
Phase 4:  T2 ------> T10
Phase 4:  T3 ------> T10
Phase 4:  T9 ------> T11
```

Execution is strictly sequential - there is no intra-phase parallelism. A single agent (or batch worker) works one task at a time, in order.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1: Create useTrackingConsent hook (website, admin, landingpage) | 3 files (cohesive - same hook, one per app) | ✅ Granular |
| T2: Create analyticsTracker (website, admin, landingpage) | 3 files (cohesive - same tracker, one per app) | ✅ Granular |
| T3: Create ConsentBanner component (website, admin, landingpage) | 3 files (cohesive - same component, one per app) | ✅ Granular |
| T4: Amend landing-page-plans/design.md for Consent Mode v2 | 1 file | ✅ Granular |
| T5: Create ConsentStore (commonMain expect + Android actual) | 2 files (cohesive - expect + one actual) | ✅ Granular |
| T6: Create iOS actual ConsentStore | 1 file | ✅ Granular |
| T7: Create AnalyticsTracker (commonMain expect + Android actual) | 2 files (cohesive - expect + one actual) | ✅ Granular |
| T8: Create iOS actual AnalyticsTracker | 1 file | ✅ Granular |
| T9: Create TrackingConsentPrompt (Android Compose + iOS SwiftUI) | 2 files (cohesive - one screen, two platforms) | ✅ Granular |
| T10: Update docs/{web-app,admin-panel,landing-page-plans}/architecture.md | 3 files (cohesive - one doc pass) | ✅ Granular |
| T11: Update docs/mobile/architecture.md | 1 file | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ----------------------- | -------------- | ------ |
| T1 | None | None | ✅ Match |
| T2 | T1 | T1 | ✅ Match |
| T3 | T1 | T1 | ✅ Match |
| T4 | None | None | ✅ Match |
| T5 | None | None | ✅ Match |
| T6 | T5 | T5 | ✅ Match |
| T7 | T5 | T5 | ✅ Match |
| T8 | T7 | T7 | ✅ Match |
| T9 | T5, T7 | T5, T7 | ✅ Match |
| T10 | T2, T3 | T2, T3 | ✅ Match |
| T11 | T9 | T9 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | ---------------------------- | ---------------- | ---------- | ------ |
| T1: useTrackingConsent | Web Infrastructure (hook) | unit | unit | ✅ OK |
| T2: analyticsTracker | Web Infrastructure (tracker) | unit | unit | ✅ OK |
| T3: ConsentBanner | Web Presentation | unit | unit | ✅ OK |
| T4: landing-page-plans/design.md amendment | Developer documentation (design doc, not code) | none | none | ✅ OK |
| T5/T6: ConsentStore (commonMain/Android/iOS) | Mobile Infrastructure | unit | unit | ✅ OK |
| T7/T8: AnalyticsTracker (commonMain/Android/iOS) | Mobile Infrastructure | unit | unit | ✅ OK |
| T9: TrackingConsentPrompt | Mobile Presentation | ui | ui | ✅ OK |
| T10/T11: docs | Developer documentation | none | none | ✅ OK |

---

## Tools & Skills for Execution

**Available MCPs for these tasks**: NONE (filesystem edits + Bash for `npm test`/`./gradlew test`/`xcodebuild test`)

**Available Skills for these tasks**: NONE
