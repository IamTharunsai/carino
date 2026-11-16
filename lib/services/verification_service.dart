import 'package:flutter/foundation.dart';
import '../config/env.dart';
import 'backend_service.dart';
import 'services.dart';

enum VerificationStatus { notStarted, pending, passed, failed }

/// The three verification LAYERS, in mandatory order (REA pattern,
/// rea-patterns.md §5.4 — Tinder's shipped stack layers the same way:
/// identity-verification challenge → biometrics/liveness → facemap
/// photo-match). A later layer never runs before the earlier one passes,
/// and the Verified badge is issued ONLY after Layer 3 (photo-match).
enum VerificationLayer {
  /// Layer 1 — government ID document check (blueprint S-005).
  document('Government ID', 'Confirms identity and that you are 21+.'),

  /// Layer 2 — liveness (blueprint S-006): a live selfie proves a real
  /// person is present — not a photo of a photo.
  liveness('Live selfie', 'A quick selfie clip — it’s really you, right now.'),

  /// Layer 3 — photo-match (blueprint S-006): the live selfie is matched
  /// against the ID photo AND the first profile photo, so the person in
  /// the profile is the person who shows up.
  photoMatch('Matches your ID', 'Your selfie and your ID photo are the same person.');

  const VerificationLayer(this.label, this.tagline);
  final String label;
  final String tagline;
}

/// Identity verification (blueprint S-004 → S-007).
///
/// PRODUCTION: a Persona/Veriff-class vendor SDK runs each layer inside
/// ITS OWN UI via a platform channel, in the order above. We store ONLY
/// per-layer results + vendor reference IDs — never the raw ID images or
/// selfie media (S-004 consent copy says exactly this, and it must stay
/// true).
///
/// INTEGRATION POINT: the server issues a session token; the client walks
/// the vendor flow layer by layer; results return by webhook. The PASS /
/// FAIL decision is the vendor + server's — failure at ANY layer lands on
/// S-007 (fail with reason + retry / alternative ID / human appeal). The
/// client only renders state; it can never self-grant a pass.
class VerificationService {
  VerificationStatus _status = VerificationStatus.notStarted;
  VerificationStatus get status => _status;

  /// Layers completed so far, in order (drives the S-004/S-007 progress UI).
  final List<VerificationLayer> _completedLayers = [];
  List<VerificationLayer> get completedLayers =>
      List.unmodifiable(_completedLayers);

  bool layerPassed(VerificationLayer layer) => _completedLayers.contains(layer);

  /// The badge exists only when ALL THREE layers passed — photo-match last.
  bool get badgeEarned =>
      _status == VerificationStatus.passed &&
      _completedLayers.length == VerificationLayer.values.length;

  /// LIVE MODE: ask our server to open a vendor session. The server (Edge
  /// Function `verification-session`) creates the provider inquiry and
  /// returns its reference + SDK token; the vendor SDK then runs Layers
  /// 1–3 in ITS OWN UI. Results arrive by webhook — this client polls
  /// `verification_records` (RLS: own row only) for the outcome.
  Future<String?> startLiveSession() async {
    if (Env.useMockBackend) return null;
    try {
      final res = await BackendService()
          .client
          .functions
          .invoke('verification-session');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        _status = VerificationStatus.pending;
        return data['provider_ref'] as String?;
      }
    } catch (e) {
      debugPrint('[VerificationService] session start failed: $e');
    }
    return null;
  }

  /// Is the signed-in account verified (all three layers, badge active)?
  /// LIVE: read from verification_records (RLS: own row only) — the client
  /// can never self-grant this. MOCK: the persisted demo flag.
  Future<bool> isVerified() async {
    if (Env.useMockBackend) return Services.prefs.mockVerified;
    try {
      final client = BackendService().client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return false;
      final row = await client
          .from('verification_records')
          .select('badge_state')
          .eq('user_id', uid)
          .maybeSingle();
      return row != null && row['badge_state'] == 'active';
    } catch (e) {
      debugPrint('[VerificationService] status check failed: $e');
      return false; // fail closed: unverified until proven otherwise
    }
  }

  /// Scaffold behaviour: walks the three layers in order, then passes, so
  /// onboarding can complete end-to-end (MOCK MODE only).
  Future<VerificationStatus> runDemoFlow() async {
    _status = VerificationStatus.pending;
    // Live builds never self-grant layers: open the vendor session and stay
    // pending until the server writes verification_records (badge_state).
    if (!Env.useMockBackend) {
      await startLiveSession();
      return _status;
    }
    for (final layer in VerificationLayer.values) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _completedLayers.add(layer);
      debugPrint('[VerificationService] layer passed: ${layer.label} (stub)');
    }
    _status = VerificationStatus.passed;
    await Services.prefs.setMockVerified(true);
    debugPrint('[VerificationService] all 3 layers passed — badge earned (stub)');
    return _status;
  }
}
