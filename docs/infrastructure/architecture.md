# Infrastructure Architecture

Reference for the QualORock local dev environment: every `docker-compose.yml`
service, every root `Makefile` target, the host-vs-container split, and the
Playwright test-only profile. Restates `docs/development.md` in the
per-stack documentation location used by every other feature (AD-014).

## Compose services

All services run under the `qualorock` Docker network. Every stack runs in
Docker except `mobile-app` (see "Host vs. container split" below).

| Service | Image / build context | Purpose |
| --- | --- | --- |
| `backend` | `./api` (Laravel/PHP 8.4) | The API: serves HTTP requests via `php artisan serve`. |
| `reverb` | `./api` (same image as `backend`) | Laravel Reverb websocket process, run via `php artisan reverb:start`, for realtime features. |
| `postgres` | `postgres:16-alpine` | Primary relational database for the backend. Has a healthcheck (`pg_isready`) other services key off. |
| `minio` | `minio/minio:latest` | S3-compatible object storage for file uploads, used by the backend via the `AWS_*` env vars. |
| `mailhog` | `mailhog/mailhog:latest` | Local mail catcher - the backend sends mail to it (SMTP on 1025) and developers view it via its web UI (8025). |
| `web-app` | `./website` (React/Node dev server) | The consumer-facing web app's Vite dev server. |
| `admin-panel` | `./admin` (React/Node dev server) | The Organizer/Super Admin panel's Vite dev server. |
| `landing-page-plans` | `./landingpage` (React/Node dev server) | The landing-page-plans marketing/plans site's dev server. |
| `pgadmin` | `dpage/pgadmin4:latest` | Web-based Postgres admin UI for inspecting/querying `postgres` during development. |
| `playwright` | `mcr.microsoft.com/playwright:latest` | End-to-end test runner. Test-only - see below. |

## Makefile targets

| Target | What it does |
| --- | --- |
| `up` | `docker compose up -d --wait` - brings up every default-profile service (`backend`, `reverb`, `postgres`, `minio`, `mailhog`, `pgadmin`, `web-app`, `admin-panel`, `landing-page-plans`) in the background, waiting for healthchecks. Never starts `playwright`. |
| `down` | `docker compose down` - stops and removes the stack. |
| `logs` | `docker compose logs -f` - tails logs for all running services. |
| `ps` | `docker compose ps` - lists container status. |
| `build` | `docker compose build` - (re)builds all service images. |
| `test-e2e` | `docker compose --profile test run --rm playwright` - the only target that starts Playwright, via its dedicated compose profile. |
| `seed` | `docker compose exec backend php artisan db:seed` - runs Laravel's `DatabaseSeeder` (`AdminPanelSeeder` then `WebAppSeeder`, in FK-safe order) against the running `backend` service. |
| `mobile-android` | Fails fast with a clear error if the `mobile/` submodule, an Android SDK (`adb`/`ANDROID_HOME`/`ANDROID_SDK_ROOT`), or `mobile/gradlew` aren't present; otherwise runs `./gradlew installDebug` from `mobile/` on the host. |
| `mobile-ios` | Fails fast with a clear error if not on macOS, `xcodebuild` isn't installed, or the `mobile/` submodule is missing; otherwise runs `xcodebuild -scheme mobile -destination 'platform=iOS Simulator,name=iPhone 15' build` from `mobile/` on the host. |

## Host vs. container split

Every stack runs in Docker except `mobile-app`. Its submodule directory is
`mobile/`, and it runs directly on the host - not in a container - because
its iOS/Android toolchains (Xcode, Android Studio, JVM/Gradle for the shared
Kotlin Multiplatform module) don't containerize for iOS builds. `mobile/`
needs Xcode, Android Studio, and a JDK + Gradle installed on the host before
`make mobile-android`/`make mobile-ios` will do real work; both targets
detect a missing prerequisite and fail with a clear message rather than
hanging or crashing unclearly.

Everything else - `backend`, `reverb`, `postgres`, `minio`, `mailhog`,
`pgadmin`, `web-app`, `admin-panel`, `landing-page-plans` - comes up with a
single `make up` (`docker compose up -d --wait`), with no manual PHP,
Postgres, or Node setup required on the host for any of those.

## Playwright test-only profile

`playwright` is defined under the compose `profiles: ["test"]` key, so it
never starts with the default `docker compose up` (or `make up`). It only
starts via `docker compose --profile test run --rm playwright`, exposed as
`make test-e2e`. It mounts each frontend's `e2e/` directory
(`./website/e2e`, `./admin/e2e`, `./landingpage/e2e`) and depends on
`web-app`, `admin-panel`, and `landing-page-plans` being up.
