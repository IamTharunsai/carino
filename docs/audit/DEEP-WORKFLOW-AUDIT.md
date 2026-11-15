# Complete-source workflow census and deeper customer audit

Date: November 15, 2026. This extends the [first customer review](../CUSTOMER-WORKFLOW-REVIEW-2026-11-15.md).

**No: every workflow has not been verified end to end in every direction, and the app is not certified complete.** The first review grouped actions into feature families. This extension inventories individual callback sites, navigation calls, input controls and reusable surfaces, and adds specific reverse/cancel paths and smaller defects. Source coverage and runtime verification are reported separately.

## Coverage you can inspect

The machine-readable [coverage summary](coverage-summary.json) contains the latest counts. The source scanner visits every `.dart` file under `lib`, including shared widgets, root routing, services and models. It records the full callback expression rather than relying on a search for buttons.

The recorded census contains **92 Dart files, 571 callback bindings, 273 navigation/modal/external calls, 98 widget classes, 164 input/back-surface sites and 81 event/lifecycle sites**. Another **42 native/backend source/config files** are hash-inventoried. The direction ledger contains **7,994 checks marked NOT RUN**, not 7,994 passes. At artifact verification, the Dart census had zero parse errors and zero source-hash drift. This describes the recorded snapshot, not future edits.

| Deliverable | What it records | What it does not prove |
|---|---|---|
| [Control census](CONTROL-CENSUS.csv) | Each named event/validation binding, exact source line, owner, callback, labels and expression | Every branch or generated row was clicked successfully |
| [Navigation and return census](NAVIGATION-AND-RETURN-CENSUS.csv) | Push, replacement, pop, sheet/dialog, clipboard and selected external/helper calls | A valid outcome and correct return at every caller |
| [Input/back-surface inventory](source-inventory.json) | Text inputs, pickers, sliders, menus, AppBars, PopScopes, PageViews and sheets | Native keyboard, system gestures or device accessibility passed |
| [Surface census](SURFACE-CENSUS.csv) | Public and private widget classes, including reusable cards and sheets | Each surface is reachable in all real account states |
| [Event/lifecycle census](EVENT-AND-LIFECYCLE-CENSUS.csv) | Listener registration/removal, timers, async callbacks, native method calls and lifecycle methods | Correct scheduling, disposal or background behavior on hardware |
| [Native/backend boundary dependencies](BOUNDARY-DEPENDENCIES.csv) | Sixteen contracts spanning native permissions/links, server jobs, providers, export/delete and cross-device outcomes | Those integrations are deployed, connected or passed |
| [Native/backend snapshot](NATIVE-AND-BACKEND-SNAPSHOT.csv) | Hash inventory of selected native and server source/config files | A complete security audit, provider QA or native build certification |
| [Source snapshot](SOURCE-SNAPSHOT.csv) | Every file's line count, SHA-256, parse diagnostics and changes since scan | Later edits preserve these results |
| [All-directions ledger](ALL-DIRECTIONS-LEDGER.csv) | Fourteen required checks per callback site, with explicit NOT RUN status | Thousands of generated rows are thousands of executed tests |

The scan includes `onPressed`, `onTap`, `onLongPress`, `onDoubleTap`, drag start/update/end, choice/menu selection, text change/submission, chip deletion, onboarding callbacks, validator and pop callbacks. Four `onSurface/onPrimary` theme colour fields are deliberately excluded. Wrapper callbacks are retained so forwarding can be checked. Disabled controls are retained; deliberate safety locks are not automatically called bugs.

**Important counting rules:** callback sites are not unique visible buttons. A loop can render many member rows, prompt hearts or choices from one site. Those are templates whose data/permission variants also need testing. Inputs can have no explicit callback and still matter; they are separately recorded. Implicit platform Back and a decorative play/send icon can also matter without an `onPressed`; the input inventory and manual findings cover these cases. The scanner is a syntax census, not a formal proof of program reachability or a semantic call graph.

## Runtime evidence and source changes

