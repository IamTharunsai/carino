# Cariño — Security (red-team view) and scale plan · Nov 14, 2026

Written for: founders, the next engineer, and a security reviewer. Every
"fixed" row has an automated test in `backend/tests/migrations.test.mjs`
(85 assertions) or `test/` (134 Flutter tests). Re-run both before any release.

## 1. How someone would attack us, and what stops them

| # | Attack | Result | Where it's stopped |
|---|---|---|---|
| 1 | Read other people's chats, notes, reflections, verification | **Blocked** | Row-level security on every table; owner-only for notes, reflections, verification |
| 2 | Forge a "Cariño Safety" system message (phishing link) | **Fixed this round** | `0009` insert guard forces `is_system_notice=false`, refuses `kind='system'` |
| 3 | Backdate messages to get round "photos after N days" | **Fixed this round** | `0009` forces `created_at = now()` for clients |
| 4 | Mark a plan "confirmed by both" / fake the other person's "home safe" | **Fixed this round** | `0009 guard_plans`: you can only change your own confirmation; check-ins are own-row only |
| 5 | Message flood / harassment burst | **Fixed this round** | 30 messages/minute per sender, enforced in the database |
| 6 | Message someone who chose "I'll message first" | **Blocked** | App + `0009` trigger |
| 7 | Send photos / call against someone's comfort rules | **Blocked** | App + `0008` triggers (lifted only after a confirmed in-person meeting) |
| 8 | Self-grant verified badge, Plus, admin, or un-ban yourself | **Blocked** | Verification/entitlements are service-role only; `guard_profiles` |
| 9 | Fake match (skip the mutual like) | **Blocked** | Matches are created only by the like trigger |
| 10 | Set your own Decompress price / overbook | **Blocked** | `0007` booking trigger sets price, commission and capacity |
| 11 | Run up our AI bill | **Limited** | Per-user 20 calls/min + 8 KB request cap (`ai-proxy`) |
| 12 | Call scheduled jobs (expire matches, SLA) | **Blocked** | `JOB_SECRET` header on every job function |
| 13 | Message after being blocked | **Blocked** | `is_blocked_pair` in the send policy |
| 14 | Steal data from a lost phone | **Reduced** | App lock (biometric), no cloud backups (`allowBackup=false`), FLAG_SECURE in Vanish |
| 15 | Fake accounts / bot farms / romance scams | **Reduced** | 21+ ID + liveness + photo match; Scam Shield; human report queue (24 h) |
| 16 | Secrets in the app binary | **None found** | Only the public anon key ships; model + vendor keys are server-only |
| 17 | Mock/sample people in a store build | **Blocked** | Release build refuses to start without real backend config |

## 2. Residual risks (be honest; fix before scale)

- **Private notes and reflections are stored on-device in plain app storage**
  in demo mode. They are sandboxed and never backed up, but a rooted phone
  could read them. Live mode must store them server-side (`private_notes`,
  `private_reflections`, owner-only RLS). Optionally add encrypted storage.
- **"Daytime first meet" is enforced only in the app** (plans store a time
  label). Add `plans.starts_at timestamptz` and a trigger.
- **Game answers** (`game_sessions`) are writable by either participant;
  low impact (a game), but should get a per-player answer column.
- **Auth abuse** (password guessing, SMS pumping): turn on Supabase Auth
  CAPTCHA (Turnstile/hCaptcha) and SMS rate limits; prefer passkeys/OTP.
- **Moderation of free-text** (bio, "topics I love"): run through the same
  pre-screen as media before showing to matches.
- **Pen test**: book an external test before public launch (this review is
  automated + manual, not a substitute).

## 3. Privacy commitments (keep these true)

AI never chats as a person; drafts only. No attractiveness scores. Reflections
and notes are owner-only. Location is a band, never a point. Analytics stay
on-device unless the member opts in. Account deletion removes data (sealed
safety records only as long as law requires).

## 4. Will it scale to millions? (plan by stage)

| Stage | Users | What changes |
|---|---|---|
| Pilot | ≤ 10k | Current stack as is: Supabase Pro, one Postgres, Edge Functions |
| City launch | 10k–250k | Read replicas for feeds; Realtime for chats; media on CDN with signed URLs; Cloudflare in front (WAF, DDoS, bot rules) |
| Multi-city | 250k–2M | Partition `messages` by month; move rate limits to the edge (KV token bucket); job queue for moderation/AI; per-city sharding of discovery |
| National+ | 2M–10M+ | Dedicated chat service (Postgres for history, a message broker for delivery), regional databases for data-residency, 24/7 trust & safety + on-call |

The data model already avoids the usual scaling traps: no global counters,
indexed per-sender and per-conversation lookups, server-set money and state,
and finite feeds (no infinite fan-out). The first real bottleneck will be chat
fan-out and media, not the database rules.
