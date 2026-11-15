-- 0009 Red-team round 2. Deploy after 0008.
-- Fixes found by attacking our own API as a signed-in member:
--  1. messages: a client could INSERT is_system_notice/kind='system' (fake
--     "Cariño Safety" phishing notices), backdate created_at (bypassing the
--     photos-after-N-days rule), pre-set expiry/dissolve/unsend/reaction.
--  2. plans: a participant could insert/update state='confirmed' and forge
--     the OTHER person's confirmation or check-in ("home safe").
--  3. no per-sender rate limit on messages (spam / harassment floods).
--  4. "I'll message first" (opens_first) enforced server-side.
begin;

alter table public.conversation_prefs add column opens_first boolean not null default false;

create index if not exists messages_sender_time on public.messages (sender, created_at desc);

-- 1 + 3 + 4: messages insert guard (runs before the comfort trigger: 'a' < 'c').
create function public.a_guard_message_insert()
returns trigger language plpgsql set search_path = '' as $$
declare v_other uuid; v_recent int;
begin
  if not public.is_client() then return new; end if;
  if new.kind = 'system' then raise exception 'system notices are server-only'; end if;
  new.is_system_notice := false;
  new.created_at := now();
  new.expires_at := null;
  new.dissolved_at := null;
  new.unsent_at := null;
  new.view_once_consumed_at := null;
  new.reaction := null;

  -- ponytail: count-in-window limit on an index; move to a token bucket at the
  -- edge (gateway/KV) if write volume ever makes this query hot.
  select count(*) into v_recent from public.messages
   where sender = new.sender and created_at > now() - interval '1 minute';
  if v_recent >= 30 then raise exception 'slow down: message rate limit'; end if;

  select case when m.user_a = new.sender then m.user_b else m.user_a end into v_other
    from public.conversations c join public.matches m on m.id = c.match_id
   where c.id = new.conversation_id;
  if exists (select 1 from public.conversation_prefs where user_id = v_other and opens_first)
     and not exists (select 1 from public.messages
                     where conversation_id = new.conversation_id and sender = v_other) then
    raise exception 'comfort rule: they send the first message';
  end if;
  return new;
end $$;
create trigger a_guard_message_insert before insert on public.messages
  for each row execute function public.a_guard_message_insert();

-- 2: plans — each person controls only their own confirmation.
create function public.guard_plans()
returns trigger language plpgsql set search_path = '' as $$
declare me text := auth.uid()::text; v_a uuid; v_b uuid;
begin
  if not public.is_client() then return new; end if;
  if tg_op = 'INSERT' then
    new.proposed_by := auth.uid();
    new.state := 'proposed';
    new.confirmations := jsonb_build_object(me, true);
    new.check_ins := '{}';
    new.created_at := now();
    return new;
  end if;
  new.match_id := old.match_id;
  new.proposed_by := old.proposed_by;
  new.created_at := old.created_at;
  new.check_ins := old.check_ins;            -- check-ins live in plan_check_ins (own row)
  new.confirmations := (old.confirmations - me)
    || case when new.confirmations ? me
            then jsonb_build_object(me, new.confirmations -> me) else '{}'::jsonb end;
  if new.state = 'completed' then new.state := old.state; end if;   -- server job only
  if new.state = 'confirmed' then
    select user_a, user_b into v_a, v_b from public.matches where id = new.match_id;
    if coalesce((new.confirmations ->> v_a::text)::boolean, false) is not true
       or coalesce((new.confirmations ->> v_b::text)::boolean, false) is not true then
      raise exception 'a plan is confirmed only when both people confirm';
    end if;
  end if;
  return new;
end $$;
create trigger guard_plans before insert or update on public.plans
  for each row execute function public.guard_plans();

commit;
