-- 0006 Social writes: real users can create friend groups, chat, run plan
-- polls and join guilds — with every rule enforced in the database, not the
-- app. Deploy after 0005. Still service-role only: friendships, trust edges,
-- vouches, intros, coffee matches, gifts, host tiers (they need bilateral
-- consent, store receipts or moderation).
begin;

-- Verified = active 3-layer badge. Only verified members create social rows.
create function public.is_verified_member()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.verification_records v
    where v.user_id = auth.uid() and v.badge_state = 'active');
$$;
revoke all on function public.is_verified_member() from public, anon;
grant execute on function public.is_verified_member() to authenticated;

create function public.are_friends(x uuid, y uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.friendships f
    where f.user_a = least(x, y) and f.user_b = greatest(x, y));
$$;
revoke all on function public.are_friends(uuid, uuid) from public, anon;
grant execute on function public.are_friends(uuid, uuid) to authenticated;

-- --- Groups ------------------------------------------------------------------
grant insert (name) on public.chat_groups to authenticated;
-- owner is forced to the caller by trigger; the policy re-checks it.
create policy groups_create on public.chat_groups for insert to authenticated
  with check (owner = auth.uid() and public.is_verified_member());

create function public.on_group_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' and new.owner is distinct from auth.uid() and auth.uid() is not null then
    new.owner := auth.uid();
  end if;
  return new;
end $$;
create trigger group_owner_is_caller before insert on public.chat_groups
  for each row execute function public.on_group_insert();

create function public.on_group_created()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- Client-created groups only; server jobs manage their own membership.
  if auth.uid() is null then return new; end if;
  insert into public.group_members(group_id, user_id) values (new.id, new.owner)
    on conflict do nothing;
  return new;
end $$;
create trigger group_owner_joins after insert on public.chat_groups
  for each row execute function public.on_group_created();

-- Owner adds ACCEPTED friends only (never strangers, never across a block).
-- Anyone may leave; the owner may remove.
grant insert (group_id, user_id), delete on public.group_members to authenticated;
create policy group_members_add on public.group_members for insert to authenticated
  with check (
    exists (select 1 from public.chat_groups g where g.id = group_id and g.owner = auth.uid())
    and user_id <> auth.uid()
    and public.are_friends(auth.uid(), user_id)
    and not public.is_blocked_pair(auth.uid(), user_id));
create policy group_members_leave on public.group_members for delete to authenticated
  using (user_id = auth.uid()
    or exists (select 1 from public.chat_groups g where g.id = group_id and g.owner = auth.uid()));

-- --- Group messages ------------------------------------------------------------
-- Clients choose group, body, kind and media only. Server stamps time and
-- vanish expiry; 'system' messages are server-only.
grant insert (group_id, sender, body, kind, media_id) on public.group_messages to authenticated;
create policy group_messages_send on public.group_messages for insert to authenticated
  with check (
    sender = auth.uid()
    and kind in ('text', 'voice')
    and public.is_social_group_member(group_id)
    and (media_id is null or exists (select 1 from public.media m
         where m.id = media_id and m.owner = auth.uid())));

create function public.on_group_message()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_vanish boolean; v_all_consent boolean;
begin
  if auth.uid() is null then return new; end if; -- server/service writes keep their values
  new.created_at := now();
  select g.vanish_enabled into v_vanish from public.chat_groups g where g.id = new.group_id;
  -- Vanish applies only when the group enabled it AND every member consented.
  select coalesce(bool_and(m.vanish_consent), false) into v_all_consent
    from public.group_members m where m.group_id = new.group_id;
  new.expires_at := case when v_vanish and v_all_consent
                         then now() + interval '24 hours' end;
  return new;
end $$;
create trigger group_message_stamp before insert on public.group_messages
  for each row execute function public.on_group_message();

-- --- Plan polls -----------------------------------------------------------------
grant insert (group_id, creator, place_type, options) on public.plan_polls to authenticated;
create policy polls_create on public.plan_polls for insert to authenticated
  with check (creator = auth.uid() and public.is_social_group_member(group_id));

-- One vote per member, changeable while the poll is open, only for a real option.
grant insert (poll_id, user_id, option_text), update (option_text), delete
  on public.plan_poll_votes to authenticated;
create function public.can_vote(p uuid, opt text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.plan_polls pp
    where pp.id = p and pp.closed_at is null and opt = any (pp.options)
      and public.is_social_group_member(pp.group_id));
$$;
revoke all on function public.can_vote(uuid, text) from public, anon;
grant execute on function public.can_vote(uuid, text) to authenticated;
create policy votes_cast on public.plan_poll_votes for insert to authenticated
  with check (user_id = auth.uid() and public.can_vote(poll_id, option_text));
create policy votes_change on public.plan_poll_votes for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.can_vote(poll_id, option_text));
create policy votes_retract on public.plan_poll_votes for delete to authenticated
  using (user_id = auth.uid() and exists (select 1 from public.plan_polls p
    where p.id = poll_id and p.closed_at is null));

-- Majority of the group locks the plan (mirrors PlanPoll.winner in Dart).
create function public.on_vote()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_group uuid; v_size int; v_top text; v_top_n int;
begin
  select group_id into v_group from public.plan_polls where id = new.poll_id;
  select count(*) into v_size from public.group_members where group_id = v_group;
  select option_text, count(*) into v_top, v_top_n from public.plan_poll_votes
    where poll_id = new.poll_id group by option_text order by count(*) desc limit 1;
  if v_top_n * 2 > v_size then
    update public.plan_polls set winning_option = v_top, closed_at = now()
      where id = new.poll_id and closed_at is null;
  end if;
  return null;
end $$;
create trigger vote_majority after insert or update on public.plan_poll_votes
  for each row execute function public.on_vote();

-- --- Guilds ---------------------------------------------------------------------
-- The directory is visible to verified members (you can't join what you can't see).
create policy guilds_directory on public.guilds for select to authenticated
  using (public.is_verified_member());
grant insert (guild_id, user_id, dating_opt_in), update (dating_opt_in), delete
  on public.guild_members to authenticated;
create policy guild_join on public.guild_members for insert to authenticated
  with check (user_id = auth.uid() and public.is_verified_member());
create policy guild_opt_in on public.guild_members for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid() and public.is_verified_member());
create policy guild_leave on public.guild_members for delete to authenticated
  using (user_id = auth.uid());

commit;
