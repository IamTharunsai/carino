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
  /// [shared] = real "You both" overlaps, so drafts are grounded in them.
  Future<List<String>> suggestOpeners({
    required String memberName,
    List<String> shared = const [],
    String tone = 'normal', // normal | romantic | funny | flirty
    String language = 'English',
    bool mix = false,
    String? lastMessage,
  }) async {
    final live = await _proxy('AI-01', {
      'member_name': memberName,
      'shared': shared,
      'tone': tone,
      'language': language,
      'mix': mix,
      if (lastMessage != null) 'last_message': lastMessage,
    });
    if (live is Map && live['drafts'] is List) {
      return List<String>.from(live['drafts'] as List);
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    // Stubbed drafts — in production these come from the model, and are
    // STILL only shown as drafts above the composer.
    return switch (tone) {
      'romantic' => [
          'Not gonna lie, $memberName — talking to you is the best part of my day.',
          'I keep thinking about our chat. Coffee soon, just us?',
          'You have a way of making ordinary sound really good.',
        ],
      'funny' => [
          'Okay $memberName, defend your most controversial food opinion. I\'m ready.',
          'Rate my texting game 1–10. Be gentle, I bruise easily.',
          'I\'d say hi but I\'ve rehearsed this too many times.',
        ],
      'flirty' => [
          'Careful $memberName, keep smiling like that in your photos and I\'ll have to ask you out.',
          'So… is it the coffee or me that you\'re excited about? 😏',
          'I have a theory you\'re trouble. Want to help me test it?',
        ],
      _ => [
          'Your playlist-rating system needs a public defender. I volunteer.',
          'Okay, $memberName — defend your most controversial food opinion.',
          'Skip the small talk: what\'s the best plan in this city right now?',
        ],
    };
  }

  /// AI profile coach: turns the member's chat answers into a draft
  /// (bio, interests, first-plan prompt). Null = use the offline draft.
  Future<({String? bio, List<String> interests, String? firstPlan})?> coachDraft(
      List<({String q, String a})> answers) async {
    final live = await _proxy('coach', {
      'answers': [for (final x in answers) {'q': x.q, 'a': x.a}],
    });
    if (live is! Map) return null;
    return (
      bio: live['bio'] as String?,
      interests: List<String>.from((live['interests'] as List?) ?? const []),
      firstPlan: live['first_plan'] as String?,
    );
  }

  /// Plan ideas for two people from both profiles (drafts to pick from).
  Future<List<({String title, String what, String search})>> planIdeas({
    required List<String> mine,
    required List<String> theirs,
    String city = '',
    String budget = 'moderate',
  }) async {
    final live = await _proxy('plan_ideas', {'mine': mine, 'theirs': theirs, 'city': city, 'budget': budget});
    if (live is Map && live['ideas'] is List && (live['ideas'] as List).isNotEmpty) {
      return [
        for (final i in live['ideas'] as List)
          (title: '${i['title']}', what: '${i['what']}', search: '${i['search']}')
      ];
    }
    final both = mine.where(theirs.contains).toList();
    final pick = both.isNotEmpty ? both.first : (theirs.isNotEmpty ? theirs.first : 'Coffee');
    return [
      (title: '$pick, together', what: 'You both picked $pick — start there, keep it easy.', search: pick),
      (title: 'Coffee + a walk', what: 'Low pressure, easy to stretch into dinner if it\'s going well.', search: 'coffee shop'),
      (title: 'Market wander', what: 'Browse, snack, people-watch. Lots to talk about.', search: 'farmers market'),
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

  /// Live Translation (labelled "Translated", original one tap away).
  /// Returns null when no translation service is connected — the UI says
  /// so plainly instead of faking a translation.
  Future<String?> translate(String text, {String to = 'English'}) async {
    final live = await _proxy('translate', {'text': text, 'to': to});
    if (live is Map && live['text'] is String) return live['text'] as String;
    return null;
  }

  /// Date Debrief (private): one gentle suggestion for next time, from the
  /// member's own private note. Never shared, never used for ranking.
  Future<String> debriefTip({
    required bool happened,
    required bool comfortable,
    required bool worthwhile,
  }) async {
    final live = await _proxy('debrief', {
      'happened': happened,
      'comfortable': comfortable,
      'worthwhile': worthwhile,
    });
    if (live is Map && live['tip'] is String) return live['tip'] as String;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!happened) {
      return 'Plans fall through. A quick "still on?" the day before saves a wasted trip.';
    }
    if (!comfortable) {
      return 'Trust that feeling. Next time, pick a busier venue and keep check-in on.';
    }
    if (!worthwhile) {
      return 'No spark is useful data. A Spark call first can save an evening.';
    }
    return 'Sounds good! If you want a second date, suggest it while it\'s fresh.';
  }

  /// AI-07: draft a plan into the composer (member reviews + sends).
  Future<String> draftPlanNote({required String placeType}) async {
    debugPrint('[AIService] drafting plan note (stub)');
    return 'Thought this could be fun: $placeType, no pressure either way — pick a time that suits you.';
  }
}
