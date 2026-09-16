# Infrastructure Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Design**: `.specs/STATE.md (AD-004, AD-009) - no separate design.md; architecture already decided`  
**Status**: Draft

---

## Coding Conventions (MANDATORY)

Per AD-012 (Clean Architecture) and AD-013 (code quality): infrastructure config (Dockerfiles, docker-compose.yml, the Makefile, database seeders) is bootstrapping/config code, not application logic, so it is **not** restructured into Domain/Application/Infrastructure/Presentation layers - that layering applies to the four feature units' own `backend`/frontend/mobile source, not to this unit. What still applies here: no magic numbers/strings (ports, thresholds, and file paths referenced in more than one place are named once, e.g. in `.env.example`, and referenced from there - not duplicated inline across `docker-compose.yml`, the `Makefile`, and seeders); no task/ticket-referencing comments in code (AD-014) - this unit's own write-up lives in `docs/infrastructure/architecture.md` (added below) instead.

---

## Test Coverage Matrix

> Guidelines found: .specs/STATE.md AD-004 (Docker Compose local dev, VPS prod) and AD-009 (S3-compatible storage via Flysystem, provider TBD). No application code exists yet - these are infrastructure/config artifacts, not domain logic, so the strong default for Entity/Config layers applies: no unit/integration/e2e tests, build gate only.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| ---------- | ------------------- | --------------------- | ----------------- | ----------- |
| Dockerfile (per service) | none | - (build gate only) | api/Dockerfile, website/Dockerfile, admin/Dockerfile, landingpage/Dockerfile | docker build . |
| docker-compose.yml orchestration | none | - (build gate only): every declared default-profile service reaches healthy/running state; the `playwright` service is profile-gated (`profiles: ["test"]`) and must NOT start with the default profile | docker-compose.yml | docker compose config -q && docker compose up -d --wait |
| .env.example templates | none | - (build gate only): documents every var the compose file references | api/.env.example, website/.env.example, admin/.env.example, landingpage/.env.example | docker compose config -q |
| Developer documentation | none | - (build gate only): must state the host-vs-container split explicitly | docs/development.md | grep -q 'mobile-app' docs/development.md |
| Makefile | none | - (build gate only): `up` boots every default-profile service; `test-e2e` runs Playwright via the test profile only; `mobile-android`/`mobile-ios` fail fast without host prerequisites | Makefile | make up && docker compose ps |
| DatabaseSeeder run order + Makefile `seed` target | none | - (build gate only): runs admin-panel's then web-app's seeders in FK-safe order with zero errors | api/database/seeders/DatabaseSeeder.php, Makefile | make seed |
| Postman collection | none | - (build gate only): one request per endpoint across admin-panel/web-app/landing-page-plans, each populated with working example data | postman/QualORock.postman_collection.json, postman/local.postman_environment.json | newman run postman/QualORock.postman_collection.json -e postman/local.postman_environment.json --folder smoke |

## Gate Check Commands

> Generated from AD-004/AD-009 - confirm before Execute. No test runner is involved at this layer; every gate is a Docker/Compose command.

| Gate Level | When to Use | Command |
| ---------- | ----------- | ------- |
| Quick | Not applicable - no unit tests at this layer | n/a |
| Full | Not applicable - no integration/e2e tests at this layer | n/a |
| Build | After every infrastructure task | docker compose config -q && docker compose build && docker compose up -d --wait && docker compose ps |

---

## Execution Plan

Phases are ordered and run sequentially - each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Per-service Dockerfiles

