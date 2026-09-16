# Dev/Debug-Mode Logging Specification

## Problem Statement

None of the five stacks (`api`, `website`, `admin-panel`, `landing-page-plans`, `mobile-app`) has a debug-mode logging story today. A developer debugging a request that spans `api` and triggers a Reverb broadcast has no way to correlate the two log lines, and the three web apps rely on raw `console.log` calls with no dev/production gating. This spec defines what gets logged in debug mode, and how, across all five stacks — not where logs are stored long-term.

## Goals

- [ ] Every `api` request is traceable end-to-end (including the Reverb broadcast it triggers) via one correlation ID appearing on every related log line.
- [ ] Debug-mode logging never ships to a production build on any stack (zero debug output in release builds).

## Out of Scope

| Feature | Reason |
| --- | --- |
| Production log aggregation/shipping (ELK, Datadog, CloudWatch, etc.) | This spec only covers what gets logged and how in dev/debug mode, not where logs land long-term. A future `infrastructure`-scoped spec can add shipping once a provider is chosen. |
| Alerting on log content (error-rate thresholds, paging) | Requires a shipping destination first (see above); no such destination exists yet. |
| Log retention/rotation policy | Local dev logs are ephemeral (container stdout / native debug console); retention only matters once logs are shipped somewhere persistent. |
| A log-viewing UI or authenticated log-query endpoint | Not requested; logs are read via `docker compose logs`, the browser console, or the platform's native debug console (Logcat/os_log) — no new authenticated surface is introduced. |
| Structured logging for `analytics-tracking`'s Firebase Analytics events | Owned by `analytics-tracking` (AD-018) — that spec reuses this feature's mobile `Logger`, but the requirement to log analytics events lives in `analytics-tracking/spec.md`, not here. |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| JSON log format for `api` debug mode | Monolog's built-in `JsonFormatter` | Standard, Laravel-native way to get structured logs without adding a new library | y |
| Correlation header name | `X-Request-Id` | Common cross-framework convention; no existing convention in the codebase to conflict with | y |
| Debug-toggle env vars | `APP_DEBUG` / `LOG_LEVEL` / `LOG_CHANNEL` (Laravel-native names) | Reuses Laravel's own `.env` keys instead of inventing project-specific ones, and slots into `infrastructure`'s existing `.env.example` convention (AD-017) | y |
| Redacted field list (request/response/SQL logs) | `password`, `password_confirmation`, `token`, `secret`, `api_key`, `authorization` (case-insensitive, matched at any nesting depth) | Covers the fields AD-008 already flags as sensitive | n — list may need expansion once real endpoints exist |
| Truncation bound for logged request/response bodies | 10 KB | Reasonable default to avoid unbounded log growth from large payloads (e.g. image uploads); no existing convention to anchor to | n |
| Mobile `Logger`'s structured `event(name, params)` call form | Added specifically so `analytics-tracking` (AD-018) can reuse this logger for Firebase Analytics event visibility, instead of building a second mechanism | Avoids duplicating a debug-logging capability across two specs, per the AD-008 precedent for shared capabilities | y |

**Open questions:** none — all resolved or logged above.

---

## Implicit-Requirement Dimensions Sweep

| Dimension | Resolution |
| --- | --- |
| Input validation & bounds | LOG-15 (body truncation bound below) |
| Failure / partial-failure states | LOG-13 (logging failures must not break the request) |
| Idempotency / retry / duplicate handling | N/A because logging is an append-only side effect with no retry/duplicate semantics to define |
| Auth boundaries & rate limits | N/A because no new authenticated endpoint or queryable log surface is introduced (see Out of Scope) |
| Concurrency / ordering | LOG-14 (request-scoped correlation ID, not shared mutable state) |
| Data lifecycle / expiry | N/A because log retention/rotation is explicitly Out of Scope for this pass |
| Observability | This feature IS the observability requirement — covered throughout |
| External-dependency failure | N/A because this feature's logging targets (Monolog, `console`, `os_log`/Logcat) are stdlib-adjacent, not network services; `analytics-tracking`'s Firebase Analytics dependency is out of this spec's scope |
| State-transition integrity | N/A because no stateful entity or state machine is introduced by this feature |

---

## User Stories

