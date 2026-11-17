# Cariño — Figma Design Brief ("Lavender Dream")

For: whoever designs Cariño in Figma (you, a designer, or Figma AI). Everything needed to draw every screen with
no guessing: palette, type, sizes, components, icons, emoji, motion, every screen pin by pin, and ready-to-paste
Figma AI prompts. Brand files in the repo: `PRODUCT.md` (who/why) and `DESIGN.md` (tokens).

---

## 1. Vision in one breath
**Cariño is the sweet friend who helps you meet someone real — and makes sure you get home safe.**
An unlimited, playful Feed for fun; a calm, face-checked Dates deck (10 hearts a day) for meeting;
Plans, Tables and tickets to actually go out. Personality: **warm · playful · safe**. Light by default.

The feeling to design for: *a lilac evening sky, a hand-written note, a heart doodled in the margin.*
Not Tinder red-alert. Not LinkedIn serious. Not generic AI cream-and-glass.

---

## 2. Colour

### 2.1 Lead palette — Lavender Dream (light, default)
| Figma variable | Hex | Where |
|---|---|---|
| `bg/canvas` | #F6F2FC | every screen background (lilac mist) |
| `bg/surface` | #FFFFFF | cards, sheets, nav bar, inputs on photos |
| `bg/soft` | #EFE8FA | chips, input fills, quiet buttons, skeletons |
| `text/ink` | #241B35 | titles, body (14.8:1 on canvas) |
| `text/soft` | #5E5470 | secondary text, captions (6.4:1) |
| `line/hair` | #E4DBF3 | dividers, card borders (1px) |
| `brand/violet` | #6C3BD1 | primary buttons, selected tab, links (white on it 6.6:1) |
| `brand/violet-deep` | #4B2399 | pressed state, focus ring |
| `love/heart` | #FF4F8B | heart icons, like burst, "It's mutual" (icons/large only) |
| `love/heart-text` | #D6266A | any heart-coloured TEXT (4.8:1) |
| `love/heart-soft` | #FFE1EC | heart chip backgrounds, "likes you" badge bg |
| `trust/gold` | #B07F17 | the gold verified tick (3.6:1, icon-safe) |
| `state/success` | #2EAD6B | "home safe", online dot |
| `state/danger` | #E5484D | SOS, report, delete |
| `gradient/dream` | #6C3BD1 → #FF4F8B, 135° | ONLY: match celebration, Plus, Feed active tab pill, gift moments |

### 2.2 Dark mode
canvas #15111F · surface #211B30 · soft #2C2440 · ink #F3EEFF · ink-soft #B9AECF · line #3A3150 ·
violet #9C7BF0 · heart #FF6FA1 · gold #F0BE55 · success #45C987 · danger #FF6B6E.
Reels/Feed are always dark-on-photo regardless of theme.

### 2.3 Alternatives (for A/B in Figma — same tokens, swap values)
| Token | Rose & Navy | Midnight Editorial |
|---|---|---|
| canvas | #FFFFFF | #0E0E10 |
| soft | #DBF2FC (ice) | #1B1B1F |
| ink | #072D59 (navy) | #F5F1E8 |
| primary | #FD6E88 (crimson pink, use navy text on it) | #F7D774 (butter, black text) |
| heart | #FD6E88 | #F7D774 |
| gold tick | #C08A1C | #F7D774 |

### 2.4 Colour rules
- Violet = "do". Heart pink = "love". Gold = "verified". Never swap them.
- Max one gradient per screen. No gradient text. No glass blur except the floating nav bar over photos.
- Colour never carries meaning alone: every state also has an icon or a word.

---

## 3. Typography
Fonts (Google, free): **Fraunces** (Soft 100, Opsz auto) for names & headlines · **Plus Jakarta Sans** for everything else.

