# Infrastructure (Local Dev Environment) Specification

## Problem Statement

None of the four platform specs (admin-panel, web-app, landing-page-plans, mobile-app) own the local development environment, yet every one of their Tasks phases assumes a running backend, database, and web dev servers exist. AD-004 already decided the stack (Docker Compose local dev, one Laravel/PHP 8.4 backend, PostgreSQL, three separate React+Tailwind web apps, Kotlin Multiplatform + native UI for mobile) but never turned that decision into a buildable environment. This spec closes that gap: every stack runs in Docker except mobile-app, which runs on the host because its iOS/Android toolchains (Xcode, Android Studio, JVM/Gradle) don't containerize for iOS builds.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Production/VPS deployment configuration | AD-004 names the VPS as the prod target but provisioning it is a separate, later concern (already flagged as a Tasks-phase prerequisite in `.specs/STATE.md`'s Handoff). |
| CI pipeline definitions (GitHub Actions workflows) | Owned by AD-011; this spec only guarantees the local dev environment the CI would exercise. |
| Mobile-app's own build tooling (Xcode project, Gradle config) | Mobile-app's own `tasks.md` owns its build setup; this spec's job is only to document that it runs on the host, not to configure it. |
| Real third-party credentials (OAuth apps, Google Maps key, production SMTP) | Local dev uses placeholders (Mailhog for mail, MinIO for S3); real credentials are a separate provisioning step already flagged in STATE.md's Handoff. |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Containerization boundary | Every stack runs in Docker except mobile-app, which runs on the host | Explicit user instruction this session; mobile's native iOS/Android toolchains don't containerize for iOS builds | y |
| Local object storage | MinIO (S3-compatible) stands in for the AD-009 Flysystem provider (TBD for prod) during local dev | AD-009 says "S3-compatible storage, provider TBD" - MinIO is the standard local-dev substitute requiring no external account | n |
| Local mail catcher | Mailhog stands in for Laravel Mail/SMTP during local dev | AD-004 names Laravel Mail/SMTP for the platform; Mailhog is the standard local substitute requiring no real SMTP relay | n |
| Database privilege model | The backend connects to Postgres as a least-privilege application user, never the superuser | AD-004/AD-008 security baseline (Eloquent-only access, no raw SQL) implies the DB credential itself shouldn't be superuser either | y |
| Developer entrypoint | A root `Makefile` wraps the raw `docker compose` commands (`up`, `down`, `logs`, `ps`, `build`, `test-e2e`, `seed`) | Explicit user instruction this session - one documented command instead of requiring every developer to know the compose invocation | y |
| E2E test isolation | Playwright is declared as a compose service under its own `profiles: ["test"]`, never in the default profile | Explicit user instruction this session - Playwright is for tests only and must never be part of the always-on dev stack | y |
| QA fixture ownership | admin-panel and web-app each own their own seeders for their own entities (see their respective `tasks.md`); this spec owns only the cross-feature run order (`DatabaseSeeder`) and the `make seed` entrypoint | Seeders touch feature-owned schemas, so the seeding logic itself belongs with the feature that owns the table - infrastructure's job is only orchestrating run order and exposing one command | y |
| Event cover images in seed data | Seeders download free-license, platform-appropriate images and upload them through the real backend upload endpoint (never write a bare external URL into the DB) | Explicit user instruction this session - QA fixtures must exercise the real MinIO/Flysystem upload path, not fake it | y |
| Postman collection scope | One collection covering every backend endpoint across admin-panel, web-app, and landing-page-plans, generated after their endpoints exist, populated with example data drawn from the seeded fixtures | Explicit user instruction this session - manual/QA testing needs real, working example requests, not empty stubs | y |

**Open questions:** none - all resolved or logged above.

**Routes to Discuss before Design:** none - AD-004/AD-008/AD-009 already fixed the architecture; Design is skipped for this spec.

---

## User Stories

### P1: Local development environment starts with one command ⭐ MVP

**User Story**: As a developer on any of the four feature teams, I want every backend-dependent service to start with a single command, so that I can begin implementing tasks without hand-configuring PHP, Postgres, or Node toolchains.

**Why P1**: Every other feature's Phase 1 tasks (migrations, scaffolding, first endpoint) assume these services already exist and run.

**Acceptance Criteria**:

1. WHEN a developer runs the documented startup command THEN the system SHALL bring up backend, Reverb, Postgres, MinIO, Mailhog, web-app, admin-panel, and landing-page-plans as running containers.
2. THE system SHALL connect the backend to Postgres using a least-privilege application-level database user, never the database superuser.
3. WHEN a developer inspects the running containers THEN the system SHALL show each with a distinct, documented port so the three web apps don't collide.
4. IF a developer needs to work on mobile-app THEN the system SHALL NOT require Docker for that work - the documentation SHALL state that mobile-app runs on the host via Xcode/Android Studio/JVM instead.
5. WHEN a developer runs `make up` THEN the system SHALL bring up every default-profile containerized service (backend, Reverb, Postgres, MinIO, Mailhog, web-app, admin-panel, landing-page-plans) via one Makefile target, without the developer needing to know the underlying `docker compose` invocation.
6. THE system SHALL run Playwright in its own Compose profile, isolated from the default profile, so that `docker compose up` and `make up` never start it - it SHALL start only via an explicit test command (`make test-e2e`).

