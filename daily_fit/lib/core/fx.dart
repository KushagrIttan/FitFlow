import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Small shared tones played through the device speaker.
enum FxTone {
  /// Crisp UI tick (nav taps, buttons).
  tap,

  /// Soft confirm pop (saves, wears, laundry done).
  pop,

  /// Filtered-noise swish (tab drag commit / swipe).
  swish,

  /// Rising lift whoosh (capsule pickup / style me).
  whoosh,

  /// Bright pluck (ratings, chip selection, verifies).
  pluck,
}

/// Centralized haptic + sound feedback.
///
/// Set [Fx.enabled] to false in widget tests / when minimizing feedback.
class Fx {
  static bool enabled = true;

  static final AudioPlayer _player = AudioPlayer();

  static const Map<FxTone, String> _assets = {
    FxTone.tap: 'audio/tap.wav',
    FxTone.pop: 'audio/pop.wav',
    FxTone.swish: 'audio/swish.wav',
    FxTone.whoosh: 'audio/whoosh.wav',
    FxTone.pluck: 'audio/pluck.wav',
  };

  /// Plays a bundled sound (no-op when disabled or playback fails).
  static void tone(FxTone tone) {
    if (!enabled) return;
    // Fire-and-forget: playback errors are non-fatal.
    _player.play(AssetSource(_assets[tone]!));
  }

  /// Light tap haptic.
  static void light() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Medium impact haptic (tab switches, drag commits, lifts).
  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Heavy impact haptic (destructive / confirm-heavy actions).
  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}