| Style | Font | Size/Line | Weight | Use |
|---|---|---|---|---|
| Display | Fraunces | 34/40 | 600 | welcome headline, match screen |
| H1 | Fraunces | 28/34 | 600 | tab titles ("Dates", "Plans") |
| H2 | Fraunces | 22/28 | 600 | profile names on cards ("Aria, 24") |
| H3 | Jakarta | 18/24 | 700 | section titles |
| Title | Jakarta | 16/22 | 600 | list titles, buttons |
| Body | Jakarta | 15/22 | 400 | paragraphs, chat bubbles |
| Caption | Jakarta | 13/18 | 500 | metadata, chips |
| Micro | Jakarta | 11/14 | 600 | badges, tab labels, timestamps |
Letter-spacing: display -1%, body 0, micro +2%. Max line length 38 characters on cards, 60 in long text.

---

## 4. Layout, shape, depth
- Frame: **iPhone 16 Pro 393 × 852** (also check 375 × 667 and Android 412 × 915).
- Side margin **20**, gutters **12**, 4-pt spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40.
- Radius: photo cards **28** · cards **24** · sheets **28 (top)** · inputs **16** · buttons & chips **pill (999)** · avatars circle.
- Elevation (only 2 levels): `lift-1` 0 2 8 rgba(108,59,209,.08) for cards; `lift-2` 0 12 32 rgba(108,59,209,.16) for floating nav, sheets, match cards.
- Touch targets ≥ 44 × 44. Bottom nav floats 12 above the home indicator.

---

## 5. Icons, emoji, imagery

### 5.1 Icons — Phosphor (Regular 1.5px; active/selected = Fill), 22px default, 24 in nav, 18 in chips
| Action | Phosphor icon |
|---|---|
| Feed tab | `PlayCircle` | 
| Dates tab | `Flame` |
| Chats tab | `ChatCircleDots` |
| Plans tab | `CalendarHeart` |
| You tab | your avatar (28px circle, violet ring when active) |
| Heart / like | `Heart` (Fill when liked, love/heart) |
| Crush (super like) | `Sparkle` |
| Not now (pass) | `X` |
| Expand profile | `ArrowsOutSimple` |
| Comment | `ChatCircle` · Gift `Gift` · Share `PaperPlaneTilt` · More `DotsThree` |
| Filters | `SlidersHorizontal` · Search `MagnifyingGlass` · Worldwide `GlobeHemisphereWest` |
| Rewind | `ArrowCounterClockwise` · Notifications `Bell` |
| Verified | `SealCheck` Fill in trust/gold |
| Safety / SOS | `ShieldCheck` · `Siren` (danger) |
| Home safe | `HouseLine` · Location `MapPin` · Booking `Ticket` |
| Camera | `Camera` · Video `VideoCamera` · Mic `Microphone` |
Cute rule: icons sit inside **soft circles** (40px, bg/soft) on lists; never bare, heavy, or filled-black.

### 5.2 Emoji — purposeful, not decorative
- Reactions & Heartbeats: 💓 😘 🔥 🌹 🥰 😏 ☕
- Gifts: 🌹 Rose · ☕ Coffee · 💖 Heart · 🍫 Chocolates · 💐 Bouquet · 💎 Diamond
- Moments of feeling in copy: "It's mutual 💞", "Your Flame 🔥", "Home safe 💛", "Plan ideas 💫", "Show them you ✨"
- Profile basics chips (like the reference): ♍ Virgo · 🍷 Drinks socially · 🌱 Vegetarian · 🏃 Runs · 🐶 Dog person · 📚 Books · 🎵 Music · ✈️ Travel
- Never as navigation or system icons.

### 5.3 Imagery
Real, warm, candid people — golden hour, string lights, cafés, parks, laughing mid-sentence. Diverse ages 21–40,
ethnicities, bodies. Never glossy stock, never AI faces. Photos fill cards edge to edge with a soft bottom
gradient (ink 0% → 70%) for text. No background photos behind UI pages.

### 5.4 Signature illustration — the LoveMark
One continuous hand-drawn line: a tail swoops in, draws a heart, trails off with a flourish (2px, love/heart).
Use: welcome headline, empty states, match screen, app icon, loading. Plus "orbit dots": small avatars on a dashed
lilac circle around a central face (onboarding + match screens, like the HUSHH reference).

---