**Independent Test**: On a clean checkout, run `make up` and confirm `docker compose ps` shows all eight default-profile services Up and the `playwright` container absent; separately run `make test-e2e` and confirm the `playwright` container starts, runs, and exits, while `docs/development.md` explicitly instructs mobile-app development to happen outside Docker.

**Edge Cases**:

- IF a required environment variable is missing from a service's `.env` THEN the system SHALL fail that service's compose config validation rather than starting it with an undefined credential.
- WHEN the stack is torn down THEN the system SHALL cleanly remove all containers without leaving orphaned volumes for anything other than the intentionally-persisted Postgres/MinIO data.
- IF a developer runs a plain `docker compose up` (bypassing `make up`) THEN the system SHALL still not start the `playwright` service, since profile isolation is enforced by the compose file itself, not only by the Makefile wrapper.

---

### P2: QA seeding and a ready-to-use Postman collection

**User Story**: As a QA engineer or another developer picking up this project, I want the database pre-populated with every scenario I'd need to test and a Postman collection covering every endpoint with working example data, so that I can start testing without hand-crafting fixtures or requests.

**Why P2**: Useful once the backend endpoints exist across admin-panel/web-app/landing-page-plans; not needed to boot the dev environment itself (that's the P1 story).

**Acceptance Criteria**:

1. WHEN a developer runs `make seed` THEN the system SHALL populate the database with admin-panel's seeders followed by web-app's seeders, in FK-safe order, covering every status/state scenario those features' own `tasks.md` seeders define.
2. WHEN admin-panel's event seeder runs THEN the system SHALL source real cover images from a free-license web source and upload each through the actual backend image-upload endpoint (multipart request), so the resulting `featuredImageUrl` points at a MinIO-hosted object, never the original external URL and never a value written directly into the database.
3. WHEN all backend endpoints across admin-panel, web-app, and landing-page-plans exist THEN the system SHALL provide one generated Postman collection covering every one of those endpoints, organized by feature.
4. THE Postman collection SHALL include example request data (bodies/params/headers) that work against the seeded fixtures from AC1 - e.g. a real seeded organizer/event ID, not a placeholder.

**Independent Test**: On a freshly seeded database, import the generated Postman collection and successfully execute at least one request per feature folder against the running `make up` stack without manually editing any request body first.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| INFRA-01 | P1: Local development environment starts with one command | Tasks | Implementing |
| INFRA-02 | P1: Local development environment starts with one command | Tasks | Implementing |
| INFRA-03 | P1: Local development environment starts with one command | Tasks | Implementing |
| INFRA-04 | P1: Local development environment starts with one command | Tasks | Implementing |
| INFRA-05 | P1: Local development environment starts with one command | Tasks | Pending |
| INFRA-06 | P1: Local development environment starts with one command | Tasks | Pending |
| INFRA-07 | P1: Local development environment starts with one command | Tasks | Pending |
| INFRA-08 | P1: Local development environment starts with one command | Tasks | Pending |
| INFRA-09 | P1: Local development environment starts with one command (Makefile `up` target) | Tasks | Pending |
| INFRA-10 | P1: Local development environment starts with one command (Playwright test-only profile isolation) | Tasks | Pending |
| INFRA-11 | P2: QA seeding and a ready-to-use Postman collection | Tasks | Pending |
| INFRA-12 | P2: QA seeding and a ready-to-use Postman collection | Tasks | Pending |
| INFRA-13 | P1: Local development environment starts with one command (pgAdmin DB admin UI, added post-spec at user request) | Tasks | Pending |

**ID format:** `INFRA-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 13 total, 0 mapped to tasks, 13 unmapped ⚠️

---

## Success Criteria

- [ ] `make up` (and, equivalently, `docker compose up -d --wait`) boots backend, Reverb, Postgres, MinIO, Mailhog, web-app, admin-panel, and landing-page-plans with no manual intervention.
- [ ] `docs/development.md` explicitly states mobile-app runs on the host, not in Docker, and lists the host prerequisites.
- [ ] No service's `.env.example` is missing a variable the compose file references.
- [ ] The `playwright` service never appears in `docker compose ps` after `make up`/`docker compose up`, and only appears after `make test-e2e`.
- [ ] `make seed` populates every QA scenario defined by admin-panel's and web-app's own seeders, in FK-safe order, with real MinIO-hosted event cover images (never a bare external URL).
- [ ] A generated Postman collection covers every admin-panel/web-app/landing-page-plans endpoint with working example data against the seeded fixtures.
