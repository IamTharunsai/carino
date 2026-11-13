# Cariño — End-to-End Production Build Report

**Date:** 2026-11-13 · **Codebase:** `~/workspace/carino-flutter/` · **Contract:** Build Blueprint Excel (66 screens / 355 options) + Product Bible v1.2

## 1. Toolchain truth (read this first)

The Flutter toolchain **was installed and verification actually ran** on this VM — nothing in this report is claimed without a tool result behind it:

- **Flutter 3.50.0-stable** (Dart 3.14) installed at `~/workspace/tools/flutter` from the official tarball. (The tar extraction printed ownership warnings — the sandbox cannot chown; the SDK is complete and runs.)
- `flutter pub get` — **succeeded**, 89 dependencies resolved (incl. `supabase_flutter` 2.x).
- `flutter analyze` — **0 errors, 0 warnings, 49 infos**. All 49 infos are one identical deprecation: SDK 3.50 deprecates the umbrella import `package:flutter/material.dart` in favour of `package:material_ui/material_ui.dart` (one per file). **The suggested migration was attempted and is NOT a drop-in replacement on this SDK** — swapping produced 2,829 issues — so it was reverted and is listed as follow-up work (§8). Every other deprecation the analyzer raised was fixed (`withOpacity`→`withValues`, `anonKey`→`publishableKey`, Radio→`RadioGroup`, `activeColor`→`activeThumbColor`, `translate`→`translateByDouble`, const lints).
- `flutter build web` — **succeeded** (full compile + link of all Dart code, ~93–100 s). Platform shells for android/ios/web were generated (`flutter create`) because the scaffold had none.
- `flutter test` — **9/9 tests pass** (invariant tests: 21+ floor, AppConfig single-source, RemoteConfig honesty defaults, mock-mode default, verification layering, match-expiry honesty, intentions).
- **SQL** — migrations parse clean against the real PostgreSQL grammar (pglast/libpg_query): 28 + 72 + 1 statements. They have **not** been executed against a live database — there is no Postgres server on this VM; first execution is `supabase db push` in the hosting phase.
- **Edge Functions** — all 6 pass `deno check` (Deno installed at `~/workspace/tools/deno`).
- **Not verified anywhere:** iOS/Android native builds (no Xcode/Android SDK on this Linux VM), on-device behaviour, and any live service. The app runs in **mock mode by default**; live mode activates only with `--dart-define` keys (§7).

## 2. What was built in the app (63 Dart files, 11,758 lines in `lib/`)

The scaffold that existed (39 files) was audited screen-by-screen against the blueprint; the ~60 gaps found were implemented. Headlines:

- **Onboarding chain completed:** S-003 real OTP states (attempts, lockout, true 30 s resend timer), S-004 consent gate + provider-disclosure slot + alternative route + exit, S-005/S-006 provider-flow screen, S-007 result screen (Passed/Pending/Failed + human appeal + badge explainer), S-008 structure/pace/availability, **S-009 privacy setup step**, **S-009B city waitlist** (RemoteConfig-gated), S-010–S-014 full profile creation (6-slot photo grid, video intro with mandatory captions, voice intro, prompts/languages/lifestyle/boundaries, preview), **S-014B permission primers**. `RootFlow` was extracted to `lib/screens/root_flow.dart` with a **session gate**: signing out anywhere drops the app back to Welcome.
- **Discover:** full **S-017 Filters screen** (reciprocal, verified-only locked ON, Plus rows→paywall, too-narrow warning), Daily Drop with A2 band + **real countdown to 18:00** + drop-complete state, shared-signal line, prompt-anchored likes, **S-018 Worldwide**, **S-019** full profile (carousel, dimensions/boundaries, per-prompt react, invite to game/Spark, hide).
- **Connect/Spark:** **S-021 Likes You** (real count, blurred free tier), next-window + pending invites, **S-026 lobby** (steps, eligibility, pool opt-in), **S-027 invite with real countdown + report**, **S-028** mic test/camera toggle/permission-denied state, **S-029** in-call PiP/blur/captions/quality/block/games, **S-033 Incoming Call** screen, **S-040 Plan Detail**, **S-041 Plans**, **S-042 Post-Plan Feedback**.
- **Chats/Games:** **S-034** Keep-only search (Vanish never indexed), **S-032B starters**, S-035 media/voice/view-once/reactions/unsend/long-press menu, S-036 per-message expiry + screenshot-detected notice, **S-037 Media Viewer**, **S-038 Conversation Settings**, blocked tombstone; **S-030/S-031** all six games with the both-answer waiting beat; Build Our Date converts to a plan draft.
- **You/Safety:** **S-043** completion meter from real fields, **S-047 Privacy Centre** full screen (blocked list + unblock, per-feature AI consent), **S-048 Likes Manager**, **S-050 Settings** wired (sessions + revoke, passkey, app lock, logout), **S-051 Report Confirmation screen** (server-issued refs via `BackendService.submitReport`), **S-052** live-incident entry + guides with content + warnings row, **S-053 Support** (AI labelled, human always visible), S-054 plan selector (prices from store only), **S-054B** subscription management, **S-055** export-first stepped delete, **S-056 Notifications Centre**, **S-059 state kit** wired into Discover/Moments/Plans/Worldwide/Spark.
- **Services layer wired to Supabase** behind the existing interfaces (`AuthService` OTP, `BackendService` feed/likes/reports/appeals/blocks/remote-config, `VerificationService` session start, `AIService` → `ai-proxy`, `VideoService` mutual-token join, `RemoteConfigService` live fetch with whitelisted keys). Config: `lib/config/env.dart` + `.env.example`; **mock mode is the default and nothing breaks without keys.**

