import 'package:flutter/material.dart';

/// Value object for a marketing feature card.
class FeatureInfo {
  final IconData icon;
  final String title;
  final String description;

  const FeatureInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Value object for a "how it works" step.
class StepInfo {
  final String title;
  final String description;

  const StepInfo({required this.title, required this.description});
}

/// Value object for a quick stat badge in the hero.
class StatInfo {
  final String value;
  final String label;

  const StatInfo({required this.value, required this.label});
}

/// All landing-page copy in one place, separated from the widgets that
/// render it — editing marketing text never touches layout code.
abstract final class LandingContent {
  static const String heroTitle = 'السنديانة الرقمية';
  static const String heroSubtitle =
      'منصة تعليمية تكيفية لمادة العلوم للمرحلة الأساسية — '
      'تحوّل دروس المنهاج الفلسطيني إلى ألعاب تفاعلية تنمو مع مستوى كل طالب، '
      'وتبقي المعلم وولي الأمر في الصورة لحظة بلحظة.';

  static const List<StatInfo> stats = [
    StatInfo(value: '6', label: 'وحدات تعليمية'),
    StatInfo(value: '3', label: 'مستويات تكيفية'),
    StatInfo(value: '16+', label: 'لعبة تفاعلية'),
    StatInfo(value: '4', label: 'قواعد خطة علاجية'),
  ];

  static const List<FeatureInfo> features = [
    FeatureInfo(
      icon: Icons.auto_graph,
      title: 'تكيف ذكي بثلاثة مستويات',
      description:
          'كل لعبة تُقدَّم بمستوى ضعيف ومتوسط ومتقدم، ويتحرك الطالب بينها '
          'تلقائياً بناءً على أدائه الفعلي، لا على تقدير جاهز.',
    ),
    FeatureInfo(
      icon: Icons.healing,
      title: 'خطة علاجية مؤتمتة',
      description:
          'ثلاثة أخطاء متتالية توقف الجلسة بلطف، تسجل فجوة مهارية، وتعيد بناء '
          'المفهوم بلعبة أسهل قبل العودة للتحدي الأصلي.',
    ),
    FeatureInfo(
      icon: Icons.cast_for_education,
      title: 'لوحة معلم لحظية',
      description:
          'نتائج الأنشطة، محاولات الطلاب، وتنبيهات صعوبات التعلم تصل لوحة '
          'المعلم فور حدوثها عبر اتصال مباشر.',
    ),
    FeatureInfo(
      icon: Icons.family_restroom,
      title: 'متابعة ولي الأمر',
      description:
          'تقارير أداء أسبوعية، الشارات المحققة، وتوصيات الخطة العلاجية تصل '
          'ولي الأمر ليشارك في رحلة التعلم.',
    ),
    FeatureInfo(
      icon: Icons.smart_toy_outlined,
      title: 'مساعد السنديانة الذكي',
      description:
          'شخصية ودودة بالذكاء الاصطناعي تحلل إجابات الطالب وتقدم تلميحات '
          'مشجعة دون كشف الحل.',
    ),
    FeatureInfo(
      icon: Icons.park_outlined,
      title: 'شجرة تقدم ومكافآت',
      description:
          'أوراق سنديانة، ثمار بلوط، وشارات تُكسب مع كل إنجاز — وشجرة '
          'تنمو أمام عيني الطالب مع كل درس يتقنه.',
    ),
  ];

  static const List<StepInfo> steps = [
    StepInfo(
      title: 'اختبار تحديد المستوى',
      description: 'تقييم قصير وممتع يحدد نقطة انطلاق الطالب في كل وحدة.',
    ),
    StepInfo(
      title: 'العب وتعلم',
      description:
          'ألعاب تفاعلية مبنية على دروس المنهاج تتكيف مع أداء الطالب لحظياً.',
    ),
    StepInfo(
      title: 'شاهد الشجرة تنمو',
      description:
          'كل إنجاز يحرك شجرة التقدم ويضيف مكافآت، والمعلم وولي الأمر يتابعان النمو.',
    ),
  ];

  static const List<String> unitNames = [
    'أجهزة جسم الإنسان',
    'الكهرباء والمغناطيسية',
    'تصنيف الكائنات الحية',
    'الحالة الجوية',
    'التنوع الحيوي',
    'الضوء والصوت',
  ];

  static const String footerNote =
      'مشروع تعليمي لخدمة طلبة المرحلة الأساسية — السنديانة الرقمية';
}