## 6. Components (build these first in Figma as components with variants)
1. **Button** — Primary (violet pill, white Title text, 52h), Secondary (white pill, 1px line, ink text), Ghost (text violet), Love (dream gradient, white) — states: default/pressed (-4% scale, violet-deep)/disabled (bg/soft, ink 38%)/loading (spinner).
2. **Chip** — filter / interest / basics: pill 32h, bg/soft, Caption; selected = violet 12% bg + violet text + leading check.
3. **Avatar** — 24/32/44/56/88; online dot (12px success, 2px white ring); story ring (2px dream gradient); gold tick overlay bottom-right.
4. **Profile card (Dates)** — 353×520 photo card, radius 28, photo-dots indicator top (segments), chips row "Ready for something real", name H2 white + age light, location Caption with MapPin, gold tick, 3 floating action buttons below card: Not now (56 white), Heart (68 violet → turns heart pink on tap), Crush (56 white, Sparkle).
5. **Reel overlay (Feed)** — full-bleed media, right rail (avatar w/ online dot + follow "+", Heart+count, Comment, Gift, Share, More) 44 spacing; bottom-left name + gold tick + Follow pill (white 20% bg) + caption 2 lines; top: Feed | Moments segmented pill + tune + post.
6. **Bottom nav** — floating white pill 64h, radius 32, lift-2, 5 items; active item = violet bg 12% pill behind icon + tiny heart dot below; Chats badge = heart pink count.
7. **List row** — 64h, 40px soft-circle icon, Title + Caption, chevron.
8. **Chat bubbles** — mine: violet, white text, radius 20/20/6/20; theirs: white, ink text, 1px line; timestamp Micro; tone tag chip; "Seen" for Plus.
9. **Sheet** — white, radius 28 top, drag handle 36×4, close X top-right (always), title H3.
10. **Toast** — ink pill, white text, icon left, 3s.
11. **Empty state** — LoveMark + H3 + one sentence + one button.
12. **Inputs** — 52h, bg/soft fill, radius 16, label above (Caption soft), focus 2px violet.
13. **Paywall table** — Free vs Plus columns, Plus header in dream gradient pill, ticks in violet.

---

## 7. Motion (ease-out-quart unless noted; everything has a Reduce Motion fallback = 150ms crossfade)
| Moment | Spec |
|---|---|
| Tap any button | scale 0.96, 120ms, back 160ms |
| Tab switch | active pill slides to new tab 250ms; icon Regular→Fill crossfade 150ms; heart dot pops 0→1 scale 200ms |
| Swipe card | follows finger, rotates ±12° max, LIKE/NOT NOW/CRUSH stamp fades in by drag distance; release > 30% width flies off 220ms |
| Heart tap / double-tap | heart scales 0→1.3→1 in 450ms with 6 tiny hearts bursting outward, light haptic |
| It's mutual 💞 | two photos slide in from sides 400ms, overlap, orbit dots rotate slowly (10s loop), confetti hearts 1.2s, success haptic |
| Reel scroll | snap paging, 280ms; heart rail counts tick up |
| Sheet open | slide up 320ms + scrim 0→40% |
| Gold tick earned | seal draws stroke 500ms then sparkle |
| Heartbeat sent | emoji floats up from avatar and fades 700ms |
| Face check | oval outline pulses softly while searching; turns success green when framed; head-turn arrows nudge 2px |
| Loading | skeleton shimmer in bg/soft, 1.2s loop (no spinners on lists) |

---

## 8. Navigation
Tabs: **Feed · Dates · Chats · Plans · You** (Feed first = faces first). Each tab: 56h top bar, H1 title left, 2–3 icon buttons right.
Settings live behind ☰ on You. Back = chevron-left top-left on every pushed screen. Sheets always have an X.

---

## 9. Screens — pin by pin (draw each as its own frame; names match the app)

