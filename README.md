# Cariño — Flutter app (working name)

A 21+, verified-first dating app: video-first profiles, stated intentions,
mutually-accepted Spark video sessions, in-chat games, and real plans over
endless chat. One Flutter codebase for iOS + Android.

> **The name is a working name.** The founder finalizes it last; every
> user-visible string reads from the single constant
> `AppConfig.appName` in `lib/config/app_config.dart`
> (ASCII contexts — scheme/domains — use `AppConfig.appNameAscii`).
> Renaming the product = editing one line.

**Spec sources (the build contract):**
`~/workspace/your_files/carino-build-blueprint/carino-build-blueprint.xlsx`
(SCREEN MAP / SCREEN DETAIL / CONNECTIONS / DESIGN SYSTEM / ANIMATION &
MOTION / SOUND DESIGN sheets) and
`~/workspace/your_files/lustra-product-bible/lustra-product-bible.pdf` (v1.2).

> **Current build status:** 65 Flutter tests and 32 database authorization
> assertions pass. Android debug APK packaging passes; the app still uses
> demo data and several provider stubs. See [HANDOFF.md](HANDOFF.md) for
> feature status and [DEPLOYMENT.md](DEPLOYMENT.md) for the walkthrough,
> hosting architecture and Android/iOS release requirements.

---

## Run it

```bash
flutter pub get
flutter run            # iOS simulator, Android emulator, or a device
```

Demo path: Welcome → enter a DOB that makes you 21+ → any phone/email →
verification auto-passes (stub) → pick an intention → publish profile →
the five tabs open. "I already have an account" on Welcome jumps straight
to the tabs. All people, matches, chats, and cases are **sample data**
(`lib/data/mock_data.dart`) — never real users.

## Project structure

```
lib/
  main.dart                  App entry + first-run flow (no tabs until verified)
  config/app_config.dart     AppConfig — appName lives HERE, flags, asset paths
  theme/                     Locked palette + Midnight (dark) / Porcelain (light) themes
  models/                    Member, MatchConnection, Moment, Plan, Conversation, games
  data/mock_data.dart        SAMPLE data (clearly marked; production = BackendService)
  services/                  All stubs with INTEGRATION POINT comments:
    auth_service.dart          Supabase Auth (passkey / OTP / email)
    backend_service.dart       Supabase gateway — profiles, matches, chat, cases, vault
    verification_service.dart  Persona-class vendor — 3 layers, in order
    video_service.dart         WebRTC provider (Daily/Agora class) — mutual tokens only
    payments_service.dart      RevenueCat entitlement `plus`
    ai_service.dart            Claude/GPT via our own server — honesty rules in-file
    sound_service.dart         Signature sounds (stubs) + real haptics, mute rules
    remote_config.dart         Server-driven UI config (see REA additions)
  widgets/                   GlassContainer/GlassScaffold, SparkButton, chips,
                             SafetyActions (report tree / block / appeals),
                             MatchCelebration (spark-join), MatchExpiryChip
  screens/
    onboarding/  Welcome (S-001), Age Gate (S-002/B), Auth (S-003),
                 Verification intro (S-004–007), Intentions (S-008),
                 Profile creation — video-first (S-010–014)
    discover/    Discover + Daily Drop + filters (S-015–017), Profile Detail (S-019)
    moments/     Moments feed / create / viewer actions (S-022–024)
    connect/     Connect Hub (S-025), Spark pre-call + live call (S-026–029, S-032),
                 Plan Composer (S-039)
    chats/       Chat List (S-034), Conversation Keep/Vanish (S-035/036/036B),
                 Games — This or That + Two Truths and a Lie (S-030–032B)
    you/         You hub (S-043–047, S-050, S-055), Trust & Safety Centre (S-052),
                 Paywall (S-054)
assets/images/               Approved imagery A1–A3 + logo + app icon
```