The first review's existing suite passed 149 tests with 68 screenshot scenarios skipped. This deeper pass enabled the capture scenarios: **all 68 capture cases completed**, writing fresh PNGs under `build/screens`. The initial combined command exited unsuccessfully because the new probe harness initially failed compilation; the capture cases themselves completed. Do not represent that combined command as a clean full-suite pass. See [capture log](screenshot-run.log). Four representative fresh renders were visually inspected: sign-in, Keep conversation, plan detail and attachment menu. Rendering 68 captures is not the same as manually inspecting all 68 or testing every action in them.

A corrected, separate **12-probe baseline run passed**: eleven checks deliberately reproduced defects and one compared preview publishing. See [baseline log](baseline-12-probes.log). These are characterisation tests, not assertions that the intended product works. Later additions test visible Back, system Back to dismiss a sheet, discarded filter edits, cancelling like options without spending, and failed-unlock protection. The latest run is recorded in [runtime status](runtime-status.json), including failures and their meaning. Native integrations log missing-plugin behavior in a widget-test host; that is not device verification.

The subsequent **17-probe run passed**, and the full local suite plus those probes completed with **166 passed and 129 skipped**. No `lib` or `test` Dart source hashes changed during that combined run. The skipped set includes 68 capture scenarios and 61 opt-in button-sweep scenarios. See [combined validation log](latest-local-validation.log) and [source-stability evidence](local-validation-source-status.json). This is evidence for the recorded source version and test assertions, including assertions deliberately reproducing defects, not a clean product acceptance result.

The available `test/audit/button_audit_test.dart` was also invoked separately with `AUDIT=1`. Its results are recorded in runtime status and its log. Its own “EVERY tappable thing” comment is too broad: it enumerates initial hit-testable InkResponse/GestureDetector targets on a tall synthetic canvas, remounts each screen, and observes one tap. It does not recursively fill forms or inspect controls revealed by that tap, long-press/drag paths, root onboarding transitions, two accounts or a complete return journey. It also suppresses some mount errors and treats a toast as an observable outcome. Its DEAD labels need manual review: selecting an already-selected option, an optional Skip, or toggling a value not included in the fingerprint can be false positives. Do not promote these observations into workflow passes.

That sweep completed **61 fixture tests and 620 tap observations**: 309 page changes, 118 sheet opens, 98 screen opens, 31 messages/toasts, 16 returns, 15 callback “next step” outcomes and 33 no-change flags. See [raw observations](BUTTON-SWEEP-OBSERVATIONS.csv) and [flag triage](BUTTON-SWEEP-FLAG-TRIAGE.csv). Of the flags, 27 are same-state selections/default resets, three are wheel-text taps rather than scroll gestures, two require native authentication simulation, and one is sign-out in an isolated Settings fixture without RootFlow. These are interpretations requiring context, not 33 accepted app bugs. Many confirmed incomplete outcomes still produce a screen/sheet/toast and therefore escape this sweep's no-change detection.

**The working tree is being changed concurrently.** During the review, application files acquired edits to blocks, mute persistence, export, screenshot notices, availability copy, profile-creation presentation and other areas. One intermediate probe run could not compile an incomplete Privacy Centre edit; the subsequent source compiled for another run. The earlier 39 findings therefore describe a baseline, not an immutable statement about the latest code. Preserve the evidence, reconcile each fix and rerun the intended outcome before closing it. I did not make these application edits.

## Smaller and cross-direction gaps found in this pass

Each item identifies the customer action, observed source consequence, required repair and acceptance rule. `Source` means confirmed in the inspected source; `Reproduced baseline` means exercised by the saved probe run; `Verify` means a risk still needs its specific device/scenario run. Existing F-numbers refer to the first report; these D-items often refine those findings rather than representing unrelated new defects.

### D01 — P1 — Hide this profile does not hide it

**Action:** open a profile → Hide this profile → return to discovery → revisit.

**Source / reproduced baseline:** `profile_detail_screen.dart`, Hide handler, only pops and displays “hidden”. It records neither pass nor hidden-member state. A Dates caller receives `null`, so it does not remove the card. The customer has asked not to see this person again and can immediately see them again.

