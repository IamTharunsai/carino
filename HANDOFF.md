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

**Not yet built — next agent:**
- 2 **Facets screen** (Public/Circles/Dating/Professional per-field
  audience). Data exists: `Services.prefs.facetAudience`. Add
  `you/facets_screen.dart` + a row in You.
- 3 **Trust Graph screen** (met-IRL code confirm, vouches). Logic exists in
  `TrustGraph`; add UI in You.
- 22 **Work facet editor** (prefs `workRole`, `workBuilding`, `workOpenTo`).
- 30 **No-Counts toggle UI** (`Services.prefs.noCounts`; Guilds already
  respects it; also hide Likes You count in `connect_screen.dart`).
- 10 **Smart chat extras**: AI catch-up button in `GroupChatScreen` using
  `catchUpSummary`, Vanish toggle for groups, voice note + translate stub.
- 34 **Plan splits** UI in `connect/plan_detail_screen.dart` using
  `splitCents`/`formatCents` ("Mark paid", no in-app money transfer).
- 27 AI coach: keep craft tips only — the blueprint forbids attractiveness
  scores, so do NOT "score photos".
- Tests: add `test/platform_test.dart` (pure logic in platform.dart and
  social.dart) and add Stage/Plans-hub/Friends/Group chat screens to the
  render list in `test/experience_test.dart`.
- Backend: `backend/supabase/migrations/0004_experience_bundle.sql` covers
  identity, stickers, events, check-ins, wingperson. **Not applied, not run
  against a DB.** A 0005 migration is still needed for circles, groups,
  polls, feed posts (ai_generated), trust edges/vouches, hosts, work facets,
  coffee matches, intro requests, guilds, gifts, plan splits.

## Tests & checks
```
$env:Path = "C:\src\flutter\bin;$env:Path"
flutter analyze   # only 'material_ui' deprecation infos are expected
flutter test      # 40 tests pass at commit after 2af3200 (all green)
```
`test/experience_test.dart` renders screens at 360×740 and fails on any
overflow — keep adding new screens to it.

## Known environment issues
- Emulator `Medium_Phone_API_35` can't start when the PC is low on RAM;
  close apps first. Package: `com.example.carino`.
- PowerShell `Set-Content -Encoding utf8` adds a BOM — avoid for Dart files.
- Inline heredoc Python sometimes fails in the Bash tool; write scripts to
  the scratchpad and run them.