### P1: A developer can trace one request across `api` and Reverb ⭐ MVP

**User Story**: As a developer debugging locally, I want every log line produced while handling one request — including the Reverb broadcast it triggers — tagged with the same correlation ID, so that I can filter logs down to exactly one user action instead of guessing which lines belong together.

**Why P1**: This is the concrete pain point that motivated the feature — cross-service debugging has no correlation mechanism today.

**Acceptance Criteria**:

1. WHEN a request reaches `api` without an `X-Request-Id` header THEN the system SHALL generate a UUIDv4 value, attach it as `X-Request-Id` on the response, and include it in every log line emitted while handling that request.
2. WHEN a request reaches `api` with an existing `X-Request-Id` header THEN the system SHALL reuse that value instead of generating a new one.
3. WHILE `APP_DEBUG=true` and `LOG_LEVEL=debug`, the system SHALL emit `api` logs in JSON format (Monolog `JsonFormatter`), each line containing at minimum: timestamp, level, `X-Request-Id`, message, and a structured context object.
4. WHEN a request handled by `api` triggers a Reverb broadcast THEN the system SHALL include that request's `X-Request-Id` in the broadcast's server-side log line.
5. IF `APP_DEBUG=false` THEN the system SHALL NOT emit JSON-formatted debug logs, regardless of `LOG_LEVEL` — production logging stays at Laravel's default line format and level.

**Independent Test**: With `APP_DEBUG=true`, send a request that triggers a Reverb broadcast; grep the container logs for the response's `X-Request-Id` value and confirm both the `api` request log line and the Reverb broadcast log line appear, sharing that same ID.

---

### P1: Debug mode logs request/response bodies and SQL, with sensitive fields redacted

**User Story**: As a developer debugging a failing request locally, I want to see the actual request body, response body, and SQL queries executed, with secrets redacted, so that I can diagnose the failure without adding temporary `dd()`/`var_dump()` calls.

**Why P1**: Body/SQL visibility is the other half of what makes debug-mode logging actually useful for diagnosing a failure, not just tracing that one happened.

**Acceptance Criteria**:

1. WHILE `APP_DEBUG=true`, the system SHALL log each request's HTTP method, path, and body, and each response's status code and body.
2. WHILE `APP_DEBUG=true`, the system SHALL log every SQL query executed during that request (query string + bound parameter values) via Laravel's query-log listener.
3. THE system SHALL redact the value of any field named `password`, `password_confirmation`, `token`, `secret`, `api_key`, or `authorization` (case-insensitive, matched at any nesting depth of a JSON body or SQL bind parameter) before it is written to a debug log, replacing the value with the literal string `"[REDACTED]"`.
4. IF `APP_DEBUG=false` THEN the system SHALL NOT log request/response bodies or SQL queries.

**Independent Test**: With `APP_DEBUG=true`, send a login request containing a `password` field; confirm the debug log shows the request body with `password` replaced by `"[REDACTED]"`, and that the executed `SELECT`/`UPDATE` SQL's bound password parameter is also redacted.

---

### P2: The three web apps use a dev-gated logger instead of raw `console.log`

**User Story**: As a developer working on `website`/`admin-panel`/`landing-page-plans`, I want debug/info logging that's automatically silent in a production build, so that debug output never leaks to end users and I don't have to manually strip `console.log` calls before shipping.

**Why P2**: Useful for day-to-day frontend debugging, but not blocking — the backend correlation story (P1) is the concrete pain point that motivated this feature.

**Acceptance Criteria**:

1. WHILE `import.meta.env.DEV` is true, each of `website`, `admin-panel`, and `landing-page-plans` SHALL route debug/info/warn/error calls through a shared logger utility that prefixes each line with the calling app's name and passes through to the matching `console.*` method.
2. WHILE `import.meta.env.DEV` is false (a production build), the logger utility SHALL be a no-op for its debug/info methods; its warn/error methods SHALL still pass through to `console.warn`/`console.error`.

**Independent Test**: Run each app's dev server and confirm `logger.debug(...)` calls appear in the browser console; run each app's production build and confirm the same calls produce no console output while `logger.error(...)` still does.

---

### P3: The mobile app has a debug-only structured logger, reusable by other features

