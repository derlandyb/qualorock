.PHONY: up down logs ps build test-e2e seed mobile-android mobile-ios

# Build every containerized service's image, bring up every default-profile
# service (backend, reverb, postgres, minio, mailhog, pgadmin, web-app,
# admin-panel, landing-page-plans), seed the database, then build/launch the
# mobile apps on the host. Never starts playwright - that lives under the
# "test" profile only. The mobile-android/mobile-ios steps are best-effort
# ("-" prefix): a missing host toolchain (Xcode, Android SDK) or missing
# mobile/ submodule prints its existing fail-fast error but does not abort
# the rest of `make up`.
up: build
	docker compose up -d --wait
	$(MAKE) seed
	-$(MAKE) mobile-android
	-$(MAKE) mobile-ios

down:
	docker compose down

logs:
	docker compose logs -f

ps:
	docker compose ps

build:
	docker compose build

# The only target that starts Playwright, via its dedicated compose profile.
# Runs each app's Playwright suite (only those with a playwright.config.ts
# today - website/landingpage have none yet, so they're skipped, not
# hardcoded out) against the already-running containers on the qualorock
# network.
#
# The Playwright container's browser runs *inside* the Docker network, so a
# page it loads must reach the backend via the "backend" service hostname,
# not "localhost" (which from that browser's perspective means the
# Playwright container itself). admin-panel's own default VITE_API_URL is
# "localhost:8000" for a host-machine browser (the normal `make up` case),
# so this target restarts admin-panel with ADMIN_PANEL_API_URL pointed at
# the container-network hostname before running the suite against it. The
# backend must also allow that origin via CORS, hence CORS_ALLOWED_ORIGINS
# below - this is the CORRECT config, but as of this writing api's CORS
# middleware (vendor/fruitcake/php-cors via Illuminate\Http\Middleware\
# HandleCors) does not actually reflect config('cors.allowed_origins') at
# request time (confirmed via reflection on the live CorsService instance:
# its $allowedOrigins stays empty regardless of this env var), so any
# admin-panel test that makes a real un-mocked browser-side cross-origin
# fetch will still fail here specifically, even though the same test
# passes correctly against a host-machine dev server talking to the same
# backend on localhost. This is a pre-existing bug in the api submodule,
# out of scope for admin-panel's own phases to fix - tracked separately.
test-e2e:
	ADMIN_PANEL_API_URL=http://backend:8000 \
	CORS_ALLOWED_ORIGINS=http://localhost:5174,http://admin-panel:5174 \
	docker compose up -d --wait admin-panel backend
	docker compose --profile test run --rm playwright sh -c '\
		set -e; \
		for app in website admin landingpage; do \
			if [ -f /e2e/$$app/playwright.config.ts ]; then \
				echo "==> running Playwright suite: $$app"; \
				cd /e2e/$$app && npm ci && npx playwright test; \
				cd /e2e; \
			fi; \
		done'

# Runs Laravel's DatabaseSeeder (AdminPanelSeeder, then WebAppSeeder) against
# the running backend service.
seed:
	docker compose exec backend php artisan db:seed

# mobile-app (submodule dir: mobile/) runs on the host, not in Docker (see
# docs/development.md). These targets fail fast with a clear message when
# the host prerequisite is missing, instead of hanging or crashing unclearly.

mobile-android:
	@if [ ! -d mobile ]; then \
		echo "error: mobile/ submodule not found - clone/init it before running make mobile-android" >&2; \
		exit 1; \
	fi
	@if ! command -v adb >/dev/null 2>&1 && [ -z "$$ANDROID_HOME" ] && [ -z "$$ANDROID_SDK_ROOT" ]; then \
		echo "error: Android SDK not found (adb not on PATH, ANDROID_HOME/ANDROID_SDK_ROOT unset) - install Android Studio and its SDK first" >&2; \
		exit 1; \
	fi
	@if [ ! -x mobile/gradlew ]; then \
		echo "error: mobile/gradlew not found - the mobile/ submodule has no Gradle project yet" >&2; \
		exit 1; \
	fi
	cd mobile && ./gradlew installDebug

mobile-ios:
	@if [ "$$(uname -s)" != "Darwin" ]; then \
		echo "error: mobile-ios requires macOS (Xcode is not available on this host)" >&2; \
		exit 1; \
	fi
	@if ! command -v xcodebuild >/dev/null 2>&1; then \
		echo "error: xcodebuild not found - install Xcode and its command line tools first" >&2; \
		exit 1; \
	fi
	@if [ ! -d mobile ]; then \
		echo "error: mobile/ submodule not found - clone/init it before running make mobile-ios" >&2; \
		exit 1; \
	fi
	cd mobile && xcodebuild -scheme mobile -destination 'platform=iOS Simulator,name=iPhone 15' build
