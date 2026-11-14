import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/platform.dart';
import '../models/social.dart';
import 'ai_service.dart';
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
  static final SocialGraph social = SocialGraph(MockData.initialCircles);
  static final TrustGraph trust = MockData.initialTrust();
}

/// Member-controlled preferences (blueprint S-009 setup, S-047 Privacy
/// Centre, S-050 Settings). In-memory for the scaffold; PRODUCTION persists
/// server-side (profile.notification_prefs / privacy fields) so they follow
/// the member across devices.
class UserPrefs {
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
  bool appLock = false;
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

  /// Plans you created via Post → Plan or Host a plan (demo store).
  final List<String> myPlans = [];

  /// No-Counts mode: hide every public number (likes, views, followers).
  final ValueNotifier<bool> noCounts = ValueNotifier<bool>(false);

  /// Facets: one account, four selves. field -> facet -> audience
  /// ('everyone' | 'matches' | 'circles' | 'hidden').
  final Map<String, Map<String, String>> facetAudience = {
    'Photos': {'Public': 'everyone', 'Circles': 'circles', 'Dating': 'matches', 'Professional': 'everyone'},
    'Pronouns': {'Public': 'everyone', 'Circles': 'circles', 'Dating': 'everyone', 'Professional': 'everyone'},
    'Orientation': {'Public': 'hidden', 'Circles': 'circles', 'Dating': 'matches', 'Professional': 'hidden'},
    'Job': {'Public': 'hidden', 'Circles': 'circles', 'Dating': 'matches', 'Professional': 'everyone'},
    'City': {'Public': 'everyone', 'Circles': 'circles', 'Dating': 'everyone', 'Professional': 'everyone'},
  };

  /// Professional wing: shown only in the Professional facet.
  String workRole = 'Product engineer';
  String workBuilding = 'A dating app that ends in real plans';
  Set<String> workOpenTo = {'coffee', 'collabs'};

  /// Guilds joined (ids) and whether each allows dating discovery.
  final Map<String, bool> guildDating = {};
}
