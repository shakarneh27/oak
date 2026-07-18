import '../models/game_definition.dart';

/// Static fallback copy of the `units` reference table, in case the app
/// is opened before Supabase reference data has synced locally.
const List<Unit> kUnits = [
  Unit(unitKey: 'unit_1', nameAr: 'الوحدة 1: أجهزة جسم الإنسان', sortOrder: 1),
  Unit(
    unitKey: 'unit_2',
    nameAr: 'الوحدة 2: الكهرباء والمغناطيسية',
    sortOrder: 2,
  ),
  Unit(
    unitKey: 'unit_3',
    nameAr: 'الوحدة 3: تصنيف الكائنات الحية',
    sortOrder: 3,
  ),
  Unit(unitKey: 'unit_4', nameAr: 'الوحدة 4: الحالة الجوية', sortOrder: 4),
  Unit(unitKey: 'unit_5', nameAr: 'الوحدة 5: التنوع الحيوي', sortOrder: 5),
  Unit(unitKey: 'unit_6', nameAr: 'الوحدة 6: الضوء والصوت', sortOrder: 6),
];
