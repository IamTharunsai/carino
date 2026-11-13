import 'package:flutter/foundation.dart';
import '../config/env.dart';
import 'backend_service.dart';

/// AI assistance (blueprint AI FEATURES sheet: AI-01…AI-07).
///
/// Architecture: Claude/GPT-class APIs sit BEHIND our own thin server —
/// model keys never ship in the app, PII is minimised, and per-feature
/// model + prompt versions are logged server-side.
///
/// HONESTY RULES — NON-NEGOTIABLE (enforced here and in the UI):
///  1. AI drafts; the MEMBER reviews, edits, and sends themselves.
///     Nothing auto-sends. Ever. (AI-01, AI-02, AI-07)
///  2. No fake users, matches, likes, messages, or "AI companions"
///     presented as people. Any AI surface labels itself as AI. (Global)
///  3. Profile Coach (AI-03) gives craft tips only — NO attractiveness
///     score is computed, displayed, or stored.
///  4. Scam/lie detection (AI-04) emits SIGNALS to the human Trust queue —
///     never a verdict, never an automatic ban.
///  5. The Support Assistant (AI-06) identifies itself as AI in its first
///     message and always offers "Talk to a human".
class AIService {
  /// Calls the `ai-proxy` Edge Function (server holds the model keys,
  /// applies the per-feature prompt + guardrails, logs model/prompt
  /// version per AI sheet MODEL ROUTING). Returns null in mock mode or on
  /// failure — callers then use their clearly-labelled local fallbacks.
  Future<dynamic> _proxy(String feature, Map<String, dynamic> payload) async {
    if (Env.useMockBackend) return null;
    try {
      final res = await BackendService().client.functions.invoke(
            'ai-proxy',
            body: {'feature': feature, ...payload},
          );
      return res.data;
    } catch (e) {
      debugPrint('[AIService] proxy $feature failed: $e');
      return null;
    }
  }

  /// AI-01/02: draft opener / reply suggestions for the conversation panel.
  /// INTEGRATION POINT: POST to our server (auth'd) with the conversation
  /// context both members consented to share; server calls the model.
  Future<List<String>> suggestOpeners({required String memberName}) async {
    final live = await _proxy('AI-01', {'member_name': memberName});
    if (live is Map && live['drafts'] is List) {
      return List<String>.from(live['drafts'] as List);
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    // Stubbed drafts — in production these come from the model, and are
    // STILL only shown as drafts above the composer.
    return [
      'Your playlist-rating system needs a public defender. I volunteer.',
      'Okay, $memberName — defend your most controversial food opinion.',
      'Skip the small talk: what\'s the best plan in this city right now?',
    ];
  }

  /// AI-03: profile craft tips (on demand only).
  Future<List<String>> profileCoachTips() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return const [
      'Lead with a solo photo — your clearest shot is currently third.',
      'Your video intro is strong. Add captions so it lands on mute.',
      'Prompt 2 is specific and funny. Prompt 3 could name a real place.',
    ];
  }

  /// AI-07: draft a plan into the composer (member reviews + sends).
  Future<String> draftPlanNote({required String placeType}) async {
    debugPrint('[AIService] drafting plan note (stub)');
    return 'Thought this could be fun: $placeType, no pressure either way — pick a time that suits you.';
  }
}
