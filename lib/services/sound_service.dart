import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'services.dart';

/// Sound + haptics (blueprint SOUND DESIGN and ANIMATION & MOTION sheets).
///
/// Signature sounds (all ORIGINAL audio — the shipped .wav files are
/// synthesized in-repo, no unlicensed library sounds; see the licensing
/// rule in the blueprint):
///  - matchChime:      soft two-note chime, the brand sound (S-020)
///  - planConfirmed:   warm confirmation tone, fuller than a message (S-040)
///  - messageBlip:     optional, very quiet, generic by design (S-035)
///  - flipTick:        subtle game-reveal tick (S-031)
///  - sparkShimmer:    reserved; Spark window itself is SILENT by default
///  - safety actions:  NO SOUND, ever — steady haptic only (S-049/S-050B)
///
/// MUTE RULES (global): a sound plays only if ALL of these allow it —
/// OS silent mode off, in-app Sounds ON (UserPrefs.soundsEnabled), and
/// this service's master switch. Member media (voice notes, video intros)
/// NEVER autoplays with sound.
///
/// Playback is best-effort: every call is wrapped so a missing audio
/// session (web, tests, silent hardware) can never crash a flow.
class SoundService {
  bool appSoundsEnabled = true;

  final AudioPlayer _player = AudioPlayer();

  bool get _mayPlay => appSoundsEnabled && Services.prefs.soundsEnabled;

  /// Plays [asset] (relative to assets/) if sound is allowed. All errors
  /// are swallowed after a debug log — sound is garnish, never a gate.
  void _playAsset(String asset) {
    if (!_mayPlay) {
      debugPrint('[SoundService] (silent) $asset');
      return;
    }
    unawaited(() async {
      try {
        await _player.play(AssetSource(asset));
      } catch (e) {
        debugPrint('[SoundService] playback failed ($asset): $e');
      }
    }());
  }

  /// The brand two-note chime (E6 → B6), synthesized at assets/sounds/.
  void matchChime() => _playAsset('sounds/chime.wav');

  /// Confirmation reuses the chime — one brand sound for good news.
  void planConfirmed() => _playAsset('sounds/chime.wav');

  /// Short soft blip for message/game cues.
  void messageBlip() => _playAsset('sounds/tap.wav');
  void flipTick() => _playAsset('sounds/tap.wav');

  /// Light tap — card commit, call accept (ANIMATION sheet).
  void tapHaptic() => HapticFeedback.lightImpact();

  /// Single gentle pulse — match moment, mode switch accepted.
  void gentleHaptic() => HapticFeedback.mediumImpact();

  /// Safety actions: steady haptic, NO sound. Calm by design.
  void safetyHaptic() => HapticFeedback.heavyImpact();
}
