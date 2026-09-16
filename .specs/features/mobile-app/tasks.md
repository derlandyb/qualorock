# Mobile App (Consumer, iOS + Android) Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Design**: `.specs/features/mobile-app/design.md`  
**Status**: Draft

---

## Coding Conventions (MANDATORY)

Per AD-012 (Clean Architecture), AD-013 (code quality), AD-015 (test tags), and AD-016 (application ID), every task in this file follows these rules without restating them per task:

- **4 layers in the KMP shared module**: `domain/{entities,repositories}` (plain Kotlin, repository *interfaces*, no Ktor dependency) ← `application/{usecases,AuthManager}` (orchestrates Domain via its contracts - native screens call these, never repositories or the Ktor client directly) → `data/{network,repositoryimpl}` (Ktor client + concrete repository implementations). Native iOS (`mobile/iosApp/Views/`) and Android (`mobile/androidApp/.../ui/`) are Presentation-only.
- **No magic numbers/strings**: the 60-second polling interval, the default 10km search radius, and every status/enum string are named constants in `shared/src/commonMain/kotlin/domain/constants/MobileConstants.kt`.
- **One class per file**, Kotlin and Swift alike.
- **No task/ticket-referencing comments in code** (AD-014) - rationale lives in `design.md` and `docs/mobile/architecture.md`.
- **Test tags** (AD-015): Android screens use `R.string.*` values from `strings-test.xml` with `Modifier.testTag(...)`; iOS views use constants from `TestTags.swift` with `.accessibilityIdentifier(...)` - never an inline string literal at the call site, see the dedicated scaffolding task below.
- **Application ID** (AD-016): `br.com.qualorock` on both platforms, set once - never duplicated as a literal elsewhere.

---

## Test Coverage Matrix

