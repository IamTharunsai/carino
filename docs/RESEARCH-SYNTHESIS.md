# Dating & social app sentiment — Synthesis Report (Nov 2026)

Pulls together all research done for Cariño in this period: web research on
dating/social trends and reviews, plus X/Twitter sentiment. Read with
`HANDOFF.md`.

## Summary
People are tired of swiping, bots and doom-scrolling, and they want control,
privacy and real-life connection. The big apps are reacting by replacing the
swipe with AI-curated matching, so "no swiping" alone is no longer a
differentiator. Cariño's defensible edge is **verified humans + plans that
happen in real life + feeds and circles the user controls**.

## Key findings (ranked by evidence quality)
1. **Swipe fatigue is mainstream, and incumbents are abandoning the swipe.**
   Evidence: High. 78% report dating-app burnout (Forbes Health/OnePoll,
   2024 data); Bumble announced ending the swipe for AI matchmaking (Q4 2026
   relaunch, limited markets); Tinder "Chemistry" daily AI set (Mar 2026);
   Hinge's founder launched a no-swipe AI app.
2. **Money is moving to intentional, date-focused apps.** Evidence: High
   (earnings). Hinge +17% payers / +26% revenue (2025); Bumble paying users
   −21%; Tinder MAU −9% (secondary reporting).
3. **Fake profiles and bots are the top complaint; false bans are the
   second-order harm.** Evidence: Medium. 21–34% of negative reviews cite
   bots/fakes (review analyses); X users describe OnlyFans bots alongside
   being wrongly banned *as* a bot with no explanation.
4. **People want control of their feeds and are actively limiting use.**
   Evidence: Medium–High. Only 36% feel in control, 65% want more
   (Cybersmile 2026); Gen Z "logging their way out of doomscrolling"
   (Business Insider, Mar 2026); privacy is the top reason to quit (51%).
5. **Real social life is moving private.** Evidence: Medium. Group chats,
   Close Friends and Discord carry Gen Z's meaningful interaction (agency
   research; directionally consistent across sources).
6. **Loneliness is high and people want IRL activity-based meeting.**
   Evidence: Medium–High. ~46% of 18–29s moderate/severe loneliness
   (WashU 8-country study); "rather sweat together" fitness dating, run
   clubs, meetups with strangers (YPulse 2026, Straits Times).
7. **AI labelling is expected.** Evidence: Medium. 85.6% want AI content
   labelled (900-person survey).
8. **Face-based verification can exclude people.** Evidence: Low
   (anecdotal X post) but high-impact: a user says Tinder's facial checks
   exclude people who can't show facial expressions.

## Contradictions
- **AI matchmaking: hype vs. reality.** Many posts celebrate AI matchmakers;
  The Atlantic's hands-on test found it "familiar and disappointing".
  *Unresolved* — treat AI as an assistant (drafts, planner, coach), not a
  replacement for the user's choice. This matches Cariño's AI rules.
- **Users hate paywalls, yet premium tiers grow.** Complaints about
  per-action charges coexist with Tinder Select ($499/mo, invite-only).
  *Resolution:* people pay for clear value and status, not for unlocking
  basic fairness. Keep one honest Plus tier; never paywall safety.
- **Engagement stats from agencies vs. surveys.** Several widely shared
  Gen Z numbers trace to blogs; use the stronger sources above externally.

## How Cariño maps (built ✓ / gap ✗)
- ✓ Finite Daily Drop, plans as the win state, events, Spark Nights, guilds
  (findings 1, 6)
- ✓ 3-layer verification + reason codes + human appeal + **alternative
  verification route** (`verification_intro_screen.dart`) (findings 3, 8)
- ✓ Finite Stage feed, plain-words controls, human-made filter, AI labels,
  no-counts and calm modes (findings 4, 7)
- ✓ Circles, private groups with plan polls (finding 5); backend writes
  enabled by migration 0006
- ✗ App is still demo-data only: Flutter screens don't yet read/write the
  Supabase social tables (0005/0006). This is the main remaining work.

## Recommendations
1. **Lead marketing with "verified people, real plans", not "no swiping"** —
   competitors are removing the swipe too (finding 1).
2. **Wire the app to Supabase for Chats → groups, messages, polls first**
   (tables + RLS exist and are tested in `backend/tests`) — the most-used
   private-life surface (finding 5).
3. **Keep the alternative verification route prominent and staffed** —
   avoid the exclusion and false-ban stories hurting Tinder (findings 3, 8).
4. **Pilot activity-based plans (run club, pottery, games) in Columbus** —
   strongest IRL demand signal (finding 6).
5. **Publish the honesty promises in the store listing** (AI labelled, no
   fake profiles, safety free) — directly answers findings 3 and 7.

## Methodology & limitations
- Web research (standard + extended search) across trade press, surveys,
  earnings coverage and review analyses; X sentiment via Crustdata account
  posts (@Tinder, @bumble; @hinge call failed) and x.com-restricted search.
- The `x_search` tool the X-research skill expects was not installed, so no
  like-sorted or date-windowed X sampling; X evidence is anecdotal.
- No primary access to company filings or survey datasets; several figures
  are secondary reporting.
- The claude-flow memory store named by the synthesis skill isn't available
  in this environment, so this file is the record.

## Sources
- Forbes Health burnout survey — https://www.forbes.com/health/dating/dating-app-fatigue/
- Axios, Tinder AI (Mar 2026) — https://www.axios.com/2026/03/12/tinder-ai-features-hinge-bumble
- Match Group Q3 2026 — https://www.globaldatinginsights.com/featured/match-group-q3-2026-results-hinge-growth-and-new-plans-for-tinder/
- Bumble paying users −21% — https://www.globaldatinginsights.com/featured/bumble-reports-high-q1-but-paying-users-drop-21/
- Bumble ending swipe (X) — https://x.com/HedgieMarkets/status/2052907149794357632 · https://x.com/6abc/status/2055204062103048622
- Hinge founder no-swipe AI app (X) — https://x.com/barstoolsports/status/2077464477444771894
- The Atlantic on AI matchmaking (X) — https://x.com/TheAtlantic/status/2057947193332416850
- Therapists on swipe burnout (X) — https://x.com/MensJournal/status/2070239391042125945
- Fitness dating (X) — https://x.com/ST_LifeTweets/status/2067059136106291631
- Gen Z logging out of doomscrolling (X) — https://x.com/ReelTalker/status/2031059642508267727
- Tinder bots / face-check complaints (X via Crustdata, @Tinder search) — https://x.com/haubursin/status/2042064371644330401
- Unstar negative-review analyses — https://unstar.app/blog/best-dating-apps-ranked-by-negative-reviews-2026
- Cybersmile Forced Feed 2026 — https://www.cybersmile.org/resource/forced-feed-report-2026/
- Incogni/quit-reasons coverage — https://www.thenewdaily.com.au/life/social-media-life/2026/07/13/social-media-disengament
- WashU loneliness study (via Relevant) — https://relevantmagazine.com/culture/loneliness-isnt-what-we-think-it-is/
- YPulse friendship & community 2026 — https://www.ypulse.com/report/2026/08/05/friendship-and-community-report-2/
- Gen Z private sharing — https://influencermarketinghub.com/gen-z-social-media-trends/
