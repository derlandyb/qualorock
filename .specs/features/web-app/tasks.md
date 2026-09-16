# Web App (Consumer, Desktop) Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Design**: `.specs/features/web-app/design.md`  
**Status**: Draft

---

## Coding Conventions (MANDATORY)

Per AD-012 (Clean Architecture) and AD-013 (code quality), every task in this file follows these rules without restating them per task:

- **4 layers, one direction of dependency**: backend follows `Domain` (entities + repository contracts) ← `Application` (use-cases/services, orchestrates via Domain contracts) → `Infrastructure` (Eloquent models + concrete repositories) and `Presentation` (thin controllers). The `website` React SPA mirrors it with `website/src/{domain,application,infrastructure,presentation}`.
- **Every persisted entity gets a `Domain/Contracts/<Entity>RepositoryInterface.php`.** `User` and `Notification` additionally get an explicit `Domain/Entities/<Entity>.php` (the `validated`-gate rule and the notification clear-all/undo rule live there). `Favorite`, `Friendship`, `EventInterest`, `ConsumerDataExportRequest` keep a thin contract with no separate entity class per YAGNI - simple join/status tables, not business-rule holders.
- **No magic numbers/strings**: the default search radius (`10`km) and every `authProvider`/`pushScopeFilter`/notification-`category` string are named constants in `backend/app/Domain/Constants/WebAppConstants.php` and `website/src/domain/constants/webAppConstants.ts` - see the dedicated constants task below.
- **One class per file**, PHP and TypeScript/TSX alike.
- **No task/ticket-referencing comments in code** (AD-014) - rationale lives in `design.md` and `docs/web-app/architecture.md`.
- **Database seeders are excluded from this layering** - they stay at `backend/database/seeders/*.php`, but still avoid magic numbers (reuse the same named constants).

---

## Test Coverage Matrix

