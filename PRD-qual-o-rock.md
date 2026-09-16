# PRD — Qual o Rock?

**Source:** Miro mindmap "Qual o Rock? Plataforma capixaba de eventos" (`https://miro.com/app/board/uXjVHCBsiOM=/`)
**Design artifacts:** Stitch project "Qual o rock - novo design" (`projects/4886677589059011690`), design system "Qual o Rock? — Grande Vitória Nightlife Exploration" (`assets/819289b0a37b4e8c84581752db2fecd4`)
**Status:** Draft, derived directly from the mindmap. Every requirement below traces to a mindmap node — nothing here is invented.

## 1. Overview

Qual o Rock? is a music-events discovery platform for Grande Vitória, Espírito Santo, Brazil. It connects three groups:

- **Attendees** — discover live music events nearby, save favorites, follow friends' interests, and reach ticket purchase through an external link.
- **Organizers / venues** — register and manage their own events, track engagement, and run their venue's public presence.
- **Promoters** — contacts linked to events by an organizer (not full account holders in the mindmap).

## 2. Personas

| Persona | Goal |
|---|---|
| End user (event-goer) | Find nearby music events matching their taste, track friends' activity, get to tickets fast |
| Admin / Organizer (venue or event admin) | Publish and manage events, understand audience engagement, manage promoters |
| Promoter | Contact record linked to events by an organizer; has no login/screens of its own in the mindmap |

## 3. Scope

- **Mobile app** (consumer) — event discovery, account, social, notifications.
- **Web admin panel** (organizer/venue console) — event management, analytics, promoter management.
- Shared concepts: events, favorites, promoters, friends.
- **Out of scope / not in the mindmap:** in-app ticket purchase or payment processing (tickets route through an external link/platform), promoter self-service accounts, push/email delivery infrastructure itself (only user-facing preference toggles are specified).

## 4. Functional Requirements

Grouped to mirror the mindmap's three frames. IDs are traceable; "Design status" cites the Stitch screen that implements each requirement, or flags it as pending.

### 4.1 Mobile App — Event Discovery (FR-MOB)

| ID | Requirement | Design status |
|---|---|---|
| FR-MOB-01 | WHEN a user opens the events screen, THE SYSTEM SHALL display a listing of events ordered by date, nearest first | Listagem de Eventos (Mobile/Desktop) |
| FR-MOB-02 | THE SYSTEM SHALL update the event listing in real time as events change | Listagem de Eventos (Mobile/Desktop) |
| FR-MOB-03 | THE SYSTEM SHALL paginate or infinite-scroll the event listing | Listagem de Eventos (Mobile/Desktop) |
| FR-MOB-04 | THE SYSTEM SHALL display each event as a card showing featured image, date/time, short description, location, and a free/paid indicator | Listagem de Eventos (Mobile/Desktop) |
| FR-MOB-05 | WHEN a user taps the favorite action on an event card, THE SYSTEM SHALL add the event to the user's favorited events | Listagem de Eventos + Eventos Favoritados |
| FR-MOB-06 | WHEN a user taps an event card, THE SYSTEM SHALL navigate to the event details page | Listagem de Eventos → Detalhes do Evento |
| FR-MOB-07 | THE SYSTEM SHALL show full event details: name, full description, date, time, location, full address, featured image, and music category | Detalhes do Evento (Mobile/Desktop) |
| FR-MOB-08 | THE SYSTEM SHALL provide a button linking to an external platform for ticket purchase | Detalhes do Evento (Mobile/Desktop) |
| FR-MOB-09 | THE SYSTEM SHALL display a free/paid indicator and a favorite button on the event details page | Detalhes do Evento (Mobile/Desktop) |
| FR-MOB-10 | THE SYSTEM SHALL let a user see which friends are interested in an event | Detalhes do Evento (Mobile/Desktop) |
| FR-MOB-11 | THE SYSTEM SHALL let a user share an event | Detalhes do Evento (Mobile/Desktop) |
| FR-MOB-12 | THE SYSTEM SHALL show the event location on a map | **Gap** — no dedicated map screen in the 9 pairs; likely an embedded element within Detalhes do Evento, not confirmed as a distinct design |
| FR-MOB-13 | THE SYSTEM SHALL show accessibility information and event rules/observations | Detalhes do Evento (Mobile/Desktop) |
| FR-MOB-14 | THE SYSTEM SHALL let a user view the list of promoters for an event, each with name, phone, email, Instagram, TikTok, and a direct-contact action (WhatsApp/email) | Detalhes do Evento (Mobile/Desktop) |

