-- 0007 Decompress (bookable stress-relief experiences) + Phone-Down presence.
-- Deploy after 0006. Members never set prices, commissions or capacity.
begin;

-- Partner-run experiences (written by staff / partner integrations only).
create table public.experiences (
  id uuid primary key default gen_random_uuid(),
  partner_name text not null,
  title text not null check (char_length(title) between 1 and 120),
  category text not null check (category in ('Walk','Water','Make','Calm','Move','Spa','Café','Sports')),
  venue_type text not null,                      -- public venue TYPE, never an address
  city text not null,
  starts_at timestamptz not null,
  duration_min int not null check (duration_min between 15 and 600),
  price_cents int not null default 0 check (price_cents >= 0),
  commission_rate numeric(4,3) not null default 0.120 check (commission_rate between 0 and 0.5),
  capacity int not null check (capacity > 0),
  max_party int not null default 4 check (max_party > 0),
  step_free boolean not null default false,
  phone_free boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.experience_bookings (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  mode text not null check (mode in ('solo','circle','date','group')),
  party_size int not null check (party_size between 1 and 20),
  -- Money fields are set by the booking function from the experience row,
  -- never by the client: member pays the listed price; commission is the
  -- venue's cost.
  member_pays_cents int not null default 0,
  commission_cents int not null default 0,
  status text not null default 'reserved' check (status in ('reserved','paid','cancelled','attended')),
  created_at timestamptz not null default now(),
  unique (experience_id, user_id)
);

create function public.on_booking_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v public.experiences%rowtype; v_taken int;
begin
  select * into v from public.experiences where id = new.experience_id for update;
  if not found then raise exception 'unknown experience'; end if;
  if new.party_size > v.max_party then raise exception 'party too large'; end if;
  select coalesce(sum(party_size), 0) into v_taken from public.experience_bookings
    where experience_id = new.experience_id and status <> 'cancelled';
  if v_taken + new.party_size > v.capacity then raise exception 'sold out'; end if;
  new.member_pays_cents := v.price_cents * new.party_size;
  new.commission_cents := round(new.member_pays_cents * v.commission_rate);
  new.status := 'reserved';
  return new;
end $$;
create trigger booking_pricing before insert on public.experience_bookings
  for each row execute function public.on_booking_insert();

-- Phone-Down presence, one row per member per plan session.
create table public.presence_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid references public.plans(id) on delete set null,
  booking_id uuid references public.experience_bookings(id) on delete set null,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  distracted_seconds int not null default 0 check (distracted_seconds >= 0),
  check_ins int not null default 0 check (check_ins >= 0),
  check (ended_at > started_at),
  check (distracted_seconds <= extract(epoch from (ended_at - started_at)))
);

alter table public.experiences enable row level security;
alter table public.experience_bookings enable row level security;
alter table public.presence_sessions enable row level security;
revoke all on public.experiences, public.experience_bookings, public.presence_sessions from anon, authenticated;
grant select on public.experiences to authenticated;
grant select, delete on public.experience_bookings to authenticated;
grant insert (experience_id, user_id, mode, party_size) on public.experience_bookings to authenticated;
grant select, insert on public.presence_sessions to authenticated;
grant all on public.experiences, public.experience_bookings, public.presence_sessions to service_role;

create policy experiences_verified_read on public.experiences for select to authenticated
  using (public.is_verified_member());
create policy bookings_own on public.experience_bookings for select to authenticated
  using (user_id = auth.uid());
create policy bookings_create_own on public.experience_bookings for insert to authenticated
  with check (user_id = auth.uid() and public.is_verified_member());
create policy bookings_cancel_own on public.experience_bookings for delete to authenticated
  using (user_id = auth.uid());
create policy presence_own_write on public.presence_sessions for insert to authenticated
  with check (user_id = auth.uid());
-- Your own scores, plus scores of people in the same plan (the shared card).
create policy presence_read on public.presence_sessions for select to authenticated
  using (user_id = auth.uid()
    or (plan_id is not null and exists (select 1 from public.plans p
          where p.id = plan_id and public.is_match_participant(p.match_id))));

commit;