**Build/done:** shared persisted hide/pass operation by member ID; every deck/list respects it; Back, restart, Daily Drop, Worldwide and other entry points agree. Define how hide differs from block and how to reverse it.

### D02 — P1 — the full-profile prompt heart sends no like at all

**Action:** Dates → full profile → small heart on a prompt → return.

**Source / reproduced baseline:** `profile_detail_screen.dart:235` announces a prompt-anchored like, then calls `pop()` without a result. The Dates caller needs a non-null boolean to commit. This is worse than losing the prompt anchor: this particular route creates no like.

**Build/done:** record a typed anchored like through the shared service; do not claim success before acknowledgement. Verify recipient, outbound list, match creation, back destination and error recovery from every caller. Refines F14/F15.

### D03 — P1 — Invite to Spark can change the person

**Action:** open someone other than Aria → Invite to Spark.

**Source:** the profile opens `const SparkPreCallScreen()` without a member/invitation. Its `_inviter` always resolves `m-aria`. Generic lobby and Spark Nights use the same screen. The intended person/event is lost.

**Build/done:** pass a real invitation/person/event ID; display and call only that resource; keep it through Full profile → Back, permissions and acceptance. Cancellation must return to the originating person/event.

### D04 — P1 — expired invitation and pool-off states do not disable acceptance

**Action:** turn Spark pool off, or let invite countdown expire → Accept.

**Source:** countdown computes an “Expired” label and pool toggle changes `_inPool`, but Accept still unconditionally replaces the route with the call screen. `_showDenied` also does not guard this action.

**Build/done:** server-authoritative invite eligibility with expired/withdrawn/declined/busy states. Acceptance must fail safely when no longer valid, explain the result and restore an appropriate destination. Refines F26.

### D05 — P2 — Voice intro and Skip for now have empty handlers

**Action:** tap profile Voice intro, or profile creation Video → Skip for now.

**Baseline source:** profile voice playback had `onTap: () {}`; the video skip button had `onPressed: () {}`. Later edits replaced playback with a truthful sample-media preview sheet, and Skip now shows a skipped state with Add now to reverse it. Those inert-control symptoms are addressed in source. Actual playback/capture/persistence are still not implemented; the full media contract remains open.

**Build/done:** actual playback, or clearly unavailable control; Skip should visibly mark video optional/skipped and move focus to the next task. Give captions, recording, stop, retake and cancel a coherent outcome. Refines F06/F20.

### D06 — P1 — video reply returns “sent” without media or a like

**Action:** prompt → Reply with video → record at least five seconds → Send privately.

**Source:** `video_reply_sheet.dart` only counts seconds; Send returns `true`. The profile shows a sent snackbar without creating a media/like object. No captions text is captured despite the automatic/editable captions promise.

**Build/done:** real capture/preview/captions/upload/moderation/receipt; cancellation clears or retains a disclosed draft; receiver sees the right private clip and prompt, once. Never turn a timer into a delivery receipt.

### D07 — P2 — Plus filter rows do not change filter behavior

**Action:** upgrade → Filters → Exact-intention matching or Worldwide distance → Apply.

**Source:** `_plusGate` says “enabled” for Plus but mutates no filter config. The filter object has no corresponding advanced flags. Worldwide is also directly accessible from Dates. The wording, entitlement and actual result disagree.

**Build/done:** define which features are free/paid; implement concrete filter values and result changes, loading/error/empty behavior and return-from-paywall refresh. Do not count a toast as enabling a filter.

### D08 — P2 — Question Cards' return target and paid deck are incomplete

**Action:** open games from Plans/profile/match celebration → Question Cards → Answer in chat.

**Source:** Answer in chat only pops. It returns to whichever caller opened Games, which may not be a chat, and transfers no question/draft. The Late-Night deck always opens Paywall, including when already Plus. Build Our Date opens a generic composer without producing the described winning combination.

**Build/done:** open the correct existing/authorised conversation with an editable question context; preserve origin on cancellation. Entitled members must open actual paid content. Refines F37.

