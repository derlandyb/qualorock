# QOR design tokens (derived from BootstrapDash "Corona" modern-vertical theme)

Source: https://demo.bootstrapdash.com/corona-tailwind/themes/modern-vertical/index.html
(dashboard shell) and .../pages/forms/basic-form.html (form inputs), verified live via
Playwright MCP `getComputedStyle` calls on 2026-09-16 (see `.playwright-mcp/` session cache for
the raw accessibility-tree captures from that pass).

| Token | Value | Used for |
|---|---|---|
| Sidebar surface | `#191c24` | `AppShell` sidebar background |
| Border | `#2c2e33` | Login input borders |
| Primary | `#0090e7` | Submit button fill |
| Warning | `#ffab00` | Pending-approval banner |
| Danger | `#fc424a` | Rejected-approval banner |
| Canvas | `#000000` | Page background |
| Sidebar expanded width | `244px` | Body wrapper `calc(100% - 244px)` |
| Sidebar collapse transition | `all .25s ease-out` | Sidebar collapse animation |
| Mobile breakpoint | `992px` | Below this, body wrapper is `100%` |
| Banner radius/padding | `6px` / `4px 8px` | Approval banners |
| Input radius | `2px` | Login form inputs |
| Button radius | `6px` | Submit button |
| Success | `#00d25b` | Published event status badge |
| Purple | `#8f5fe8` | Draft event status badge |
| Light gray | `#e4eaec` | Closed event status badge |
| Table header text | `rgb(108, 114, 147)` | Event list table header cells |

These values are mirrored as named constants in `admin/src/domain/constants/adminPanelConstants.ts`
and as Tailwind `@theme` tokens in `admin/src/index.css` — this doc is the source of truth if
either drifts. If the live reference ever needs re-checking, do it manually (e.g. a Playwright
MCP browser pass against the URLs above) and update this table plus both code locations
together. Do not add an automated test that fetches the external site — `admin/e2e/visual/login-shell.spec.ts`
asserts only against admin-panel's own rendered pages, using the values documented here.