> Guidelines found: .specs/STATE.md AD-010/AD-011 (Pest backend, Jest+RTL web, Playwright E2E, GIVEN/WHEN/THEN names, >=80% coverage). A `Screen / UI layout` row is added: this feature's visual reference is the Stitch project `projects/4886677589059011690` ("Qual o rock - novo design") which, on inspection, has real DESKTOP-device screen variants for every flow except Notifications (mobile-only screen exists - matches the spec's own assumption that no dedicated desktop notifications screen exists yet).

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------- | --------------------- | ----------------- | ----------- |
| Eloquent model / migration | none | - (build gate only) | backend/app/Models/*.php, backend/database/migrations/* | php artisan migrate --pretend |
| Controller / route (feature) | integration | All routes in scope: happy path + every listed edge case + error/failure paths, GIVEN/WHEN/THEN named | backend/tests/Feature/Consumer/**/*Test.php | php artisan test --testsuite=Feature |
| React component (page/widget) | unit | All branches; interaction states (loading/error/empty) covered | website/src/**/__tests__/*.test.tsx | npm --prefix website test |
| Screen / UI layout | visual | Every screen matched to its Stitch reference (desktop variant where one exists, mobile variant reflowed for Notifications): layout + verified color/typography tokens + element presence confirmed by Playwright screenshot + getComputedStyle comparison | website/e2e/visual/*.spec.ts | npx --prefix website playwright test e2e/visual |
| E2E flow | e2e | Full flows per design.md Test Plan (favorite-and-sync, export-then-deletion) | website/e2e/*.spec.ts | npx --prefix website playwright test |
| Database seeder (QA fixtures) | none | - (build gate only): idempotent, covers every enumerated status/state combination named in its task | backend/database/seeders/*.php | php artisan db:seed --class=WebAppSeeder |
| Developer documentation | none | - (build gate only): documents the Clean Architecture layering and conventions for this feature | docs/web-app/*.md | test -f docs/web-app/architecture.md |

## Gate Check Commands

> Generated from AD-010/AD-011 - confirm before Execute once backend/website scaffolding exists (infrastructure/tasks.md Phase 0).

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After tasks with unit tests only (models, React components) | php artisan test --testsuite=Unit && npm --prefix website test |
| Full | After tasks with integration/e2e/visual tests (controllers, screens) | php artisan test && npm --prefix website test && npx --prefix website playwright test |
| Build | After phase completion or config/migration-only tasks | php artisan test && npm --prefix website run build && npx --prefix website playwright test |

---

## Execution Plan

Phases are ordered and run sequentially - each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Data models & migrations

Shared consumer data model per design.md - this feature owns the canonical User row that mobile-app reuses 1:1.

```
T1 -> T2
T1 -> T3
T1 -> T4
T1 -> T5
T1 -> T6
```

### Phase 2: Auth backend (shared consumer guard)

Sanctum consumer guard, OAuth + email/password, signup consent capture, validated-gate, password recovery.

```
T1 -> T7
T7 -> T8
T8 -> T9
T8 -> T10
```

### Phase 3: Event listing & real-time backend

Read-only against admin-panel's Event schema; ranking by cached lat/lng, subscribed to the same Reverb channel admin-panel publishes to.

```
T1 -> T11
T11 -> T12
```

### Phase 4: Profile, social, and notifications backend

ProfileController (WEB-14..16), SocialController (WEB-17/18), NotificationController (WEB-19/20).

```
T2 -> T13
T7 -> T13
T3 -> T14
T4 -> T14
T7 -> T14
T5 -> T15
T7 -> T15
```

### Phase 5: LGPD data export & deletion (canonical implementation)

Owned here per AD-008; mobile-app deep-links to this flow instead of duplicating it.

```
T6 -> T16
T2 -> T16
T3 -> T16
T4 -> T16
T5 -> T16
T16 -> T17
```

### Phase 6: Screen: App shell + auth (login, signup, validation, password recovery)

Reference: Stitch project projects/4886677589059011690 - desktop screen variants exist for every auth flow ('Entrar', 'Cadastro de Novo Usuário', 'Validação de Conta', 'Recuperação de Senha').

```
T9 -> T18
T10 -> T18
T18 -> T19
```

### Phase 7: Screen: Event listing

Reference: Stitch 'Listagem de Eventos' desktop screen (`.../screens/60e855f535d34e1db72fb17510d492a2`), already screenshotted this session and visually confirmed: hero headline, segmented filter bar, featured hero card, event card grid, footer.

```
T11 -> T20
T12 -> T20
T18 -> T20
T20 -> T21
```

### Phase 8: Screen: Event details

Reference: Stitch 'Detalhes do Evento' desktop screen (`.../screens/d8e64e2c4efb4dd8b4565781220ab7f0`).

```
T11 -> T22
T14 -> T22
T18 -> T22
T22 -> T23
```

### Phase 9: Screen: Profile, favorites, and LGPD data rights

Reference: Stitch 'Perfil do Usuário' desktop (`.../screens/c39e5f7bf210481189186e3a9930e4e1`) and 'Eventos Favoritados' desktop (`.../screens/603644825d3f43b1b2411130d7921a0f`).

```
T13 -> T24
T16 -> T24
T17 -> T24
T18 -> T24
T24 -> T25
```

### Phase 10: Screen: Social feed

Reference: Stitch 'Feed Social e Conexões de Amigos' desktop screen (`.../screens/03dd853cc71b48bbb63c63f93a2b2d44`).

```
T14 -> T26
T18 -> T26
T26 -> T27
```

### Phase 11: Screen: Notifications (mobile-layout reflow - no desktop Stitch screen exists)

Reference: Stitch 'Notificações' is mobile-only (`.../screens/3268d4f7227445a1b6a237781fe3316d`) - the web-app spec's own assumption says to reflow this layout for desktop rather than invent an unreferenced one.

```
T15 -> T28
T18 -> T28
T28 -> T29
```

### Phase 12: Cross-cutting accessibility pass

WEB-21's remaining scope beyond the event-details accessibility-info field already covered in T22: screen-reader labels, contrast, dark-mode-first, responsive breakpoints across the whole app.

```
T18 -> T30
T20 -> T30
T22 -> T30
T24 -> T30
T26 -> T30
T28 -> T30
```

### Phase 13: QA seeders

Fixture data covering every scenario needed for QA/manual testing across web-app's consumer entities. Depends on admin-panel's EventSeeder (see admin-panel/tasks.md T38) already having populated Event rows for Favorite/EventInterest to reference.

```
T1 -> T31
T31 -> T32
T2 -> T32
T31 -> T33
T3 -> T33
T32 -> T34
T33 -> T34
T4 -> T34
T31 -> T35
T5 -> T35
T31 -> T36
T6 -> T36
T31 -> T37
T32 -> T37
T33 -> T37
T34 -> T37
T35 -> T37
T36 -> T37
```

### Phase 14: Clean Architecture scaffolding: constants & docs (AD-012..AD-014)

Concrete artifacts for the new architecture decisions: named constants and the per-stack documentation file.

```
T1 -> T38
T5 -> T38
T38 -> T39
```

---

## Task Breakdown

### T1: User migration + model

**What**: Migration and Eloquent model for the canonical consumer `User` (username, email, phone, photoUrl, primaryAddress, searchRadiusKm default 10, favoriteEventTypes, pushEnabled, pushScopeFilter, authProvider, validated flag, consentGivenAt, soft-delete).
**Where**: `backend/database/migrations/xxxx_create_users_table.php, backend/app/Infrastructure/Persistence/Eloquent/User.php, backend/app/Domain/Entities/User.php, backend/app/Domain/Contracts/UserRepositoryInterface.php, backend/app/Infrastructure/Persistence/Eloquent/EloquentUserRepository.php`
**Depends on**: None
**Requirement**: WEB-10..13, WEB-22 (data foundation, shared with mobile-app)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Migration matches design.md's `User` interface field-for-field
- [ ] Model casts `authProvider`/`pushScopeFilter` as enums and `validated` as boolean, with `SoftDeletes`
- [ ] `php artisan migrate --pretend` runs without error
- [ ] GIVEN Clean Architecture (AD-012) THEN `Domain/Entities/User.php` and `Domain/Contracts/UserRepositoryInterface.php` exist, implemented by `Infrastructure/Persistence/Eloquent/EloquentUserRepository.php`

**Tests**: none
**Gate**: build

**Commit**: `feat(web-app): add User migration and model`

---

### T2: Favorite migration + model

**What**: Migration and model for the `Favorite` pivot (userId FK -> users, eventId FK -> admin-panel's events table, createdAt).
**Where**: `backend/database/migrations/xxxx_create_favorites_table.php, backend/app/Infrastructure/Persistence/Eloquent/Favorite.php`
**Depends on**: T1
**Requirement**: WEB-06, WEB-15 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Migration FKs to both `users` and `events` with a composite unique key (one favorite per user per event)
- [ ] Model defines `belongsTo(User::class)` and `belongsTo(Event::class)`
- [ ] `php artisan migrate --pretend` runs without error

**Tests**: none
**Gate**: build

**Commit**: `feat(web-app): add Favorite migration and model`

---

### T3: Friendship migration + model

**What**: Self-referencing migration and model for `Friendship` (userId, friendId, status pending/accepted), queryable both directions.
**Where**: `backend/database/migrations/xxxx_create_friendships_table.php, backend/app/Infrastructure/Persistence/Eloquent/Friendship.php`
**Depends on**: T1
**Requirement**: WEB-17 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Migration FKs both `user_id` and `friend_id` to `users`
- [ ] Model exposes a scope querying both directions for a given user's friend list
- [ ] `php artisan migrate --pretend` runs without error

**Tests**: none
**Gate**: build

**Commit**: `feat(web-app): add Friendship migration and model`

---

### T4: EventInterest migration + model

**What**: Migration and model for `EventInterest` (userId, eventId, markedAt) - also read by admin-panel's AudienceInterestController (ADMIN-15).
**Where**: `backend/database/migrations/xxxx_create_event_interests_table.php, backend/app/Infrastructure/Persistence/Eloquent/EventInterest.php`
**Depends on**: T1
**Requirement**: WEB-17, WEB-18 (data foundation, shared read by admin-panel)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Migration FKs to both `users` and `events` with a composite unique key
- [ ] Model defines `belongsTo(User::class)` and `belongsTo(Event::class)`
- [ ] `php artisan migrate --pretend` runs without error

**Tests**: none
**Gate**: build

**Commit**: `feat(web-app): add EventInterest migration and model`

---

### T5: Notification migration + model

**What**: Migration and model for `Notification` (userId, category enum, read, muted per-alert, payload JSON, createdAt).
**Where**: `backend/database/migrations/xxxx_create_notifications_table.php, backend/app/Infrastructure/Persistence/Eloquent/Notification.php, backend/app/Domain/Entities/Notification.php, backend/app/Domain/Contracts/NotificationRepositoryInterface.php, backend/app/Infrastructure/Persistence/Eloquent/EloquentNotificationRepository.php`
**Depends on**: T1
**Requirement**: WEB-19, WEB-20 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Migration matches design.md's `Notification` interface field-for-field, `payload` as JSON column
- [ ] Model casts `category` as an enum and `payload` as an array
- [ ] `php artisan migrate --pretend` runs without error
- [ ] GIVEN Clean Architecture (AD-012) THEN `Domain/Entities/Notification.php` and `Domain/Contracts/NotificationRepositoryInterface.php` exist, implemented by `Infrastructure/Persistence/Eloquent/EloquentNotificationRepository.php`

**Tests**: none
**Gate**: build

**Commit**: `feat(web-app): add Notification migration and model`

---

### T6: DataExportRequest migration + model

**What**: Migration and model for the consumer `DataExportRequest` (userId, status, downloadUrl, requestedAt) - distinct table from admin-panel's organizer-scoped export requests.
**Where**: `backend/database/migrations/xxxx_create_consumer_data_export_requests_table.php, backend/app/Infrastructure/Persistence/Eloquent/ConsumerDataExportRequest.php`
**Depends on**: T1
**Requirement**: WEB-24 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Migration matches design.md's `DataExportRequest` interface
- [ ] Model defines `belongsTo(User::class)`
- [ ] `php artisan migrate --pretend` runs without error

**Tests**: none
**Gate**: build

**Commit**: `feat(web-app): add consumer DataExportRequest migration and model`

---

### T7: Configure consumer Sanctum guard (cookie + stateful CSRF)

**What**: Add the `consumer` Sanctum guard to `config/auth.php` with HttpOnly/Secure/SameSite cookie config for web sessions and stateful-domain CSRF protection, distinct from admin-panel's guards per AD-002; mobile-app authenticates against the same guard via a personal-access token instead of the cookie.
**Where**: `backend/config/auth.php`
**Depends on**: T1
**Requirement**: AD-002, AD-008 (foundation for WEB-10..13)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `consumer` guard is defined, distinct from `organizer`/`super_admin`
- [ ] Sanctum's stateful-domain CSRF protection is enabled for the web app's domain
- [ ] `php artisan config:show auth` reflects the new guard

**Tests**: none
**Gate**: build

**Commit**: `feat(web-app): configure consumer Sanctum guard with cookie + CSRF`

---

### T8: AuthController: OAuth (Instagram/Facebook/Google) + email/password login

**What**: Socialite-backed OAuth callback for three providers, plus email/password login returning a single generic 'invalid credentials' error (no field-specific enumeration hint).
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/AuthController.php`
**Depends on**: T7
**Requirement**: WEB-10, WEB-11

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a valid OAuth callback from any of the three providers WHEN processed THEN a session is established for the matching/created User - test passes
- [ ] GIVEN an invalid email/password WHEN logging in THEN the response is a single generic 'invalid credentials' message (not field-specific) - test passes
- [ ] GIVEN a cancelled/failed OAuth attempt THEN the user is redirected back to login with a non-blocking inline error - test passes
- [ ] Gate check passes: `php artisan test --filter=ConsumerAuth`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add OAuth and email/password login`

---

### T9: AuthController: signup + LGPD consent capture + validated-gate

**What**: Email/password + OAuth signup, server-side-required consent checkbox (WEB-22, not just client-side) before account creation completes, and a `validated` gate blocking event/social/notification routes until true.
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/AuthController.php`
**Depends on**: T8
**Requirement**: WEB-12, WEB-22

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a signup request without the consent flag WHEN submitted THEN account creation is rejected server-side even if the client bypassed its own checkbox - test passes
- [ ] GIVEN a signup request with consent WHEN submitted THEN `consentGivenAt` is stamped with a timestamp - test passes
- [ ] GIVEN an unvalidated account WHEN it requests an event/social/notification route THEN the request is redirected to the validation flow - test passes
- [ ] Gate check passes: `php artisan test --filter=ConsumerSignup`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add signup with server-side consent capture and validated-gate`

---

### T10: AuthController: password recovery + persistent session

**What**: Password-reset email flow and a persistent (long-lived, refreshable) session for returning users.
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/AuthController.php`
**Depends on**: T8
**Requirement**: WEB-13

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a password-recovery request WHEN submitted with a registered email THEN a reset link/token is issued - test passes
- [ ] GIVEN a returning user with a valid persistent session WHEN they open the app THEN they remain logged in without re-entering credentials - test passes
- [ ] Gate check passes: `php artisan test --filter=PasswordRecovery`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add password recovery and persistent session`

---

### T11: ConsumerEventController (list, details, pagination, ranking)

**What**: `GET /consumer/events` (paginated, ordered by date, ranked by `User.primaryAddress`+`searchRadiusKm` against the Event's cached lat/lng) and `GET /consumer/events/{id}` (details).
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/EventController.php`
**Depends on**: T1
**Requirement**: WEB-01, WEB-03, WEB-04, WEB-08

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN events within the user's search radius WHEN listing THEN they are returned ordered by date and ranked nearer-first - test passes
- [ ] GIVEN pagination parameters WHEN requested THEN the correct page of results is returned - test passes
- [ ] GIVEN an event missing a geocoded lat/lng (per design.md's Risks table) WHEN listed THEN it still appears, without a map pin, rather than being silently dropped - test passes
- [ ] Gate check passes: `php artisan test --filter=ConsumerEventController`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add ConsumerEventController list/details/ranking`

---

### T12: Reverb `events` channel subscription wiring

**What**: Frontend Echo/Reverb client subscription to the public `events` channel (same one admin-panel's EventController broadcasts to) so the listing refreshes within 60 seconds of a publish/update/cancel.
**Where**: `website/src/infrastructure/realtime/RealtimeClient.ts`
**Depends on**: T11
**Requirement**: WEB-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN an `EventPublished`/`EventUpdated`/`EventCancelled` broadcast WHEN received THEN the in-memory event list updates within 60 seconds without a full page reload - test passes
- [ ] Gate check passes: `npm --prefix website test -- realtime`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(web-app): wire Reverb events channel subscription`

---

### T13: ProfileController (edit, preferences, favorites CRUD)

**What**: `PUT /consumer/profile`, `GET /consumer/favorites`, `DELETE /consumer/favorites/{eventId}` - profile fields, address/radius preference, favorites management.
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/ProfileController.php`
**Depends on**: T2, T7
**Requirement**: WEB-14, WEB-15, WEB-16

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a profile edit WHEN submitted THEN the User row updates and the response reflects the new values - test passes
- [ ] GIVEN a user favorites/unfavorites an event WHEN requested THEN the Favorite row is created/removed accordingly - test passes
- [ ] GIVEN a user changes `searchRadiusKm` WHEN saved THEN subsequent listing requests use the new radius - test passes
- [ ] Gate check passes: `php artisan test --filter=ProfileController`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add ProfileController`

---

### T14: SocialController (friends, suggestions, feed, sharing)

**What**: Friends list, friend suggestions, 'friends interested' surfacing on an event, activity feed, and a share action.
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/SocialController.php`
**Depends on**: T3, T4, T7
**Requirement**: WEB-17, WEB-18

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN accepted friendships WHEN requesting the friends list THEN both directions of the relationship resolve correctly - test passes
- [ ] GIVEN a friend has marked interest in an event WHEN the current user views that event THEN they appear in its 'friends interested' list - test passes
- [ ] GIVEN the activity feed WHEN requested THEN it reflects recent friend activity (favorites, interest, new friendships) - test passes
- [ ] Gate check passes: `php artisan test --filter=SocialController`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add SocialController`

---

### T15: NotificationController (categories, mute, clear+undo, push toggle)

**What**: Filterable notification list by category, per-item mute, 'clear all' as a soft-delete with a client-side undo window, and a scoped push-channel toggle (`all` vs `favorited_and_friends`).
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/NotificationController.php`
**Depends on**: T5, T7
**Requirement**: WEB-19, WEB-20

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN notifications across categories WHEN filtered by a tab THEN only that category's items return - test passes
- [ ] GIVEN a 'clear all' request WHEN submitted THEN notifications are soft-deleted (not hard-deleted) and reversible via a subsequent undo call - test passes
- [ ] GIVEN a push-scope toggle change WHEN saved THEN it persists to `pushScopeFilter` - test passes
- [ ] Gate check passes: `php artisan test --filter=NotificationController`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add NotificationController`

---

### T16: Consumer data export endpoint

**What**: `POST /consumer/data-export` queuing `DataExportJob` (Laravel Queue) generating a downloadable JSON archive of User/Favorite/Friendship/EventInterest/Notification rows for that user.
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/DataRightsController.php`
**Depends on**: T6, T2, T3, T4, T5
**Requirement**: WEB-24

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN an export request WHEN the queued job completes THEN the `DataExportRequest` moves to `ready` with a `downloadUrl` - test passes
- [ ] GIVEN the archive WHEN inspected THEN it contains only that user's own rows across all five tables - test passes
- [ ] Gate check passes: `php artisan test --filter=ConsumerDataExport`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add consumer data export endpoint`

---

### T17: Consumer account deletion endpoint (cross-platform deactivation)

**What**: `POST /consumer/account/delete` soft-deleting the User row so the same account is deactivated on both web and mobile (shared guard); 409 with a confirmation-required flag when unresolved state exists (e.g. a pending friend request) per design.md's Error Handling table.
**Where**: `backend/app/Presentation/Http/Controllers/Consumer/DataRightsController.php`
**Depends on**: T16
**Requirement**: WEB-25

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a user with no unresolved state WHEN requesting deletion THEN the User row is soft-deleted and both a mobile-session token check and a web-session cookie check reflect the deactivation - test passes
- [ ] GIVEN a user with a pending friend request WHEN requesting deletion without `confirm: true` THEN the response is 409 - test passes
- [ ] Gate check passes: `php artisan test --filter=ConsumerAccountDeletion`

**Tests**: integration
**Gate**: full

**Commit**: `feat(web-app): add consumer account deletion with cross-platform deactivation`

---

### T18: Build app shell + login/signup/validation/password-recovery screens

**What**: Global shell (marquee strip, nav, footer per designMd) plus the four auth screens, matching the Stitch desktop screens: Entrar (`.../screens/9e47e96ce09740cda73db77096e0470d`), Cadastro (`.../screens/83e8b87d2eaa4bb2b6dd88bcbf5ed137`), Validação de Conta (`.../screens/ef264dd4fcf84e9bb1da8b302009036a`), Recuperação de Senha (`.../screens/5a52f29f5aed476184432de638a0ff75`).
**Where**: `website/src/presentation/pages/Login.tsx, website/src/presentation/pages/Signup.tsx, website/src/presentation/pages/AccountValidation.tsx, website/src/presentation/pages/PasswordRecovery.tsx`
**Depends on**: T9, T10
**Requirement**: WEB-10, WEB-11, WEB-12, WEB-13, WEB-22, WEB-23

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Page background `#131315`/`#08080a` (surface / surface-dim tokens); card surfaces `#1c1c20` with `1rem` radius (verified design-system tokens from Stitch `designTheme.designMd`)
- [ ] Form inputs: `#17171a` background, `1px #2c2e33`-equivalent border (`outline-variant #48423c`), `0.5rem` radius, `#f2f1ee` text, focus state a `2px #ff7a3d` stroke
- [ ] Primary CTA button ('Entrar', 'Criar Conta'): pill (`rounded-full`), solid `#ff7a3d` fill, `#3a1200`-equivalent dark label, 14px vertical / 28px horizontal padding, hover `translateY(-2px)` + glow shadow
- [ ] Consent checkbox is visibly required (not pre-checked) on the signup screen, with the privacy-policy/DPO link (WEB-23) placed directly beside it, per the LGPD consent AC
- [ ] OAuth buttons (Instagram/Facebook/Google) render as Secondary (outlined) buttons per the design system's button spec
- [ ] Password-recovery screen matches the Stitch reference's form-field layout, not a generic unstyled form

**Tests**: visual
**Gate**: quick

**Commit**: `feat(web-app): add app shell and auth screens (login, signup, validation, password recovery)`

---

### T19: Verify Screen: Auth flow against Stitch reference

**What**: Screenshot each of the four auth screens on the running website dev build with Playwright, download the matching Stitch reference screenshots (`mcp__stitch__get_screen` + image download), and compare layout, the specific hex tokens above, and element presence via `getComputedStyle`.
**Where**: `website/e2e/visual/auth.spec.ts`
**Depends on**: T18
**Requirement**: WEB-10, WEB-11, WEB-12, WEB-13, WEB-22, WEB-23

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Card/background/input colors on each screen match the verified Stitch tokens exactly
- [ ] Primary button styling (fill, radius, hover transform) matches the design system's Button spec
- [ ] Consent checkbox and privacy-policy link are both present and visible without scrolling on the signup screen
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(web-app): verify auth screens against Stitch reference`

---

### T20: Build event listing page

**What**: Hero headline + segmented filter bar ('Banda ou Gênero' | 'Cidade' | 'Data'), featured event card, and the responsive event card grid, subscribed to the T12 realtime feed.
**Where**: `website/src/presentation/pages/EventListing.tsx`
**Depends on**: T11, T12, T18
**Requirement**: WEB-01, WEB-03, WEB-04, WEB-05, WEB-06, WEB-07, WEB-08, WEB-09

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Event card: `1rem` radius, `#1c1c20` surface, 16:9 image banner with bottom scrim gradient, top-left location badge (`label-caps`, uppercase, +0.08em tracking), top-right circular favorite icon (44x44px, `rgba(255,255,255,.05)` fill, `#ff5d7a` fill when active), footer amber price (`#ffb020`) left + pill 'Detalhes' CTA right, hover: image `scale(1.04)` + card rises 6px (all verified `designTheme.designMd` tokens)
- [ ] Filter chips: inactive = transparent bg, `1px #2c2e33`-equivalent border (`outline-variant`), `#a3a09b` text; active = `#ff7a3d` at 15% opacity with `1.5px` solid `#ff7a3d` border, `#ff7a3d` text
- [ ] Ticket-link button opens in a new tab (`target="_blank"`), not the current one, per WEB-08
- [ ] GIVEN a listing fetch failure THEN an inline error state renders instead of a blank page (WEB-09)
- [ ] GIVEN pagination WHEN scrolled/clicked THEN additional pages load without losing scroll position

**Tests**: visual
**Gate**: quick

**Commit**: `feat(web-app): add event listing page`

---

### T21: Verify Screen: Event listing against Stitch reference

**What**: Screenshot the running listing page, compare against the Stitch 'Listagem de Eventos' desktop reference (layout confirmed this session: hero + filter bar + card grid + footer) for structure, the verified card/chip/button tokens, and element presence.
**Where**: `website/e2e/visual/event-listing.spec.ts`
**Depends on**: T20
**Requirement**: WEB-01, WEB-03, WEB-04, WEB-05, WEB-06, WEB-07, WEB-08, WEB-09

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Card anatomy (banner, badge, favorite icon, price, CTA) matches the reference element-for-element
- [ ] Filter chip active/inactive colors match the verified tokens exactly
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(web-app): verify event listing screen against Stitch reference`

---

### T22: Build event details page

**What**: Full event detail view (date/time, venue, description, price, ticket link, accessibility info, promoter list) with a favorite toggle and 'friends interested' surfacing (from T14).
**Where**: `website/src/presentation/pages/EventDetails.tsx`
**Depends on**: T11, T14, T18
**Requirement**: WEB-01, WEB-08, WEB-21

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Layout follows the Stitch 'Detalhes do Evento' reference: full-bleed hero image with gradient scrim, title/date in `headline-lg` (Poppins), venue with pin icon, amber price, pill ticket-link CTA
- [ ] Accessibility info section is present and visible without requiring an accordion click for the primary fields (per WEB-21)
- [ ] GIVEN the external ticket link fails to open THEN an inline error appears and the user stays on the details page (per design.md's Error Handling table), no dead-end navigation
- [ ] 'Friends interested' section renders avatars + names when T14 returns results, and is hidden (not an empty box) when there are none

**Tests**: visual
**Gate**: quick

**Commit**: `feat(web-app): add event details page`

---

### T23: Verify Screen: Event details against Stitch reference

**What**: Screenshot the running details page, compare against the Stitch 'Detalhes do Evento' desktop reference for layout, typography tokens, and element presence.
**Where**: `website/e2e/visual/event-details.spec.ts`
**Depends on**: T22
**Requirement**: WEB-01, WEB-08, WEB-21

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Hero, typography scale, and CTA styling match the verified reference
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(web-app): verify event details screen against Stitch reference`

---

### T24: Build profile, favorites, and data-rights screen

**What**: Profile edit form, address/radius preference control, favorites list (reusing the T20 event-card component), and the LGPD export/delete UI.
**Where**: `website/src/presentation/pages/Profile.tsx`
**Depends on**: T13, T16, T17, T18
**Requirement**: WEB-14, WEB-15, WEB-16, WEB-23, WEB-24, WEB-25

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Profile form reuses the T18 input/label tokens
- [ ] Favorites grid reuses the T20 event-card component and tokens exactly (no divergent restyling)
- [ ] Export button: Default Primary spec; export status pill reuses the badge tokens (pending/ready/failed mapped to the design system's warning/success/error colors)
- [ ] Delete Account button uses a visually distinct danger treatment (`#ff6b5e`/error token) from the Default Primary button
- [ ] Deleting with unresolved state (e.g. pending friend request) shows a confirmation modal before resubmitting with `confirm: true`, not a silent 409

**Tests**: visual
**Gate**: quick

**Commit**: `feat(web-app): add profile, favorites, and data-rights screen`

---

### T25: Verify Screen: Profile & data rights against Stitch reference

**What**: Screenshot the profile screen, compare against the Stitch 'Perfil do Usuário' and 'Eventos Favoritados' desktop references for layout and tokens.
**Where**: `website/e2e/visual/profile.spec.ts`
**Depends on**: T24
**Requirement**: WEB-14, WEB-15, WEB-16, WEB-23, WEB-24, WEB-25

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Form, favorites-grid, and button styling match the verified references
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(web-app): verify profile and data-rights screen against Stitch reference`

---

### T26: Build social feed page

**What**: Friends list, friend suggestions, activity feed, and share action, backed by T14.
**Where**: `website/src/presentation/pages/SocialFeed.tsx`
**Depends on**: T14, T18
**Requirement**: WEB-17, WEB-18

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Layout follows the Stitch 'Feed Social' reference structure (friend list column + activity feed column, per the reference screenshot)
- [ ] Friend avatars use the design system's circular-element convention
- [ ] Share action uses the Secondary (outlined) button spec, distinct from the Default Primary actions elsewhere on the page

**Tests**: visual
**Gate**: quick

**Commit**: `feat(web-app): add social feed page`

---

### T27: Verify Screen: Social feed against Stitch reference

**What**: Screenshot the social feed page, compare against the Stitch reference for layout and tokens.
**Where**: `website/e2e/visual/social-feed.spec.ts`
**Depends on**: T26
**Requirement**: WEB-17, WEB-18

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Layout and button styling match the verified reference
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(web-app): verify social feed screen against Stitch reference`

---

### T28: Build notifications page (reflowed from the mobile Stitch reference)

**What**: Category filter tabs, per-item actions (mute), 'clear all' with an undo window, and a push-scope toggle, laid out as a wider single-column reflow of the mobile Stitch screen's structure (per the spec's carried-over assumption) rather than a net-new desktop layout.
**Where**: `website/src/presentation/pages/Notifications.tsx`
**Depends on**: T15, T18
**Requirement**: WEB-19, WEB-20

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Category tabs and notification-item cards reuse the verified card/chip tokens from the other screens (no divergent one-off styling)
- [ ] 'Clear all' shows an undo affordance for the client-side window (per design.md's Tech Decision) before the soft-delete is finalized
- [ ] Mute action is per-item, not channel-wide
- [ ] Push-scope toggle persists via T15's endpoint

**Tests**: visual
**Gate**: quick

**Commit**: `feat(web-app): add notifications page (reflowed desktop layout)`

---

### T29: Verify Screen: Notifications against Stitch reference

**What**: Screenshot the notifications page, compare its reused card/chip tokens against the same verified values checked on the other screens (there is no desktop Stitch screenshot to diff directly, since none exists - the check instead confirms token consistency with the rest of the app).
**Where**: `website/e2e/visual/notifications.spec.ts`
**Depends on**: T28
**Requirement**: WEB-19, WEB-20

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Card/chip/button tokens match the same verified values used elsewhere in the app (internal consistency check, since no desktop reference screenshot exists)
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(web-app): verify notifications screen for token consistency`

---

### T30: App-wide accessibility audit and fixes

**What**: Run an automated accessibility check (e.g. jest-axe / Playwright's axe integration) across every screen built in this feature and fix violations (contrast, missing labels, focus order, dark-mode-first defaults, responsive breakpoints per the design system's mobile/tablet/desktop rules).
**Where**: `website/src/presentation/**/*.tsx`
**Depends on**: T18, T20, T22, T24, T26, T28
**Requirement**: WEB-21

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN an automated axe scan of every screen THEN zero critical/serious violations remain - test passes
- [ ] Dark mode is confirmed as the default rendering (no unstyled light-mode flash)
- [ ] Every interactive element has a visible focus ring per the design system's `2px solid #ff7a3d` focus spec
- [ ] Gate check passes: `npm --prefix website test -- a11y`

