import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/member.dart';
import '../models/notify.dart' show NotifTone;
import '../models/platform.dart';
import '../models/social.dart';
import '../models/sync.dart';
import 'ai_service.dart';
import 'analytics_service.dart';
import 'biometric_service.dart';
import 'auth_service.dart';
import 'backend_service.dart';
import 'payments_service.dart';
import 'remote_config.dart';
import 'sound_service.dart';
import 'verification_service.dart';
import 'video_service.dart';

/// Single shared instances of every service.
///
/// Services hold session-scoped state (auth, Plus entitlement, verification
/// layers, user prefs) — screens must NEVER construct their own copies
/// (a fresh `PaymentsService()` always reads "not Plus", a fresh
/// `VerificationService()` always reads "not started"). Everything goes
/// through [Services].
class Services {
  Services._();

  static final AuthService auth = AuthService();
  static final BackendService backend = BackendService();
  static final VerificationService verification = VerificationService();
  static final PaymentsService payments = PaymentsService();
  static final AIService ai = AIService();
  static final VideoService video = VideoService();
  static final SoundService sound = SoundService();
  static final RemoteConfigService remoteConfig = RemoteConfigService();
  static final UserPrefs prefs = UserPrefs();
  static final BiometricService biometric = BiometricService();
  static final AnalyticsService analytics = AnalyticsService();
  static final SocialGraph social = SocialGraph(MockData.initialCircles);
  static final TrustGraph trust = MockData.initialTrust();
}

/// Member-controlled preferences (blueprint S-009 setup, S-047 Privacy
/// Centre, S-050 Settings). In-memory for the scaffold; PRODUCTION persists
/// server-side (profile.notification_prefs / privacy fields) so they follow
/// the member across devices.
class UserPrefs {
  // --- Persistence (security-relevant + gates only) --------------------------
  // Survives restarts so app lock, hidden chats and the under-21 block can't
  // be undone by killing the app. Non-sensitive flags only — no secrets.
  SharedPreferences? _sp;

  Future<void> load() async {
    _sp = await SharedPreferences.getInstance();
    final sp = _sp!;
    _appLock = sp.getBool('appLock') ?? false;
    hiddenChats
      ..clear()
      ..addAll(sp.getStringList('hiddenChats') ?? const []);
    pinnedChats
      ..clear()
      ..addAll(sp.getStringList('pinnedChats') ?? const []);
    mockVerified = sp.getBool('mockVerified') ?? false;
    final blocked = sp.getString('ageBlockedUntil');
    ageBlockedUntil = blocked == null ? null : DateTime.tryParse(blocked);
    _sparkDay = sp.getString('sparkDay');
    _sparksUsed = sp.getInt('sparksUsed') ?? 0;
    _loadSync(sp.getString('sync'));
  }

  Future<void> save() async {
    final sp = _sp;
    if (sp == null) return; // not loaded (e.g. widget tests without setup)
    await sp.setBool('appLock', _appLock);
    await sp.setStringList('hiddenChats', hiddenChats.toList());
    await sp.setStringList('pinnedChats', pinnedChats.toList());
    await sp.setBool('mockVerified', mockVerified);
    if (ageBlockedUntil == null) {
      await sp.remove('ageBlockedUntil');
    } else {
      await sp.setString('ageBlockedUntil', ageBlockedUntil!.toIso8601String());
    }
    if (_sparkDay != null) await sp.setString('sparkDay', _sparkDay!);
    await sp.setInt('sparksUsed', _sparksUsed);
    await sp.setString('sync', jsonEncode(_syncJson()));
  }

  /// Demo-mode stand-in for the server's verification_records badge.
  bool mockVerified = false;
  Future<void> setMockVerified(bool v) async {
    mockVerified = v;
    await save();
  }

  /// Under-21 block: set when the age gate refuses; lifted on the 21st
  /// birthday. Persisted so "back → create account" can't retry.
  DateTime? ageBlockedUntil;

  // S-009 defaults are privacy-first, per the blueprint:
  String visibility = 'Discovery'; // Discovery | Connections only | Paused
  bool showActivity = false; // hidden until the member enables it
  bool genericPreviews = true; // generic notification previews ON
  bool allowCalls = true; // incoming calls from connections
  bool notifMatches = true;
  bool notifMessages = true;
  bool notifDrops = true;
  bool notifSpark = true;
  bool notifPlans = true;
  bool notifMoments = true;
  bool soundsEnabled = true;
  bool _appLock = false;
  bool get appLock => _appLock;
  set appLock(bool v) {
    _appLock = v;
    save();
  }
  bool excludeContacts = true;
  bool showDistanceBand = true;
  bool readReceipts = true;
  bool sensitiveMediaBlur = true;

