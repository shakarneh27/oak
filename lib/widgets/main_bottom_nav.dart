import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _tabs = [
  ('/dashboard', Icons.home_outlined, 'الرئيسية'),
  ('/progress-tree', Icons.park_outlined, 'شجرتي'),
  ('/units', Icons.menu_book_outlined, 'الوحدات'),
  ('/achievements', Icons.emoji_events_outlined, 'الإنجازات'),
  ('/settings', Icons.settings_outlined, 'الإعدادات'),
];

/// Shared bottom navigation for the five student tab screens — tapping
/// a tab just routes, GoRouter keeps each screen's own state.
class MainBottomNav extends StatelessWidget {
  final String currentPath;
  const MainBottomNav({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final index = _tabs.indexWhere((t) => t.$1 == currentPath).clamp(0, _tabs.length - 1);
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => context.go(_tabs[i].$1),
      destinations: [
        for (final tab in _tabs) NavigationDestination(icon: Icon(tab.$2), label: tab.$3),
      ],
    );
  }
}
