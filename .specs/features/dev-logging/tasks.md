# Dev-Logging Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Design**: `.specs/features/dev-logging/design.md`
**Status**: Draft

---

**Prerequisite note (read before Execute):** every `api`/web/mobile component below targets a real Laravel/Vite/KMP application skeleton that does not exist yet - `admin-panel`/`web-app`/`landing-page-plans`/`mobile-app`'s own Execute passes haven't started, so `api/`, `website/`, `admin/`, `landingpage/`, and `mobile/` currently contain only their `infrastructure`-authored Dockerfile (or nothing, for `mobile/`). This is the same situation `infrastructure`'s T1-T4 hit: tasks are written against the target file paths from `design.md`, but their gates will be **DEFERRED** at Execute time until a minimal app skeleton exists per stack - exactly like `infrastructure`'s Dockerfile build gates were deferred. Do not fabricate a passing gate for a skeleton that isn't there.

---

## Test Coverage Matrix

> Guidelines found: `.specs/STATE.md` AD-010 (Pest backend, Jest+RTL web, `kotlin.test` for the shared KMP module, GIVEN/WHEN/THEN test names, >=80% coverage) and AD-011 (CI gates). No test files exist yet in this repo for any of the three toolchains - the commands below are the standard entrypoints for the tools AD-010 already mandates, to run once each stack's own skeleton exists.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------- | --------------------- | ----------------- | ----------- |
| api Infrastructure/Logging (`SensitiveFieldRedactor`, `RequestIdLogProcessor`, `QueryLogListener`) | unit | All branches; 1:1 to spec ACs (LOG-01/03/05/06); every listed edge case (nested-key redaction, truncation) has a test, GIVEN/WHEN/THEN named | `api/tests/Unit/Infrastructure/Logging/*Test.php` | `php artisan test --testsuite=Unit` |
| api Infrastructure/Http/Middleware (`CorrelationIdMiddleware`, `DebugRequestLogger`) | integration | Every behavior in scope: header generated when absent, header reused when present, debug-mode body/status logging, `APP_DEBUG=false` produces no debug log line, GIVEN/WHEN/THEN named | `api/tests/Feature/Logging/*Test.php` | `php artisan test --testsuite=Feature` |
| api debug-logging config wiring (`config/logging.php`, conditional service-provider registration) | none | - (build gate only): `docker compose config -q` still exits 0 after new env vars are added | `docker-compose.yml`, `api/.env.example` | `docker compose config -q` |
| Web `devLogger` (website/admin/landingpage) | unit | DEV/no-op branches covered for every exported method (`debug`/`info`/`warn`/`error`), GIVEN/WHEN/THEN named | `website/src/infrastructure/logging/*.test.ts`, `admin/src/infrastructure/logging/*.test.ts`, `landingpage/src/infrastructure/logging/*.test.ts` | `npm --prefix website test`, `npm --prefix admin test`, `npm --prefix landingpage test` |
| Mobile `Logger` (KMP shared) | unit | Debug/release no-op branches and `event()`'s structured output shape covered, GIVEN/WHEN/THEN named | `mobile/shared/src/commonTest/.../LoggerTest.kt` | `./gradlew :shared:test` |
| Developer documentation | none | - (build gate only): every stack's `docs/*/architecture.md` states its debug-logging behavior | `docs/{backend,web-app,admin-panel,landing-page-plans,mobile,infrastructure}/architecture.md` | `grep -qi 'debug' docs/backend/architecture.md` (repeated per stack) |

## Gate Check Commands

> Generated from AD-010/AD-011 - confirm before Execute once each stack's own skeleton exists (per this file's Prerequisite note above).

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | After tasks with unit tests only (Logging classes, devLogger, mobile Logger) | `php artisan test --testsuite=Unit` (api tasks) / `npm --prefix <app> test` (web tasks) / `./gradlew :shared:test` (mobile tasks) |
| Full | After tasks with integration tests (middleware) | `php artisan test` |
| Build | After phase completion or config-only tasks | `docker compose config -q && php artisan test && npm --prefix website test && npm --prefix admin test && npm --prefix landingpage test && ./gradlew :shared:test` |

---

## Execution Plan

Phases are ordered and run sequentially - each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: api logging infrastructure

```
T1  T2
T1 -> T3
T2 -> T4
T1 -> T5
T2 -> T5
T1 -> T6
T3 -> T6
T4 -> T6
T5 -> T6
```

### Phase 2: Web apps' dev-gated logger

```
T7  T8  T9
```

### Phase 3: Mobile shared logger

```
T10 -> T11
```

