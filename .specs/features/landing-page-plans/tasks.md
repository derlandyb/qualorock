# Landing Page & Plans Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Design**: `.specs/features/landing-page-plans/design.md`  
**Status**: Draft

---

## Coding Conventions (MANDATORY)

Per AD-012 (Clean Architecture) and AD-013 (code quality), every task in this file follows these rules without restating them per task:

- **4 layers**: the public backend endpoints follow `Domain` (repository contracts, shared with admin-panel's `Organizer` contract - not redefined here) ← `Application` (use-cases: `SignupOrganizer`, `ReadCurrentPlanPrice`, `CheckOrganizerStatus`) → `Infrastructure` (reuses admin-panel's Eloquent repositories) and `Presentation` (thin controllers). The `landingpage` React SPA mirrors it with `landingpage/src/{domain,application,infrastructure,presentation}`.
- **`ConsentRecord` gets a `Domain/Contracts/ConsentRecordRepositoryInterface.php`** with no separate entity class beyond the Eloquent model, per YAGNI - it's a simple append-only record with no independent business rule.
- **No magic numbers/strings**: the signup rate-limit thresholds are named constants in `backend/app/Domain/Constants/PublicSignupConstants.php` and `landingpage/src/domain/constants/landingPageConstants.ts`.
- **One class per file**, PHP and TypeScript/TSX alike.
- **No task/ticket-referencing comments in code** (AD-014) - rationale lives in `design.md` and `docs/landing-page-plans/architecture.md`.

---

## Test Coverage Matrix

