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
  // --- 0006 social writes ---------------------------------------------------
  const c = '00000000-0000-0000-0000-00000000000c';
  const d = '00000000-0000-0000-0000-00000000000d';
  const e = '00000000-0000-0000-0000-00000000000e';
  await db.exec('reset role');
  await db.exec(`
    insert into auth.users(id) values ('${c}'),('${d}'),('${e}');
    insert into public.verification_records(user_id, badge_state) values ('${c}','active'),('${d}','active')
      on conflict (user_id) do update set badge_state = excluded.badge_state;
    insert into public.friendships(user_a,user_b) values ('${c}','${d}');
    insert into public.guilds(name) values ('Run Club');
  `);
  await as(c);
  await db.exec(`insert into public.chat_groups(name) values ('Weekend crew')`);
  const g2 = (await db.query(`select id, owner from public.chat_groups where name = 'Weekend crew'`)).rows[0];
  equal(g2.owner, c); // owner forced to the caller
  equal(await count('group_members'), 1); // owner auto-joined
  await db.exec(`insert into public.group_members(group_id,user_id) values ('${g2.id}','${d}')`);
  await denied(`insert into public.group_members(group_id,user_id) values ('${g2.id}','${e}')`); // not a friend
  await db.exec(`insert into public.group_messages(group_id,sender,body) values ('${g2.id}','${c}','Saturday?')`);
  const msg = (await db.query(`select expires_at from public.group_messages where body='Saturday?'`)).rows[0];
  equal(msg.expires_at, null); // vanish not enabled -> kept
  await denied(`insert into public.group_messages(group_id,sender,body) values ('${g2.id}','${d}','Forged')`);
  await denied(`insert into public.group_messages(group_id,sender,body,kind) values ('${g2.id}','${c}','x','system')`);
  await denied(`insert into public.group_messages(group_id,sender,body,expires_at) values ('${g2.id}','${c}','x',now())`);
  await db.exec(`insert into public.plan_polls(group_id,creator,place_type,options) values ('${g2.id}','${c}','Bowling',array['Fri','Sat'])`);
  const p2 = (await db.query(`select id from public.plan_polls where place_type='Bowling'`)).rows[0].id;
  await denied(`insert into public.plan_poll_votes values ('${p2}','${c}','Sunday')`); // not an option
  await db.exec(`insert into public.plan_poll_votes values ('${p2}','${c}','Fri')`);
  equal((await db.query(`select closed_at from public.plan_polls where id='${p2}'`)).rows[0].closed_at, null);
  await as(d);
  await db.exec(`insert into public.plan_poll_votes values ('${p2}','${d}','Fri')`);
  equal((await db.query(`select winning_option from public.plan_polls where id='${p2}'`)).rows[0].winning_option, 'Fri');
  await denied(`update public.plan_poll_votes set option_text='Sat' where poll_id='${p2}' and user_id='${d}'`); // closed
  equal(await count('guilds'), 1);
  const guild = (await db.query(`select id from public.guilds`)).rows[0].id;
  await db.exec(`insert into public.guild_members(guild_id,user_id,dating_opt_in) values ('${guild}','${d}',true)`);
  await as(e); // unverified
  equal(await count('guilds'), 0);
  await denied(`insert into public.guild_members(guild_id,user_id) values ('${guild}','${e}')`);
  await denied(`insert into public.group_messages(group_id,sender,body) values ('${g2.id}','${e}','hi')`);
  await denied(`insert into public.chat_groups(name) values ('Unverified group')`);

  // --- 0007 Decompress + presence -------------------------------------------
  await db.exec('reset role');
  await db.exec(`insert into public.experiences(title,partner_name,category,venue_type,city,starts_at,duration_min,price_cents,capacity,max_party)
    values ('Kayak','Paddle Co','Water','River outfitter','Columbus',now()+interval '1 day',120,4500,4,4)`);
  const exp = (await db.query(`select id from public.experiences where title='Kayak'`)).rows[0].id;
  await as(c);
  equal(await count('experiences'), 1);
  // Client tries to set its own price: column not granted -> denied.
  await denied(`insert into public.experience_bookings(experience_id,user_id,mode,party_size,member_pays_cents) values ('${exp}','${c}','date',2,1)`);
  await db.exec(`insert into public.experience_bookings(experience_id,user_id,mode,party_size) values ('${exp}','${c}','date',2)`);
  const bk = (await db.query(`select member_pays_cents, commission_cents from public.experience_bookings`)).rows[0];
  equal(bk.member_pays_cents, 9000);   // listed price x2, no markup
  equal(bk.commission_cents, 1080);    // 12% from the venue side
  await denied(`insert into public.experience_bookings(experience_id,user_id,mode,party_size) values ('${exp}','${d}','solo',1)`); // forged user
  await as(d);
  await assert.rejects(db.exec(`insert into public.experience_bookings(experience_id,user_id,mode,party_size) values ('${exp}','${d}','circle',3)`)); assertions++; // sold out (2+3 > 4)
  await db.exec(`insert into public.presence_sessions(user_id,started_at,ended_at,distracted_seconds,check_ins) values ('${d}',now()-interval '2 hours',now(),300,1)`);
  await denied(`insert into public.presence_sessions(user_id,started_at,ended_at) values ('${c}',now()-interval '1 hour',now())`);
  await as(e); // unverified
  equal(await count('experiences'), 0);

  // --- 0008 Conversation Sync -----------------------------------------------
  const f = '00000000-0000-0000-0000-00000000000f';
  const g = '00000000-0000-0000-0000-000000000010';
  const m2 = '20000000-0000-0000-0000-000000000002';
  await db.exec('reset role');
  await db.exec(`insert into auth.users(id) values ('${f}'),('${g}');
    insert into public.matches(id,user_a,user_b) values ('${m2}','${f}','${g}');`);
  const conv2 = (await db.query(`select id from public.conversations where match_id='${m2}'`)).rows[0].id;
  await as(f);
  await db.exec(`insert into public.conversation_prefs(user_id,reply_pace,photos_after_days,no_calls_before_meet,loves)
    values ('${f}','evenings',3,true,array['Film photography'])`);
  await assert.rejects(db.exec(`update public.conversation_prefs set loves=array['a','b','c','d','e','f'] where user_id='${f}'`)); assertions++; // max 5 tags
  await as(g);
  equal(await count('conversation_prefs'), 1);          // matches can read the card
  await denied(`insert into public.conversation_prefs(user_id) values ('${f}')`); // not yours
  await db.exec(`insert into public.messages(conversation_id,sender,kind,body) values ('${conv2}','${g}','text','hi')`);
  await assert.rejects(db.exec(`insert into public.messages(conversation_id,sender,kind) values ('${conv2}','${g}','photo')`),
    e => /photos after 3 days/.test(e.message)); assertions++; // f's rule holds the photo
  await as(f);
  await db.exec(`insert into public.messages(conversation_id,sender,kind,body,tone_tag) values ('${conv2}','${f}','text','lol','joking')`);
  await assert.rejects(db.exec(`insert into public.messages(conversation_id,sender,kind,body,tone_tag) values ('${conv2}','${f}','text','x','sarcastic')`)); assertions++;
  await db.exec(`update public.messages set tone_tag='serious' where body='lol'`);
  equal((await db.query(`select tone_tag from public.messages where body='lol'`)).rows[0].tone_tag, 'joking'); // immutable
  await db.exec(`insert into public.private_reflections(user_id,category,good,liked) values ('${f}','Calm',true,array['quiet'])`);
  await assert.rejects(db.exec(`insert into public.private_reflections(user_id,good,liked) values ('${f}',true,array['looks'])`)); assertions++;
  await db.exec(`insert into public.private_notes(user_id,about_user,body) values ('${f}','${g}','Dog called Biscuit')`);
  await db.exec(`insert into public.chat_pauses(conversation_id,user_id,back_label) values ('${conv2}','${f}','next week')`);
  await as(g);
  equal(await count('private_reflections'), 0);         // owner only
  equal(await count('private_notes'), 0);               // owner only
  equal(await count('chat_pauses'), 1);                 // both see the pause
  await denied(`insert into public.chat_pauses(conversation_id,user_id,back_label) values ('${conv2}','${f}','tomorrow')`);
  await as(outsider);
  equal(await count('conversation_prefs'), 0);
  equal(await count('chat_pauses'), 0);
  await db.exec('reset role');
  await assert.rejects(db.exec(`insert into public.calls(participants) values (array['${f}','${g}']::uuid[])`),
    e => /no calls before meeting/.test(e.message)); assertions++;
  await db.exec(`insert into public.trust_meetings values ('${f}','${g}',now())`);
  await db.exec(`insert into public.calls(participants) values (array['${f}','${g}']::uuid[])`);
  await as(g);
  await db.exec(`insert into public.messages(conversation_id,sender,kind) values ('${conv2}','${g}','photo')`); // met: allowed
  equal(await count('messages'), 3);

  await db.exec('reset role; set role anon');
  await denied('select * from public.social_preferences');
  await denied('select public.is_social_group_member(null)');
  console.log(`Passed ${assertions} migration/RLS assertions.`);
} finally {
  await db.close();
}
