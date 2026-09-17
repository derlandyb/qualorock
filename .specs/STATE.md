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
- **Decision**: Shared technology stack across all four surfaces — Laravel (latest) on PHP 8.4 as the single backend API; PostgreSQL as the database, accessed via a least-privilege application DB user (not superuser); React + Tailwind CSS for the three web surfaces (web-app, admin-panel, landing-page-plans), each its own app rather than one shared codebase; Kotlin Multiplatform for mobile with fully native UI (SwiftUI on iOS, Jetpack Compose on Android); custom-built auth (no third-party IDP) via Laravel Sanctum with two distinct guards/user models (consumer vs organizer); Laravel Reverb (self-hosted WebSockets) for real-time-ish updates; Google Maps Platform for embedded maps/geocoding; Laravel Mail over a generic SMTP relay for transactional email; Docker Compose for local dev (all stack except mobile); a VPS for production; one root git repo with `mobile`, `website`, `backend`, `landingpage`, `admin` as submodules.
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

### AD-019
- **Decision**: Google Analytics 4 "Consent Mode v2" (`gtag('consent', 'default'/'update', {...})`) is the consent mechanism for all four platform apps' GA integration, **superseding** `landing-page-plans/design.md`'s originally-specified mechanism ("GA script tag is conditionally loaded only after a separate cookie-consent banner is accepted" — that file's existing text is not yet amended; this AD records the decision, the file edit is a follow-up). Under Consent Mode v2, `gtag.js` always loads; the cookie-consent banner (still a distinct UI from AD-008's account-data consent checkbox) calls `gtag('consent', 'default', {analytics_storage: 'denied', ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied'})` on page load, then `gtag('consent', 'update', {analytics_storage: 'granted'})` if the user accepts. Since this project has no Google Ads integration, `ad_storage`/`ad_user_data`/`ad_personalization` stay permanently `'denied'` — only `analytics_storage` is ever toggled.
- **Reason**: Explicit user decision this session, made with the trade-off named directly — Google's current (June 2026) guidance recommends Consent Mode v2 over conditional script loading, and the user chose to align with it despite `landing-page-plans` already specifying the older mechanism.
- **Trade-off**: `landing-page-plans/design.md` needs a follow-up amendment to match (not done as part of this decision — a separate, explicit edit to that file); the three `ad_*` consent flags are set up with no corresponding Ads product to use them, which is inert but harmless scaffolding kept for parity with Google's four-flag model rather than a home-grown two-flag variant.
- **Scope**: Governs all of `.specs/features/{mobile-app,web-app,admin-panel,landing-page-plans}`'s GA/analytics-tracking mechanism; supersedes `landing-page-plans/design.md`'s conditional-script-load description specifically.
- **Date**: 2026-09-16
- **Status**: active

### AD-020
- **Decision**: `analytics-tracking`'s two remaining Design-phase unknowns resolved: (1) mobile's Firebase Analytics integration uses Kotlin `expect`/`actual` wrapping the native Android and iOS Firebase Analytics SDKs directly (same pattern as `dev-logging`'s `Logger`, AD-017) — no third-party KMP wrapper library (e.g. Firebase-KMP-Kit, KFire); confirmed there is no official Google-maintained KMP Firebase SDK as of this session. (2) Consent-for-tracking UI is new, real scope for this feature on `web-app`, `admin-panel`, and `mobile-app` (which have no such UI today, only AD-008's separate account-data consent checkbox) — each gets its own cookie-consent banner (web, per-app copy, no shared component library per AD-004) or a one-time in-app tracking-consent prompt (mobile), not an assumed pre-existing prerequisite.
- **Reason**: Explicit user decisions this session, resolving `analytics-tracking/spec.md`'s two `n`-confirmed Assumptions.
- **Trade-off**: expect/actual for Firebase means more boilerplate per platform than a unified wrapper library would give, accepted to avoid a community-maintained (non-Google) dependency. Building three new consent UIs (vs. assuming they exist) meaningfully grows this feature's scope beyond "wire up analytics calls," accepted because AD-018's Scope line already committed to extending the consent mechanism to those apps.
- **Scope**: Governs `.specs/features/analytics-tracking`'s Design/Tasks/Execute.
- **Date**: 2026-09-16
- **Status**: active

### AD-021

