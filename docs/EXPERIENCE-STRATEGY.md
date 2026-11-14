# Cariño — Experience Strategy, Customer Scenarios & 2050 Vision (Nov 14, 2026)

For the founder and the next agents. Pairs with `HANDOFF.md` and
`docs/RESEARCH-SYNTHESIS.md`. Screenshots of every screen and scenario are
produced by `CAPTURE=1 flutter test test/screenshots/capture_test.dart`
(output: `build/screens/*.png`, 54 shots).

---

## 1. Customer walkthrough — every screen, wrong inputs, what happens

| Screen | Customer does… | App does (today) | Status |
|---|---|---|---|
| Welcome | Taps Create account / Sign in / Terms | Photo top, panel mid-screen, arrow CTA, legal sheets | ✓ fixed layout bug found by screenshots |
| Sign in | Taps Sign in with empty fields | Button disabled; "* Required"; per-field "is required" after touching | ✓ |
| Sign in | Wrong password | "That username and password don't match" (never reveals if user exists) | ✓ |
| Sign in | Forgot password | One-time-code route | ✓ |
| Sign in | Google / Apple / passkey | OAuth (live) / biometric passkey prompt | ✓ new |
| Date of birth | Taps Continue without scrolling | Disabled; chip "Scroll to your date of birth" | ✓ |
| Date of birth | Picks a future date | "That date is in the future", Continue disabled | ✓ |
| Date of birth | Under 21 | Kind refusal; back returns to Welcome (no retry trick) | ✓ |
| Phone/email code | Types "abc" | "Enter a valid phone number or email." | ✓ |
| Code entry | Wrong code ×5 | Attempts left → lockout screen, passkey fallback | ✓ |
| Verification | Fails a layer | Reason category, retry, alternative route, human appeal | ✓ |
| Every onboarding page | Presses back (button or Android gesture) | Goes one step back | ✓ |
| Dates | Taps ♥ | Heart burst, then match celebration | ✓ new |
| Dates | Holds ♥ | Like with note / gift / Spark (honest daily count) | ✓ new |
| Dates | Swipes left by mistake | "Undo" snackbar | ✓ |
| Chat | Types money/crypto/"WhatsApp me" | Pre-send pause + Scam Shield banner + Report | ✓ |
| Chat | Wants photo/sticker/voice/game/plan | One "+" menu (Hick's law) | ✓ new |
| Chat | Wants a different look | Per-chat theme | ✓ new |
| Chat list | Wants privacy | Hold → pin / hide behind Face-fingerprint | ✓ new |
| Settings | Turns on app lock without biometrics | Refuses with a clear reason (can't lock yourself out) | ✓ new |
| Settings | Changes theme | Dark / Light / Auto app-wide | ✓ new |
| You | Marks "Married" | Dates pauses automatically (Honest Status) | ✓ new |
| Paywall | Has a code | Promo link → Invite & offers | ✓ new |
| Promo | Invalid / reused code | Plain error / "already redeemed" | ✓ new |

**Known gaps (next agent):** everything runs on sample data; real camera,
AR lenses, payments and RTC wait on vendor accounts (see `DEPLOYMENT.md`).
Emoji render as boxes only in the headless screenshot tool (no emoji font
there) — they render normally on phones.

---

## 2. Design changes this round (and why)

- **Type:** DM Serif Display for headlines (romance, "feeling"), Poppins for
  UI/body (friendly, highly legible). Bundled under OFL — no runtime font
  downloads.
- **Layout fixes from screenshots:** welcome collapsed to the logo; tab
  bar, Spark call, pre-call and Dates header overflowed or truncated at
  phone width; buttons were in the system font; You screen had corrupted
  characters ("Â·"). All fixed; 0 layout issues across 54 shots.
- **Motion:** cinematic heart / Spark-flame burst (~900 ms, spring-like
  ease-out, coral bloom); single-heart fade in Calm mode / reduced motion.
- **Composer:** 7 icons → "+" menu, AI draft, Send (more room to type).
- **Theme:** user-selectable Dark (Midnight) / Light (Porcelain) / Auto.

---

## 3. Marketing psychology applied — ethically

| Moment | Principle | How it's used | Guardrail |
|---|---|---|---|
| Onboarding steps | Goal-gradient, IKEA effect | Progress + identity/taste the user builds | Every step skippable where legal |
| Like with a note | Reciprocity, specificity | Note references their prompt → more replies | Never auto-written |
| Spark (Super Like) | Scarcity (real) | 1 free/day, counter is true | No fake "only 2 left" timers |
| Invite & offers | Reciprocity + unity | Give a week, get a week (verified friends only) | Cobra-effect guard: no reward for fake sign-ups, 10/yr cap |
| Promo codes | Endowment | Founding / city-launch codes | Server-validated, one per account |
| Paywall | Anchoring (honest) | Real store price + renewal stated | No decoy tiers, no countdowns |
| Match | Peak-end rule | Heart burst → match celebration → plan | Calm mode respected |
| Chat list | Zeigarnik | "Quiet for 6 days — close kindly?" | Optional; nobody is labelled |
| Profile aura | Goal-gradient | Glows with effort | Never measures looks |

North Star: **dates that happened per active member per month**.

---

## 4. "Think like 2050, ship now" — what people really want

People want: to feel desired and safe at the same time, to be understood
without over-explaining, less time typing and more time together, and
privacy about who they're talking to. Translated into buildable features:

| 2050 idea | Ship-now version | State |
|---|---|---|
| The app knows when you're both free | Couples calendar + Night Planner + group plan polls | ✓ |
| One tap from "we should" to a booked night | Bookings hand-off (OpenTable, Booking.com, Uber, Maps) | ✓ new (links) |
| Your relationship is your business | Honest Status with audience (everyone / friends / just me) | ✓ new |
| Private memories that never leak | Couples memories, view-once, hidden chats behind biometrics | ✓ new |
| Biometric everything | App lock + passkey via Face/fingerprint (`local_auth`) | ✓ new |
| Presence without pressure | Away assistant (labelled) | ✓ new (toggle) |
| AR flirting | Lenses on Spark calls, labelled | ✓ (placeholder until RTC) |
| Real-time translation | Chat translate (live AI proxy) | ✓ stub |
| Next: shared playlists, couple goals, anniversary reminders, AI date-recap journal (private), group trip planner with splits | Backlog |

### Relationship status, cheating and consent
- **Honest Status:** "In a relationship" / "Married" automatically pauses
  Dates. We do not verify marriages or report anyone to a partner — that
  would be surveillance — but we remove the easy path to deception.
- **Open relationships** are first-class and labelled on the card, so
  everyone consents with full information.
- **Couples mode** requires both people to link (mutual code); either can
  unlink; nothing from before linking is shared.
- **Never build:** partner-tracking, "see who your partner talks to",
  location sharing without live mutual consent, or screenshots of others'
  chats. These create stalking/abuse risk and legal exposure.

---

## 5. Why the AI must not chat *as* the user (and what we built instead)

Request considered: "AI chats with people on the user's behalf in a
natural tone." We are not shipping that, because:
1. **Deception & law:** undisclosed bots that influence people can breach
   California's BOT Act (SB 1001), the EU AI Act transparency duties, FTC
   deception rules, and Apple/Google policies. Romance contexts raise the
   harm (the other person is forming feelings for software).
2. **Trust collapse:** once members suspect replies might be AI, every
   conversation loses value — the core product dies.
3. **Safety:** an autonomous agent can agree to meetups, share details or
   escalate intimacy the user never approved.

**Instead (built):** AI drafts you edit and send yourself; icebreakers;
Night Planner; and the **Away assistant**, which only sends a clearly
labelled "Your assistant" note about when you'll be back — never flirting,
never pretending.

---

## 6. Legal & policy checklist for the new features

| Area | Risk | Mitigation |
|---|---|---|
| Biometrics | BIPA/GDPR biometric data | We never receive biometric data — OS returns pass/fail only |
| Hotel/"night" bookings | FOSTA-SESTA, solicitation, store policy | Bookings are hand-offs to licensed partners; no paid companionship, no "hourly rooms" category; ToS bans commercial sex |
| Relationship status | Privacy, defamation | Self-declared, audience-controlled, never shown to an ex/partner without consent |
| Referrals | FTC endorsement, incentive fraud | Plain terms; verified-only rewards; annual cap |
| Promotions | Auto-renew laws (CA ARL), store rules | Store-native offers; renewal disclosed |
| Gifts | Money transmission | Store IAP only; no peer-to-peer cash |
| AI | Disclosure laws | All AI output labelled; no autonomous messaging |
| Age | 21+ product | DOB gate + 3-layer ID verification |

---

## 7. Measurement — "who clicks what"

`AnalyticsService` (on-device in demo; PostHog-class in production with
opt-out) tracks screen views (tab switches) and key actions: `like`,
`like_note`, `spark`, `pass`, `chat_theme`, `sticker`, `booking_*`,
`status_*`, `referral_copied`, `promo_redeemed`. Members see their own
usage in **You → Your activity**. Never logged: message text, photos,
locations, or who was viewed.

Core funnels to watch: welcome → verified (activation); like → match →
first message → plan → plan happened (North Star); paywall view → purchase;
referral copied → friend verified.

---

## 8. Next build list (prioritised)

1. Wire Chats/groups/polls to Supabase live (tables + RLS exist: 0005/0006).
2. Real passkeys (platform credential APIs) — today passkey = biometric demo.
3. Couples mode backend (couple_links, shared_calendar, memories; RLS by pair).
4. Away assistant server job (labelled auto-note only).
5. Anniversary reminders, shared playlists, private AI date journal.
6. Store assets from `build/screens` (App Store / Play screenshots).
