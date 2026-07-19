import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart';

/// نظام الصوت — ported from the reference sounds.ts: every effect is a
/// short generated tone sequence (Web Audio API), and [speak] reads text
/// aloud in Arabic via SpeechSynthesis. No audio files needed.
///
/// On non-web platforms the stub implementation is a silent no-op.
abstract class SoundService {
  /// Gate checked before every effect — wired to the user's sound toggle.
  bool Function() soundOn = () => true;

  /// Gate for the spoken voice — wired to the AI-voice toggle.
  bool Function() voiceOn = () => true;

  factory SoundService() => createSoundService();

  SoundService.base();

  /// 🖱️ short blip for button presses.
  void click();

  /// ✅ rising C5–E5–G5 arpeggio.
  void correct();

  /// ❌ falling sawtooth pair.
  void wrong();

  /// 🏆 completion fanfare, richer with more [stars] (1–3).
  void complete(int stars);

  /// ⭐ sparkle when a star pops in.
  void star();

  /// 🗣️ read [text] aloud in Arabic.
  void speak(String text);

  void stopSpeaking();
}
