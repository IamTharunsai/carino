# Cariño — Handoff for the next agent

Read this before coding. It records what was built in the "experience bundle"
and "social platform" passes (Nov 2026), how it is wired, and what is left.

## Hard rules (do not break)
- **Never change the style or design.** Use the existing tokens and widgets:
  `AppColors`, `GlassContainer`, `GlassScaffold`, `showGlassSheet`,
  `SparkButton`, Midnight/Porcelain themes. No new colours or fonts.
- Honesty rules from the blueprint: no fake users/likes/matches, AI never
  sends as the user, AI content always labelled, no fake countdowns, safety
  never paywalled, no attractiveness scores.
- Dating (Dates tab) stays **21+ and ID-verified**. Friends/groups never mix
  with Dates.
- Every new screen must pass the phone-size render test (see Tests).

## Product direction (decided by founder)
Cariño = a social app (Chats, Stage, Plans, circles) **with dating as one
21+ tab**. Vision page: https://claude.ai/artifact/MFtyYQ7RQfof6fdxyo3D12
Founder's 34-feature list is the target (see "Feature map" below).

## Tabs (lib/screens/home_shell.dart)
`Chats · Stage · Dates · Plans · You`
- Chats = `chats/chat_list_screen.dart` (Groups section + Dates 1:1 chats)
- Stage = `stage/stage_screen.dart` (Feed | Moments switch)
- Dates = `discover/discover_screen.dart`
- Plans = `connect/connect_screen.dart` (hub; label "Plans")
- You = `you/you_screen.dart`

## Where the logic lives (pure Dart, unit-tested)
- `lib/models/experience.dart` — identity options, `wantsToMeet`/`mutualFit`,
  taste quiz + `sharedTastes`, events, Spark Nights, `ChemistryStreak`,
  profile aura, Scam Shield (`scanForScam`), Close the Loop templates.
- `lib/models/social.dart` — `Circle` enum + `circleCanSee`, `SocialGraph`,
  `GroupChat`/`GroupMessage`, `PlanPoll` (majority vote), `suggestPlanTimes`.
- `lib/models/platform.dart` — Stage feed (`FeedItem`, `parseFeedControls`,
  `buildFeed` finite/human-only/chronological, `whyThisPost`), `TrustGraph`
  (met-IRL, warm-intro `introducersFor`, vouches), `hostTier` +
  `hostShareCents`, `splitCents`, `suggestNightPlan`, `WorkFacet` +
  `weeklyCoffeeMatch`, `Guild`, `catchUpSummary`, `Gift`.
- Sample data: `lib/data/mock_data.dart` (members incl. Rowan they/them and
  Elena 44, friends, groups, feed, guilds, work facets, events, tonight).
- State: `lib/services/services.dart` → `Services.prefs` (identity, calm
  mode, no-counts, facets, trusted contact, myPlans, guilds),
  `Services.social` (circles), `Services.trust` (trust graph).

## Feature map (founder's 34) — status
Built & wired (demo data): 1 verified ID (existing onboarding), 4 taste
quiz, 5 finite feed, 6 human-made filter, 7 Moments stickers, 8 video prompt
replies, 9 private circles (circle picker on Moments, Friends & circles
screen), 10 group chat polls + plan-making, 11 highlights, 12 wingperson,
13 Post → Plan (`widgets/post_to_plan_sheet.dart`, on feed cards, guild
rooms, night planner), 14 Tonight Near Me, 15 group hangouts + Spark Nights,
16 Micro-Hosts (`HostPlanScreen`, tiers), 17 check-in safety (plan detail),
18 mutual-fit discover, 19 Spark lenses, 20 Scam Shield (1:1 + groups),
21 close the loop + debrief, 23 coffee chats, 24 warm intros, 25 guilds,
26 AI drafts (existing), 28 AI night planner card, 29 safety signals,
30 calm mode (You tab), 31 forgiving streaks, 32 why-you're-seeing,
33 Plus (existing), 34 gifts in Stage (demo-only purchase).

**Implemented in the remaining-features pass (Nov 13, 2026):**
- 2 **Facets**: `you/facets_screen.dart`, linked from You; all five fields,
  four facets and four audiences editable. Session preferences only; the
  screen explicitly says live profile enforcement is not connected.
- 3 **Trust Graph**: `you/trust_graph_screen.dart`, linked from You. Local
  matching-code preview, regenerated after success/selection; confirmed
  meetings, received vouches and own authored vouches. Never impersonates
  a voucher. This is not bilateral verification on two phones.
