import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/platform.dart';
import '../models/social.dart';
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
