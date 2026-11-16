# Publishing Cariño — web, Google Play, App Store

Written Nov 15, 2026 for the founder. 🔑 = needs you (an account, payment or a click).
Do [GO-LIVE.md](GO-LIVE.md) first: Supabase, Vercel environment variables, NVIDIA and Stripe.

## Order of launch
1. **Web (now):** carino-liard.vercel.app. Plus is sold by Stripe on the web, which is allowed.
2. **Android, internal testing, then closed testing:** fastest store review.
3. **iPhone, TestFlight, then App Store.**

## 1. Accounts 🔑
| What | Cost | Notes |
|---|---|---|
| Google Play Console | $25 once | Organisation account (needs a D-U-N-S number) avoids the 12-tester / 14-day rule for personal accounts |
| Apple Developer Program | $99/yr | Organisation account; needs D-U-N-S |
| ID-verification vendor (Persona / Veriff) | per check | Live sign-ups stop at verification without it, by design |
| Support email + privacy policy URL | — | Both stores require them; host the policy on the Vercel site |

## 1b. App ID 🔑 (permanent: pick once)
The app is still `com.example.carino`, which both stores refuse. Choose the real ID
(e.g. `com.<yourcompany>.carino`) and Claude will change it in `android/app/build.gradle*`
(`applicationId` + `namespace`, plus the Kotlin package folder) and in the iOS
project's `PRODUCT_BUNDLE_IDENTIFIER`. Once an app is uploaded, its ID can't change.

## 2. Store products 🔑 (create the same IDs in both stores)
| Product ID | Type | Price (US) |
|---|---|---|
| `carino_plus_monthly` | Auto-renewing subscription, group "Cariño Plus" | $12.99 |
| `carino_plus_annual` | Auto-renewing subscription, same group | $89.99 |
| `carino_superlikes_5` | Consumable | $4.99 |

Free trials: if you offer one, set it in the store (it's shown in the store's own sheet).

## 3. Code still needed before the phone apps can sell (≈1–2 days, after the products exist)
- Add the `in_app_purchase` plugin. `PaymentsService.purchaseDemoPlus` becomes a real
  purchase for the IDs above; restore uses the store's restore.
- A `verify-purchase` Edge Function: validate receipts with Apple's App Store Server API
  and Google's Play Developer API, then write `entitlements` (the same table the Stripe
  webhook writes). The app reads Plus from `entitlements`, never from the device.
- This can't be tested until the store products exist, so it's built after step 2.
  Until then, live phone builds say honestly that Plus isn't on sale yet.

## 4. Android release 🔑
```bash
keytool -genkey -v -keystore carino-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
# android/key.properties (git-ignored): storePassword, keyPassword, keyAlias=upload, storeFile=../carino-upload.jks
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key> \
  --dart-define=USE_MOCK_BACKEND=false
```
Upload `build/app/outputs/bundle/release/app-release.aab`. In Play Console:
- **Content rating:** dating app, 18+.
- **Target audience:** adults only.
- **Data safety:**
  - Collected: location (approximate), photos, ID-verification result, messages.
  - Encrypted in transit; deletion available in the app.
- **Dating app declaration:** ID verification, report and block in-app.
- **App access:** give reviewers a pre-verified test login (see GO-LIVE §4).

## 5. iPhone release 🔑
Needs a Mac, a cloud Mac (MacinCloud, ~$1/hr) or GitHub's macOS runner with signing secrets.
1. In App Store Connect, create the app with the bundle ID from §1b.
2. Run `flutter build ipa --release` with the same three `--dart-define`s, then upload with Transporter.
3. Send it to TestFlight (internal testers get it the same day).
4. For App Review:
   - age rating 18+
   - privacy nutrition labels (same items as Data safety)
   - a demo account
   - review notes that explain the ID check, Decompress bookings and in-app purchases
5. Rules reviewers check for dating apps:
   - report and block on every profile and chat (done)
   - account deletion in the app (done)
   - in-app purchases only through Apple (done; Stripe only for real-world bookings and the web)
   - no links to buy Plus on the web from inside the iPhone app (done)

xtool (Windows) can install the unsigned GitHub build on your own phone for testing,
but it can't publish to the App Store.

## 6. Launch checklist
- [ ] GO-LIVE steps done; `USE_MOCK_BACKEND=false` on Vercel
- [ ] ID vendor live; manual test-verify rows removed
- [ ] Store products created; purchase verification built and tested in sandbox
- [ ] Privacy policy, terms and support email live on the website
- [ ] Review prompts only at happy moments (MONETIZATION-STRATEGY §6)
- [ ] NVIDIA and Stripe keys rotated; live Stripe keys only in Supabase secrets