**Tests**: unit
**Gate**: quick

**Commit**: `fix(web-app): resolve app-wide accessibility audit findings`

---

### T31: UserSeeder (every authProvider x validated-state combination)

**What**: Seed consumer users covering every `authProvider` (instagram/facebook/google/email) x `validated` (true/false) combination, with varied `primaryAddress`/`searchRadiusKm` values for ranking QA, and at least one soft-deleted user (for LGPD-deletion QA).
**Where**: `backend/database/seeders/UserSeeder.php`
**Depends on**: T1
**Requirement**: WEB-10..13, WEB-14..16, WEB-22 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least one user exists for each of the 8 authProvider x validated combinations
- [ ] At least 3 users have distinct `primaryAddress`/`searchRadiusKm` values spanning near/far from the seeded events' locations
- [ ] One user has `deletedAt` set (soft-deleted, for WEB-25 QA)
- [ ] `php artisan db:seed --class=UserSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(web-app): add UserSeeder for QA scenarios`

---

### T32: FavoriteSeeder

**What**: Seed favorites linking T31's users to admin-panel's seeded events (see admin-panel/tasks.md T38).
**Where**: `backend/database/seeders/FavoriteSeeder.php`
**Depends on**: T31, T2
**Reuses**: admin-panel's EventSeeder output (admin-panel/tasks.md T38) - this seeder requires those Event rows to already exist
**Requirement**: WEB-06, WEB-15 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least 2 users have at least one favorited event each
- [ ] `php artisan db:seed --class=FavoriteSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(web-app): add FavoriteSeeder for QA scenarios`

