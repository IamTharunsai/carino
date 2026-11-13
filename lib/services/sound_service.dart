import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sound + haptics (blueprint SOUND DESIGN and ANIMATION & MOTION sheets).
///
/// Signature sounds (all ORIGINAL commissioned audio — no unlicensed
/// library sounds ship; see licensing rule in the blueprint):
///  - matchChime:      soft two-note chime, the brand sound (S-020)
///  - planConfirmed:   warm confirmation tone, fuller than a message (S-040)
///  - messageBlip:     optional, very quiet, generic by design (S-035)
///  - flipTick:        subtle game-reveal tick (S-031)
///  - sparkShimmer:    reserved; Spark window itself is SILENT by default
///  - safety actions:  NO SOUND, ever — steady haptic only (S-049/S-050B)
///
/// MUTE RULES (global): a sound plays only if ALL of these allow it —
/// OS silent mode off, in-app Sounds ON, per-category setting ON.
/// Member media (voice notes, video intros) NEVER autoplays with sound.
///
/// SCAFFOLD: sounds are stubs (debugPrint) — drop the commissioned .m4a
/// files into assets/sounds/ and play them here with an audio plugin.
/// Haptics are real (HapticFeedback) and already respect OS settings.
class SoundService {
  bool appSoundsEnabled = true;

  bool get _mayPlay => appSoundsEnabled; // + OS silent switch check in prod

  void _cue(String name, {required bool audible}) {
    if (audible && _mayPlay) {
      // INTEGRATION POINT: play assets/sounds/$name.m4a at low gain.
      debugPrint('[SoundService] ♪ $name');
    } else {
      debugPrint('[SoundService] (silent) $name');
    }
  }

  void matchChime() => _cue('match_chime', audible: true);
  void planConfirmed() => _cue('plan_confirmed', audible: true);
  void messageBlip() => _cue('message_blip', audible: true);
  void flipTick() => _cue('flip_tick', audible: true);

  /// Light tap — card commit, call accept (ANIMATION sheet).
  void tapHaptic() => HapticFeedback.lightImpact();

  /// Single gentle pulse — match moment, mode switch accepted.
  void gentleHaptic() => HapticFeedback.mediumImpact();

  /// Safety actions: steady haptic, NO sound. Calm by design.
  void safetyHaptic() => HapticFeedback.heavyImpact();
}
