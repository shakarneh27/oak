import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'sound_service.dart';

SoundService createSoundService() => _WebSoundService();

/// Web Audio implementation — a direct port of the reference sounds.ts.
class _WebSoundService extends SoundService {
  web.AudioContext? _ctx;

  _WebSoundService() : super.base();

  web.AudioContext? get _context {
    try {
      _ctx ??= web.AudioContext();
      if (_ctx!.state == 'suspended') _ctx!.resume();
      return _ctx;
    } catch (_) {
      return null;
    }
  }

  void _tone(
    double freq,
    double start,
    double duration, {
    double gain = 0.25,
    String type = 'sine',
  }) {
    final c = _context;
    if (c == null) return;
    final osc = c.createOscillator();
    final g = c.createGain();
    osc.connect(g);
    g.connect(c.destination);
    osc.type = type;
    final t = c.currentTime + start;
    osc.frequency.setValueAtTime(freq, t);
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(gain, t + 0.02);
    g.gain.exponentialRampToValueAtTime(0.001, t + duration);
    osc.start(t);
    osc.stop(t + duration + 0.05);
  }

  @override
  void click() {
    if (!soundOn()) return;
    _tone(900, 0, 0.07, gain: 0.15);
  }

  @override
  void correct() {
    if (!soundOn()) return;
    _tone(523, 0, 0.15, gain: 0.2);
    _tone(659, 0.12, 0.15, gain: 0.2);
    _tone(784, 0.24, 0.25, gain: 0.2);
  }

  @override
  void wrong() {
    if (!soundOn()) return;
    _tone(400, 0, 0.12, gain: 0.2, type: 'sawtooth');
    _tone(330, 0.1, 0.18, gain: 0.15, type: 'sawtooth');
  }

  @override
  void complete(int stars) {
    if (!soundOn()) return;
    if (stars >= 3) {
      const seq = [523.0, 523.0, 784.0, 659.0, 784.0, 1047.0];
      const times = [0.0, 0.15, 0.3, 0.45, 0.55, 0.65];
      for (var i = 0; i < seq.length; i++) {
        _tone(seq[i], times[i], 0.18);
      }
    } else if (stars == 2) {
      _tone(523, 0, 0.15, gain: 0.2);
      _tone(659, 0.15, 0.15, gain: 0.2);
      _tone(784, 0.3, 0.25, gain: 0.2);
    } else {
      _tone(523, 0, 0.2, gain: 0.2);
      _tone(587, 0.2, 0.2, gain: 0.2);
    }
  }

  @override
  void star() {
    if (!soundOn()) return;
    _tone(1047, 0, 0.1, gain: 0.18);
    _tone(1319, 0.08, 0.12, gain: 0.15);
  }

  @override
  void speak(String text) {
    if (!voiceOn()) return;
    try {
      final synth = web.window.speechSynthesis;
      synth.cancel();
      final utterance = web.SpeechSynthesisUtterance(text)
        ..lang = 'ar-SA'
        ..rate = 0.88
        ..pitch = 1.05;
      final voices = synth.getVoices().toDart;
      for (final voice in voices) {
        if (voice.lang.startsWith('ar')) {
          utterance.voice = voice;
          break;
        }
      }
      synth.speak(utterance);
    } catch (_) {
      // speech synthesis unavailable — stay silent
    }
  }

  @override
  void stopSpeaking() {
    try {
      web.window.speechSynthesis.cancel();
    } catch (_) {}
  }
}