### Phase 4: Documentation (AD-014)

```
T6 -> T12
T7 -> T12
T8 -> T12
T9 -> T12
T11 -> T12
T12 -> T13
```

---

## Task Breakdown

### T1: Create `CorrelationIdMiddleware`

**What**: Middleware that resolves an `X-Request-Id` from the inbound request header (or generates a UUIDv4 if absent), binds it into the container under a resolvable key, and sets it on the response header.
**Where**: `api/app/Infrastructure/Http/Middleware/CorrelationIdMiddleware.php`
**Depends on**: None
**Reuses**: none - first piece of `api` application code
**Requirement**: LOG-01, LOG-02, LOG-14

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a request without `X-Request-Id` WHEN the middleware runs THEN it generates a UUIDv4, binds it into the container, and sets it on the response header
- [ ] GIVEN a request with an existing `X-Request-Id` (including a non-UUID value) WHEN the middleware runs THEN it reuses that exact value instead of generating a new one
- [ ] GIVEN two concurrent requests WHEN both are handled THEN each resolves its own container-bound ID with no cross-request leakage (test asserts via two independent test-client calls, not a shared static)
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `php artisan test --testsuite=Unit`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add CorrelationIdMiddleware`

---

### T2: Create `SensitiveFieldRedactor`

**What**: A class that recursively redacts configured field names (case-insensitive, any nesting depth) from an array, replacing matched values with `"[REDACTED]"`.
**Where**: `api/app/Infrastructure/Logging/SensitiveFieldRedactor.php`, `api/config/logging.php` (new `debug_redacted_fields` config key, seeded with `password`, `password_confirmation`, `token`, `secret`, `api_key`, `authorization`)
**Depends on**: None
**Reuses**: none
**Requirement**: LOG-05

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN an array with a top-level `password` key WHEN redacted THEN the value becomes `"[REDACTED]"`
- [ ] GIVEN an array with a nested `user.password` key WHEN redacted THEN the nested value becomes `"[REDACTED]"` regardless of depth
- [ ] GIVEN a key matching a configured field name in any case (`Password`, `PASSWORD`) WHEN redacted THEN it is still matched and redacted
- [ ] GIVEN an array with no matching keys WHEN redacted THEN it is returned unchanged
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `php artisan test --testsuite=Unit`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add SensitiveFieldRedactor`

---

### T3: Create `RequestIdLogProcessor`

**What**: A Monolog processor that reads the container-bound `X-Request-Id` (from T1) and injects it into every log record's `extra` array as `request_id`.
**Where**: `api/app/Infrastructure/Logging/RequestIdLogProcessor.php`
**Depends on**: T1
**Reuses**: `CorrelationIdMiddleware`'s container binding
**Requirement**: LOG-01, LOG-03

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a bound request ID WHEN the processor runs on a log record THEN `extra.request_id` on that record equals the bound ID
- [ ] GIVEN no bound request ID (e.g. a CLI/console context outside an HTTP request) WHEN the processor runs THEN it does not throw - `extra.request_id` is simply omitted
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `php artisan test --testsuite=Unit`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add RequestIdLogProcessor`

---

### T4: Create `QueryLogListener`

**What**: A listener for Laravel's `DB::listen()` `QueryExecuted` event that redacts bind parameters (via T2) and writes one structured debug log line per executed query.
**Where**: `api/app/Infrastructure/Logging/QueryLogListener.php`
**Depends on**: T2
**Reuses**: `SensitiveFieldRedactor`
**Requirement**: LOG-06, LOG-05, LOG-13

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a `QueryExecuted` event with a bound parameter named `password` WHEN handled THEN the logged bind-parameter value is `"[REDACTED]"`
- [ ] GIVEN a `QueryExecuted` event with no sensitive bind parameters WHEN handled THEN the query string and bind values are logged unredacted
- [ ] GIVEN the log write itself throws (simulated sink failure) WHEN the listener runs THEN the exception is swallowed and does not propagate to the caller
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `php artisan test --testsuite=Unit`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add QueryLogListener`

---

### T5: Create `DebugRequestLogger` middleware