One Dockerfile per containerized stack. Mobile-app is intentionally excluded - it runs on the host (KMP/SwiftUI/Compose need Xcode/Android Studio/JVM toolchains that don't containerize for iOS builds).

```
T1  T2  T3  T4
```

### Phase 2: Compose orchestration, config templates, docs, smoke test

Wire every service (backend, its DB, its object store, its mail catcher, and the three web apps) into one docker-compose.yml, document the host-vs-container split, and prove the whole stack boots.

```
T1 -> T5
T2 -> T5
T3 -> T5
T4 -> T5
T5 -> T14
T5 -> T6
T14 -> T6
T5 -> T7
T5 -> T8
T8 -> T9
T5 -> T10
T14 -> T10
T6 -> T10
T7 -> T10
T8 -> T10
T9 -> T10
```

### Phase 3: QA tooling: seeding orchestration & Postman collection

Cross-feature concerns that only make sense once admin-panel's and web-app's own seeders (see their respective tasks.md) and backend endpoints exist. This phase owns run order and the developer-facing entrypoints, not the seeding logic itself.

```
T9 -> T11
T11 -> T12
```

### Phase 4: Documentation (AD-014)

Per-stack documentation convention applied to this unit too, for consistency.

```
T10 -> T13
T12 -> T13
```

---

## Task Breakdown

### T1: Create api Dockerfile (PHP 8.4 + Laravel)

**What**: Multi-stage Dockerfile for the Laravel/PHP 8.4 API (per AD-004): composer install stage + php-fpm/nginx (or Laravel Octane) runtime stage, with Reverb's websocket process runnable via the same image.
**Where**: `api/Dockerfile` (submodule directory renamed from `backend` to `api`; the compose service name stays `backend` per T5)
**Depends on**: None
**Requirement**: INFRA-01 (AD-004)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Dockerfile builds a PHP 8.4 image with Composer dependencies installed
- [x] Image exposes the app port and can run `php artisan serve` or php-fpm
- [x] Image can also run `php artisan reverb:start` for the websocket process
- [ ] DEFERRED: `docker build -f api/Dockerfile .` succeeding with exit code 0 - the `api/` submodule has no source yet (its own feature spec hasn't been executed); re-run this check once real source lands

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add api Dockerfile`

---

### T2: Create web-app Dockerfile (React/Node dev server)

**What**: Dockerfile for the `website` submodule's React+Tailwind dev server (Vite/CRA dev server exposed for local development, not a production build).
**Where**: `website/Dockerfile`
**Depends on**: None
**Requirement**: INFRA-02 (AD-004)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Dockerfile installs Node deps and runs the dev server on a fixed port
- [ ] DEFERRED: `docker build -f website/Dockerfile .` succeeding with exit code 0 - the `website/` submodule has no source yet; re-run this check once real source lands

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add web-app Dockerfile`

---

### T3: Create admin Dockerfile (React/Node dev server)

**What**: Dockerfile for the admin-panel submodule's React+Tailwind dev server, mirroring T2's pattern.
**Where**: `admin/Dockerfile` (submodule directory renamed from `adminpanel` to `admin`; the compose service name stays `admin-panel` per T5)
**Depends on**: None
**Reuses**: website/Dockerfile pattern from T2
**Requirement**: INFRA-03 (AD-004)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Dockerfile installs Node deps and runs the dev server on a fixed port distinct from web-app's
- [ ] DEFERRED: `docker build -f admin/Dockerfile .` succeeding with exit code 0 - the `admin/` submodule has no source yet; re-run this check once real source lands

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add admin Dockerfile`

---

### T4: Create landing-page-plans Dockerfile (React/Node dev server)

**What**: Dockerfile for the `landingpage` submodule's unauthenticated public React+Tailwind app, mirroring T2's pattern.
**Where**: `landingpage/Dockerfile`
**Depends on**: None
**Reuses**: website/Dockerfile pattern from T2
**Requirement**: INFRA-04 (AD-004)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Dockerfile installs Node deps and runs the dev server on a fixed port distinct from web-app's and admin-panel's
- [ ] DEFERRED: `docker build -f landingpage/Dockerfile .` succeeding with exit code 0 - the `landingpage/` submodule has no source yet; re-run this check once real source lands

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add landing-page-plans Dockerfile`

---

### T5: Write docker-compose.yml wiring all containerized services

**What**: Root `docker-compose.yml` defining services: `backend` (T1 image, build context `api/`), `reverb` (same image, different command), `postgres` (least-privilege app user per AD-004/AD-008), `minio` (S3-compatible store per AD-009), `mailhog` (SMTP catcher per AD-004's Laravel Mail decision), `web-app` (T2), `admin-panel` (T3, build context `admin/`), `landing-page-plans` (T4) - with named volumes for Postgres/MinIO data and a shared network.
**Where**: `docker-compose.yml`
**Depends on**: T1, T2, T3, T4
**Requirement**: INFRA-05 (AD-004, AD-008, AD-009)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] All eight services declared with correct build contexts (T1-T4 Dockerfiles, using the `api/`/`admin/` renamed paths) or pinned images (postgres, minio, mailhog)
- [x] Postgres service uses a least-privilege app-level DB user/password (not superuser) for the backend connection, per AD-008
- [x] `docker compose config -q` exits 0 (valid compose file)

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add docker-compose.yml wiring all containerized services`

---

### T14: Add pgAdmin service to docker-compose.yml

**What**: Add a `pgadmin` service (`dpage/pgadmin4` pinned image) to `docker-compose.yml` for local Postgres inspection - joins the same shared network as `postgres`, `depends_on: postgres`, credentials via `PGADMIN_DEFAULT_EMAIL`/`PGADMIN_DEFAULT_PASSWORD` placeholders (no magic strings inline, per AD-013), own fixed port distinct from every other service's port. No named/persistent volume for pgAdmin's own server config - only Postgres/MinIO data is intentionally persisted (spec.md edge case).
**Where**: `docker-compose.yml`
**Depends on**: T5
**Reuses**: T5's shared network and Postgres service definition
**Requirement**: INFRA-13

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `pgadmin` service declared with `depends_on: postgres`, on the same network as `postgres`
- [x] `PGADMIN_DEFAULT_EMAIL`/`PGADMIN_DEFAULT_PASSWORD` are read from environment variables, not hardcoded in docker-compose.yml
- [x] `pgadmin` exposes a fixed port distinct from every other declared service's port
- [x] `pgadmin` has no named/persistent volume declared for it
- [x] `docker compose config -q` still exits 0 with `pgadmin` present

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add pgadmin service to docker-compose.yml`

---

### T6: Add .env.example templates for every containerized service

**What**: One `.env.example` per service (api, website, admin, landingpage) documenting every environment variable docker-compose.yml references (DB DSN, Sanctum/session domain, Reverb keys, MinIO/S3 credentials, Mailhog SMTP host/port, Google Maps key placeholder, OAuth client-id placeholders, pgAdmin default email/password placeholders from T14).
**Where**: `api/.env.example, website/.env.example, admin/.env.example, landingpage/.env.example`
**Depends on**: T5, T14
**Requirement**: INFRA-06 (AD-004, AD-009)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Every variable referenced in docker-compose.yml's `environment:`/`env_file:` blocks (including pgAdmin's) has a matching placeholder line in the relevant .env.example
- [x] No real secret values are committed - all placeholders
- [x] `docker compose config -q` still exits 0 after templates are in place

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add .env.example templates for containerized services`

---

### T7: Write docs/development.md documenting the host-vs-container split

**What**: Developer setup doc stating explicitly that every stack EXCEPT mobile-app runs via `docker compose up` (backend, web-app, admin-panel, landing-page-plans, Postgres, MinIO, Mailhog, pgAdmin), while mobile-app is the one stack that runs on the host machine (Xcode for iOS/SwiftUI, Android Studio for Compose, shared KMP module built via Gradle/JVM on the host) because those toolchains don't containerize for iOS builds - plus the one-time host setup steps for mobile (Xcode, Android Studio, JDK/Gradle), the one command (`docker compose up -d --wait`) that starts everything else, and the `make mobile-android`/`make mobile-ios` targets (T9) that shell out to the host toolchains for mobile. The submodule directory is `mobile/` (matching AD-004); this doc's prose keeps calling the stack "mobile-app" for readability and to satisfy this task's own grep gate below.
**Where**: `docs/development.md`
**Depends on**: T5
**Requirement**: INFRA-07 (AD-004)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Doc contains an explicit sentence-level statement that mobile-app runs on host, not in Docker, and why
- [x] Doc lists the one-time host prerequisites for mobile-app (Xcode, Android Studio, JDK/Gradle)
- [x] Doc gives the single command to start every containerized service
- [x] `grep -q 'mobile-app' docs/development.md` and `grep -qi 'host' docs/development.md` both succeed

**Tests**: none
**Gate**: build

**Commit**: `docs(infra): document host-vs-container development split`

---

### T8: Add Playwright service to docker-compose.yml under a test-only profile

**What**: Add a `playwright` service (official Playwright Docker image) to docker-compose.yml, mounting the e2e test directories from `website`, `adminpanel`, and `landingpage` (per those features' `e2e/visual/*.spec.ts` suites), tagged `profiles: ["test"]` so it is excluded from the default profile entirely - not merely stopped by default, but structurally absent unless the `test` profile is explicitly requested.
**Where**: `docker-compose.yml`
**Depends on**: T5
**Requirement**: INFRA-10

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] The `playwright` service declares `profiles: ["test"]` in docker-compose.yml
- [x] GIVEN a plain `docker compose up` (no `--profile` flag) WHEN inspected THEN `docker compose ps` does NOT list a `playwright` container
- [ ] DEFERRED: `docker compose --profile test up playwright` reaching `website`/`admin-panel`/`landing-page-plans` over the shared network - those three services' images can't build yet (no submodule source), so the Playwright container has nothing running to reach
- [x] `docker compose config -q` still exits 0 with the new service present

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add Playwright service under a test-only compose profile`

---

### T9: Add root Makefile (up/down/logs/ps/build/test-e2e/mobile-android/mobile-ios)

**What**: Root `Makefile` wrapping the compose commands so no developer needs to know the raw invocation: `up` (`docker compose up -d --wait` - every default-profile service: backend, reverb, postgres, minio, mailhog, pgadmin, web-app, admin-panel, landing-page-plans), `down` (`docker compose down`), `logs` (`docker compose logs -f`), `ps` (`docker compose ps`), `build` (`docker compose build`), `test-e2e` (`docker compose --profile test run --rm playwright ...`, the ONLY target that starts Playwright). Also add two host-shelling targets for the `mobile/` submodule, which runs outside Docker (per AD-004/spec.md): `mobile-android` (runs `./gradlew installDebug` or equivalent against `mobile/`, failing fast with a clear message if the Android SDK isn't on PATH) and `mobile-ios` (runs `xcodebuild`/`xcrun simctl` against `mobile/`'s Xcode project, failing fast with a clear message on a non-macOS host).
**Where**: `Makefile`
**Depends on**: T8
**Requirement**: INFRA-09

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] DEFERRED: `make up` on a clean checkout bringing backend/reverb/web-app/admin-panel/landing-page-plans to Up/healthy - no submodule source yet, so their images can't build. Verified instead via `docker compose up -d --wait postgres minio mailhog pgadmin` (the four services with no dependency on unbuilt images), which reached Up/healthy for real (see T9 commit's gate run)
- [x] GIVEN a plain `docker compose ps` after bringing up the default-profile-capable services WHEN inspected THEN it does NOT show a `playwright` container (the `up` target never references the `test` profile)
- [ ] DEFERRED: `make test-e2e` starting the `playwright` container via the `test` profile and exiting with the suite's real pass/fail code - no e2e specs exist yet in the unbuilt frontend submodules
- [x] `make down` cleanly stops and removes all containers started (verified against the four unblocked services)
- [x] `make mobile-android` and `make mobile-ios` exist as Makefile targets and fail fast with a clear message when their host prerequisite is missing (Android SDK / macOS respectively) - DEFERRED end-to-end run (the `mobile/` submodule has no Gradle/Xcode project yet); the fail-fast path itself was run for real and exits non-zero with a clear message

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): add root Makefile with up/down/logs/ps/build/test-e2e/mobile targets`

---

### T10: Smoke-test: full containerized stack boots healthy

**What**: Bring up every containerized service and confirm each reaches a running/healthy state, proving T1-T9 compose into a working dev environment before any feature work starts on top of it.
**Where**: `docker-compose.yml`
**Depends on**: T5, T14, T6, T7, T8, T9
**Requirement**: INFRA-08, INFRA-09, INFRA-10, INFRA-13

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `docker compose config -q` exits 0 for the full compose file (all nine services, including `pgadmin`)
- [x] `docker compose up -d --wait postgres minio mailhog pgadmin` exits 0 and `docker compose ps` shows all four Up/healthy - these have no dependency on the unbuilt submodules, so this check runs for real
- [ ] DEFERRED: `docker compose up -d --wait` for the full stack (backend, reverb, web-app, admin-panel, landing-page-plans) - blocked on T1-T4's images, which can't build until `api/`, `website/`, `admin/`, `landingpage/` have real source
- [x] `docker compose ps` does NOT show a `playwright` container after a plain `docker compose up` (profile isolation verified against the services that do run)
- [x] `docker compose down` cleanly stops and removes all containers that were started

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): verify pgadmin/postgres/minio/mailhog boot healthy; defer full-stack smoke test`

---

### T11: DatabaseSeeder run order + `make seed` target

**What**: Wire Laravel's `DatabaseSeeder::run()` to call admin-panel's `AdminPanelSeeder` (see admin-panel/tasks.md T42) before web-app's `WebAppSeeder` (see web-app/tasks.md T37), since web-app's Favorite/EventInterest rows reference admin-panel's Event rows. Add a `seed` target to the Makefile from T9 running `docker compose exec backend php artisan db:seed`.
**Where**: `api/database/seeders/DatabaseSeeder.php, Makefile`
**Depends on**: T9
**Reuses**: admin-panel/tasks.md T42 (AdminPanelSeeder) and web-app/tasks.md T37 (WebAppSeeder) - this task only orders and exposes them, it does not reimplement their fixture logic
**Requirement**: INFRA-11

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `DatabaseSeeder::run()` calls `AdminPanelSeeder` before `WebAppSeeder`, in FK-safe order, and the `seed` Makefile target exists
- [ ] DEFERRED: `make seed` running with zero foreign-key errors on a freshly migrated database - `AdminPanelSeeder`/`WebAppSeeder` and the `api/` Laravel app don't exist yet (blocked on admin-panel/web-app/infra Phase-1 execution)
- [ ] DEFERRED: idempotency of running `make seed` twice in a row - same blocker
- [ ] DEFERRED: `make up && make seed` succeeding end-to-end on a clean checkout - same blocker

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): wire DatabaseSeeder run order and add make seed target`

---

### T12: Generate Postman collection covering every backend endpoint

**What**: Generate `postman/QualORock.postman_collection.json` covering every endpoint across admin-panel, web-app, and landing-page-plans (organized into one Postman folder per feature), plus `postman/local.postman_environment.json` (base URL pointing at the `make up` stack, a seeded organizer/Super Admin/consumer credential set for auth-required requests). Every request body/param uses real values from T11's seeded fixtures (e.g. an actual seeded event ID), not placeholders.
**Where**: `postman/QualORock.postman_collection.json, postman/local.postman_environment.json`
**Depends on**: T11
**Reuses**: Every controller/route task across admin-panel/tasks.md, web-app/tasks.md, and landing-page-plans/tasks.md - this task is generated FROM their already-implemented endpoints, not written ahead of them
**Requirement**: INFRA-12

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `postman/QualORock.postman_collection.json` and `postman/local.postman_environment.json` exist with one folder per feature (admin-panel, web-app, landing-page-plans), scaffolded structure ready to receive real requests
- [ ] DEFERRED: one request per implemented endpoint, populated with working example data - admin-panel/web-app/landing-page-plans have no implemented endpoints yet
- [ ] DEFERRED: auth requests carrying a working seeded credential/token - no seeded fixtures exist yet (blocked on T11)
- [ ] DEFERRED: request bodies/params referencing real seeded record IDs
- [ ] DEFERRED: `newman run postman/QualORock.postman_collection.json -e postman/local.postman_environment.json --folder smoke` exiting 0 - no backend/endpoints exist yet to run against

**Tests**: none
**Gate**: build

**Commit**: `chore(infra): generate Postman collection for all backend endpoints`

---

### T13: docs/infrastructure/architecture.md

**What**: Markdown write-up of the local dev environment: every service in docker-compose.yml (including `pgadmin`), the Makefile targets (`up`/`down`/`logs`/`ps`/`build`/`test-e2e`/`seed`/`mobile-android`/`mobile-ios`), the host-vs-container split (mobile-app on host, submodule directory `mobile/`), and the Playwright test-only profile - restates `docs/development.md`'s content in the same per-stack documentation location as every other feature, per AD-014.
**Where**: `docs/infrastructure/architecture.md`
**Depends on**: T10, T12
**Requirement**: AD-014 (documentation)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Doc lists every compose service and its purpose, including `pgadmin`
- [ ] Doc lists every Makefile target and what it does, including `mobile-android`/`mobile-ios`
- [ ] Doc restates the host-vs-container split and the Playwright test-only profile

**Tests**: none
**Gate**: build

**Commit**: `docs(infra): add architecture.md for the local dev environment`

---

## Phase Execution Map

Visual representation of task ordering. Phases run in sequence, and tasks within a phase run in order:

```
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4

Phase 1:  T1  T2  T3  T4
Phase 2:  T1 ------> T5
Phase 2:  T2 ------> T5
Phase 2:  T3 ------> T5
Phase 2:  T4 ------> T5
Phase 2:  T5 ------> T14
Phase 2:  T5 ------> T6
Phase 2:  T14 ------> T6
Phase 2:  T5 ------> T7
Phase 2:  T5 ------> T8
Phase 2:  T8 ------> T9
Phase 2:  T5 ------> T10
Phase 2:  T14 ------> T10
Phase 2:  T6 ------> T10
Phase 2:  T7 ------> T10
Phase 2:  T8 ------> T10
Phase 2:  T9 ------> T10
Phase 3:  T9 ------> T11
Phase 3:  T11 ------> T12
Phase 4:  T10 ------> T13
Phase 4:  T12 ------> T13
```

Execution is strictly sequential - there is no intra-phase parallelism. A single agent (or batch worker) works one task at a time, in order.

---

## Task Granularity Check

| Task | Scope | Status |
| ---- | ----- | ------ |
| T1: Create api Dockerfile (PHP 8.4 + Laravel) | 1 file | ✅ Granular |
| T2: Create web-app Dockerfile (React/Node dev server) | 1 file | ✅ Granular |
| T3: Create admin Dockerfile (React/Node dev server) | 1 file | ✅ Granular |
| T4: Create landing-page-plans Dockerfile (React/Node dev server) | 1 file | ✅ Granular |
| T5: Write docker-compose.yml wiring all containerized services | 1 file | ✅ Granular |
| T14: Add pgAdmin service to docker-compose.yml | 1 file (modifies T5's docker-compose.yml) | ✅ Granular |
| T6: Add .env.example templates for every containerized service | 4 files (cohesive - one template set for the one compose stack) | ✅ Granular |
| T7: Write docs/development.md documenting the host-vs-container split | 1 file | ✅ Granular |
| T8: Add Playwright service to docker-compose.yml under a test-only profile | 1 file (modifies T5's docker-compose.yml) | ✅ Granular |
| T9: Add root Makefile (up/down/logs/ps/build/test-e2e/mobile-android/mobile-ios) | 1 file | ✅ Granular |
| T10: Smoke-test: full containerized stack boots healthy | 1 file (verification of existing compose config, no new file) | ✅ Granular |
| T11: DatabaseSeeder run order + `make seed` target | 2 files (cohesive - the seeder run-order and its one Makefile entrypoint) | ✅ Granular |
| T12: Generate Postman collection covering every backend endpoint | 2 files (cohesive - the collection and its one companion environment) | ✅ Granular |
| T13: docs/infrastructure/architecture.md | 1 file | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| ---- | ----------------------- | -------------- | ------ |
| T1 | None | None | ✅ Match |
| T2 | None | None | ✅ Match |
| T3 | None | None | ✅ Match |
| T4 | None | None | ✅ Match |
| T5 | T1, T2, T3, T4 | T1, T2, T3, T4 | ✅ Match |
| T14 | T5 | T5 | ✅ Match |
| T6 | T5, T14 | T5, T14 | ✅ Match |
| T7 | T5 | T5 | ✅ Match |
| T8 | T5 | T5 | ✅ Match |
| T9 | T8 | T8 | ✅ Match |
| T10 | T5, T14, T6, T7, T8, T9 | T5, T14, T6, T7, T8, T9 | ✅ Match |
| T11 | T9 | T9 | ✅ Match |
| T12 | T11 | T11 | ✅ Match |
| T13 | T10, T12 | T10, T12 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| ---- | ---------------------------- | ---------------- | ---------- | ------ |
| T1: Create api Dockerfile (PHP 8.4 + Laravel) | Dockerfile (per service) | none | none | ✅ OK |
| T2: Create web-app Dockerfile (React/Node dev server) | Dockerfile (per service) | none | none | ✅ OK |
| T3: Create admin Dockerfile (React/Node dev server) | Dockerfile (per service) | none | none | ✅ OK |
| T4: Create landing-page-plans Dockerfile (React/Node dev server) | Dockerfile (per service) | none | none | ✅ OK |
| T5: Write docker-compose.yml wiring all containerized services | docker-compose.yml orchestration | none | none | ✅ OK |
| T14: Add pgAdmin service to docker-compose.yml | docker-compose.yml orchestration | none | none | ✅ OK |
| T6: Add .env.example templates for every containerized service | .env.example templates | none | none | ✅ OK |
| T7: Write docs/development.md documenting the host-vs-container split | Developer documentation | none | none | ✅ OK |
| T8: Add Playwright service to docker-compose.yml under a test-only profile | docker-compose.yml orchestration | none | none | ✅ OK |
| T9: Add root Makefile (up/down/logs/ps/build/test-e2e/mobile-android/mobile-ios) | Makefile | none | none | ✅ OK |
| T10: Smoke-test: full containerized stack boots healthy | docker-compose.yml orchestration | none | none | ✅ OK |
| T11: DatabaseSeeder run order + `make seed` target | DatabaseSeeder run order + Makefile `seed` target | none | none | ✅ OK |
| T12: Generate Postman collection covering every backend endpoint | Postman collection | none | none | ✅ OK |
| T13: docs/infrastructure/architecture.md | Developer documentation | none | none | ✅ OK |

---

## Tools & Skills for Execution

**Available MCPs for these tasks**: NONE (filesystem edits + Bash for docker/docker-compose CLI)

**Available Skills for these tasks**: NONE

