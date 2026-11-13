-- Cariño backend · seed · remote config v1
-- These values mirror the compiled defaults in
-- lib/services/remote_config.dart EXACTLY — the server can tune copy and
-- windows, but the client's hard limits apply regardless of what a doc
-- contains: no key can unverify anyone, hide a safety surface, fabricate
-- a count, or reword the Vanish honesty copy.
insert into public.remote_config_docs (version, doc, active)
values (
  1,
  '{
    "welcome_hook": "Find your kind of spark.",
    "paywall_headline": "Less swiping into the void. More actual plans.",
    "daily_drop_size": 3,
    "daily_drop_time": "18:00",
    "daily_drop_empty_copy": "Today''s drop is done — regular discovery stays open.",
    "next_spark_window": "Tonight · 20:00–22:00",
    "match_expiry_hours": 72,
    "city_batch_full": false,
    "feature_flags": {
      "spark_sessions": true,
      "fun_mode": true
    }
  }'::jsonb,
  true
)
on conflict (version) do nothing;
