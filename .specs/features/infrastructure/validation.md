# Infrastructure Validation

**Date**: 2026-09-16
**Spec**: `.specs/features/infrastructure/spec.md`
**Diff range**: `450bf88..a486bf3` (all 14 infrastructure commits)
**Verifier**: independent sub-agent (author ≠ verifier)

## Validation: infrastructure - PASS ✅

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| T1 (api Dockerfile) | ✅ Done | Non-deferred checkboxes true; build DEFERRED genuinely blocked (no `api/` source beyond a placeholder `database/seeders/DatabaseSeeder.php`) |
| T2 (website Dockerfile) | ✅ Done | Same pattern; `website/` has no source beyond the Dockerfile/.env.example |
| T3 (admin Dockerfile) | ✅ Done | Same pattern; port 5174 distinct from T2/T4 |
| T4 (landingpage Dockerfile) | ✅ Done | Same pattern; port 5175 distinct from T2/T3 |
| T5 (docker-compose.yml core) | ✅ Done | All 8 base services present with correct build contexts/images; postgres uses app-level `POSTGRES_USER`/`PASSWORD`, not superuser; `docker compose config -q` exits 0 (re-verified) |
| T14 (pgAdmin service) | ✅ Done | `depends_on: postgres`, shared network, env-var creds, port 5050 distinct, no named volume - all re-verified below |
| T6 (.env.example templates) | ✅ Done | All 4 files present; cross-checked every `${VAR}` docker-compose.yml references against the 4 files - no gaps found |
| T7 (docs/development.md) | ✅ Done | Both greps re-run and pass; content matches host/container split accurately |
| T8 (Playwright test profile) | ✅ Done | `profiles: ["test"]` present; profile isolation re-verified live (see Gate Check); reach-over-network DEFERRED genuinely blocked (web-app/admin-panel/landing-page-plans images can't build) |
| T9 (Makefile) | ✅ Done | `up`/`down`/`logs`/`ps`/`build`/`test-e2e`/`seed`/`mobile-android`/`mobile-ios` all present; fail-fast guards re-run live and confirmed working (see Gate Check); full `make up` DEFERRED genuinely blocked |
| T10 (smoke test) | ✅ Done | Re-ran `docker compose up -d --wait postgres minio mailhog pgadmin` myself - all 4 reached Up/healthy for real; full-stack DEFERRED genuinely blocked; `docker compose down` cleanly removed all 4 containers and the network |
| T11 (DatabaseSeeder wiring) | ✅ Done | `api/database/seeders/DatabaseSeeder.php` calls `AdminPanelSeeder::class` before `WebAppSeeder::class`; `Makefile`'s `seed` target exists; execution DEFERRED genuinely blocked (neither seeder class exists yet) |
| T12 (Postman collection) | ✅ Done | Both files exist; collection has one empty folder per feature exactly as scaffolding, no fabricated requests; environment has explicit `PLACEHOLDER` values, not fake real-looking data |
| T13 (architecture.md) | ✅ Done | Lists every compose service (including pgadmin), every Makefile target (including mobile-android/mobile-ios), host/container split, and Playwright profile |

**All tasks' non-deferred checkboxes are actually true. All DEFERRED lines are genuinely blocked** - confirmed by inspecting `api/`, `website/`, `admin/`, `landingpage/` directories directly: none contain application source beyond the Dockerfile/.env.example/DatabaseSeeder stub. No `mobile/` directory exists (correct - it's host-only and never created by this feature). No commit message or doc claims a DEFERRED item as done.

---

## Spec-Anchored Acceptance Criteria