### 4.2 Account, Social & Notifications (FR-ACC)

| ID | Requirement | Design status |
|---|---|---|
| FR-ACC-01 | THE SYSTEM SHALL support login via Instagram, Facebook, or Google | Entrar (Mobile/Desktop) |
| FR-ACC-02 | THE SYSTEM SHALL support login via email and password | Entrar (Mobile/Desktop) |
| FR-ACC-03 | THE SYSTEM SHALL support new-user signup | Cadastro de Novo Usuário (Mobile/Desktop) |
| FR-ACC-04 | THE SYSTEM SHALL support password recovery | Recuperação de Senha (Mobile/Desktop) |
| FR-ACC-05 | THE SYSTEM SHALL validate new accounts | Validação de Conta (Mobile/Desktop) |
| FR-ACC-06 | THE SYSTEM SHALL manage user sessions | Entrar (implicit in login flow) |
| FR-ACC-07 | THE SYSTEM SHALL let a user edit registration data: phone, address, photo, username | Perfil do Usuário (Mobile/Desktop) |
| FR-ACC-08 | THE SYSTEM SHALL use the user's address to search nearby events, supporting a primary address, manual updates, and location permission | Perfil do Usuário (Mobile/Desktop) |
| FR-ACC-09 | THE SYSTEM SHALL let a user view and remove favorited events and access their details from that list | Eventos Favoritados (Mobile/Desktop) |
| FR-ACC-10 | THE SYSTEM SHALL let a user set preferences: favorite event types, search radius, notification preferences | Perfil do Usuário (Mobile/Desktop) |
| FR-ACC-11 | THE SYSTEM SHALL notify a user of five categories: urgent alerts (e.g. event time changes), ticket-batch/pricing alerts, friend/social activity (e.g. a friend confirms attendance), new-event discovery in their region, and event reminders (countdown to a saved event) | Notificações (Mobile) |
| FR-ACC-12 | THE SYSTEM SHALL let a user filter notifications (All / Unread / Urgent / Batches & Shows / Friends), take a per-notification action (view details, mute this alert, buy ticket, see who's going, access ticket, delete), bulk-manage the list (edit, clear all, undo a delete), and toggle a push channel with a "favorited shows and friends only" filter | Notificações (Mobile). **Gap** — no desktop/web equivalent screen exists yet; tracked as WEB-NOTIF-GAP in the web-app spec |
| FR-ACC-13 | THE SYSTEM SHALL let a user manage a friends list: view, add, remove, and receive suggestions | Feed Social e Conexões de Amigos (Mobile/Desktop) |
| FR-ACC-14 | THE SYSTEM SHALL let a user see friends' interests, common events, and a social activity feed | Feed Social e Conexões de Amigos (Mobile/Desktop) |
| FR-ACC-15 | THE SYSTEM SHALL let a user share an event with friends | Feed Social e Conexões de Amigos / Detalhes do Evento |
| FR-ACC-16 | THE SYSTEM SHALL surface events popular among friends and which friends favorited/are interested in an event | Feed Social e Conexões de Amigos |

**Non-functional (from "Experiência Do Usuário"):**

| ID | Requirement |
|---|---|
| NFR-01 | THE SYSTEM SHALL provide an intuitive, responsive interface across device sizes |
| NFR-02 | THE SYSTEM SHALL support a dark mode (the current design system is dark-first) |
| NFR-03 | THE SYSTEM SHALL be accessible: screen-reader support, adequate contrast, adjustable font size |
| NFR-04 | THE SYSTEM SHALL be fast and performant |

### 4.3 Admin Panel — Organizer/Venue Console (FR-ADM)

| ID | Requirement | Design status |
|---|---|---|
| FR-ADM-01 | THE SYSTEM SHALL let an admin register an event with: featured image, date/time, description, location/address, external ticket link, free/paid type, music category, capacity, age range, additional info | *Pending — see §5* |
| FR-ADM-02 | THE SYSTEM SHALL let an admin edit, delete, and duplicate their own events | *Pending* |
| FR-ADM-03 | THE SYSTEM SHALL let an admin change an event's status: draft, published, cancelled, closed | *Pending* |
| FR-ADM-04 | THE SYSTEM SHALL let an admin view statistics per event | *Pending* |
| FR-ADM-05 | THE SYSTEM SHALL show a dashboard with: count of interested users, views, favorites, external link clicks, and performance per event | *Pending* |
| FR-ADM-06 | THE SYSTEM SHALL let an admin manage venue ("Casa de Shows") data: name, description, address, contact, image | *Pending* |
| FR-ADM-07 | THE SYSTEM SHALL show the venue's event agenda and event history | *Pending* |
| FR-ADM-08 | THE SYSTEM SHALL let an admin track user interest, view mutual friends attending an event, and respond to info/update requests | *Pending* |
| FR-ADM-09 | THE SYSTEM SHALL let an admin register a promoter: name, contact phone, email, Instagram link, TikTok link | *Pending* |
| FR-ADM-10 | THE SYSTEM SHALL let an admin link promoters to an event, edit promoter info, remove promoters, and list promoters per event | *Pending* |

## 5. Design Gap — Admin Panel

None of the 18 existing device screens in the Stitch project implement FR-ADM-01 through FR-ADM-10. Six new desktop screens are being generated in the same project/design system to close this gap:

1. Painel Administrador — Dashboard → FR-ADM-04, FR-ADM-05
2. Cadastro de Evento → FR-ADM-01
3. Gerenciar Eventos → FR-ADM-02, FR-ADM-03, FR-ADM-04
4. Gestão da Casa de Shows → FR-ADM-06, FR-ADM-07
5. Relacionamento Com Público → FR-ADM-08
6. Gerenciar Promoters → FR-ADM-09, FR-ADM-10

## 6. Other Open Gaps (not addressed by this pass)

- **Desktop/web notifications screen** (FR-ACC-12) — a mobile Notificações screen now exists (see §4.2); no desktop/web equivalent has been designed yet.
- **Map view** (FR-MOB-12) — referenced in the mindmap as part of event details; not confirmed as its own screen.

## 7. Assumptions

- Ticket purchase is entirely external (a link out), per the mindmap's "Link Externo Para Ingressos" / "Plataforma Externa" nodes — no in-app checkout is in scope.
- Promoters are managed records, not account holders — they have no login or self-service screens in the mindmap.
- The admin console is desktop-first, consistent with the existing project's screen pairing pattern for every other section (mobile app + desktop companion), but the mindmap itself does not specify device for the Admin Panel frame.
- **Mobile and Web are tracked as two independent specs** (`.specs/features/mobile-app`, `.specs/features/web-app`) rather than one shared "Mobile/Desktop" requirement set, even though their functional requirements largely mirror each other — each gets its own requirement IDs so a platform-specific gap (e.g. the missing web notifications screen) doesn't block or get silently inherited by the other.

## 8. Platform Plans & Landing Page (new scope, not in the original mindmap)

Added during the 2026-09-15 Specify session, at the user's direction — not traceable to the Miro mindmap like §4's requirements, and not yet represented by any Stitch screen.

- A public **landing page** markets the platform to organizers/venues and shows **pricing/plan tiers** (a comparison of what each tier includes).
- The landing page ends in a **self-serve signup** that creates an organizer account on the **free plan** by default.
- A new organizer account is **not usable immediately** — it requires **super-admin approval** before the organizer can log in and manage events. This introduces a fourth persona, **Super Admin** (platform operator, not a venue/organizer), who reviews and approves/rejects pending organizer signups.
- Organizer accounts for the admin panel use their **own, separate login/signup** — distinct from the consumer app's social/email login (FR-ACC-01/02).
- Open for a future Discuss pass: how paid tiers are billed (the PRD's existing pattern routes money-movement through an external link, as with ticket purchase — likely applicable here too, but not decided), the exact tier names/pricing/feature breakdown, and what happens on rejection (notification path back to the organizer).
- Tracked in `.specs/features/landing-page-plans/spec.md`; the Super Admin approval action itself is tracked in `.specs/features/admin-panel/spec.md`.
