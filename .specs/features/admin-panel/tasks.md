# Admin Panel (Organizer/Venue Console) Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Design**: `.specs/features/admin-panel/design.md`  
**Status**: Draft

---

## Coding Conventions (MANDATORY)

Per AD-012 (Clean Architecture) and AD-013 (code quality), every task in this file follows these rules without restating them per task:

- **4 layers, one direction of dependency**: `Domain` (entities + repository contracts, zero framework dependency) ← `Application` (use-cases/services/policies, orchestrates Domain via its contracts) → `Infrastructure` (Eloquent models + concrete repositories implementing Domain contracts) and `Presentation` (controllers - thin, call Application use-cases only, no direct Eloquent queries or business rules). The React `admin` frontend mirrors this with `admin/src/{domain,application,infrastructure,presentation}`.
- **Every persisted entity gets a matching `Domain/Contracts/<Entity>RepositoryInterface.php`.** Entities carrying real business rules (`Organizer`, `Event`, `PlanPrice`) additionally get an explicit `Domain/Entities/<Entity>.php` plain object holding those rules (approval-state transitions, event-status transitions, append-only pricing). Simple CRUD entities (`Venue`, `Promoter`, `DataExportRequest`, `EventInfoRequest`) keep a thin contract with no separate entity class beyond the Eloquent model, per YAGNI - this is not a layering violation, it's the deliberately minimal form Clean Architecture takes for a table with no behavior beyond storage.
- **No magic numbers/strings**: the Basic-tier cap (`4`), the deletion retention window (`30` days), and every status/enum string are named constants in `backend/app/Domain/Constants/AdminPanelConstants.php` (backend) and `admin/src/domain/constants/adminPanelConstants.ts` (frontend) - see the dedicated constants task below.
- **One class per file**, PHP and TypeScript/TSX alike.
- **No task/ticket-referencing comments in code** (AD-014) - rationale lives in `design.md` and `docs/admin-panel/architecture.md`, not in code comments.
- **Database seeders are excluded from this layering** - they stay at `backend/database/seeders/*.php` as bootstrapping code, not a Clean Architecture layer, but still avoid magic numbers (reuse the same named constants).

---

## Test Coverage Matrix

