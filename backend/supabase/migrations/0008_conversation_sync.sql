-- 0008 Conversation Sync. Deploy after 0007.
--  * conversation_prefs: "How I text" card + comfort rules (shown to matches)
--  * comfort rules ENFORCED here, not just in the app: photos/videos wait for
--    the recipient's day count; direct calls wait until both have met
--  * messages.tone_tag (optional, sender-chosen, immutable after send)
--  * private_reflections: after-plan check-ins, readable by the owner ONLY
--  * chat_pauses: "pause, don't ghost" (both participants can see it)
--  * private_notes: "things to remember" about a match, owner ONLY
begin;

create function public.short_tags(tags text[]) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(bool_and(char_length(t) between 1 and 30), true) from unnest(tags) t
$$;

create function public.met_in_person(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.trust_meetings
                 where user_a = least(a, b) and user_b = greatest(a, b))
$$;

-- Caller has an active, unblocked match with [other].
create function public.is_matched_with(other uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.matches m
    where m.state = 'active'
      and ((m.user_a = auth.uid() and m.user_b = other)
        or (m.user_b = auth.uid() and m.user_a = other))
      and not public.is_blocked_pair(m.user_a, m.user_b))
$$;

create table public.conversation_prefs (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  reply_pace text check (reply_pace in ('quick','evenings','slow')),
  msg_length text check (msg_length in ('short','long')),
  voice_notes text check (voice_notes in ('love','sometimes','textOnly')),
  humour text check (humour in ('dry','playful','wholesome')),
  loves text[] not null default '{}' check (cardinality(loves) <= 5 and public.short_tags(loves)),
  avoid text[] not null default '{}' check (cardinality(avoid) <= 5 and public.short_tags(avoid)),
  no_calls_before_meet boolean not null default false,
  photos_after_days int not null default 0 check (photos_after_days between 0 and 30),
  daytime_first_meet boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.messages add column tone_tag text
  check (tone_tag in ('joking','serious','being gentle','excited'));

-- Photos/videos follow the RECIPIENT's rule until the pair has met.
create function public.enforce_comfort_on_message()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_other uuid; v_days int; v_first timestamptz;
begin
  if new.kind not in ('photo','video') then return new; end if;
  select case when m.user_a = new.sender then m.user_b else m.user_a end
    into v_other
    from public.conversations c join public.matches m on m.id = c.match_id
   where c.id = new.conversation_id;
  select photos_after_days into v_days from public.conversation_prefs where user_id = v_other;
  if coalesce(v_days, 0) = 0 or public.met_in_person(new.sender, v_other) then return new; end if;
  select min(created_at) into v_first from public.messages where conversation_id = new.conversation_id;
  if coalesce(v_first, now()) > now() - make_interval(days => v_days) then
    raise exception 'comfort rule: photos after % days of chatting', v_days;
  end if;
  return new;
end $$;
create trigger comfort_on_message before insert on public.messages
  for each row execute function public.enforce_comfort_on_message();

-- Direct calls (not Spark-night sessions, which are opt-in by design) wait
-- until both have met when either participant asked for that.
create function public.enforce_comfort_on_call()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.spark_session_id is null
     and cardinality(new.participants) = 2
     and not public.met_in_person(new.participants[1], new.participants[2])
     and exists (select 1 from public.conversation_prefs
                 where user_id = any(new.participants) and no_calls_before_meet) then
    raise exception 'comfort rule: no calls before meeting';
  end if;
  return new;
end $$;
create trigger comfort_on_call before insert on public.calls
  for each row execute function public.enforce_comfort_on_call();

-- Tone tags are immutable after send, like the rest of the content.
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
    new.tone_tag := old.tone_tag;
  end if;
  return new;
end;
$$;

create table public.private_reflections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid references public.plans(id) on delete set null,
  category text check (category in ('Walk','Water','Make','Calm','Move','Spa','Café','Sports')),
  good boolean not null,
  liked text[] not null default '{}' check (liked <@ array['place','talk','pace','timeOfDay','quiet','busy']),
  disliked text[] not null default '{}' check (disliked <@ array['place','talk','pace','timeOfDay','quiet','busy']),
  created_at timestamptz not null default now()
);

create table public.chat_pauses (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  back_label text not null check (back_label in ('tomorrow','in a few days','next week')),
  created_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table public.private_notes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  about_user uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) <= 300),
  updated_at timestamptz not null default now(),
  primary key (user_id, about_user)
);

alter table public.conversation_prefs enable row level security;
alter table public.private_reflections enable row level security;
alter table public.chat_pauses enable row level security;
alter table public.private_notes enable row level security;
revoke all on public.conversation_prefs, public.private_reflections,
  public.chat_pauses, public.private_notes from anon, authenticated;
grant select, insert, update, delete on public.conversation_prefs to authenticated;
grant select, insert, delete on public.private_reflections to authenticated;
grant select, insert, delete on public.chat_pauses to authenticated;
grant select, insert, update, delete on public.private_notes to authenticated;
grant all on public.conversation_prefs, public.private_reflections,
  public.chat_pauses, public.private_notes to service_role;

create policy prefs_own on public.conversation_prefs for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy prefs_matches_read on public.conversation_prefs for select to authenticated
  using (public.is_matched_with(user_id));

create policy reflections_own on public.private_reflections for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy pauses_read on public.chat_pauses for select to authenticated
  using (exists (select 1 from public.conversations c
                 where c.id = conversation_id and public.is_match_participant(c.match_id)));
create policy pauses_own_write on public.chat_pauses for insert to authenticated
  with check (user_id = auth.uid() and exists (
    select 1 from public.conversations c
    where c.id = conversation_id and public.is_match_participant(c.match_id)));
create policy pauses_own_delete on public.chat_pauses for delete to authenticated
  using (user_id = auth.uid());

create policy notes_own on public.private_notes for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

commit;