> Guidelines found: .specs/STATE.md AD-010 (kotlin.test for shared KMP module, XCTest for iOS, Compose UI tests for Android, GIVEN/WHEN/THEN names, >=80% coverage on the shared module). No backend tasks here - mobile-app reuses web-app's User/Favorite/Friendship/EventInterest/Notification schema and AuthController 1:1 (see web-app/tasks.md); this file is client-only (KMP shared module + native iOS/Android screens). Visual verification for native screens cannot use Playwright/getComputedStyle (those apply to admin-panel/web-app's web pages only) - it uses each platform's own screenshot-testing tool (XCTest snapshot on iOS, Compose UI test screenshot on Android) compared against the same Stitch mobile screenshots used as reference.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------- | --------------------- | ----------------- | ----------- |
| KMP shared module (repository/service) | unit | All branches; 1:1 to spec ACs; every listed edge case (kotlin.test) | mobile/shared/src/commonTest/kotlin/**/*Test.kt | ./gradlew :shared:allTests |
| iOS SwiftUI screen | e2e | Every screen: rendering + interaction states (XCTest) | mobile/iosApp/Tests/**/*Tests.swift | xcodebuild test -scheme iosApp |
| Android Compose screen | e2e | Every screen: rendering + interaction states (Compose UI tests) | mobile/androidApp/src/androidTest/kotlin/**/*Test.kt | ./gradlew :androidApp:connectedAndroidTest |
| Screen / UI layout (visual) | visual | Every screen matched to its Stitch mobile-device reference (layout + verified color/typography tokens + element presence), checked per-platform via that platform's own screenshot-testing tool | mobile/iosApp/Tests/Snapshots/**, mobile/androidApp/src/androidTest/.../screenshots/** | xcodebuild test -scheme iosApp -only-testing:SnapshotTests && ./gradlew :androidApp:connectedAndroidTest --tests '*Screenshot*' |
| Developer documentation | none | - (build gate only): documents the Clean Architecture layering, test-tag convention, and application ID for this feature | docs/mobile/*.md | test -f docs/mobile/architecture.md |

## Gate Check Commands

> Generated from AD-010 - confirm before Execute once the KMP shared module and iOS/Android app scaffolding exist (mobile-app runs on the host per infrastructure/tasks.md, not in Docker).

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After shared-module tasks with unit tests only | ./gradlew :shared:allTests |
| Full | After tasks with platform UI/e2e/visual tests (screens) | ./gradlew :shared:allTests && xcodebuild test -scheme iosApp && ./gradlew :androidApp:connectedAndroidTest |
| Build | After phase completion | ./gradlew build && xcodebuild build -scheme iosApp |

---

## Execution Plan

Phases are ordered and run sequentially - each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Shared KMP module

One implementation shared by both native UIs - repositories, auth, real-time.

```
T1 -> T5
```

### Phase 2: Screen: Auth (login, signup, validation, password recovery)

Reference: Stitch mobile screens 'Entrar' (`.../screens/4432113bda884182a3f8170f2db3ff66`), 'Cadastro de Novo Usuário' (`.../screens/45b113c871c54658935474dbd7d0e895`), 'Validação de Conta' (`.../screens/ce227916941b4f12afc28981d7e67437`), 'Recuperação de Senha' (`.../screens/2c91e0f051ea4d91b0651d80aee00f3b`).

```
T2 -> T6
T6 -> T7
```

### Phase 3: Screen: Event listing, details, and embedded map

Reference: Stitch mobile screens 'Listagem de Eventos' (`.../screens/7b50f87c23af45348be0d119bafa8e09`) and 'Detalhes do Evento' (`.../screens/4156785173254673b0b822f12a9734fd`). Note: design.md labels the embedded-map component '(MOBILE-12)', but spec.md's Requirement Traceability table places MOBILE-12 under the Auth story ('password recovery') instead - a design-doc inconsistency. This task tags the map under the discovery/listing IDs its actual behavior belongs to (MOBILE-01..09), not design.md's mislabeled tag.

```
T1 -> T8
T5 -> T8
T8 -> T9
```

### Phase 4: Screen: Profile, favorites, privacy link, and LGPD deep-link

Reference: Stitch mobile screens 'Perfil do Usuário' (`.../screens/38aa89ec2ad9482ba6bf391dfdee836e`) and 'Eventos Favoritados' (`.../screens/04b726b51e494157bd2e7daf7ce8a37d`).

```
T3 -> T10
T10 -> T11
```

### Phase 5: Screen: Social feed

Reference: Stitch mobile screen 'Feed Social e Conexões de Amigos' (`.../screens/302baa3df5134290b4ed4e7e609707b9`).

```
T3 -> T12
T12 -> T13
```

### Phase 6: Screen: Notifications

Reference: Stitch mobile screen 'Notificações' (`.../screens/3268d4f7227445a1b6a237781fe3316d`).

```
T4 -> T14
T14 -> T15
```

### Phase 7: Cross-cutting accessibility pass

MOBILE-21's remaining scope beyond what individual screens already cover: platform-native accessibility APIs.

```
T6 -> T16
T8 -> T16
T10 -> T16
T12 -> T16
T14 -> T16
```

### Phase 8: Clean Architecture scaffolding: constants, test tags, app ID, docs (AD-012..AD-016)

Concrete artifacts for the new architecture decisions - not just the convention statement above.

```
T1 -> T17
T5 -> T17
T17 -> T21
T18 -> T21
T19 -> T21
T20 -> T21
```

---

## Task Breakdown

### T1: EventRepository (KMP)

**What**: `listEvents(page)`, `getEventDetails(id)`, and `subscribeToEventUpdates(): Flow<EventUpdate>` against the same API contracts web-app's ConsumerEventController exposes (see web-app/tasks.md T11).
**Where**: `mobile/shared/src/commonMain/kotlin/domain/repositories/EventRepository.kt, mobile/shared/src/commonMain/kotlin/application/usecases/{ListEventsUseCase,GetEventDetailsUseCase}.kt, mobile/shared/src/commonMain/kotlin/data/repositoryimpl/EventRepositoryImpl.kt, mobile/shared/src/commonMain/kotlin/data/network/EventApiClient.kt`
**Depends on**: None
**Reuses**: web-app's ConsumerEventController API contract (web-app/tasks.md T11) - same backend, no mobile-specific endpoint
**Requirement**: MOBILE-01, MOBILE-03, MOBILE-04, MOBILE-08

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a page of events WHEN fetched THEN they are ordered by date and ranked by the user's radius, matching the same contract as web-app - test passes
- [ ] GIVEN pagination parameters THEN the correct page is returned - test passes
- [ ] Gate check passes: `./gradlew :shared:allTests --tests EventRepositoryTest`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(mobile-app): add EventRepository (KMP)`

---

### T2: AuthManager (KMP)

**What**: `login()` (OAuth + email/password with generic invalid-credentials error), `signup(consentGiven, ...)` (rejects if consent missing, routes to validation), `logout()`, and Sanctum token persistence via `expect`/`actual` Keychain (iOS) / Keystore (Android) - never plaintext UserDefaults/SharedPreferences.
**Where**: `mobile/shared/src/commonMain/kotlin/application/AuthManager.kt, mobile/shared/src/commonMain/kotlin/domain/repositories/AuthRepository.kt, mobile/shared/src/commonMain/kotlin/data/repositoryimpl/AuthRepositoryImpl.kt`
**Depends on**: None
**Requirement**: MOBILE-10, MOBILE-11, MOBILE-12, MOBILE-13, MOBILE-22

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN valid OAuth or email/password credentials THEN login succeeds and a token is stored via the secure-storage backend - test passes
- [ ] GIVEN invalid email/password THEN a single generic invalid-credentials error is returned - test passes
- [ ] GIVEN signup without `consentGiven=true` THEN the call fails before any account-creation request is sent - test passes
- [ ] GIVEN an unvalidated account THEN `AuthManager` exposes its restricted state so screens can gate event/social features - test passes
- [ ] GIVEN a stored token on app restart THEN the session resumes without re-login until explicit logout or expiry - test passes
- [ ] Gate check passes: `./gradlew :shared:allTests --tests AuthManagerTest`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(mobile-app): add AuthManager (KMP) with secure token storage`

---

### T3: FavoriteRepository + SocialRepository (KMP)

**What**: Favorites CRUD, profile/preferences read-write, friends list/suggestions, 'friends interested' surfacing, activity feed - mirroring web-app's ProfileController/SocialController contracts (web-app/tasks.md T13/T14).
**Where**: `mobile/shared/src/commonMain/kotlin/domain/repositories/{Favorite,Social}Repository.kt, mobile/shared/src/commonMain/kotlin/application/usecases/{ToggleFavoriteUseCase,GetSocialFeedUseCase}.kt, mobile/shared/src/commonMain/kotlin/data/repositoryimpl/{FavoriteRepositoryImpl,SocialRepositoryImpl}.kt`
**Depends on**: None
**Reuses**: web-app's ProfileController and SocialController API contracts (web-app/tasks.md T13, T14)
**Requirement**: MOBILE-14, MOBILE-15, MOBILE-16, MOBILE-17, MOBILE-18

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a favorite toggle THEN the repository calls the same favorites endpoint web-app uses and reflects the updated state - test passes
- [ ] GIVEN accepted friendships THEN the friends list resolves both directions correctly - test passes
- [ ] GIVEN a friend interested in an event THEN it surfaces via the same contract web-app's SocialController returns - test passes
- [ ] Gate check passes: `./gradlew :shared:allTests --tests FavoriteRepositoryTest,SocialRepositoryTest`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(mobile-app): add FavoriteRepository and SocialRepository (KMP)`

---

### T4: NotificationRepository (KMP)

**What**: Category-filtered list, per-item mute, clear-all-with-undo, push-scope toggle - mirroring web-app's NotificationController contract (web-app/tasks.md T15).
**Where**: `mobile/shared/src/commonMain/kotlin/domain/repositories/NotificationRepository.kt, mobile/shared/src/commonMain/kotlin/application/usecases/{ListNotificationsUseCase,ClearAllNotificationsUseCase}.kt, mobile/shared/src/commonMain/kotlin/data/repositoryimpl/NotificationRepositoryImpl.kt`
**Depends on**: None
**Reuses**: web-app's NotificationController API contract (web-app/tasks.md T15)
**Requirement**: MOBILE-19, MOBILE-20

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a category filter THEN only matching notifications are returned - test passes
- [ ] GIVEN a clear-all call THEN the repository exposes an undo window before the soft-delete is finalized - test passes
- [ ] Gate check passes: `./gradlew :shared:allTests --tests NotificationRepositoryTest`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(mobile-app): add NotificationRepository (KMP)`

---

### T5: Reverb WS subscription with 60s polling fallback

**What**: Wire `EventRepository.subscribeToEventUpdates()` to the same Reverb `events` channel web-app uses, falling back to a 60-second poll if the WebSocket connection drops, per design.md's Risks table and Tech Decision.
**Where**: `mobile/shared/src/commonMain/kotlin/data/network/EventApiClient.kt, mobile/shared/src/commonMain/kotlin/application/usecases/SubscribeToEventUpdatesUseCase.kt`
**Depends on**: T1
**Requirement**: MOBILE-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN an active WS connection WHEN an event is published/updated THEN the flow emits the update - test passes
- [ ] GIVEN the WS connection drops THEN a 60-second poll timer takes over and still surfaces updates within 60 seconds - test passes
- [ ] Gate check passes: `./gradlew :shared:allTests --tests EventRepositoryRealtimeTest`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(mobile-app): add Reverb subscription with polling fallback`

---

### T6: Build native auth screens (SwiftUI + Compose)

**What**: Login/signup/validation/password-recovery screens on both platforms, backed by T2's AuthManager.
**Where**: `mobile/iosApp/Views/Auth/, mobile/androidApp/src/main/kotlin/ui/auth/`
**Depends on**: T2
**Requirement**: MOBILE-10, MOBILE-11, MOBILE-12, MOBILE-13, MOBILE-22

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Matches the verified 'Qual o Rock?' design-system tokens (dark surfaces `#131315`/`#1c1c20`, primary pill button `#ff7a3d`, form inputs `#17171a` bg with `#48423c` outline-variant border, `0.5rem` radius) translated to each platform's native styling APIs
- [ ] Consent checkbox on signup is unchecked by default and required before the create-account action is enabled
- [ ] Unvalidated accounts are routed to and locked within the validation screen (no event/social tab reachable)
- [ ] OAuth buttons render as the Secondary/outlined button treatment, distinct from the primary email/password submit

**Tests**: visual
**Gate**: quick

**Commit**: `feat(mobile-app): add native auth screens (iOS + Android)`

---

### T7: Verify Screen: Auth flow against Stitch mobile reference

**What**: Run each platform's own screenshot test (XCTest snapshot on iOS, Compose UI test screenshot on Android) for the four auth screens and compare against the downloaded Stitch mobile reference screenshots for layout and the verified tokens.
**Where**: `mobile/iosApp/Tests/Snapshots/AuthSnapshotTests.swift, mobile/androidApp/src/androidTest/kotlin/ui/auth/AuthScreenshotTest.kt`
**Depends on**: T6
**Requirement**: MOBILE-10, MOBILE-11, MOBILE-12, MOBILE-13, MOBILE-22

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] iOS snapshot tests pass against the reference layout/tokens
- [ ] Android screenshot tests pass against the same reference layout/tokens
- [ ] Any mismatch on either platform is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(mobile-app): verify auth screens against Stitch mobile reference`

---

### T8: Build native event listing/details screens + embedded map (SwiftUI + Compose)

**What**: Discovery-to-ticket loop screens on both platforms, backed by T1/T5, with an embedded (not standalone) Google Maps view inside the details screen per the spec's Assumptions.
**Where**: `mobile/iosApp/Views/Event/, mobile/androidApp/src/main/kotlin/ui/event/`
**Depends on**: T1, T5
**Requirement**: MOBILE-01, MOBILE-02, MOBILE-03, MOBILE-04, MOBILE-05, MOBILE-06, MOBILE-07, MOBILE-08, MOBILE-09

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Event card matches the verified design-system Card spec (1rem-equivalent radius, dark surface, image banner with scrim, location badge, favorite icon, price + CTA footer)
- [ ] Map is embedded inside the details screen (not a separate navigable screen), consuming the same cached lat/lng as web-app
- [ ] Ticket-link action hands off to the device's default browser/external app, per MOBILE-07
- [ ] GIVEN a network failure during listing fetch THEN the last cached listing renders with a stale-data indicator (per design.md's Error Handling table) rather than a blank screen

**Tests**: visual
**Gate**: quick

**Commit**: `feat(mobile-app): add native event listing, details, and embedded map screens`

---

### T9: Verify Screen: Event listing/details against Stitch mobile reference

**What**: Platform screenshot tests for the listing and details screens against the downloaded Stitch mobile reference screenshots.
**Where**: `mobile/iosApp/Tests/Snapshots/EventSnapshotTests.swift, mobile/androidApp/src/androidTest/kotlin/ui/event/EventScreenshotTest.kt`
**Depends on**: T8
**Requirement**: MOBILE-01, MOBILE-02, MOBILE-03, MOBILE-04, MOBILE-05, MOBILE-06, MOBILE-07, MOBILE-08, MOBILE-09

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] iOS and Android snapshot/screenshot tests both pass against the reference layout/tokens
- [ ] Any mismatch on either platform is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(mobile-app): verify event listing/details screens against Stitch mobile reference`

---

### T10: Build native profile/favorites screens + privacy link + LGPD deep-link (SwiftUI + Compose)

**What**: Profile edit, preferences, favorites list, a privacy-policy link, and a data-export/deletion entry that deep-links to web-app's flow in an in-app browser/Custom Tab rather than reimplementing it natively, per design.md's Code Reuse Analysis.
**Where**: `mobile/iosApp/Views/Profile/, mobile/androidApp/src/main/kotlin/ui/profile/`
**Depends on**: T3
**Requirement**: MOBILE-14, MOBILE-15, MOBILE-16, MOBILE-23, MOBILE-24

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Matches the verified design-system tokens for cards/forms/buttons
- [ ] 'Export my data' / 'Delete my account' actions open web-app's data-rights URL in an in-app browser (SFSafariViewController / Custom Tabs), not a native reimplementation
- [ ] Privacy-policy link is visible on the profile screen without requiring a sub-menu tap

**Tests**: visual
**Gate**: quick

**Commit**: `feat(mobile-app): add native profile/favorites screens with LGPD deep-link`

---

### T11: Verify Screen: Profile/favorites against Stitch mobile reference

**What**: Platform screenshot tests for the profile and favorites screens against the downloaded Stitch mobile reference screenshots; additionally confirm the LGPD deep-link actually opens the correct web-app URL (not a broken/placeholder link).
**Where**: `mobile/iosApp/Tests/Snapshots/ProfileSnapshotTests.swift, mobile/androidApp/src/androidTest/kotlin/ui/profile/ProfileScreenshotTest.kt`
**Depends on**: T10
**Requirement**: MOBILE-14, MOBILE-15, MOBILE-16, MOBILE-23, MOBILE-24

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] iOS and Android snapshot/screenshot tests both pass against the reference layout/tokens
- [ ] The deep-link target URL is asserted to match web-app's data-rights route exactly
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(mobile-app): verify profile/favorites screens and LGPD deep-link`

---

### T12: Build native social feed screens (SwiftUI + Compose)

**What**: Friends list, suggestions, activity feed, and sharing, backed by T3's SocialRepository.
**Where**: `mobile/iosApp/Views/Social/, mobile/androidApp/src/main/kotlin/ui/social/`
**Depends on**: T3
**Requirement**: MOBILE-17, MOBILE-18

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Matches the verified design-system tokens for list rows and avatars (circular-element convention)
- [ ] Share action uses the native platform share sheet (UIActivityViewController / Android Sharesheet), not a custom in-app share UI

**Tests**: visual
**Gate**: quick

**Commit**: `feat(mobile-app): add native social feed screens`

---

### T13: Verify Screen: Social feed against Stitch mobile reference

**What**: Platform screenshot tests for the social feed screen against the downloaded Stitch mobile reference screenshot.
**Where**: `mobile/iosApp/Tests/Snapshots/SocialSnapshotTests.swift, mobile/androidApp/src/androidTest/kotlin/ui/social/SocialScreenshotTest.kt`
**Depends on**: T12
**Requirement**: MOBILE-17, MOBILE-18

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] iOS and Android snapshot/screenshot tests both pass against the reference layout/tokens
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(mobile-app): verify social feed screen against Stitch mobile reference`

---

### T14: Build native notifications screens (SwiftUI + Compose)

**What**: Category filter tabs, per-item mute, clear-all-with-undo, and a push-scope toggle exposed as a native OS notification-permission-aware setting, backed by T4's NotificationRepository.
**Where**: `mobile/iosApp/Views/Notifications/, mobile/androidApp/src/main/kotlin/ui/notifications/`
**Depends on**: T4
**Requirement**: MOBILE-19, MOBILE-20

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Matches the verified design-system tokens for list/card/chip styling
- [ ] Clear-all shows a native undo affordance (e.g. a Snackbar on Android, a toast/banner on iOS) within the client-side undo window before finalizing the soft-delete
- [ ] Push-scope toggle respects the OS-level notification permission state (doesn't claim 'on' if OS permission was denied)

**Tests**: visual
**Gate**: quick

**Commit**: `feat(mobile-app): add native notifications screens`

---

### T15: Verify Screen: Notifications against Stitch mobile reference

**What**: Platform screenshot tests for the notifications screen against the downloaded Stitch mobile reference screenshot.
**Where**: `mobile/iosApp/Tests/Snapshots/NotificationsSnapshotTests.swift, mobile/androidApp/src/androidTest/kotlin/ui/notifications/NotificationsScreenshotTest.kt`
**Depends on**: T14
**Requirement**: MOBILE-19, MOBILE-20

**Tools**:

- MCP: Stitch MCP
- Skill: NONE

**Done when**:

- [ ] iOS and Android snapshot/screenshot tests both pass against the reference layout/tokens
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(mobile-app): verify notifications screen against Stitch mobile reference`

---

### T16: App-wide accessibility audit and fixes (iOS + Android)

**What**: Run each platform's own accessibility audit (Xcode Accessibility Inspector / iOS XCUITest accessibility checks; Android's Accessibility Scanner / Espresso accessibility checks) across every screen built in this feature and fix violations (VoiceOver/TalkBack labels, contrast, dynamic type/font-scaling, dark-mode-first default).
**Where**: `mobile/iosApp/Views/**, mobile/androidApp/src/main/kotlin/ui/**`
**Depends on**: T6, T8, T10, T12, T14
**Requirement**: MOBILE-21

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN an automated accessibility audit on each platform THEN zero critical violations remain - test passes
- [ ] Dark mode renders as the default on first launch (no unstyled light-mode flash)
- [ ] Every interactive element has a VoiceOver/TalkBack label
- [ ] Gate check passes on both platforms: `xcodebuild test -scheme iosApp -only-testing:AccessibilityTests` and `./gradlew :androidApp:connectedAndroidTest --tests '*Accessibility*'`

**Tests**: e2e
**Gate**: full

**Commit**: `fix(mobile-app): resolve app-wide accessibility audit findings (iOS + Android)`

---

### T17: MobileConstants (KMP shared, no magic numbers/strings)

**What**: Named constants replacing magic literals used across this feature's tasks: the 60-second real-time polling interval, the default 10km search radius, and every status/enum string mirrored from web-app.
**Where**: `mobile/shared/src/commonMain/kotlin/domain/constants/MobileConstants.kt`
**Depends on**: T1, T5
**Requirement**: AD-013 (code quality)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] The 60s polling interval and 10km default radius are defined exactly once
- [ ] T5 (Reverb+polling) and T1 (EventRepository) reference this constant instead of a bare `60`/`10`

**Tests**: unit
**Gate**: quick

**Commit**: `refactor(mobile-app): extract named constants for polling interval and default radius`

---

### T18: Android strings-test.xml scaffolding (AD-015)

**What**: One `strings-test.xml` resource file declaring a named `R.string` entry for every Compose `testTag` this feature's screens need (auth, event listing/details, profile/favorites, social feed, notifications) - screens reference these resources, never an inline string literal, when calling `Modifier.testTag(...)`.
**Where**: `mobile/androidApp/src/main/res/values/strings-test.xml`
**Depends on**: None
**Requirement**: AD-015

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Every Compose screen task in this file (T6, T8, T10, T12, T14) references a `R.string.*` value from this file for its `testTag()` calls, not an inline literal
- [ ] No `testTag("...")` inline string literal exists anywhere in `mobile/androidApp/src/main/kotlin/ui/`

**Tests**: none
**Gate**: build

**Commit**: `chore(mobile-app): add strings-test.xml for Compose test tags`

---

### T19: iOS TestTags.swift scaffolding (AD-015)

**What**: One `TestTags.swift` file declaring a named constant for every accessibility identifier this feature's screens need, mirroring T18's Android resource file - screens reference these constants, never an inline string literal, when calling `.accessibilityIdentifier(...)`.
**Where**: `mobile/iosApp/Support/TestTags.swift`
**Depends on**: None
**Requirement**: AD-015

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Every SwiftUI screen task in this file (T6, T8, T10, T12, T14) references a constant from this file for its `.accessibilityIdentifier(...)` calls, not an inline literal
- [ ] No inline string literal is passed to `.accessibilityIdentifier(...)` anywhere in `mobile/iosApp/Views/`

**Tests**: none
**Gate**: build

**Commit**: `chore(mobile-app): add TestTags.swift for accessibility identifiers`

---

### T20: Application ID / bundle identifier configuration (AD-016)

**What**: Set the Android `applicationId` and the iOS bundle identifier to `br.com.qualorock` on both platforms.
**Where**: `mobile/androidApp/build.gradle.kts, mobile/iosApp/iosApp.xcodeproj/project.pbxproj`
**Depends on**: None
**Requirement**: AD-016

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `androidApp/build.gradle.kts` sets `applicationId = "br.com.qualorock"`
- [ ] The iOS Xcode project's `PRODUCT_BUNDLE_IDENTIFIER` is `br.com.qualorock` for every build configuration (Debug/Release)
- [ ] `./gradlew :androidApp:assembleDebug` and `xcodebuild -showBuildSettings -scheme iosApp | grep PRODUCT_BUNDLE_IDENTIFIER` both confirm the value

**Tests**: none
**Gate**: build

**Commit**: `chore(mobile-app): set application ID to br.com.qualorock on both platforms`

---

### T21: docs/mobile/architecture.md

**What**: Markdown write-up of this feature's Clean Architecture layering (AD-012), coding conventions (AD-013), test-tag convention (AD-015), and application ID (AD-016), with a per-layer example drawn from the Event listing flow.
**Where**: `docs/mobile/architecture.md`
**Depends on**: T17, T18, T19, T20
**Requirement**: AD-014 (documentation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Doc explains all 3 KMP-shared layers (domain/application/data) plus native Presentation, with one concrete example path per layer
- [ ] Doc states the no-magic-numbers, one-class-per-file, no-task-comments, test-tag-file, and application-ID rules
- [ ] Doc is committed under `docs/mobile/`, not scattered as code comments

**Tests**: none
**Gate**: build

**Commit**: `docs(mobile-app): add architecture.md documenting Clean Architecture layering`

---

## Phase Execution Map

Visual representation of task ordering. Phases run in sequence, and tasks within a phase run in order:

```
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6 -> Phase 7 -> Phase 8

Phase 1:  T1 ------> T5
Phase 2:  T2 ------> T6
Phase 2:  T6 ------> T7
Phase 3:  T1 ------> T8
Phase 3:  T5 ------> T8
Phase 3:  T8 ------> T9
Phase 4:  T3 ------> T10
Phase 4:  T10 ------> T11
Phase 5:  T3 ------> T12
Phase 5:  T12 ------> T13
Phase 6:  T4 ------> T14
Phase 6:  T14 ------> T15
Phase 7:  T6 ------> T16
Phase 7:  T8 ------> T16
Phase 7:  T10 ------> T16
Phase 7:  T12 ------> T16
Phase 7:  T14 ------> T16
Phase 8:  T1 ------> T17
Phase 8:  T5 ------> T17
Phase 8:  T17 ------> T21
Phase 8:  T18 ------> T21
Phase 8:  T19 ------> T21
Phase 8:  T20 ------> T21
```

Execution is strictly sequential - there is no intra-phase parallelism. A single agent (or batch worker) works one task at a time, in order.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1: EventRepository (KMP) | 1 file | ✅ Granular |
| T2: AuthManager (KMP) | 1 file | ✅ Granular |
| T3: FavoriteRepository + SocialRepository (KMP) | 2 files (cohesive - both are thin API-contract mirrors of web-app's controllers) | ✅ Granular |
| T4: NotificationRepository (KMP) | 1 file | ✅ Granular |
| T5: Reverb WS subscription with 60s polling fallback | 1 file (modifies T1) | ✅ Granular |
| T6: Build native auth screens (SwiftUI + Compose) | 2 directories (cohesive - one auth flow, two native platforms, matching the pattern of every other mobile screen task) | ✅ Granular |
| T7: Verify Screen: Auth flow against Stitch mobile reference | 2 files (one per platform's test framework) | ✅ Granular |
| T8: Build native event listing/details screens + embedded map (SwiftUI + Compose) | 2 directories (cohesive - one discovery flow, two native platforms) | ✅ Granular |
| T9: Verify Screen: Event listing/details against Stitch mobile reference | 2 files | ✅ Granular |
| T10: Build native profile/favorites screens + privacy link + LGPD deep-link (SwiftUI + Compose) | 2 directories (cohesive - one profile flow, two native platforms) | ✅ Granular |
| T11: Verify Screen: Profile/favorites against Stitch mobile reference | 2 files | ✅ Granular |
| T12: Build native social feed screens (SwiftUI + Compose) | 2 directories | ✅ Granular |
| T13: Verify Screen: Social feed against Stitch mobile reference | 2 files | ✅ Granular |
| T14: Build native notifications screens (SwiftUI + Compose) | 2 directories | ✅ Granular |
| T15: Verify Screen: Notifications against Stitch mobile reference | 2 files | ✅ Granular |
| T16: App-wide accessibility audit and fixes (iOS + Android) | cross-cutting (multiple files - audit-and-fix task, not a single new component) | ✅ Granular |
| T17: MobileConstants (KMP shared, no magic numbers/strings) | 1 file | ✅ Granular |
| T18: Android strings-test.xml scaffolding (AD-015) | 1 file | ✅ Granular |
| T19: iOS TestTags.swift scaffolding (AD-015) | 1 file | ✅ Granular |
| T20: Application ID / bundle identifier configuration (AD-016) | 2 files (cohesive - one identity decision, two platform config files) | ✅ Granular |
| T21: docs/mobile/architecture.md | 1 file | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ----------------------- | -------------- | ------ |
| T1 | None | None | ✅ Match |
| T2 | None | None | ✅ Match |
| T3 | None | None | ✅ Match |
| T4 | None | None | ✅ Match |
| T5 | T1 | T1 | ✅ Match |
| T6 | T2 | T2 | ✅ Match |
| T7 | T6 | T6 | ✅ Match |
| T8 | T1, T5 | T1, T5 | ✅ Match |
| T9 | T8 | T8 | ✅ Match |
| T10 | T3 | T3 | ✅ Match |
| T11 | T10 | T10 | ✅ Match |
| T12 | T3 | T3 | ✅ Match |
| T13 | T12 | T12 | ✅ Match |
| T14 | T4 | T4 | ✅ Match |
| T15 | T14 | T14 | ✅ Match |
| T16 | T6, T8, T10, T12, T14 | T6, T8, T10, T12, T14 | ✅ Match |
| T17 | T1, T5 | T1, T5 | ✅ Match |
| T18 | None | None | ✅ Match |
| T19 | None | None | ✅ Match |
| T20 | None | None | ✅ Match |
| T21 | T17, T18, T19, T20 | T17, T18, T19, T20 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | ---------------------------- | ---------------- | ---------- | ------ |
| T1: EventRepository (KMP) | KMP shared module (repository/service) | unit | unit | ✅ OK |
| T2: AuthManager (KMP) | KMP shared module (repository/service) | unit | unit | ✅ OK |
| T3: FavoriteRepository + SocialRepository (KMP) | KMP shared module (repository/service) | unit | unit | ✅ OK |
| T4: NotificationRepository (KMP) | KMP shared module (repository/service) | unit | unit | ✅ OK |
| T5: Reverb WS subscription with 60s polling fallback | KMP shared module (repository/service) | unit | unit | ✅ OK |
| T6: Build native auth screens (SwiftUI + Compose) | iOS SwiftUI screen | visual | visual | ✅ OK |
| T7: Verify Screen: Auth flow against Stitch mobile reference | Screen / UI layout (visual) | visual | visual | ✅ OK |
| T8: Build native event listing/details screens + embedded map (SwiftUI + Compose) | iOS SwiftUI screen | visual | visual | ✅ OK |
| T9: Verify Screen: Event listing/details against Stitch mobile reference | Screen / UI layout (visual) | visual | visual | ✅ OK |
| T10: Build native profile/favorites screens + privacy link + LGPD deep-link (SwiftUI + Compose) | iOS SwiftUI screen | visual | visual | ✅ OK |
| T11: Verify Screen: Profile/favorites against Stitch mobile reference | Screen / UI layout (visual) | visual | visual | ✅ OK |
| T12: Build native social feed screens (SwiftUI + Compose) | iOS SwiftUI screen | visual | visual | ✅ OK |
| T13: Verify Screen: Social feed against Stitch mobile reference | Screen / UI layout (visual) | visual | visual | ✅ OK |
| T14: Build native notifications screens (SwiftUI + Compose) | iOS SwiftUI screen | visual | visual | ✅ OK |
| T15: Verify Screen: Notifications against Stitch mobile reference | Screen / UI layout (visual) | visual | visual | ✅ OK |
| T16: App-wide accessibility audit and fixes (iOS + Android) | iOS SwiftUI screen | e2e | e2e | ✅ OK |
| T17: MobileConstants (KMP shared, no magic numbers/strings) | KMP shared module (repository/service) | unit | unit | ✅ OK |
| T18: Android strings-test.xml scaffolding (AD-015) | iOS SwiftUI screen | none | none | ✅ OK |
| T19: iOS TestTags.swift scaffolding (AD-015) | iOS SwiftUI screen | none | none | ✅ OK |
| T20: Application ID / bundle identifier configuration (AD-016) | iOS SwiftUI screen | none | none | ✅ OK |
| T21: docs/mobile/architecture.md | iOS SwiftUI screen | none | none | ✅ OK |

---

## Tools & Skills for Execution

**Available MCPs for these tasks**: Stitch MCP (`mcp__stitch__get_screen`, screenshot download) for screen tasks and their paired verification tasks, to pull the matching mobile-device reference; NONE for shared-module tasks.

**Available Skills for these tasks**: NONE

