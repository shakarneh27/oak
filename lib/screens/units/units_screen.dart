import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../widgets/main_bottom_nav.dart';

/// صفحة الوحدات: استعراض الوحدات الرئيسية الست (`fetch_units_status`).
class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الوحدات')),
      bottomNavigationBar: const MainBottomNav(currentPath: '/units'),
      body: unitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
        data: (units) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: units.length,
          itemBuilder: (context, index) {
            final unit = units[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(unit.nameAr),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.push('/units/${unit.unitKey}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
