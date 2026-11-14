-- 0004 Experience bundle: identity + inclusion, soundtrack, taste quiz,
-- Moment stickers, events, date check-in, wingperson.
-- Every new table is own-row RLS unless stated; nothing here widens what
-- another member can read about you.

-- --- 1. Identity (S-008A) on member_profiles --------------------------------
alter table public.member_profiles
  add column gender text[] not null default '{}',
  add column pronouns text not null default '',
  add column orientation text not null default '',
  add column want_to_meet text[] not null default '{}',           -- empty = everyone
  -- field -> everyone|matches|hidden. Hidden fields still drive matching.
  add column identity_visibility jsonb not null
    default '{"gender":"everyone","pronouns":"everyone","orientation":"matches"}',
  add column access_note text not null default '' check (char_length(access_note) <= 80),
  add column taste_answers jsonb not null default '{}',
  add column anthem text,
  add column top_artists text[] not null default '{}',
  add column highlight_moment_ids uuid[] not null default '{}'
    check (cardinality(highlight_moment_ids) <= 3);

-- Bucket used by the reciprocal "I want to meet" rule (mirrors
-- lib/models/experience.dart wantsToMeet): trans women -> Women, trans men
-- -> Men, everything else outside Woman/Man -> Non-binary people.
create or replace function public.meets(want text[], gender text[])
returns boolean language sql immutable as $$
  select cardinality(want) = 0 or cardinality(gender) = 0 or exists (
    select 1 from unnest(gender) g
    where (case
             when g in ('Woman', 'Trans woman') then 'Women'
             when g in ('Man', 'Trans man') then 'Men'
             else 'Non-binary people'
           end) = any (want)
  );
$$;

-- Feed: same safety floor as 0003, plus reciprocal fit, plus identity
-- columns masked by the member's own visibility choice. (Discovery is
-- never a match, so only 'everyone' fields are exposed here; matches read
-- 'matches' fields through match-scoped endpoints.)
create or replace view public.feed_profiles as
select
  mp.user_id, mp.display_name, mp.age, mp.city, mp.headline, mp.intention,
  mp.structure, mp.pace, mp.availability, mp.boundaries, mp.interests,
  mp.languages, mp.prompts,
  vr.badge_state = 'active' as verified,
  mp.visibility,
  public.band_for(vc.cell, mc.cell, mp.city) as distance_band,
  case when mp.identity_visibility->>'gender' = 'everyone' then mp.gender end as gender,
  case when coalesce(mp.identity_visibility->>'pronouns', 'everyone') = 'everyone'
       then mp.pronouns end as pronouns,
  case when mp.identity_visibility->>'orientation' = 'everyone' then mp.orientation end as orientation,
  mp.access_note, mp.taste_answers, mp.anthem, mp.top_artists
from public.member_profiles mp
join public.verification_records vr on vr.user_id = mp.user_id
join public.member_profiles me on me.user_id = auth.uid()
left join public.geo_cells mc on mc.user_id = mp.user_id
left join public.geo_cells vc on vc.user_id = auth.uid()
where mp.discoverable = true
  and mp.visibility = 'Discovery'
  and vr.badge_state = 'active'
  and mp.user_id <> auth.uid()
  and exists (select 1 from public.verification_records mv
              where mv.user_id = auth.uid() and mv.badge_state = 'active')
  and not public.is_blocked_pair(mp.user_id, auth.uid())
  and public.meets(me.want_to_meet, mp.gender)
  and public.meets(mp.want_to_meet, me.gender);

-- --- 2. Moment stickers -------------------------------------------------------
alter table public.moments
  add column sticker jsonb;  -- {kind: poll|ask_me|this_or_that, question, options[]}

-- Answers go privately to the poster. No public tally exists anywhere.
create table public.moment_sticker_answers (
  moment_id uuid not null references public.moments (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  answer text not null check (char_length(answer) between 1 and 200),
  created_at timestamptz not null default now(),
  primary key (moment_id, user_id)
);
alter table public.moment_sticker_answers enable row level security;
create policy "sticker answers: answer as yourself" on public.moment_sticker_answers
  for insert with check (user_id = auth.uid());
create policy "sticker answers: you or the poster read" on public.moment_sticker_answers
  for select using (
    user_id = auth.uid()
    or exists (select 1 from public.moments m
               where m.id = moment_id and m.author = auth.uid()));

-- --- 3. Events Near You ---------------------------------------------------------
create table public.events (
  id uuid primary key default gen_random_uuid(),
  city text not null,
  title text not null,
  venue_type text not null,              -- public venue TYPE, never an address
  starts_at timestamptz not null,
  category text not null,
  step_free boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.events enable row level security;
create policy "events: verified members read" on public.events
  for select using (exists (select 1 from public.verification_records v
                            where v.user_id = auth.uid() and v.badge_state = 'active'));
-- (Writes: service role / staff console only.)

create table public.event_rsvps (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);
alter table public.event_rsvps enable row level security;
create policy "event_rsvps: own write" on public.event_rsvps
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
-- "Aria is going" is visible to MATCHES only, never strangers.
create policy "event_rsvps: matches read" on public.event_rsvps
  for select using (exists (
    select 1 from public.matches m
    where (m.user_a = auth.uid() and m.user_b = user_id)
       or (m.user_b = auth.uid() and m.user_a = user_id)));

-- --- 4. Date check-in + trusted contact (free forever) -------------------------
create table public.trusted_contacts (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  phone text not null check (phone ~ '^[+0-9 ()-]{7,20}$'),
  updated_at timestamptz not null default now()
);
alter table public.trusted_contacts enable row level security;
create policy "trusted_contacts: own row" on public.trusted_contacts
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create table public.plan_check_ins (
  plan_id uuid not null references public.plans (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  check_at timestamptz not null,
  state text not null default 'active',  -- active|safe|missed|help
  created_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);
alter table public.plan_check_ins enable row level security;
create policy "plan_check_ins: own row" on public.plan_check_ins
  for all using (user_id = auth.uid() and public.is_match_participant(
                   (select p.match_id from public.plans p where p.id = plan_id)))
  with check (user_id = auth.uid());
-- ponytail: the missed-check-in SMS is a scheduled Edge Function (service
-- role) reading state='active' rows past check_at + 15 min; add it with the
-- SMS vendor in the hosting phase.

-- --- 5. Wingperson -------------------------------------------------------------
create table public.wingperson_invites (
  owner uuid primary key references public.profiles (id) on delete cascade,
  -- gen_random_uuid is core in PG13+, so no extension-schema lookup needed.
  token text not null unique default replace(gen_random_uuid()::text, '-', ''),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.wingperson_invites enable row level security;
create policy "wingperson: own row" on public.wingperson_invites
  for all using (owner = auth.uid()) with check (owner = auth.uid());
-- The friend never gets table access: a token-checked Edge Function serves
-- ONLY the owner's Daily Drop cards and records suggestions.
