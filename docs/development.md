# Local Development Setup

QualORock's local dev environment splits into two halves: everything that runs in Docker, and mobile-app, which runs on the host.

## Host vs. container split

**Every stack runs in Docker except mobile-app.** Mobile-app is the one stack that runs on your host machine, not in a container, because its iOS/Android toolchains (Xcode, Android Studio, JVM/Gradle for the shared Kotlin Multiplatform module) don't containerize for iOS builds. Concretely:

- Containerized (via `docker compose`): `backend`, `reverb`, `postgres`, `minio`, `mailhog`, `pgadmin`, `web-app`, `admin-panel`, `landing-page-plans`.
- Host-only: `mobile-app` (submodule directory `mobile/`) - build and run it directly with Xcode (iOS/SwiftUI) or Android Studio (Compose), not Docker.

## One-time host prerequisites for mobile-app

Before working on `mobile/`, install on your host:

- **Xcode** (for the iOS/SwiftUI target)
- **Android Studio** (for the Android/Compose target)
- **JDK + Gradle** (for the shared Kotlin Multiplatform module, used by both targets)

Once these are installed, `make mobile-android` and `make mobile-ios` (see the root `Makefile`) shell out to the host's Gradle wrapper and `xcodebuild`/`xcrun simctl` respectively against the `mobile/` submodule - they fail fast with a clear error if the required toolchain isn't present.

## Starting everything else

A single command brings up every containerized service:

```
docker compose up -d --wait
```

(equivalently, `make up`). This starts `backend`, `reverb`, `postgres`, `minio`, `mailhog`, `pgadmin`, `web-app`, `admin-panel`, and `landing-page-plans` - no manual PHP/Postgres/Node setup required on the host for any of those.