## 3. Coverage matrix — summary

| Scope | Implemented | Stubbed | Out-of-scope | Total |
|---|---|---|---|---|
| Screens | **62** | 2 | 2 | 66 |
| SCREEN DETAIL options | **333** | 14 | 8 | 355 |

- **Stubbed screens:** S-005/S-006 — the ID-capture/liveness frames. By blueprint design the vendor SDK owns this UI in production (D-01); the screen implements every state/control around it.
- **Out-of-scope screens:** S-057/S-058 — internal staff web consoles; the blueprint's own SCREEN MAP note excludes them from the mobile binary. Their backend (case tables, SLA job) **is** built.
- **Stubbed options (14):** vendor capture options, native camera record, OS permission prompt calls, RTC join, store checkout — each an explicitly marked integration point.
- **Out-of-scope options (8):** the 7 options on S-057/S-058 + Super Like (OPEN DECISION D-05: do not ship).
- **Full matrix:** `coverage_matrix.csv` (355 rows, per option, with evidence file + note) and `coverage_screens.csv` (66 rows) at the project root. Screen table in §9.

## 4. Backend inventory (`backend/`)

- `supabase/migrations/0001_schema.sql` — **26 tables** implementing every DATA & API entity: profiles, verification_records, member_profiles, media, profile_photos, likes, passes, matches (with expiry), conversations, messages, safety_vault, moments, moment_views, game_sessions, spark_sessions, calls, plans, plan_feedback, reports (case refs + SLA), appeals, warnings, blocks, entitlements, notifications, remote_config_docs, ai_interaction_log.
- `supabase/migrations/0002_rls_views_triggers.sql` — RLS on **all** tables (own-rows only; verification/entitlements service-write-only; **safety_vault: client append-only, no client reads**), `geo_cells` + `band_for()` (distance BANDS from coarse cells — coordinates stored nowhere), `feed_profiles` view (safe columns only), `likes_you()` (count for all, identities Plus-only), mutual-like→match trigger, block-propagation trigger, 3 private storage buckets with own-folder policies, pg_cron schedule notes.
- `supabase/seed_remote_config.sql` — config v1, byte-equivalent in meaning to the client's compiled defaults.
- `supabase/functions/` — **ai-proxy** (Claude/GPT gateway, keys server-side, drafts-only by design, per-feature consent + logging), **moderation-intake** (AI-05; held-for-human is the default), **match-expiry** (archives unmessaged matches, deletes expired moments, dissolves due Vanish messages), **report-sla** (24 h SLA watch + escalation counts), **remote-config**, **verification-session** (opens IDV session; returns a marked pending session until D-01 lands). All pass `deno check`.
- `supabase/config.toml`, `backend/README.md` (security model + deploy steps).

## 5. QC pass — Bible release blockers (12/12 PASS, code-level evidence)

