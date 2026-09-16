# LESSONS - auto-maintained by scripts/lessons.py

> Machine-owned. Do NOT hand-edit. Changes are overwritten on the next `lessons.py` write.
> Canonical state lives in `.specs/lessons.json`. Edit lessons only via the script.
> promote_threshold=2 distinct features · window_days=45 · quarantine_threshold=2

## Confirmed (load these at Specify/Design)

Corroborated across multiple features. Safe to apply as guidance.

_none_

## Candidates (under observation - do NOT load as guidance yet)

Seen once or not yet corroborated. Tracked, not trusted.

### L-001 - docker compose config -q does not validate depends_on targets or host-port collisions - do not rely on it alone to catch those regressions in compose files
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `infra` · harmful: 0
- features: infrastructure
- evidence: docker-compose.yml:155-156 (mutation 1) (infra)
- last seen: 2026-09-16T13:56:26Z

### L-002 - Makefile fail-fast guards (e.g. mobile-android/mobile-ios) have no automated exit-code assertion in the Gate Check Commands table - a silent no-op regression would only be caught by manual inspection
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `infra` · harmful: 0
- features: infrastructure
- evidence: Makefile:34-47 (mutation 4) (infra)
- last seen: 2026-09-16T13:56:29Z

## Quarantined (failed when applied - ignore)

A confirmed lesson that recurred alongside failure. Kept for the maintainer to review.

_none_