- **Decision**: Every admin-panel backend route is namespaced under `/api/admin/v1/...` (e.g. `/api/admin/v1/organizer/login`, `/api/admin/v1/super-admin/organizers`), distinct from the `/api/v1/...` prefix `web-app`/`mobile-app` are expected to use for their own consumer-facing endpoints when their own Execute begins.
- **Reason**: Explicit user instruction during admin-panel Phase 2 Execute, so the organizer/super-admin surface can never be confused with the consumer API at the routing level, independent of the guard-level separation AD-002 already established.
- **Trade-off**: None named — a routing-namespace convention with no competing alternative raised. It does commit `web-app`/`mobile-app` to mirroring the `/api/v1` half of the pattern for consistency, though that isn't enforced until their own Execute.
- **Scope**: Governs `.specs/features/admin-panel`'s route definitions now; sets the expected convention for `.specs/features/{web-app,mobile-app}` once their Execute reaches routing.
- **Date**: 2026-09-16
- **Status**: active

### AD-022

- **Decision**: `admin-panel` (and, by implication, `web-app`/`landing-page-plans` once their own Execute reaches this point) uses Vitest instead of Jest for unit/component tests, with React Testing Library unchanged.
- **Reason**: Jest's CommonJS module system doesn't natively understand Vite's ESM-first output, `import.meta.env`, or `vite.config.ts` path aliases without extra transform/shim packages (`ts-jest`/`babel-jest`, `jest-environment-jsdom`, manual `moduleNameMapper` mirroring every Vite alias, a shim for `import.meta.env`). Vitest is built on Vite, reuses `vite.config.ts` unmodified, and is API-compatible with Jest's `describe`/`it`/`expect`.
- **Trade-off**: Deviates from AD-010's literal wording ("Jest + RTL"). Test syntax and React Testing Library usage are unchanged, so this is a tooling substitution, not a rewrite risk.
- **Scope**: Amends AD-010 for the three React surfaces (`admin-panel`, `web-app`, `landing-page-plans`) only. Backend (Pest/PHPUnit) and mobile (`kotlin.test`/XCTest/Compose) tooling are untouched.
- **Date**: 2026-09-17
- **Status**: active

## Handoff

