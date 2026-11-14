# Cariño: preview, hosting and mobile release

Readiness review: November 13, 2026. This is a working demo with a compiled
Android debug APK, not a production launch candidate. See HANDOFF.md for
implementation details and explicit integration gaps.

## What you can preview

The app has Chats, Stage, Dates, Plans and You. Follow this walkthrough:

1. Welcome → age gate → mock authentication → three-layer verification
   walkthrough → intentions → identity → taste quiz → privacy → profile
   → permission primers → home. Use sample details only. Verification and
   OTP are demo outcomes, not real checks. Returning-account entry still
   follows authentication/verification when there is no signed-in session.
2. Chats → Friends & circles → group → Chat extras → catch-up / Vanish /
   voice integration notice. Make a plan to try the group poll.
3. Stage → human-made/chronological feed → Make it a plan; switch to Moments.
4. Dates → filters → profile → match/chat/Spark previews. Dates stays 21+
   and ID-verified; sample profiles are not actual members.
5. Plans → Tonight / Host / Coffee chats / Guilds → stored plan → cost
   split and own paid mark. No money is transferred.
6. You → Facets / Work facet / Trust Graph; No-Counts and Calm mode;
   Privacy, Trust & Safety, Plus and Settings. AI coach gives craft tips.

All sample state is session memory. Closing/reloading can reset it. Voice
recording/translation, real video, ID verification, purchases, push and
moderation operations still need their providers. Web preview does not prove
camera, microphone, notification or purchase behavior on a physical phone.

Local browser build: `flutter build web --no-pub`, then serve `build/web`
with a local HTTP server. Android demo: `build/app/outputs/flutter-apk/app-debug.apk`.

## Recommended hosting setup

Keep the existing Flutter + Supabase architecture. Avoid adding a second
backend before the existing service interfaces are connected.

| Component | Recommendation | Remaining work |
| --- | --- | --- |
| Database, auth, realtime, storage | Separate Supabase staging and production projects | Apply migrations, provider setup, private buckets, signed media URLs, policies and restore tests |
| Social API | Authenticated Supabase Edge Functions | Friendship invitations, group membership, consent, polls, facet projections, trust codes, vouches, splits |
| AI | Existing server-side AI proxy | Provider credentials, per-feature consent, usage limits, factual catch-up and translation contracts |
| Video | One managed RTC provider, such as Daily or Agora | Provider selection, Flutter SDK, mutual-accept room tokens, disconnect/report behavior |
| Verification | One ID/liveness provider, such as Persona or Veriff | Contract, supported regions, SDK, signed webhooks, human appeal; no raw ID images in app tables |
| Subscriptions | RevenueCat over StoreKit/Google Play Billing | Store products, receipt/webhook validation, restore, refund/revocation handling |
| Notifications | FCM with APNs for iOS | Device tokens, server sender, foreground/background/deep-link tests |
| Media | Private object storage plus screening/transcoding | Capture/upload, captions, EXIF removal, quarantine, signed playback URLs |
| Operations | Error reporting, service metrics and a human support/moderation console | Alerts, delivery failures, abuse/rate limits, access audit and staffed escalation |
| Public pages | Static website on your chosen host | Final domain, support contact, privacy, terms, community/child-safety standards, deletion request page |

These are implementation recommendations, not purchased or connected services.
Choose regions and budgets before provisioning. Track database, storage/egress,
video minutes, ID checks, AI usage, messaging, moderation and backup costs.
Set spending alerts and service quotas before opening registration.

## Backend launch gates

- Replace MockData/session-memory paths with authenticated repositories. A
  successful `db push` does not connect the app's screens to live data.
- Apply 0001–0005 to staging first. Locally they execute in PostgreSQL WASM
  with Auth/Storage shims and 32 authorization assertions. Hosted Auth,
  Realtime, Storage and Edge Function behavior still needs real staging QA.
- Enforce 21+/verification on Dates APIs, not merely navigation. Audit the
  returning-session path. Keep friend and dating audiences separate.
- Implement all 0005 service-owned write endpoints before enabling their UI
  in live mode. Validate participants, blocks, invitations, poll choices and
  strict majority, split rounding, purchase receipts and host reputation.
- Enforce per-field facets in server projections, bilateral expiring trust
  codes and real group-wide Vanish consent. Schedule message/media deletion;
  hiding expired rows is not a deletion guarantee.
