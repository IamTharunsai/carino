-- Social platform foundation. No payment processing or client-issued trust.
-- Deploy after 0004. Social writes requiring invitations, bilateral consent,
-- moderation, settlement, or reputation are service-role ONLY until their
-- authenticated Edge Functions are implemented. RLS defaults to denial.
begin;

create table public.social_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  no_counts boolean not null default false,
  calm_mode boolean not null default false,
  facet_audience jsonb not null default '{}' check (jsonb_typeof(facet_audience) = 'object')
);
create table public.circles (
  owner uuid not null references public.profiles(id) on delete cascade,
  person uuid not null references public.profiles(id) on delete cascade,
  circle text not null check (circle in ('inner','friends','dates')),
  primary key (owner, person), check (owner <> person)
);
-- Circle assignments are private. They do not establish accepted friendship.
create table public.friendships (
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  accepted_at timestamptz not null default now(),
  primary key(user_a, user_b), check (user_a < user_b)
);
create table public.chat_groups (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  vanish_enabled boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.group_members (
  group_id uuid not null references public.chat_groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  vanish_consent boolean not null default false,
  primary key(group_id, user_id)
);

-- The caller can only ask about their own membership. Avoid recursive RLS on
-- group_members; no exposed helper accepts an arbitrary member identity.
create function public.is_social_group_member(g uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.group_members m
    where m.group_id = g and m.user_id = auth.uid());
$$;
revoke all on function public.is_social_group_member(uuid) from public, anon;
grant execute on function public.is_social_group_member(uuid) to authenticated;

create table public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.chat_groups(id) on delete cascade,
  sender uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 4000),
  kind text not null default 'text' check (kind in ('text','voice','system')),
  media_id uuid references public.media(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  check (expires_at is null or expires_at > created_at)
);
create index group_messages_thread on public.group_messages(group_id, created_at);
create index group_messages_expiry on public.group_messages(expires_at) where expires_at is not null;
create table public.plan_polls (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.chat_groups(id) on delete cascade,
  creator uuid not null references public.profiles(id) on delete cascade,
  place_type text not null check (char_length(place_type) between 1 and 120),
  options text[] not null check (cardinality(options) between 2 and 8),
  winning_option text,
  closed_at timestamptz,
  check (winning_option is null or winning_option = any(options))
);
create table public.plan_poll_votes (
  poll_id uuid not null references public.plan_polls(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  option_text text not null,
  primary key(poll_id, user_id)
);

create table public.feed_posts (
  id uuid primary key default gen_random_uuid(),
  author uuid not null references public.profiles(id) on delete cascade,
  caption text not null check (char_length(caption) between 1 and 4000),
  topic text not null,
  audience text not null default 'friends' check (audience in ('inner','friends','dates','public')),
  ai_generated boolean not null default false,
  moderation_state text not null default 'pending' check (moderation_state in ('pending','approved','held','rejected')),
  created_at timestamptz not null default now()
);
-- Approved cross-member projections must enforce facets, audience, blocks,
-- and Dates eligibility. Until that endpoint exists clients read own posts.
create table public.trust_meetings (
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  confirmed_at timestamptz not null default now(),
  primary key(user_a, user_b), check(user_a < user_b)
);
-- One-time code hashes belong in a private schema, never in a readable row.
-- A future bilateral-confirmation function consumes codes and inserts edges.
create table public.trust_vouches (
  voucher uuid not null references public.profiles(id) on delete cascade,
  subject uuid not null references public.profiles(id) on delete cascade,
  note text not null check (char_length(trim(note)) between 1 and 240),
  created_at timestamptz not null default now(),
  primary key(voucher, subject), check(voucher <> subject)
);
create table public.host_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  plans_hosted integer not null default 0 check (plans_hosted >= 0),
  positive_feedback integer not null default 0 check (positive_feedback between 0 and plans_hosted),
  upheld_reports integer not null default 0 check (upheld_reports >= 0),
  tier text not null default 'new' check (tier in ('new','trusted','partner'))
);
create table public.work_facets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  role text not null default '' check (char_length(role) <= 80),
  building text not null default '' check (char_length(building) <= 200),
  skills text[] not null default '{}',
  open_to text[] not null default '{}' check (open_to <@ array['coffee','collabs','mentoring','hiring']::text[])
);
create table public.coffee_matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  week_of date not null,
  state text not null default 'proposed' check (state in ('proposed','accepted','passed','completed')),
  unique(user_a, user_b, week_of), check(user_a < user_b)
);
create table public.intro_requests (
  id uuid primary key default gen_random_uuid(),
  requester uuid not null references public.profiles(id) on delete cascade,
  introducer uuid not null references public.profiles(id) on delete cascade,
  target uuid not null references public.profiles(id) on delete cascade,
  note text not null check (char_length(note) between 1 and 500),
  state text not null default 'requested' check (state in ('requested','offered','accepted','declined')),
  check(requester <> target and requester <> introducer and introducer <> target)
);
create table public.guilds (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 80),
  blurb text not null default '',
  rooms text[] not null default '{}'
);
create table public.guild_members (
  guild_id uuid not null references public.guilds(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  dating_opt_in boolean not null default false,
  primary key(guild_id, user_id)
);
create table public.gifts (
  id uuid primary key default gen_random_uuid(),
  sender uuid not null references public.profiles(id) on delete cascade,
  recipient uuid not null references public.profiles(id) on delete cascade,
  post_id uuid references public.feed_posts(id) on delete set null,
  product_id text not null,
  purchase_ref text not null unique,
  price_cents integer not null check (price_cents > 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  created_at timestamptz not null default now(), check(sender <> recipient)
);
create table public.plan_splits (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans(id) on delete cascade,
  creator uuid not null references public.profiles(id) on delete cascade,
  total_cents integer not null check (total_cents > 0),
  currency text not null default 'USD' check (currency = 'USD'),
  created_at timestamptz not null default now()
);
create table public.plan_split_shares (
  split_id uuid not null references public.plan_splits(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount_cents integer not null check (amount_cents >= 0),
  self_marked_paid boolean not null default false,
  primary key(split_id, user_id)
);

-- Every table explicitly listed: do not mutate unrelated existing policies.
do $$ declare t text; begin
  foreach t in array array['social_preferences','circles','friendships','chat_groups',
    'group_members','group_messages','plan_polls','plan_poll_votes','feed_posts',
    'trust_meetings','trust_vouches','host_profiles','work_facets','coffee_matches',
    'intro_requests','guilds','guild_members','gifts','plan_splits','plan_split_shares']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('grant all on public.%I to service_role', t);
  end loop;
end $$;

grant insert, update, delete on public.social_preferences, public.circles, public.work_facets to authenticated;
create policy social_preferences_own on public.social_preferences for all to authenticated
  using(user_id = auth.uid()) with check(user_id = auth.uid());
create policy circles_own on public.circles for all to authenticated
  using(owner = auth.uid()) with check(owner = auth.uid());
create policy work_facets_own on public.work_facets for all to authenticated
  using(user_id = auth.uid()) with check(user_id = auth.uid());
create policy friendships_read on public.friendships for select to authenticated
  using(auth.uid() in (user_a, user_b) and not public.is_blocked_pair(user_a,user_b));
create policy groups_read on public.chat_groups for select to authenticated
  using(public.is_social_group_member(id));
create policy group_members_read on public.group_members for select to authenticated
  using(public.is_social_group_member(group_id));
create policy group_messages_read on public.group_messages for select to authenticated
  using(public.is_social_group_member(group_id) and (expires_at is null or expires_at > now())
    and not public.is_blocked_pair(sender,auth.uid()));
create policy polls_read on public.plan_polls for select to authenticated
  using(public.is_social_group_member(group_id));
create policy votes_read on public.plan_poll_votes for select to authenticated
  using(exists(select 1 from public.plan_polls p where p.id = poll_id and public.is_social_group_member(p.group_id)));
create policy feed_posts_own_read on public.feed_posts for select to authenticated using(author = auth.uid());
create policy meetings_read on public.trust_meetings for select to authenticated
  using(auth.uid() in (user_a,user_b) and not public.is_blocked_pair(user_a,user_b));
create policy vouches_read on public.trust_vouches for select to authenticated
  using(auth.uid() in (voucher,subject) and not public.is_blocked_pair(voucher,subject));
create policy host_own_read on public.host_profiles for select to authenticated using(user_id = auth.uid());
create policy coffee_read on public.coffee_matches for select to authenticated
  using(auth.uid() in (user_a,user_b) and not public.is_blocked_pair(user_a,user_b));
create policy intros_read on public.intro_requests for select to authenticated
  using((auth.uid() in (requester,introducer) or (target = auth.uid() and state in ('offered','accepted')))
    and not public.is_blocked_pair(requester,target));
create policy guilds_read on public.guilds for select to authenticated
  using(exists(select 1 from public.guild_members m where m.guild_id = id and m.user_id = auth.uid()));
create policy guild_members_own_read on public.guild_members for select to authenticated using(user_id = auth.uid());
create policy gifts_read on public.gifts for select to authenticated using(auth.uid() in (sender,recipient));
create policy splits_read on public.plan_splits for select to authenticated
  using(exists(select 1 from public.plans p where p.id = plan_id and public.is_match_participant(p.match_id)));
create policy shares_read on public.plan_split_shares for select to authenticated
  using(exists(select 1 from public.plan_splits s where s.id = split_id));
grant update(self_marked_paid) on public.plan_split_shares to authenticated;
create policy shares_mark_own on public.plan_split_shares for update to authenticated
  using(user_id = auth.uid() and exists(select 1 from public.plan_splits s where s.id = split_id))
  with check(user_id = auth.uid() and exists(select 1 from public.plan_splits s where s.id = split_id));

-- The scheduled service-role job must DELETE expired group_messages, and
-- remove their audio objects according to the existing safety-vault policy.
-- Hiding rows with SELECT RLS is not a retention/deletion guarantee.
commit;
