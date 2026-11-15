# Notifications — architecture and workflow

Goal: notifications people are *glad* to get, so they keep them on. That
beats volume: an app whose notifications get muted loses the channel for good,
and fake ones ("someone viewed you", messages nobody sent) break store rules
(Apple 5.6, Google Play deceptive behaviour) and the Cariño honesty promise.

## Rule zero
A notification exists only because something real happened. AI may choose
the **words, language and timing**; it never chooses the **facts**.

## Pipeline
```
real event (DB insert: message, match, like, plan, check-in, moment reply)
   │  Postgres trigger writes a row to notification_outbox (same transaction)
   ▼
notify worker (Edge Function on a queue / cron every few seconds)
   1. Load the member's prefs: language, tone, categories off, quiet hours
      (in THEIR timezone), daily cap, generic lock-screen previews
   2. Rules (lib/models/notify.dart `compose`, ported 1:1 server-side):
      - category off → drop (safety check-ins can't be turned off)
      - quiet hours → hold until morning (safety always goes through)
      - daily cap 5 → drop extras (messages, plans and safety are exempt)
      - collapse: 4 messages from Aria → one "Aria sent 4 messages"
      - de-duplicate by (member, kind, subject) within 10 minutes
   3. Copy: template for the member's language + tone, slots filled with the
      real facts ({who}, {detail}).
      Optional AI polish: the model may only REPHRASE the template; output is
      rejected unless every slot value is present unchanged and no new name,
      number or claim appears → fallback to the template.
   4. Send via FCM (Android) / APNs (iOS) with a collapse key; the lock-screen
      text is generic ("Cariño · Something new for you") unless the member
      turned previews on.
   5. Log delivered / opened / dismissed / disabled (no message content).
   ▼
learning (opt-in): best send hour per member from their own opens; a
category someone keeps dismissing gets sent less. Guardrail metric: opt-out
rate — if it rises, the system sends less, never more.
```

## Languages
English, Spanish, Hindi, Telugu, French, Portuguese ship as templates in
`lib/models/notify.dart` (native-speaker review before launch). Move to ARB
files when more languages are added.

## What makes someone open the app (honestly)
- A real person waiting: "Aria sent you a message", "Plan tomorrow: Coffee with Aria".
- A real like, without the name for free members: "A verified person liked your profile".
- Streaks: "Day 5 with Sofia — one game keeps it going" (real streak only).
- Daily Drop at the member's chosen hour.
- Never: invented views, invented messages, fake countdowns, guilt copy.

## Status
✅ Rules, languages, tones, caps, quiet hours, generic lock screen (tested in
`test/notify_test.dart`); in-app preview on the Notifications screen.
🔑 To build for live: `notification_outbox` table + triggers, the worker
Edge Function, FCM/APNs keys, device-token table.
