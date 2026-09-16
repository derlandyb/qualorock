# STATE

## Decisions

### AD-001
- **Decision**: The platform is specified as four independent feature specs — `mobile-app`, `web-app`, `admin-panel`, `landing-page-plans` — each with its own requirement-ID namespace (MOBILE-*, WEB-*, ADMIN-*, PLAN-*), rather than one combined platform spec or a shared spec for mobile+web (even though mobile/web functional requirements largely mirror each other).
- **Reason**: User explicitly requested this split so each surface (and its platform-specific gaps, e.g. the missing web notifications screen) can be designed/tasked/verified independently without blocking or silently inheriting from another surface.
- **Trade-off**: Mobile and web ACs duplicate almost 1:1 today; a shared requirement changing on one platform must be manually mirrored to the other's spec rather than being a single source of truth.
- **Scope**: Governs `.specs/features/mobile-app`, `.specs/features/web-app`, `.specs/features/admin-panel`, `.specs/features/landing-page-plans`.
- **Date**: 2026-09-15
- **Status**: active

### AD-002
- **Decision**: The admin panel (organizer/venue console) uses its own, separate login/signup system, entirely distinct from the consumer app's social/email login (FR-ACC-01/02).
- **Reason**: Explicit user decision — organizers are a different persona with different auth needs (tied to approval gating), not consumer accounts with an elevated role flag.
- **Trade-off**: Two auth systems to build and maintain instead of one with role-based access; an organizer who is also a fan needs two separate accounts.
- **Scope**: Governs `.specs/features/admin-panel` (login) and `.specs/features/landing-page-plans` (signup creates a credential in this same separate system).
- **Date**: 2026-09-15
- **Status**: active

### AD-003
- **Decision**: Every organizer account has exactly one of three approval states — `pending`, `approved`, `rejected` — and only a Super Admin (provisioned out-of-band, no self-service path) can move an account out of `pending`. No self-registered organizer gets platform access automatically, regardless of selected plan tier.
- **Reason**: Explicit user decision: free-plan self-registration must still require super-admin approval before the platform can be used.
- **Trade-off**: Adds an approval-latency step between signup and first use; requires building a Super Admin review surface before any organizer can be onboarded end-to-end.
- **Scope**: Governs `.specs/features/admin-panel` (the approval gate + Super Admin review UI) and `.specs/features/landing-page-plans` (the signup flow that produces the `pending` account).
- **Date**: 2026-09-15
- **Status**: active

### AD-004
- **Decision**: Shared technology stack across all four surfaces — Laravel (latest) on PHP 8.4 as the single backend API; PostgreSQL as the database, accessed via a least-privilege application DB user (not superuser); React + Tailwind CSS for the three web surfaces (web-app, admin-panel, landing-page-plans), each its own app rather than one shared codebase; Kotlin Multiplatform for mobile with fully native UI (SwiftUI on iOS, Jetpack Compose on Android); custom-built auth (no third-party IDP) via Laravel Sanctum with two distinct guards/user models (consumer vs organizer); Laravel Reverb (self-hosted WebSockets) for real-time-ish updates; Google Maps Platform for embedded maps/geocoding; Laravel Mail over a generic SMTP relay for transactional email; Docker Compose for local dev (all stack except mobile); a VPS for production; one root git repo with `mobile`, `website`, `backend`, `landingpage`, `adminpanel` as submodules.
- **Reason**: Explicit user choice for every layer (this is a from-scratch project with no existing code) — PostgreSQL's least-privilege user and custom-built auth were both stated as deliberate security decisions, not defaults.
- **Trade-off**: Custom-built dual auth (vs. a managed IDP) means owning OAuth integration, session/token issuance, and approval-state gating in-house — more implementation and security surface, but no vendor lock-in/cost. Three independent React apps (vs. one shared web codebase) means UI/component duplication across web-app/admin-panel/landing-page-plans unless a shared component library is introduced later.
- **Scope**: Governs all of `.specs/features/{mobile-app,web-app,admin-panel,landing-page-plans}` — this is the project's foundational architecture decision every feature's `design.md` conforms to.
- **Date**: 2026-09-15
- **Status**: active