### D09 — P1 — feedback text is discarded and feedback is not tied to its plan

**Action:** past plan → type private debrief note → Save → reopen.

**Source / reproduced baseline:** `_comment` is displayed and disposed but never read by `_save`. Reflection stores category/good/tags, not note, member/plan ID or submission time. Saving is not guarded while awaiting AI; repeat taps can add multiple reflections. A sample plan's `feedbackPending` is not changed by that save.

**Build/done:** save the explicitly promised data against a real plan; edit/reopen or explain retention; prevent duplicate submission; do not make AI availability a prerequisite to saving the customer's note. Refines F24/F36.

### D10 — P1 — group plan votes impersonate other members and leave no plan

**Action:** group → Make it a plan → start vote → vote → majority.

**Source:** `_vote` schedules fake votes for member IDs. `_checkWinner` clears the poll and appends “Plan set” text; it creates no plan record. Starting a new poll can overwrite the existing one without resolving it. Invalid empty vote form returns silently.

**Build/done:** one real independent vote per member; clear tie/change/cancel/expiry rules; authorised host/poll replacement; saved confirmed plan visible in group and Plans. Use a clearly labelled practice preview until realtime is connected.

### D11 — P1 — group membership has no complete lifecycle

**Action:** create/join group → want to leave, remove a member, report/block an individual or recover group history.

**Source:** inspected group extras contain catch-up, Vanish and voice preview, but no group details/member-management/leave flow. New groups are inserted into a local screen list. Friend requests only announce sending; no pending/inbound/accept/decline/cancel lifecycle is implemented in these screens. Removing a friend does not itself specify what happens to shared groups or old content.

**Build/done:** define roles, consent to membership, invite acceptance, leave/remove/report/block behavior, group visibility and durable history. Include zero-friends and no-eligible-invitee empty states. Do not silently equate membership with consent to dating.

### D12 — P2 — deleting one feed preference chip resets all preferences

**Action:** Stage → ask for several preferences → remove one displayed chip.

**Source:** every InputChip `onDeleted` clears `_ask` and resets all `FeedControls`, regardless of which chip was selected.

**Build/done:** remove the indicated preference only, or label the control “Reset all” rather than implying individual deletion. Preserve the remaining filters and show the resulting feed/empty state.

### D13 — P2 — Moments lose state when moving backwards

**Action:** answer/react on Moment A → next B → previous A.

**Source:** `_next/_prev` reset `_reacted/_answered`, which are viewer-global values rather than per-Moment records. `_askMe` is not cleared in those navigation methods, so an unsent Ask Me answer can remain while the recipient changes. This creates both lost feedback and wrong-recipient draft risks.

**Build/done:** store reaction/answer per content ID; scope unsent draft to its recipient; decide whether moving away saves/discards it. Verify next, previous, last-item close, reopening and expiry while the viewer is open.

### D14 — P2 — own Moments and highlights have incomplete lifecycle

**Action:** create two Moments, pin one, delete/unpin it, restart and inspect public profile.

**Source:** creation assigns one `_ownMoment` slot, replacing the previous current item. Highlights store captions rather than stable content IDs/media; own `prefs.me` does not include those highlights in its Member construction. No created-at/expiry timestamp drives the displayed “24h” value. The documented own-viewer list is not rendered in the inspected viewer.

**Build/done:** define single versus multiple active Moments, actual expiry, audience-aware highlight retention, viewer-list privacy, duplicate captions and delete propagation. Pin/unpin must change the real profile, not just a local list. Refines F33/F36.

### D15 — P1 — hidden chats can become hard to recover on an unsupported device

**Action:** long-press chat → Hide → open Hidden chats on a device without working authentication.

**Source:** Hide persists the ID without proving the member can unlock it. `_openHidden` refuses when biometric/device authentication fails and only shows setup guidance. There is no alternate unhide/recovery action in that branch. The general app-lock enable flow is more careful and verifies unlock first.