> Guidelines found: .specs/STATE.md AD-010 (Pest for backend, Jest+RTL for web, Playwright for E2E, GIVEN/WHEN/THEN test names, >=80% coverage) and AD-011 (Conventional Commits, one branch per phase). No existing test files to sample (greenfield backend). A `Screen / UI layout` row is added because admin-panel's visual reference is the live BootstrapDash 'Corona' theme (verified via Playwright MCP, not guessed from static CSS) rather than an in-repo design file.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------- | --------------------- | ----------------- | ----------- |
| Eloquent model / migration | none | - (build gate only) | backend/app/Models/*.php, backend/database/migrations/* | php artisan migrate --pretend |
| Policy (authorization/IDOR) | unit | All branches; 1:1 to spec ACs; every listed edge case (cross-organizer access denial) | backend/tests/Unit/Policies/*Test.php | php artisan test --filter=Policy |
| Service (PublishedEventCounter, etc.) | unit | All branches; 1:1 to spec ACs; every listed edge case (month-boundary/timezone) | backend/tests/Unit/Services/*Test.php | php artisan test --testsuite=Unit |
| Controller / route (feature) | integration | All routes in scope: happy path + every listed edge case + error/failure paths, GIVEN/WHEN/THEN named | backend/tests/Feature/**/*Test.php | php artisan test --testsuite=Feature |
| React component (form/table/dashboard) | unit | All branches; interaction states (loading/error/empty) covered | admin/src/**/__tests__/*.test.tsx | npm --prefix admin test |
| Screen / UI layout | visual | Every screen matched to the BootstrapDash Corona reference: layout + verified color/spacing tokens + element presence confirmed by Playwright screenshot + getComputedStyle comparison | admin/e2e/visual/*.spec.ts (screenshot output alongside) | npx --prefix admin playwright test e2e/visual |
| E2E flow | e2e | Full approval -> publish -> cap -> pricing flow per design.md Test Plan | admin/e2e/*.spec.ts | npx --prefix admin playwright test |
| Database seeder (QA fixtures) | none | - (build gate only): idempotent, covers every enumerated status/state combination named in its task | backend/database/seeders/*.php | php artisan db:seed --class=AdminPanelSeeder |
| Developer documentation | none | - (build gate only): documents the Clean Architecture layering and conventions for this feature | docs/admin-panel/*.md | test -f docs/admin-panel/architecture.md |

## Gate Check Commands

> Generated from AD-010/AD-011 - confirm before Execute once backend/admin scaffolding exists (infrastructure/tasks.md Phase 0).

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After tasks with unit tests only (models, policies, services, React components) | php artisan test --testsuite=Unit && npm --prefix admin test |
| Full | After tasks with integration/e2e/visual tests (controllers, screens) | php artisan test && npm --prefix admin test && npx --prefix admin playwright test |
| Build | After phase completion or config/migration-only tasks | php artisan test && npm --prefix admin run build && npx --prefix admin playwright test |

---

## Execution Plan

Phases are ordered and run sequentially - each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Data models & migrations

One migration+Eloquent model per entity in design.md's Data Models section, plus EventInfoRequest (needed for ADMIN-16, not explicitly named in design.md - added here following the same Controller+Policy pattern as the rest of the feature).

```
T1 -> T2
T1 -> T3
T2 -> T3
T1 -> T4
T3 -> T4
T1 -> T6
T3 -> T7
```

### Phase 2: Auth guards & Super Admin approval

Sanctum organizer/super_admin guards, then the approval gate itself (ADMIN-01..05).

```
T1 -> T8
T8 -> T9
T9 -> T10
```

### Phase 3: Event CRUD, ownership policy, and Basic-tier cap

EventPolicy first (used by every subsequent event endpoint), then the counter service, then the controller, then the cap wired on top.

```
T3 -> T11
T3 -> T12
T11 -> T13
T13 -> T14
T12 -> T14
```

### Phase 4: Venue & promoter management

CRUD for venue presence and promoters, plus event-promoter linking with edit/remove propagation.

```
T8 -> T15
T2 -> T15
T8 -> T16
T4 -> T16
```

### Phase 5: Engagement dashboard & audience interest

Read-only aggregation over stats written by mobile-app/web-app, plus the new audience-interest and info-request surfaces (ADMIN-15/16 - a design gap filled here).

```
T13 -> T17
T17 -> T18
T7 -> T19
T17 -> T19
```

### Phase 6: Plan pricing (AD-006)

Super Admin sets the Plus tier's price with a full append-only history.

```
T8 -> T20
T5 -> T20
```

### Phase 7: LGPD data export & deletion

Organizer self-service export/deletion with Super Admin override, per AD-008 and design.md's Tech Decisions (soft-delete + 30-day retention).

```
T6 -> T21
T2 -> T21
T3 -> T21
T4 -> T21
T21 -> T22
```

### Phase 8: Screen: App shell + Super Admin approval / organizer login

Reference: BootstrapDash 'Corona' modern-vertical theme, verified live via Playwright (dashboard + buttons + forms pages, see plan notes). Sidebar/topbar shell is shared by every subsequent screen phase.

```
T10 -> T23
T23 -> T24
```

### Phase 9: Screen: Event management (list, form, status, cap messaging)

Event CRUD UI backed by T11-T14.

```
T14 -> T25
T23 -> T25
T25 -> T26
```

### Phase 10: Screen: Engagement dashboard & audience interest

Backed by T17-T19.

```
T18 -> T27
T19 -> T27
T23 -> T27
T27 -> T28
```

### Phase 11: Screen: Venue & promoter management

Backed by T15-T16.

```
T15 -> T29
T16 -> T29
T23 -> T29
T29 -> T30
```

### Phase 12: Screen: Plan pricing (Super Admin)

Backed by T20.

```
T20 -> T31
T23 -> T31
T31 -> T32
```

### Phase 13: Screen: LGPD data export & deletion

Backed by T21-T22.

```
T22 -> T33
T23 -> T33
T33 -> T34
```

### Phase 14: QA seeders (event cover images uploaded to MinIO via the real upload endpoint)

Fixture data covering every scenario needed for QA/manual testing across admin-panel's entities. Event cover images are never a bare external URL - they are downloaded from a free-license source and pushed through T13's real event-image upload flow so MinIO/Flysystem storage is exercised exactly as a real organizer upload would be.

```
T1 -> T35
T35 -> T36
T2 -> T36
T13 -> T37
T36 -> T38
T37 -> T38
T3 -> T38
T38 -> T39
T4 -> T39
T5 -> T40
T6 -> T41
T7 -> T41
T38 -> T41
T35 -> T42
T36 -> T42
T37 -> T42
T38 -> T42
T39 -> T42
T40 -> T42
T41 -> T42
```

### Phase 15: Clean Architecture scaffolding: constants & docs (AD-012..AD-014)

Concrete artifacts for the new architecture decisions, not just the convention statement above: named constants (no magic numbers/strings) and the per-stack documentation file.

```
T1 -> T43
T3 -> T43
T5 -> T43
T43 -> T44
```

---

## Task Breakdown

### T1: Organizer migration + model ✅

**What**: Migration and Eloquent model for `Organizer` (orgName, contactName, email unique, phone, passwordHash, planTier enum, approvalState enum, rejectionReason nullable, consentGivenAt, soft-delete `deletedAt`).
**Where**: `backend/database/migrations/xxxx_create_organizers_table.php, backend/app/Infrastructure/Persistence/Eloquent/Organizer.php, backend/app/Domain/Entities/Organizer.php, backend/app/Domain/Contracts/OrganizerRepositoryInterface.php, backend/app/Infrastructure/Persistence/Eloquent/EloquentOrganizerRepository.php`
**Depends on**: None
**Requirement**: ADMIN-01..05 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Migration creates `organizers` table matching design.md's `Organizer` interface exactly, including `SoftDeletes`
- [x] Model casts `approvalState`/`planTier` as enums and exposes a `deletedAt` scope
- [x] `php artisan migrate --pretend` runs without error
- [x] GIVEN Clean Architecture (AD-012) THEN `Domain/Entities/Organizer.php` (plain, framework-agnostic) and `Domain/Contracts/OrganizerRepositoryInterface.php` exist, and the Eloquent model implements that interface via a matching `Infrastructure/Persistence/Eloquent/EloquentOrganizerRepository.php`

**Tests**: none
**Gate**: build

**Commit**: `feat(admin-panel): add Organizer migration and model`

---

### T2: Venue migration + model ✅

**What**: Migration and Eloquent model for `Venue` (organizerId FK, name, description, address, contactInfo, imageUrl nullable), one venue per organizer per current scope.
**Where**: `backend/database/migrations/xxxx_create_venues_table.php, backend/app/Infrastructure/Persistence/Eloquent/Venue.php`
**Depends on**: T1
**Requirement**: ADMIN-13, ADMIN-14 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Migration FKs `organizer_id` to `organizers` with a unique constraint (one venue per organizer)
- [x] Model defines `belongsTo(Organizer::class)`
- [x] `php artisan migrate --pretend` runs without error

**Tests**: none
**Gate**: build

**Commit**: `feat(admin-panel): add Venue migration and model`

---

### T3: Event migration + model ✅

**What**: Migration and Eloquent model for `Event` (organizerId, venueId FKs, title, description, dateTime, location, fullAddress, featuredImageUrl, externalTicketLink, priceType, musicCategory, capacity nullable, ageRange nullable, additionalInfo/accessibilityInfo/eventRules nullable, status enum, publishedAt nullable).
**Where**: `backend/database/migrations/xxxx_create_events_table.php, backend/app/Infrastructure/Persistence/Eloquent/Event.php, backend/app/Domain/Entities/Event.php, backend/app/Domain/Contracts/EventRepositoryInterface.php, backend/app/Infrastructure/Persistence/Eloquent/EloquentEventRepository.php`
**Depends on**: T1, T2
**Requirement**: ADMIN-06..10, ADMIN-28 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Migration matches design.md's `Event` interface field-for-field
- [x] Model casts `status` as an enum with the four values (draft/published/cancelled/closed)
- [x] `php artisan migrate --pretend` runs without error
- [x] GIVEN Clean Architecture (AD-012) THEN `Domain/Entities/Event.php` (plain, framework-agnostic) and `Domain/Contracts/EventRepositoryInterface.php` exist, and the Eloquent model implements that interface via a matching `Infrastructure/Persistence/Eloquent/EloquentEventRepository.php`

**Tests**: none
**Gate**: build

**Commit**: `feat(admin-panel): add Event migration and model`

---

### T4: Promoter + EventPromoter migrations + models ✅

**What**: Migration and model for `Promoter` (organizerId FK, name, phone, email, instagramUrl, tiktokUrl) plus the `EventPromoter` pivot table (eventId, promoterId).
**Where**: `backend/database/migrations/xxxx_create_promoters_table.php, backend/database/migrations/xxxx_create_event_promoter_table.php, backend/app/Infrastructure/Persistence/Eloquent/Promoter.php`
**Depends on**: T1, T3
**Requirement**: ADMIN-17..19 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Promoter migration FKs to `organizers`; pivot table FKs to both `events` and `promoters` with a composite unique key
- [x] Model defines `belongsToMany(Event::class)` via the pivot
- [x] `php artisan migrate --pretend` runs without error

**Tests**: none
**Gate**: build

**Commit**: `feat(admin-panel): add Promoter and EventPromoter migrations and models`

---

### T5: PlanPrice migration + model ✅

**What**: Append-only migration and model for `PlanPrice` (tier, amount in integer cents, effectiveFrom, effectiveTo nullable, setBySuperAdminId) - never updated in place per design.md's Tech Decisions.
**Where**: `backend/database/migrations/xxxx_create_plan_prices_table.php, backend/app/Infrastructure/Persistence/Eloquent/PlanPrice.php, backend/app/Domain/Entities/PlanPrice.php, backend/app/Domain/Contracts/PlanPriceRepositoryInterface.php, backend/app/Infrastructure/Persistence/Eloquent/EloquentPlanPriceRepository.php`
**Depends on**: None
**Requirement**: ADMIN-20..23 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Migration matches design.md's `PlanPrice` interface
- [x] Model has no `update`-in-place helper exposed - only `create` (append-only) is used elsewhere
- [x] `php artisan migrate --pretend` runs without error
- [x] GIVEN Clean Architecture (AD-012) THEN `Domain/Entities/PlanPrice.php` (plain, framework-agnostic) and `Domain/Contracts/PlanPriceRepositoryInterface.php` exist, and the Eloquent model implements that interface via a matching `Infrastructure/Persistence/Eloquent/EloquentPlanPriceRepository.php`

**Spec gap noted**: `set_by_super_admin_id` has no FK constraint - no `super_admins` table exists in any admin-panel task (T8 only configures the guard; Super Admin provisioning is out-of-band per AD-003). Stored as a plain unsigned bigint. Surfaced here for whoever builds the `super_admin` guard's user provider (T8) or later, not fixed as part of this task.

**Tests**: none
**Gate**: build

**Commit**: `feat(admin-panel): add PlanPrice migration and model`

---

### T6: DataExportRequest migration + model ✅

**What**: Migration and model for `DataExportRequest` (organizerId FK, status enum pending/ready/failed, downloadUrl nullable, requestedAt).
**Where**: `backend/database/migrations/xxxx_create_data_export_requests_table.php, backend/app/Infrastructure/Persistence/Eloquent/DataExportRequest.php`
**Depends on**: T1
**Requirement**: ADMIN-24..27 (data foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Migration matches design.md's `DataExportRequest` interface
- [x] Model defines `belongsTo(Organizer::class)`
- [x] `php artisan migrate --pretend` runs without error

**Tests**: none
**Gate**: build

**Commit**: `feat(admin-panel): add DataExportRequest migration and model`

---

### T7: EventInfoRequest migration + model (design gap filled here) ✅

**What**: Migration and model for a consumer-submitted info/update request on an event (eventId FK, consumerUserId, message, organizerResponse nullable, respondedAt nullable) - design.md's Components section doesn't name this entity explicitly; it's required by spec AC ADMIN-16 ('a user submits an info/update request... surfaced to the organizer with the ability to respond') and follows the same FK/ownership pattern as the rest of the feature.
**Where**: `backend/database/migrations/xxxx_create_event_info_requests_table.php, backend/app/Infrastructure/Persistence/Eloquent/EventInfoRequest.php`
**Depends on**: T3
**Requirement**: ADMIN-16 (data foundation, design gap)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Migration FKs `event_id` to `events`
- [x] Model defines `belongsTo(Event::class)` and exposes `respond(string $response)`
- [x] `php artisan migrate --pretend` runs without error

**Spec gap noted**: `consumer_user_id` has no FK constraint - web-app owns the consumer User model and hasn't been executed yet (data-owner-first order per project CLAUDE.md). Stored as a plain unsigned bigint, same pattern as T5's `set_by_super_admin_id` gap.

**Tests**: none
**Gate**: build

**Commit**: `feat(admin-panel): add EventInfoRequest migration and model`

---

### T8: Configure organizer + super_admin Sanctum guards

**What**: Add the two Sanctum guards (`organizer`, `super_admin`) to `config/auth.php`, distinct from the consumer guard used by web-app/mobile-app per AD-002, with HttpOnly/Secure/SameSite cookie session config per AD-008.
**Where**: `backend/config/auth.php`
**Depends on**: T1
**Requirement**: AD-002, AD-008 (foundation for ADMIN-01..05)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `organizer` and `super_admin` guards are defined and distinct from `consumer`
- [ ] Session cookie config sets HttpOnly, Secure, SameSite per AD-008
- [ ] `php artisan config:show auth` reflects both new guards

**Tests**: none
**Gate**: build

**Commit**: `feat(admin-panel): configure organizer and super_admin Sanctum guards`

---

### T9: OrganizerApprovalController + SuperAdminOrganizerPolicy

**What**: List pending organizers, approve, reject (with optional reason), restricted to the `super_admin` guard only.
**Where**: `backend/app/Presentation/Http/Controllers/SuperAdmin/OrganizerApprovalController.php, backend/app/Application/Policies/SuperAdminOrganizerPolicy.php`
**Depends on**: T8
**Requirement**: ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-05

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a super_admin WHEN listing organizers with `state=pending` THEN every pending organizer's signup details are returned - test passes
- [ ] GIVEN a super_admin WHEN approving an organizer THEN its approvalState becomes `approved` - test passes
- [ ] GIVEN a super_admin WHEN rejecting an organizer with a reason THEN approvalState becomes `rejected` and the reason is stored - test passes
- [ ] GIVEN an organizer (not super_admin) WHEN calling any of these endpoints THEN the response is 403 - test passes
- [ ] Gate check passes: `php artisan test --filter=OrganizerApproval`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add OrganizerApprovalController and policy`

---

### T10: Login gate denies pending/rejected organizers

**What**: Wire the organizer login endpoint so a `pending` or `rejected` account is denied access to event/venue/promoter management, shown its current state and rejection reason (if any), and forced to re-authenticate if approved mid-session per spec's Edge Case.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/AuthController.php`
**Depends on**: T9
**Requirement**: ADMIN-04

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a `pending` organizer WHEN attempting to log in THEN management endpoints return 403 with the current state in the response body - test passes
- [ ] GIVEN a `rejected` organizer WHEN attempting to log in THEN the same 403 includes the stored rejection reason - test passes
- [ ] GIVEN an organizer approved while their session was still active THEN their existing session does not silently gain management access without re-authentication - test passes
- [ ] Gate check passes: `php artisan test --filter=OrganizerLoginGate`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): deny management access to pending/rejected organizers at login`

---

### T11: EventPolicy (ownership / IDOR guard) ✅

**What**: Laravel Policy checking every event mutation against the authenticated organizer's own `id`, per AD-008's IDOR guardrail.
**Where**: `backend/app/Application/Policies/EventPolicy.php`
**Depends on**: T3
**Requirement**: ADMIN-10 (ownership enforcement)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN organizer A WHEN attempting to update/delete organizer B's event THEN the policy denies it - test passes
- [x] GIVEN organizer A WHEN acting on their own event THEN the policy allows it - test passes
- [x] Gate check passes: `php artisan test --filter=EventPolicy`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(admin-panel): add EventPolicy for ownership/IDOR enforcement`

---

### T12: PublishedEventCounter service ✅

**What**: Service counting an organizer's `status -> published` transitions within the current calendar month, using UTC storage and the organizer's configured timezone (default America/Sao_Paulo) for the month boundary, per design.md's Risks table.
**Where**: `backend/app/Application/Services/PublishedEventCounter.php`
**Depends on**: T3
**Requirement**: ADMIN-28 (foundation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN 4 events published this calendar month WHEN counting THEN the service returns 4 - test passes
- [x] GIVEN an event published in the last minute of the month in America/Sao_Paulo but the next UTC day THEN it counts toward the correct month - test passes (month-boundary edge case)
- [x] Gate check passes: `php artisan test --filter=PublishedEventCounter`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(admin-panel): add PublishedEventCounter service`

---

### T13: EventController CRUD + status transitions + duplication ✅

**What**: Create/update/delete an event, an explicit status-transition whitelist (draft->published->cancelled/closed, rejecting invalid transitions with 422), and duplication.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/EventController.php`
**Depends on**: T11
**Requirement**: ADMIN-06, ADMIN-07, ADMIN-08, ADMIN-09

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN all required fields (image, date/time, location, ticket link, price type) WHEN creating an event THEN it saves as `draft` - test passes
- [x] GIVEN a required field is missing WHEN attempting to transition to `published` THEN the request is rejected with the missing fields identified - test passes
- [x] GIVEN an invalid transition (e.g. cancelled -> published) THEN the request is rejected with 422 - test passes
- [x] GIVEN an organizer deletes their own event THEN it is removed from all consumer-facing listings - test passes
- [x] GIVEN an organizer duplicates their own event THEN a new `draft` event is created with the same field values - test passes
- [x] Gate check passes: `php artisan test --filter=EventController`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add EventController CRUD and status transitions`

---

### T14: Wire Basic-tier 4-events/month cap into publish transition ✅

**What**: Block a 5th `published` transition within a calendar month for `planTier === "basic"` organizers, returning 422 with an `upgrade_required` error code, using `PublishedEventCounter` from T12.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/EventController.php`
**Depends on**: T13, T12
**Requirement**: ADMIN-28

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN a Basic-tier organizer with 4 published events this month WHEN publishing a 5th THEN the response is 422 with `upgrade_required` - test passes
- [x] GIVEN a Plus-tier organizer with 4+ published events this month WHEN publishing another THEN it succeeds - test passes
- [x] Gate check passes: `php artisan test --filter=EventCap`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): enforce Basic-tier 4-events/month publish cap`

---

### T15: VenueController CRUD

**What**: Create/read/update an organizer's own venue presence (one per organizer).
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/VenueController.php`
**Depends on**: T8, T2
**Requirement**: ADMIN-13, ADMIN-14

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN an organizer WHEN creating/updating their venue THEN the record saves scoped to that organizer - test passes (venue create/delete deliberately out of scope - see design.md's Scope decision; update covered instead, consistent with spec ADMIN-13/14's actual ACs)
- [x] GIVEN organizer A WHEN attempting to update organizer B's venue THEN the response is 403 - test passes
- [x] Gate check passes: `php artisan test --filter=VenueController`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add VenueController CRUD`

---

### T16: PromoterController CRUD + event linking with propagation

**What**: Register/edit/remove promoters and link/unlink them to events, with edits and removals applying to every linked event per spec AC.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/PromoterController.php`
**Depends on**: T8, T4
**Requirement**: ADMIN-17, ADMIN-18, ADMIN-19

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN a promoter linked to 3 events WHEN the organizer edits that promoter THEN all 3 events reflect the change - test passes
- [x] GIVEN a promoter linked to a published event WHEN the organizer removes the promoter THEN the event's promoter list no longer includes them but the event itself is untouched (per spec's Edge Case) - test passes
- [x] GIVEN an event's promoter list WHEN requested THEN every currently-linked promoter is returned - test passes
- [x] Gate check passes: `php artisan test --filter=PromoterController`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add PromoterController CRUD and event linking`

---

### T17: EngagementDashboardController

**What**: Per-event and aggregate stats (views, favorites, ticket-link clicks, interest count), reading `event_stats` rows written by mobile-app/web-app.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/EngagementDashboardController.php`
**Depends on**: T13
**Requirement**: ADMIN-11, ADMIN-12

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN an event with recorded views/favorites/clicks/interest WHEN the organizer requests its dashboard THEN all four counts are returned - test passes
- [ ] GIVEN multiple events WHEN requesting the aggregate view THEN totals sum correctly across the organizer's own events only - test passes
- [ ] Gate check passes: `php artisan test --filter=EngagementDashboard`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add EngagementDashboardController`

---

### T18: AudienceInterestController (design gap filled here)

**What**: List users who marked interest in an event and, where available, mutual friends of an interested user who are also attending - design.md's Components section doesn't name this controller; added following the same read-only-aggregation pattern as EngagementDashboardController.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/AudienceInterestController.php`
**Depends on**: T17
**Requirement**: ADMIN-15 (design gap)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN an event with interested users WHEN the organizer opens its audience view THEN the count and list are returned - test passes
- [ ] GIVEN an interested user with mutual friends attending WHEN their detail is requested THEN those mutual friends are listed - test passes
- [ ] Gate check passes: `php artisan test --filter=AudienceInterest`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add AudienceInterestController`

---

### T19: EventInfoRequestController (design gap filled here) ✅

**What**: Surface consumer-submitted info/update requests (T7's `EventInfoRequest`) to the organizer and let them respond.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/EventInfoRequestController.php`
**Depends on**: T7, T17
**Requirement**: ADMIN-16 (design gap)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN a consumer submits an info request WHEN the organizer lists their event's requests THEN it appears - test passes
- [x] GIVEN an organizer responds to a request THEN the response and timestamp are stored and returned on subsequent reads - test passes
- [x] Gate check passes: `php artisan test --filter=EventInfoRequest`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add EventInfoRequestController`

---

### T20: PlanPricingController

**What**: `GET /super-admin/plan-prices` (full history) and `POST /super-admin/plan-prices` (creates a new current-price row, closes the previous row's `effectiveTo`), super_admin guard only, positive-numeric validation.
**Where**: `backend/app/Presentation/Http/Controllers/SuperAdmin/PlanPricingController.php`
**Depends on**: T8, T5
**Requirement**: ADMIN-20, ADMIN-21, ADMIN-22, ADMIN-23

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN a super_admin sets a new Plus price WHEN reading history THEN the new row appears as current and the previous row's `effectiveTo` is set - test passes
- [x] GIVEN a non-numeric or negative amount WHEN submitted THEN the response is 422 - test passes
- [x] GIVEN an organizer (not super_admin) WHEN calling either endpoint THEN the response is 403 - test passes
- [x] Gate check passes: `php artisan test --filter=PlanPricing`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add PlanPricingController with append-only history`

---

### T21: OrganizerDataController: export ✅

**What**: Queue a Laravel Queue job that generates a downloadable archive of the organizer's own Organizer/Venue/Event/Promoter rows.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/OrganizerDataController.php`
**Depends on**: T6, T2, T3, T4
**Requirement**: ADMIN-24, ADMIN-26

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN an organizer requests a data export WHEN the queued job completes THEN a `DataExportRequest` row moves to `ready` with a `downloadUrl` - test passes
- [x] GIVEN the export archive WHEN inspected THEN it contains only that organizer's own Organizer/Venue/Event/Promoter data - test passes
- [x] Gate check passes: `php artisan test --filter=OrganizerDataExport`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add organizer data export`

---

### T22: OrganizerDataController: account deletion with Super Admin override ✅

**What**: Soft-delete the organizer and cascade-hide (not hard-delete) events/venue/promoters from consumer listings immediately; schedule a hard-delete of personal fields after the 30-day retention window (flagged in design.md as an unconfirmed default). Deletion with an upcoming published event returns 409 requiring `confirm: true` per design.md's Error Handling table. Super Admin can trigger this on an organizer's behalf.
**Where**: `backend/app/Presentation/Http/Controllers/Organizer/OrganizerDataController.php`
**Depends on**: T21
**Requirement**: ADMIN-25, ADMIN-27

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] GIVEN an organizer with no upcoming published events WHEN requesting deletion THEN the account is soft-deleted and its events/venue/promoters are hidden from consumer listings - test passes
- [x] GIVEN an organizer with an upcoming published event WHEN requesting deletion without `confirm: true` THEN the response is 409 - test passes
- [x] GIVEN 30 days have elapsed since soft-delete WHEN the scheduled job runs THEN personal fields are hard-deleted - test passes
- [x] GIVEN a super_admin WHEN triggering deletion on an organizer's behalf THEN the same flow applies - test passes
- [x] Gate check passes: `php artisan test --filter=OrganizerDataDeletion`

**Tests**: integration
**Gate**: full

**Commit**: `feat(admin-panel): add organizer account deletion with retention window`

---

### T23: Build app shell + organizer login/approval-state screen ✅

**What**: Fixed dark sidebar (collapsible) + topbar shell, and the organizer login screen showing pending/rejected state banners, matching the Corona reference's verified tokens.
**Where**: `admin/src/presentation/layouts/AppShell.tsx, admin/src/presentation/pages/Login.tsx`
**Depends on**: T10
**Requirement**: ADMIN-01, ADMIN-04, ADMIN-05

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [x] Sidebar: fixed, `#191c24` surface (verified: dashboard sidebar background), collapses via `all .25s ease-out`; body wrapper is `width: calc(100% - 244px)` when expanded, `100%` under 992px
- [x] Page canvas background `#000` (verified: dashboard `body` background)
- [x] Login form inputs: `#191c24` background, `1px #2c2e33` border, `2px` radius (`rounded-sm`), white text, label `14px/500` white (verified: basic-form.html computed styles)
- [x] Primary submit button: Default-variant Primary - solid `#0090e7` fill, white text, `6px` radius (verified: Buttons reference page + dashboard 'Add' button)
- [x] Pending-state banner: `#ffab00` (warning) pill, `6px` radius, `4px 8px` padding, `12px/500` white text (verified: dashboard 'Pending' badge)
- [x] Rejected-state banner: same pill treatment in `#fc424a` (danger, verified: dashboard 'Failed' badge), shows the rejection reason when present
- [x] Super-admin-only pending-organizers list route is unreachable for the organizer guard (403 surfaces as an in-app message, not a raw error page)

**Tests**: visual
**Gate**: quick

**Commit**: `feat(admin-panel): add app shell and organizer login/approval-state screen`

---

### T24: Verify Screen: App shell + Login/Approval-state against Corona reference ✅

**What**: Navigate the running admin dev build with Playwright, screenshot the login screen and the collapsed/expanded sidebar states, and compare against the Corona reference (dashboard shell + buttons + forms pages already captured this session) using `getComputedStyle` on the same properties sampled from the reference (background colors, border-radius, padding, transition duration).
**Where**: `admin/e2e/visual/login-shell.spec.ts`
**Depends on**: T23
**Requirement**: ADMIN-01, ADMIN-04, ADMIN-05

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [x] Sidebar background computes to `#191c24` and body-wrapper width matches `calc(100% - 244px)` when expanded
- [x] Login input background/border/radius match the verified reference values exactly
- [x] Primary button background matches `#0090e7`; pending/rejected banners match `#ffab00`/`#fc424a` respectively
- [x] Any mismatch is filed as a fix note before this phase is marked done - no silent drift accepted

**Tests**: visual
**Gate**: quick

**Commit**: `test(admin-panel): verify app shell and login screen against Corona reference`

---

### T25: Build event list + event form + status-transition UI

**What**: Event list as a data table, a create/edit form covering every design.md `Event` field, status-transition controls, duplicate action, and the Basic-tier cap warning message.
**Where**: `admin/src/presentation/pages/Events/EventList.tsx, admin/src/presentation/pages/Events/EventForm.tsx`
**Depends on**: T14, T23
**Requirement**: ADMIN-06, ADMIN-07, ADMIN-09, ADMIN-10, ADMIN-28

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Event list rows sit on `#191c24` cards, `6px` radius, no shadow (verified: dashboard stat-card tokens)
- [ ] Status badges (draft/published/cancelled/closed) reuse the verified pill tokens (`6px` radius, `4px 8px` padding, `12px/500` white text) mapped to `#8f5fe8` info / `#00d25b` success / `#fc424a` danger / `#e4eaec` secondary respectively
- [ ] Table header cells: `rgb(108,114,147)` text, `14px/700` (verified: dashboard Order Status table header)
- [ ] Form inputs reuse the T23 input tokens (`#191c24` bg, `#2c2e33` border, `2px` radius)
- [ ] 'Publish'/'Save' actions use the Default Primary button spec; cap-exceeded state shows an `upgrade_required` message using the `#ffab00` warning tint, not a raw error string
- [ ] Duplicate action creates a new draft without navigating away from the list

**Tests**: visual
**Gate**: quick

**Commit**: `feat(admin-panel): add event list, form, and status-transition UI`

---

### T26: Verify Screen: Event management against Corona reference

**What**: Screenshot the event list and form, compare layout/colors/elements against the Corona reference (dashboard cards/tables + buttons + forms pages).
**Where**: `admin/e2e/visual/events.spec.ts`
**Depends on**: T25
**Requirement**: ADMIN-06, ADMIN-07, ADMIN-09, ADMIN-10, ADMIN-28

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Card and table styling matches the verified reference values
- [ ] Status badge colors match the mapped semantic hex values exactly
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(admin-panel): verify event management screen against Corona reference`

---

### T27: Build engagement dashboard + audience/info-request screen

**What**: Per-event and aggregate stat cards (views/favorites/clicks/interest), an interested-users list with mutual-friends detail, and an info-request list with a reply action.
**Where**: `admin/src/presentation/pages/Engagement/Dashboard.tsx, admin/src/presentation/pages/Engagement/Audience.tsx`
**Depends on**: T18, T19, T23
**Requirement**: ADMIN-11, ADMIN-12, ADMIN-15, ADMIN-16

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Stat cards match the verified dashboard card tokens (`#191c24`, `6px` radius, no shadow)
- [ ] Reply action on an info request uses the Default Primary button spec
- [ ] Interested-users list rows follow the same table-header token as the event list (`rgb(108,114,147)`, `14px/700`)

**Tests**: visual
**Gate**: quick

**Commit**: `feat(admin-panel): add engagement dashboard and audience/info-request screen`

---

### T28: Verify Screen: Engagement & audience against Corona reference

**What**: Screenshot the engagement dashboard and audience screen, compare against the Corona reference dashboard-card and table tokens.
**Where**: `admin/e2e/visual/engagement.spec.ts`
**Depends on**: T27
**Requirement**: ADMIN-11, ADMIN-12, ADMIN-15, ADMIN-16

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Stat card and table styling matches the verified reference values
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(admin-panel): verify engagement and audience screen against Corona reference`

---

### T29: Build venue profile + promoter list/form UI

**What**: Venue presence edit form and a promoter table with add/edit/remove actions and per-event linking controls.
**Where**: `admin/src/presentation/pages/Venue/VenueProfile.tsx, admin/src/presentation/pages/Promoters/PromoterList.tsx`
**Depends on**: T15, T16, T23
**Requirement**: ADMIN-13, ADMIN-14, ADMIN-17, ADMIN-18, ADMIN-19

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Form inputs reuse the T23 tokens; promoter table reuses the T25 table-header tokens
- [ ] Edit/Remove row actions use the Outline Button variant (`1px` border, transparent fill, verified on the Buttons reference page) to visually distinguish them from the primary 'Add Promoter' action (Default Primary)
- [ ] Removing a promoter linked to a published event updates the event's promoter list without a page reload

**Tests**: visual
**Gate**: quick

**Commit**: `feat(admin-panel): add venue profile and promoter management UI`

---

### T30: Verify Screen: Venue & promoter management against Corona reference

**What**: Screenshot the venue and promoter screens, compare against the Corona reference form/table/button tokens.
**Where**: `admin/e2e/visual/venue-promoters.spec.ts`
**Depends on**: T29
**Requirement**: ADMIN-13, ADMIN-14, ADMIN-17, ADMIN-18, ADMIN-19

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Form and table styling, and the Outline-vs-Default button distinction, match the verified reference
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(admin-panel): verify venue and promoter screens against Corona reference`

---

### T31: Build plan pricing screen (current price + append-only history)

**What**: Current Plus price stat card, a 'Set new price' form, and an append-only history table.
**Where**: `admin/src/presentation/pages/SuperAdmin/PlanPricing.tsx`
**Depends on**: T20, T23
**Requirement**: ADMIN-20, ADMIN-21, ADMIN-22, ADMIN-23

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Current-price stat card reuses the verified dashboard card tokens
- [ ] History table reuses the verified table-header token
- [ ] 'Save New Price' button uses the Default Primary spec; a non-numeric/negative input shows inline validation using the danger `#fc424a` tint, not a raw browser alert

**Tests**: visual
**Gate**: quick

**Commit**: `feat(admin-panel): add plan pricing screen`

---

### T32: Verify Screen: Plan pricing against Corona reference

**What**: Screenshot the plan pricing screen, compare against the Corona reference card/table/form tokens.
**Where**: `admin/e2e/visual/plan-pricing.spec.ts`
**Depends on**: T31
**Requirement**: ADMIN-20, ADMIN-21, ADMIN-22, ADMIN-23

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Card, table, and form styling match the verified reference
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(admin-panel): verify plan pricing screen against Corona reference`

---

### T33: Build organizer data export/deletion screen

**What**: Export-request button (with pending/ready status display) and an account-deletion flow with the confirm-required warning modal from design.md's Error Handling table.
**Where**: `admin/src/presentation/pages/Account/DataRights.tsx`
**Depends on**: T22, T23
**Requirement**: ADMIN-24, ADMIN-25, ADMIN-26, ADMIN-27

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Export button uses the Default Primary spec; export status pill reuses the verified badge tokens (pending=`#ffab00`, ready=`#00d25b`, failed=`#fc424a`)
- [ ] Delete Account button uses the Danger button variant (verified on the Buttons reference page)
- [ ] Deleting with an upcoming published event shows a confirmation modal (not a silent 409) before resubmitting with `confirm: true`

**Tests**: visual
**Gate**: quick

**Commit**: `feat(admin-panel): add organizer data export/deletion screen`

---

### T34: Verify Screen: LGPD data export/deletion against Corona reference

**What**: Screenshot the data-rights screen, compare against the Corona reference badge/button tokens.
**Where**: `admin/e2e/visual/data-rights.spec.ts`
**Depends on**: T33
**Requirement**: ADMIN-24, ADMIN-25, ADMIN-26, ADMIN-27

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Status pill and Danger button styling match the verified reference
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(admin-panel): verify LGPD data export/deletion screen against Corona reference`

---

### T35: OrganizerSeeder (every approval-state x tier combination)

**What**: Seed organizers covering every `approvalState` (pending/approved/rejected) x `planTier` (basic/plus) combination, plus one Basic-tier organizer already at the 4-published-events monthly cap (for ADMIN-28 QA) and one `rejected` organizer with a stored rejection reason (for ADMIN-03/04 QA).
**Where**: `backend/database/seeders/OrganizerSeeder.php`
**Depends on**: T1
**Requirement**: ADMIN-01..05, ADMIN-28 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN the seeder runs THEN at least one organizer exists for each of the 6 approvalState x planTier combinations
- [ ] One seeded Basic-tier organizer has exactly 4 `published` events already this calendar month (cap-boundary QA)
- [ ] One seeded `rejected` organizer has a non-null `rejectionReason`
- [ ] `php artisan db:seed --class=OrganizerSeeder` exits 0 and is re-runnable (idempotent via `firstOrCreate`/truncate-and-reseed, not duplicate rows on a second run)

**Tests**: none
**Gate**: build

**Commit**: `test(admin-panel): add OrganizerSeeder for QA scenarios`

---

### T36: VenueSeeder

**What**: One venue per `approved` organizer seeded by T35.
**Where**: `backend/database/seeders/VenueSeeder.php`
**Depends on**: T35, T2
**Requirement**: ADMIN-13, ADMIN-14 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Every `approved` organizer from T35 has exactly one venue after seeding
- [ ] `php artisan db:seed --class=VenueSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(admin-panel): add VenueSeeder for QA scenarios`

---

### T37: EventCoverImageSeeder (real upload, not a bare URL)

**What**: Downloads a small set of free-license, platform-appropriate live-music/concert cover images (e.g. from Unsplash's or Pexels' free-to-use API/collections - both explicitly allow commercial use without attribution) into a local seeder fixture directory, then uploads each one through T13's actual event-image upload endpoint (multipart/form-data POST, not a direct DB write) so every image is stored in MinIO via Flysystem exactly as a real organizer's upload would be. Returns the resulting stored `featuredImageUrl` values for T39's EventSeeder to consume.
**Where**: `backend/database/seeders/support/EventCoverImageSeeder.php`
**Depends on**: T13
**Reuses**: T13's EventController image-upload endpoint - this seeder is a real HTTP client of that endpoint, not a shortcut around it
**Requirement**: ADMIN-06 (QA fixtures - featuredImageUrl)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least 6 distinct cover images are downloaded from a free-license source and uploaded through the real endpoint
- [ ] Every resulting `Event.featuredImageUrl` value points to a MinIO-hosted object (verifiable via the MinIO console/API), never the original external source URL
- [ ] Re-running the seeder does not re-download/re-upload images that already exist in MinIO (idempotent by content hash or a seeded-marker check)
- [ ] `php artisan db:seed --class=EventCoverImageSeeder` exits 0

**Tests**: none
**Gate**: build

**Commit**: `test(admin-panel): add EventCoverImageSeeder uploading real images to MinIO`

---

### T38: EventSeeder (every status x price-type combination)

**What**: Seed events across every `status` (draft/published/cancelled/closed) and `priceType` (free/paid), some with `capacity`/`ageRange` set and some left null, using T37's real MinIO-hosted image URLs for `featuredImageUrl` - never a placeholder or external URL.
**Where**: `backend/database/seeders/EventSeeder.php`
**Depends on**: T36, T37, T3
**Requirement**: ADMIN-06..10, ADMIN-28 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least one event exists for each of the 4 status values and both price types
- [ ] Every seeded event's `featuredImageUrl` is one of T37's real MinIO-uploaded URLs
- [ ] The Basic-tier at-cap organizer from T35 has exactly 4 `published` events dated within the current calendar month
- [ ] `php artisan db:seed --class=EventSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(admin-panel): add EventSeeder for QA scenarios`

---

### T39: PromoterSeeder + event-promoter linking

**What**: Seed promoters and link some of them to published events seeded by T38.
**Where**: `backend/database/seeders/PromoterSeeder.php`
**Depends on**: T38, T4
**Requirement**: ADMIN-17..19 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least 2 promoters exist, each linked to at least one published event
- [ ] At least one promoter is linked to more than one event (for the edit-propagation QA scenario)
- [ ] `php artisan db:seed --class=PromoterSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(admin-panel): add PromoterSeeder for QA scenarios`

---

### T40: PlanPriceSeeder (historical + current)

**What**: Seed at least two `PlanPrice` rows for the Plus tier - one closed-out historical row (`effectiveTo` set) and one current row (`effectiveTo` null) - for price-history QA.
**Where**: `backend/database/seeders/PlanPriceSeeder.php`
**Depends on**: T5
**Requirement**: ADMIN-20..23 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] At least 2 PlanPrice rows exist for tier=plus, exactly one with `effectiveTo` null (current)
- [ ] `php artisan db:seed --class=PlanPriceSeeder` exits 0 and is idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(admin-panel): add PlanPriceSeeder for QA scenarios`

---

### T41: DataExportRequestSeeder + EventInfoRequestSeeder

**What**: Seed one `DataExportRequest` per status (pending/ready/failed) and one `EventInfoRequest` per state (unresponded/responded) for LGPD and audience-request screen QA.
**Where**: `backend/database/seeders/DataExportRequestSeeder.php, backend/database/seeders/EventInfoRequestSeeder.php`
**Depends on**: T6, T7, T38
**Requirement**: ADMIN-16, ADMIN-24..27 (QA fixtures)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] One DataExportRequest exists per status value
- [ ] One EventInfoRequest exists unresponded and one exists responded (with `organizerResponse` set)
- [ ] Both seeders exit 0 and are idempotent

**Tests**: none
**Gate**: build

**Commit**: `test(admin-panel): add DataExportRequestSeeder and EventInfoRequestSeeder`

---

### T42: AdminPanelSeeder (orchestrator)

**What**: Master seeder calling T35-T41 in FK-safe order (Organizer -> Venue -> [image upload] -> Event -> Promoter, PlanPrice, DataExportRequest/EventInfoRequest), registered so `php artisan db:seed` picks it up.
**Where**: `backend/database/seeders/AdminPanelSeeder.php`
**Depends on**: T35, T36, T37, T38, T39, T40, T41
**Requirement**: ADMIN-01..28 (QA fixtures, orchestration)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `php artisan db:seed --class=AdminPanelSeeder` runs all 7 seeders in FK-safe order with no foreign-key errors
- [ ] Running it twice in a row does not create duplicate rows or fail
- [ ] Registered in `DatabaseSeeder::run()` before web-app's seeder (see infrastructure/tasks.md's master seeding task) since web-app's Favorite/EventInterest rows reference these Event rows

**Tests**: none
**Gate**: build

**Commit**: `test(admin-panel): add AdminPanelSeeder orchestrator`

---

### T43: AdminPanelConstants (backend + frontend, no magic numbers/strings)

**What**: Named constants replacing every magic literal used across this feature's tasks: `BASIC_TIER_MONTHLY_EVENT_CAP = 4`, `DELETION_RETENTION_DAYS = 30`, and the `approvalState`/`planTier`/event-`status` enum string values.
**Where**: `backend/app/Domain/Constants/AdminPanelConstants.php, admin/src/domain/constants/adminPanelConstants.ts`
**Depends on**: T1, T3, T5
**Requirement**: AD-013 (code quality)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `BASIC_TIER_MONTHLY_EVENT_CAP`, `DELETION_RETENTION_DAYS`, and every approvalState/planTier/event-status string are defined exactly once, backend and frontend
- [ ] T14 (Basic-tier cap enforcement) and T22 (account deletion) reference these constants instead of the literals `4`/`30`
- [ ] No other task in this file's Done-when reintroduces a bare `4` or `30` for these same concepts once this task lands

**Tests**: none
**Gate**: build

**Commit**: `refactor(admin-panel): extract named constants for cap/retention/status values`

---

### T44: docs/admin-panel/architecture.md

**What**: Markdown write-up of this feature's Clean Architecture layering (AD-012) and coding conventions (AD-013), for anyone browsing the `backend`/`admin` source without `.specs/` context - restates this file's Coding Conventions block and design.md's Architecture Overview in prose, with a short per-layer example drawn from the Event flow.
**Where**: `docs/admin-panel/architecture.md`
**Depends on**: T43
**Requirement**: AD-014 (documentation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Doc explains all 4 layers (Domain/Application/Infrastructure/Presentation) with one concrete example path per layer from this feature
- [ ] Doc states the no-magic-numbers, one-class-per-file, and no-task-comments rules
- [ ] Doc is committed under `docs/admin-panel/`, not scattered as code comments

**Tests**: none
**Gate**: build

**Commit**: `docs(admin-panel): add architecture.md documenting Clean Architecture layering`

---

## Phase Execution Map

Visual representation of task ordering. Phases run in sequence, and tasks within a phase run in order:

```
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6 -> Phase 7 -> Phase 8 -> Phase 9 -> Phase 10 -> Phase 11 -> Phase 12 -> Phase 13 -> Phase 14 -> Phase 15

Phase 1:  T1 ------> T2
Phase 1:  T1 ------> T3
Phase 1:  T2 ------> T3
Phase 1:  T1 ------> T4
Phase 1:  T3 ------> T4
Phase 1:  T1 ------> T6
Phase 1:  T3 ------> T7
Phase 2:  T1 ------> T8
Phase 2:  T8 ------> T9
Phase 2:  T9 ------> T10
Phase 3:  T3 ------> T11
Phase 3:  T3 ------> T12
Phase 3:  T11 ------> T13
Phase 3:  T13 ------> T14
Phase 3:  T12 ------> T14
Phase 4:  T8 ------> T15
Phase 4:  T2 ------> T15
Phase 4:  T8 ------> T16
Phase 4:  T4 ------> T16
Phase 5:  T13 ------> T17
Phase 5:  T17 ------> T18
Phase 5:  T7 ------> T19
Phase 5:  T17 ------> T19
Phase 6:  T8 ------> T20
Phase 6:  T5 ------> T20
Phase 7:  T6 ------> T21
Phase 7:  T2 ------> T21
Phase 7:  T3 ------> T21
Phase 7:  T4 ------> T21
Phase 7:  T21 ------> T22
Phase 8:  T10 ------> T23
Phase 8:  T23 ------> T24
Phase 9:  T14 ------> T25
Phase 9:  T23 ------> T25
Phase 9:  T25 ------> T26
Phase 10:  T18 ------> T27
Phase 10:  T19 ------> T27
Phase 10:  T23 ------> T27
Phase 10:  T27 ------> T28
Phase 11:  T15 ------> T29
Phase 11:  T16 ------> T29
Phase 11:  T23 ------> T29
Phase 11:  T29 ------> T30
Phase 12:  T20 ------> T31
Phase 12:  T23 ------> T31
Phase 12:  T31 ------> T32
Phase 13:  T22 ------> T33
Phase 13:  T23 ------> T33
Phase 13:  T33 ------> T34
Phase 14:  T1 ------> T35
Phase 14:  T35 ------> T36
Phase 14:  T2 ------> T36
Phase 14:  T13 ------> T37
Phase 14:  T36 ------> T38
Phase 14:  T37 ------> T38
Phase 14:  T3 ------> T38
Phase 14:  T38 ------> T39
Phase 14:  T4 ------> T39
Phase 14:  T5 ------> T40
Phase 14:  T6 ------> T41
Phase 14:  T7 ------> T41
Phase 14:  T38 ------> T41
Phase 14:  T35 ------> T42
Phase 14:  T36 ------> T42
Phase 14:  T37 ------> T42
Phase 14:  T38 ------> T42
Phase 14:  T39 ------> T42
Phase 14:  T40 ------> T42
Phase 14:  T41 ------> T42
Phase 15:  T1 ------> T43
Phase 15:  T3 ------> T43
Phase 15:  T5 ------> T43
Phase 15:  T43 ------> T44
```

Execution is strictly sequential - there is no intra-phase parallelism. A single agent (or batch worker) works one task at a time, in order.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1: Organizer migration + model | 1 model + 1 migration (cohesive) | ✅ Granular |
| T2: Venue migration + model | 1 model + 1 migration | ✅ Granular |
| T3: Event migration + model | 1 model + 1 migration | ✅ Granular |
| T4: Promoter + EventPromoter migrations + models | 2 migrations + 1 model (cohesive - one pivot relationship) | ✅ Granular |
| T5: PlanPrice migration + model | 1 model + 1 migration | ✅ Granular |
| T6: DataExportRequest migration + model | 1 model + 1 migration | ✅ Granular |
| T7: EventInfoRequest migration + model (design gap filled here) | 1 model + 1 migration | ✅ Granular |
| T8: Configure organizer + super_admin Sanctum guards | 1 file | ✅ Granular |
| T9: OrganizerApprovalController + SuperAdminOrganizerPolicy | 1 controller + 1 policy (cohesive) | ✅ Granular |
| T10: Login gate denies pending/rejected organizers | 1 file | ✅ Granular |
| T11: EventPolicy (ownership / IDOR guard) | 1 file | ✅ Granular |
| T12: PublishedEventCounter service | 1 file | ✅ Granular |
| T13: EventController CRUD + status transitions + duplication | 1 file | ✅ Granular |
| T14: Wire Basic-tier 4-events/month cap into publish transition | 1 file (modifies T13's controller) | ✅ Granular |
| T15: VenueController CRUD | 1 file | ✅ Granular |
| T16: PromoterController CRUD + event linking with propagation | 1 file | ✅ Granular |
| T17: EngagementDashboardController | 1 file | ✅ Granular |
| T18: AudienceInterestController (design gap filled here) | 1 file | ✅ Granular |
| T19: EventInfoRequestController (design gap filled here) | 1 file | ✅ Granular |
| T20: PlanPricingController | 1 file | ✅ Granular |
| T21: OrganizerDataController: export | 1 file | ✅ Granular |
| T22: OrganizerDataController: account deletion with Super Admin override | 1 file (modifies T21's controller) | ✅ Granular |
| T23: Build app shell + organizer login/approval-state screen | 2 files (cohesive - shell + the one screen that uses it first) | ✅ Granular |
| T24: Verify Screen: App shell + Login/Approval-state against Corona reference | 1 file | ✅ Granular |
| T25: Build event list + event form + status-transition UI | 2 files (cohesive - list + form share the same screen flow) | ✅ Granular |
| T26: Verify Screen: Event management against Corona reference | 1 file | ✅ Granular |
| T27: Build engagement dashboard + audience/info-request screen | 2 files (cohesive - dashboard + audience share the engagement flow) | ✅ Granular |
| T28: Verify Screen: Engagement & audience against Corona reference | 1 file | ✅ Granular |
| T29: Build venue profile + promoter list/form UI | 2 files (cohesive - venue + promoter share the presence-management flow) | ✅ Granular |
| T30: Verify Screen: Venue & promoter management against Corona reference | 1 file | ✅ Granular |
| T31: Build plan pricing screen (current price + append-only history) | 1 file | ✅ Granular |
| T32: Verify Screen: Plan pricing against Corona reference | 1 file | ✅ Granular |
| T33: Build organizer data export/deletion screen | 1 file | ✅ Granular |
| T34: Verify Screen: LGPD data export/deletion against Corona reference | 1 file | ✅ Granular |
| T35: OrganizerSeeder (every approval-state x tier combination) | 1 file | ✅ Granular |
| T36: VenueSeeder | 1 file | ✅ Granular |
| T37: EventCoverImageSeeder (real upload, not a bare URL) | 1 file | ✅ Granular |
| T38: EventSeeder (every status x price-type combination) | 1 file | ✅ Granular |
| T39: PromoterSeeder + event-promoter linking | 1 file | ✅ Granular |
| T40: PlanPriceSeeder (historical + current) | 1 file | ✅ Granular |
| T41: DataExportRequestSeeder + EventInfoRequestSeeder | 2 files (cohesive - both are small per-status fixture seeders for the same LGPD/audience QA pass) | ✅ Granular |
| T42: AdminPanelSeeder (orchestrator) | 1 file | ✅ Granular |
| T43: AdminPanelConstants (backend + frontend, no magic numbers/strings) | 2 files (cohesive - one constants set for the one feature, backend + frontend mirror) | ✅ Granular |
| T44: docs/admin-panel/architecture.md | 1 file | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ----------------------- | -------------- | ------ |
| T1 | None | None | ✅ Match |
| T2 | T1 | T1 | ✅ Match |
| T3 | T1, T2 | T1, T2 | ✅ Match |
| T4 | T1, T3 | T1, T3 | ✅ Match |
| T5 | None | None | ✅ Match |
| T6 | T1 | T1 | ✅ Match |
| T7 | T3 | T3 | ✅ Match |
| T8 | T1 | T1 | ✅ Match |
| T9 | T8 | T8 | ✅ Match |
| T10 | T9 | T9 | ✅ Match |
| T11 | T3 | T3 | ✅ Match |
| T12 | T3 | T3 | ✅ Match |
| T13 | T11 | T11 | ✅ Match |
| T14 | T13, T12 | T13, T12 | ✅ Match |
| T15 | T8, T2 | T8, T2 | ✅ Match |
| T16 | T8, T4 | T8, T4 | ✅ Match |
| T17 | T13 | T13 | ✅ Match |
| T18 | T17 | T17 | ✅ Match |
| T19 | T7, T17 | T7, T17 | ✅ Match |
| T20 | T8, T5 | T8, T5 | ✅ Match |
| T21 | T6, T2, T3, T4 | T6, T2, T3, T4 | ✅ Match |
| T22 | T21 | T21 | ✅ Match |
| T23 | T10 | T10 | ✅ Match |
| T24 | T23 | T23 | ✅ Match |
| T25 | T14, T23 | T14, T23 | ✅ Match |
| T26 | T25 | T25 | ✅ Match |
| T27 | T18, T19, T23 | T18, T19, T23 | ✅ Match |
| T28 | T27 | T27 | ✅ Match |
| T29 | T15, T16, T23 | T15, T16, T23 | ✅ Match |
| T30 | T29 | T29 | ✅ Match |
| T31 | T20, T23 | T20, T23 | ✅ Match |
| T32 | T31 | T31 | ✅ Match |
| T33 | T22, T23 | T22, T23 | ✅ Match |
| T34 | T33 | T33 | ✅ Match |
| T35 | T1 | T1 | ✅ Match |
| T36 | T35, T2 | T35, T2 | ✅ Match |
| T37 | T13 | T13 | ✅ Match |
| T38 | T36, T37, T3 | T36, T37, T3 | ✅ Match |
| T39 | T38, T4 | T38, T4 | ✅ Match |
| T40 | T5 | T5 | ✅ Match |
| T41 | T6, T7, T38 | T6, T7, T38 | ✅ Match |
| T42 | T35, T36, T37, T38, T39, T40, T41 | T35, T36, T37, T38, T39, T40, T41 | ✅ Match |
| T43 | T1, T3, T5 | T1, T3, T5 | ✅ Match |
| T44 | T43 | T43 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | ---------------------------- | ---------------- | ---------- | ------ |
| T1: Organizer migration + model | Eloquent model / migration | none | none | ✅ OK |
| T2: Venue migration + model | Eloquent model / migration | none | none | ✅ OK |
| T3: Event migration + model | Eloquent model / migration | none | none | ✅ OK |
| T4: Promoter + EventPromoter migrations + models | Eloquent model / migration | none | none | ✅ OK |
| T5: PlanPrice migration + model | Eloquent model / migration | none | none | ✅ OK |
| T6: DataExportRequest migration + model | Eloquent model / migration | none | none | ✅ OK |
| T7: EventInfoRequest migration + model (design gap filled here) | Eloquent model / migration | none | none | ✅ OK |
| T8: Configure organizer + super_admin Sanctum guards | Eloquent model / migration | none | none | ✅ OK |
| T9: OrganizerApprovalController + SuperAdminOrganizerPolicy | Controller / route (feature) | integration | integration | ✅ OK |
| T10: Login gate denies pending/rejected organizers | Controller / route (feature) | integration | integration | ✅ OK |
| T11: EventPolicy (ownership / IDOR guard) | Policy (authorization/IDOR) | unit | unit | ✅ OK |
| T12: PublishedEventCounter service | Service (PublishedEventCounter, etc.) | unit | unit | ✅ OK |
| T13: EventController CRUD + status transitions + duplication | Controller / route (feature) | integration | integration | ✅ OK |
| T14: Wire Basic-tier 4-events/month cap into publish transition | Controller / route (feature) | integration | integration | ✅ OK |
| T15: VenueController CRUD | Controller / route (feature) | integration | integration | ✅ OK |
| T16: PromoterController CRUD + event linking with propagation | Controller / route (feature) | integration | integration | ✅ OK |
| T17: EngagementDashboardController | Controller / route (feature) | integration | integration | ✅ OK |
| T18: AudienceInterestController (design gap filled here) | Controller / route (feature) | integration | integration | ✅ OK |
| T19: EventInfoRequestController (design gap filled here) | Controller / route (feature) | integration | integration | ✅ OK |
| T20: PlanPricingController | Controller / route (feature) | integration | integration | ✅ OK |
| T21: OrganizerDataController: export | Controller / route (feature) | integration | integration | ✅ OK |
| T22: OrganizerDataController: account deletion with Super Admin override | Controller / route (feature) | integration | integration | ✅ OK |
| T23: Build app shell + organizer login/approval-state screen | React component (form/table/dashboard) | visual | visual | ✅ OK |
| T24: Verify Screen: App shell + Login/Approval-state against Corona reference | Screen / UI layout | visual | visual | ✅ OK |
| T25: Build event list + event form + status-transition UI | React component (form/table/dashboard) | visual | visual | ✅ OK |
| T26: Verify Screen: Event management against Corona reference | Screen / UI layout | visual | visual | ✅ OK |
| T27: Build engagement dashboard + audience/info-request screen | React component (form/table/dashboard) | visual | visual | ✅ OK |
| T28: Verify Screen: Engagement & audience against Corona reference | Screen / UI layout | visual | visual | ✅ OK |
| T29: Build venue profile + promoter list/form UI | React component (form/table/dashboard) | visual | visual | ✅ OK |
| T30: Verify Screen: Venue & promoter management against Corona reference | Screen / UI layout | visual | visual | ✅ OK |
| T31: Build plan pricing screen (current price + append-only history) | React component (form/table/dashboard) | visual | visual | ✅ OK |
| T32: Verify Screen: Plan pricing against Corona reference | Screen / UI layout | visual | visual | ✅ OK |
| T33: Build organizer data export/deletion screen | React component (form/table/dashboard) | visual | visual | ✅ OK |
| T34: Verify Screen: LGPD data export/deletion against Corona reference | Screen / UI layout | visual | visual | ✅ OK |
| T35: OrganizerSeeder (every approval-state x tier combination) | Eloquent model / migration | none | none | ✅ OK |
| T36: VenueSeeder | Eloquent model / migration | none | none | ✅ OK |
| T37: EventCoverImageSeeder (real upload, not a bare URL) | Eloquent model / migration | none | none | ✅ OK |
| T38: EventSeeder (every status x price-type combination) | Eloquent model / migration | none | none | ✅ OK |
| T39: PromoterSeeder + event-promoter linking | Eloquent model / migration | none | none | ✅ OK |
| T40: PlanPriceSeeder (historical + current) | Eloquent model / migration | none | none | ✅ OK |
| T41: DataExportRequestSeeder + EventInfoRequestSeeder | Eloquent model / migration | none | none | ✅ OK |
| T42: AdminPanelSeeder (orchestrator) | Eloquent model / migration | none | none | ✅ OK |
| T43: AdminPanelConstants (backend + frontend, no magic numbers/strings) | Eloquent model / migration | none | none | ✅ OK |
| T44: docs/admin-panel/architecture.md | Developer documentation | none | none | ✅ OK |

---

## Tools & Skills for Execution

**Available MCPs for these tasks**: Playwright MCP (`mcp__plugin_playwright_playwright__*`) for screen tasks (reference-site navigation, computed-style extraction, screenshots) and their paired verification tasks; NONE for backend tasks.

**Available Skills for these tasks**: NONE