- 22 **Work facet**: `you/work_facet_screen.dart`, validated role, project
  and open-to choices; updates prefs used by coffee matching.
- 30 **No-Counts**: reactive switch in You, reactive Likes You headline;
  Guilds continues using the same notifier.
- 10 **Group chat extras**: Chat extras menu offers AI catch-up (consent
  gated, labelled rule-based local fallback), prospective 24-hour Vanish
  for own new messages, and an honest voice/translation integration stub.
  Expired messages are removed on thread open, while open, and before
  list previews. Turning Vanish off preserves existing expiry times.
- 34 **Plan splits**: `widgets/plan_split_card.dart` on plan detail, exact
  USD cents, two equal shares, mark/undo own payment, edit/reset total.
  Stable stored-plan ID keys, session ledger; no transfer or verified payment.
- 27 **AI coach remains craft tips only**, never attractiveness scores.
- Added logic and interaction tests; expanded phone renders to Stage,
  Friends, Group chat, all Plans hub destinations and all new screens.
  Fixed Stage action-row and Plans match-card phone overflows.
- Backend: **0005_social_platform.sql** adds 20 tables with RLS and explicit
  grants. Consent/invitation/moderation/payment/reputation writes are
  service-role only pending authenticated endpoints. Paid marks can only
  update the caller's own share, never amounts or another member's mark.
- Migrations **0001–0005 run locally in PostgreSQL WASM (PGlite)** with
  Supabase Auth/Storage shims and 32 RLS assertions. Fixed 0004 check-in
  INSERT authorization to require actual plan participation.
  **Neither 0004 nor 0005 has been applied to hosted Supabase.**

**Still requires production integration:**
- Existing app prefs/social models are session memory. Add authenticated
  persistence and server-enforced per-field facet projections before launch.
- Server-issued expiring meeting codes with bilateral acceptance, vouch
  delivery, group membership invitations and group-wide Vanish consent.
- Scheduled deletion of expired messages/media (RLS hiding is not deletion).
- Real AI summaries, audio capture/playback/transcription and voice translation.
- Server-side social write endpoints, validated poll membership/options and
  majority, split membership/rounding, purchase receipts and host reputation.
  Schema availability does not imply these endpoints exist.
- Hosted Supabase migration dry-run/apply and real Auth/Storage/Edge testing.
  Docker Desktop's Linux engine was unavailable here; tests use isolated
  PGlite and do not validate hosted services or scheduled jobs.

## Tests & checks
Verified in this pass: 65 Flutter tests pass; 32 database/RLS assertions
pass; eight additional Midnight/Porcelain preview renders pass at 360×740.
Analyzer reports only the existing Flutter material import deprecation infos.
Android debug packaging passes: `flutter build apk --debug --no-pub`;
artifact: `build/app/outputs/flutter-apk/app-debug.apk` (mock backend).

```
$env:Path = "C:\src\flutter\bin;$env:Path"
flutter analyze   # only 'material_ui' deprecation infos are expected
flutter test      # includes logic, interaction and 360x740 render tests
cd backend/tests
npm ci --ignore-scripts
npm test          # applies 0001-0005 and checks 32 authorization assertions
```
`test/experience_test.dart` renders screens at 360×740 and fails on any
overflow — keep adding new screens to it.

## Known environment issues
- Emulator `Medium_Phone_API_35` can't start when the PC is low on RAM;
  close apps first. Package: `com.example.carino`.
- PowerShell `Set-Content -Encoding utf8` adds a BOM — avoid for Dart files.
- Inline heredoc Python sometimes fails in the Bash tool; write scripts to
  the scratchpad and run them.

## Update (after Codex ea17cb2)
- Reviewed Codex commit: analyzer clean, 65 Flutter tests, RLS tests pass.
- Migration `0006_social_writes.sql` enables real client writes for groups, group messages, plan polls and guild joins (48 RLS assertions in `backend/tests`).
- **Next priority:** wire Flutter Chats (groups, messages, polls) to Supabase in live mode; screens still use demo data.
- Research: see `docs/RESEARCH-SYNTHESIS.md`.