### A. Onboarding
1. **Welcome** — canvas; logo top-left; orbit of 3 tilted photo cards (or HUSHH-style orbit circle) with "It's mutual" pill; LoveMark; Display "Find your kind of spark."; Body line; Primary "Create account →"; Secondary "I already have an account"; Terms · Privacy · Guidelines links.
2. **Create account** — H1 "Create your account"; 3 buttons: Continue with Apple (black), Google (white), Phone or email (violet); small privacy line.
3. **Phone/email + password** — inputs with labels, show-password eye, "At least 8 characters" helper, Primary "Send me a code".
4. **Code** — 6 boxes (like reference), resend timer, change number link.
5. **Birthday** — wheel date picker, "You must be 21+" rule, never shown publicly.
6. **Face check** — full camera, oval mask, top label "Quick face check · 10 sec", live hint pill ("Move a little closer"), 3 progress segments, Cancel X. Success: oval turns green + check.
7. **Profile builder** (one page, scroll) — "Show them you ✨"; "Fill it in with AI — just chat" button; Photos & videos grid (3×3, first big); Video intro card (record / play / retake / delete); Voice intro card (record ● timer, Listen, Retake, Delete); Bio; Prompts chips → answer fields; Languages chips + search sheet; Interests chips + "Add your own"; Lifestyle chips; Boundaries; Primary "Save & go" (needs 1 photo).
8. **AI coach chat** — chat bubbles, coach asks one question at a time, result card with Bio / Interests / Prompt, Primary "Use this".

### B. Feed (tab 1)
9. **Reels** — see component 5; double-tap heart burst; "AI-made" chip when relevant.
10. **Moments** — stories row (avatars with gradient ring, "Your story +"), 24h cards grid.
11. **Creator profile** — avatar w/ online dot, name + gold tick, "Active now", posts count; Follow / Subscribe ($4.99/mo) / Gift; tabs Top · Recent · Short (like reference); 3-col grid, locked posts show lock + blur; web banner "Get the app".
12. **Comments sheet** — list; composer for Plus/subscribers; others see "Comment with Plus or by subscribing".
13. **Gift sheet** — credits balance, emoji gifts grid with credit cost, packs (3 for $0.99, 10 for $2.99, 40 for $9.99).
14. **Post composer** — media preview, caption, "How long should it stay?" Forever / 24h / 7 days, Share.

### C. Dates (tab 2)
15. **Deck** — top bar: "Dates" + Search, Worldwide, Bell, Filters; Nearby | Daily Drop chips; today's ritual line ("Sunset Sunday — slow Sundays…"); profile card; hearts left counter "7 hearts left today 💗" (Caption).
16. **Profile detail** — full photo carousel, name H2 + gold tick, location pill, basics chips with emoji (like reference "My Basics"), About me, What I'm looking for, Interests, prompts, voice intro, "How Aria texts", 🔥 Flame with you; floating bar Not now / Heart / Message (if matched).
17. **Filters** — Where: Near me / Another city / Worldwide (Plus); distance slider; age range; language; Real photos only; Verified only; Plus filters.
18. **Search by vibe** — search field "hike on Sundays…", results grid 2-col photo cards (like reference "Explore people near you").
19. **It's mutual 💞** — dream-gradient canvas, two photos overlapping in orbit, Display "It's mutual", buttons: Send a message, Suggest a plan, Play a game, "Keep looking".
20. **Out of hearts** — sheet: "That's your 10 hearts for today 💗", "New hearts at midnight", See Plus.
21. **Caught up** — LoveMark, "You're caught up", next Drop time, "Invite friends — fill your city faster".
22. **Get your gold tick** — intro (what we keep, who checks it, optional), ID front/back, selfie, result with gold seal animation.

### D. Chats (tab 3)
23. **Chat list** — search; **Heartbeats** row (avatars with 🔥n under name); New matches row; conversations (avatar w/ online dot, name, last message, time, unread heart badge); swipe right = Pin, left = Hide; "Hidden chats 🔒" row at bottom.
24. **Conversation** — header avatar + name + gold tick + call/video/plan/theme; sync strip (pace note, "You both" chips, 🔥 Flame day); bubbles; tone tag chips; plan bridge card; composer (+, field, ✨ AI vibe, send). + menu: Photo/Video, View-once, Tone tag, Sticker, Voice note, Play a game, Plan ideas 💫, Vanish mode, Translation, Pause.
25. **AI vibe picker** — 😊 Just me · 🌹 Romantic · 😂 Funny · 😏 Flirty → 3 draft chips above composer ("Draft — edit before sending").
26. **Chat theme** — bubble colours row + wallpapers (gradients + My photo).
27. **Group chat** — sender names, photos/videos, plan vote card.
28. **Spark call** — pre-call checklist, call screen with 15-min free timer.

