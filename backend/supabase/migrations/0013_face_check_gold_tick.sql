-- 0013 Two levels of trust:
--   * Face-checked (live selfie passed at sign-up) = can use the app.
--   * Gold (government ID passed, 21+ confirmed) = the gold tick, and
--     gold profiles are shown first in Dates.
-- The 21+ floor itself stays in the schema (member_profiles.age >= 21).

-- One gate for every write that used to need the full ID badge.
create or replace function public.is_verified_member()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.verification_records v
    where v.user_id = auth.uid()
      and (v.liveness_result = 'passed' or v.badge_state = 'active'));
$$;

-- Events used the badge directly; same gate now.
drop policy if exists "events: verified members read" on public.events;
create policy "events: face-checked members read" on public.events
  for select using (public.is_verified_member());

-- Dates feed: face-checked viewers see face-checked people; `verified`
-- now means GOLD, and gold profiles come first.
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
  and (vr.liveness_result = 'passed' or vr.badge_state = 'active')
  and mp.user_id <> auth.uid()
  and public.is_verified_member()
  and not public.is_blocked_pair(mp.user_id, auth.uid())
  and public.meets(me.want_to_meet, mp.gender)
  and public.meets(mp.want_to_meet, me.gender)
-- ponytail: gold-first ordering lives in the view; a real ranker replaces it at scale.
order by (vr.badge_state = 'active') desc, mp.updated_at desc;
