import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool darkMode;
  final bool soundEnabled;
  final bool aiVoiceAnalyzerEnabled;

  const AppSettings({
    required this.darkMode,
    required this.soundEnabled,
    required this.aiVoiceAnalyzerEnabled,
  });

  static const defaults = AppSettings(
    darkMode: false,
    soundEnabled: true,
    aiVoiceAnalyzerEnabled: true,
  );

  AppSettings copyWith({
    bool? darkMode,
    bool? soundEnabled,
    bool? aiVoiceAnalyzerEnabled,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      aiVoiceAnalyzerEnabled:
          aiVoiceAnalyzerEnabled ?? this.aiVoiceAnalyzerEnabled,
    );
  }
}

/// Backs صفحة الإعدادات (`update_user_settings`) with real persistence via
/// SharedPreferences instead of a bare in-memory toggle.
class SettingsService {
  static const _darkModeKey = 'settings.dark_mode';
  static const _soundKey = 'settings.sound_enabled';
  static const _aiVoiceKey = 'settings.ai_voice_analyzer_enabled';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      darkMode: prefs.getBool(_darkModeKey) ?? AppSettings.defaults.darkMode,
      soundEnabled:
          prefs.getBool(_soundKey) ?? AppSettings.defaults.soundEnabled,
      aiVoiceAnalyzerEnabled:
          prefs.getBool(_aiVoiceKey) ??
          AppSettings.defaults.aiVoiceAnalyzerEnabled,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, settings.darkMode);
    await prefs.setBool(_soundKey, settings.soundEnabled);
    await prefs.setBool(_aiVoiceKey, settings.aiVoiceAnalyzerEnabled);
  }
}