**What**: Middleware that logs the request method/path/body and response status/body in debug mode, applying redaction (T2) and a 10 KB truncation bound before writing.
**Where**: `api/app/Infrastructure/Http/Middleware/DebugRequestLogger.php`
**Depends on**: T1, T2
**Reuses**: `SensitiveFieldRedactor`, `CorrelationIdMiddleware`'s bound ID
**Requirement**: LOG-04, LOG-08, LOG-15, LOG-13

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN `APP_DEBUG=true` WHEN a request is handled THEN the log contains the request method, path, redacted body, response status, and redacted response body
- [ ] GIVEN `APP_DEBUG=false` WHEN a request is handled THEN no request/response body is logged
- [ ] GIVEN a request/response body larger than 10 KB WHEN logged THEN the logged value is truncated to 10 KB with a `"...[truncated]"` marker appended
- [ ] GIVEN the log write itself throws (simulated sink failure) WHEN the middleware runs THEN the exception is swallowed and the response is still returned to the caller
- [ ] Integration tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `php artisan test --testsuite=Feature`

**Tests**: integration
**Gate**: full

**Commit**: `feat(logging): add DebugRequestLogger middleware`

---

### T6: Wire debug-mode config, service-provider registration, and env vars

**What**: Register `RequestIdLogProcessor`/`QueryLogListener`/`DebugRequestLogger` conditionally (only when `APP_DEBUG=true`) in a service provider; add a Monolog `debug` channel using `JsonFormatter`; add `APP_DEBUG`/`LOG_LEVEL`/`LOG_CHANNEL` to `docker-compose.yml`'s existing `x-backend-env` anchor (`docker-compose.yml:12-33`) and to `api/.env.example`'s existing per-concern grouping. Also prove LOG-07 (Reverb correlation): add a Pest feature test that dispatches a synthetic `ShouldBroadcast` event within a test request and asserts its log line carries the same `X-Request-Id` as the response header.
**Where**: `api/app/Providers/LoggingServiceProvider.php` (new), `api/config/logging.php`, `docker-compose.yml`, `api/.env.example`
**Depends on**: T1, T3, T4, T5
**Reuses**: `docker-compose.yml`'s `x-backend-env` anchor, `api/.env.example`'s existing structure
**Requirement**: LOG-03, LOG-07, LOG-08

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN `APP_DEBUG=true` WHEN the app boots THEN the `debug` Monolog channel is active with `JsonFormatter` and all three debug-only components (T3, T4, T5's listener/middleware) are registered
- [ ] GIVEN `APP_DEBUG=false` WHEN the app boots THEN none of the three debug-only components are registered (verified by asserting they're absent from the container/event-listener list, not just inactive)
- [ ] GIVEN a request that dispatches a synthetic `ShouldBroadcast` event WHEN both the request's own log line and the broadcast's log line are inspected THEN both carry the identical `X-Request-Id`
- [ ] `docker compose config -q` exits 0 with the new env vars present
- [ ] Integration tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `docker compose config -q && php artisan test`

**Tests**: integration
**Gate**: build

**Commit**: `feat(logging): wire debug-mode config and env vars`

---

### T7: Create `website`'s `devLogger`

**What**: A thin logger wrapping `console.*`, gated by `import.meta.env.DEV`, prefixed `[website]`.
**Where**: `website/src/infrastructure/logging/devLogger.ts`
**Depends on**: None
**Reuses**: none
**Requirement**: LOG-09, LOG-10

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN `import.meta.env.DEV` is true WHEN `debug`/`info`/`warn`/`error` are called THEN each passes through to the matching `console.*` method, prefixed `[website]`
- [ ] GIVEN `import.meta.env.DEV` is false WHEN `debug`/`info` are called THEN they produce no console output; `warn`/`error` still pass through
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `npm --prefix website test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add website devLogger`

---

### T8: Create `admin`'s `devLogger`

**What**: Same design as T7, for the `admin-panel` app.
**Where**: `admin/src/infrastructure/logging/devLogger.ts`
**Depends on**: None
**Reuses**: `website/src/infrastructure/logging/devLogger.ts` pattern from T7
**Requirement**: LOG-09, LOG-10

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Same criteria as T7, prefixed `[admin-panel]`
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `npm --prefix admin test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add admin-panel devLogger`

---

### T9: Create `landingpage`'s `devLogger`

**What**: Same design as T7, for the `landing-page-plans` app.
**Where**: `landingpage/src/infrastructure/logging/devLogger.ts`
**Depends on**: None
**Reuses**: `website/src/infrastructure/logging/devLogger.ts` pattern from T7
**Requirement**: LOG-09, LOG-10

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Same criteria as T7, prefixed `[landing-page-plans]`
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `npm --prefix landingpage test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add landing-page-plans devLogger`

---

### T10: Create KMP shared `Logger` (`commonMain` expect + `androidMain` actual)

**What**: An `expect class Logger` in `commonMain` with `d(tag, message)` and `event(tag, name, params)`, and its Android `actual` implementation writing to Logcat in debug builds, no-op in release builds.
**Where**: `mobile/shared/src/commonMain/kotlin/.../infrastructure/logging/Logger.kt`, `mobile/shared/src/androidMain/kotlin/.../Logger.android.kt`
**Depends on**: None
**Reuses**: none - first piece of mobile application code; this component is a dependency `analytics-tracking` (ANLY-10) will reuse
**Requirement**: LOG-11, LOG-12

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a debug build WHEN `Logger.d(tag, message)` is called THEN the message appears in Logcat with the given tag
- [ ] GIVEN a debug build WHEN `Logger.event(tag, name, params)` is called THEN the event name and parameters appear in Logcat
- [ ] GIVEN a release build WHEN either method is called THEN no Logcat output is produced
- [ ] Unit tests written per the Test Coverage Matrix, GIVEN/WHEN/THEN named
- [ ] Gate check passes: `./gradlew :shared:test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add KMP shared Logger (commonMain + Android)`

---

### T11: Create iOS `actual` `Logger`

**What**: The iOS `actual` implementation of `Logger` from T10, writing to `os_log`/`NSLog` in debug builds, no-op in release builds.
**Where**: `mobile/shared/src/iosMain/kotlin/.../Logger.ios.kt`
**Depends on**: T10
**Reuses**: `Logger`'s `expect` contract from T10
**Requirement**: LOG-11, LOG-12

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] GIVEN a debug build WHEN `Logger.d`/`Logger.event` are called THEN output appears in `os_log`/Console
- [ ] GIVEN a release build WHEN either method is called THEN no output is produced
- [ ] Unit tests written per the Test Coverage Matrix (the shared `commonTest` suite exercises both platform actuals via `expect`/`actual` resolution), GIVEN/WHEN/THEN named
- [ ] Gate check passes: `./gradlew :shared:test`

**Tests**: unit
**Gate**: quick

**Commit**: `feat(logging): add KMP iOS actual Logger`

---

### T12: Update `docs/infrastructure/architecture.md` and `docs/development.md`

**What**: Add a "Debug logging" subsection to both docs: the new `APP_DEBUG`/`LOG_LEVEL`/`LOG_CHANNEL` env vars and what they control, and a one-line pointer to each stack's own `docs/*/architecture.md` for the implementation details.
**Where**: `docs/infrastructure/architecture.md`, `docs/development.md`
**Depends on**: T6, T7, T8, T9, T11
**Reuses**: existing doc structure from `infrastructure`'s Execute pass
**Requirement**: none (AD-014 documentation convention)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Both docs mention `APP_DEBUG`/`LOG_LEVEL`/`LOG_CHANNEL` and what debug mode logs
- [ ] `grep -qi 'debug' docs/infrastructure/architecture.md` and `grep -qi 'debug' docs/development.md` both succeed

**Tests**: none
**Gate**: build

**Commit**: `docs(infra): document dev/debug-mode logging env vars`

---

### T13: Add "Debug logging" subsection to each stack's own architecture doc

**What**: One-paragraph "Debug logging" subsection in each of the five stacks' own `docs/*/architecture.md`, describing that stack's specific implementation (correlation ID + redaction + JSON logs for `backend`; the `devLogger` pattern for the three web apps; the KMP `Logger` for `mobile`).
**Where**: `docs/backend/architecture.md`, `docs/web-app/architecture.md`, `docs/admin-panel/architecture.md`, `docs/landing-page-plans/architecture.md`, `docs/mobile/architecture.md`
**Depends on**: T12
**Reuses**: none - these per-stack doc files don't exist yet (created here for the first time, since no platform feature has executed Tasks yet)
**Requirement**: none (AD-014 documentation convention)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Each of the five files exists with a "Debug logging" section describing that stack's mechanism
- [ ] `grep -qi 'debug' docs/backend/architecture.md` (repeated per file) succeeds for all five

**Tests**: none
**Gate**: build

**Commit**: `docs(logging): add per-stack debug-logging architecture notes`

---

## Phase Execution Map

Visual representation of task ordering. Phases run in sequence, and tasks within a phase run in order:

```
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4

Phase 1:  T1  T2
Phase 1:  T1 ------> T3
Phase 1:  T2 ------> T4
Phase 1:  T1 ------> T5
Phase 1:  T2 ------> T5
Phase 1:  T1 ------> T6
Phase 1:  T3 ------> T6
Phase 1:  T4 ------> T6
Phase 1:  T5 ------> T6
Phase 2:  T7  T8  T9
Phase 3:  T10 ------> T11
Phase 4:  T6 ------> T12
Phase 4:  T7 ------> T12
Phase 4:  T8 ------> T12
Phase 4:  T9 ------> T12
Phase 4:  T11 ------> T12
Phase 4:  T12 ------> T13
```

Execution is strictly sequential - there is no intra-phase parallelism. A single agent (or batch worker) works one task at a time, in order.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1: Create CorrelationIdMiddleware | 1 file | ✅ Granular |
| T2: Create SensitiveFieldRedactor | 1 file + 1 config key | ✅ Granular |
| T3: Create RequestIdLogProcessor | 1 file | ✅ Granular |
| T4: Create QueryLogListener | 1 file | ✅ Granular |
| T5: Create DebugRequestLogger middleware | 1 file | ✅ Granular |
| T6: Wire debug-mode config, service-provider registration, and env vars | 4 files (cohesive - one wiring pass tying T1/T3/T4/T5 together) | ✅ Granular |
| T7: Create website's devLogger | 1 file | ✅ Granular |
| T8: Create admin's devLogger | 1 file | ✅ Granular |
| T9: Create landingpage's devLogger | 1 file | ✅ Granular |
| T10: Create KMP shared Logger (commonMain + Android) | 2 files (cohesive - expect + one actual) | ✅ Granular |
| T11: Create iOS actual Logger | 1 file | ✅ Granular |
| T12: Update docs/infrastructure/architecture.md and docs/development.md | 2 files (cohesive - one infra-doc pass) | ✅ Granular |
| T13: Add "Debug logging" subsection to each stack's own architecture doc | 5 files (cohesive - one per-stack doc pass, near-identical edits) | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ----------------------- | -------------- | ------ |
| T1 | None | None | ✅ Match |
| T2 | None | None | ✅ Match |
| T3 | T1 | T1 | ✅ Match |
| T4 | T2 | T2 | ✅ Match |
| T5 | T1, T2 | T1, T2 | ✅ Match |
| T6 | T1, T3, T4, T5 | T1, T3, T4, T5 | ✅ Match |
| T7 | None | None | ✅ Match |
| T8 | None | None | ✅ Match |
| T9 | None | None | ✅ Match |
| T10 | None | None | ✅ Match |
| T11 | T10 | T10 | ✅ Match |
| T12 | T6, T7, T8, T9, T11 | T6, T7, T8, T9, T11 | ✅ Match |
| T13 | T12 | T12 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | ---------------------------- | ---------------- | ---------- | ------ |
| T1: Create CorrelationIdMiddleware | api Infrastructure/Http/Middleware | integration | unit (contained, no HTTP roundtrip needed to test container binding + header) | ⚠️ see note |
| T2: Create SensitiveFieldRedactor | api Infrastructure/Logging | unit | unit | ✅ OK |
| T3: Create RequestIdLogProcessor | api Infrastructure/Logging | unit | unit | ✅ OK |
| T4: Create QueryLogListener | api Infrastructure/Logging | unit | unit | ✅ OK |
| T5: Create DebugRequestLogger middleware | api Infrastructure/Http/Middleware | integration | integration | ✅ OK |
| T6: Wire debug-mode config, service-provider registration, and env vars | api debug-logging config wiring + Middleware (LOG-07 proof) | none (config) / integration (LOG-07 proof) | integration | ✅ OK |
| T7-T9: devLogger (website/admin/landingpage) | Web devLogger | unit | unit | ✅ OK |
| T10: KMP shared Logger (commonMain + Android) | Mobile Logger | unit | unit | ✅ OK |
| T11: KMP iOS actual Logger | Mobile Logger | unit | unit | ✅ OK |
| T12: infra docs | Developer documentation | none | none | ✅ OK |
| T13: per-stack docs | Developer documentation | none | none | ✅ OK |

**Note on T1**: the matrix lists `CorrelationIdMiddleware` under the same "Http/Middleware" layer as `DebugRequestLogger` (integration), but T1's own Done-when criteria (header generated/reused, container binding, no cross-request leakage) are fully testable by invoking the middleware directly with a mocked request/response - no real HTTP roundtrip is required the way `DebugRequestLogger`'s body-logging behavior needs one. T1 is still exercised end-to-end anyway in T6's Feature test (LOG-07 proof), so its behavior gets integration-level coverage there; T1's own task keeps unit tests for the class-level contract. This is a deliberate split, not a coverage gap - flagged here rather than silently deviating from the matrix.

---

## Tools & Skills for Execution

**Available MCPs for these tasks**: NONE (filesystem edits + Bash for `php artisan test`/`npm test`/`./gradlew test`)

**Available Skills for these tasks**: NONE