**Build/done:** validate unlock capability before hiding, explain requirements, and define a safe recovery path when credentials/plugin support changes. Verify system Back while locked; pointer/semantics blocking alone does not prove Back cannot mutate the underlying route. This is a source recovery gap; actual credential changes require hardware testing.

### D16 — P2 — Open Settings does nothing and error Support is unused

**Action:** permission-denied card → Open Settings; generic error state → seek support.

**Source / reproduced baseline:** `PermissionDeniedState` defaults to an empty handler. `AppErrorState.onSupport` is accepted but never rendered/used; only Retry appears. Permission instructions are Android-shaped even though iOS is supported.

**Build/done:** actual platform Settings handoff, failure feedback, recheck on return and a rendered Support action. On unsupported platforms provide honest instructions without an enabled dead button.

### D17 — P2 — copy/share actions can announce success after failure

**Action:** copy friend/wingperson/hangout/referral link or Presence summary when clipboard access fails.

**Source:** several handlers catch clipboard exceptions and still show “Copied”; some also mark an invitation active or a friend invited. The member can then propose a hangout based only on that local flag, without an actual invitation recipient.

**Build/done:** distinguish link creation, clipboard copy, external sharing and recipient acceptance. Report copy failure with a selectable fallback; do not advance acceptance-dependent steps because a link was copied. External launches need cancel/unsupported/offline return handling too.

### D18 — P1 — Back/cancel does not preserve all onboarding drafts

**Action:** type answers → Back → forward; cancel verification → Back again; quit and sign in later.

**Source:** RootFlow stores stage history but recreates local screen state; draft identity, quiz progress, media slots and unfinished auth input are not a complete saved draft. Cancel verification calls `_go(intro)`, adding history rather than explicitly replacing/removing the cancelled provider step. These are different from an intentional destructive “Discard”.

**Build/done:** a documented stage/draft model; Back returns one meaningful step with retained work; cancellation does not resurrect cancelled work on the next Back; submitted operations reconcile instead of replaying. Verify both visible Back and native system Back. Refines F10/F36.

### D19 — P2 — edit-return paths do not consistently refresh their caller

**Action:** You → edit profile/identity/tastes → save → return to You or another retained tab.

**Source:** several handlers push then pop without awaiting the route or calling `setState`; mutable prefs are not a shared notifier for those fields. Intentions explicitly refreshes its caller, showing inconsistent patterns. Conversation settings can similarly change state without requesting its underlying conversation rebuild.

**Build/done:** appropriate shared observable state or explicit route results. Verify immediate updated text, deck eligibility and privacy on the first returned frame; tab-switching must not be required to make a save appear.

### D20 — P1 — chat actions can lose context or override customer work

**Action:** type an unsent message → tap AI draft/starter; open pinned plan; unsend an old message; use Translate.

**Source:** draft/starter selection directly replaces `_composer.text` without preserving existing text. Pinned plan opens hard-coded Coffee/Saturday rather than a plan ID. Unsend describes a window but checks only ownership. Translation defaults to English without a target-language selector, and its direct-chat consent path needs review. “Add yours” in Their style merely closes the sheet instead of opening the editor. Direct chat has no keyboard `onSubmitted` send equivalent.

**Build/done:** preserve/confirm replacement of drafts, route using real IDs, enforce actual unsend limits, clear translation/consent/original rules and honest shortcuts. Specify keyboard Enter versus newline behavior, with an accessible Send alternative.

### D21 — P1 — safety evidence guidance can discourage preserving missing evidence

**Action:** open Trust & Safety → money/scam guide → follow its evidence guidance.

**Source:** the guide says not to screenshot because the sealed vault already has the evidence. The inspected UI/report payload does not establish that promised capture exists for every source. A sample screenshot notification is not evidence of a functioning retention system.

**Build/done:** make evidence guidance accurate to the actual system and explicitly link retained evidence to the case/content IDs. Do not assert a safety backup exists until the collection/retention/access workflow is implemented and verified. Refines F18/F27.

### D22 — P1 — partial block fixes still leave cross-surface holes

**Latest-source reconciliation:** a persisted `blocked` set, local backend updates, Nearby exclusion, Chat List exclusion and shared Privacy Centre unblock were added during review. This supersedes the original statement that demo blocking has no state at all.