| # | Check | Result | Evidence |
|---|---|---|---|
| 1 | Age gate refuses under-21 | PASS | `age_gate_screen.dart` compares DOB-derived age to `AppConfig.minimumAge` (21); S-002B blocked state; unit test "age math"; DB `check (age >= 21)` |
| 2 | Safety reachable everywhere, never paywalled | PASS | `SafetyActions` wired on Profile/Chat/Chat Settings/Moments/Viewer/Spark invite+call/Incoming call/Post-plan/Trust Centre; **0** `isPlus` references in any safety file; paywall table explicitly excludes safety |
| 3 | Vanish honesty copy | PASS | Every "prevent" mention in the codebase is a negation or the rule statement; user copy: screenshots "can't be blocked… you'll always be told when one is detected"; sealed vault disclosed in Welcome/Privacy copy |
| 4 | AI never auto-sends | PASS | `AIService` exposes no send API (grep: 0 send methods); AI drafts only fill the composer on member tap (2 call sites); `ai-proxy` returns drafts only — no send route exists server-side |
| 5 | No fake users / fake scarcity | PASS | Pressure-phrase scan (`hurry`, `last chance`, `only N left`, `people are viewing`…): only hit is a comment stating the ban; Drop/Likes counts come from the data layer; defaults asserted in tests |
| 6 | App name in AppConfig only | PASS | Runtime strings route through `AppConfig.appName/plusName` (fixed in state_kit, filters, incoming call, settings); remaining occurrences are doc comments and the config itself |
| 7 | No hard-coded prices | PASS | "$12.99" appears only in comments explicitly labelled test hypothesis (D-04); paywall plan cards say "price shown at checkout" |
| 8 | Timers are real | PASS | Drop countdown computed from the clock to 18:00; OTP resend is a real 30 s `Timer`; Spark invite runs a real 10:00 countdown; match expiry is a server job, client only renders server state |
| 9 | Verification can't be self-granted | PASS | Client badge derives from completed layers only; RLS makes `verification_records` read-own-only with service-role writes; schema age floor |
| 10 | Block propagation + tombstone | PASS | SQL trigger closes matches/conversations on block; client `onBlocked` renders the conversation tombstone and removes the composer |
| 11 | Support AI is labelled | PASS | First support message self-identifies as AI; persistent banner "You're chatting with AI support. Not a person."; "Talk to a human" always visible |
| 12 | Session gate integrity | PASS | `AuthService.sessionChanges` drives RootFlow: sign-out (Settings/Delete) returns the app to Welcome; unverified states have no path to HomeShell |

## 6. How to run what was built

```bash
# Toolchain (already installed on this VM):
export PATH="$HOME/workspace/tools/flutter/bin:$PATH"
cd ~/workspace/carino-flutter
flutter pub get
flutter analyze        # 0 errors / 0 warnings / 49 infos (see §1)
flutter test           # 9/9
flutter build web      # compiles; or run on a device/emulator with a native toolchain
# Mock mode is automatic. Live mode:
flutter run --dart-define=SUPABASE_URL=https://<project>.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=<anon key>
```

## 7. Hosting phase — the precise remainder (Lovely's accounts/keys/actions only)

