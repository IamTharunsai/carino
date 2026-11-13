# Cariño backend — Supabase (config-ready, no live project yet)

Everything here is code, ready to deploy the moment the hosting phase
creates the Supabase project. Nothing in this folder contains real keys.

## Layout

```
backend/
  README.md                     <- this file
  supabase/
    config.toml                 <- project config (local dev defaults)
    seed_remote_config.sql      <- remote-config v1 = the client's compiled defaults
    migrations/
      0001_schema.sql           <- all DATA & API entities (21 tables)
      0002_rls_views_triggers.sql
                                <- RLS on every table, feed_profiles view,
                                   likes_you(), mutual-like + block triggers,
                                   geo_cells + band function, storage buckets
    functions/
      ai-proxy/                 <- Claude/GPT gateway (keys server-side, drafts only)
      moderation-intake/        <- media pre-screen (AI-05), human-held by default
      match-expiry/             <- scheduled: match archive, moment deletion, vanish dissolve
      report-sla/               <- scheduled: 24h SLA watch + escalation counts
      remote-config/            <- serves the active config document
      verification-session/     <- opens IDV vendor session (vendor = D-01)
```

## Security model (mirrors 0002)

- Clients touch only their own rows (RLS everywhere).
- `verification_records`, `entitlements`: service-role writes only — no
  client can self-grant a badge or Plus.
- `safety_vault`: clients may only INSERT (append) via their report flow;
  no client SELECT/UPDATE/DELETE exists. Staff read via the S-057 console
  with the service role; reads append to `access_log`.
- `feed_profiles`: a view exposing safe columns only; distance is a BAND
  computed from coarse geo cells — coordinates are stored nowhere.
- `likes_you()`: count for everyone, identities only for active Plus.
- Storage buckets are private; objects live under `<uid>/…`; cross-member
  chat media is served by short-lived signed URLs minted server-side.

## Deploy (hosting phase — Lovely's accounts)

1. Create the Supabase project; link this folder (`supabase link`).
2. `supabase db push` (runs 0001 + 0002), then run
   `seed_remote_config.sql`.
3. `supabase functions deploy` for all six functions.
4. Set function secrets: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`,
   `IDV_VENDOR` (+ vendor keys), screening-provider key.
5. Schedule `match-expiry` (15 min) and `report-sla` (hourly) — pg_cron
   snippets are commented at the end of migration 0002.
6. Build the app with
   `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`
   (see the app's `.env.example`). Without defines, the app runs in mock
   mode and none of this is touched.

## What is deliberately NOT here yet (hosting-phase contracts)

- IDV vendor SDK session creation (D-01) — `verification-session` returns
  a marked pending session until the vendor is chosen.
- RTC room minting for Spark (D-02) — `spark_sessions.rtc_room_ref` is
  minted by the (future) spark-token function once the provider is picked.
- RevenueCat webhook → `entitlements` writer.
- APNs/FCM push sender (reads `notifications`).
- S-057 staff console (separate internal web app).