---

### T33: FriendshipSeeder

**What**: Seed friendships across T31's users covering both `pending` and `accepted` states, in both directions.
**Where**: `backend/database/seeders/FriendshipSeeder.php`
**Depends on**: T31, T3
**Requirement**: WEB-17 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least one `pending` and one `accepted` friendship pair exist
- [ ] `php artisan db:seed --class=FriendshipSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(web-app): add FriendshipSeeder for QA scenarios`

---

### T34: EventInterestSeeder ('friends interested' QA overlap)

**What**: Seed EventInterest rows overlapping T33's accepted friendships and admin-panel's seeded events, so at least one event shows a 'friends interested' result for at least one seeded user.
**Where**: `backend/database/seeders/EventInterestSeeder.php`
**Depends on**: T32, T33, T4
**Requirement**: WEB-17, WEB-18 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least one event has 2+ interested users who are also friends with each other (per T33), producing a non-empty 'friends interested' result
- [ ] `php artisan db:seed --class=EventInterestSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(web-app): add EventInterestSeeder for QA scenarios`

---

### T35: NotificationSeeder (every category x read x muted combination)

**What**: Seed notifications covering every `category` (urgent/batch_pricing/friends/new_event/reminder) crossed with read/unread and muted/unmuted states.
**Where**: `backend/database/seeders/NotificationSeeder.php`
**Depends on**: T31, T5
**Requirement**: WEB-19, WEB-20 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least one notification exists per category, with at least one read+muted, one unread+unmuted, and one of each other combination represented across the set
- [ ] `php artisan db:seed --class=NotificationSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(web-app): add NotificationSeeder for QA scenarios`

