-- Cariño backend · 0001 · core schema
-- Implements the blueprint DATA & API sheet entities on Postgres (Supabase).
-- Conventions:
--   * All timestamps timestamptz, UTC. All "timers" the product promises
--     (match expiry, Vanish, Moment 24h, Spark windows, view-once) are
--     SERVER-authoritative: the columns below are the single source of
--     truth; clients only render what the server states.
--   * auth.users holds credentials (Supabase Auth: passkey / phone OTP /
--     email). public.profiles is the member record, 1:1 with auth.users.
--   * No coordinates anywhere. Distance is computed in the feed view and
--     returned as a BAND string only.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- User / Account (DATA & API: User/Account)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  auth_method text not null default 'phone',           -- passkey|phone|email
  phone text,
  email text,
  -- DOB itself is NOT stored beyond policy need: the verification provider
  -- returns age21_result; dob_verified_flag records that a DOB was checked.
  dob_verified_flag boolean not null default false,
  account_status text not null default 'active',       -- active|paused|restricted|deleted
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Verification (DATA & API: Verification) — three layers, one row per user.
-- Written ONLY by the verification-session Edge Function / provider webhook
-- (service role). Clients can read their own row, never write it: a client
-- must never be able to self-grant a badge.
-- ---------------------------------------------------------------------------
create table public.verification_records (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  provider text not null default 'pending-vendor',     -- D-01 OPEN DECISION
  provider_ref text,
  age21_result text not null default 'not_started',    -- not_started|pending|passed|failed
  liveness_result text not null default 'not_started',
  photo_match_result text not null default 'not_started',
  badge_state text not null default 'none',            -- none|active|suspended
  appeal_state text not null default 'none',           -- none|open|upheld|overturned
  failure_category text,                               -- plain category shown on S-007
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Profile (DATA & API: Profile) — the public-facing member shape.
-- ---------------------------------------------------------------------------
create table public.member_profiles (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  display_name text not null,
  age int not null check (age >= 21),                  -- the 21+ floor, in the schema
  city text not null,
  headline text not null default '',
  intention text not null,                             -- tonight|casual_dating|long_term|hangout_and_play|still_exploring
  structure text not null default 'Monogamy',
  pace text not null default 'Chat first',
  availability text not null default 'This week',
  boundaries text not null default '',
  interests text[] not null default '{}',
  languages text[] not null default '{English}',
  prompts jsonb not null default '[]',                 -- [{question, answer}]
  video_intro_id uuid,
  voice_intro_id uuid,
  visibility text not null default 'Discovery',        -- Discovery|Incognito|Paused
  show_activity boolean not null default false,
  exclude_contacts boolean not null default true,
  generic_previews boolean not null default true,
  discoverable boolean not null default true,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Media (DATA & API: Media) — EXIF stripped at upload; moderation before
-- distribution; signed URLs only (storage buckets are private).
-- ---------------------------------------------------------------------------
create table public.media (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null references public.profiles (id) on delete cascade,
  kind text not null,                                  -- photo|video_intro|voice_intro|moment|chat
  bucket text not null,
  object_path text not null,
  moderation_state text not null default 'pending',    -- pending|approved|held|rejected
  captions text,                                       -- required for video before publish
  created_at timestamptz not null default now()
);

create table public.profile_photos (
  user_id uuid not null references public.profiles (id) on delete cascade,
  media_id uuid not null references public.media (id) on delete cascade,
  position int not null check (position between 0 and 5),
  primary key (user_id, position)
);

-- ---------------------------------------------------------------------------
-- Like / Pass (DATA & API: Like/Reaction)
-- ---------------------------------------------------------------------------
create table public.likes (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.profiles (id) on delete cascade,
  to_user uuid not null references public.profiles (id) on delete cascade,
  anchor_type text not null default 'profile',         -- profile|photo|prompt|moment|video
  anchor_id text,
  created_at timestamptz not null default now(),
  unique (from_user, to_user, anchor_type, anchor_id)
);

create table public.passes (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.profiles (id) on delete cascade,
  to_user uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (from_user, to_user)
);

-- ---------------------------------------------------------------------------
-- Match (DATA & API: Match) — created by trigger on mutual like, or by a
-- mutual Spark Connect choice. Expiry is a real server clock (REA §5.1).
-- ---------------------------------------------------------------------------
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  source text not null default 'like',                 -- like|spark
  state text not null default 'active',                -- active|archived|blocked|closed
  created_at timestamptz not null default now(),
  expires_at timestamptz,                              -- set while unmessaged
  unique (user_a, user_b),
  check (user_a < user_b)
);

-- ---------------------------------------------------------------------------
-- Conversation + Message (DATA & API) — mode changes are proposals until
-- BOTH accept (mode_proposal_*), and prospective only.
-- ---------------------------------------------------------------------------
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches (id) on delete cascade,
  mode text not null default 'keep',                   -- keep|vanish
  vanish_minutes int not null default 60,              -- 0 = after read
  mode_proposal_state text not null default 'none',    -- none|pending|accepted|declined
  mode_proposal_by uuid references public.profiles (id),
  closed boolean not null default false,               -- set by block
  created_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender uuid not null references public.profiles (id) on delete cascade,
  kind text not null default 'text',                   -- text|voice|photo|video|game|system
  body text,
  media_id uuid references public.media (id),
  view_once boolean not null default false,
  view_once_consumed_at timestamptz,
  expires_at timestamptz,                              -- vanish: server-set on read
  dissolved_at timestamptz,                            -- vanish: set by job when timer ends
  unsent_at timestamptz,
  reaction text,
  is_system_notice boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Safety Vault (DATA & API) — sealed, report-only evidence copies.
-- Rows are written by the report flow (service role) and read by STAFF
-- only. Retention is bounded by retention_until; access is logged.
-- ---------------------------------------------------------------------------
create table public.safety_vault (
  id uuid primary key default gen_random_uuid(),
  report_id uuid,                                      -- linked on report creation
  reporter uuid references public.profiles (id),
  retained_items_refs jsonb not null default '[]',     -- message/media ids, sealed copies
  retention_until timestamptz not null,
  access_log jsonb not null default '[]',
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Moment (DATA & API) — 24h, real deletion job at expires_at.
-- ---------------------------------------------------------------------------
create table public.moments (
  id uuid primary key default gen_random_uuid(),
  author uuid not null references public.profiles (id) on delete cascade,
  media_id uuid references public.media (id),
  caption text not null default '',
  audience text not null default 'connections',        -- connections|matches_plus
  moderation_state text not null default 'pending',
  expires_at timestamptz not null default (now() + interval '24 hours'),
  created_at timestamptz not null default now()
);

create table public.moment_views (
  moment_id uuid not null references public.moments (id) on delete cascade,
  viewer uuid not null references public.profiles (id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (moment_id, viewer)
);

-- ---------------------------------------------------------------------------
-- Games / Spark / Calls (DATA & API)
-- ---------------------------------------------------------------------------
create table public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  game_type text not null,                             -- this_or_that|two_truths|guess_my_answer|build_our_date|music_match|question_cards
  participants uuid[] not null,
  state text not null default 'invited',               -- invited|active|revealed|closed
  answers jsonb not null default '{}',
  reveal_state text not null default 'waiting',        -- waiting|revealed
  flirty_deck_opt_in boolean not null default false,   -- double opt-in, stored
  created_at timestamptz not null default now()
);

create table public.spark_sessions (
  id uuid primary key default gen_random_uuid(),
  window_label text not null,
  participants uuid[] not null,
  accept_state text not null default 'invited',        -- invited|both_accepted|declined|expired
  rtc_room_ref text,                                   -- minted ONLY on both_accepted
  post_call_choices jsonb not null default '{}',       -- PRIVATE per-user choices
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

create table public.calls (
  id uuid primary key default gen_random_uuid(),
  spark_session_id uuid references public.spark_sessions (id),
  participants uuid[] not null,
  kind text not null default 'video',
  started_at timestamptz,
  ended_at timestamptz,
  quality_flags jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Plans + feedback (DATA & API)
-- ---------------------------------------------------------------------------
create table public.plans (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches (id) on delete cascade,
  proposed_by uuid not null references public.profiles (id),
  place_type text not null,                            -- public place TYPE only
  place_ref text,                                      -- public venue ref, never a home address
  time_label text not null,
  state text not null default 'proposed',              -- proposed|confirmed|changed|declined|cancelled|completed
  confirmations jsonb not null default '{}',           -- {user_id: true}
  check_ins jsonb not null default '{}',               -- {arrived: [...], home_safe: [...]}
  created_at timestamptz not null default now()
);

create table public.plan_feedback (
  plan_id uuid not null references public.plans (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  happened boolean,
  comfortable boolean,
  worthwhile boolean,
  comment text,
  report_link uuid,
  created_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Reports / Appeals / Warnings (DATA & API: Report/Case)
-- ---------------------------------------------------------------------------
create sequence public.case_ref_seq start 1000;

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  case_ref text not null unique
    default ('CN-' || to_char(now(), 'YYYY') || '-' || nextval('public.case_ref_seq')::text),
  reporter uuid not null references public.profiles (id) on delete cascade,
  reported uuid references public.profiles (id) on delete set null,
  category text not null,
  reason text not null,
  details text,
  surface text not null,
  evidence_refs jsonb not null default '[]',
  status text not null default 'new',                  -- new|in_review|actioned|closed_no_action
  sla_due timestamptz not null default (now() + interval '24 hours'),
  action text,
  created_at timestamptz not null default now()
);

create table public.appeals (
  id uuid primary key default gen_random_uuid(),
  appeal_ref text not null unique
    default ('CN-A-' || to_char(now(), 'YYYY') || '-' || nextval('public.case_ref_seq')::text),
  user_id uuid not null references public.profiles (id) on delete cascade,
  case_ref text,
  subject text not null,
  status text not null default 'open',                 -- open|upheld|overturned
  created_at timestamptz not null default now()
);

create table public.warnings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  case_ref text,
  reason text not null,
  state text not null default 'active',                -- active|acknowledged|appealed|expired
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Blocks (DATA & API) — immediate propagation via trigger (0002).
-- ---------------------------------------------------------------------------
create table public.blocks (
  blocker uuid not null references public.profiles (id) on delete cascade,
  blocked uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker, blocked)
);

-- ---------------------------------------------------------------------------
-- Entitlements / Notifications / Remote config / AI log (DATA & API)
-- ---------------------------------------------------------------------------
create table public.entitlements (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  product_id text,
  store_transaction_ref text,
  state text not null default 'free',                  -- free|active|grace|expired
  renews_at timestamptz,
  source text,                                         -- app_store|play_store (via RevenueCat)
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  category text not null,                              -- match|message|plan|drop|safety|system
  text text not null,
  deep_link text,
  read_state boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.remote_config_docs (
  version int primary key,
  doc jsonb not null,
  active boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.ai_interaction_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  feature text not null,                               -- AI-01..AI-07
  suggestion_id text,
  user_action text,                                    -- accepted|edited|dismissed
  model text,
  prompt_version text,
  created_at timestamptz not null default now()
  -- Note: message CONTENT is never logged here — suggestion metadata only.
);