### AD-005
- **Decision**: Two plan tiers for `landing-page-plans`: **Basic** (free) capped at 4 published events/month, enforced (an organizer is blocked from publishing a 5th event in a calendar month); **Plus** (paid) with unlimited event publishing and no other feature difference from Basic. Billing for Plus runs through an external link, mirroring the existing ticket-purchase pattern — no in-app checkout.
- **Reason**: Explicit user decision on tier structure and enforcement; external-link billing keeps PCI scope out of the platform, consistent with how ticket purchases already work.
- **Trade-off**: Enforcing the Basic cap requires the admin-panel to track a rolling monthly published-event count per organizer, not just accept-all event creation — real backend logic, not just a landing-page comparison table.
- **Scope**: Governs `.specs/features/landing-page-plans` (tier display/signup) and `.specs/features/admin-panel` (the enforcement + pricing management in AD-006).
- **Date**: 2026-09-15
- **Status**: active

### AD-006
- **Decision**: New admin-panel capability, not in the original ADMIN-01..19 set: a Super Admin can edit the Plus tier's price via a form, and every price change is kept as a versioned historical record in the database. The landing page reads the *current* price dynamically from this data rather than a hardcoded value.
- **Reason**: Explicit user requirement, surfaced when specifying the Plus tier's price during this session's Discuss pass.
- **Trade-off**: Adds a new admin-panel domain (price history) and a new landing-page read dependency on backend-managed pricing data, instead of the landing page being fully static content.
- **Scope**: Governs `.specs/features/admin-panel` (new pricing-management story) and `.specs/features/landing-page-plans` (dynamic price read).
- **Date**: 2026-09-15
- **Status**: active

### AD-007
- **Decision**: `admin-panel`'s two remaining Discuss items resolved: (1) rejection UX stays at the spec's existing minimal default — a rejected organizer sees their rejection state + optional reason on login, no in-product resubmit/appeal flow; (2) admin-panel access itself stays uniform across tiers (no feature-gating beyond the AD-005 Basic event cap).
- **Reason**: Explicit user decisions, both taking the recommended/minimal default over building additional flows not yet requested.
- **Trade-off**: A rejected organizer who wants reconsideration has no self-service path — would require manual/out-of-band re-onboarding if ever needed; deferred rather than built speculatively.
- **Scope**: Governs `.specs/features/admin-panel`.
- **Date**: 2026-09-15
- **Status**: active

### AD-008
- **Decision**: Cross-cutting LGPD and security baseline for all four features. LGPD, in scope now: (a) explicit timestamped consent capture at signup on both consumer (mobile-app/web-app) and organizer (landing-page-plans) flows; (b) self-service data export & deletion for both a consumer account and an organizer account (new requirements needed in `web-app`/`mobile-app` and `admin-panel`); (c) a privacy-policy page + DPO/encarregado contact linked in-product (surface only — legal text supplied later by the user). Data residency in Brazil was explicitly declined — hosting location is not constrained. Security baseline, applied as architecture guardrails in every `design.md` (not new user stories): all DB access through Eloquent/query builder only (no raw SQL, SQL-injection protection); Policy/Gate-based authorization on every endpoint touching a user/organizer-owned resource (IDOR protection); web sessions via HttpOnly+Secure+SameSite cookies instead of localStorage, mobile sessions via iOS Keychain/Android Keystore.
- **Reason**: Explicit user requirement — the whole platform must be LGPD-covered and defended against SQL injection and IDOR, stated directly (not inferred).
- **Trade-off**: Self-service export/deletion and consent-timestamp storage add real backend scope (new endpoints, new audit data) beyond what the original specs described; cookie-based web sessions require CSRF handling that token-in-localStorage would have avoided, but close the XSS-token-theft gap that motivated the requirement.
- **Scope**: Governs all of `.specs/features/{mobile-app,web-app,admin-panel,landing-page-plans}` — every feature's `design.md` must state its compliance with this baseline explicitly.
- **Date**: 2026-09-15
- **Status**: active

