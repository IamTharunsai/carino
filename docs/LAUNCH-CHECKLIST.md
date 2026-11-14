# Cariño — Final launch checklist (Nov 14, 2026)

The code side is release-ready for a **pilot**: 89 automated tests, clean
analyzer, release APK builds, 48 database security assertions, 54-screen
visual audit. What remains needs **your accounts, keys, legal text and
people** — no code can do these for you. Work top to bottom.

Legend: ✅ done in code · 🔑 needs you · ⚠️ decision/risk

---

## 1. Decisions to make first
- 🔑 **App ID / bundle ID.** Currently `com.example.carino` — Google Play and
  Apple reject `com.example.*`. Pick a reverse-domain you own (e.g.
  `app.carino`), then change `applicationId` + `namespace` in
  `android/app/build.gradle.kts`, the Kotlin package folder of
  `MainActivity.kt`, and `PRODUCT_BUNDLE_IDENTIFIER` in Xcode.
- ⚠️ **Name clearance** for "Cariño" (trademark search in your markets).
- ⚠️ **"Tonight" intention.** Apple bans hookup-style apps. Keep it framed as
  "verified, public plans" (it is) — or rename before iOS review.
- ⚠️ **Apple "saturated dating" risk (Guideline 4.3).** Submit as a
  *social app with a 21+ Dates tab*, and lead the review notes with what's
  unique: 3-layer ID verification, plans engine, Honest Status, finite feed.

## 2. Accounts
- 🔑 Google Play Console ($25) · Apple Developer Program ($99/yr).
- 🔑 Supabase project (Pro plan for backups/PITR).
- 🔑 Verification vendor (Persona/Veriff class, must return a 21+ result).
- 🔑 RevenueCat + store products (Plus monthly/annual) in both stores.
- 🔑 LLM API key for the AI proxy (server-side only).
- 🔑 Support email + website (privacy policy, terms, account-deletion page).

## 3. Backend go-live
1. 🔑 `supabase link` to your project, then `supabase db push` (applies
   migrations 0001–0006). ✅ All six migrations are tested in
   `backend/tests` (48 RLS assertions) — run `cd backend/tests && npm test`
   first.
2. 🔑 Set Edge Function secrets: `ANTHROPIC_API_KEY`/`OPENAI_API_KEY`,
   verification vendor keys, `SCHEDULER_SECRET`; deploy all functions in
   `backend/supabase/functions` (`supabase functions deploy`).
3. 🔑 Auth settings: enable Phone + Email OTP, Google, Apple; add redirect
   URL **`carino://login-callback`** (✅ already registered in the Android
   manifest and iOS Info.plist).
4. 🔑 Schedule the jobs: match-expiry, report-sla, moderation-intake.
5. 🔑 Run Supabase **Security Advisor** and fix anything it flags.

## 4. Build the store binaries
```powershell
# Android (needs android/key.properties + your upload keystore; gitignored)
flutter build appbundle --release `
  --dart-define=SUPABASE_URL=https://<project>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```
- ✅ Release builds **refuse to start** without these values (no sample
  people can ever ship by accident). Demo/preview builds:
  `--dart-define=USE_MOCK_BACKEND=true`.
- ✅ Release signing reads `android/key.properties`
  (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). 🔑 Create the
  keystore: `keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
- ✅ Targets Android 16 (API 36) — meets Google Play's current requirement.
- 🔑 iOS: open `ios/Runner.xcworkspace` on a Mac, set Team + bundle ID,
  add a **PrivacyInfo.xcprivacy** (UserDefaults reason `CA92.1` for
  shared_preferences), then Product → Archive. ✅ Face ID usage string and
  URL scheme are already in Info.plist.

## 5. Store compliance (both stores)
| Requirement | State |
|---|---|
| Age: 21+ gate + ID verification; store rating 18+ (Apple requires 18+ for dating from Nov 16, 2026) | ✅ app · 🔑 set rating |
| Apple: "Dating and Relationships" + "Shared Location" declarations (due Jan 12, 2027) | 🔑 App Store Connect |
| UGC: report, block, filter, 24 h review | ✅ app · 🔑 staff the 24 h rota |
| In-app account deletion | ✅ (delete-account function) · 🔑 web deletion page URL for Google |
| Sign in with Apple offered alongside Google | ✅ |
| Subscriptions through store billing only, Restore, cancel route, renewal terms shown | ✅ UI · 🔑 RevenueCat products |
| No anonymous random video chat | ✅ Spark is mutual-accept, verified only |
| AI content labelled; AI never chats as a user | ✅ |
| Privacy policy + Terms with zero-tolerance clause, linked in-app and in listing | 🔑 legal text |
| Google Data Safety form / Apple privacy labels matching real collection (verification vendor, analytics, AI, crash reporting) | 🔑 fill after vendors chosen |
| Screenshot protection honesty (Android blocks in Vanish; iOS detects only) | ✅ |
| No backups of private data (`allowBackup=false`) | ✅ |
| Biometric data never leaves the device | ✅ |

## 6. Test before submitting
- ✅ `flutter test` (89) · `flutter analyze` · `cd backend/tests && npm test`.
- ✅ Visual audit: `CAPTURE=1 flutter test test/screenshots/capture_test.dart`
  → `build/screens/` (also your store screenshots).
- 🔑 **Real-device pass** (one Android, one iPhone) against the LIVE
  backend: sign up → DOB → OTP → verification → profile → like → match →
  chat (incl. scam warning) → plan → check-in → report/block → delete
  account. Also: app lock on/off, Google + Apple sign-in round-trip, Vanish
  screenshot block, offline/poor-network behaviour.
- 🔑 Internal testing track (Play) + TestFlight with 10–20 real people.

## 7. Operations on day one
- 🔑 Moderation + support staffed (24 h report SLA is an Apple 1.2 duty).
- 🔑 Crash reporting (Sentry-class) and analytics provider (PostHog-class)
  connected to `Services.analytics`; opt-out stays in You → Your activity.
- 🔑 Pilot city waitlist on (`remote_config` → city batch).

## 8. Marketing launch
- Store listing built on "Verified people. Real plans." (see
  `docs/EXPERIENCE-STRATEGY.md` §3 for the ethical psychology rules).
- Referral programme live (verified friends only, 10 weeks/year cap).
- Optional: simulate messaging and pricing with MiroFish
  (`docs/mirofish/README.md`) — then validate with real pilot users.

## Known limits (be honest in review notes)
- Couples mode, wingperson, hosted plans, stage feed and guilds run on
  local/demo data until their tables/endpoints are wired (tables for
  groups, polls, guilds, check-ins already exist: migrations 0004–0006).
- Passkeys: platform passkeys not yet wired; the button refuses in live
  mode rather than faking a sign-in.