## Update (Nov 14) — experience upgrade
- Read `docs/EXPERIENCE-STRATEGY.md` first (scenarios, psychology, 2050 vision, legal, AI policy).
- Screenshots of all screens: `CAPTURE=1 flutter test test/screenshots/capture_test.dart` -> `build/screens/` (54 shots, real fonts). Run it after any UI change and look for "LAYOUT ISSUE".
- Brand fonts bundled: DM Serif Display (headlines) + Poppins (UI) in `assets/fonts` (OFL).
- New: biometric app lock + passkey prompt (`local_auth`, Android FlutterFragmentActivity), Google/Apple sign-in (Supabase OAuth, redirect `carino://login-callback` must be configured), theme switch, heart burst + like options, chat themes/stickers/+ menu, pin/hide chats, Honest Status + Couples mode + bookings (`url_launcher`), referrals/promo, on-device analytics (`Services.analytics`).
- Policy: AI never chats as the user; only labelled drafts and the labelled Away assistant.

## Update (Nov 14) — Conversation Sync
- Logic: `lib/models/sync.dart` (TextingStyle/paceNote/styleHints,
  commonGround/groundedOpeners/findBridge, ComfortRules + callBlockedReason /
  photoBlockedReason / firstMeetAllowed, ToneTag, Reflection + rankForMe,
  PauseLength/pauseNotice). Tests: `test/sync_test.dart`,
  `test/sync_screens_test.dart` (real fonts via `test/support/real_fonts.dart`).
- Screens: chat (`conversation_screen.dart`: You-both strip at top of the
  thread, plan bridge after the messages, tone tag, pause, comfort holds,
  auto-scroll to newest), `you/sync_settings_screen.dart` (You → How I text &
  comfort), profile card (`widgets/sync_widgets.dart` TextingCard), plan
  composer daytime rule, post-plan private check-in, Decompress "Picked for
  you · reason", conversation settings "Things to remember".
- Data: `Member.textingStyle/comfort`, `Conversation.daysChatting/pausedLabel`,
  `ChatMessage.toneTag`; prefs persisted under the `sync` key.
- Backend: `0008_conversation_sync.sql` (conversation_prefs readable by
  matches; private_reflections + private_notes owner-only; chat_pauses;
  messages.tone_tag immutable; comfort triggers on messages + calls).
- Booking from anywhere: `bookExperience(context, experience, mode)`.
- Review-driven extras and store copy: `docs/REVIEW-GAPS.md`.

## Update (Nov 14) — screen audit, care, red-team round 2
- Removed internal spec codes (S-0xx, AI-0x) and "scaffold build" from all
  user-visible text/tooltips; demo-only controls (incoming-call preview,
  waitlist "batch opened") show only when `Env.useMockBackend`.
- `lib/models/care.dart`: Mood/careFor/moodPicks (Decompress "How are you,
  really?" + `OneMinuteScreen`), `personalDeck` (This or That built from both
  profiles; GamesScreen uses it). `ComfortRules.opensFirst` +
  `firstMessageHold` ("I'll message first").
- Tests: `test/care_games_test.dart`, `test/personas_test.dart` (10,000 seeded
  people, invariants), `test/prefs_roundtrip_test.dart`.
- `0009_hardening_round2.sql`: client message insert guard (no system
  notices, server time, rate limit, opens-first), `guard_plans`. Guards are
  SECURITY INVOKER — `is_client()` is always false inside definer functions.
- Security + scale write-up: `docs/SECURITY-AND-SCALE.md`.

## Update (Nov 15) — merged the parallel build (`carino-source (1)`)
- That folder was the Nov 13 first commit + another agent's rewrite around a
  central `AppStore`. A blind copy would have deleted migrations 0003–0010
  and today's work, so it was merged feature by feature into THIS
  architecture: motion library (aurora backgrounds, Ken Burns, shimmer),
  real tap/chime sounds (`audioplayers`, `assets/sounds`), particle match
  overlay (`flutter_animate`), 3D swipe tilt + LIKE/PASS/SUPER stamps + flick
  + swipe-up Super Like, scrollable sheets, and their bug fixes (Daily Drop
  advances, view-once spent on close, Vanish dissolves, AI switches honoured,
  keyboard send + 1000-char cap, video button → Spark lobby, photo blur,
  theme saved). Their `AppStore`, chaos tests, Worldwide and Plans list
  were NOT taken (they need the store). The folder stays on disk, ignored by
  git and the analyzer.
- Tests: `test/flutter_test_config.dart` freezes the looping backgrounds
  (`stillBackgrounds`) so pumpAndSettle can finish.
- Button audit: `AUDIT=1 flutter test test/audit/button_audit_test.dart`
  (620 controls / 61 screens → `build/audit/buttons.csv`).
- Other agent's source audit kept in `docs/CUSTOMER-WORKFLOW-REVIEW-2026-11-15.md`
  and `docs/audit/` (26 findings; D01/D02/D05/D06/D09/D16/D17/D22-drop/D25
  fixed today — the rest are listed there).