### AD-009
- **Decision**: Media (event/profile/venue images) via S3-compatible object storage through Laravel's Flysystem abstraction (AWS S3 or self-hosted MinIO — provider TBD as an implementation prerequisite). Analytics: Google Analytics added across consumer-facing surfaces, alongside (not replacing) the first-party engagement data already modeled for the admin dashboard; because GA is a third-party tracker, the AD-008 consent flow must extend to cookie/tracking consent, not just account-data consent. Localization: Portuguese (pt-BR) only for this pass — no i18n/translation-key framework built now.
- **Reason**: Explicit user choices; GA was chosen over a self-hosted/privacy-first alternative despite the LGPD direction already set, so the consent-extension trade-off is called out explicitly rather than silently absorbed.
- **Trade-off**: GA sends user behavioral data to a third party, which is the one point of tension with AD-008's LGPD framing — mitigated by requiring consent-gated script loading, not by avoiding GA. Skipping i18n now means a future multi-language push is a retrofit, not a day-one capability.
- **Scope**: Governs all of `.specs/features/{mobile-app,web-app,admin-panel,landing-page-plans}`.
- **Date**: 2026-09-15
- **Status**: active

### AD-010
- **Decision**: TDD is mandatory across backend, web, and mobile; every test name/description must follow GIVEN/WHEN/THEN with the keywords capitalized, with no exceptions. Tooling: backend — Pest or PHPUnit (feature tests against real routes + a test DB, unit tests for isolated logic); web — Jest + React Testing Library; cross-platform — Playwright for end-to-end flows; mobile — `kotlin.test` for the shared KMP module, XCTest for SwiftUI, Compose UI tests for Jetpack Compose. Coverage gate: ≥80%, enforced in CI (AD-011).
- **Reason**: Explicit user mandate, stated directly — not inferred from repo conventions (there are none yet, this is greenfield).
- **Trade-off**: Mandatory TDD + a hard 80% coverage gate + a fixed naming convention adds process overhead to every task, but buys the skill's own execution-contract guarantee (tests assert spec-defined outcomes) uniformly across four different tech stacks.
- **Scope**: Governs all of `.specs/features/{mobile-app,web-app,admin-panel,landing-page-plans}` and every future Tasks/Execute phase.
- **Date**: 2026-09-15
- **Status**: active

