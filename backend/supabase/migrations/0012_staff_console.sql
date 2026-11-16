-- 0012 Staff console: who is staff, what staff can see, and an audit row
-- for every action. Staff are added by the service role only (SQL editor /
-- dashboard) — no one can make themselves staff from the app.

create table public.staff (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  role text not null check (role in ('moderator', 'admin')),
  created_at timestamptz not null default now()
);
alter table public.staff enable row level security;
revoke all on public.staff from anon, authenticated;

create table public.staff_actions (
  id bigint generated always as identity primary key,
  staff_id uuid not null references public.profiles (id),
  target_kind text not null,              -- report|media|appeal|member
  target_id uuid not null,
  action text not null,
  note text,
  created_at timestamptz not null default now()
);
alter table public.staff_actions enable row level security;
revoke all on public.staff_actions from anon, authenticated;

-- Definer so RLS policies can ask "is this caller staff?" without exposing
-- the staff table itself.
create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.staff where user_id = auth.uid());
$$;
grant execute on function public.is_staff() to authenticated;

-- Read access for staff (queues + member lookup). Writes go through the
-- functions below so every change is audited.
create policy "staff read reports" on public.reports for select using (public.is_staff());
create policy "staff read appeals" on public.appeals for select using (public.is_staff());
create policy "staff read warnings" on public.warnings for select using (public.is_staff());
create policy "staff read media" on public.media for select using (public.is_staff());
create policy "staff read blocks" on public.blocks for select using (public.is_staff());
create policy "staff read profiles" on public.profiles for select using (public.is_staff());
create policy "staff read verification" on public.verification_records for select using (public.is_staff());
create policy "staff read own actions" on public.staff_actions for select using (public.is_staff());
grant select on public.staff_actions to authenticated;

create or replace function public.staff_review_report(p_report uuid, p_status text, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_staff() then raise exception 'staff only'; end if;
  if p_status not in ('in_review', 'actioned', 'closed_no_action') then
    raise exception 'unknown status %', p_status;
  end if;
  update public.reports set status = p_status, action = left(p_note, 500) where id = p_report;
  insert into public.staff_actions(staff_id, target_kind, target_id, action, note)
    values (auth.uid(), 'report', p_report, p_status, left(p_note, 500));
end $$;

create or replace function public.staff_moderate_media(p_media uuid, p_state text, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_staff() then raise exception 'staff only'; end if;
  if p_state not in ('approved', 'held', 'rejected') then
    raise exception 'unknown state %', p_state;
  end if;
  update public.media set moderation_state = p_state where id = p_media;
  insert into public.staff_actions(staff_id, target_kind, target_id, action, note)
    values (auth.uid(), 'media', p_media, p_state, left(p_note, 500));
end $$;

create or replace function public.staff_decide_appeal(p_appeal uuid, p_status text, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_staff() then raise exception 'staff only'; end if;
  if p_status not in ('upheld', 'overturned') then raise exception 'unknown status %', p_status; end if;
  update public.appeals set status = p_status where id = p_appeal;
  insert into public.staff_actions(staff_id, target_kind, target_id, action, note)
    values (auth.uid(), 'appeal', p_appeal, p_status, left(p_note, 500));
end $$;

create or replace function public.staff_set_account(p_user uuid, p_status text, p_note text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_staff() then raise exception 'staff only'; end if;
  if p_status not in ('active', 'paused', 'restricted') then raise exception 'unknown status %', p_status; end if;
  update public.profiles set account_status = p_status where id = p_user;
  insert into public.staff_actions(staff_id, target_kind, target_id, action, note)
    values (auth.uid(), 'member', p_user, p_status, left(p_note, 500));
end $$;

revoke execute on function public.staff_review_report(uuid, text, text) from anon;
revoke execute on function public.staff_moderate_media(uuid, text, text) from anon;
revoke execute on function public.staff_decide_appeal(uuid, text, text) from anon;
revoke execute on function public.staff_set_account(uuid, text, text) from anon;
grant execute on function public.staff_review_report(uuid, text, text) to authenticated;
grant execute on function public.staff_moderate_media(uuid, text, text) to authenticated;
grant execute on function public.staff_decide_appeal(uuid, text, text) to authenticated;
grant execute on function public.staff_set_account(uuid, text, text) to authenticated;

-- Staff can open media files to review them (private buckets otherwise).
create policy "staff read media objects" on storage.objects for select using (public.is_staff());
