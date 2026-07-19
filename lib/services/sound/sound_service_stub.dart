import 'sound_service.dart';

SoundService createSoundService() => _SilentSoundService();

/// No-op implementation for platforms without Web Audio (used until a
/// native audio backend is added for mobile builds).
class _SilentSoundService extends SoundService {
  _SilentSoundService() : super.base();

  @override
  void click() {}

  @override
  void correct() {}

  @override
  void wrong() {}

  @override
  void complete(int stars) {}

  @override
  void star() {}

  @override
  void speak(String text) {}

  @override
  void stopSpeaking() {}
}
