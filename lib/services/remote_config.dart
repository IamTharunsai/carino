import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'backend_service.dart';

/// Server-driven UI configuration (REA pattern, rea-patterns.md §5.5 —
/// Tinder ships `/v2/dynamicui/configuration/content` so experiments and
/// copy ship WITHOUT an app release; for a solo builder this is the growth
/// lever that avoids App Store review cycles for wording).
///
/// What may live here: hook/onboarding copy, paywall headline + offer
/// framing, Daily Drop composition (size + drop time), match-expiry window,
/// and feature flags for staged rollouts.
///
/// HARD LIMITS (blueprint guardrails — config can never override these):
///  - Config can NEVER gate or hide safety surfaces (report, block,
///    appeals, Safety Centre) or change their copy to discourage use.
///  - Config can NEVER introduce fake scarcity/countdowns: any number it
///    carries (drop size, session seats) must be the real server number.
///  - Pricing shown to members always comes from the store via
///    PaymentsService — config carries framing copy only, never a price.
///
/// INTEGRATION POINT: `fetch()` GETs the signed config document from our
/// own backend (BackendService, e.g. `GET /v1/config?platform=…&build=…`),
/// caches it, and falls back to these compiled-in defaults offline.
/// Defaults below MUST always describe a fully honest, working app.
class RemoteConfigService extends ChangeNotifier {
  String welcomeHook = AppConfig.tagline;
  String paywallHeadline = 'Less swiping into the void. More actual plans.';
  String dailyDropEmptyCopy =
      'Today\'s Drop is done — the next one lands at the usual time.';

  // --- Daily Drop composition (S-016; counts are real or not shown) ---
  int dailyDropSize = 3;
  String dailyDropTimeLabel = '18:00';

  // --- Spark windows (S-025; real schedule, server-owned) ---
  String nextSparkWindowLabel = 'Tonight · 20:00–22:00';

  // --- City batching (S-009B): when true, newly verified members join the
  // waitlist instead of discovery. Default false.
  bool cityBatchFull = false;

  // --- Match expiry (REA §5.1; server enforces, client displays) ---
  /// Hours an unmessaged match stays live before it is archived.
  int matchExpiryHours = 48;

  // --- Feature flags (mirror AppConfig compiled defaults) ---
  bool sparkSessionsEnabled = AppConfig.sparkSessionsEnabled;
  bool funModeEnabled = AppConfig.funModeEnabled;

  /// Read receipts / seen states are a Plus entitlement (REA §5.10) —
  /// a low-offence paid perk that never gates safety.
  bool readReceiptsForPlus = true;

  bool _fetched = false;
  bool get fetched => _fetched;

  Future<void> fetch() async {
    // LIVE MODE: GET the config document via BackendService (Edge Function
    // `remote-config`) and apply ONLY the whitelisted keys below — the
    // hard limits in this file's doc comment are enforced by never reading
    // any other key. On any failure keep defaults and stay silent in UI.
    try {
      final doc = await BackendService().fetchRemoteConfig();
      if (doc != null) {
        welcomeHook = (doc['welcome_hook'] as String?) ?? welcomeHook;
        paywallHeadline =
            (doc['paywall_headline'] as String?) ?? paywallHeadline;
        dailyDropEmptyCopy =
            (doc['daily_drop_empty_copy'] as String?) ?? dailyDropEmptyCopy;
        dailyDropSize = (doc['daily_drop_size'] as int?) ?? dailyDropSize;
        dailyDropTimeLabel =
            (doc['daily_drop_time'] as String?) ?? dailyDropTimeLabel;
        nextSparkWindowLabel =
            (doc['next_spark_window'] as String?) ?? nextSparkWindowLabel;
        matchExpiryHours =
            (doc['match_expiry_hours'] as int?) ?? matchExpiryHours;
        cityBatchFull = (doc['city_batch_full'] as bool?) ?? cityBatchFull;
        final flags = doc['feature_flags'];
        if (flags is Map<String, dynamic>) {
          sparkSessionsEnabled =
              (flags['spark_sessions'] as bool?) ?? sparkSessionsEnabled;
          funModeEnabled = (flags['fun_mode'] as bool?) ?? funModeEnabled;
        }
      }
    } catch (e) {
      debugPrint('[RemoteConfig] fetch failed, defaults kept: $e');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _fetched = true;
    debugPrint('[RemoteConfig] active (fetched=$_fetched)');
    notifyListeners();
  }
}