1. **Apple Developer** ($99/yr) + **Google Play** ($25) accounts; bundle ID / app signing.
2. **Supabase project** → `supabase link`, `supabase db push`, run the seed, `supabase functions deploy`, enable the two scheduled jobs (§4).
3. **Function secrets:** `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, screening-provider key, `IDV_VENDOR` + vendor keys.
4. **D-01 verification vendor contract** (Persona/Veriff class) → replaces the S-005/S-006 stub frame + `verification-session` pending mode.
5. **D-02 RTC provider** (Daily/Agora class) → `VideoService.joinWithToken` SDK wiring + a spark-token function to mint `rtc_room_ref`.
6. **RevenueCat** project + store products → `PaymentsService` purchase/restore wiring + the entitlements webhook (prices stay store-side; D-04 pricing decision is Lovely's).
7. **Native integrations:** camera capture (S-011), OS permission requests (S-014B), passkey ceremony, APNs/FCM push sender + token registration.
8. **Moderation staffing:** the S-057 console front-end + a staffed 24 h human queue (the SLA clock is already enforced by `report-sla`).
9. **Legal set:** full Terms/Privacy texts (summaries ship in S-001), formal name clearance for Cariño, `carino.app` + `@carinoapp` handles (from the name sweep homework).
10. **Device QA:** iOS + Android builds on a machine with Xcode/Android SDK; the 12 QC themes re-run as on-device tests.
11. **Follow-up (non-blocking):** migrate the 49 files off the deprecated `package:flutter/material.dart` umbrella import when `material_ui` reaches drop-in parity on a future SDK.

## 8. Known limitations, stated plainly

- All member data in the app today is **sample data** (`MockData`) — real feeds arrive with the live backend; screens were built so only the service layer changes.
- The demo OTP accepts any 6-digit code **in mock mode only** and says so in code/logs; live mode uses real Supabase OTP.
- The web build proves compilation, not store readiness: no native build has run anywhere yet.
- Migrations passed a grammar parse, not a live apply; first `db push` may surface Supabase-platform specifics (auth schema, storage policies) that need a fix round.

## 9. Screen-by-screen status (full option matrix: coverage_matrix.csv)

| Screen | Name | Pri | Status |
|---|---|---|---|
| S-001 | Welcome / Splash | P0 | IMPLEMENTED |
| S-002 | Age Gate — DOB Entry | P0 | IMPLEMENTED |
| S-002B | Under-21 Blocked Notice | P0 | IMPLEMENTED |
| S-003 | Auth — Passkey / Phone / Email | P0 | IMPLEMENTED |
| S-004 | ID Verification — Intro & Consent | P0 | IMPLEMENTED |
| S-005 | ID Capture (Provider SDK) | P0 | STUBBED |
| S-006 | Liveness + Selfie / Photo Match | P0 | STUBBED |
| S-007 | Verification Result / Pending / Appeal | P0 | IMPLEMENTED |
| S-008 | Intentions Setup | P0 | IMPLEMENTED |
| S-009 | Privacy & Notifications Setup | P0 | IMPLEMENTED |
| S-009B | City Waitlist | P1 | IMPLEMENTED |
| S-010 | Profile Creation — Photos | P0 | IMPLEMENTED |
| S-011 | Video Intro Recorder | P0 | IMPLEMENTED |
| S-012 | Voice Intro Recorder | P1 | IMPLEMENTED |
| S-013 | Prompts, Interests & Boundaries | P0 | IMPLEMENTED |
| S-014 | Profile Preview / Publish | P0 | IMPLEMENTED |
| S-014B | Permissions Primers | P0 | IMPLEMENTED |
| S-015 | Discover Feed — Nearby | P0 | IMPLEMENTED |
| S-016 | Daily Drop | P0 | IMPLEMENTED |
| S-017 | Discover Filters | P0 | IMPLEMENTED |
| S-018 | Worldwide / City Search | P1 | IMPLEMENTED |
| S-019 | Profile Detail | P0 | IMPLEMENTED |
| S-020 | Match Celebration Overlay | P0 | IMPLEMENTED |
| S-021 | Likes You / Who Liked Me | P1 | IMPLEMENTED |
| S-022 | Moments Feed | P1 | IMPLEMENTED |
| S-023 | Create Moment | P1 | IMPLEMENTED |
| S-024 | Moment Viewer | P1 | IMPLEMENTED |
| S-025 | Connect Hub | P0 | IMPLEMENTED |
| S-026 | Spark Session Lobby | P0 | IMPLEMENTED |
| S-027 | Spark Invite — Accept / Decline | P0 | IMPLEMENTED |
| S-028 | Camera / Mic Preview | P0 | IMPLEMENTED |
| S-029 | Live Spark / Video Call | P0 | IMPLEMENTED |
| S-030 | Games Hub / Lobby | P0 | IMPLEMENTED |
| S-031 | In-Game Play | P0 | IMPLEMENTED |
| S-032 | Post-Call Choice | P0 | IMPLEMENTED |
| S-032B | Compatibility Reveal | P1 | IMPLEMENTED |
| S-033 | Incoming Call | P0 | IMPLEMENTED |
| S-034 | Chat List | P0 | IMPLEMENTED |
| S-035 | Conversation — Keep Mode | P0 | IMPLEMENTED |
| S-036 | Conversation — Vanish Mode | P0 | IMPLEMENTED |
| S-036B | Mode Switch Sheet (Keep <-> Vanish) | P0 | IMPLEMENTED |
| S-037 | Media Viewer (incl. View-Once) | P0 | IMPLEMENTED |
| S-038 | Conversation Settings | P0 | IMPLEMENTED |
| S-039 | Plan Composer — Suggest a Plan | P0 | IMPLEMENTED |
| S-040 | Plan Detail / Confirmation | P0 | IMPLEMENTED |
| S-041 | Plans List | P1 | IMPLEMENTED |
| S-042 | Post-Plan Feedback | P1 | IMPLEMENTED |
| S-043 | My Profile — You Tab | P0 | IMPLEMENTED |
| S-044 | Edit Profile & Media | P0 | IMPLEMENTED |
| S-045 | Intentions & Availability Editor | P0 | IMPLEMENTED |
| S-046 | Verification Centre | P0 | IMPLEMENTED |
| S-047 | Privacy Centre | P0 | IMPLEMENTED |
| S-048 | Likes & Introductions Manager | P1 | IMPLEMENTED |
| S-049 | Report Flow | P0 | IMPLEMENTED |
| S-050 | Settings — Account & App | P0 | IMPLEMENTED |
| S-050B | Block Confirmation | P0 | IMPLEMENTED |
| S-051 | Report Confirmation / Appeal | P0 | IMPLEMENTED |
| S-052 | Safety Centre | P0 | IMPLEMENTED |
| S-053 | Help & AI Support Assistant | P0 | IMPLEMENTED |
| S-054 | Paywall — Cariño Plus | P0 | IMPLEMENTED |
| S-054B | Subscription Management | P0 | IMPLEMENTED |
| S-055 | Delete Account | P0 | IMPLEMENTED |
| S-056 | Notifications Centre | P1 | IMPLEMENTED |
| S-057 | Moderation Console — Trust OS (Internal) | P0 | OUT-OF-SCOPE |
| S-058 | Admin — Accounts, Billing & Config (Internal) | P1 | OUT-OF-SCOPE |
| S-059 | Empty / Error / Permission State Kit | P0 | IMPLEMENTED |