**Remaining source issue:** Daily Drop returns before the Nearby block check. Worldwide, inbound likes, sample matches, Moments, groups and already-open screens need the same authoritative policy. `applyBlock/removeBlock` mutate local state before a live write; failure lacks rollback/reconciliation in those methods. Hiding a row is not sufficient to revoke an already-open conversation or active call.

**Build/done:** one authoritative relationship policy, immediate local safe state, explicit pending/failure reconciliation and verification from both accounts across every surface. Keep F03 open until that broader contract passes.

### D23 — P2 — feedback, access needs and discovery filtering can over-assume intent

**Action:** add an access note unrelated to mobility → Events; skip tastes/identity; change availability.

**Source:** Events enables step-free filtering whenever `accessNote` is nonempty, regardless of its content. Tastes can fall back to sample answers, and empty “want to meet” falls back through sample identity. Generic plan-time chips can have no allowed time when Tonight meets a daytime-first rule.

**Build/done:** explicit optional preferences and neutral unanswered values; never infer a mobility restriction or taste from unrelated text/sample data. Explain no-valid-time states and offer another day/custom time without overriding comfort rules.

### D24 — P2 — form edge cases need explicit small-step behavior

**Source:** prompt deselection/reselection creates a fresh controller and loses the prior answer; empty language selection is allowed; six-photo Move later is enabled even on the last slot; some empty submit handlers silently return; partner/event/couple times are strings without dates; cost-split records are explicitly session-only and have no real payment claim.

**Build/done:** define whether each field is optional, keep deselected drafts or warn, disable unavailable reordering, show validation near its field and maintain focus. Preserve exact decimal/currency and paid-mark reset behavior for the transparent local cost calculator. Do not classify the calculator as money transfer merely because its button says paid.

### D25 — P1 — startup failures do not have a customer recovery surface

**Action:** launch when backend initialisation or local preference loading throws.

**Source:** `main()` awaits services before `runApp` without a top-level recoverable loading/error branch. Remote config has a fallback, but that is not a complete startup strategy.

**Build/done:** bounded startup loading, recoverable error/retry, support/build identification and safe offline behavior. Never display the normal home or demo people simply to hide a failed eligibility check.

### D26 — P2 — visual accessibility needs measurements and hardware evidence

**Fresh render observations:** enabled secondary actions use crimson text against dark surfaces, and the chat's large context/plan/booking panels compete with conversation space. The captured chat render shows the context card partially scrolled under the pinned sections; this alone does not prove an unreachable control. Some emoji render as missing-glyph boxes in the widget-test host, which needs real-device comparison before calling it an app font defect.

**Verify/done:** measure actual composited contrast, inspect long labels/large text/light theme/small screens, test keyboard and modal height, reachable focus and screen-reader actions for custom GestureDetector cards. The full capture set is one phone size/dark theme, not all devices. Avoid a universal accessibility score based on those captures.

## Forward/back/cancel matrix for the customer journeys

These are explicit completion contracts. The per-site ledger expands these checks to the callback inventory; the table below adds workflow-specific consequences. Source inspection is not a mark of runtime passing.

