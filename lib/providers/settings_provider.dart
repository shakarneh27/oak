import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.watch(settingsServiceProvider).load();

  Future<void> updateSettings(AppSettings Function(AppSettings) transform) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    final updated = transform(current);
    state = AsyncData(updated);
    await ref.read(settingsServiceProvider).save(updated);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