---

### T36: ConsumerDataExportRequestSeeder

**What**: Seed one `DataExportRequest` (consumer) per status (pending/ready/failed) for LGPD data-rights screen QA.
**Where**: `backend/database/seeders/ConsumerDataExportRequestSeeder.php`
**Depends on**: T31, T6
**Requirement**: WEB-24 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] One ConsumerDataExportRequest exists per status value
- [ ] `php artisan db:seed --class=ConsumerDataExportRequestSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(web-app): add ConsumerDataExportRequestSeeder for QA scenarios`

---

### T37: WebAppSeeder (orchestrator)

**What**: Master seeder calling T31-T36 in FK-safe order, registered so `php artisan db:seed` picks it up after admin-panel's `AdminPanelSeeder` (see infrastructure/tasks.md's master seeding task for the cross-feature run order).
**Where**: `backend/database/seeders/WebAppSeeder.php`
**Depends on**: T31, T32, T33, T34, T35, T36
**Reuses**: Must run after admin-panel's AdminPanelSeeder (admin-panel/tasks.md T42) since Favorite/EventInterest reference its Event rows
**Requirement**: WEB-01..25 (QA fixtures, orchestration)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `php artisan db:seed --class=WebAppSeeder` runs all 6 seeders in FK-safe order with no foreign-key errors, given AdminPanelSeeder has already run
- [ ] Running it twice in a row does not create duplicate rows or fail