| Journey | Forward success | Back/cancel/reverse | Failure/reopen/other direction |
|---|---|---|---|
| Create account | Eligible authenticated member reaches correct required next stage | Back retains valid draft; cancel returns to clear signed-out/unfinished state | Kill/restart resumes; no gate bypass after sign-in |
| OTP | Correct code establishes one session for selected contact | Change contact invalidates old request; Back does not silently send | Expiry/resend/throttle/offline independently recoverable |
| OAuth/passkey | Actual credential creates/restores correct account | Browser/OS cancel returns usable sign-in | Cold callback, duplicate callback and lost credential handled |
| Verification | Real decision moves one account forward | Cancel exits vendor safely and preserves resumable state | Pending refreshes; failed/restricted/appeal paths accessible |
| Waitlist | Real admission resumes onboarding | Leave/reopen keeps place and preferences | Returning sign-in cannot bypass admission |
| Profile | Same saved result from every Publish path | Preview Back keeps draft; editor Back applies explicit discard policy | Upload rejection, offline save and process death preserve valid work |
| Identity/privacy | Correct audience/policy enforced from other account | Cancelled edits do not accidentally apply | Restart/account switch and every renderer honour policy |
| Discovery | Correct eligible candidate, one action per intended person | Open profile then Back changes nothing | Empty/filter/offline/blocked/deleted states distinguished |
| Likes | Accepted note/anchor/kind goes to exact recipient | Cancel no spend; withdraw follows documented policy | Lost response/retry/double tap reconciles once |
| Pass | Candidate removed according to policy | Undo restores the exact old candidate, not latest global value | Restart and alternate decks honour decision |
| Match | One mutual relationship and chat | Close celebration preserves match; reopening gives useful actions | Simultaneous likes, deleted/blocked person and unmatch handled |
| Chat list | Opens exact thread with correct badges | Back reflects read state; pin/unpin and hide/unhide are inverse | Hidden authentication failure has recovery; archive is findable |
| Conversation | Draft becomes acknowledged delivered message | Leave preserves draft; draft suggestions do not destroy it silently | Offline/retry/order/restart, unsend and recipient deletion reconcile |
| Direct Vanish | Consent applies only to eligible new messages | Reject/cancel leaves mode unchanged; switching back preserves old expiry | Server deadlines, cache/search and both devices agree |
| Media | Selected/captured media previews then delivers | Cancel upload/recording never sends; close first-view follows policy | First-view load failure, consumed retry, report and revoke handled |
| Games | Real invitation and independent answers | Back preserves round or explicitly declines; Answer in chat opens chat | Unanswered/expired/declined games and paid access work |
| Group | Real accepted members and durable messages | Leave/remove/block/report rights exist | Membership changes, multiple devices and no-friend states handled |
| Group plan vote | Real majority creates one identified plan | Change vote/cancel/replace poll are explicit | Tie/expiry/duplicate votes and removed voters defined |
| Plan proposal | Exact note/date/place delivered and listed | Back retains draft; decline changes stored state | No-person/no-valid-time/offline/stale version handled |
| Confirmed plan | Both accept same version | Reschedule requires reacceptance; cancel clears all dependent jobs | Lists/chat/calendar/check-ins resolve same current version |
| Safety check-in | Server-acknowledged schedule and actual authorised contact delivery | Ending/cancelling acknowledged before showing safe completion | Force-stop, timezone, failed delivery and duplicate escalation handled |
| Events/hosting | Real capacity reservation and invites | RSVP withdrawal and host cancellation release correct capacity | Sold-out race, provider change/refund and no events handled |
| Decompress | Real reservation or accurately labelled preview | Sheet cancel no booking; confirmation Later retains itinerary | Capacity/payment/provider failure and restart handled |
| Phone-Down | Actual session started and measurement policy explained | Back asks end; Keep going keeps session; Done returns to caller | Lock vs app switch, process death and unsupported platform accurate |
| Moments/Stage | Correct media and audience published | Edit/delete/undo/previous-next preserve correct content context | Expiry, moderation, rejected media and offline/restart handled |
| Report/appeal | Real case receipt with selected evidence and details | Cancel no case; Back retains allowed draft | Timeout/retry/duplicate submission and case tracking handled |
| Block | Contact is stopped across every surface | Cancel no effect; unblock uses same relationship | Server failure/account switch/current call/old links handled |
| Subscription | Selected store product yields verified entitlement | Cancel returns to caller without false active state | Pending/refund/restore/expiry and second device handled |
| Export/delete | Real retrievable export; reconciled deletion and local cleanup | Cancel delete keeps data; cancel export does not imply deletion | Duplicate/timeout/status and subscriptions clearly addressed |
| Couples/invites | Intended recipient accepts scoped relationship | Revoke/unlink prevents future shared access | Expired/reused/wrong-account links and prior partner data isolated |
| Settings/activity | Each control saves the policy it describes | Toggle reverse/clear works; Back reflects current saved value | Restart/OS overrides/account switch and failed save explained |
| Notifications | Opens exact safe event destination | Back returns to inbox/caller without nested duplicate tabs | Closed app/signed out/stale target/quiet hours and read counts handled |