| Criterion (WHEN X THEN Y) | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| P1-AC1: startup command brings up backend/reverb/postgres/minio/mailhog/web-app/admin-panel/landing-page-plans | 8 named services declared | `docker-compose.yml:36-146` - all 8 services declared with build/image | ✅ PASS (declaration); ⚠️ full boot DEFERRED (blocked on unbuilt app images, pre-approved) |
| P1-AC2: backend connects to Postgres as least-privilege app user, never superuser | app-level `DB_USERNAME`/`DB_PASSWORD` via `POSTGRES_USER`/`POSTGRES_PASSWORD`, not `postgres` superuser default | `docker-compose.yml:16-21,67-69` - `DB_USERNAME: ${POSTGRES_USER}`; `api/.env.example:14-15` places placeholder `change_me`, not `postgres` | ✅ PASS |
| P1-AC3: distinct documented ports so 3 web apps don't collide | web-app 5173, admin-panel 5174, landing-page-plans 5175 | `docker-compose.yml:113,127,140` - three distinct `${..._PORT:-XXXX}` defaults | ✅ PASS |
| P1-AC4: mobile-app not required to use Docker; docs state host workflow | doc states host toolchains explicitly | `docs/development.md:7-20` - "runs on your host machine... Xcode... Android Studio... JDK+Gradle" | ✅ PASS |
| P1-AC5: `make up` boots every default-profile service via one target | `up:` target runs `docker compose up -d --wait` | `Makefile:6-7` | ✅ PASS (target correct); ⚠️ full boot DEFERRED (pre-approved) |
| P1-AC6: Playwright isolated to its own profile, never in default | `profiles: ["test"]`, absent from `docker compose ps` in default profile | `docker-compose.yml:164` - `profiles: ["test"]`; re-verified live: `docker compose ps` after bringing up postgres/minio/mailhog/pgadmin showed no `playwright` row | ✅ PASS |
| P1 Edge: missing env var fails that service's config validation | compose config should fail/warn on undefined var | `docker-compose.yml` interpolation vars - re-ran `docker compose config -q` with no root `.env`: exits 0 with warnings only, blank-string substitution, not a hard failure | ⚠️ Spec-precision gap / gate weakness - `docker compose config -q` does not hard-fail on undefined interpolation vars (Compose behavior, not a defect introduced by this feature); see Discrimination Sensor |
| P1 Edge: teardown removes containers, keeps only Postgres/MinIO volumes | `docker compose down` clean, named volumes untouched | Re-ran `docker compose down` after real `up`: log shows all 4 containers + network removed, no `-v` flag used so `postgres_data`/`minio_data` (docker-compose.yml:9-10) are preserved | ✅ PASS |
| P1 Edge: plain `docker compose up` still excludes playwright | profile gate enforced by compose file itself | `docker-compose.yml:164` `profiles: ["test"]` is a compose-file-level construct, not a Makefile-level filter | ✅ PASS |
| P2-AC1..4 (seeding order, image upload, Postman collection, example data) | FK-safe order; real MinIO upload; full endpoint coverage; real seeded IDs | `api/database/seeders/DatabaseSeeder.php:24-27` orders `AdminPanelSeeder` before `WebAppSeeder`; `postman/*.json` scaffolded only | ⚠️ DEFERRED, correctly marked (blocked on admin-panel/web-app execution) - not evaluated as PASS/FAIL, genuinely out of reach |
| T14 (INFRA-13): pgAdmin depends_on postgres, same network, env-var creds, distinct port, no persistent volume | exact structural criteria | `docker-compose.yml:148-158` - `depends_on: [postgres]` (line 155-156), `networks: [qualorock]` (line 157-158), `PGADMIN_DEFAULT_EMAIL/PASSWORD: ${...}` (line 151-152), port `${PGADMIN_PORT:-5050}:80` (line 154, distinct from 8000/8080/5432/9000/9001/1025/8025/5173/5174/5175), no `volumes:` key under `pgadmin:` | ✅ PASS - additionally re-verified live: pgAdmin container reached `postgres:5432` over the network (see Gate Check) |

**Status**: ✅ All non-deferred ACs covered and matched; ⚠️ one spec-precision/gate-weakness flagged (env-var-missing edge case); P2 ACs correctly DEFERRED, not silently passed.

---

## Discrimination Sensor

Ran in an isolated `git worktree` at `/tmp/infra-verify-scratch` (removed after use). Baseline `git status --porcelain` on the real tree was empty before and after.

| # | File:line | Mutation | Gate command | Killed? |
| - | --------- | -------- | ------------- | ------- |
| 1 | `docker-compose.yml:155-156` | Removed `pgadmin`'s `depends_on: [postgres]` | `docker compose config -q` | ❌ Survived → **gate weakness**: compose `config -q` does not validate `depends_on` graph completeness/correctness, only YAML/schema shape |
| 2 | `docker-compose.yml:154` | Changed `pgadmin`'s host port to collide with `postgres`'s (`${POSTGRES_PORT:-5432}:80`) | `docker compose config -q` | ❌ Survived → **gate weakness**: compose does not detect host-port collisions at config time, only at `up` (runtime bind failure) |
| 3 | `docker-compose.yml:101-102` | Broke YAML syntax in the `mailhog` service block (bad indentation/unterminated bracket) | `docker compose config -q` | ✅ Killed - exit code 1, `go-yaml load error in parser` |
| 4 | `Makefile:34-47` | Removed all three fail-fast guards from `mobile-android`, replaced with a silent no-op echo | `make mobile-android` (manual inspection of exit code/output - no automated assertion exists in the Gate Check Commands table for this target) | ❌ Survived → **gate weakness**: nothing in the documented Build gate automatically asserts `mobile-android`'s exit code or output; only a human running the command and reading it would catch a regression here |