**Tests**: none
**Gate**: build

**Commit**: `test(web-app): add WebAppSeeder orchestrator`

---

### T38: WebAppConstants (backend + frontend, no magic numbers/strings)

**What**: Named constants replacing magic literals: `DEFAULT_SEARCH_RADIUS_KM = 10`, notification clear-all undo-window seconds, and every `authProvider`/`pushScopeFilter`/notification-`category` enum string.
**Where**: `backend/app/Domain/Constants/WebAppConstants.php, website/src/domain/constants/webAppConstants.ts`
**Depends on**: T1, T5
**Requirement**: AD-013 (code quality)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `DEFAULT_SEARCH_RADIUS_KM`, the undo-window duration, and every authProvider/pushScopeFilter/category string are defined exactly once, backend and frontend
- [ ] T13 (ProfileController) and T15 (NotificationController) reference these constants instead of bare literals
- [ ] No other task in this file reintroduces a bare `10` for the default radius once this task lands

**Tests**: none
**Gate**: build

**Commit**: `refactor(web-app): extract named constants for radius/undo-window/status values`

---

### T39: docs/web-app/architecture.md

**What**: Markdown write-up of this feature's Clean Architecture layering (AD-012) and coding conventions (AD-013), with a per-layer example drawn from the Event listing flow.
**Where**: `docs/web-app/architecture.md`
**Depends on**: T38
**Requirement**: AD-014 (documentation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Doc explains all 4 layers with one concrete example path per layer from this feature
- [ ] Doc states the no-magic-numbers, one-class-per-file, and no-task-comments rules
- [ ] Doc is committed under `docs/web-app/`, not scattered as code comments

**Tests**: none
**Gate**: build

**Commit**: `docs(web-app): add architecture.md documenting Clean Architecture layering`

---

## Phase Execution Map

Visual representation of task ordering. Phases run in sequence, and tasks within a phase run in order:

```
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6 -> Phase 7 -> Phase 8 -> Phase 9 -> Phase 10 -> Phase 11 -> Phase 12 -> Phase 13 -> Phase 14

Phase 1:  T1 ------> T2
Phase 1:  T1 ------> T3
Phase 1:  T1 ------> T4
Phase 1:  T1 ------> T5
Phase 1:  T1 ------> T6
Phase 2:  T1 ------> T7
Phase 2:  T7 ------> T8
Phase 2:  T8 ------> T9
Phase 2:  T8 ------> T10
Phase 3:  T1 ------> T11
Phase 3:  T11 ------> T12
Phase 4:  T2 ------> T13
Phase 4:  T7 ------> T13
Phase 4:  T3 ------> T14
Phase 4:  T4 ------> T14
Phase 4:  T7 ------> T14
Phase 4:  T5 ------> T15
Phase 4:  T7 ------> T15
Phase 5:  T6 ------> T16
Phase 5:  T2 ------> T16
Phase 5:  T3 ------> T16
Phase 5:  T4 ------> T16
Phase 5:  T5 ------> T16
Phase 5:  T16 ------> T17
Phase 6:  T9 ------> T18
Phase 6:  T10 ------> T18
Phase 6:  T18 ------> T19
Phase 7:  T11 ------> T20
Phase 7:  T12 ------> T20
Phase 7:  T18 ------> T20
Phase 7:  T20 ------> T21
Phase 8:  T11 ------> T22
Phase 8:  T14 ------> T22
Phase 8:  T18 ------> T22
Phase 8:  T22 ------> T23
Phase 9:  T13 ------> T24
Phase 9:  T16 ------> T24
Phase 9:  T17 ------> T24
Phase 9:  T18 ------> T24
Phase 9:  T24 ------> T25
Phase 10:  T14 ------> T26
Phase 10:  T18 ------> T26
Phase 10:  T26 ------> T27
Phase 11:  T15 ------> T28
Phase 11:  T18 ------> T28
Phase 11:  T28 ------> T29
Phase 12:  T18 ------> T30
Phase 12:  T20 ------> T30
Phase 12:  T22 ------> T30
Phase 12:  T24 ------> T30
Phase 12:  T26 ------> T30
Phase 12:  T28 ------> T30
Phase 13:  T1 ------> T31
Phase 13:  T31 ------> T32
Phase 13:  T2 ------> T32
Phase 13:  T31 ------> T33
Phase 13:  T3 ------> T33
Phase 13:  T32 ------> T34
Phase 13:  T33 ------> T34
Phase 13:  T4 ------> T34
Phase 13:  T31 ------> T35
Phase 13:  T5 ------> T35
Phase 13:  T31 ------> T36
Phase 13:  T6 ------> T36
Phase 13:  T31 ------> T37
Phase 13:  T32 ------> T37
Phase 13:  T33 ------> T37
Phase 13:  T34 ------> T37
Phase 13:  T35 ------> T37
Phase 13:  T36 ------> T37
Phase 14:  T1 ------> T38
Phase 14:  T5 ------> T38
Phase 14:  T38 ------> T39
```

Execution is strictly sequential - there is no intra-phase parallelism. A single agent (or batch worker) works one task at a time, in order.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1: User migration + model | 1 model + 1 migration | ✅ Granular |
| T2: Favorite migration + model | 1 model + 1 migration | ✅ Granular |
| T3: Friendship migration + model | 1 model + 1 migration | ✅ Granular |
| T4: EventInterest migration + model | 1 model + 1 migration | ✅ Granular |
| T5: Notification migration + model | 1 model + 1 migration | ✅ Granular |
| T6: DataExportRequest migration + model | 1 model + 1 migration | ✅ Granular |
| T7: Configure consumer Sanctum guard (cookie + stateful CSRF) | 1 file | ✅ Granular |
| T8: AuthController: OAuth (Instagram/Facebook/Google) + email/password login | 1 file | ✅ Granular |
| T9: AuthController: signup + LGPD consent capture + validated-gate | 1 file (modifies T8's controller) | ✅ Granular |
| T10: AuthController: password recovery + persistent session | 1 file (modifies T8's controller) | ✅ Granular |
| T11: ConsumerEventController (list, details, pagination, ranking) | 1 file | ✅ Granular |
| T12: Reverb `events` channel subscription wiring | 1 file | ✅ Granular |
| T13: ProfileController (edit, preferences, favorites CRUD) | 1 file | ✅ Granular |
| T14: SocialController (friends, suggestions, feed, sharing) | 1 file | ✅ Granular |
| T15: NotificationController (categories, mute, clear+undo, push toggle) | 1 file | ✅ Granular |
| T16: Consumer data export endpoint | 1 file | ✅ Granular |
| T17: Consumer account deletion endpoint (cross-platform deactivation) | 1 file (modifies T16's controller) | ✅ Granular |
| T18: Build app shell + login/signup/validation/password-recovery screens | 4 files (cohesive - the auth flow is one connected screen group in the reference) | ✅ Granular |
| T19: Verify Screen: Auth flow against Stitch reference | 1 file | ✅ Granular |
| T20: Build event listing page | 1 file | ✅ Granular |
| T21: Verify Screen: Event listing against Stitch reference | 1 file | ✅ Granular |
| T22: Build event details page | 1 file | ✅ Granular |
| T23: Verify Screen: Event details against Stitch reference | 1 file | ✅ Granular |
| T24: Build profile, favorites, and data-rights screen | 1 file | ✅ Granular |
| T25: Verify Screen: Profile & data rights against Stitch reference | 1 file | ✅ Granular |
| T26: Build social feed page | 1 file | ✅ Granular |
| T27: Verify Screen: Social feed against Stitch reference | 1 file | ✅ Granular |
| T28: Build notifications page (reflowed from the mobile Stitch reference) | 1 file | ✅ Granular |
| T29: Verify Screen: Notifications against Stitch reference | 1 file | ✅ Granular |
| T30: App-wide accessibility audit and fixes | cross-cutting (multiple files - audit-and-fix task, not a single new component) | ✅ Granular |
| T31: UserSeeder (every authProvider x validated-state combination) | 1 file | ✅ Granular |
| T32: FavoriteSeeder | 1 file | ✅ Granular |
| T33: FriendshipSeeder | 1 file | ✅ Granular |
| T34: EventInterestSeeder ('friends interested' QA overlap) | 1 file | ✅ Granular |
| T35: NotificationSeeder (every category x read x muted combination) | 1 file | ✅ Granular |
| T36: ConsumerDataExportRequestSeeder | 1 file | ✅ Granular |
| T37: WebAppSeeder (orchestrator) | 1 file | ✅ Granular |
| T38: WebAppConstants (backend + frontend, no magic numbers/strings) | 2 files (cohesive - one constants set, backend + frontend mirror) | ✅ Granular |
| T39: docs/web-app/architecture.md | 1 file | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ----------------------- | -------------- | ------ |
| T1 | None | None | ✅ Match |
| T2 | T1 | T1 | ✅ Match |
| T3 | T1 | T1 | ✅ Match |
| T4 | T1 | T1 | ✅ Match |
| T5 | T1 | T1 | ✅ Match |
| T6 | T1 | T1 | ✅ Match |
| T7 | T1 | T1 | ✅ Match |
| T8 | T7 | T7 | ✅ Match |
| T9 | T8 | T8 | ✅ Match |
| T10 | T8 | T8 | ✅ Match |
| T11 | T1 | T1 | ✅ Match |
| T12 | T11 | T11 | ✅ Match |
| T13 | T2, T7 | T2, T7 | ✅ Match |
| T14 | T3, T4, T7 | T3, T4, T7 | ✅ Match |
| T15 | T5, T7 | T5, T7 | ✅ Match |
| T16 | T6, T2, T3, T4, T5 | T6, T2, T3, T4, T5 | ✅ Match |
| T17 | T16 | T16 | ✅ Match |
| T18 | T9, T10 | T9, T10 | ✅ Match |
| T19 | T18 | T18 | ✅ Match |
| T20 | T11, T12, T18 | T11, T12, T18 | ✅ Match |
| T21 | T20 | T20 | ✅ Match |
| T22 | T11, T14, T18 | T11, T14, T18 | ✅ Match |
| T23 | T22 | T22 | ✅ Match |
| T24 | T13, T16, T17, T18 | T13, T16, T17, T18 | ✅ Match |
| T25 | T24 | T24 | ✅ Match |
| T26 | T14, T18 | T14, T18 | ✅ Match |
| T27 | T26 | T26 | ✅ Match |
| T28 | T15, T18 | T15, T18 | ✅ Match |
| T29 | T28 | T28 | ✅ Match |
| T30 | T18, T20, T22, T24, T26, T28 | T18, T20, T22, T24, T26, T28 | ✅ Match |
| T31 | T1 | T1 | ✅ Match |
| T32 | T31, T2 | T31, T2 | ✅ Match |
| T33 | T31, T3 | T31, T3 | ✅ Match |
| T34 | T32, T33, T4 | T32, T33, T4 | ✅ Match |
| T35 | T31, T5 | T31, T5 | ✅ Match |
| T36 | T31, T6 | T31, T6 | ✅ Match |
| T37 | T31, T32, T33, T34, T35, T36 | T31, T32, T33, T34, T35, T36 | ✅ Match |
| T38 | T1, T5 | T1, T5 | ✅ Match |
| T39 | T38 | T38 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | ---------------------------- | ---------------- | ---------- | ------ |
| T1: User migration + model | Eloquent model / migration | none | none | ✅ OK |
| T2: Favorite migration + model | Eloquent model / migration | none | none | ✅ OK |
| T3: Friendship migration + model | Eloquent model / migration | none | none | ✅ OK |
| T4: EventInterest migration + model | Eloquent model / migration | none | none | ✅ OK |
| T5: Notification migration + model | Eloquent model / migration | none | none | ✅ OK |
| T6: DataExportRequest migration + model | Eloquent model / migration | none | none | ✅ OK |
| T7: Configure consumer Sanctum guard (cookie + stateful CSRF) | Eloquent model / migration | none | none | ✅ OK |
| T8: AuthController: OAuth (Instagram/Facebook/Google) + email/password login | Controller / route (feature) | integration | integration | ✅ OK |
| T9: AuthController: signup + LGPD consent capture + validated-gate | Controller / route (feature) | integration | integration | ✅ OK |
| T10: AuthController: password recovery + persistent session | Controller / route (feature) | integration | integration | ✅ OK |
| T11: ConsumerEventController (list, details, pagination, ranking) | Controller / route (feature) | integration | integration | ✅ OK |
| T12: Reverb `events` channel subscription wiring | React component (page/widget) | unit | unit | ✅ OK |
| T13: ProfileController (edit, preferences, favorites CRUD) | Controller / route (feature) | integration | integration | ✅ OK |
| T14: SocialController (friends, suggestions, feed, sharing) | Controller / route (feature) | integration | integration | ✅ OK |
| T15: NotificationController (categories, mute, clear+undo, push toggle) | Controller / route (feature) | integration | integration | ✅ OK |
| T16: Consumer data export endpoint | Controller / route (feature) | integration | integration | ✅ OK |
| T17: Consumer account deletion endpoint (cross-platform deactivation) | Controller / route (feature) | integration | integration | ✅ OK |
| T18: Build app shell + login/signup/validation/password-recovery screens | React component (page/widget) | visual | visual | ✅ OK |
| T19: Verify Screen: Auth flow against Stitch reference | Screen / UI layout | visual | visual | ✅ OK |
| T20: Build event listing page | React component (page/widget) | visual | visual | ✅ OK |
| T21: Verify Screen: Event listing against Stitch reference | Screen / UI layout | visual | visual | ✅ OK |
| T22: Build event details page | React component (page/widget) | visual | visual | ✅ OK |
| T23: Verify Screen: Event details against Stitch reference | Screen / UI layout | visual | visual | ✅ OK |
| T24: Build profile, favorites, and data-rights screen | React component (page/widget) | visual | visual | ✅ OK |
| T25: Verify Screen: Profile & data rights against Stitch reference | Screen / UI layout | visual | visual | ✅ OK |
| T26: Build social feed page | React component (page/widget) | visual | visual | ✅ OK |
| T27: Verify Screen: Social feed against Stitch reference | Screen / UI layout | visual | visual | ✅ OK |
| T28: Build notifications page (reflowed from the mobile Stitch reference) | React component (page/widget) | visual | visual | ✅ OK |
| T29: Verify Screen: Notifications against Stitch reference | Screen / UI layout | visual | visual | ✅ OK |
| T30: App-wide accessibility audit and fixes | React component (page/widget) | unit | unit | ✅ OK |
| T31: UserSeeder (every authProvider x validated-state combination) | Eloquent model / migration | none | none | ✅ OK |
| T32: FavoriteSeeder | Eloquent model / migration | none | none | ✅ OK |
| T33: FriendshipSeeder | Eloquent model / migration | none | none | ✅ OK |
| T34: EventInterestSeeder ('friends interested' QA overlap) | Eloquent model / migration | none | none | ✅ OK |
| T35: NotificationSeeder (every category x read x muted combination) | Eloquent model / migration | none | none | ✅ OK |
| T36: ConsumerDataExportRequestSeeder | Eloquent model / migration | none | none | ✅ OK |
| T37: WebAppSeeder (orchestrator) | Eloquent model / migration | none | none | ✅ OK |
| T38: WebAppConstants (backend + frontend, no magic numbers/strings) | Eloquent model / migration | none | none | ✅ OK |
| T39: docs/web-app/architecture.md | Developer documentation | none | none | ✅ OK |

---

## Tools & Skills for Execution

**Available MCPs for these tasks**: Playwright MCP (`mcp__plugin_playwright_playwright__*`) and Stitch MCP (`mcp__stitch__get_screen`, screenshot download) for screen tasks and their paired verification tasks; NONE for backend tasks.

**Available Skills for these tasks**: NONE

