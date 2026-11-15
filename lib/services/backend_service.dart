import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import 'auth_service.dart';
import 'services.dart';

// AuthService lives in auth_service.dart; this file is the core data gateway.

/// Core backend gateway — profiles, discovery, matches, chat, plans.
///
/// LIVE MODE: Supabase (Postgres + Row Level Security + Realtime channels +
/// Storage), initialised in [initialize] from [Env]. Every table in
/// `backend/supabase/migrations/` carries RLS so a client can only ever
/// touch its own rows; the service-role key NEVER ships in the app.
///
/// MOCK MODE ([Env.useMockBackend], the default until hosting): no network
/// calls; screens read the local sample data exactly as the scaffold did.
///
/// Rules that stay server-side in both modes:
///  - Age/verification state (an unverified client can NEVER self-grant).
///  - All timers: Daily Drop window, Spark windows, Vanish expiry,
///    view-once — server-authoritative, never the device clock.
///  - The Safety Vault: sealed, report-only copies tied to OPEN reports so
///    abuse can be evidenced (Bible honest-promises). Never user-visible.
///  - AI-04 scam/lie SIGNAL flags -> human Trust queue (S-057). Signals
///    only — a model score never bans anyone by itself.
///  - MATCH EXPIRY job (REA §5.1): unmessaged matches archive when the
///    configured window elapses; enforced by the backend cron/Edge
///    Function `match-expiry`, never faked in the client.
///  - Remote config document: served by the `remote-config` Edge Function.
///  - CASE SYSTEM (REA §5.3): structured report tree, case creation,
///    warning acknowledge, appeals — the Trust & Safety Centre reads case
///    statuses from the `reports` / `appeals` tables.
class BackendService {
  bool get isLive => !Env.useMockBackend;
  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    if (Env.useMockBackend) {
      debugPrint(
          '[BackendService] MOCK mode — local stub data, no network. '
          'Pass --dart-define=SUPABASE_URL/ANON_KEY to go live.');
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // supabase_flutter >=2.9 name for the anon/public key.
      publishableKey: Env.supabaseAnonKey,
    );
    client.auth.onAuthStateChange.listen((state) {
      // Keep the RootFlow session gate in sync with real auth state.
      AuthService.sessionChanges.value = state.session != null;
    });
    debugPrint('[BackendService] Supabase initialised (${Env.supabaseUrl})');
  }

  String? get currentUserId =>
      isLive ? client.auth.currentUser?.id : 'demo-user';

  // --- Profiles / discovery ------------------------------------------------

  /// GET /feed equivalent: reciprocal-eligibility profiles. RLS + the
  /// `feed_profiles` view guarantee distance BANDS only — coordinates
  /// never leave the server.
  Future<List<Map<String, dynamic>>> fetchFeed() async {
    if (!isLive) return const [];
    final rows = await client
        .from('feed_profiles')
        .select()
        .limit(30);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> recordLike(String toUserId, {String anchorType = 'profile', String? anchorId}) async {
    if (!isLive) return;
    await client.from('likes').insert({
      'from_user': currentUserId,
      'to_user': toUserId,
      'anchor_type': anchorType,
      'anchor_id': anchorId,
    });
  }

  Future<void> recordPass(String toUserId) async {
    if (!isLive) return;
    await client.from('passes').insert({
      'from_user': currentUserId,
      'to_user': toUserId,
    });
  }

  // --- Cases (reports / appeals) --------------------------------------------

  /// POST /reports equivalent. Returns the server-issued case reference —
  /// the S-051 confirmation shows ONLY a real, server-issued ID in live
  /// mode (mock mode prefixes DEMO so it can never be mistaken for one).
  Future<String> submitReport({
    required String category,
    required String reason,
    String? details,
    String? reportedUserId,
    required String surface,
  }) async {
    if (!isLive) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return 'CN-DEMO';
    }
    final row = await client
        .from('reports')
        .insert({
          'reporter': currentUserId,
          'reported': reportedUserId,
          'category': category,
          'reason': reason,
          'details': details,
          'surface': surface,
        })
        .select('case_ref')
        .single();
    return row['case_ref'] as String;
  }

  Future<String> submitAppeal({required String subject, String? caseRef}) async {
    if (!isLive) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return 'CN-A-DEMO';
    }
    final row = await client
        .from('appeals')
        .insert({
          'user_id': currentUserId,
          'subject': subject,
          'case_ref': caseRef,
        })
        .select('appeal_ref')
        .single();
    return row['appeal_ref'] as String;
  }

  Future<void> applyBlock(String blockedUserId) async {
    Services.prefs.blocked.add(blockedUserId);
    await Services.prefs.save();
    if (!isLive) return;
    // Server propagates immediately: hides both ways + ends contact
    // surfaces (RLS + the blocks trigger in the migration).
    await client.from('blocks').insert({
      'blocker': currentUserId,
      'blocked': blockedUserId,
    });
  }

  /// "Download my data": the export-data Edge Function's JSON, or null in
  /// demo mode (no server account to export).
  Future<String?> exportMyData() async {
    if (!isLive) return null;
    final res = await client.functions.invoke('export-data');
    final d = res.data;
    return d is String ? d : const JsonEncoder.withIndent('  ').convert(d);
  }

  /// Vanish screenshot notice for both people (server-side system notice).
  Future<void> reportScreenshot(String conversationId) async {
    if (!isLive) return;
    try {
      await client.rpc('report_screenshot', params: {'p_conversation': conversationId});
    } catch (e) {
      debugPrint('[Backend] report_screenshot failed: $e');
    }
  }

  Future<void> removeBlock(String blockedUserId) async {
    Services.prefs.blocked.remove(blockedUserId);
    await Services.prefs.save();
    final me = currentUserId;
    if (!isLive || me == null) return;
    await client.from('blocks').delete().match({'blocker': me, 'blocked': blockedUserId});
  }

  // --- Remote config ---------------------------------------------------------

  /// The signed config document (Edge Function `remote-config`). Returns
  /// null offline/mock so RemoteConfigService keeps its honest defaults.
  Future<Map<String, dynamic>?> fetchRemoteConfig() async {
    if (!isLive) return null;
    try {
      final res = await client.functions.invoke('remote-config');
      final data = res.data;
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('[BackendService] remote-config fetch failed: $e');
      return null;
    }
  }
}
