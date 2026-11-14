import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';

// Disposable actual PostgreSQL (WASM), with Supabase's auth/storage surface
// shimmed. This validates SQL and RLS, not hosted Auth, Storage or Edge jobs.
const db = new PGlite({ extensions: { pgcrypto } });
try {
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create role service_role nologin bypassrls;
    create schema auth;
    create table auth.users(id uuid primary key, phone text, email text);
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
    $$;
    create schema storage;
    create table storage.buckets(id text primary key, name text, public boolean);
    create table storage.objects(id uuid primary key default gen_random_uuid(), bucket_id text, name text);
    alter table storage.objects enable row level security;
    create function storage.foldername(text) returns text[] language sql immutable as $$
      select string_to_array($1, '/')
    $$;
    grant usage on schema public, auth, storage to anon, authenticated, service_role;
    grant execute on function auth.uid() to anon, authenticated, service_role;
    -- Supabase's default privileges; migration 0005 must narrow these.
    alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
  `);
  const migrationDir = new URL('../supabase/migrations/', import.meta.url);
  for (const file of (await readdir(migrationDir)).filter(f => f.endsWith('.sql')).sort()) {
    await db.exec(await readFile(new URL(file, migrationDir), 'utf8'));
    console.log(`Applied ${file}`);
  }

  const a = '00000000-0000-0000-0000-000000000001';
  const b = '00000000-0000-0000-0000-000000000002';
  const outsider = '00000000-0000-0000-0000-000000000003';
  const group = '10000000-0000-0000-0000-000000000001';
  const match = '20000000-0000-0000-0000-000000000001';
  const plan = '30000000-0000-0000-0000-000000000001';
  const split = '40000000-0000-0000-0000-000000000001';
  const poll = '50000000-0000-0000-0000-000000000001';
  await db.exec(`
    insert into auth.users(id) values ('${a}'),('${b}'),('${outsider}');
    insert into public.chat_groups(id,owner,name) values ('${group}','${a}','Friends');
    insert into public.group_members(group_id,user_id) values ('${group}','${a}'),('${group}','${b}');
    insert into public.group_messages(group_id,sender,body,created_at,expires_at) values
      ('${group}','${a}','live',now(),null),
      ('${group}','${a}','expired',now()-interval '2 days',now()-interval '1 day');
    insert into public.plan_polls(id,group_id,creator,place_type,options)
      values ('${poll}','${group}','${a}','Coffee',array['Friday','Saturday']);
    insert into public.plan_poll_votes values ('${poll}','${a}','Friday');
    insert into public.trust_meetings values ('${a}','${b}',now());
    insert into public.trust_vouches(voucher,subject,note) values ('${a}','${b}','Helpful');
    insert into public.matches(id,user_a,user_b) values ('${match}','${a}','${b}');
    insert into public.plans(id,match_id,proposed_by,place_type,time_label)
      values ('${plan}','${match}','${a}','Coffee','Tomorrow');
    insert into public.plan_splits(id,plan_id,creator,total_cents) values ('${split}','${plan}','${a}',1001);
    insert into public.plan_split_shares(split_id,user_id,amount_cents)
      values ('${split}','${a}',501),('${split}','${b}',500);
  `);
  async function as(user) {
    await db.exec('reset role');
    await db.query("select set_config('request.jwt.claim.sub', $1, false)", [user]);
    await db.exec('set role authenticated');
  }
  async function count(table) {
    return Number((await db.query(`select count(*) as n from public.${table}`)).rows[0].n);
  }
  let assertions = 0;
  function equal(actual, expected) { assert.equal(actual, expected); assertions++; }
  async function denied(sql) {
    await assert.rejects(db.exec(sql), e => e.code === '42501'); assertions++;
  }

  await as(a);
  await db.exec(`insert into public.plan_check_ins(plan_id,user_id,check_at) values ('${plan}','${a}',now()+interval '1 hour')`);
  equal(await count('plan_check_ins'), 1);
  equal(await count('group_members'), 2);
  equal(await count('group_messages'), 1); // Expired content is invisible.
  equal(await count('plan_poll_votes'), 1);
  equal(await count('trust_meetings'), 1);
  equal(await count('plan_split_shares'), 2);
  await db.exec(`update public.plan_split_shares set self_marked_paid = true where split_id = '${split}' and user_id = '${a}'`);
  equal((await db.query(`select self_marked_paid from public.plan_split_shares where user_id='${a}'`)).rows[0].self_marked_paid, true);
  equal((await db.exec(`update public.plan_split_shares set self_marked_paid = true where user_id = '${b}'`))[0].affectedRows, 0);
  await denied(`update public.plan_split_shares set amount_cents=0 where user_id='${a}'`);
  await denied(`insert into public.trust_meetings values ('${a}','${outsider}',now())`);
  await denied(`insert into public.trust_vouches(voucher,subject,note) values ('${b}','${a}','Forged')`);
  await denied(`insert into public.group_members(group_id,user_id) values ('${group}','${outsider}')`);
  await denied(`update public.chat_groups set vanish_enabled=true`);
  await denied(`update public.host_profiles set tier='partner'`);
  await denied(`insert into public.gifts(sender,recipient,product_id,purchase_ref,price_cents,currency)
    values ('${a}','${b}','gift','fake',1,'USD')`);
  await db.exec(`insert into public.social_preferences(user_id,no_counts) values ('${a}',true)`);
  await denied(`insert into public.social_preferences(user_id) values ('${b}')`);
  await as(outsider);
  await denied(`insert into public.plan_check_ins(plan_id,user_id,check_at) values ('${plan}','${outsider}',now()+interval '1 hour')`);
  for (const table of ['chat_groups','group_members','group_messages','plan_polls','plan_poll_votes','trust_meetings','trust_vouches','plan_splits','plan_split_shares','social_preferences']) {
    equal(await count(table), 0);
  }
  await db.exec('reset role');
  await db.exec(`insert into public.blocks(blocker,blocked) values ('${b}','${a}')`);
  await as(b);
  equal(await count('group_messages'), 0);
  equal(await count('trust_meetings'), 0);
  equal(await count('trust_vouches'), 0);
  await db.exec('reset role; set role anon');
  await denied('select * from public.social_preferences');
  await denied('select public.is_social_group_member(null)');
  console.log(`Passed ${assertions} migration/RLS assertions.`);
} finally {
  await db.close();
}