  // Per-feature AI consent (S-047 / Bible §3.11) — off means fully off.
  bool aiConversationAssistant = true;
  bool aiProfileCoach = true;
  bool aiIcebreakers = true;

  // --- Identity (S-008A) — each field has its own visibility ---------------
  List<String> gender = const [];
  String pronouns = '';
  String orientation = '';
  List<String> wantToMeet = const []; // empty = open to everyone
  Map<String, String> identityVisibility = {
    'gender': 'everyone',
    'pronouns': 'everyone',
    'orientation': 'matches',
  };
  String accessNote = '';

  /// Taste Quiz answers (question id -> pick).
  Map<String, String> tasteAnswers = {};

  /// My answers, or the demo sample until the quiz is taken.
  Map<String, String> get tastesOrSample => tasteAnswers.isNotEmpty
      ? tasteAnswers
      : const {'t2': 'Midnight pancakes', 't3': 'Coffee and a walk', 't7': 'Farmers market'};

  /// Calm mode: fewer animations, no celebration motion, plain language.
  /// A notifier so MaterialApp re-reads it app-wide the moment it flips.
  final ValueNotifier<bool> calmMode = ValueNotifier<bool>(false);

  /// Date Check-in: one trusted contact (name + number) kept on-device in
  /// the demo; production stores it server-side, own-row RLS only.
  String trustedContactName = '';
  String trustedContactPhone = '';

  /// Profile Soundtrack — connected through the official music service.
  bool musicConnected = false;

  /// Wingperson invite (one active link at a time; revocable).
  bool wingpersonActive = false;

  /// Moments pinned to your profile as Highlights (max 3).
  final List<String> highlights = [];

  // --- Experience upgrade (Nov 14) ------------------------------------------
  /// App theme: Midnight (dark, brand default), Porcelain (light), System.
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  /// Relationship status + who may see it. In a relationship, Dates pauses
  /// itself (Honest Status): you can't be discoverable and "taken" at once.
  String relationshipStatus = 'Single'; // Single | Dating | In a relationship | Married | It's complicated
  String? _visibilityBeforePause;

  static bool pausesDating(String status) =>
      status == 'In a relationship' || status == 'Married';

  /// Honest Status: taken pauses Dates; going back to an available status
  /// restores whatever visibility the member had before.
  void setRelationshipStatus(String status) {
    final wasPaused = pausesDating(relationshipStatus);
    final nowPaused = pausesDating(status);
    if (nowPaused && !wasPaused) {
      _visibilityBeforePause = visibility;
      visibility = 'Paused';
    } else if (!nowPaused && wasPaused && _visibilityBeforePause != null) {
      visibility = _visibilityBeforePause!;
      _visibilityBeforePause = null;
    }
    relationshipStatus = status;
  }

  /// Unlinking wipes the shared space — a future partner never sees it.
  void unlinkPartner() {
    partnerName = null;
    coupleMemories.clear();
    coupleCalendar.clear();
  }
  String relationshipVisibility = 'hidden'; // everyone | matches | hidden

  /// Couples mode: linked partner (by mutual invite code).
  String? partnerName;
  final List<String> coupleMemories = [];
  final List<(String, String)> coupleCalendar = []; // (when, what)

  /// Chats: pinned, hidden (behind app lock), and per-chat theme index.
  final Set<String> pinnedChats = {};
  final Set<String> hiddenChats = {};
  final Map<String, int> chatThemes = {};

  /// Super Like ("Spark"): 1 a day free, Plus gets 5 — honest count.
  String? _sparkDay;
  int _sparksUsed = 0;

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  int sparksLeft(DateTime now, {required bool isPlus}) {
    final allowance = isPlus ? 5 : 1;
    if (_sparkDay != _dayKey(now)) return allowance;
    return math.max(0, allowance - _sparksUsed);
  }

  /// Spends one Spark; false when none are left today.
  bool useSpark(DateTime now, {required bool isPlus}) {
    if (sparksLeft(now, isPlus: isPlus) <= 0) return false;
    if (_sparkDay != _dayKey(now)) {
      _sparkDay = _dayKey(now);
      _sparksUsed = 0;
    }
    _sparksUsed++;
    save();
    return true;
  }