> Guidelines found: .specs/STATE.md AD-010/AD-011. No dedicated Stitch screen exists for this feature (the 33-screen Stitch project projects/4886677589059011690 only covers the mobile/web consumer app and has no 'landing page' or 'plans' screen). Per the same brand family (AD-004: one product, 'Qual o Rock?'), the landing page reuses the web-app's verified Stitch design-system tokens (colors, typography, button/card specs) rather than inventing an unrelated visual language - flagged as an assumption, same treatment web-app gave its Notifications screen.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------- | --------------------- | ----------------- | ----------- |
| Eloquent model / migration | none | - (build gate only) | backend/app/Models/*.php, backend/database/migrations/* | php artisan migrate --pretend |
| Controller / route (feature) | integration | All routes in scope: happy path + every listed edge case + error/failure paths, GIVEN/WHEN/THEN named | backend/tests/Feature/Public/**/*Test.php | php artisan test --testsuite=Feature |
| React component (form/section) | unit | All branches; loading/error/success states covered (PlanComparisonSection, SignupForm per design.md Test Plan) | landingpage/src/**/__tests__/*.test.tsx | npm --prefix landingpage test |
| Screen / UI layout | visual | Screen matched against the reused Stitch design-system tokens (no dedicated screen exists - token-consistency check, same treatment as web-app's Notifications screen) | landingpage/e2e/visual/*.spec.ts | npx --prefix landingpage playwright test e2e/visual |
| E2E flow | e2e | Full signup flow per design.md Test Plan (valid signup -> pending in admin-panel; duplicate-email; rejected-email resubmission) | landingpage/e2e/*.spec.ts | npx --prefix landingpage playwright test |
| Developer documentation | none | - (build gate only): documents the Clean Architecture layering and conventions for this feature | docs/landing-page-plans/*.md | test -f docs/landing-page-plans/architecture.md |

## Gate Check Commands

> Generated from AD-010/AD-011 - confirm before Execute once backend/landingpage scaffolding exists (infrastructure/tasks.md Phase 0). This feature's signup endpoint depends on admin-panel's Organizer model (see admin-panel/tasks.md T1) already existing.

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After tasks with unit tests only (models, React components) | php artisan test --testsuite=Unit && npm --prefix landingpage test |
| Full | After tasks with integration/e2e/visual tests (controllers, screens) | php artisan test && npm --prefix landingpage test && npx --prefix landingpage playwright test |
| Build | After phase completion or config/migration-only tasks | php artisan test && npm --prefix landingpage run build && npx --prefix landingpage playwright test |

---

## Execution Plan

Phases are ordered and run sequentially - each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Public backend: consent record, price read, signup, status-check

All four endpoints are unauthenticated (no session guard) per design.md - the signup endpoint is the platform's only unauthenticated write and gets its own rate limiting.

```
T1 -> T3
T3 -> T4
```

### Phase 2: Screen: Landing page (plan comparison + signup) and confirmation/status-check

No dedicated Stitch screen exists for this feature - reuses the verified 'Qual o Rock?' design-system tokens (same brand, per AD-004) for visual consistency with web-app/mobile-app rather than an unreferenced one-off style.

```
T2 -> T5
T3 -> T5
T5 -> T6
T3 -> T7
T4 -> T7
T7 -> T8
```

### Phase 3: Clean Architecture scaffolding: constants & docs (AD-012..AD-014)

Concrete artifacts for the new architecture decisions.

```
T3 -> T9
T9 -> T10
```

---

## Task Breakdown

### T1: ConsentRecord migration + model

**What**: Migration and Eloquent model for `ConsentRecord` (organizerId FK, consentedAt, consentVersion) tying a signup's consent to a specific privacy-policy revision.
**Where**: `backend/database/migrations/xxxx_create_consent_records_table.php, backend/app/Infrastructure/Persistence/Eloquent/ConsentRecord.php`
**Depends on**: None
**Reuses**: admin-panel's Organizer migration (see admin-panel/tasks.md T1) must exist first for the FK, even though that dependency crosses tasks.md files and isn't expressed as a local `Depends on`
**Requirement**: PLAN-12

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Migration FKs `organizer_id` to `organizers`
- [ ] Model defines `belongsTo(Organizer::class)`
- [ ] `php artisan migrate --pretend` runs without error

**Tests**: none
**Gate**: build

**Commit**: `feat(landing-page-plans): add ConsentRecord migration and model`

---

### T2: Public plan-price read endpoint

**What**: `GET /public/plan-prices` - unauthenticated, read-only proxy over admin-panel's `PlanPrice` table returning the current Basic (always free) and Plus (live) prices.
**Where**: `backend/app/Presentation/Http/Controllers/Public/PlanPriceController.php`
**Depends on**: None
**Reuses**: admin-panel's PlanPrice model (see admin-panel/tasks.md T5)
**Requirement**: PLAN-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN the current Plus price WHEN requested THEN it returns without requiring authentication - test passes
- [ ] GIVEN no Plus price has ever been set THEN the endpoint returns a graceful empty/null value rather than erroring - test passes
- [ ] Gate check passes: `php artisan test --filter=PublicPlanPrice`

**Tests**: integration
**Gate**: full

**Commit**: `feat(landing-page-plans): add public plan-price read endpoint`

---

### T3: PublicSignupController (rate-limited)

**What**: `POST /public/organizer-signup` - validates required fields + email format, creates a `pending`/`basic` Organizer and a ConsentRecord, rejects duplicate pending/approved emails with 409, surfaces rejection context for a previously-`rejected` email (409), requires `consentGiven: true` server-side, and applies an IP+email throttle per design.md's Risks table.
**Where**: `backend/app/Presentation/Http/Controllers/Public/OrganizerSignupController.php`
**Depends on**: T1
**Requirement**: PLAN-02, PLAN-03, PLAN-04, PLAN-05, PLAN-06, PLAN-12

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN valid signup fields with consent THEN an Organizer row is created with state=`pending`, tier=`basic`, and a ConsentRecord is created with the current `consentVersion` - test passes
- [ ] GIVEN a missing required field or invalid email THEN the response is 422 with field-level errors - test passes
- [ ] GIVEN an email already `pending` or `approved` THEN the response is 409 with a generic 'account already exists' message - test passes
- [ ] GIVEN an email previously `rejected` THEN the response is 409 surfacing that prior rejection context (not a silent new pending account) - test passes
- [ ] GIVEN `consentGiven` is missing or false THEN the response is 422 even if the client-side checkbox was bypassed - test passes
- [ ] GIVEN repeated signup attempts from the same IP/email beyond the throttle threshold THEN subsequent attempts are rate-limited - test passes
- [ ] Gate check passes: `php artisan test --filter=OrganizerSignup`

**Tests**: integration
**Gate**: full

**Commit**: `feat(landing-page-plans): add rate-limited public organizer signup endpoint`

---

### T4: Public status-check endpoint

**What**: `GET /public/organizer-status` - lets the email owner re-check their own pending/approved/rejected state (not a public lookup by arbitrary email, per design.md's Risks table - requires the same email+a submitted token/secret from the confirmation step, not just a bare email query param).
**Where**: `backend/app/Presentation/Http/Controllers/Public/OrganizerStatusController.php`
**Depends on**: T3
**Requirement**: PLAN-10

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN the correct email+status-check token THEN the current approvalState is returned - test passes
- [ ] GIVEN an incorrect or missing token THEN the endpoint does not reveal whether that email exists at all (generic response) - test passes
- [ ] Gate check passes: `php artisan test --filter=OrganizerStatus`

**Tests**: integration
**Gate**: full

**Commit**: `feat(landing-page-plans): add public organizer status-check endpoint`

---

### T5: Build landing page (hero, plan comparison, signup form, privacy link)

**What**: Public single-page: value-proposition hero, `PlanComparisonSection` (live Plus price with fallback copy on fetch failure), `SignupForm` (all fields + required consent checkbox, not pre-checked), a signup CTA reachable from anywhere on the page (sticky or repeated), and the `PrivacyPolicyLink`/DPO surface.
**Where**: `landingpage/src/presentation/pages/Landing.tsx`
**Depends on**: T2, T3
**Requirement**: PLAN-01, PLAN-02, PLAN-07, PLAN-08, PLAN-09, PLAN-12, PLAN-13

**Tools**:

- MCP: Playwright MCP, Stitch MCP
- Skill: NONE

**Done when**:

- [ ] Reuses the verified 'Qual o Rock?' design-system tokens: primary CTA = pill, solid `#ff7a3d` fill, 14px/28px padding, hover `translateY(-2px)`+glow (same Button spec verified for web-app); plan cards = `1rem` radius, `#1c1c20` surface (same Card spec)
- [ ] GIVEN the Plus-price fetch fails THEN the page shows 'Pricing temporarily unavailable - contact us' and signup remains usable (fail-open per design.md's Tech Decision) - not a blocking error state
- [ ] Consent checkbox is unchecked by default and required before submit is enabled; the privacy-policy/DPO link sits directly beside it
- [ ] Signup CTA is reachable without scrolling back to the top from anywhere on the page (sticky header or repeated CTA block)
- [ ] Page reflows correctly at mobile/tablet/desktop breakpoints per the design system's spacing tokens
- [ ] A separate cookie-consent banner (not the signup consent checkbox) gates the GA script per design.md's Risks table

**Tests**: visual
**Gate**: quick

**Commit**: `feat(landing-page-plans): add landing page with plan comparison and signup form`

---

### T6: Verify Screen: Landing page token consistency

**What**: Screenshot the running landing page with Playwright and confirm its colors/typography/spacing/button styling match the same verified 'Qual o Rock?' design-system tokens used on web-app's screens (no dedicated Stitch screenshot exists to diff directly against, same treatment as web-app's Notifications screen).
**Where**: `landingpage/e2e/visual/landing.spec.ts`
**Depends on**: T5
**Requirement**: PLAN-01, PLAN-07, PLAN-08, PLAN-09, PLAN-12, PLAN-13

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Button/card/typography tokens match the verified design-system values exactly
- [ ] Consent checkbox and privacy-policy link are both visible without scrolling on the signup section
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(landing-page-plans): verify landing page against design-system tokens`

---

### T7: Build signup confirmation + status-check page

**What**: Post-signup confirmation screen ('pending Super Admin approval') with a status-check link, and the status-check page itself; shows an external billing link only once the checked status is `approved` (PLAN-11).
**Where**: `landingpage/src/presentation/pages/SignupConfirmation.tsx, landingpage/src/presentation/pages/StatusCheck.tsx`
**Depends on**: T3, T4
**Requirement**: PLAN-05, PLAN-10, PLAN-11

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Confirmation screen reuses the T5 design-system tokens (card surface, typography)
- [ ] Status-check page calls T4's endpoint and renders pending/approved/rejected states distinctly
- [ ] GIVEN the checked status is `approved` THEN an external billing link is shown; GIVEN `pending`/`rejected` THEN it is not shown at all (not shown-but-disabled)

**Tests**: visual
**Gate**: quick

**Commit**: `feat(landing-page-plans): add signup confirmation and status-check pages`

---

### T8: Verify Screen: Confirmation/status-check token consistency

**What**: Screenshot the confirmation and status-check pages, confirm token consistency with the rest of the app.
**Where**: `landingpage/e2e/visual/confirmation-status.spec.ts`
**Depends on**: T7
**Requirement**: PLAN-05, PLAN-10, PLAN-11

**Tools**:

- MCP: Playwright MCP
- Skill: NONE

**Done when**:

- [ ] Card/typography tokens match the verified design-system values
- [ ] The approved-only billing link's conditional visibility is confirmed for all three states
- [ ] Any mismatch is filed as a fix note before this phase is marked done

**Tests**: visual
**Gate**: quick

**Commit**: `test(landing-page-plans): verify confirmation and status-check pages`

---

### T9: PublicSignupConstants (backend + frontend, no magic numbers/strings)

**What**: Named constants for the signup rate-limit thresholds (attempts per IP/email per window) and the HTTP status codes used in the Error Handling table, replacing bare literals.
**Where**: `backend/app/Domain/Constants/PublicSignupConstants.php, landingpage/src/domain/constants/landingPageConstants.ts`
**Depends on**: T3
**Requirement**: AD-013 (code quality)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Rate-limit thresholds are defined exactly once, backend and frontend
- [ ] T3 (PublicSignupController) references these constants instead of bare literals

**Tests**: none
**Gate**: build

**Commit**: `refactor(landing-page-plans): extract named constants for rate-limit thresholds`

---

### T10: docs/landing-page-plans/architecture.md

**What**: Markdown write-up of this feature's Clean Architecture layering (AD-012) and coding conventions (AD-013).
**Where**: `docs/landing-page-plans/architecture.md`
**Depends on**: T9
**Requirement**: AD-014 (documentation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Doc explains all 4 layers with one concrete example path per layer from this feature
- [ ] Doc states the no-magic-numbers, one-class-per-file, and no-task-comments rules

**Tests**: none
**Gate**: build

**Commit**: `docs(landing-page-plans): add architecture.md documenting Clean Architecture layering`

---

## Phase Execution Map

Visual representation of task ordering. Phases run in sequence, and tasks within a phase run in order:

```
Phase 1 -> Phase 2 -> Phase 3

Phase 1:  T1 ------> T3
Phase 1:  T3 ------> T4
Phase 2:  T2 ------> T5
Phase 2:  T3 ------> T5
Phase 2:  T5 ------> T6
Phase 2:  T3 ------> T7
Phase 2:  T4 ------> T7
Phase 2:  T7 ------> T8
Phase 3:  T3 ------> T9
Phase 3:  T9 ------> T10
```

Execution is strictly sequential - there is no intra-phase parallelism. A single agent (or batch worker) works one task at a time, in order.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1: ConsentRecord migration + model | 1 model + 1 migration | ✅ Granular |
| T2: Public plan-price read endpoint | 1 file | ✅ Granular |
| T3: PublicSignupController (rate-limited) | 1 file | ✅ Granular |
| T4: Public status-check endpoint | 1 file | ✅ Granular |
| T5: Build landing page (hero, plan comparison, signup form, privacy link) | 1 file | ✅ Granular |
| T6: Verify Screen: Landing page token consistency | 1 file | ✅ Granular |
| T7: Build signup confirmation + status-check page | 2 files (cohesive - confirmation and status-check are one linked flow) | ✅ Granular |
| T8: Verify Screen: Confirmation/status-check token consistency | 1 file | ✅ Granular |
| T9: PublicSignupConstants (backend + frontend, no magic numbers/strings) | 2 files (cohesive - one constants set, backend + frontend mirror) | ✅ Granular |
| T10: docs/landing-page-plans/architecture.md | 1 file | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ----------------------- | -------------- | ------ |
| T1 | None | None | ✅ Match |
| T2 | None | None | ✅ Match |
| T3 | T1 | T1 | ✅ Match |
| T4 | T3 | T3 | ✅ Match |
| T5 | T2, T3 | T2, T3 | ✅ Match |
| T6 | T5 | T5 | ✅ Match |
| T7 | T3, T4 | T3, T4 | ✅ Match |
| T8 | T7 | T7 | ✅ Match |
| T9 | T3 | T3 | ✅ Match |
| T10 | T9 | T9 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | ---------------------------- | ---------------- | ---------- | ------ |
| T1: ConsentRecord migration + model | Eloquent model / migration | none | none | ✅ OK |
| T2: Public plan-price read endpoint | Controller / route (feature) | integration | integration | ✅ OK |
| T3: PublicSignupController (rate-limited) | Controller / route (feature) | integration | integration | ✅ OK |
| T4: Public status-check endpoint | Controller / route (feature) | integration | integration | ✅ OK |
| T5: Build landing page (hero, plan comparison, signup form, privacy link) | React component (form/section) | visual | visual | ✅ OK |
| T6: Verify Screen: Landing page token consistency | Screen / UI layout | visual | visual | ✅ OK |
| T7: Build signup confirmation + status-check page | React component (form/section) | visual | visual | ✅ OK |
| T8: Verify Screen: Confirmation/status-check token consistency | Screen / UI layout | visual | visual | ✅ OK |
| T9: PublicSignupConstants (backend + frontend, no magic numbers/strings) | Eloquent model / migration | none | none | ✅ OK |
| T10: docs/landing-page-plans/architecture.md | Developer documentation | none | none | ✅ OK |

---

## Tools & Skills for Execution

**Available MCPs for these tasks**: Playwright MCP (`mcp__plugin_playwright_playwright__*`) and Stitch MCP (`mcp__stitch__get_screen`) for screen tasks; NONE for backend tasks.

**Available Skills for these tasks**: NONE