- **Feature**: Seven feature units exist: the original four platform features (AD-001) plus `infrastructure`, plus two cross-cutting units — `dev-logging` (AD-017) and `analytics-tracking` (AD-018).
- **Phase / Task**: `infrastructure` is fully Executed and Verified. `admin-panel` Execute is underway: Phase 1 (T1-T7), Phase 2 (T8-T10), Phase 3 (T11-T14), Phase 4 (Venue & promoter management, T15-T16), Phase 5 T19 (`EventInfoRequestController`, ADMIN-16), Phase 6 T20 (`PlanPricingController`, ADMIN-20..23), and Phase 7 T21-T22 (`OrganizerDataController`: LGPD export/deletion, ADMIN-24..27) are merged to `qualorock-api`'s `main` (PR #1-#7) and the root repo's `api` submodule pointer matches. Phase 4 shipped `VenueController` (show/update/agenda/history — no create/delete, deliberate scope decision) and `PromoterController` (register/edit/remove + link/unlink, with edits/removals propagating). Phase 5 is **partially done**: T19 is merged; T17 (`EngagementDashboardController`) and T18 (`AudienceInterestController`) remain deliberately deferred — both depend on `event_stats`/`Favorite`/`Friendship`/`EventInterest` tables that `web-app`'s design.md owns and whose Execute hasn't started. Phase 6 is fully done (its only task, T20, is merged). Phase 7 is fully done (T21/T22 merged). Phases 8-15 of `admin-panel/tasks.md` have not started. `web-app`, `landing-page-plans`, `mobile-app` still have Specify/Design/Tasks complete but Execute not started. `dev-logging`/`analytics-tracking` remain Specify-only.
- **Completed**: This session - merged PR #7 (admin-panel T21/T22, `OrganizerDataController`) into `qualorock-api` main via `gh pr merge` (merge commit `17b39fe`). `ExportOrganizerData`/`DeleteOrganizerAccount`/`PurgeRetainedOrganizerPersonalData` use-cases, `GenerateOrganizerDataExportJob` (queued export to S3), `HardDeleteRetainedOrganizersCommand` (30-day retention purge), `hidden_at` cascade-hide on venue/event/promoter, and Super Admin override via `SuperAdminOrganizerPolicy` were implemented and independently Verified (PASS: 4/4 ACs, 3/3 discrimination-sensor mutations killed) before merge. A same-session self-caught IDOR (predictable export id + unsigned URL) was fixed pre-merge. A post-merge independent code-review pass (dispatched per this session's request) found 7 more issues the Verifier's spec-anchored check and sensor didn't catch, since the tests it ran asserted internal DB state rather than the spec's user-visible outcomes: (1) the retention-purge command was registered in `bootstrap/app.php`'s schedule but nothing in the Docker Compose stack ever ran `schedule:work`, so it never actually fired; (2) `GenerateOrganizerDataExportJob` ignored `Storage::put()`'s return value, so a failed S3 write (disk configured with `'throw' => false`) silently left the request `Ready` with a URL to a nonexistent object; (3) there was no endpoint to ever retrieve a completed export — only `POST data-export` existed; (4) `hidden_at` was written but had no reader anywhere in this repo; (5) the retention purge scrubbed the `organizers` row but left the S3 export archive (same PII) orphaned forever; (6) `DeleteOrganizerAccount`'s cascade wasn't transactional, so a partial failure could leave an organizer soft-deleted (and thus locked out) with venue/events left unhidden; (7) the IDOR fix had no regression test pinning it. Fixed pre-existing-in-main (findings 1-3,5-7): added a `scheduler` service (`php artisan schedule:work`) to root `docker-compose.yml`; the export job now throws on a failed write; added `GET organizer/data-export/{id}` (self-scoped, 404 on mismatch) and switched `DataExportRequest` to store an S3 key (`download_path`, new migration) with the signed URL minted fresh on read instead of persisted with a stale TTL; the retention purge now deletes each organizer's export archives; `DeleteOrganizerAccount`'s cascade now runs in `DB::transaction`; added regression tests for the unguessable-key format and the upload-failure path. Finding 4 (`hidden_at` unread) was deliberately left unfixed — no consumer-facing listing endpoint exists in this repo to filter on it, consistent with spec.md's own Out-of-Scope table (web-app/mobile-app own consumer listings); building one here would be new scope, not a bug fix. Also flagged but left as an open product question: venue `contact_info` and promoter `name/phone/email` aren't scrubbed by the retention purge (only the organizer row + export archive are) — whether LGPD erasure should extend that far wasn't decided. Also DRY'd `SuperAdminOrganizerPolicy`'s four duplicated `instanceof SuperAdmin` checks into a private helper (no behavior change), per explicit user request. Full suite 78/78 passing, Pint clean, before these fixes were merged via 3 follow-up commits on the PR branch (`4c13845`, `0267bd1`, `788cf50`) prior to merge.
- **In-progress**: none for T21/T22 — merged, submodule-bumped, and closed out.
- **Next step**: Commit this Handoff update plus the bumped `api` submodule pointer to the root repo. Phase 8 of `admin-panel/tasks.md` has not started. T17/T18 stay blocked until `web-app`'s Execute reaches its data-model tasks (or the user decides to build the shared tables under a different feature now). Unresolved items carried forward: (a) CI test job still has no coverage `--min` threshold; (b) `EloquentOrganizerRepository::update()`'s generic attributes-array signature remains a latent mass-assignment/IDOR risk if a future endpoint forwards unfiltered user input through it; (c) candidate lesson `L-004` (duplicate/copy field-equivalence tests should enumerate every field the use-case's constructor call actually assigns) - not exercised this session either; (d) `spec.md`'s traceability table for ADMIN-01..15/17..19 remains stale (pre-existing gap, not touched this session; ADMIN-24..27 rows are current); (e) new from this session — whether the retention purge should also scrub venue `contact_info` and promoter contact fields (not just the organizer row and export archive) is an open product decision, not yet made; (f) new candidate lesson: a Verifier's discrimination sensor and spec-anchored check can both pass while a feature is non-functional end-to-end if the task's own `Done when` criteria were written against internal state (a DB column, a job status) instead of the spec's user-visible outcome (e.g., T21/T22 passed despite no endpoint existing to retrieve an export) — worth considering whether `tasks.md`'s task-writing guidance should require at least one Done-when bullet per task to name an externally-observable effect, not just an internal one.
- **Blockers**: T17/T18 blocked on `web-app` Execute reaching its `event_stats`/`Favorite`/`Friendship`/`EventInterest` data model (see Phase/Task above). Not a blocker on T21/T22, which are done. No blockers on Phase 8+.
- **Uncommitted files**: root repo has the bumped `api` submodule pointer plus this Handoff update, both pending commit. The `api` submodule's working tree is clean on `main`.
- **Branch**: root repo `main`. `api` submodule is on `main`, up to date with `qualorock-api`'s `main` (includes the Phase 7 T21/T22 merge, merge commit `17b39fe`).