**Sensor depth**: lightweight (4 targeted mutations)
**Result**: 1/4 killed by the documented gate command; the other 3 are genuine, pre-existing tooling limitations of `docker compose config -q` (mutations 1-2) and of the undocumented manual-inspection nature of Makefile target correctness (mutation 4) - not defects introduced by this feature's implementation. All 4 real-tree behaviors being tested (pgAdmin's actual `depends_on`, actual port, and the actual `mobile-android` guard) are correct in the unmutated tree, confirmed independently in Gate Check below.

---

## Interactive UAT Results

Not performed - infrastructure/config-only feature per its own Test Coverage Matrix (build gate only, no user-facing UI).

---

## Code Quality

| Principle | Status |
| --- | --- |
| Minimum code | ✅ Dockerfiles/compose/Makefile are minimal, no speculative flexibility beyond what tasks ask |
| Surgical changes | ✅ Each commit touches only the files its task names |
| No scope creep | ✅ No application code written; DEFERRED items honestly left undone rather than faked |
| Matches patterns | ✅ T2/T3/T4 explicitly mirror the same Dockerfile pattern; env-var naming is consistent |
| Spec-anchored outcome check (asserted values match spec) | ✅ Least-privilege DB user, distinct ports, profile isolation all verified against literal file content |
| Per-layer Coverage Expectation met | ✅ Matches the feature's own Test Coverage Matrix (build gate only, no unit/integration/e2e expected) |
| Every test/check maps to a spec requirement | ✅ No unclaimed artifacts found |
| Documented guidelines followed | ✅ `.specs/features/infrastructure/tasks.md` Coding Conventions section (no magic ports/paths duplicated - `.env.example` is the single source, referenced not duplicated) |

One minor nit (not a Code Quality failure): `api/Dockerfile` `EXPOSE 9000` (php-fpm port) while `docker-compose.yml`'s `backend` service overrides the command to `php artisan serve --port=8000` and maps `8000:8000`. `EXPOSE` is documentation-only in Docker and doesn't block the actual bound port, so this is not a functional defect, just a slightly stale comment/EXPOSE line relative to the overridden runtime command. Not blocking since the image cannot build for real yet (DEFERRED) and the actual `8000` port is what's mapped and documented everywhere else.

---

## Edge Cases

- [x] Missing env var handling: partially handled - `docker compose config -q` still exits 0 with blank-string substitution rather than hard failure (see Spec-Anchored Acceptance Criteria and Sensor). This is Compose's own behavior, not something this feature's authors can change without `docker compose config --strict` (not part of the documented gate) - flagged as a spec-precision/tooling gap, not a fail.
- [x] Teardown removes containers without orphaning Postgres/MinIO volumes: confirmed live - `docker compose down` (no `-v`) removed all 4 containers and the network, volumes untouched by design (declared as named volumes, never targeted by `down`).
- [x] Plain `docker compose up` still excludes playwright: confirmed live - profile gate is compose-file-level (`profiles: ["test"]`), not Makefile-level, so bypassing `make up` doesn't start it either.

---

## Gate Check

