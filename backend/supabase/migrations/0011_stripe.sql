-- 0011 Stripe: Decompress bookings (Stripe Connect) + website Plus.
-- Deploy after 0010. Only Edge Functions (service role) write these columns.
--  * In-app Plus stays on App Store / Google Play billing (store rules).
--  * Real-world bookings pay the venue directly via Connect; Cariño's
--    commission is the platform fee — the member pays the listed price.
begin;

alter table public.experiences add column stripe_account_id text;          -- venue's Connect account
alter table public.experience_bookings add column stripe_session_id text;  -- Checkout session

-- Webhooks retry: remember processed event ids so each applies once.
create table public.stripe_events (
  id text primary key,
  type text not null,
  received_at timestamptz not null default now()
);
alter table public.stripe_events enable row level security;
revoke all on public.stripe_events from anon, authenticated;
grant all on public.stripe_events to service_role;

commit;