### E. Plans (tab 4)
29. **Plans home** — "1 upcoming plan 💫" card with 4 steps Pick · Agree · Book · Go + "Create a plan"; rows: Group plans, Tables & tickets / Private circles / My tickets; Spark Sessions; Decompress; Meet in real life list.
30. **Create a plan** — what/where/when chips, group size, instant join, check-in code (optional), note.
31. **Plan detail** — confirm/propose/decline, Book it sheet (🍽️ table, 🎟️ tickets, 🏨 stay, 🌲 parks, 🚗 ride), check-in card, "I'm home safe", "I don't feel safe" SOS, split the cost (local currency), add to calendar.
32. **SOS sheet** — "Alert my trusted contacts" (violet), "Call 911/112" (danger).
33. **Tables** — night cards (area, dress vibe, price/seat, seats left), booking, reveal screen, no-show policy in plain words.
34. **Tickets / My tickets / Circles / Circle detail (invite link) / Concierge chat**.

### F. You (tab 5)
35. **Profile** (Instagram-style, like HUSHH reference) — name + gold tick, ☰; avatar 88 with story ring; Posts · Followers · Following; bio; interests; "Get your gold tick" card (if not gold); Edit profile / Share profile pills; tabs Top · Recent · Short; 3-col grid with ⏱ on timed posts.
36. **Settings & account** (like HUSHH side menu) — sections: Your profile · Dating · Subscription & payments · Privacy & safety · Notifications & app · Account; each row = soft-circle icon + title + caption + chevron.
37. **Cariño Plus** — dream-gradient header, Free vs Plus table, $7.99/month · $59.99/year cards, honest renewal text, restore purchases.
38. **Trusted contacts & SOS**, **Notifications** (language + tone + live preview), **Privacy Centre**, **Delete account**.

### G. States (draw once, reuse)
Empty (LoveMark), Loading (skeleton), Error ("Something went wrong — try again" + retry), Offline banner, Permission denied (camera/mic/location with "Open settings").

---

## 10. Voice & words (use exactly)
heart (not like) · crush (not super like) · Not now (not pass) · It's mutual 💞 (not match) · Flame 🔥 (not streak) ·
Heartbeats (one-tap emoji) · gold tick (not badge) · Plans · Tables · "Home safe 💛". Warm, short, a little cheeky; never guilt.

---

## 11. Figma file setup
Pages: `00 Cover` · `01 Foundations` (variables, type, icons, LoveMark) · `02 Components` · `03 Onboarding` · `04 Feed` · `05 Dates` · `06 Chats` · `07 Plans` · `08 You` · `09 States` · `10 Prototype`.
Variables: collections `Color` (modes Light/Dark), `Space`, `Radius`. Auto layout everywhere; frames named exactly like section 9 (e.g. `C15 Dates / Deck`).
Prototype: Smart Animate for tab pill, card swipe, sheet open, match screen.

---

## 12. Figma AI prompts (paste into Figma "First Draft"/"Make")

**Master style prompt (paste first, every time):**
> Mobile dating + social app "Cariño", iPhone 16 Pro frame 393×852, light mode. Style: soft, dreamy, warm, playful and safe — lilac-mist background #F6F2FC, white cards radius 24, photo cards radius 28, pill buttons, violet #6C3BD1 primary, heart pink #FF4F8B for hearts only, gold #B07F17 verified tick, ink text #241B35. Fonts: Fraunces 600 for names and headlines, Plus Jakarta Sans for UI. Phosphor icons regular 22px inside soft lilac circles. Floating white pill bottom nav (Feed, Dates, Chats, Plans, You) with violet active pill and tiny heart dot. Real candid golden-hour photos of diverse adults 21–40. Generous spacing (20px margins, 4pt grid), soft violet shadows, no glassmorphism, no gradient text, no cream backgrounds.

