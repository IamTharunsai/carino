# Go live — Supabase + Vercel + NVIDIA AI + Stripe + iPhone testing

Written Nov 15, 2026 for the founder. Do the steps in order. Anything marked
🔑 needs you (an account, a key or a click); everything else is ready in code.

## 0. What's already done in code
- `vercel.json` — Vercel installs Flutter and builds the web app on every push.
- `backend/supabase/functions/ai-proxy` — uses NVIDIA (Nemotron) for opener
  drafts, translation and after-date tips. Tested: ~1.5 s per answer.
- `stripe-checkout` + `stripe-webhook` functions, migration `0011_stripe.sql`.
- Your NVIDIA key is in `backend/supabase/.env` (git-ignored — never uploaded).
- GitHub builds a demo Android APK and an unsigned iPhone `.ipa` you can
  download from each successful Actions run (Artifacts).

## 1. Give Claude access to your new Supabase project 🔑
Your new "Carino" organisation isn't visible to the Supabase connector yet.
Either:
- **Option A (easiest):** claude.ai → Settings → Connectors → Supabase →
  reconnect and tick the **Carino** organisation; or
- **Option B:** create a personal access token at
  supabase.com/dashboard/account/tokens and tell Claude the project ref and
  database password (Claude runs the CLI locally; nothing is committed).

Claude then runs (or you can):
```bash
cd backend
npx supabase link --project-ref <your-ref>
npx supabase db push                                  # migrations 0001–0011
npx supabase functions deploy                         # all functions
npx supabase functions deploy stripe-webhook --no-verify-jwt
npx supabase secrets set --env-file supabase/.env     # NVIDIA + Stripe keys
```

## 2. Supabase Auth settings 🔑 (dashboard → Authentication → URL configuration)
- Site URL: `https://carino-liard.vercel.app`
- Redirect URLs: `https://carino-liard.vercel.app/**` and `carino://login-callback`
- Providers: Email (OTP) on; Phone needs an SMS provider (Twilio) — optional for the pilot.
- Turn on CAPTCHA (Attack Protection) before inviting strangers.

## 3. Vercel environment variables 🔑 (project → Settings → Environment Variables)
| Name | Value |
|---|---|
| `SUPABASE_URL` | `https://<your-ref>.supabase.co` |
| `SUPABASE_ANON_KEY` | the **anon / publishable** key (never the service-role key) |
| `USE_MOCK_BACKEND` | `false` for the live site · `true` for the demo |
Then Deployments → Redeploy. Without these the site builds the demo.

## 4. Testing live before an ID vendor is signed
Real ID verification needs a vendor (Persona/Veriff). Until then, live
sign-ups stop at verification — by design, so the app can't be opened to
unverified strangers. To test with **your own** accounts, mark each test
account verified by hand in Supabase (SQL editor), one at a time, and remove
it before launch:
```sql
-- Test accounts ONLY. Replace with your own test user's id.
update public.verification_records
   set age21_result='passed', liveness_result='passed', photo_match_result='passed',
       badge_state='active', provider='manual-test (not a real ID check)'
 where user_id = '<test-user-uuid>';
```

## 5. Stripe 🔑 (start in the sandbox)
- Where Stripe is allowed: **Decompress bookings** (real-world services) and
  **Plus bought on the website**. Inside the iPhone/Android apps, Plus must use
  Apple / Google billing (store rules) — the app already refuses otherwise.
- Add to `backend/supabase/.env`, then `npx supabase secrets set --env-file supabase/.env`:
  - `STRIPE_SECRET_KEY=sk_test_...`
  - `STRIPE_PRICE_PLUS_MONTHLY=price_...` (create a Product "Cariño Plus", monthly)
  - `STRIPE_WEBHOOK_SECRET=whsec_...` from a webhook endpoint pointing at
    `https://<your-ref>.supabase.co/functions/v1/stripe-webhook`
    with events `checkout.session.completed` and `customer.subscription.deleted`.
    (Local testing: `stripe listen --forward-to <that URL>` — you have the CLI.)
  - `SITE_URL=https://carino-liard.vercel.app`
- Venues get paid through **Stripe Connect**: each partner venue onboards a
  connected account; put its `acct_...` id in `experiences.stripe_account_id`.
  Cariño's commission is taken as the platform fee; the member pays the
  listed price. A venue without Connect can't take online payment (pay at venue).

## 6. iPhone testing from Windows with xtool 🔑
xtool can't build Flutter apps (it builds Swift packages), but it can **sign
and install** the iPhone app GitHub builds:
1. Install xtool (xtool.sh → Installation, Windows uses WSL) and run `xtool setup`
   and `xtool auth` with your Apple ID.
2. GitHub → Actions → latest green "flutter-ci" run → download
   `carino-ios-unsigned`.
3. `xtool install carino-unsigned.ipa` with your iPhone connected.
Free Apple IDs: the app expires after 7 days. For TestFlight / App Store you
need the Apple Developer Program ($99/yr) and a Mac or a cloud Mac to sign.

## 7. Rotate secrets after testing 🔑
- NVIDIA key — it was shared in chat; create a new one and update
  `backend/supabase/.env` + `supabase secrets set`.
- Stripe: keep test keys until launch; live keys only in Supabase secrets.