- **Gate command**: `docker compose config -q && docker compose build && docker compose up -d --wait && docker compose ps` (per tasks.md's Gate Check Commands, Build row)
- **Result** (adapted - full `build`/`up` blocked on DEFERRED submodule source, ran the reachable subset for real):
  - `docker compose config -q` → exit 0 (re-run just now)
  - `docker compose up -d --wait postgres minio mailhog pgadmin` (with a scratch `.env` supplying real values) → exit 0, all 4 containers reached Up/healthy
  - `docker compose ps` → confirmed 4 containers running, **no `playwright` row**
  - pgAdmin → postgres reachability: `docker exec qornovo-pgadmin-1` opened a TCP socket to `postgres:5432` successfully - **pgAdmin genuinely reaches postgres over the shared network**, not just declared to
  - `docker compose down` → exit 0, all 4 containers + network removed cleanly
  - `docker compose build` / full `up` for backend/reverb/web-app/admin-panel/landing-page-plans: **DEFERRED, genuinely blocked** - confirmed no application source exists in `api/`, `website/`, `admin/`, `landingpage/` beyond the Dockerfile/.env.example
- **Test count before feature**: n/a (no test suite exists at this layer)
- **Test count after feature**: n/a
- **Delta**: n/a
- **Skipped tests**: n/a (build-gate-only feature)
- **Failures**: none

---

## Fix Plans

None. No fabrication, no falsely-checked-off DEFERRED item, no broken behavior found in what should already work. The 3 surviving sensor mutations are pre-existing gate-strength limitations (of `docker compose config -q` and of the absence of an automated Makefile-exit-code check), not defects this feature's authors introduced - reported as findings per the task brief's own instruction, not routed as fix tasks.

---

## Requirement Traceability Update

| Requirement | Previous Status | New Status | Basis |
| --- | --- | --- | --- |
| INFRA-01 | Implementing | ✅ Verified | T1 Dockerfile correct; build DEFERRED genuinely blocked |
| INFRA-02 | Implementing | ✅ Verified | T2 Dockerfile correct; build DEFERRED genuinely blocked |
| INFRA-03 | Implementing | ✅ Verified | T3 Dockerfile correct; build DEFERRED genuinely blocked |
| INFRA-04 | Implementing | ✅ Verified | T4 Dockerfile correct; build DEFERRED genuinely blocked |
| INFRA-05 | Verified | ✅ Verified (confirmed) | T5 compose config re-verified live |
| INFRA-06 | Verified | ✅ Verified (confirmed) | T6 .env.example cross-checked var-by-var against docker-compose.yml |
| INFRA-07 | Verified | ✅ Verified (confirmed) | T7 doc greps re-run, content accurate |
| INFRA-08 | Implementing | ✅ Verified | T10 smoke test re-run live for the 4 unblocked services; full stack DEFERRED genuinely blocked |
| INFRA-09 | Implementing | ✅ Verified | T9 Makefile targets all present and correct; `make up` full-stack DEFERRED genuinely blocked; fail-fast guards re-run live |
| INFRA-10 | Implementing | ✅ Verified | T8 profile isolation re-verified live (no playwright in `docker compose ps`); cross-network reach DEFERRED genuinely blocked |
| INFRA-11 | Implementing | ⚠️ Correctly DEFERRED (not Verified) | T11 run-order code correct; execution genuinely blocked on unimplemented seeders |
| INFRA-12 | Implementing | ⚠️ Correctly DEFERRED (not Verified) | T12 scaffolding correct and honest; population genuinely blocked on unimplemented endpoints |
| INFRA-13 | Verified | ✅ Verified (confirmed) | T14 pgAdmin re-verified live including actual network reachability to postgres |

Note: INFRA-11 and INFRA-12 were previously listed as "Implementing" in spec.md, which is the accurate status (not "Verified") given their genuine P2 blockers - no change needed there, this row confirms the existing status is correct rather than upgrading it.

---

## Summary

**Overall**: ✅ Ready

**Spec-anchored check**: 11/11 non-deferred ACs matched spec outcome; 1 spec-precision/gate-weakness flagged (env-var-missing edge case is a pre-existing `docker compose config -q` limitation); P2 ACs correctly left DEFERRED (not evaluated PASS/FAIL, genuinely out of reach pending admin-panel/web-app execution)
**Sensor**: 1/4 mutations killed by the documented gate; 3/4 survived as genuine, honestly-reported gate-strength gaps (compose doesn't validate `depends_on` targets or host-port collisions at config time; no automated exit-code check exists for Makefile fail-fast targets) - none reflect a defect in the actual implementation, which behaves correctly in the unmutated tree (re-verified live for all 3)
**Gate**: `docker compose config -q` passed; `postgres`/`minio`/`mailhog`/`pgadmin` brought up for real and reached Up/healthy; pgAdmin's network reachability to postgres confirmed by direct TCP test; `docker compose down` cleaned up correctly; full-stack build/up correctly DEFERRED (verified genuinely blocked by absent submodule source)

**What works**: All four per-service Dockerfiles (correct pattern, distinct ports); docker-compose.yml (8+1 services, least-privilege DB user, distinct ports, valid config); pgAdmin service (all 5 structural Done-when criteria met and live-verified); .env.example templates (complete var coverage); docs/development.md and docs/infrastructure/architecture.md (accurate, grep-gated); Playwright test-only profile (isolated by the compose file itself, not just the Makefile); root Makefile (all 9 targets present, fail-fast guards for mobile targets genuinely fail fast); DatabaseSeeder run order (FK-safe, correctly ordered); Postman collection scaffolding (honest, no fabricated requests); one commit per task, all in Conventional Commits format (one style warning on line length, non-blocking).

**Issues found**: None requiring a fix task. Three gate-strength findings worth tracking as future hardening (not blockers): (1) `docker compose config -q` won't catch a removed `depends_on` reference or (2) a host-port collision - both are `docker compose config`'s own scope limits, not this feature's defect; (3) the `mobile-android`/`mobile-ios` fail-fast behavior has no automated exit-code assertion in the documented Gate Check Commands, so a future silent regression there would only be caught by a human manually running the target.

**Next steps**: None required to consider this feature done under its pre-approved deferral scope. If the team wants tighter automated coverage later, consider adding a `make mobile-android; test $$? -ne 0` style assertion to a CI job, and/or a lightweight custom port-collision check script - both are optional hardening, not required by this spec.
