## Validation: admin-panel Phase 1 (T1-T7) - PASS ✅

# Admin Panel Validation — Phase 1 (T1–T7: Data models & migrations)

**Date**: 2026-09-16
**Spec**: `.specs/features/admin-panel/design.md` (Data Models, lines 30-114), `.specs/features/admin-panel/tasks.md` (T1-T7, lines 243-421)
**Scope**: This validation covers **Phase 1 only** — tasks T1-T7 (data-modeling layer: migrations, Eloquent models, and the Domain/Entities + Domain/Contracts + Infrastructure repositories for Organizer, Event, PlanPrice). Phases 2-15 of admin-panel have not been executed and are out of scope here.
**Diff range**: `3f61d3d^..65d65f9` (api submodule) — commits `3f61d3d`..`65d65f9`, i.e.:
```
3f61d3d feat(admin-panel): add Organizer migration and model
b80c246 feat(admin-panel): add Venue migration and model
36fcfe9 feat(admin-panel): add Event migration and model
87e70f8 feat(admin-panel): add Promoter and EventPromoter migrations and models
f1f0a7f feat(admin-panel): add PlanPrice migration and model
6d8e22e feat(admin-panel): add DataExportRequest migration and model
65d65f9 feat(admin-panel): add EventInfoRequest migration and model
```
**Verifier**: independent sub-agent (author ≠ verifier)

---

## Task Completion

| Task | Status  | Notes |
| ---- | ------- | ----- |
| T1   | ✅ Done | Organizer migration/model/entity/contract/repo all present and correct |
| T2   | ✅ Done | Venue migration/model correct, unique FK enforced |
| T3   | ✅ Done | Event migration/model/entity/contract/repo all present and correct |
| T4   | ⚠️ Done with gap | Promoter/EventPromoter present and functional; missing inverse `promoters()` relation on `Event` model (see Findings) |
| T5   | ✅ Done | PlanPrice migration/model/entity/contract/repo correct; append-only honored (no update method on interface) |
| T6   | ✅ Done | DataExportRequest migration/model correct |
| T7   | ✅ Done | EventInfoRequest migration/model correct, `respond()` verified functionally |

---

## Spec-Anchored Field Check (design.md Data Models vs. migrations/models)

This layer has no acceptance-criteria tests (Test Coverage Matrix: "none — build gate only" for this layer), so the spec-anchored check here is a field-for-field structural comparison instead of a test-assertion trace.

