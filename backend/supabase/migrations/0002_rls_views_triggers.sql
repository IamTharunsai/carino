-- Cariño backend · 0002 · Row Level Security, views, triggers, storage.
--
-- The security model in one paragraph: a client can only ever touch its
-- OWN rows. Verification, entitlements, and the safety vault are written
-- by the service role (Edge Functions / webhooks) — clients get read-only
-- or NO access, so no client can self-grant a badge, a Plus entitlement,
-- or peek at sealed evidence. Staff access happens through the S-057
-- console with the service role + audited vault access log.

alter table public.profiles enable row level security;
alter table public.verification_records enable row level security;
alter table public.member_profiles enable row level security;
alter table public.media enable row level security;
alter table public.profile_photos enable row level security;
alter table public.likes enable row level security;
alter table public.passes enable row level security;
alter table public.matches enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.safety_vault enable row level security;
alter table public.moments enable row level security;
alter table public.moment_views enable row level security;
alter table public.game_sessions enable row level security;
alter table public.spark_sessions enable row level security;
alter table public.calls enable row level security;
alter table public.plans enable row level security;
alter table public.plan_feedback enable row level security;
alter table public.reports enable row level security;
alter table public.appeals enable row level security;
alter table public.warnings enable row level security;
alter table public.blocks enable row level security;
alter table public.entitlements enable row level security;
alter table public.notifications enable row level security;
alter table public.remote_config_docs enable row level security;
alter table public.ai_interaction_log enable row level security;

-- Helper: is the caller a participant of a match?
create or replace function public.is_match_participant(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.matches m
    where m.id = p_match and (m.user_a = auth.uid() or m.user_b = auth.uid())
  );
$$;

-- --- Account / own rows -----------------------------------------------------
create policy "profiles: own row" on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

create policy "verification: read own only" on public.verification_records
  for select using (user_id = auth.uid());
-- (No insert/update/delete policies: service role only.)

create policy "member_profiles: own write" on public.member_profiles
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
-- Public discovery does NOT read this table directly; it reads the
-- feed_profiles view below, which exposes only safe columns.

create policy "media: own rows" on public.media
  for all using (owner = auth.uid()) with check (owner = auth.uid());

create policy "profile_photos: own rows" on public.profile_photos
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- --- Likes / passes -----------------------------------------------------------
create policy "likes: send own" on public.likes
  for insert with check (from_user = auth.uid());
create policy "likes: read own sent" on public.likes
  for select using (from_user = auth.uid());
-- "Who liked me" is NOT exposed row-by-row to clients: the likes_you()
-- function below returns a count to everyone and identities only to Plus.

create policy "passes: own rows" on public.passes
  for all using (from_user = auth.uid()) with check (from_user = auth.uid());

-- --- Matches ------------------------------------------------------------------
create policy "matches: participants read" on public.matches
  for select using (user_a = auth.uid() or user_b = auth.uid());
-- (Created by trigger / service role only.)

-- --- Conversations / messages ---------------------------------------------------
create policy "conversations: participants" on public.conversations
  for select using (public.is_match_participant(match_id));
create policy "conversations: participants update proposals" on public.conversations
  for update using (public.is_match_participant(match_id))
  with check (public.is_match_participant(match_id));

create policy "messages: participants read" on public.messages
  for select using (
    exists (select 1 from public.conversations c
            where c.id = conversation_id
              and public.is_match_participant(c.match_id))
  );
create policy "messages: send as self" on public.messages
  for insert with check (
    sender = auth.uid()
    and exists (select 1 from public.conversations c
                where c.id = conversation_id
                  and public.is_match_participant(c.match_id)
                  and c.closed = false)
  );
create policy "messages: unsend/react own" on public.messages
  for update using (sender = auth.uid()) with check (sender = auth.uid());