  /// AI Away Assistant — replies ONLY with a visible "assistant" label,
  /// only when you're away, never pretending to be you.
  bool awayAssistant = false;

  /// Referral: your code; promo redeemed state.
  final String referralCode = 'CARINO-YOU7';
  String? redeemedPromo;

  // --- My profile: what onboarding collects, used everywhere ----------------
  Intention intention = MockData.currentUser.intention;
  String structure = 'Monogamy';
  String pace = 'Chat first';
  String availability = 'This week';
  String bio = '';
  String boundaries = '';
  Map<String, String> promptAnswers = {};
  List<String> languages = const ['English'];

  /// Notifications: written in this language and tone (real events only).
  String notifLanguage = 'English';
  NotifTone notifTone = NotifTone.calm;

  /// People I blocked (ids). Hidden both ways: Dates, Chats, Privacy Centre
  /// lists them with Unblock. Live: also the `blocks` table.
  final Set<String> blocked = {};

  /// Chats I muted (conversation ids).
  final Set<String> mutedChats = {};

  /// People I liked (ids), newest first. A match needs them to like me too.
  final List<String> liked = [];

  /// Chemistry streak per person (member id -> days). Games and chat share it.
  final Map<String, int> streaks = {'m-sofia': 4};

  /// Empty until the member picks some (then the demo sample is replaced).
  List<String> interests = const [];

  /// "Me" as everyone else sees it — the demo base, overridden by every
  /// answer the member actually gave. Screens read THIS, not MockData.
  Member get me {
    const b = MockData.currentUser;
    return Member(
      id: b.id,
      name: b.name,
      age: b.age,
      city: b.city,
      distanceBand: b.distanceBand,
      intention: intention,
      photoAsset: b.photoAsset,
      headline: bio.isEmpty ? b.headline : bio,
      prompts: promptAnswers.isEmpty
          ? b.prompts
          : [for (final e in promptAnswers.entries) PromptAnswer(e.key, e.value)],
      interests: interests.isEmpty ? b.interests : interests,
      languages: languages,
      structure: structure,
      pace: pace,
      availability: availability,
      boundaries: boundaries,
      gender: gender.isEmpty ? b.gender : gender,
      pronouns: pronouns.isEmpty ? b.pronouns : pronouns,
      orientation: orientation,
      wantToMeet: wantToMeet,
      identityVisibility: identityVisibility,
      tasteAnswers: tastesOrSample,
      accessNote: accessNote,
      textingStyle: myStyle,
      comfort: myComfort,
    );
  }

  // --- Conversation Sync (Nov 14) -------------------------------------------
  /// My "How I text" card and comfort rules — shown to my matches; the app
  /// enforces the rules in chat (calls, photos) and in the plan composer.
  TextingStyle myStyle = const TextingStyle();
  ComfortRules myComfort = const ComfortRules();

  /// Private after-plan check-ins. Never shared; only reorder MY shelf.
  final List<Reflection> reflections = [];

  /// "Things to remember" — private notes about a match (memberId -> note).
  final Map<String, String> matchNotes = {};

  Map<String, Object?> _syncJson() => {
        'pace': myStyle.pace?.name,
        'length': myStyle.length?.name,
        'voice': myStyle.voice?.name,
        'humour': myStyle.humour?.name,
        'loves': myStyle.loves,
        'avoid': myStyle.avoid,
        'noCalls': myComfort.noCallsBeforeMeet,
        'photoDays': myComfort.photosAfterDays,
        'daytime': myComfort.daytimeFirstMeet,
        'opensFirst': myComfort.opensFirst,
        'notes': matchNotes,
        'liked': liked,
        'blocked': blocked.toList(),
        'muted': mutedChats.toList(),
        'notifLanguage': notifLanguage,
        'theme': themeMode.value.name,
        'notifTone': notifTone.name,
        'streaks': streaks,
        'profile': {
          'intention': intention.name,
          'structure': structure,
          'pace': pace,
          'availability': availability,
          'bio': bio,
          'boundaries': boundaries,
          'prompts': promptAnswers,
          'languages': languages,
          'interests': interests,
        },
        'reflections': [
          for (final r in reflections)
            {
              'c': r.category,
              'g': r.good,
              'l': [for (final t in r.liked) t.name],
              'd': [for (final t in r.disliked) t.name],
            }
        ],
      };