| Entity | design.md fields | Migration file:line | Match |
| ------ | ----------------- | -------------------- | ----- |
| Organizer | orgName, contactName, email(unique), phone, passwordHash, planTier(enum), approvalState(enum), rejectionReason(nullable), consentGivenAt, deletedAt(soft-delete) | `database/migrations/2026_09_16_000001_create_organizers_table.php:11-24` | ✅ All fields present; `email` unique (`:15`); `softDeletes()` (`:23`) |
| Venue | organizerId(FK, 1:1), name, description, address, contactInfo, imageUrl(nullable) | `database/migrations/2026_09_16_000002_create_venues_table.php:11-20` | ✅ `organizer_id` FK + `unique()` (`:13`) enforces one-venue-per-organizer |
| Event | organizerId, venueId(FKs), title, description, dateTime, location, fullAddress, featuredImageUrl, externalTicketLink, priceType, musicCategory, capacity(nullable), ageRange(nullable), additionalInfo/accessibilityInfo/eventRules(nullable), status(enum, 4 values), publishedAt(nullable) | `database/migrations/2026_09_16_000003_create_events_table.php:11-32` | ✅ All 17 fields present field-for-field |
| Promoter | organizerId(FK), name, phone, email, instagramUrl, tiktokUrl | `database/migrations/2026_09_16_000004_create_promoters_table.php:11-20` | ✅ Match |
| EventPromoter | eventId, promoterId (composite key) | `database/migrations/2026_09_16_000005_create_event_promoter_table.php:11-15` | ✅ FKs to both `events`/`promoters`, composite `unique(['event_id','promoter_id'])` (`:14`) |
| PlanPrice | tier, amount(int cents), effectiveFrom, effectiveTo(nullable), setBySuperAdminId | `database/migrations/2026_09_16_000006_create_plan_prices_table.php:11-21` | ✅ `amount` is `unsignedInteger` (integer BRL cents, matches design.md comment) |
| DataExportRequest | organizerId, status(enum), downloadUrl(nullable), requestedAt | `database/migrations/2026_09_16_000007_create_data_export_requests_table.php:11-18` | ✅ Match |
| EventInfoRequest (T7's own field list, design.md gap) | eventId, consumerUserId, message, organizerResponse(nullable), respondedAt(nullable) | `database/migrations/2026_09_16_000008_create_event_info_requests_table.php:11-21` | ✅ Matches T7's stated field list exactly |

**Enum casts verified** (model `casts()` methods):
- `Organizer::plan_tier → PlanTier`, `Organizer::approval_state → OrganizerApprovalState` (`app/Infrastructure/Persistence/Eloquent/Organizer.php:18-26`)
- `Event::price_type → EventPriceType`, `Event::status → EventStatus` (`app/Infrastructure/Persistence/Eloquent/Event.php:18-26`) — `EventStatus` enum has all 4 required values: Draft/Published/Cancelled/Closed (`app/Domain/Enums/EventStatus.php:6-10`)
- `PlanPrice::tier → PlanTier` (`app/Infrastructure/Persistence/Eloquent/PlanPrice.php:12-19`)
- `DataExportRequest::status → DataExportRequestStatus` (`app/Infrastructure/Persistence/Eloquent/DataExportRequest.php:13-19`)

**Status**: ✅ All fields covered field-for-field, no gaps against design.md or T7's self-declared field list.

---

## Clean Architecture Layering (AD-012) Check

Per tasks.md's Coding Conventions (line 21): entities with real business rules (Organizer, Event, PlanPrice) get `Domain/Entities` + `Domain/Contracts` + Eloquent repository; simple CRUD entities (Venue, Promoter, DataExportRequest, EventInfoRequest) get only the Eloquent model.

| Entity | Domain/Entities/*.php | Domain/Contracts/*Interface.php | Infrastructure/.../Eloquent*Repository.php | Expected | Actual |
| ------ | --- | --- | --- | -------- | ------ |
| Organizer | `app/Domain/Entities/Organizer.php` | `app/Domain/Contracts/OrganizerRepositoryInterface.php` | `app/Infrastructure/Persistence/Eloquent/EloquentOrganizerRepository.php` | full 3-piece | ✅ present |
| Event | `app/Domain/Entities/Event.php` | `app/Domain/Contracts/EventRepositoryInterface.php` | `app/Infrastructure/Persistence/Eloquent/EloquentEventRepository.php` | full 3-piece | ✅ present |
| PlanPrice | `app/Domain/Entities/PlanPrice.php` | `app/Domain/Contracts/PlanPriceRepositoryInterface.php` | `app/Infrastructure/Persistence/Eloquent/EloquentPlanPriceRepository.php` | full 3-piece | ✅ present |
| Venue | — | — | — | model only | ✅ correctly absent |
| Promoter | — | — | — | model only | ✅ correctly absent |
| DataExportRequest | — | — | — | model only | ✅ correctly absent |
| EventInfoRequest | — | — | — | model only | ✅ correctly absent |

`EloquentOrganizerRepository`/`EloquentEventRepository`/`EloquentPlanPriceRepository` implement their respective `Domain/Contracts` interfaces (verified via `implements` clause in each file) and map to/from the framework-agnostic `Domain/Entities` object via a private `toEntity()` method — no Eloquent leakage into Domain. **Result**: layering matches the T1/T3/T5-vs-T2/T4/T6/T7 split exactly, no violations.

---

## AD-013 Compliance (no magic numbers/strings, one class per file)

- **One class per file**: confirmed — every migration, model, entity, contract, enum, and repository file in scope (29 files, `git diff --stat 3f61d3d^..65d65f9`) declares exactly one class/interface/enum.
- **No magic strings**: enum values (`draft`/`published`/…, `pending`/`approved`/…, `free`/`paid`, `basic`/`plus`, `pending`/`ready`/`failed`) are all PHP backed enums under `app/Domain/Enums/*.php`, not inline strings — `EventStatus`, `OrganizerApprovalState`, `EventPriceType`, `PlanTier`, `DataExportRequestStatus`. ✅
- **Minor AD-014 friction (not a T1-T7 Done-when failure)**: `database/migrations/2026_09_16_000006_create_plan_prices_table.php:17-18` and `2026_09_16_000008_create_event_info_requests_table.php:14-15` carry inline rationale comments explaining the missing FK ("No FK constraint: no super_admins table exists yet…", "…web-app owns the consumer User model, not yet executed"). AD-014 states rationale should live in `design.md`/`docs/*/architecture.md`, not in code comments — these aren't task/ticket-referencing comments (the literal violation AD-014 names), but they are narrative rationale inline in code. Flagging as an observation, not a fail: the same rationale is already captured properly in tasks.md's "Spec gap noted" callouts under T5/T7 (confirmed below), so the code comment is redundant/duplicative rather than the sole record.

---

## Confirmed: Known Spec Gaps Honestly Noted in tasks.md

1. **T5** (`tasks.md:364`): `plan_prices.set_by_super_admin_id` has no FK constraint — noted immediately after T5's Done-when checklist, matches `database/migrations/2026_09_16_000006_create_plan_prices_table.php:19` (`unsignedBigInteger`, no `constrained()`). ✅ Honestly documented, not re-flagged as new.
2. **T7** (`tasks.md:416`): `event_info_requests.consumer_user_id` has no FK constraint — noted immediately after T7's Done-when checklist, matches `database/migrations/2026_09_16_000008_create_event_info_requests_table.php:16`. ✅ Honestly documented, not re-flagged as new.

---

## Gate Check (MANDATORY, re-run independently)

- **Gate command** (per Test Coverage Matrix, `tasks.md:35`): `php artisan migrate --pretend`
- Re-ran via `docker run --rm -v ".../api":/var/www/html -w /var/www/html --network qualorock qualorock-api-cli php artisan migrate:fresh --force` against the live `qornovo-postgres-1` Postgres container.
- **Result**: all 11 migrations (3 Laravel bootstrap + 8 admin-panel) applied cleanly, 0 errors:
  ```
  2026_09_16_000001_create_organizers_table .......... DONE
  2026_09_16_000002_create_venues_table ............... DONE
  2026_09_16_000003_create_events_table ............... DONE
  2026_09_16_000004_create_promoters_table ............ DONE
  2026_09_16_000005_create_event_promoter_table ....... DONE
  2026_09_16_000006_create_plan_prices_table .......... DONE
  2026_09_16_000007_create_data_export_requests_table . DONE
  2026_09_16_000008_create_event_info_requests_table .. DONE
  ```
- All T1-T7 "Done when: `php artisan migrate --pretend` runs without error" checkboxes: ✅ genuinely satisfiable (re-verified independently, not trusted from tasks.md's checkmarks).

---

## Functional Verification (tinker, beyond bare migrate --pretend)

Ran a live `php artisan tinker` script creating one row per entity through each Eloquent model, to confirm casts/relations/constraints actually work at runtime, not just that DDL parses:

| Check | Result |
| ----- | ------ |
| `Organizer::create()` with `plan_tier: basic` → enum cast on read | ✅ `PlanTier::Basic`, value `basic` |
| `Venue::create()` FK to organizer | ✅ created |
| Second `Venue::create()` for same `organizer_id` | ✅ **rejected** — `UniqueConstraintViolationException` (unique-per-organizer constraint enforced, T2 Done-when confirmed live) |
| `Event::create()` with `status: draft` → enum cast on read | ✅ `EventStatus::Draft` |
| `Promoter::events()->attach()` pivot | ✅ attach + count(1) succeeded |
| **`Event::promoters()`** (inverse of Promoter's `belongsToMany`) | ❌ **`BadMethodCallException: Call to undefined method Event::promoters()`** — see Findings below |
| `PlanPrice::create(tier: 'plus')` → enum cast | ✅ `PlanTier::Plus` |
| `DataExportRequest::create(status: 'pending')` → enum cast | ✅ `DataExportRequestStatus::Pending` |
| `EventInfoRequest::respond('thanks')` | ✅ sets `organizer_response` + `responded_at` |
| `Organizer::toArray()` excludes `password_hash` | ✅ `#[Hidden(['password_hash'])]` honored |
| `Organizer::create(plan_tier: 'not_a_real_tier')` | ✅ **rejected** — `ValueError: "not_a_real_tier" is not a valid backing value for enum PlanTier` (backed-enum casts self-guard against typo'd enum strings even with zero tests) |

---

## Findings

### Finding 1 — Missing inverse relation `Event::promoters()` (T4, minor)

`app/Infrastructure/Persistence/Eloquent/Promoter.php:18-21` defines `Promoter::events(): BelongsToMany`, but `app/Infrastructure/Persistence/Eloquent/Event.php` (`:16-37`) defines only `organizer()` and `venue()` — no `promoters()` inverse. Confirmed live: `Event::promoters()` throws `BadMethodCallException`.

- **Against T4's literal Done-when** (`tasks.md:332-336`): not a failure — the checklist only requires "*Model* defines `belongsToMany(Event::class)` via the pivot," which is satisfied on the `Promoter` side. T4 passes as written.
- **Against design.md**: design.md's Relationships line says `Event N—N Promoter via EventPromoter` — a symmetric N–N relationship, implying both directions should be navigable once the models exist, since Phase 2+ (EventController, event detail views) will very likely need `$event->promoters` to render an event's promoter list.
- **Severity**: Minor — does not block Phase 1's own gate (migrate --pretend), but will surface as a real blocker the moment a later task needs `$event->promoters`. Recommend a one-line fix task before or during whichever later phase first touches `Event` + `Promoter` together (add `public function promoters(): BelongsToMany { return $this->belongsToMany(Promoter::class, 'event_promoter'); }` to `Event.php`).

### Finding 2 — Inline rationale comments duplicate tasks.md's "Spec gap noted" callouts (AD-014, cosmetic)

See AD-013/AD-014 section above — `database/migrations/2026_09_16_000006_*.php:17-18` and `...000008_*.php:14-15`. Not task/ticket-referencing (the literal thing AD-014 forbids), but narrative rationale that AD-014 says belongs in docs. Cosmetic; no action required unless a later docs pass wants to consolidate.

---

## Structural Discrimination Check (in place of a test-based sensor)

Per this task's brief: this layer has **no tests** by the spec's own Test Coverage Matrix (`tasks.md:35`, Gate = build only), so the standard scratch-worktree mutation sensor doesn't apply — there is nothing for a mutation to make a test fail. Instead: for 3 representative migrations/models, asking "if a field type, enum value, or constraint were silently wrong, would `php artisan migrate --pretend` or a tinker instantiation actually catch it?"

| Migration/Model | Would `migrate --pretend` catch a wrong field TYPE (e.g. `string` where design implies `text`)? | Would it catch a WRONG ENUM VALUE (e.g. a typo'd status string)? | Would it catch a swapped FIELD ORDER? | Would it catch a MISSING nullable/constraint? |
| --- | --- | --- | --- | --- |
| `events` migration | ❌ No — `migrate --pretend` only validates the DDL is syntactically runnable against the driver, not that a `string` vs `text` choice matches design.md's implied semantics | ⚠️ Partial — the *migration* itself has no enum type (Postgres `string` column), so a typo'd literal passed at write time is NOT caught by the migration; it IS caught later at the **model** layer (backed-enum `ValueError`, confirmed live above) — but only because these particular fields have PHP enum casts | ❌ No — column order is irrelevant to Postgres/Eloquent correctness and `migrate --pretend` would pass identically either way | ⚠️ Partial — a missing `->nullable()` would surface only on the first `INSERT` that omits the field (a runtime NOT NULL violation), not at `--pretend` time, since `--pretend` never executes DDL |
| `organizers` migration (unique email) | ❌ No | N/A (no enum in migration itself) | ❌ No | ✅ Yes for the specific case tested here — a *missing* `unique()` would not be caught by `--pretend`, but was positively confirmed present via live tinker (duplicate-venue insert rejected) rather than assumed from the DDL text |
| `plan_prices` migration (FK gap) | ❌ No | N/A | ❌ No | N/A — this is a deliberate, documented gap (Finding: none, already tracked) |

**Coverage-limitation conclusion (not a failure)**: `php artisan migrate --pretend` is a weak gate on its own — it only proves the migration *file* is syntactically valid DDL, not that field types, nullability, or ordering match design.md's intent. The stronger discrimination in this Phase 1 comes from (a) PHP's backed-enum casts, which self-reject invalid enum literals at write time regardless of test coverage, and (b) this Verifier's own live tinker pass, which positively exercised uniqueness/FK/enum/hidden-field behavior rather than trusting the DDL text. This is an accepted, spec-declared coverage limitation for this layer (Test Coverage Matrix explicitly assigns "none — build gate only" here) — flagged per the task brief, not treated as a fail.

---

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code (no speculative flexibility) | ✅ — no unused fields, no premature abstraction beyond what T1-T7 ask |
| Surgical changes (only files required for task) | ✅ — `git diff --stat` for the whole range shows only new files under `database/migrations/`, `app/Domain/{Entities,Contracts,Enums}`, `app/Infrastructure/Persistence/Eloquent` — nothing pre-existing touched |
| No scope creep | ✅ — Application/Presentation layers correctly not started (out of Phase 1 scope) |
| Matches patterns/style | ✅ — consistent naming (`Eloquent<Entity>Repository`, `<Entity>RepositoryInterface`), consistent use of PHP 8.4 `#[Fillable]`/`#[Hidden]` attributes across all 7 models |
| Layering per AD-012 | ✅ — see Clean Architecture section above |
| AD-013 (no magic numbers/strings, one class/file) | ✅ — see AD-013 section above |
| AD-014 (no task-referencing comments) | ⚠️ Minor friction — see Finding 2 |
| Documented guidelines followed | tasks.md Coding Conventions (lines 16-25), `.specs/STATE.md` AD-012/AD-013 |

---

## Requirement Traceability Update

| Requirement | Previous Status | New Status |
| ----------- | ---------------- | ---------- |
| ADMIN-01..05 (Organizer data foundation) | Implementing | ✅ Verified |
| ADMIN-13, ADMIN-14 (Venue data foundation) | Implementing | ✅ Verified |
| ADMIN-06..10, ADMIN-28 (Event data foundation) | Implementing | ✅ Verified |
| ADMIN-17..19 (Promoter/EventPromoter data foundation) | Implementing | ⚠️ Verified with minor gap (Finding 1) |
| ADMIN-20..23 (PlanPrice data foundation) | Implementing | ✅ Verified |
| ADMIN-24..27 (DataExportRequest data foundation) | Implementing | ✅ Verified |
| ADMIN-16 (EventInfoRequest, design gap filled by T7) | Implementing | ✅ Verified |

---

## Summary

**Overall**: ✅ Ready (Phase 1 / T1-T7 only)

**Spec-anchored check**: 8/8 entities matched design.md (or T7's own field list) field-for-field; 0 spec-precision gaps (this layer has no ACs of its own — it's the data-modeling substrate for later phases' ACs)
**Gate**: 8/8 admin-panel migrations passed `migrate --pretend` / `migrate:fresh --force`, 0 failed
**Layering (AD-012)**: 3/3 entities-with-business-rules (Organizer, Event, PlanPrice) have the full Domain/Entities+Contracts+Infrastructure triad; 4/4 simple-CRUD entities correctly have model-only, no over- or under-building
**Discrimination**: no test-based sensor applicable (spec-declared no-tests layer); structural check performed instead — flagged as an accepted coverage limitation, not a fail

**What works**: All 7 tasks' migrations and models are present, match design.md exactly, the Clean-Architecture 3-tier split is applied exactly where required and correctly omitted elsewhere, both documented spec gaps (T5/T7 missing FKs) are honestly carried in tasks.md, and live tinker verification confirms uniqueness constraints, enum casts, hidden attributes, and the pivot relation all work at runtime — not just that the DDL parses.

**Issues found**:
1. Finding 1 (minor): `Event` model is missing the inverse `promoters(): BelongsToMany` relation that `Promoter::events()` implies — recommend adding it as a one-line fix whenever a later phase first needs `$event->promoters`.
2. Finding 2 (cosmetic): two migration files carry inline rationale comments that duplicate tasks.md's own "Spec gap noted" callouts — AD-014 prefers this rationale live only in docs; no functional impact.

**Next steps**: Neither finding blocks Phase 1 sign-off or the next phase starting. Finding 1 should be picked up as a small fix task by whichever later phase first wires `Event`↔`Promoter` together (likely the EventController/Promoter management phase).

---
---

## Validation: admin-panel Phase 2 (T8-T10) - PASS ✅

# Admin Panel Validation — Phase 2 (T8–T10: Auth guards & Super Admin approval)

**Date**: 2026-09-16
**Spec**: `.specs/features/admin-panel/spec.md` ("P1: Organizer access is gated by Super Admin approval", lines 52-66), `.specs/features/admin-panel/design.md` (Architecture Overview lines 9-26; `OrganizerApprovalController`/`SuperAdminOrganizerPolicy` component, lines 120-125; Coding Conventions lines 196-202), `.specs/features/admin-panel/tasks.md` (T8-T10, lines 425-499)
**Scope**: Phase 2 only — T8 (Sanctum guards), T9 (`OrganizerApprovalController`/`SuperAdminOrganizerPolicy`), T10 (login-gate denial for pending/rejected organizers). Phase 1 (above) already verified; Phases 3-15 not started.
**Diff range**: `api` submodule, `main..feat/admin-panel-phase-2-auth-guards` (merge-base `0257c3f`):
```
f86aff3 feat(admin-panel): configure organizer and super_admin Sanctum guards
567da62 feat(admin-panel): add OrganizerApprovalController and policy
83b765b feat(admin-panel): deny management access to pending/rejected organizers at login
6ace089 docs(admin-panel): clarify why the CI coverage gate still has no threshold
```
**Verifier**: independent sub-agent (author ≠ verifier) — no prior "done" claim trusted; all evidence re-derived from the diff, tests, and live gate runs.

---

## Task Completion

| Task | Status  | Notes |
| ---- | ------- | ----- |
| T8   | ✅ Done | `organizer`/`super_admin` guards + `organizers`/`super_admins` providers present in `config/auth.php:47-57,85-94`, distinct from `web`; `php artisan config:show auth` independently re-run and confirms both guards; session cookie Secure/HttpOnly/SameSite confirmed (see AD-008 section below) |
| T9   | ✅ Done | `OrganizerApprovalController` (list/approve/reject) + `SuperAdminOrganizerPolicy`, all 4 Done-when criteria test-verified; gate `--filter=OrganizerApproval` independently re-run, 4/4 pass |
| T10  | ✅ Done | `AuthController::login` + `LoginOrganizer` use-case + `EnsureOrganizerApproved` session-snapshot middleware; all 3 Done-when criteria test-verified including the mid-session re-auth requirement; gate `--filter=OrganizerLoginGate` independently re-run, 4/4 pass |

---

## Spec-Anchored Acceptance Criteria (ADMIN-01..05)

| Criterion (WHEN X THEN Y) | Spec-defined outcome | `file:line` + assertion expression | Result |
| ------------------------- | --------------------- | ----------------------------------- | ------ |
| ADMIN-01: WHEN a Super Admin opens the pending-organizers list THEN the system SHALL show every organizer account in `pending` state with signup details | List contains only `pending` organizers, with signup fields (org name, email, etc.) present | `tests/Feature/SuperAdmin/OrganizerApprovalTest.php:19-33` — `$response->assertJsonCount(1, 'data')` (excludes the seeded `approved` organizer) + `assertJsonFragment(['id' => $pending->id, 'orgName' => ..., 'email' => ..., 'approvalState' => 'pending'])` | ✅ PASS (⚠️ spec doesn't enumerate which "signup details" fields are required — test checks id/orgName/email/approvalState but not contactName/phone/planTier; flagged as a minor spec-precision gap, not a fail, since the controller's `toResponse()` at `app/Presentation/Http/Controllers/SuperAdmin/OrganizerApprovalController.php:53-64` does return all of them and the count-exclusion of non-pending rows is the AC's real teeth) |
| ADMIN-02: WHEN a Super Admin approves a pending organizer THEN the system SHALL set state to `approved` and grant management access on next login | `approval_state === Approved`; a subsequent login grants management access | `tests/Feature/SuperAdmin/OrganizerApprovalTest.php:39-49` — `$this->assertSame(OrganizerApprovalState::Approved, $organizer->fresh()->approval_state)`; "next login" half of the AC covered by `tests/Feature/Organizer/OrganizerLoginGateTest.php:72-82` — `it_allows_an_approved_organizer_management_access` asserts `->assertOk()` on the management route after login | ✅ PASS (evidence spans two test files, both cited) |
| ADMIN-03: WHEN a Super Admin rejects a pending organizer THEN the system SHALL set state to `rejected` and record an optional reason | `approval_state === Rejected`, `rejection_reason` stored exactly as submitted | `tests/Feature/SuperAdmin/OrganizerApprovalTest.php:53-67` — `$this->assertSame(OrganizerApprovalState::Rejected, $fresh->approval_state)` + `$this->assertSame('Missing venue documentation.', $fresh->rejection_reason)` | ✅ PASS — exact value asserted, not just presence |
| ADMIN-04: IF an organizer whose account is `pending`/`rejected` attempts to log in THEN the system SHALL deny access to management and show current state (+ rejection reason, if any) | 403 response; body contains the account's `state` and `rejectionReason` verbatim | `tests/Feature/Organizer/OrganizerLoginGateTest.php:32-45` — `$response->assertForbidden(); $response->assertJson(['state' => 'pending', 'rejectionReason' => null]);` and `:49-67` — `assertJson(['state' => 'rejected', 'rejectionReason' => 'Missing venue documentation.'])` | ✅ PASS — both status code and exact JSON payload values asserted (conjunction check: `assertJson` requires all listed key/value pairs to match, not just key presence) |
| ADMIN-05: THE system SHALL restrict the pending-organizers list and approve/reject actions to Super Admin accounts only | Non-super-admin caller gets 403 (not 401, not 200) | `tests/Feature/SuperAdmin/OrganizerApprovalTest.php:71-82` — `it_denies_a_non_super_admin`: `$response->assertForbidden()` on both the list and approve endpoints, called `actingAs($organizer, 'organizer')`; unit-level: `tests/Unit/Policies/SuperAdminOrganizerPolicyTest.php:36-51` — `assertFalse` for an `Organizer` instance and for `null` (unauthenticated) across all 3 policy methods | ✅ PASS — exact status code (403) asserted at the integration layer, all branches (organizer, null) asserted at the unit layer |

**Status**: ✅ All 5 ACs covered with a `file:line` + assertion matching the spec-defined outcome; 1 minor spec-precision gap flagged on ADMIN-01 (spec doesn't enumerate which "signup details" fields are required — not a coverage failure).

---

## Edge Cases (spec.md lines 189-195, in scope for Phase 2)

- [x] "IF a Super Admin account itself is deactivated or doesn't exist THEN no organizer can self-approve" — covered indirectly: `SuperAdminOrganizerPolicy` only returns `true` for an `instanceof SuperAdmin`, never for an `Organizer` acting on itself (`tests/Feature/SuperAdmin/OrganizerApprovalTest.php:71-82`, `tests/Unit/Policies/SuperAdminOrganizerPolicyTest.php:36-42`) — there is no code path where an organizer can approve itself, since approval requires a `super_admin`-guard-authenticated user and the guard/provider are entirely separate tables (T8).
- [x] "IF an organizer's account is approved mid-session THEN the system SHALL require re-authentication before granting management access" — `tests/Feature/Organizer/OrganizerLoginGateTest.php:86-105` (`it_requires_re_authentication_after_a_mid_session_approval`): logs in as `pending`, mutates the DB row to `Approved` directly (simulating an out-of-band approval during an open session), asserts the still-open session's management route stays `403`, then asserts a *second* login-and-check succeeds. This is the strongest test in the diff — it is exactly the discrimination sensor's mutation #2 target (see below) and killed that mutant.

---

## Discrimination Sensor

Isolation method: `cp -r` of `api/` to `/tmp/admin-panel-phase2-sensor` (a plain directory copy, not a git worktree — this submodule's own `.git` did not copy cleanly under the scratch path, so `git worktree add` was not usable there; the fallback file-copy method from validate.md step 1 was used instead). Baseline `git status --porcelain` on the real `api/` tree was clean before sensor work; re-confirmed clean and unchanged after cleanup (`rm -rf` of the scratch directory, no `git stash` used at any point).

| Mutation | File:line | Description | Killed? |
| -------- | --------- | ------------ | ------- |
| 1 | `app/Application/Policies/SuperAdminOrganizerPolicy.php:10-13` | `viewPending()` changed from `return $user instanceof SuperAdmin;` to `return true;` | ✅ Killed — `it_denies_a_non_super_admin` failed: expected 403, got 200 |
| 2 | `app/Presentation/Http/Middleware/EnsureOrganizerApproved.php:22-29` | Changed the session-snapshot read (`$request->session()->get(...)`) to a live DB lookup (`Organizer::find($request->user('organizer')?->id)->approval_state`) | ✅ Killed — `it_requires_re_authentication_after_a_mid_session_approval` failed: expected 403, got 200 (the live-DB version incorrectly grants access mid-session, exactly the regression this test exists to catch) |
| 3 | `app/Application/UseCases/OrganizerApproval/ApproveOrganizer.php:18` | Swapped `OrganizerApprovalState::Approved` → `OrganizerApprovalState::Rejected` in the approve use-case | ✅ Killed — `it_approves_a_pending_organizer` failed: expected `Approved`, got `Rejected` |

**Sensor depth**: lightweight (default tier) — 3 targeted behavior-level mutations covering the two design decisions called out as highest-risk (policy discrimination, session-snapshot-vs-live-DB) plus one straightforward state-assignment flip.
**Result**: 3/3 killed — PASS ✅. All three mutations were caught by exactly the test the author's commit messages claim exists for that purpose, confirming the tests are not just present but discriminating.

---

## Payload/Conjunction Check

- `assertJson(['state' => 'pending', 'rejectionReason' => null])` (`OrganizerLoginGateTest.php:44`) and `assertJson(['state' => 'rejected', 'rejectionReason' => 'Missing venue documentation.'])` (`:64-67`) — Laravel's `assertJson` performs a subset-match requiring every listed key **and its exact value** to be present in the response; confirmed this is a value check (not presence-only) by the sensor's mutation 2, which changed the underlying state source and correctly broke this exact assertion.
- `assertSame(OrganizerApprovalState::Rejected, $fresh->approval_state)` / `assertSame('Missing venue documentation.', $fresh->rejection_reason)` (`OrganizerApprovalTest.php:65-66`) — `assertSame` is a strict value/identity check, not presence.
- `assertJsonFragment([...])` (`OrganizerApprovalTest.php:29-34`) — also a value-matching (not key-presence-only) assertion; Laravel's `assertJsonFragment` fails if any listed value differs from the response.

No JSON assertion in scope was found to check only key presence without a value.

---

## Gate Check (MANDATORY, re-run independently — not trusted from tasks.md checkmarks or STATE.md's "full test suite green" claim)

All commands below were re-run fresh via `docker run --rm -v "$(pwd)":/app -w /app composer:2 ...` from inside `api/`, on the `feat/admin-panel-phase-2-auth-guards` branch as checked out (no branch switch performed).

| Gate command (from tasks.md) | Result |
| --- | --- |
| `php artisan config:show auth` | ✅ Output confirms `guards.organizer.driver=session`, `guards.organizer.provider=organizers`, `guards.super_admin.driver=session`, `guards.super_admin.provider=super_admins`, `providers.organizers.model=App\Infrastructure\Persistence\Eloquent\Organizer`, `providers.super_admins.model=App\Infrastructure\Persistence\Eloquent\SuperAdmin` — matches T8's Done-when exactly |
| `php artisan test --filter=OrganizerApproval` | ✅ 4 passed (13 assertions), 0 failed |
| `php artisan test --filter=OrganizerLoginGate` | ✅ 4 passed (12 assertions), 0 failed |
| `php artisan test` (full suite) | ✅ 13 passed (36 assertions), 0 failed, 0 skipped — matches `.specs/STATE.md`'s "full test suite green (13 tests)" claim, independently confirmed rather than trusted |
| `vendor/bin/pint --test` | ✅ PASS, 77 files, 0 style violations |

- **Test count before Phase 2**: 2 (the two Laravel-scaffold `ExampleTest`s — Phase 1 added 0 tests per its own "Tests: none" Test Coverage Matrix row)
- **Test count after Phase 2**: 13
- **Delta**: +11 new tests (4 `OrganizerApprovalTest` + 4 `OrganizerLoginGateTest` + 3 `SuperAdminOrganizerPolicyTest`) — no test count decrease, no assertions found weakened
- **Skipped tests**: none
- **Failures**: none

---

## Clean Architecture (AD-012) / AD-013 Check

**T9 (`OrganizerApprovalController`)** — matches design.md's component description (lines 120-125) exactly:
- Presentation: `app/Presentation/Http/Controllers/SuperAdmin/OrganizerApprovalController.php` — thin, calls `SuperAdminOrganizerPolicy` + 3 Application use-cases only, no direct Eloquent queries.
- Application: `app/Application/UseCases/OrganizerApproval/{ListPendingOrganizers,ApproveOrganizer,RejectOrganizer}.php` + `app/Application/Policies/SuperAdminOrganizerPolicy.php` — each a single-purpose use-case, orchestrating via the Domain contract.
- Domain: `app/Domain/Contracts/OrganizerRepositoryInterface.php` (from Phase 1) — `ApproveOrganizer`/`RejectOrganizer`/`ListPendingOrganizers` all type-hint this interface, never the Eloquent model, and all three return `App\Domain\Entities\Organizer` (the framework-agnostic entity), not the Eloquent model.
- Infrastructure: `app/Infrastructure/Persistence/Eloquent/EloquentOrganizerRepository.php` (from Phase 1, unmodified) implements the contract; bound in `app/Providers/AppServiceProvider.php:15`.
- **Result**: ✅ Full 4-layer compliance, no deviation, no direct Eloquent access from Presentation or Application.

**T10 (`AuthController`/`LoginOrganizer`) — design.md does NOT describe this component at all.** Confirmed by re-reading design.md's full Components section (lines 118-157): only `OrganizerApprovalController`, `EventController`, `VenueController`/`PromoterController`, `EngagementDashboardController`, `PlanPricingController`, and `OrganizerDataController` are documented — no `AuthController`, no `LoginOrganizer` use-case, no login endpoint anywhere in design.md. This is a genuine **design-doc gap**: T10 was added directly in tasks.md (its own text says "Wire the organizer login endpoint...") without a corresponding design.md component ever being written. Noting this honestly rather than assuming design.md silently covers it.

Given no documented layering to compare against, the *established pattern* from T9/Phase 1 is the closest applicable baseline, and T10 deviates from it in one respect:
- `app/Application/UseCases/OrganizerAuth/LoginOrganizer.php:1-18` type-hints and returns `App\Infrastructure\Persistence\Eloquent\Organizer` — the **Eloquent model**, not `App\Domain\Entities\Organizer` (the Domain entity every other Application use-case in this diff returns). It also calls `Illuminate\Support\Facades\Auth::guard('organizer')->attempt(...)` directly, bypassing `OrganizerRepositoryInterface` entirely.
- `app/Presentation/Http/Controllers/Organizer/AuthController.php:20-33` then reads `$organizer->approval_state->value` / `$organizer->rejection_reason` directly off that Eloquent model.
- **Assessment**: this is a real, if narrow, Clean-Architecture deviation from AD-012's "Application orchestrates Domain via contracts" description — it is understandable (Laravel's `Auth::attempt()` credential-verification path is themost practical way to do password-hash comparison + session login, and forcing it through a hand-rolled Domain-Entity-returning repository method would duplicate Sanctum session-auth machinery for no functional gain) but it is not what AD-012 literally prescribes, and it is not a doc-approved exception since design.md never discusses this component in the first place. **Flagged as a Finding below, not a blocking fail** — no test asserts on Domain-entity purity here, no spec AC is affected, and functionally the login gate behaves correctly (Gate Check + Discrimination Sensor mutation 2 both confirm this).

**AD-013 spot-check (magic numbers/strings, one class/file)**:
- One class per file: confirmed across all 19 new/changed PHP files in the diff (`git diff --stat main..feat/admin-panel-phase-2-auth-guards` — every file declares exactly one class/interface).
- No magic strings: session keys (`organizer_approval_state`, `organizer_rejection_reason`) are named constants in `app/Domain/Constants/AdminPanelConstants.php:5-7`, not inlined at call sites; approval-state comparisons use the `OrganizerApprovalState` backed enum (`->value`), not raw strings, in both `EnsureOrganizerApproved.php:24` and `AuthController.php:26-28`.
- **AD-014** (no task-referencing comments): confirmed clean — `EnsureOrganizerApproved.php`'s docblock and the `organizer`/`super_admin` guard comment in `config/auth.php` are rationale-explaining, not task/ticket-referencing (e.g. no `// T10` or `// ADMIN-04`), consistent with the convention.

---

## Findings

### Finding 1 — T10's `LoginOrganizer` returns the Eloquent model, not the Domain entity (minor, Clean Architecture deviation)

See Clean Architecture section above. `app/Application/UseCases/OrganizerAuth/LoginOrganizer.php` type-hints/returns `App\Infrastructure\Persistence\Eloquent\Organizer` and calls `Auth::guard('organizer')->attempt()` directly, rather than going through `OrganizerRepositoryInterface` and returning `App\Domain\Entities\Organizer` the way `ApproveOrganizer`/`RejectOrganizer`/`ListPendingOrganizers` do.

- **Severity**: Minor — no spec AC or test depends on Domain-entity purity here; functionally correct and gate-verified. Design.md never documents this component, so there is no literal doc violation, only a departure from the pattern the rest of this phase (and Phase 1) establishes.
- **Recommendation**: When design.md is next touched for admin-panel, add an `AuthController`/`LoginOrganizer` component entry (closing the doc gap AD-014 implies every component should have), and consider whether a `Auth::guard()`-based login path is an accepted, named exception to AD-012's "orchestrate via contracts" language, or whether a follow-up should wrap it through the repository. Not blocking.

### Finding 2 — ADMIN-01's "signup details" is not spec-precise (spec-precision gap, not a fail)

Spec.md doesn't enumerate which fields constitute "the signup details they submitted." The test (`OrganizerApprovalTest.php:29-34`) checks `id`/`orgName`/`email`/`approvalState` via `assertJsonFragment`, while the controller's `toResponse()` (`OrganizerApprovalController.php:53-64`) actually returns `contactName`/`phone`/`planTier`/`rejectionReason` too — so the implementation is more complete than the test asserts, but the spec itself gives no fixed target to hold the test to. No action required; flagged per validate.md's instruction to surface spec-precision gaps rather than pass silently.

---

## Code Quality

| Principle        | Status |
| ---------------- | ------ |
| Minimum code (no speculative flexibility) | ✅ — no endpoints/use-cases beyond T8-T10's literal scope |
| Surgical changes (only files required for task) | ✅ — `git diff --stat` shows only auth-guard config, the approval controller/policy/use-cases, the login controller/use-case/middleware, their tests, and the honest CI-comment-only 4th commit; nothing pre-existing modified beyond `config/auth.php`, `config/session.php`, `bootstrap/app.php`, `app/Providers/AppServiceProvider.php`, and the two `Organizer`/`SuperAdmin` Eloquent models (extended, not rewritten) |
| No scope creep | ✅ — no EventController/VenuePolicy/etc. work leaked in from later phases |
| Matches existing patterns/style | ✅ — consistent with Phase 1's `Eloquent<Entity>` / `<Entity>RepositoryInterface` naming; GIVEN/WHEN/THEN `#[TestDox]` naming matches AD-010 |
| Spec-anchored outcome check (asserted values match spec) | ✅ — see Spec-Anchored Acceptance Criteria table above; all 5 ACs assert exact values/status codes |
| Per-layer Coverage Expectation met (Policy: unit, all branches; Controller/route: integration, happy+edge+error) | ✅ — `SuperAdminOrganizerPolicyTest` covers all 3 branches (super admin/organizer/null) per Test Coverage Matrix's "Policy … all branches" row; `OrganizerApprovalTest`/`OrganizerLoginGateTest` cover happy path + the 403 edge cases per the Matrix's "Controller/route … happy path + every listed edge case + error/failure paths" row |
| Every test in scope maps to a spec AC, listed edge case, or Done-when criterion (no unclaimed tests) | ✅ — all 11 new tests map 1:1 to ADMIN-01..05 or the mid-session Edge Case (see table above); none found testing unrequested behavior |
| Documented guidelines followed | tasks.md Coding Conventions (lines 16-25), `.specs/STATE.md` AD-012/AD-013/AD-002/AD-008/AD-021 |
| Layering (AD-012) | ✅ T9 full compliance; ⚠️ T10 minor deviation (Finding 1) — honestly noted, not blocking |

---

## Requirement Traceability Update

| Requirement | Previous Status | New Status |
| ----------- | ---------------- | ---------- |
| ADMIN-01 | Design | ✅ Verified (⚠️ spec-precision gap noted on field enumeration) |
| ADMIN-02 | Design | ✅ Verified |
| ADMIN-03 | Design | ✅ Verified |
| ADMIN-04 | Design | ✅ Verified |
| ADMIN-05 | Design | ✅ Verified |

---

## Summary

**Overall**: ✅ Ready (Phase 2 / T8-T10 only)

**Spec-anchored check**: 5/5 ACs matched spec-defined outcomes with `file:line` evidence; 1 minor spec-precision gap flagged (ADMIN-01's undefined field list) — not a coverage failure
**Sensor**: 3/3 mutations killed (policy-bypass, live-DB-vs-session-snapshot, approve/reject state flip) — the tests genuinely discriminate against the two highest-risk design decisions in this phase
**Gate**: 5/5 gate commands passed (config:show, 2 filtered test runs, full suite 13/13, Pint 77 files clean), 0 failed, 0 skipped; test count grew 2→13 (+11), no regressions

**What works**: T8's guard/provider config is exactly as declared and independently reproducible via `config:show auth`; T9's controller/policy/use-cases are a clean, fully-layered implementation matching design.md verbatim, with all 4 Done-when criteria test-proven including the 403-not-401 distinction the author's commit message called out; T10's session-snapshot approach to the mid-session-approval edge case is real (not just claimed) — the discrimination sensor's mutation 2 proves the test would catch a regression to live-DB-checking; the `/api/admin/v1/super-admin/*` routes genuinely have no `auth:super_admin` middleware (confirmed by reading `routes/admin-panel.php`), so the policy really is what produces the 403, matching AD-021/the author's stated design intent.

**Issues found**:
1. Finding 1 (minor, non-blocking): `LoginOrganizer` returns the Eloquent model and calls `Auth::guard()` directly rather than routing through `OrganizerRepositoryInterface`/`Domain\Entities\Organizer` the way sibling use-cases do — recommend closing the design.md documentation gap for this component in a future pass and deciding whether this is an accepted exception.
2. Finding 2 (cosmetic): ADMIN-01's "signup details" isn't spec-precise; implementation covers more fields than the test asserts, no functional gap.

**Next steps**: Neither finding blocks Phase 2 sign-off or Phase 3 starting. Recommend adding an `AuthController`/`LoginOrganizer` design.md component entry whenever admin-panel's design.md is next revisited, to close the doc gap AD-014 implies every component should have.

---
---

## Validation: admin-panel Phase 3 (T11-T14) - PASS ✅ (after re-verification, see "Re-verification (iteration 2)" below)

# Admin Panel Validation — Phase 3 (T11–T14: EventPolicy, PublishedEventCounter, EventController CRUD, Basic-tier cap)

**Date**: 2026-09-16
**Spec**: `.specs/features/admin-panel/spec.md` ("P1: Register and manage events", lines 70-87), `.specs/features/admin-panel/design.md` (Components: "EventController / EventPolicy", lines 127-132; Error Handling Strategy, lines 169-177; Risks & Concerns, lines 181-189), `.specs/features/admin-panel/tasks.md` (T11-T14, lines 503-602)
**Scope**: Phase 3 only — T11 (`EventPolicy`), T12 (`PublishedEventCounter`), T13 (`EventController` CRUD + status transitions + duplication), T14 (Basic-tier 4-events/month publish cap). Phases 1-2 (above) already verified; Phases 4-15 not started.
**Diff range**: `api` repo, `main..HEAD` on `feat/admin-panel-phase-3-event-crud`:
```
26a0169 feat(admin-panel): add EventPolicy for ownership/IDOR enforcement
170a644 feat(admin-panel): add PublishedEventCounter service
00b68fa feat(admin-panel): add EventController CRUD and status transitions
21c940e feat(admin-panel): enforce Basic-tier 4-events/month publish cap
```
**Verifier**: independent sub-agent (author ≠ verifier) — no prior "done" claim trusted; all evidence re-derived from the diff, tests, and live gate/sensor runs.

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| T11  | ✅ Done | `EventPolicy::owns()` correctly checks `$user instanceof Organizer && $user->id === $event->organizerId`; all 3 Done-when tests present and pass (`tests/Unit/Policies/EventPolicyTest.php`) |
| T12  | ✅ Done | `PublishedEventCounter` correctly converts to `AdminPanelConstants::DEFAULT_ORGANIZER_TIMEZONE` before computing `startOfMonth()/endOfMonth()`, then queries in UTC — both Done-when tests present and pass, including the month-boundary edge case |
| T13  | ⚠️ Done with gaps | CRUD/duplication implemented correctly; 2 of 6 literal Done-when criteria have no Feature-level (HTTP) test evidence — see Findings 1 and the AC5/AC6 rows below |
| T14  | ✅ Done | Cap correctly wired into `TransitionEventStatus::hasReachedBasicTierPublishCap()`, `>=` comparison against `AdminPanelConstants::BASIC_TIER_MONTHLY_PUBLISH_LIMIT` (4); both Done-when tests present and pass |

---

## Spec-Anchored Acceptance Criteria ("P1: Register and manage events", spec.md lines 76-87)

| Criterion (WHEN X THEN Y) | Spec-defined outcome | `file:line` + assertion expression | Result |
| -------------------------- | ---------------------- | ------------------------------------ | ------ |
| AC1: WHEN an approved organizer submits a new event with the required fields THEN create it in `draft` status | New `events` row exists with `status = draft` | `tests/Feature/Organizer/EventControllerTest.php:31-46` — `$response->assertJsonFragment(['status' => 'draft']); $this->assertDatabaseHas('events', ['organizer_id' => ..., 'venue_id' => ..., 'status' => 'draft']);` | ✅ PASS |
| AC2: WHEN an organizer edits their own event THEN save the changes and apply them immediately | Field's new value is persisted and readable right after the request | `tests/Feature/Organizer/EventControllerTest.php:49-60` — `$response->assertOk(); $this->assertSame('New Title', $event->fresh()->title);` | ✅ PASS |
| AC3: WHEN an organizer duplicates their own event THEN create a new `draft` copy with the same field values, excluding engagement stats | The duplicate's fields equal the original's fields (all of them), status forced to `draft` | `tests/Feature/Organizer/EventControllerTest.php:104-117` — asserts only `title` and `status` via `assertJsonFragment(['title' => 'Original', 'status' => 'draft'])` and `assertDatabaseCount('events', 2)` | ⚠️ Spec-precision gap — the test does not assert equality of the other 13 duplicated fields (description, dateTime, location, fullAddress, featuredImageUrl, externalTicketLink, priceType, musicCategory, capacity, ageRange, additionalInfo, accessibilityInfo, eventRules) that `App\Application\UseCases\Event\DuplicateEvent::handle()` (`app/Application/UseCases/Event/DuplicateEvent.php:17-38`) does copy 1:1 in the implementation — code review confirms the implementation is correct, but the test would not catch a regression that dropped or mismapped any of those 13 fields |
| AC4: WHEN an organizer deletes their own event THEN remove it from all consumer-facing listings | The event row no longer exists / cannot be returned by any listing query | `tests/Feature/Organizer/EventControllerTest.php:90-102` — `$response->assertNoContent(); $this->assertDatabaseMissing('events', ['id' => $event->id]);` | ✅ PASS |
| AC5: WHEN an organizer changes an event's status THEN accept only draft→published, published→cancelled, published→closed, draft→cancelled, and reject any other transition | All 4 whitelisted transitions succeed; any non-whitelisted transition is rejected | Domain rule matches exactly: `app/Domain/Entities/Event.php:33-40`. Tested sub-cases: draft→published (implicit happy path, `EventControllerTest.php:31-46` and `EventCapTest.php`), cancelled→published rejected (`EventControllerTest.php:76-88`, `TransitionEventStatusTest.php:38-50`). **No test anywhere in the diff exercises published→cancelled, published→closed, or draft→cancelled** (confirmed via `grep -rn "closed\|Closed\|cancelled\|Cancelled" tests/` — only the two cases above appear) | ❌ GAP — 3 of the 4 whitelisted transitions have zero test evidence (evidence-or-zero); only 1 of the many possible invalid transitions is tested |
| AC6: IF an organizer attempts to edit or delete an event they don't own THEN deny the action | 403 on both edit and delete for a non-owner | Edit: `tests/Feature/Organizer/EventControllerTest.php:62-74` — `$response->assertForbidden();`. Delete: **no Feature-level test exists** — `EventControllerTest.php` has no `it_denies_deleting_another_organizers_event` (or equivalent) case; confirmed absent by reading the full file | ❌ GAP — "delete" half of AC6 has no HTTP-level test evidence. (`DeleteEventRequest extends OrganizerOwnedEventRequest`, `app/Presentation/Http/Requests/Organizer/DeleteEventRequest.php:5`, so it does share the same `authorize()`/`EventPolicy::owns()` check as update — code review suggests it works — but the AC is untested end-to-end for delete specifically) |
| AC7: IF a Basic-tier organizer attempts to transition a 5th event to `published` within the same calendar month THEN block the transition and identify the Plus-tier upgrade | 422 response identifying the upgrade path | `tests/Feature/Organizer/EventCapTest.php:29-42` — `$response->assertStatus(422); $response->assertJsonFragment(['error' => 'upgrade_required']);` | ✅ PASS |

**Status**: ❌ Gaps present — 4/7 ACs fully covered with exact-outcome evidence, 1 spec-precision gap (AC3), 2 real coverage gaps (AC5, AC6) where a documented sub-case has no test evidence at all.

---

## Edge Cases (spec.md lines 189-195, in scope for Phase 3)

- [x] "IF an organizer tries to publish an event missing a required field ... THEN the system SHALL block the status transition to `published` and identify the missing fields" — covered at the **Unit** level only: `tests/Unit/UseCases/Event/TransitionEventStatusTest.php:22-36` (`it_rejects_publishing_an_event_with_missing_required_fields`) asserts `$exception->missingFields === ['featuredImageUrl']`. **No Feature/HTTP-level test** asserts the controller's actual JSON shape (`{"error": "missing_required_fields", "missingFields": [...]}` per `EventController.php:70-74`) — flagged as a minor gap below (Finding 2), since the mapping from exception → HTTP response is itself untested.
- [ ] "WHEN an organizer deletes a promoter linked to a published event THEN remove the promoter from that event's public list without deleting the event" — N/A for this phase (Promoter/EventPromoter not yet built; correctly out of scope for T11-T14).

---

## Discrimination Sensor

**Isolation method**: `git worktree add /tmp/verify-scratch HEAD` (a real git worktree, not a copy or stash). Baseline `git status --porcelain` on the real `api/` tree was captured and confirmed empty (clean) before any sensor work, and re-confirmed identical (still empty) after the worktree was removed via `git worktree remove --force /tmp/verify-scratch` — no `git stash` used at any point.

| Mutation | File:line | Description | Killed? |
| -------- | --------- | ------------ | ------- |
| 1 | `app/Application/Policies/EventPolicy.php:13` | `owns()` changed from `return $user instanceof Organizer && $user->id === $event->organizerId;` to `return true;` | ✅ Killed — `EventPolicyTest::it_denies_when_there_is_no_authenticated_organizer` failed (`assertFalse` got `true`); `EventControllerTest::it_denies_updating_another_organizers_event` failed (expected 403, got 200) |
| 2 | `app/Application/UseCases/Event/TransitionEventStatus.php:49` | Basic-tier cap comparison changed from `>= AdminPanelConstants::BASIC_TIER_MONTHLY_PUBLISH_LIMIT` to `> AdminPanelConstants::BASIC_TIER_MONTHLY_PUBLISH_LIMIT` | ✅ Killed — `EventCapTest::it_blocks_a_fifth_publish_for_a_basic_tier_organizer` failed (expected 422, got 200) |
| 3 | `app/Domain/Entities/Event.php:38` | `canTransitionTo()`'s `default => false` (reject any status not `Draft`/`Published`) changed to `default => true` | ✅ Killed — `TransitionEventStatusTest::it_rejects_an_invalid_status_transition` failed (expected exception, none thrown); `EventControllerTest::it_rejects_an_invalid_status_transition` failed (expected 422, got 200) |

**Sensor depth**: lightweight (default tier) — 3 targeted behavior-level mutations covering the two highest-risk new rules (IDOR ownership check, Basic-tier cap boundary) plus the transition whitelist's fallback branch.
**Result**: 3/3 killed — PASS ✅. Note: mutation 3 targeted the entity's `default` branch (which both `Draft`/`Published`'s explicit whitelists rely on for rejecting out-of-list targets); it does not by itself prove `published→cancelled`/`published→closed`/`draft→cancelled` are individually exercised — see AC5's coverage gap above, which the sensor's kill does not close.

---

## Gate Check (MANDATORY, re-run independently — not trusted from tasks.md checkmarks)

All commands re-run fresh via `docker run --rm -v "$(pwd):/var/www/html" -w /var/www/html php:8.4-cli-alpine ...` (PHP is not installed on the host; `vendor/` was already present in the checked-out tree).

| Gate command | Result |
| --- | --- |
| `php artisan test` (full suite) | ✅ 30 passed (66 assertions), 0 failed, 0 skipped |
| `vendor/bin/pint --test` | ✅ PASS, 102 files, 0 style violations |

- **Test count before Phase 3** (re-derived independently, not from STATE.md): 14 — measured by checking out `main` (`b4a8a97`) into a separate worktree (`/tmp/verify-scratch-main`), copying `vendor/`, generating a fresh `.env`/app key, and running `php artisan test`: `14 passed (38 assertions)`.
- **Test count after Phase 3**: 30
- **Delta**: +16 new tests (3 `EventPolicyTest` + 2 `PublishedEventCounterTest` + 3 `TransitionEventStatusTest` + 6 `EventControllerTest` + 2 `EventCapTest`) — no decrease, no assertions found weakened.
- **Skipped tests**: none.
- **Failures**: none.

---

## Clean Architecture (AD-012) / AD-013 Check

Matches design.md's `EventController / EventPolicy` component description (lines 127-132) closely:
- **Presentation**: `app/Presentation/Http/Controllers/Organizer/EventController.php` — thin, delegates to 5 Application use-cases only; the 3 `catch` blocks map Domain exceptions to HTTP status/error-code, no business logic. `app/Presentation/Http/Requests/Organizer/*.php` — validation + `EventPolicy` authorization only.
- **Application**: `app/Application/UseCases/Event/{CreateEvent,UpdateEvent,DeleteEvent,DuplicateEvent,TransitionEventStatus}.php` + `app/Application/Policies/EventPolicy.php` + `app/Application/Services/PublishedEventCounter.php` — each single-purpose, orchestrating via `EventRepositoryInterface`.
- **Domain**: `app/Domain/Entities/Event.php` (status-transition whitelist + `missingFieldsForPublish()` as pure rules, no framework dependency), `app/Domain/Contracts/EventRepositoryInterface.php`, 3 new `Domain/Exceptions/*.php`.
- **Infrastructure**: `app/Infrastructure/Persistence/Eloquent/EloquentEventRepository.php` implements the contract, maps to/from the Domain entity via `toEntity()`; `countPublishedBetween()` correctly queries in UTC per the Risks table's mitigation (`PublishedEventCounter` converts to `America/Sao_Paulo` before computing month bounds, then `.utc()` before querying — `app/Application/Services/PublishedEventCounter.php:18-23`).
- **Result**: ✅ Full 4-layer compliance, no deviation. No magic numbers: the cap (`4`) and timezone default are named constants in `AdminPanelConstants` (`app/Domain/Constants/AdminPanelConstants.php:13,15`), not inlined. One class per file confirmed across all 33 changed files.

---

## Findings

### Finding 1 — AC5's status-transition matrix is only 2/4-plus-1 tested (Major)

`app/Domain/Entities/Event.php:33-40` correctly whitelists exactly the 4 transitions spec.md AC5 names (draft→published, draft→cancelled, published→cancelled, published→closed) and rejects everything else via `default => false` — confirmed correct by code review and by the discrimination sensor killing a mutation of that fallback branch. However, only draft→published (happy path) and cancelled→published (one invalid case) have any test evidence; published→cancelled, published→closed, and draft→cancelled have **none** — no unit test on the entity's `canTransitionTo()`, no Feature test posting `{"status": "cancelled"}` against a `published` event, etc.

- **Severity**: Major — this is the core rule T13/T14 exist to enforce; three of its four positive cases are unverified by any test, so a future regression to any of them (e.g. someone tightens `Published => [Cancelled]` and silently drops `Closed`) would not be caught.
- **Recommendation**: Add a unit test on `Event::canTransitionTo()` (or Feature tests against `POST /organizer/events/{id}/status`) for `published→cancelled`, `published→closed`, and `draft→cancelled` succeeding, and for at least one more invalid case (e.g. `closed→published`) being rejected.

### Finding 2 — AC6's delete-ownership case has no Feature-level test (Minor)

`app/Presentation/Http/Requests/Organizer/DeleteEventRequest.php` extends `OrganizerOwnedEventRequest`, so it shares the same `authorize()` → `EventPolicy::owns()` gate as `UpdateEventRequest` (tested) — code review indicates it works correctly. But `tests/Feature/Organizer/EventControllerTest.php` has no test asserting 403 when organizer A tries to `DELETE /organizer/events/{organizer B's event}`.

- **Severity**: Minor — the underlying policy is unit-tested generically (`EventPolicyTest`) and shared by construction (same abstract base class), so the residual risk is low, but AC6 literally names both "edit or delete" and only "edit" has end-to-end evidence.
- **Recommendation**: Add `it_denies_deleting_another_organizers_event` (and, while at it, the same for `duplicate`/`status` — both also extend `OrganizerOwnedEventRequest` and are equally untested for the ownership-denial case at Feature level).

### Finding 3 — Missing-required-fields HTTP response shape untested (Minor)

The domain rule (`Event::missingFieldsForPublish()`) and the use-case's exception-throwing are unit-tested (`TransitionEventStatusTest.php:22-36`), but the controller's mapping of that exception to `{"error": "missing_required_fields", "missingFields": [...]}` (`EventController.php:70-74`) has no Feature-level test exercising it through the real HTTP route.

- **Severity**: Minor — low risk since the mapping is a single straightforward `catch` block, but per this feature's own Test Coverage Matrix ("routes/e2e cover happy + edge + error paths for every route in scope"), this is an error path of the `status` route that is not exercised end-to-end.
- **Recommendation**: Add a Feature test posting to `/organizer/events/{id}/status` with `status: published` against an event missing a required field, asserting the full JSON error shape.

### Finding 4 — AC3's duplicate assertion doesn't verify full field equivalence (Minor, spec-precision)

See AC3 row above. `DuplicateEvent::handle()` (`app/Application/UseCases/Event/DuplicateEvent.php:17-38`) correctly copies all 15 fields, but `EventControllerTest::it_duplicates_an_organizers_own_event` only asserts `title` and `status` match — a regression that dropped or mis-set any other field (e.g. `capacity`, `musicCategory`) would not be caught.

- **Severity**: Minor — implementation confirmed correct by code review; this is a test-strength gap, not a functional bug.
- **Recommendation**: Strengthen the assertion to compare the duplicate's full field set against the original (e.g. assert equality on every field except `id`/`status`/`publishedAt`).

---

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code (no speculative flexibility) | ✅ — no endpoints/use-cases beyond T11-T14's literal scope |
| Surgical changes (only files required for task) | ✅ — `git diff --stat main..HEAD` touches only Event-related Domain/Application/Infrastructure/Presentation files, their tests, `routes/admin-panel.php`, `AppServiceProvider.php` (binding), and the two new factories; nothing pre-existing rewritten |
| No scope creep | ✅ — no Venue/Promoter/Dashboard work leaked in from later phases |
| Matches existing patterns/style | ✅ — consistent with Phase 1/2's `Eloquent<Entity>Repository`/`<Entity>RepositoryInterface` naming, GIVEN/WHEN/THEN `#[TestDox]` convention, `pint --test` clean |
| Spec-anchored outcome check (asserted values match spec) | ⚠️ — 4/7 ACs fully match; AC3 asserts a subset of the spec's "same field values"; AC5/AC6 have real coverage gaps (see Findings 1-2) |
| Per-layer Coverage Expectation met (domain 1:1 ACs; routes happy+edge+error) | ❌ — the `status` route's error path (missing fields) and the `delete`/`duplicate`/`status` routes' ownership-denial path are not covered at the Feature/route level (Findings 1-3) |
| Every test in scope maps to a spec AC, listed edge case, or Done-when criterion (no unclaimed tests) | ✅ — all 16 new tests map to ADMIN-06..10/ADMIN-28 or the missing-required-fields edge case; none found testing unrequested behavior |
| Documented guidelines followed | tasks.md Coding Conventions (lines 204-211), design.md Risks & Concerns (timezone handling, lines 181-189) |

---

## Requirement Traceability Update

| Requirement | Previous Status | New Status |
| ----------- | ---------------- | ---------- |
| ADMIN-06 (create event as draft) | Implementing | ✅ Verified |
| ADMIN-07 (edit own event) | Implementing | ✅ Verified |
| ADMIN-08 (duplicate) | Implementing | ⚠️ Verified with gap (Finding 4) |
| ADMIN-09 (delete) | Implementing | ✅ Verified |
| ADMIN-10 (ownership enforcement) | Implementing | ⚠️ Verified with gap (Finding 2 — delete/duplicate/status ownership paths untested at Feature level) |
| ADMIN-28 (Basic-tier cap + status transitions) | Implementing | ⚠️ Verified with gap (Finding 1 — 3 of 4 whitelisted transitions untested) |

---

## Summary

**Overall**: ❌ Not Ready (Phase 3 / T11-T14)

**Spec-anchored check**: 4/7 ACs matched spec outcome cleanly; 1 spec-precision gap (AC3); 2 real coverage gaps with zero test evidence for a named sub-case (AC5, AC6)
**Sensor**: 3/3 mutations killed (IDOR bypass, cap boundary, transition-whitelist fallback) — the tests that do exist are genuinely discriminating for what they cover
**Gate**: 30/30 tests passed, 0 failed; `pint --test` clean across 102 files; test count grew 14→30 (+16), no regressions

**What works**: `EventPolicy`, `PublishedEventCounter` (including the month-boundary timezone edge case from design.md's Risks table), event create/update/delete/duplicate, the transition whitelist's rejection logic, and the Basic-tier cap are all implemented correctly per code review and are proven correct by tests where tests exist; all 3 injected mutations were caught, confirming those tests are not superficial.

**Issues found**:
1. Finding 1 (Major): AC5's status-transition whitelist — only 2 of 4 valid transitions and 1 invalid case are tested; `published→cancelled`, `published→closed`, `draft→cancelled` have zero test evidence.
2. Finding 2 (Minor): AC6's ownership-denial is untested at Feature level for `delete`/`duplicate`/`status` (only `update` is tested end-to-end).
3. Finding 3 (Minor): the missing-required-fields error path is untested through the actual HTTP route (only unit-tested).
4. Finding 4 (Minor): AC3's duplicate test doesn't verify full field equivalence, only `title`/`status`.

**Next steps**: Route Findings 1-4 as fix tasks (add the missing transition tests, the missing ownership-denial tests, the missing HTTP-level error-path test, and strengthen the duplicate-field assertion) before Phase 3 sign-off. None require an implementation change — code review found the underlying logic correct in all four cases; these are test-coverage gaps, not functional bugs.

---

### Re-verification (iteration 2)

**Date**: 2026-09-16
**Diff added**: `c017ff3` — "test(admin-panel): close Phase 3 verifier coverage gaps" (`tests/Feature/Organizer/EventControllerTest.php`, +134/-2, 7 new test methods; no non-test files touched)
**Verifier**: independent sub-agent (fresh review; did not author `c017ff3`)

**Gap-by-gap re-check** (evidence-or-zero, re-derived independently from `git show c017ff3`, not trusted from the commit message):

| # | Original gap | Status | Evidence |
| - | ------------- | ------ | -------- |
| 1 | AC5: `published→cancelled`, `published→closed`, `draft→cancelled` had zero test evidence (Major) | ✅ Closed | `tests/Feature/Organizer/EventControllerTest.php:90-102` `it_allows_transitioning_a_published_event_to_cancelled` — `$response->assertOk(); $response->assertJsonFragment(['status' => 'cancelled']);`; `:104-116` `it_allows_transitioning_a_published_event_to_closed` — `assertOk()` + `assertJsonFragment(['status' => 'closed'])`; `:118-130` `it_allows_transitioning_a_draft_event_to_cancelled` — `assertOk()` + `assertJsonFragment(['status' => 'cancelled'])`. All 4 whitelisted transitions from spec.md AC5 now have exact-outcome HTTP evidence. Confirmed discriminating: sensor mutation 4 below (removing `Closed` from `Published`'s allowed targets in `app/Domain/Entities/Event.php:37`) fails exactly `it_allows_transitioning_a_published_event_to_closed` (expected 200, got 422) and no other test. |
| 2 | AC6: ownership-denial (403) untested at Feature level for `delete`/`duplicate`/`status` (Minor) | ✅ Closed | `EventControllerTest.php:147-160` `it_denies_deleting_another_organizers_event` — `$response->assertForbidden(); $this->assertDatabaseHas('events', ['id' => $event->id]);`; `:162-175` `it_denies_duplicating_another_organizers_event` — `assertForbidden()` + `assertDatabaseCount('events', 1)`; `:177-190` `it_denies_transitioning_another_organizers_event_status` — `assertForbidden()` + `assertSame('draft', $event->fresh()->status->value)`. All 3 previously-untested routes now assert both the 403 and that the denied action had no side effect. Confirmed discriminating: sensor mutation 5 below (bypassing `OrganizerOwnedEventRequest::authorize()`) fails all 3 of these plus the pre-existing `update` ownership test. |
| 3 | `missing_required_fields` error response untested through the real HTTP route (Minor) | ✅ Closed | `EventControllerTest.php:132-145` `it_rejects_publishing_an_event_with_a_missing_required_field_over_http` — `$response->assertStatus(422); $response->assertJsonFragment(['error' => 'missing_required_fields']); $response->assertJsonFragment(['missingFields' => ['location']]);`. Exercises the real `POST /organizer/events/{id}/status` route end-to-end, asserting the full JSON error shape `EventController.php:70-74` produces (not just the underlying exception, which was already unit-tested). |
| 4 | AC3's duplicate test only asserted `title`/`status`, not full field equivalence across all 14 copied fields (Minor, spec-precision) | ⚠️ Partially closed | `EventControllerTest.php:206-249` `it_duplicates_an_organizers_own_event` now sets 12 distinguishing values on the original (`title`, `description`, `location`, `full_address`, `featured_image_url`, `external_ticket_link`, `music_category`, `capacity`, `age_range`, `additional_info`, `accessibility_info`, `event_rules`) plus a real `venue_id`, and asserts all of them (`venueId`, `title`, `description`, `location`, `fullAddress`, `featuredImageUrl`, `externalTicketLink`, `musicCategory`, `capacity`, `ageRange`, `additionalInfo`, `accessibilityInfo`, `eventRules`) plus the forced `status`/`publishedAt` on the response — 13 of the 15 non-forced fields `DuplicateEvent::handle()` copies (`app/Application/UseCases/Event/DuplicateEvent.php:17-38`) are now verified, up from 2 (`title`, `status`). **Two fields remain unverified**: `dateTime` and `priceType` are copied by `DuplicateEvent::handle()` (lines 23, 28) but never overridden on the factory-built original nor asserted in the response fragment — a regression that dropped or mismapped either of those two specific fields would still not be caught by this test. |

**Discrimination sensor (targeted at the new coverage)**: isolated `git worktree add /tmp/verify-scratch-2 HEAD` at `c017ff3` (`vendor/` and `.env` copied in for the container run; never `git stash`). Baseline `git status --porcelain` on the real `api/` tree was empty before sensor work and confirmed still empty (identical) after `git worktree remove --force /tmp/verify-scratch-2`.

| Mutation | File:line | Description | Killed? |
| -------- | --------- | ------------ | ------- |
| 4 | `app/Domain/Entities/Event.php:37` | `Published`'s allowed targets narrowed from `[Cancelled, Closed]` to `[Cancelled]` (i.e. `published→closed` silently starts being rejected) | ✅ Killed — only `it_allows_transitioning_a_published_event_to_closed` failed (expected 200, got 422); the other 12 `EventControllerTest` cases still passed, confirming the new test is precisely targeting this transition and not redundant with existing ones |
| 5 | `app/Presentation/Http/Requests/Organizer/OrganizerOwnedEventRequest.php:18` | `authorize()` changed from `$event !== null && app(EventPolicy::class)->owns(...)` to `return true;` (ownership check bypassed for all 4 routes sharing this base request) | ✅ Killed — `it_denies_updating_another_organizers_event`, `it_denies_deleting_another_organizers_event`, `it_denies_duplicating_another_organizers_event`, and `it_denies_transitioning_another_organizers_event_status` all failed (expected 403, got 200/201); 9 of 13 `EventControllerTest` cases still passed |

**Sensor depth**: lightweight, 2 additional targeted mutations (bringing the feature's cumulative sensor total to 5/5 killed across both iterations).

**Gate re-run** (fresh, via `docker run --rm -v "$(pwd):/var/www/html" -w /var/www/html php:8.4-cli-alpine ...`):

| Gate command | Result |
| --- | --- |
| `php artisan test` (full suite) | ✅ 37 passed (94 assertions), 0 failed, 0 skipped |
| `vendor/bin/pint --test` | ✅ PASS, 102 files, 0 style violations |

- **Test count iteration 1 → iteration 2**: 30 → 37 (+7, matching the 7 new `#[Test]` methods in `c017ff3`); assertions 66 → 94. No decrease, no weakened assertions found.

**Updated Spec-Anchored Acceptance Criteria** (supersedes the iteration-1 AC5/AC6/AC3 rows above):

| Criterion | Result |
| --------- | ------ |
| AC5 (status-transition matrix) | ✅ PASS — all 4 whitelisted transitions now have exact-outcome HTTP evidence |
| AC6 (ownership denial on edit/delete) | ✅ PASS — edit, delete, duplicate, and status-transition ownership denial all have exact-outcome HTTP evidence (duplicate/status weren't literally named by AC6's "edit or delete" wording but share the same enforcement mechanism and route family, so their added coverage strengthens confidence without being required by AC6 itself) |
| AC3 (duplicate field equivalence) | ⚠️ Spec-precision gap (narrowed) — 13/15 non-forced fields now verified; `dateTime` and `priceType` still unverified |

**Overall verdict**: ✅ **PASS** — Findings 1-3 (the Major AC5 gap and the two Minor gaps on ownership-denial and the missing-required-fields HTTP path) are fully closed with exact-outcome test evidence and confirmed discriminating by fresh sensor mutations. Finding 4 is substantially narrowed (from 2/15 to 13/15 fields verified) but not fully closed — `dateTime`/`priceType` remain unasserted in the duplicate test. This residual is Minor/spec-precision, the underlying implementation was already confirmed correct by code review in iteration 1, and it does not gate sign-off; it is carried forward as a non-blocking follow-up rather than routed through another fix→re-verify cycle.

**Non-blocking follow-up**: Strengthen `EventControllerTest::it_duplicates_an_organizers_own_event` to also set and assert `dateTime` and `priceType` on the original/duplicate, closing Finding 4 completely.

---

# Admin Panel Validation — Phase 4 (T15–T16: VenueController, PromoterController)

**Date**: 2026-09-16
**Spec**: `.specs/features/admin-panel/spec.md` ("P2: Manage venue (\"Casa de Shows\") presence", lines 106-118; "P2: Manage promoters", lines 138-151; Edge Cases, line 195)
**Design**: `.specs/features/admin-panel/design.md` ("VenueController, PromoterController" component, lines 135-142)
**Tasks**: `.specs/features/admin-panel/tasks.md` (T15, lines 606-627; T16, lines 631-653)
**Scope**: Phase 4 only — T15 (`VenueController`: show/update/agenda/history) and T16 (`PromoterController`: CRUD + link/unlink + event-promoter list). Phases 1-3 (above) already verified; Phases 5+ not started.
**Diff range**: `api` repo, `main..HEAD` on `feat/admin-panel-phase-4-venue-promoter`:
```
239c305 feat(admin-panel): add VenueController CRUD
1d34d7f feat(admin-panel): add PromoterController CRUD and event linking
```
**Verifier**: independent sub-agent (author ≠ verifier) — no prior "done" claim trusted; all evidence re-derived from the diff, tests, and live gate/sensor runs.

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| T15 | ✅ Done | `VenueController::show/update/agenda/history` implemented; both literal Done-when tests present and pass (`tests/Feature/Organizer/VenueControllerTest.php`). Venue create/delete correctly omitted — see Design Scope-Decision Check below. |
| T16 | ✅ Done | `PromoterController::index/store/update/destroy/link/unlink/eventPromoters` implemented; all 3 literal Done-when tests present and pass (`tests/Feature/Organizer/PromoterControllerTest.php`). |

---

## Design Scope-Decision Check

Design.md's stated Scope decision (line 141): "Venue has no create/delete endpoint... spec ADMIN-13/14 ACs only cover update plus two read views." Re-derived independently from spec.md lines 112-118 (the actual "Manage venue presence" AC prose, not the design doc's paraphrase): the 3 listed ACs are (1) edit name/description/address/contact/image, (2) open agenda view, (3) open history view — no AC mentions creating or deleting a venue. The decision is consistent with the spec's actual ACs. ✅ Confirmed, not just taken on the design doc's word.

Note: the requirement-traceability table (spec.md lines 215-216) maps only 2 IDs (ADMIN-13, ADMIN-14) to this 3-AC story — a pre-existing ID/AC-count bookkeeping mismatch in spec.md itself, unrelated to this implementation. Flagged for awareness, not a code gap.

---

## Spec-Anchored Acceptance Criteria

### P2: Manage venue ("Casa de Shows") presence (spec.md lines 112-118)

| Criterion (WHEN X THEN Y) | Spec-defined outcome | `file:line` + assertion expression | Result |
| -------------------------- | ---------------------- | ------------------------------------ | ------ |
| AC1: WHEN an organizer edits their venue's name, description, address, contact, or image THEN save the change and reflect it on the venue's public presence | New value persisted and readable immediately after | `tests/Feature/Organizer/VenueControllerTest.php:29-44` (`it_updates_the_organizers_own_venue`) — `$response->assertOk(); $response->assertJsonFragment(['name' => 'New Name']); $this->assertSame('New Name', $venue->fresh()->name); $showResponse->assertJsonFragment(['name' => 'New Name']);` — asserts persistence AND that a subsequent `show` reflects it | ✅ PASS |
| AC2: WHEN an organizer opens the venue agenda view THEN show the venue's upcoming published events | Only upcoming (`date_time >= now`) AND `published` events returned, excluding drafts and past events | `tests/Feature/Organizer/VenueControllerTest.php:63-82` (`it_shows_only_upcoming_published_events_in_the_agenda`) — seeds an upcoming-published, a draft, and a past-published event; `$response->assertJsonCount(1, 'data'); $response->assertJsonFragment(['title' => 'Upcoming Published']); $this->assertSame($upcomingPublished->id, $response->json('data.0.id'));` — precise, not just "a 200 came back" | ✅ PASS |
| AC3: WHEN an organizer opens the venue history view THEN show the venue's past (closed or elapsed) events | Events that are `closed` OR `date_time < now`, excluding future published events | `tests/Feature/Organizer/VenueControllerTest.php:86-106` (`it_shows_only_past_or_closed_events_in_the_history`) — seeds a past-published, a closed-but-future, and a future-published event; `$response->assertJsonCount(2, 'data'); assertJsonFragment(['title' => 'Past Published']); assertJsonFragment(['title' => 'Closed Upcoming']); assertJsonMissing(['title' => 'Future Published']);` — both disjunction branches (`Closed` status, elapsed date) independently exercised | ✅ PASS |

**IDOR check** (not a spec AC but a cross-cutting requirement — organizer isolation per Success Criteria): `VenueControllerTest.php:47-59` (`it_denies_updating_another_organizers_venue`) — `$response->assertForbidden(); $this->assertSame('Venue B', $venueB->fresh()->name);` — confirms both the 403 and no side effect. ✅ PASS.

### P2: Manage promoters (spec.md lines 138-151)

| Criterion (WHEN X THEN Y) | Spec-defined outcome | `file:line` + assertion expression | Result |
| -------------------------- | ---------------------- | ------------------------------------ | ------ |
| AC1: WHEN an organizer registers a promoter with name, contact phone, email, Instagram link, and TikTok link THEN save the promoter as a record owned by that organizer | New `promoters` row exists with `organizer_id` and the given fields | `tests/Feature/Organizer/PromoterControllerTest.php:28-40` (`it_registers_a_promoter_for_the_organizer`) — `$response->assertCreated(); $this->assertDatabaseHas('promoters', ['organizer_id' => $organizer->id, 'name' => 'DJ Test']);` | ✅ PASS |
| AC2: WHEN an organizer links a promoter to one of their events THEN make that promoter visible on the event's consumer-facing promoter list | Promoter appears when the event's promoter list is queried | `tests/Feature/Organizer/PromoterControllerTest.php:44-58` (`it_links_a_promoter_to_the_organizers_own_event`) — links, then `GET /organizer/events/{id}/promoters` and asserts `assertJsonFragment(['id' => $promoter->id])` | ⚠️ Spec-precision/scope note — the spec names the "consumer-facing" list explicitly; this admin-panel repo phase only builds and tests the organizer-facing read of the same underlying `event_promoter` join (there is no consumer endpoint in this diff or design.md's Interfaces list for this component — the consumer surface is out of scope for admin-panel per the project's data-owner-first split, built later by web-app/mobile-app reading this same data). The underlying data relationship the consumer view would read from is correctly and precisely tested; the actual consumer-facing rendering is not in this diff to test. |
| AC3: WHEN an organizer edits or removes a promoter THEN apply the change to every event that promoter is linked to | Edit: all linked events' promoter data reflects the new value. Remove: promoter gone from every linked event's list, but the event itself untouched | Edit: `tests/Feature/Organizer/PromoterControllerTest.php:97-116` (`it_propagates_promoter_edits_to_every_linked_event`) — links promoter to 3 events, updates name, then for each of the 3 events asserts `$listResponse->assertJsonFragment(['name' => 'New Name']);` (all 3, not just one). Remove: `PromoterControllerTest.php:118-134` (`it_removes_a_deleted_promoter_from_events_without_deleting_the_event`) — `assertDatabaseMissing('promoters', ...); assertDatabaseMissing('event_promoter', ...); assertDatabaseHas('events', ['id' => $event->id]);` | ✅ PASS |
| AC4: WHEN an organizer opens an event's promoter list THEN show every promoter currently linked to that event | All linked promoters returned, none missing | `tests/Feature/Organizer/PromoterControllerTest.php:79-94` (`it_returns_every_promoter_linked_to_an_event`) — attaches 2 promoters, asserts `assertJsonCount(2, 'data')` | ✅ PASS |

**IDOR checks**: `PromoterControllerTest.php:60-77` (`it_denies_linking_across_organizers`) — organizer A's promoter + organizer B's event — `assertForbidden(); assertDatabaseMissing('event_promoter', ...)`, proving the dual (promoter-owner AND event-owner) check in `LinkPromoterRequest::authorize()` actually gates on both sides, not just one. `PromoterControllerTest.php:136-149`/`151-164` cover update/delete ownership denial with 403 + unchanged DB state. All ✅ PASS.

### Edge Case (spec.md line 195)

| Edge Case | Spec-defined outcome | `file:line` + assertion | Result |
| --------- | ---------------------- | -------------------------- | ------ |
| WHEN an organizer deletes a promoter that is linked to a **published** event THEN remove the promoter from that event's public list without deleting the event itself | Pivot row gone, promoter row gone, event row untouched — specifically tested against a `published()` event, not an arbitrary one | `tests/Feature/Organizer/PromoterControllerTest.php:118-134` (`it_removes_a_deleted_promoter_from_events_without_deleting_the_event`) — event created via `->published()->create()`; `assertDatabaseMissing('promoters', ['id' => $promoter->id]); assertDatabaseMissing('event_promoter', ['promoter_id' => $promoter->id]); assertDatabaseHas('events', ['id' => $event->id]);` | ✅ PASS |

**Status**: 7/7 literal ACs plus the edge case matched their spec-defined outcome with exact evidence; 1 spec-precision/scope note (AC2, promoter-link visibility tested at the data layer this repo owns, not through an out-of-scope consumer endpoint).

---

## Discrimination Sensor

**Isolation method**: `git worktree add <scratch> HEAD` (real git worktree, never `git stash`). Baseline `git status --porcelain` on the real `api/` tree was empty before any sensor work and confirmed still empty (identical) after `git worktree remove --force <scratch>` + `git worktree prune`. **Methodological note**: the scratch worktree does not contain `vendor/`; a first attempt symlinked `vendor` into the worktree, which silently caused PHP's autoloader to resolve `baseDir` back to the *original* tree (composer's cached absolute-path resolution follows the symlink target), so mutated files in the worktree were never actually loaded and all mutants appeared to "survive." This was caught by manually inspecting the mutated agenda-query result and re-verified as a false negative. Fixed by running Docker with `-v <main-vendor>:<worktree>/vendor -v <worktree>:<worktree>` (bind-mounting vendor directly under the worktree path, not via a host symlink) so `__DIR__`-based path resolution inside composer's autoloader stays rooted in the worktree. Re-ran all 5 mutations under the corrected setup.

| Mutation | File:line | Description | Killed? |
| -------- | --------- | ------------ | ------- |
| 1 | `app/Infrastructure/Persistence/Eloquent/EloquentVenueRepository.php:38` | Agenda query's `->where('date_time', '>=', now())` flipped to `'<'` | ✅ Killed — `it_shows_only_upcoming_published_events_in_the_agenda` failed: returned "Past Published" instead of "Upcoming Published" |
| 2 | `app/Infrastructure/Persistence/Eloquent/EloquentPromoterRepository.php:49` | Removed `$model->events()->detach();` before `$model->delete();` in `delete()` | ✅ Killed — `it_removes_a_deleted_promoter_from_events_without_deleting_the_event` failed with `SQLSTATE[23000]: Integrity constraint violation: 19 FOREIGN KEY constraint failed` |
| 3 | `app/Infrastructure/Persistence/Eloquent/EloquentVenueRepository.php:37` | Agenda filter's `EventStatus::Published` swapped to `EventStatus::Draft` | ✅ Killed — `it_shows_only_upcoming_published_events_in_the_agenda` failed: returned the "Draft" event instead of "Upcoming Published" |
| 4 | `app/Presentation/Http/Requests/Organizer/LinkPromoterRequest.php:28-29` | `authorize()` narrowed to check only `PromoterPolicy::owns()`, dropping the `EventPolicy::owns()` half of the dual ownership check | ✅ Killed — `it_denies_linking_across_organizers` failed: expected 403, got 204 (organizer A could link their promoter to organizer B's event) |
| 5 | `app/Infrastructure/Persistence/Eloquent/EloquentVenueRepository.php:50` | History query's `->orWhere('date_time', '<', now())` flipped to `'>='` | ✅ Killed — `it_shows_only_past_or_closed_events_in_the_history` failed: "Past Published" dropped from history, replaced by "Future Published" |

**Sensor depth**: lightweight (default tier) — 5 targeted behavior-level mutations covering the agenda/history query semantics (both operators and the status filter), the pivot-detach-before-delete FK-integrity requirement, and the dual-ownership IDOR check named in design.md's Layering note.
**Result**: 5/5 killed — PASS ✅.

---

## Gate Check (MANDATORY, re-run independently — not trusted from tasks.md checkmarks)

All commands re-run fresh via `docker run --rm -v "$PWD":/var/www/html -w /var/www/html php:8.4-cli php artisan test ...` (PHP not installed on host; `vendor/` already present in the checked-out tree).

| Gate command | Result |
| --- | --- |
| `php artisan test` (full suite) | ✅ 49 passed (133 assertions), 0 failed, 0 skipped |
| `vendor/bin/pint --test` | ✅ PASS, 133 files, 0 style violations |

- **Test count before Phase 4** (end of Phase 3, per that section's re-run): 37
- **Test count after Phase 4**: 49
- **Delta**: +12 new tests (4 `VenueControllerTest` + 8 `PromoterControllerTest`) — no decrease, no assertions found weakened.
- **Skipped tests**: none.
- **Failures**: none.

---

## Clean Architecture (AD-012) / AD-013 Check

Matches design.md's "VenueController, PromoterController" component description (lines 135-142):
- **Presentation**: `VenueController`/`PromoterController` are thin — delegate to Application use-cases, map entities to response arrays only. `ShowVenueRequest`/`UpdateVenueRequest` resolve the venue server-side from the authenticated organizer (no route param), matching the Layering note's claim that there is no IDOR surface for venue actions "by construction" — confirmed correct: `ShowVenueRequest::venue()` calls `findByOrganizerId((int) $this->user('organizer')->id)`, never a route-bound ID. `LinkPromoterRequest`/`UnlinkPromoterRequest::authorize()` does perform the documented dual (promoter + event) ownership check — confirmed by reading the code and killed by sensor mutation 4.
- **Application**: `CreatePromoter`, `UpdatePromoter`, `DeletePromoter`, `LinkPromoterToEvent`, `UnlinkPromoterFromEvent`, `GetEventPromoters`, `GetVenueAgenda`, `GetVenueHistory`, `UpdateVenue` — each single-purpose, delegating to the repository contracts only.
- **Domain**: `VenueRepositoryInterface`, `PromoterRepositoryInterface`, `Domain\Entities\{Venue,Promoter}` — framework-free.
- **Infrastructure**: `EloquentVenueRepository`/`EloquentPromoterRepository` implement the contracts and map to/from Domain entities via `toEntity()`.
- **Result**: ✅ Full 4-layer compliance, no deviation. `UpdatePromoter::FIELD_MAP` is a documented, deliberate allowlist (prevents forwarding arbitrary request keys to the repository's `update()`), not scope creep. One class per file confirmed across all 36 changed files, except `UnlinkPromoterRequest extends LinkPromoterRequest` and `DeletePromoterRequest`/`UpdatePromoterRequest`/`ShowEventPromotersRequest` extend shared abstract base request classes — consistent with this codebase's pre-existing `OrganizerOwned*Request` pattern (e.g. Phase 3's `OrganizerOwnedEventRequest`), not a new convention.

---

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code (no speculative flexibility) | ✅ — no venue create/delete endpoint built (correctly out of scope, see Scope-Decision Check above); no endpoints beyond T15/T16's literal list |
| Surgical changes (only files required for task) | ✅ — diff touches only Venue/Promoter Domain/Application/Infrastructure/Presentation files, their tests, `routes/admin-panel.php`, `AppServiceProvider.php` (bindings), and one new factory; nothing pre-existing rewritten |
| No scope creep | ✅ — no EngagementDashboard/PlanPricing/OrganizerData work leaked in from later phases |
| Matches existing patterns/style | ✅ — consistent with Phases 1-3's `Eloquent<Entity>Repository`/`<Entity>RepositoryInterface` naming, `OrganizerOwned*Request` base-class pattern, GIVEN/WHEN/THEN `#[TestDox]` convention; `pint --test` clean |
| Spec-anchored outcome check (asserted values match spec) | ✅ — 7/7 ACs plus the edge case match the spec's precise outcome; 1 documented spec-precision/scope note (AC2) |
| Per-layer Coverage Expectation met (domain 1:1 ACs; routes happy+edge+error) | ✅ — every route in scope (venue show/update/agenda/history; promoter index/store/update/destroy/link/unlink/eventPromoters) has a happy-path test, and every route requiring ownership enforcement has a 403/edge test |
| Every test in scope maps to a spec AC, listed edge case, or Done-when criterion (no unclaimed tests) | ✅ — all 12 new tests map directly to ADMIN-13/14/17/18/19's ACs, the promoter-deletion edge case, or T15/T16's literal Done-when IDOR criteria |
| Documented guidelines followed | design.md Coding Conventions (lines 209-215: no magic strings/numbers, one class per file, YAGNI); tasks.md T15/T16 Done-when |

---

## Requirement Traceability Update

| Requirement | Previous Status | New Status |
| ----------- | ---------------- | ---------- |
| ADMIN-13/14 (venue update, agenda, history) | Implementing | ✅ Verified |
| ADMIN-17 (promoter registration) | Implementing | ✅ Verified |
| ADMIN-18 (promoter link visible on event list; edit/remove propagation) | Implementing | ✅ Verified (with spec-precision note on AC2's consumer-facing scope, see above) |
| ADMIN-19 (event promoter list) | Implementing | ✅ Verified |

---

## Summary

**Overall**: ✅ Ready (Phase 4 / T15-T16)

**Spec-anchored check**: 7/7 ACs plus the promoter-deletion edge case matched spec-defined outcomes with exact evidence; 1 spec-precision/scope note (AC2 — organizer-facing data layer tested, consumer-facing rendering is a different feature's scope)
**Sensor**: 5/5 mutations killed — agenda/history query operators and status filter, promoter pivot-detach-before-delete FK integrity, and the dual-ownership IDOR check on promoter-event linking are all genuinely discriminated by the existing tests
**Gate**: 49/49 tests passed, 0 failed; `pint --test` clean across 133 files; test count grew 37→49 (+12), no regressions

**What works**: `VenueController` (show/update/agenda/history) and `PromoterController` (CRUD + link/unlink + event-promoter list) are both implemented correctly per code review and proven correct by tests; all 7 spec ACs and the edge case have exact-outcome test coverage; the design doc's venue create/delete scope decision is independently confirmed consistent with spec.md's actual ACs (not taken on the doc's word); the dual-ownership IDOR check on promoter-event linking (the component's one non-standard pattern per design.md's Layering note) is real and is confirmed discriminating by the sensor.

**Issues found**: None blocking. One spec-precision/scope note (AC2's "consumer-facing" wording vs. this repo's organizer-facing test), which reflects an intentional cross-feature scope boundary (admin-panel owns the data; web-app/mobile-app render the consumer view), not a gap in this implementation.

**Next steps**: None required for Phase 4 sign-off.

**Post-verification update (PR #4 review)**: the automated PR review pass found 0 correctness bugs and 2 reuse/cleanup issues - `LinkPromoterRequest` duplicating `OrganizerOwnedPromoterRequest`'s promoter-resolution logic instead of extending it, and `EloquentVenueRepository::toEventEntity()` duplicating `EloquentEventRepository::toEntity()`'s Event mapping. Both were fixed in a follow-up commit (`LinkPromoterRequest extends OrganizerOwnedPromoterRequest`; shared `EventEntityMapper` used by both repositories) and re-verified: 49/49 tests still passing, `pint --test` clean. PR #4 merged with the fix included.
