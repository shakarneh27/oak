import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/main_bottom_nav.dart';

/// صفحة الإعدادات: الصوت، المحلل الصوتي AI، الملف الشخصي، والثيمات
/// (`update_user_settings`) — محفوظة فعلياً عبر SharedPreferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      bottomNavigationBar: const MainBottomNav(currentPath: '/settings'),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
        data: (settings) => ListView(
          children: [
            profileAsync.when(
              data: (user) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(user?.name ?? ''),
                subtitle: Text(user?.role.name ?? ''),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('الثيم الداكن'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: settings.darkMode,
              onChanged: (v) => notifier.updateSettings((s) => s.copyWith(darkMode: v)),
            ),
            SwitchListTile(
              title: const Text('الصوت'),
              secondary: const Icon(Icons.volume_up_outlined),
              value: settings.soundEnabled,
              onChanged: (v) => notifier.updateSettings((s) => s.copyWith(soundEnabled: v)),
            ),
            SwitchListTile(
              title: const Text('تفعيل المحلل الصوتي بالذكاء الاصطناعي'),
              secondary: const Icon(Icons.mic_none_outlined),
              value: settings.aiVoiceAnalyzerEnabled,
              onChanged: (v) => notifier.updateSettings((s) => s.copyWith(aiVoiceAnalyzerEnabled: v)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
