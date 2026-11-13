import 'package:flutter/foundation.dart';

/// Video calling for Spark Sessions and connection calls (S-026 → S-033).
///
/// PRODUCTION: a managed WebRTC provider (Daily / Agora class) — do NOT
/// home-build WebRTC signalling, TURN, or abuse handling.
///
/// Non-negotiables baked into the product (Apple Guideline 1.2 + Bible):
///  - Cameras open ONLY after BOTH people accept from full profiles
///    (S-027). Anonymous/random video is prohibited — this service must
///    refuse a session token for any non-mutual pairing.
///  - Calls are between connections only — never strangers (S-033).
///  - Report stays reachable DURING the call (S-029), and Leave is instant.
///  - Incoming calls use the platform call UI (CallKit / ConnectionService).
///
/// INTEGRATION POINT: the server mints a short-lived room token after it
/// verifies mutual acceptance; this service joins that room and exposes
/// local/remote tracks to SparkCallScreen.
class VideoService {
  bool _inCall = false;
  bool get inCall => _inCall;

  /// LIVE MODE: join with a server-minted, short-lived room token. The
  /// server mints it ONLY after verifying mutual acceptance (S-027) —
  /// this method refuses to run without one.
  Future<bool> joinWithToken(String roomToken) async {
    if (roomToken.isEmpty) {
      debugPrint('[VideoService] refused: no mutual-acceptance token');
      return false;
    }
    // INTEGRATION POINT: provider SDK join (Daily/Agora class) with
    // [roomToken]; expose local/remote tracks to SparkCallScreen.
    _inCall = true;
    return true;
  }

  Future<void> joinDemoSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _inCall = true;
    debugPrint('[VideoService] demo Spark session joined (stub — no real media)');
  }

  Future<void> leave() async {
    _inCall = false;
    debugPrint('[VideoService] left session (stub)');
  }
}