### AD-011
- **Decision**: Git/CI workflow for the future Tasks/Execute phases: Conventional Commits (one commit per task, matching the skill's own contract) and Conventional branch naming, with one branch per Phase/Milestone off `main` (not one branch per task). After a milestone branch's development completes, a stack-specific code-review subagent reviews its PR and leaves comments; comments are read, addressed with fix commits, and the PR updated. A PR can only merge once CI is fully green. CI (GitHub Actions) quality gates: per-stack lint (Pint/PHPStan, ESLint, detekt), the full test suite from AD-010, coverage ≥80% as a required check, `detekt` specifically required for Android/Kotlin, and `ubuntu-latest` runners for every job except SwiftUI/iOS tests (which require macOS/Xcode).
- **Reason**: Explicit user mandate for how future implementation work must be branched, reviewed, and gated.
- **Trade-off**: Branch-per-milestone (not per-task) means a milestone's tasks share a branch until the whole milestone's automated review+fix cycle completes before merge — slower to land individual tasks on `main`, but keeps PR-level code review meaningful (reviewing one task's diff in isolation would be too granular to be useful).
- **Scope**: Governs the *future* Tasks/Execute phases for all four features — no `.github/workflows` files or code are authored in this Design pass; recorded now so the decision isn't lost before Tasks starts.
- **Date**: 2026-09-15
- **Status**: active

### AD-012
- **Decision**: Clean Architecture, domain-agnostic, applied uniformly across every stack: 4 layers — Domain (framework-agnostic entities + repository interfaces/contracts), Application (use-cases, services, policies orchestrating Domain via the contracts), Infrastructure (concrete repository implementations, Eloquent models, API clients), Presentation (controllers for the backend; pages/components for the three React SPAs; SwiftUI/Compose screens for mobile). Backend: `app/{Domain,Application,Infrastructure,Presentation}`. React SPAs (web-app, admin-panel, landing-page-plans): `src/{domain,application,infrastructure,presentation}` — same 4-layer split, not a lighter frontend-only variant. Mobile: the KMP shared module holds Domain + Application + Infrastructure(data); native iOS/Android UI is Presentation-only and calls Application-layer use-cases, never repositories or the Ktor client directly.
- **Reason**: Explicit user requirement this session, to keep business logic testable and framework-independent across four different stacks built from scratch.
- **Trade-off**: More files and indirection per feature (an entity + a contract + a use-case + an implementation, instead of one Eloquent model + one controller) — deliberately accepted for consistency and testability over the fastest path to a working CRUD endpoint.
- **Scope**: Governs every future Tasks/Execute pass for all five units (`infrastructure`, `admin-panel`, `web-app`, `landing-page-plans`, `mobile-app`).
- **Date**: 2026-09-16
- **Status**: active

### AD-013
- **Decision**: Project-wide code-quality baseline — DRY, KISS, Clean Code, YAGNI (write only what an approved requirement needs, no speculative flexibility), no magic numbers/strings (every literal with meaning gets a named constant, centralized under each layer's own constants location — e.g. backend `Domain/Constants`, React `src/domain/constants`, KMP `shared/.../domain/constants`), and one class per file in every stack (PHP, TypeScript/TSX, Kotlin, Swift alike).
- **Reason**: Explicit user requirement this session, to keep the from-scratch codebase consistent and free of duplicated/inline literals from day one.
- **Trade-off**: One-class-per-file and named-constants-everywhere add file count and a small amount of indirection versus colocating small helper classes or inlining a one-off literal; accepted for long-term navigability.
- **Scope**: Governs every future Tasks/Execute pass for all five units.
- **Date**: 2026-09-16
- **Status**: active

### AD-014
- **Decision**: No task/ticket/implementation-narrative comments in code (e.g. no `// ADMIN-06` or `// fixes T13` style comments) — this formalizes the project's existing root `CLAUDE.md` "no comments referencing the current task" rule as a cross-project architecture decision. All such documentation instead lives as Markdown under a per-stack `docs/` subfolder: `docs/backend/`, `docs/web-app/`, `docs/admin-panel/`, `docs/landing-page-plans/`, `docs/mobile/`, `docs/infrastructure/` — each stack's own `architecture.md` is the canonical write-up of its Clean Architecture layering (AD-012) and conventions (AD-013).
- **Reason**: Explicit user requirement this session; keeps code comments limited to non-obvious *why*, per the project's existing coding guidelines, while still giving every stack a durable architecture write-up.
- **Trade-off**: Documentation now lives in a separate file from the code it describes, which can drift if not kept current during Execute — accepted because the alternative (comments narrating tasks) rots even faster and pollutes the code itself.
- **Scope**: Governs every future Tasks/Execute pass for all five units.
- **Date**: 2026-09-16
- **Status**: active

### AD-015
- **Decision**: Mobile test-identifier convention — Android: every Compose `testTag` string is a named resource inside one dedicated `strings-test.xml` file (no inline string literals at the call site); iOS: every accessibility-identifier constant lives in one dedicated `TestTags.swift` file (the idiomatic iOS equivalent, since iOS has no XML strings mechanism for this — confirmed with the user).
- **Reason**: Explicit user requirement this session, refined via user Q&A once the XML-specificity of the original ask was clarified as Android-only.
- **Trade-off**: One central file per platform to keep in sync as screens are added, versus scattering literals inline — accepted for discoverability and to prevent typo'd/duplicated test-tag strings across screens.
- **Scope**: Governs `.specs/features/mobile-app`'s future Tasks/Execute pass.
- **Date**: 2026-09-16
- **Status**: active

### AD-016
- **Decision**: The mobile app's application identifier is `br.com.qualorock` on both platforms — Android `applicationId` in `androidApp/build.gradle.kts` and the iOS bundle identifier in the Xcode project, confirmed via user Q&A to apply to both rather than Android only.
- **Reason**: Explicit user requirement this session.
- **Trade-off**: None — a fixed identifier decision with no competing alternative raised.
- **Scope**: Governs `.specs/features/mobile-app`'s future Tasks/Execute pass.
- **Date**: 2026-09-16
- **Status**: active

### AD-017
- **Decision**: Structured (JSON) dev/debug-mode logging across all five stacks, with a request-correlation ID threaded through cross-service calls. `api` (Laravel): `APP_DEBUG`/`LOG_LEVEL`/`LOG_CHANNEL` (extending the `.env`/`docker-compose.yml` naming `infrastructure` already established) select a Monolog JSON formatter in debug mode; debug mode additionally logs request/response bodies and the executed SQL query log, redacting fields AD-008's LGPD baseline flags as sensitive (passwords, tokens, PII). Every inbound request gets an `X-Request-Id` (generated at the edge if the client didn't send one), echoed back in the response and attached to every log line for that request, including the Reverb broadcast it triggers, so a developer can trace one user action across the api/Reverb boundary. `website`/`admin-panel`/`landing-page-plans` (React/Vite): a thin logger wrapping `console.*`, gated by `import.meta.env.DEV`, is used instead of raw `console.log` calls. `mobile-app` (KMP): an `expect`/`actual` `Logger` in the shared module, debug-build-only, with a structured `event(name, params)` call in addition to plain string logging — the latter exists specifically so `analytics-tracking` (AD-018) can log outgoing Firebase Analytics events through the same mechanism instead of building a second logger.
- **Reason**: Explicit user requirement this session — debugging a request that spans the api and a Reverb broadcast currently has no way to correlate the two log lines; existing stacks have no debug-mode logging story at all.
- **Trade-off**: JSON-formatted logs are less readable in a raw terminal than Laravel's default line format, and redacting sensitive fields from request/response/SQL logging adds a maintained deny-list that must be kept current as new sensitive fields are added — both accepted for the debugging value of structured, correlated output.
- **Scope**: Governs `infrastructure` (the `.env`/`docker-compose.yml` debug-toggle vars) and every one of `.specs/features/{admin-panel,web-app,landing-page-plans,mobile-app}`'s own `design.md` for its own stack's logger.
- **Date**: 2026-09-16
- **Status**: active

### AD-018
- **Decision**: Extends AD-009's Google Analytics decision with custom GA4 event tracking on all four platform apps (mobile-app, web-app, admin-panel, landing-page-plans) — not just the landing page, which is the only app with a GA integration detailed so far. Mobile-app uses Firebase Analytics (GA4's mobile SDK — `gtag.js` is web-only) as the mobile analytics client; this SDK choice is an **unconfirmed assumption**, flagged in `analytics-tracking/spec.md` for confirmation during that feature's Design phase. Every app's custom events are gated by the same cookie/tracking-consent mechanism AD-008/AD-009 already established for landing-page-plans — this decision does not introduce a second consent mechanism, it extends the existing one to the other three apps. This does not replace GA or add a new first-party/self-hosted event-storage backend; it is GA's own custom-event capability, used more broadly.
- **Reason**: Explicit user requirement this session — clarified during Specify that "custom analytics tracking" means GA with custom events, not a new tracking system, and that all four apps (not just the two consumer-facing ones) are in scope.
- **Trade-off**: Firebase Analytics as the mobile client (vs. building a Ktor client against the raw GA4 Measurement Protocol) means an unconfirmed third-party SDK dependency added to the KMP mobile app now, alongside the web `gtag.js` script — two different vendor SDKs to keep event-schema-consistent across platforms instead of one shared implementation.
- **Scope**: Governs the same four feature units as AD-009 (`.specs/features/{mobile-app,web-app,admin-panel,landing-page-plans}`), plus a reuse dependency on `dev-logging` (AD-017)'s mobile `Logger` for the debug-visibility requirement (mobile-app logs every Firebase Analytics event it sends, in debug builds).
- **Date**: 2026-09-16
- **Status**: active

## Handoff

- **Feature**: Seven feature units now exist: the original four platform features (AD-001) plus `infrastructure`, plus two new cross-cutting units Specified this session — `dev-logging` (AD-017) and `analytics-tracking` (AD-018).
- **Phase / Task**: `infrastructure` is fully Executed and Verified (see its own `validation.md`) — `docker-compose.yml`, all four platform apps' Dockerfiles (`api/`, `website/`, `admin/`, `landingpage/`; `mobile/` submodule not yet cloned), `pgadmin`, `.env.example` templates, `docs/development.md`, `docs/infrastructure/architecture.md`, and a `Makefile` (`up` now builds+boots+seeds+best-effort-launches mobile) are all committed. The four platform features (`admin-panel`, `web-app`, `landing-page-plans`, `mobile-app`) have Specify/Design/Tasks complete but **Execute has not started** for any of them — `api/`, `website/`, `admin/`, `landingpage/` contain only their infra Dockerfile, no real app source yet. `dev-logging` and `analytics-tracking` have **Specify complete only** (`validate_spec.py` exits 0 for both); Design/Tasks/Execute have not started for either.
- **Completed**: Infra Execute (see `infrastructure`'s own Handoff-equivalent: its `validation.md`). This session: recorded AD-017 (structured/correlated dev-debug logging, all five stacks) and AD-018 (GA4 custom-event tracking, all four platform apps, extending AD-009) in the Decisions log above; wrote and validated `.specs/features/dev-logging/spec.md` (15 requirements, `LOG-01..15`) and `.specs/features/analytics-tracking/spec.md` (11 requirements, `ANLY-01..11`) — both Specify-only, no `context.md`/`design.md`/`tasks.md` yet since Design wasn't run this session.
- **In-progress**: None — this session's Specify work for `dev-logging`/`analytics-tracking` is complete and stops there, per the user's explicit request (they asked to "specify," not design/tasks/execute).
- **Next step**: For `dev-logging`/`analytics-tracking`: run Design next (both have real architectural decisions pending — see each spec's Assumptions & Open Questions for the specific unconfirmed items: `dev-logging`'s redacted-field list and body-truncation bound; `analytics-tracking`'s Firebase Analytics SDK choice and starter event taxonomy, both flagged `n` for confirmation). For the four platform features: Execute is still not started — `git init`, real submodule source, and the same DEFERRED-gate discipline used for `infrastructure`'s T1-T4 will be needed once that begins. Before any Execute of `dev-logging`/`analytics-tracking`/the platform features, the open implementation prerequisites already flagged remain unresolved: OAuth app registrations (Instagram/Facebook/Google), a Google Maps API key/billing account, SMTP relay credentials, VPS provisioning details, S3-compatible bucket/provider choice (MinIO is the local-dev stand-in), confirmation of Sanctum as the AD-004 auth implementation, the actual privacy-policy legal text (AD-008), the deletion-retention-window default in `admin-panel/design.md` (30 days, unconfirmed), a Google Analytics property ID (AD-009/AD-018), and a Firebase project (AD-018, pending SDK confirmation).
- **Blockers**: none currently open.
- **Uncommitted files**: `.specs/STATE.md` (this Handoff + AD-017/AD-018), `.specs/features/dev-logging/spec.md` (new), `.specs/features/analytics-tracking/spec.md` (new) — not yet committed as of this Handoff snapshot; commit before ending the session if these should persist in git history the same way `infrastructure`'s work was committed task-by-task.
- **Branch**: `main` (default branch from `git init`; no other branches created yet — `infrastructure`'s 17 commits are the only history).
