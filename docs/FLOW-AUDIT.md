# Flow audit — start to finish (Nov 15, 2026)

Order a new member goes through (`lib/screens/root_flow.dart`):
Welcome → age check → phone/email code → verification (ID → liveness →
photo match) → [waitlist] → intentions → about you → taste quiz → privacy →
profile → permissions → home.

## Fixed tonight
| Problem | Fix |
|---|---|
| Verification bar: 3 segments, but the selfie step completed liveness AND photo match together | Three real steps with "Step N of 3", one segment each; photo match is its own step |
| "Upload instead" offered for the live selfie; "Retake" did nothing | Retake/Upload only on the ID photos; Retake confirms it cleared |
| Sign-in screen "Preview Settings" opened full app settings before an account exists | Removed |
| No way into the Privacy Centre from Settings | "Privacy Centre" row added to Settings |
| Intention, structure, pace, availability picked in onboarding were thrown away (You tab always said "Casual Dating") | Saved; You tab and editing read them back |
| Bio, prompts, boundaries, languages from profile creation were thrown away | Saved; editing the profile starts from them |
| Interests were never asked, yet "You both", games and plan ideas depend on them | "Interests · pick up to 8" in profile creation, saved and used everywhere |
| Verification promised a match to "your profile photo" before you've added one | Copy now says the profile photo is matched when you add it |
| Swipe/like: every like on the demo deck became a match | Swipe right or double-tap = like; swipe left = pass; the card flies off; a match only when they already liked you |
| Nowhere to see who I liked | "You liked" in You → Likes & introductions (waiting / matched, undo) |
| "It's a spark" buttons (Message / Plan / Game) all just closed | Each opens the chat, plan composer or games; the match lands in Chats |
| Profile opened from a chat showed Pass / Like | Matched profiles show Message / Suggest a plan |
| Chat messages vanished after leaving the chat | One session chat list; what you send stays |
| Streak only inside Games, number not shared | Streak per person, shown in the chat with one tap to play |
| Tapping a notification did nothing (from Dates) | Every row opens its screen |

All of it is saved on the device (`Services.prefs`, key `sync`), and
`Services.prefs.me` is the one place screens read "my profile" from.

## Check together tomorrow (in this order)
1. **Name and age.** The app shows "You", age 25 (demo). In live mode they
   must come from the verified ID; in demo, ask for a first name after
   verification. The date of birth from the age check isn't used afterwards.
2. **Photos.** The profile photo slots fill with sample images. Wire the
   real photo picker (camera/gallery) and show the chosen main photo on You.
3. **Lifestyle chips** (non-smoker, dog person…) are collected but shown
   nowhere. Either show them on the profile or remove them.
4. **Taste quiz → Dates.** Confirm that "why you're seeing them" changes
   after retaking the quiz from You.
5. **Returning member.** Sign in → straight to home (verified) and app lock
   prompt; check that no onboarding screen shows again.
6. **Every back button** in onboarding returns to the previous step with the
   answers still filled in.
7. **Live mode wiring.** Profile, notes, reflections and comfort rules are
   device-only in demo; map each to its Supabase table before launch
   (`docs/LAUNCH-CHECKLIST.md`).

How to check: `CAPTURE=1 flutter test test/screenshots/capture_test.dart`
(screens → `build/screens/`), or open the local web demo.