## Reconcile fixes made while this audit was running

These observations are not approvals of those implementations. Verify the entire original contract before closing its F-number.

| Original finding | Change observed during review | Still required |
|---|---|---|
| F03 block state | Shared persisted set, Nearby/Chat List filtering, real local unblock added | Cross-surface policy, live failure reconciliation, existing/open routes, account isolation |
| F20 capture notices | iOS/native bridge, secure-screen listener and migration edits appeared | Hardware detection/recipient notification/permissions and truthful platform copy |
| F28 privacy/availability copy | Contacts copy now says matching has not launched; away-assistant copy states its dependency on live messaging | Actual enforcement and consent checks at every action/service, request suppression, persistence and server policy |
| F29 subscription wording | Undo-pass premium row removed; other paywall edits appeared | Actual selected-package purchase, false-return handling, restore and management |
| F30 export | Privacy Centre now invokes an export endpoint and copies JSON; demo says no server data | Authorisation/data completeness, failure handling, secure usable file, delete-screen export consistency |
| F36 mute | Per-conversation muted IDs now persist | Real notification suppression, account isolation and return refresh |
| D05 empty handlers | Profile intro now opens an explanatory sample-media sheet; Skip shows a skipped state with Add now | Real capture/playback/persistence and the remaining media acceptance cases |
| Minor validation/feedback | Empty Send buttons are disabled; empty vouch gets feedback; activity clear shows confirmation | Verify actual non-empty send/recipient outcomes, state scope and persistence |

The first report's direct Publish issue was reproduced in the saved baseline and 17-probe run. The inspected later profile-creation edit changes Skip presentation, not the direct publish handler; F05 remains open on that evidence. Do not infer that a changed file or a new method alone closes a workflow. The new delete-screen export action can still mark Export done when demo export returns null; distinguish no export available from a completed export.

## What prevents a 100% end-to-end claim

1. **Several real outcomes have no integration yet.** Verification, media/calls, delivery, payment, reservations, support and safety cannot be fully verified by clicking a local preview.
2. **Real multi-person evidence is absent.** Matching, consent, messaging, plans, blocks and invites require independent accounts and assertions on both sides.
3. **Native behavior is not widget-test behavior.** System Back/edge swipe, OS permissions/settings, biometric lockout, app switching, capture events, push/deep links and store UI need supported iOS/Android hardware.
4. **All-direction checks remain open.** The generated ledger deliberately says NOT RUN. N/A needs a documented reason; source inspection is not silently promoted to pass.
5. **The source changed during execution.** Baseline results must not be advertised as passing the current working tree. The snapshot lets a future run identify exactly what needs rechecking.

To close the audit, use a pinned build and configured staging services, two independent test accounts/devices, and record each applicable ledger row as PASS/FAIL with evidence (or N/A with reason). Include role/state/data boundaries, interruptions and reverse paths. Fix failures, then rerun the affected contracts. A million-percent assurance is not a meaningful test result; an explicit inventory with no unexplained coverage gaps is.

## Reproduce the inventory and probes

These commands use the locally installed tools and existing dependency caches. The analyzer dependency belongs to Flutter tooling; the app's pubspec was not changed.

```powershell
& C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe `
  --packages=C:\src\flutter\packages\flutter_tools\.dart_tool\package_config.json `
  docs\audit\inventory.dart
python docs\audit\build_coverage.py
```

```powershell
& C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe `
  C:\src\flutter\bin\cache\flutter_tools.snapshot test --no-pub --reporter expanded `
  docs\audit\workflow_probes_test.dart
```

The probe file is deliberately outside the normal `test/` tree. Defect-characterisation assertions can stop passing when a defect is fixed; reconcile them rather than modifying the application to preserve a defect. Convert accepted fixes into regression tests of the intended behavior in the project's test suite.