**User Story**: As a developer working on the mobile app, I want a shared KMP logger that's silent in release builds and supports both plain messages and structured events, so that debug output never ships to end users and other features (like `analytics-tracking`) don't need to build a second logging mechanism.

**Why P3**: Lower urgency than the backend/web stories since mobile app development hasn't started yet, but the structured `event()` call form is a direct dependency for `analytics-tracking` (AD-018).

**Acceptance Criteria**:

1. WHILE the mobile app is a debug build, the shared KMP `Logger` SHALL accept a plain-message call (`Logger.d(tag, message)`) and print it to the platform's native debug console (Logcat on Android, `os_log`/Console on iOS).
2. WHILE the mobile app is a debug build, the shared KMP `Logger` SHALL accept a structured call (`Logger.event(tag, name, params: Map<String, Any>)`) and print the event name and parameters to the same native debug console.
3. WHILE the mobile app is a release build, the shared KMP `Logger` SHALL be a no-op for both call forms.

**Independent Test**: In a debug build, call `Logger.event("Analytics", "test_event", mapOf("k" to "v"))` and confirm it appears in Logcat/Console; in a release build, confirm the same call produces no output.

---

## Edge Cases

- IF a request's `X-Request-Id` header is present but not a valid UUID THEN the system SHALL still accept and log it as-is, rather than rejecting the request over a malformed correlation header (third-party clients may send non-UUID trace IDs).
- IF a logged request/response body exceeds 10 KB THEN the system SHALL truncate the logged body to 10 KB and append a `"...[truncated]"` marker, rather than logging an unbounded payload. (LOG-15)
- IF the logging sink fails to write (e.g. a disk/IO error) THEN the system SHALL swallow the logging failure and continue serving the request — a logging fault SHALL NOT raise an exception to the caller. (LOG-13)
- THE system SHALL keep each request's `X-Request-Id` request-scoped (resolved from Laravel's per-request service container), never stored in a shared/global mutable variable, so concurrent requests never leak or overwrite each other's correlation ID. (LOG-14)

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| LOG-01 | P1: A developer can trace one request across api and Reverb | Tasks | Pending |
| LOG-02 | P1: A developer can trace one request across api and Reverb | Tasks | Pending |
| LOG-03 | P1: A developer can trace one request across api and Reverb | Tasks | Pending |
| LOG-04 | P1: A developer can trace one request across api and Reverb | Tasks | Pending |
| LOG-05 | P1: Debug mode logs request/response bodies and SQL, with sensitive fields redacted | Tasks | Pending |
| LOG-06 | P1: Debug mode logs request/response bodies and SQL, with sensitive fields redacted | Tasks | Pending |
| LOG-07 | P1: Debug mode logs request/response bodies and SQL, with sensitive fields redacted | Tasks | Pending |
| LOG-08 | P1: Debug mode logs request/response bodies and SQL, with sensitive fields redacted | Tasks | Pending |
| LOG-09 | P2: The three web apps use a dev-gated logger instead of raw console.log | Tasks | Pending |
| LOG-10 | P2: The three web apps use a dev-gated logger instead of raw console.log | Tasks | Pending |
| LOG-11 | P3: The mobile app has a debug-only structured logger, reusable by other features | Tasks | Pending |
| LOG-12 | P3: The mobile app has a debug-only structured logger, reusable by other features | Tasks | Pending |
| LOG-13 | Edge case: logging failures must not break the request | Tasks | Pending |
| LOG-14 | Edge case: request-scoped correlation ID under concurrency | Tasks | Pending |
| LOG-15 | Edge case: logged body truncation bound | Tasks | Pending |

**ID format:** `LOG-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 15 total, 0 mapped to tasks, 15 unmapped ⚠️

---

## Success Criteria

- [ ] Two concurrent `api` requests each get their own distinct `X-Request-Id`, and each ID's log lines never appear mixed with the other request's.
- [ ] Setting `APP_DEBUG=false` removes all request/response-body and SQL logging with no code change — only the env var flips.
- [ ] A production build of `website`/`admin-panel`/`landing-page-plans` produces zero `logger.debug`/`logger.info` console output.
- [ ] A release mobile build produces zero `Logger` output for either call form.
- [ ] A request containing a `password` field never appears unredacted in any debug log line.