**Per-screen prompts (append to the master prompt):**
1. Welcome: "Welcome screen with an orbit of three tilted photo cards of couples at golden hour, a small pill 'It's mutual' with a pink heart, a hand-drawn line heart above the headline 'Find your kind of spark.', subtitle 'Real people, real plans, and a date you'll actually go on.', violet pill 'Create account →', white outline pill 'I already have an account', tiny Terms/Privacy links."
2. Face check: "Full-screen front camera with a dark mask and a white oval face guide, hint pill 'Move a little closer', label 'Quick face check · 10 sec', three progress segments, cancel X."
3. Dates deck: "Dates screen: title 'Dates' in serif, icons search/globe/bell/filters, chips Nearby and Daily Drop, a large photo card of a smiling woman with name 'Aria, 24' in serif and a gold verified seal, chips 'Ready for something real', 'Coffee', 'Photography', and below the card three round buttons: white X, big violet heart, white sparkle. Caption '7 hearts left today 💗'."
4. Profile detail: "Profile detail with photo carousel, name 'Aria, 24' + gold seal, location pill, 'My basics' emoji chips (♍ Virgo, ☕ Coffee, 🌱 Vegetarian, 🐶 Dog person), sections About me / What I'm looking for / Interests in white cards, a floating bar with X, heart, message."
5. It's mutual: "Match celebration on a violet-to-pink gradient: two circular photos overlapping inside a dashed orbit with small floating hearts, headline 'It's mutual 💞', buttons 'Send a message', 'Suggest a plan', 'Play a game', text link 'Keep looking'."
6. Feed reel: "Full-screen vertical video of friends laughing at a café, segmented pill Feed | Moments at top, right rail with avatar (green online dot), heart 1.2k, comment, gift, share, more; bottom-left 'Sam ✓gold · Follow' and caption."
7. Chat list: "Chats screen: search bar, a 'Heartbeats' row of round avatars with '🔥4' under names, then conversations with avatar, name, last message, time and pink unread badge."
8. Conversation: "Chat with Aria: header with avatar and gold seal, a soft card 'You both: Midnight pancakes · Coffee', violet bubbles for me, white bubbles for her, a plan card 'Phone-free café hour · Tomorrow 16:00', composer with +, field 'Message Aria…', sparkle AI button, send."
9. Plans home: "Plans screen: card '1 upcoming plan 💫' with 4 numbered steps Pick, Agree, Book, Go and a violet 'Create a plan' button; list rows with lilac circle icons: Group plans, Tables & tickets / Private circles / My tickets."
10. You profile: "Instagram-style profile: name with gold seal and menu icon, round avatar with gradient ring, Posts / Followers / Following, bio, a soft card 'Get your gold tick — 2 minutes', pills Edit profile and Share profile, tabs Top / Recent / Short, 3-column photo grid."
11. Settings: "Settings & account list on lilac background, grouped sections with small violet uppercase-free headers: Your profile, Dating, Subscription & payments, Privacy & safety, Notifications & app, Account; each row has a lilac circle icon, title, caption, chevron."
12. Plus: "Cariño Plus paywall: gradient header with a heart, comparison table Free vs Plus (Unlimited hearts, See who has a crush on you, 5 crushes a day, Advanced filters, Travel mode, Read receipts), plan cards $7.99/month and $59.99/year 'best value', violet pill 'Continue', small honest renewal text."

---

## 13. Handoff checklist (before importing back into the app)
- [ ] Every colour is a variable (Light + Dark modes), no raw hex in frames.
- [ ] Text ≥ 4.5:1 (body) / 3:1 (icons, large) — numbers in section 2.
- [ ] Every screen in section 9 drawn, plus states in 9G.
- [ ] Touch targets ≥ 44; nav and sheets clear the home indicator.
- [ ] Motion notes on prototype connections match section 7.
- [ ] Copy uses section 10 words.
Then share the Figma link: the app's tokens (`lib/theme/app_colors.dart`, `app_theme.dart`) get updated to match, screen by screen.
