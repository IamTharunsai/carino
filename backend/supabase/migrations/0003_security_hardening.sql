-- =============================================================================
-- 0003 — Security hardening (pre-launch review findings)
-- Clients (anon/authenticated) can no longer write server-owned columns;
-- service role, definer functions and triggers are unaffected.
-- =============================================================================

-- True when the statement comes straight from a PostgREST client role.
-- Inside security-definer functions current_user is the owner, so the
-- block/match triggers and Edge Functions (service_role) bypass the guards.
create or replace function public.is_client()
returns boolean language sql stable set search_path = public as $$
  select current_user in ('anon', 'authenticated');
$$;

create or replace function public.is_blocked_pair(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.blocks
                 where (blocker = a and blocked = b) or (blocker = b and blocked = a));
$$;

alter function public.band_for(text, text, text) set search_path = public;

-- --- 1. Profile row for every new auth user ----------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, phone, email, auth_method)
  values (new.id, new.phone, new.email,
          case when new.phone is not null and new.phone <> '' then 'phone' else 'email' end)
  on conflict (id) do nothing;
  insert into public.verification_records (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- --- 2. Server-owned columns are immutable for clients -----------------------
create or replace function public.guard_profiles()
returns trigger language plpgsql set search_path = public as $$
begin
  if public.is_client() then
    if tg_op = 'INSERT' then
      new.account_status := 'active';
      new.dob_verified_flag := false;
    else
      new.id := old.id;
      new.account_status := old.account_status;
      new.dob_verified_flag := old.dob_verified_flag;
      new.created_at := old.created_at;
    end if;
  end if;
  return new;
end;
$$;
create trigger guard_profiles before insert or update on public.profiles
  for each row execute function public.guard_profiles();

-- Media + Moments: moderation is the server's call; Moments live 24h max.
create or replace function public.guard_moderated()
returns trigger language plpgsql set search_path = public as $$
begin
  if public.is_client() then
    if tg_op = 'INSERT' then
      new.moderation_state := 'pending';
    else
      new.moderation_state := old.moderation_state;
    end if;
    if tg_table_name = 'moments' then
      new.created_at := coalesce(old.created_at, now());
      new.expires_at := least(new.expires_at, new.created_at + interval '24 hours');
    end if;
  end if;
  return new;
end;
$$;
create trigger guard_media before insert or update on public.media
  for each row execute function public.guard_moderated();
create trigger guard_moments before insert or update on public.moments
  for each row execute function public.guard_moderated();

-- Reports: clients file them; status/SLA/action are staff-owned.
create or replace function public.guard_reports()
returns trigger language plpgsql set search_path = public as $$
begin
  if public.is_client() then
    new.status := 'new';
    new.sla_due := now() + interval '24 hours';
    new.action := null;
  end if;
  return new;
end;
$$;
create trigger guard_reports before insert on public.reports
  for each row execute function public.guard_reports();

-- Appeals: file + read only; outcome is staff-owned.
drop policy "appeals: own rows" on public.appeals;
create policy "appeals: file own" on public.appeals
  for insert with check (user_id = auth.uid() and status = 'open');
create policy "appeals: read own" on public.appeals
  for select using (user_id = auth.uid());

-- Warnings: a member may only acknowledge or appeal.
create or replace function public.guard_warnings()
returns trigger language plpgsql set search_path = public as $$
begin
  if public.is_client() then
    if new.state not in ('acknowledged', 'appealed') then
      raise exception 'warnings: members may only acknowledge or appeal';
    end if;
    new.user_id := old.user_id;
    new.case_ref := old.case_ref;
    new.reason := old.reason;
    new.created_at := old.created_at;
  end if;
  return new;
end;
$$;
create trigger guard_warnings before update on public.warnings
  for each row execute function public.guard_warnings();

-- --- 3. Safety vault: truly append-only --------------------------------------
create or replace function public.guard_vault()
returns trigger language plpgsql set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'safety_vault is append-only';
  end if;
  if tg_op = 'INSERT' then
    if public.is_client() then
      new.access_log := '[]'::jsonb;
      new.retention_until := now() + interval '180 days';  -- ponytail: policy value, move to remote config if legal changes it
    end if;
    return new;
  end if;
  -- UPDATE (service role only — no client policy exists): only access_log may grow.
  if new.report_id is distinct from old.report_id and old.report_id is not null
     or new.reporter is distinct from old.reporter
     or new.retained_items_refs is distinct from old.retained_items_refs
     or new.created_at is distinct from old.created_at then
    raise exception 'safety_vault rows are sealed';
  end if;
  return new;
end;
$$;
create trigger guard_vault before insert or update or delete on public.safety_vault
  for each row execute function public.guard_vault();

-- --- 4. Conversations: created per match, never reopened by a client --------
drop policy "conversations: participants update proposals" on public.conversations;
-- ponytail: Keep<->Vanish proposals need a definer RPC (propose/accept) before
-- the mode switch goes live; until then conversations are read-only to clients.

create or replace function public.on_match_created()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.conversations (match_id) values (new.id);
  return new;
end;
$$;
create trigger matches_conversation_trigger
  after insert on public.matches
  for each row execute function public.on_match_created();

-- --- 5. Messages ------------------------------------------------------------
drop policy "messages: send as self" on public.messages;
create policy "messages: send as self" on public.messages
  for insert with check (
    sender = auth.uid()
    and exists (
      select 1 from public.conversations c
      join public.matches m on m.id = c.match_id
      where c.id = conversation_id
        and c.closed = false
        and m.state = 'active'
        and (m.user_a = auth.uid() or m.user_b = auth.uid())
        and not public.is_blocked_pair(m.user_a, m.user_b)
    )
  );

drop policy "messages: participants read" on public.messages;
create policy "messages: participants read" on public.messages
  for select using (
    dissolved_at is null
    and exists (select 1 from public.conversations c
                where c.id = conversation_id
                  and public.is_match_participant(c.match_id))
  );

-- Senders may only unsend / react; content and routing are immutable.
create or replace function public.guard_messages()
returns trigger language plpgsql set search_path = public as $$
begin
  if public.is_client() then
    new.conversation_id := old.conversation_id;
    new.sender := old.sender;
    new.kind := old.kind;
    new.body := case when new.unsent_at is not null then null else old.body end;
    new.media_id := case when new.unsent_at is not null then null else old.media_id end;
    new.view_once := old.view_once;
    new.view_once_consumed_at := old.view_once_consumed_at;
    new.expires_at := old.expires_at;
    new.dissolved_at := old.dissolved_at;
    new.is_system_notice := old.is_system_notice;
    new.created_at := old.created_at;
  end if;
  return new;
end;
$$;
create trigger guard_messages before update on public.messages
  for each row execute function public.guard_messages();

-- --- 6. Likes never cross a block; matches never form across one ------------
drop policy "likes: send own" on public.likes;
create policy "likes: send own" on public.likes
  for insert with check (from_user = auth.uid()
                         and not public.is_blocked_pair(from_user, to_user));

create or replace function public.on_like_created()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_blocked_pair(new.from_user, new.to_user) then
    return new;
  end if;
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

-- --- 7. Spark: acceptance + room tokens are server-minted --------------------
create or replace function public.guard_spark()
returns trigger language plpgsql set search_path = public as $$
begin
  if public.is_client() then
    if tg_op = 'INSERT' then
      new.accept_state := 'invited';
      new.rtc_room_ref := null;
    else
      new.participants := old.participants;
      new.accept_state := old.accept_state;
      new.rtc_room_ref := old.rtc_room_ref;
    end if;
  end if;
  return new;
end;
$$;
create trigger guard_spark before insert or update on public.spark_sessions
  for each row execute function public.guard_spark();
-- ponytail: post_call_choices / game answers are still readable by the other
-- participant; move them to a per-user table before the Spark/Games beta.

-- --- 8. Feed: only verified viewers, never across a block, never Incognito ----
create or replace view public.feed_profiles as
select
  mp.user_id, mp.display_name, mp.age, mp.city, mp.headline, mp.intention,
  mp.structure, mp.pace, mp.availability, mp.boundaries, mp.interests,
  mp.languages, mp.prompts,
  vr.badge_state = 'active' as verified,
  mp.visibility,
  public.band_for(vc.cell, mc.cell, mp.city) as distance_band
from public.member_profiles mp
join public.verification_records vr on vr.user_id = mp.user_id
left join public.geo_cells mc on mc.user_id = mp.user_id
left join public.geo_cells vc on vc.user_id = auth.uid()
where mp.discoverable = true
  and mp.visibility = 'Discovery'
  and vr.badge_state = 'active'
  and mp.user_id <> auth.uid()
  and exists (select 1 from public.verification_records me
              where me.user_id = auth.uid() and me.badge_state = 'active')
  and not public.is_blocked_pair(mp.user_id, auth.uid());
