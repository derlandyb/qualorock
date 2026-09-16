<a name="top"></a>
[![Backend](https://img.shields.io/badge/backend-Laravel%20%2F%20PHP%208.4-FF2D20)](https://laravel.com/)
[![Database](https://img.shields.io/badge/database-PostgreSQL-336791)](https://www.postgresql.org/)
[![Web](https://img.shields.io/badge/web-React%20%2B%20Tailwind-38BDF8)](https://react.dev/)
[![Mobile](https://img.shields.io/badge/mobile-Kotlin%20Multiplatform-7F52FF)](https://kotlinlang.org/lp/multiplatform/)
[![License](https://img.shields.io/badge/license-TBD-lightgrey)](#-license)
[![Status](https://img.shields.io/badge/status-pre--implementation-lightgrey)](#-project-status)

**QOR Novo (Qual o Rock)** — an event-discovery and organizer platform: one shared Laravel API behind four independent apps (consumer web, consumer mobile, organizer/venue admin panel, plans landing page).

## Table of Contents
- [About](#-about)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Repository Structure](#-repository-structure)
- [Getting Started](#-getting-started)
- [Documentation](#-documentation)
- [Project Status](#-project-status)
- [Contributing](#-contributing)
- [License](#-license)

## 🚀 About

Qual o Rock lets organizers publish and manage events, venues, and promoters — subject to plan-tier limits (a free Basic tier capped at 4 published events/month, an unlimited Plus tier) and Super Admin approval before any organizer account can use the platform. Consumers discover events, follow venues and friends, favorite and share events, and get notified about the ones they care about.

Four independent apps sit on top of one shared backend rather than one another:

- **web-app** — the consumer-facing web app.
- **mobile-app** — the consumer-facing mobile app (Kotlin Multiplatform, native iOS/Android UI).
- **admin-panel** — the organizer/venue console, plus Super Admin approval and plan-pricing management.
- **landing-page-plans** — the public marketing site and organizer signup/plan-comparison flow.

## 🏗 Architecture

- **Two distinct auth systems**: organizers and consumers are different personas with different needs (organizer accounts require Super Admin approval before first use), so they're two separate Sanctum guards/user models rather than one account with a role flag.
- **Clean Architecture everywhere**: every app — backend and each React SPA alike — is split into `Domain` (framework-agnostic entities + contracts), `Application` (use-cases/services/policies), `Infrastructure` (concrete implementations), and `Presentation` (controllers/pages/components), one direction of dependency. Mobile keeps Domain/Application/Infrastructure(data) in its Kotlin Multiplatform shared module; native SwiftUI/Compose UI is Presentation-only.
- **LGPD and security baseline, applied to every feature**: explicit timestamped consent capture at signup, self-service data export and deletion for both consumer and organizer accounts, all database access through Eloquent/the query builder (no raw SQL), Policy/Gate-based authorization on every endpoint touching a user- or organizer-owned resource (IDOR protection), and HttpOnly+Secure+SameSite session cookies on web (not localStorage).

The full architecture-decision record — every explicit choice made for this platform, with its reasoning and trade-offs — lives in [`.specs/STATE.md`](.specs/STATE.md).

## 🧱 Tech Stack

| Layer | Choice |
| --- | --- |
| Backend API | Laravel (latest), PHP 8.4 |
| Database | PostgreSQL, least-privilege application user |
| Auth | Laravel Sanctum, dual guards (consumer / organizer) |
| Realtime | Laravel Reverb (self-hosted WebSockets) |
| Web (×3 apps) | React + Tailwind CSS, one independent app per surface |
| Mobile | Kotlin Multiplatform + native SwiftUI (iOS) / Jetpack Compose (Android) |
| Maps | Google Maps Platform |
| Email | Laravel Mail over a generic SMTP relay |
| Object storage | S3-compatible via Flysystem (MinIO locally) |
| Local dev | Docker Compose (every stack except mobile-app, which runs on the host) |

## 📁 Repository Structure

```
.
├── api/             # Laravel backend (git submodule → qualorock-api)
├── admin/           # Organizer/venue admin panel (React)
├── website/         # Consumer web app (React)
├── landingpage/      # Public landing page + organizer signup (React)
├── mobile/          # Consumer mobile app (Kotlin Multiplatform) — not yet cloned
├── .specs/          # Spec-driven planning: requirements, architecture, task breakdowns
├── docs/            # Per-stack architecture docs + local dev guide
├── docker-compose.yml
└── Makefile
```

`admin/`, `website/`, and `landingpage/` are still plain directories today; `api/` is the first to be split into its own repository and wired in as a git submodule, with the others following the same pattern later.

## ⚡ Getting Started

```shell
git clone --recurse-submodules git@github.com:derlandyb/qualorock.git
cd qualorock
make up
```

`make up` builds every containerized service, boots the default profile (backend, Reverb, Postgres, MinIO, Mailhog, pgAdmin, web-app, admin-panel, landing-page-plans), seeds the database, then best-effort builds/launches the mobile apps on the host. See [`docs/development.md`](docs/development.md) for the full walkthrough, every other `make` target (`down`, `logs`, `ps`, `seed`, `test-e2e`), and the mobile-on-host setup.

## 📚 Documentation

- [`.specs/STATE.md`](.specs/STATE.md) — every cross-feature architecture decision, with reasoning and trade-offs.
- [`.specs/features/`](.specs/features/) — per-feature requirements (EARS notation), architecture design, and atomic task breakdowns.
- [`docs/development.md`](docs/development.md) — local dev setup.
- [`docs/infrastructure/architecture.md`](docs/infrastructure/architecture.md) — infrastructure layout.
- Each stack's own `docs/<stack>/architecture.md` (added alongside that stack's first implementation tasks) documents its Clean Architecture layering and conventions in full — code itself carries no task-referencing comments by design.

## 📍 Project Status

- **infrastructure** — Executed and verified: Docker Compose, every app's Dockerfile, local-dev docs, and the `Makefile` are in place.
- **admin-panel**, **web-app**, **landing-page-plans**, **mobile-app** — fully specified, designed, and broken into tasks; implementation (Execute) is starting now, beginning with admin-panel's data models and migrations.
- **dev-logging**, **analytics-tracking** — requirements specified; design and implementation not yet started.

## 🤝 Contributing

This project follows Conventional Commits (one commit per task) and Conventional branch naming, with one branch per phase/milestone off `main` — not one branch per task. Once a milestone branch's work is complete, a stack-specific code-review pass reviews its PR and leaves comments; those are addressed with fix commits before the PR is updated. CI (GitHub Actions) enforces per-stack lint and the full test suite at ≥80% coverage as a required check. A PR only merges once CI is fully green after the review round.

## 📃 License

TBD — no license has been chosen for this project yet.

[Back to top](#top)