Design: **glassmorphism + minimalism**, Gen Z-first. Glass = `BackdropFilter`
blur (σ24) + translucent tint + 1pt hairline border + soft shadow; primary
actions are always SOLID Ember Crimson (#B81735) — glass is for surfaces,
never for the main action. Floating glass bottom nav, 24px card radii,
both themes fully supported (Porcelain is not an inverted Midnight).

## REA pattern additions (2026-11-13)

Folded in from `~/workspace/lustra/rea-patterns.md` (evidence-labelled REA
extraction over the shipped Tinder web client + public competitor/Temu
evidence). The screen set is unchanged; these are states, a service, and
safety structure:

1. **Match expiry + archived matches** (§5.1) — `MatchConnection` carries
   `expiresInLabel` / `archived`; `MatchExpiryChip` renders the honest
   "Expires in Xh" chip (real server clock, no fake countdown, no shame
   copy); the Connect tab shows live matches, an explainer, and a quiet
   **Archived** section. The expiry job itself is server-side
   (BackendService notes; window = `RemoteConfigService.matchExpiryHours`).
   Once a conversation or plan exists, expiry no longer applies.
2. **Server-driven UI config** (§5.5) — `RemoteConfigService`
   (`lib/services/remote_config.dart`): hook/paywall copy, Daily Drop
   composition, match-expiry window, and feature flags can change without
   an app release. Hard limits in code: config can never hide or re-word
   safety surfaces, never introduce fake scarcity, and never carry prices
   (prices come from the store via PaymentsService).
3. **Layered verification, explicit** (§5.4) — `VerificationLayer` enum
   (document → liveness → photoMatch) in `verification_service.dart`, each
   layer tracked in order; the Verified badge is earned only after
   photo-match passes. The S-004 intro screen presents the three layers
   as three named steps (+ badge), and the You → Verification Centre
   lists all three with vendor references.
4. **Structured report tree + appeals** (§5.3) — `SafetyActions.reportTree`
   (category → specific reason → submit; replaces any free-text-only box),
   used by every Report entry (profile, chat, Moments, Spark call, Safety
   Centre). `SafetyActions.showAppealsEntry` is the appeals entry point —
   linked from the safety sheet, the Trust & Safety Centre (S-052), and
   report confirmations; warnings can be acknowledged or appealed
   (the `/v1/case/warnings/acknowledge` pattern). "Your cases" in S-052
   shows report/appeal refs + SLAs (stub data).

Also carried from the same report: read receipts marked as a Plus
entitlement (§5.10, noted in Conversation + RemoteConfig), founding-member
intro pricing with transparent renewal copy on the paywall (§5.8), and
contacts exclusion in the Privacy Centre (§5.9).

## Implemented vs stubbed

**Implemented (navigable, local state):** full onboarding flow incl. 21+
hard block; three-layer verification walk-through (stub outcome); video-first
profile builder with working AI Coach panel (stub responses); Discover swipe
deck with drag physics, coral Like-glow, Pass fade + Undo, intent filters,
Daily Drop with truthful count; spark-join Match celebration overlay;
Moments feed with expiry chips; Connect hub with match expiry/archived
states, Plan Composer with AI draft (member sends), Spark pre-call
(profile-first, both-accept, preview + blur toggle) and mock live call with
in-call Report and post-call private Connect/Pass; chat list; conversations
in Keep + Vanish with mode-switch proposal flow, pinned plan card, AI opener
drafts (tap-to-edit, never auto-sent), playable This or That and Two Truths
and a Lie with both-answer reveal; You hub with Verification/Privacy sheets,
Trust & Safety Centre (report tree, appeals, cases, guides), honest paywall
with restore, delete-account flow.

**Stubbed (marked INTEGRATION POINT in code):** all backend calls (Supabase),
vendor verification SDK, WebRTC media, StoreKit/RevenueCat purchases, AI
model calls, commissioned sound files (haptics are real), push/CallKit,
media capture/upload, moderation pre-screen, remote-config fetch.

## Honest launch checklist (NOT done by this scaffold)

This is the **complete front-end experience — it is not yet a submittable
production app.** Before any store submission:

- [ ] Apple Developer Program + Google Play Console accounts (founder)
- [ ] Live Supabase project: schema, Row Level Security, Realtime, Storage,
      Safety Vault, match-expiry job, config + case-system endpoints
- [ ] Verification vendor contract (Persona/Veriff class) + SDK integration;
      badge issuance server-side only
- [ ] WebRTC provider account + server token minting (mutual-accept only)
- [ ] RevenueCat + store products; final Plus pricing decision
      (blueprint OPEN DECISIONS — $12.99/mo is a hypothesis, not a price)
- [ ] **Staffed 24h human moderation** + report/appeal SLAs staffed for real
      (Apple Guideline 1.2 evidence pack: filtering, flagging, blocking,
      published contact, response times)
- [ ] Legal set: privacy policy, terms, data-retention schedule, age-rating
      questionnaires, App Privacy / Data Safety labels, ATT where applicable
- [ ] Commissioned original sound set (licensing rule — no library rips)
- [ ] Accessibility audit (WCAG AA in BOTH themes; Reduce Motion pass) —
      a launch gate per the blueprint
- [ ] Guideline 4.3 differentiation notes (why this is not "another dating app")
- [ ] `flutter analyze` clean + device QA on real iOS/Android hardware

## Guardrails baked into the code (do not remove)

21+ hard gate before any account · verification layers in order, badge only
after photo-match · no anonymous/random video — mutual accept from full
profiles only · report/block/appeals reachable everywhere a person appears
and never paywalled · screenshots are detected/notified, never promised as
"prevented" · AI drafts only — members send; no fake users, ever · broad
distance bands, never exact location · real counts and real deadlines only.