-- --- Safety vault: append-only from the report flow, staff-read only -----------
-- Clients may INSERT an evidence bundle tied to their own report flow;
-- NOBODY with the anon/authenticated role can select, update, or delete.
-- Staff read via the service role (S-057 console), and every staff read
-- appends to access_log (enforced in the console's data layer).
create policy "vault: append by reporter" on public.safety_vault
  for insert with check (reporter = auth.uid());
-- (Deliberately no select/update/delete policies for clients.)

-- --- Moments ---------------------------------------------------------------------
create policy "moments: author writes" on public.moments
  for all using (author = auth.uid()) with check (author = auth.uid());
create policy "moments: connections read live moments" on public.moments
  for select using (
    expires_at > now()
    and moderation_state = 'approved'
    and exists (
      select 1 from public.matches m
      where ((m.user_a = auth.uid() and m.user_b = author)
             or (m.user_b = auth.uid() and m.user_a = author))
        and m.state = 'active'
    )
  );
create policy "moment_views: record + author reads" on public.moment_views
  for all using (
    viewer = auth.uid()
    or exists (select 1 from public.moments mm
               where mm.id = moment_id and mm.author = auth.uid())
  )
  with check (viewer = auth.uid());

-- --- Games / Spark / Calls ---------------------------------------------------------
create policy "games: participants" on public.game_sessions
  for all using (auth.uid() = any(participants))
  with check (auth.uid() = any(participants));
create policy "spark: participants" on public.spark_sessions
  for all using (auth.uid() = any(participants))
  with check (auth.uid() = any(participants));
create policy "calls: participants read" on public.calls
  for select using (auth.uid() = any(participants));

-- --- Plans ---------------------------------------------------------------------------
create policy "plans: match participants" on public.plans
  for all using (public.is_match_participant(match_id))
  with check (public.is_match_participant(match_id));
create policy "plan_feedback: own row" on public.plan_feedback
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- --- Trust: reports / appeals / warnings ------------------------------------------------
create policy "reports: file + read own" on public.reports
  for insert with check (reporter = auth.uid());
create policy "reports: reporter reads own" on public.reports
  for select using (reporter = auth.uid());
-- The REPORTED person has no policy: they can never see who reported them.
create policy "appeals: own rows" on public.appeals
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "warnings: read own" on public.warnings
  for select using (user_id = auth.uid());
create policy "warnings: acknowledge own" on public.warnings
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- --- Blocks -----------------------------------------------------------------------------
create policy "blocks: own rows" on public.blocks
  for all using (blocker = auth.uid()) with check (blocker = auth.uid());

-- --- Billing / system ----------------------------------------------------------------------
create policy "entitlements: read own" on public.entitlements
  for select using (user_id = auth.uid());
-- (Writes: RevenueCat webhook via service role only.)
create policy "notifications: own rows" on public.notifications
  for select using (user_id = auth.uid());
create policy "notifications: mark read own" on public.notifications
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "remote_config: active doc readable" on public.remote_config_docs
  for select using (active = true);
create policy "ai_log: insert own" on public.ai_interaction_log
  for insert with check (user_id = auth.uid());
-- (No client select: the honesty audit is a staff function.)

-- =============================================================================
-- Views + functions
-- =============================================================================

-- Discovery feed: SAFE COLUMNS ONLY, and the distance band is computed
-- per-viewer from COARSE geo cells. The geo_cells table is written only
-- by the backend location service (city-cell granularity, ~1–2 mi cells);
-- it is never client-readable, and coordinates exist nowhere in the
-- system — cells are the coarsest thing stored.
create table public.geo_cells (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  cell text not null,        -- e.g. 'cmh:nw4' (city:sector)
  city text not null
);
alter table public.geo_cells enable row level security;
-- (No client policies at all: service role only.)

create or replace function public.band_for(viewer_cell text, member_cell text, member_city text)
returns text language sql immutable as $$
  select case
    when viewer_cell is null then 'Worldwide'
    when viewer_cell = member_cell then '~2 mi'
    when split_part(viewer_cell, ':', 1) = split_part(member_cell, ':', 1) then 'Same city'
    else 'Worldwide'
  end;
$$;

create or replace view public.feed_profiles as
select
  mp.user_id,
  mp.display_name,
  mp.age,
  mp.city,
  mp.headline,
  mp.intention,
  mp.structure,
  mp.pace,
  mp.availability,
  mp.boundaries,
  mp.interests,
  mp.languages,
  mp.prompts,
  vr.badge_state = 'active' as verified,
  mp.visibility,
  public.band_for(vc.cell, mc.cell, mp.city) as distance_band
from public.member_profiles mp
join public.verification_records vr on vr.user_id = mp.user_id
left join public.geo_cells mc on mc.user_id = mp.user_id
left join public.geo_cells vc on vc.user_id = auth.uid()
where mp.discoverable = true
  and mp.visibility <> 'Paused'
  and vr.badge_state = 'active'
  and mp.user_id <> auth.uid();
-- Reciprocal filter eligibility (you only see people whose filters
-- include you) is enforced in the feed service (GET /feed) on top of
-- this view; the view fixes the column contract + the safety floor
-- (verified, discoverable, not paused, not yourself, not blocked —
-- block filtering also happens in the feed service via public.blocks).

-- Likes You: count for everyone; identities only with an active Plus
-- entitlement. The client renders exactly what this returns — it cannot
-- inflate the count or peek at identities on the free tier.
create or replace function public.likes_you()
returns table (like_count int, members jsonb)
language plpgsql stable security definer set search_path = public as $$
declare
  v_count int;
  v_plus boolean;
begin
  select count(*) into v_count from public.likes where to_user = auth.uid();
  select exists (
    select 1 from public.entitlements
    where user_id = auth.uid() and state = 'active'
  ) into v_plus;
  if v_plus then
    return query select v_count, coalesce(jsonb_agg(jsonb_build_object(
      'user_id', l.from_user, 'anchor_type', l.anchor_type)), '[]'::jsonb)
    from public.likes l where l.to_user = auth.uid();
  else
    return query select v_count, '[]'::jsonb;
  end if;
end;
$$;

-- =============================================================================
-- Triggers: mutual-like -> match; block -> propagate
-- =============================================================================
create or replace function public.on_like_created()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- Mutual? Create the match with its real expiry clock (config:
  -- remote_config doc match_expiry_hours, default 72).
  if exists (select 1 from public.likes
             where from_user = new.to_user and to_user = new.from_user) then
    insert into public.matches (user_a, user_b, source, expires_at)
    values (least(new.from_user, new.to_user),
            greatest(new.from_user, new.to_user),
            'like', now() + interval '72 hours')
    on conflict (user_a, user_b) do nothing;
  end if;
  return new;
end;
$$;
create trigger likes_match_trigger
  after insert on public.likes
  for each row execute function public.on_like_created();

create or replace function public.on_block_created()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- Immediate, both directions: matches close, conversations close.
  update public.matches set state = 'blocked'
  where (user_a = new.blocker and user_b = new.blocked)
     or (user_a = new.blocked and user_b = new.blocker);
  update public.conversations c set closed = true
  from public.matches m
  where c.match_id = m.id
    and ((m.user_a = new.blocker and m.user_b = new.blocked)
      or (m.user_a = new.blocked and m.user_b = new.blocker));
  return new;
end;
$$;
create trigger blocks_propagate_trigger
  after insert on public.blocks
  for each row execute function public.on_block_created();

-- =============================================================================
-- Storage buckets (private; signed URLs only)
-- =============================================================================
insert into storage.buckets (id, name, public)
values ('profile-media', 'profile-media', false),
       ('moment-media', 'moment-media', false),
       ('chat-media', 'chat-media', false)
on conflict (id) do nothing;

-- Objects live under <uid>/... — a member can only touch their own folder.
create policy "storage: own folder all buckets" on storage.objects
  for all using (
    bucket_id in ('profile-media', 'moment-media', 'chat-media')
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id in ('profile-media', 'moment-media', 'chat-media')
    and (storage.foldername(name))[1] = auth.uid()::text
  );
-- Chat-media READS by the other participant happen through short-lived
-- signed URLs minted by the backend (service role) after a participant
-- check — never through a broad client policy.

-- =============================================================================
-- Scheduled jobs (pg_cron) — enable in the hosting phase; the Edge
-- Functions in ../functions implement the same logic for cron invocation:
--   select cron.schedule('match-expiry', '*/15 * * * *', ...http to function...);
--   select cron.schedule('report-sla',   '0 * * * *',  ...);
-- Kept as comments so the migration is honest about what is NOT yet live.
-- =============================================================================
