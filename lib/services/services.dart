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
}
