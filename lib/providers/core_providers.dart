import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/ai_assistant_service.dart';
import '../services/auth_service.dart';
import '../services/sound/sound_service.dart';
import 'settings_provider.dart';
import '../services/catalog_service.dart';
import '../services/realtime_service.dart';
import '../services/remedial_engine.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(ref.watch(supabaseClientProvider));
});

final remedialEngineProvider = Provider<RemedialEngine>((ref) {
  return RemedialEngine(
    ref.watch(supabaseClientProvider),
    ref.watch(realtimeServiceProvider),
  );
});

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService(ref.watch(supabaseClientProvider));
});

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService(ref.watch(supabaseClientProvider));
});

/// Generated sound effects + Arabic speech, gated by the user's settings.
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  service.soundOn = () =>
      ref.read(settingsProvider).valueOrNull?.soundEnabled ?? true;
  service.voiceOn = () =>
      ref.read(settingsProvider).valueOrNull?.aiVoiceAnalyzerEnabled ?? true;
  return service;
});