  void _loadSync(String? raw) {
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      List<String> strs(Object? o) => [for (final x in (o as List? ?? const [])) '$x'];
      myStyle = TextingStyle(
        pace: ReplyPace.values.asNameMap()[j['pace']],
        length: MsgLength.values.asNameMap()[j['length']],
        voice: VoiceNotes.values.asNameMap()[j['voice']],
        humour: Humour.values.asNameMap()[j['humour']],
        loves: strs(j['loves']),
        avoid: strs(j['avoid']),
      );
      myComfort = ComfortRules(
        noCallsBeforeMeet: j['noCalls'] == true,
        photosAfterDays: (j['photoDays'] as num?)?.toInt() ?? 0,
        daytimeFirstMeet: j['daytime'] == true,
        opensFirst: j['opensFirst'] == true,
      );
      final pr = j['profile'] as Map? ?? const {};
      intention = Intention.values.asNameMap()[pr['intention']] ?? intention;
      structure = pr['structure'] as String? ?? structure;
      pace = pr['pace'] as String? ?? pace;
      availability = pr['availability'] as String? ?? availability;
      bio = pr['bio'] as String? ?? bio;
      boundaries = pr['boundaries'] as String? ?? boundaries;
      promptAnswers = {
        for (final e in (pr['prompts'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'
      };
      if (pr['languages'] is List) languages = strs(pr['languages']);
      if (pr['interests'] is List) interests = strs(pr['interests']);
      notifLanguage = j['notifLanguage'] as String? ?? notifLanguage;
      themeMode.value = ThemeMode.values.asNameMap()[j['theme']] ?? themeMode.value;
      notifTone = NotifTone.values.asNameMap()[j['notifTone']] ?? notifTone;
      blocked
        ..clear()
        ..addAll(strs(j['blocked']));
      mutedChats
        ..clear()
        ..addAll(strs(j['muted']));
      if (j['liked'] is List) {
        liked
          ..clear()
          ..addAll(strs(j['liked']));
      }
      if (j['streaks'] is Map) {
        streaks
          ..clear()
          ..addAll({
            for (final e in (j['streaks'] as Map).entries) '${e.key}': (e.value as num).toInt()
          });
      }
      matchNotes
        ..clear()
        ..addAll({
          for (final e in (j['notes'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'
        });
      Set<ReflectTag> tags(Object? o) =>
          {
            for (final n in strs(o))
              if (ReflectTag.values.asNameMap()[n] case final t?) t
          };
      reflections
        ..clear()
        ..addAll([
          for (final r in (j['reflections'] as List? ?? const []))
            Reflection(
              category: (r as Map)['c'] as String?,
              good: r['g'] == true,
              liked: tags(r['l']),
              disliked: tags(r['d']),
            )
        ]);
    } catch (_) {
      // Corrupt local blob: keep defaults rather than crash on launch.
    }
  }

  /// Decompress bookings (demo store; production = partner bookings table).
  final List<String> bookings = [];

  /// Plans you created via Post → Plan or Host a plan (demo store).
  final List<String> myPlans = [];

  /// No-Counts mode: hide every public number (likes, views, followers).
  final ValueNotifier<bool> noCounts = ValueNotifier<bool>(false);

  /// Facets: one account, four selves. field -> facet -> audience
  /// ('everyone' | 'matches' | 'circles' | 'hidden').
  final Map<String, Map<String, String>> facetAudience = {
    'Photos': {
      'Public': 'everyone',
      'Circles': 'circles',
      'Dating': 'matches',
      'Professional': 'everyone'
    },
    'Pronouns': {
      'Public': 'everyone',
      'Circles': 'circles',
      'Dating': 'everyone',
      'Professional': 'everyone'
    },
    'Orientation': {
      'Public': 'hidden',
      'Circles': 'circles',
      'Dating': 'matches',
      'Professional': 'hidden'
    },
    'Job': {
      'Public': 'hidden',
      'Circles': 'circles',
      'Dating': 'matches',
      'Professional': 'everyone'
    },
    'City': {
      'Public': 'everyone',
      'Circles': 'circles',
      'Dating': 'everyone',
      'Professional': 'everyone'
    },
  };

  /// Professional wing: shown only in the Professional facet.
  String workRole = 'Product engineer';
  String workBuilding = 'A dating app that ends in real plans';
  Set<String> workOpenTo = {'coffee', 'collabs'};

  final Map<String, String> givenVouches = {};
  final Map<String, PlanSplit> planSplits = {};

  /// Guilds joined (ids) and whether each allows dating discovery.
  final Map<String, bool> guildDating = {};
}