- Configure Auth redirect/deep links and real email/SMS delivery. Restrict
  admin/service keys to server secrets. Test expired sessions and revocation.
- Configure scheduled match/moment expiry, check-in escalation, report-SLA
  handling and account deletion. A safety screen cannot promise delivery
  until the sender, retries, alerts and staffed response actually work.
- Test two real accounts on two devices: reconnect/offline recovery,
  persistence after restart, cross-user privacy, blocks, reports, deletion,
  failed uploads, failed verification, missed check-ins and purchase restore.
- Verify backups with an actual restore exercise; database backups and
  uploaded media need an explicit recovery plan.

The existing `.github/workflows/supabase-deploy.yml` runs on backend pushes
to main and manually. It needs `SUPABASE_ACCESS_TOKEN`,
`SUPABASE_DB_PASSWORD`, and `SUPABASE_PROJECT_ID` in GitHub Secrets.
Check which project those secrets target before enabling production use.
It currently links, pushes migrations and deploys functions without a
staging validation gate. Add environment separation before production.

## Android release

- Establish the final reverse-domain application ID; replace
  `com.example.carino` consistently in Gradle and Android sources before
  registering Firebase, verification and billing integrations.
- Configure a private upload keystore and Play App Signing. The checked-in
  Gradle release configuration currently signs with the debug key.
- Confirm target API **36 or higher** for new apps/updates under Google's
  current submission policy; inspect the actual merged manifest because
  this app inherits its SDK values from Flutter.
- Configure camera/microphone/photos/notifications permissions only for
  implemented features. Test background/resume, deep links, accessibility,
  Reduce Motion, font scaling and slow networks on physical devices.
- Create a signed `.aab` with `flutter build appbundle --release` using live
  environment defines only once the backend is ready; upload to internal
  testing first. The debug APK is for preview, not a Play Store release.
- Complete Play Console identity/account setup, privacy URL, Data Safety,
  content rating, app access instructions and account deletion requirements.
- For affected personal developer accounts created after November 13, 2023,
  complete closed testing with at least **12 testers continuously opted in
  for 14 days**, then apply for production access.
- Social/dating apps must meet Google's Child Safety Standards even when
  the app has its own adult-only gate.

## iOS release

- Use macOS with Xcode for archive/signing; this Windows machine cannot
  produce a verified signed iOS release. CI contains an unsigned macOS build
  job, but that is not a TestFlight upload or physical-device QA result.
- Register the final Bundle ID, Apple team and App Store Connect record;
  configure distribution signing/provisioning, APNs, universal links and
  store products. Current upload minimum is **Xcode 26+ / iOS 26 SDK+**.
- Add accurate camera/microphone/photo usage descriptions as those SDKs
  land. Review SDK privacy manifests, required-reason APIs and collected data.
- Test camera/voice/video, interrupted calls, backgrounding, purchases and
  push on physical iPhones; use TestFlight before App Store submission.
- Complete App Privacy, age-rating questions, support/privacy URLs, export
  compliance and reviewer access. Demonstrate reporting, blocking, content
  filtering, moderation and reachable support for user-generated content.
- Explain the real differentiation: private facets, friends-to-plans,
  reciprocal verified dating, finite feed and professional coffee chats.
  Apple explicitly scrutinizes repetitive dating-app submissions.

## Feature priorities for a strong launch

First release: reliable persistent chat/groups, privacy facets, verified
Dates, plans/polls, real report/block handling, check-ins with tested delivery,
No-Counts and accessibility. These make the existing product trustworthy.

Next: reliable video/voice with captions and consent, factual catch-up,
real meeting confirmations/warm intros, curated coffee chats and guilds.

Later: gifts, host revenue share and paid extras, after receipts, disputes,
moderation and support are operational. Keep splits as manual records unless
a separately designed payments product is approved. Keep safety free, AI
drafts member-sent, no fabricated engagement and no attractiveness scoring.

## Official references

- [Flutter Android release](https://docs.flutter.dev/deployment/android)
- [Flutter iOS release](https://docs.flutter.dev/deployment/ios)
- [Google target API policy](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [Google closed-testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- [Google Developer Program Policies](https://support.google.com/googleplay/android-developer/answer/18265346?hl=en)
- [Apple SDK upload requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Supabase production checklist](https://supabase.com/docs/guides/deployment/going-into-prod)
- [RevenueCat Flutter SDK](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [FCM for Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
