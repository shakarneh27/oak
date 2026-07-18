import '../models/adaptive_level.dart';
import '../models/game_interaction.dart';

/// Concrete playable content for every game in the catalog (see
/// games_matrix_data.dart), built on the three generic mechanics in
/// AdaptiveGameShell: match, sequence and mcq. Item counts grow with the
/// level to express difficulty, matching the weak/medium/advanced
/// descriptions from the spreadsheet.
final Map<String, GameInteractionConfig> kGameInteractions = {
  'weather_hunter': const GameInteractionConfig.match({
    AdaptiveLevel.weak: [
      MatchItem('☀️', 'شمس'),
      MatchItem('🌧️', 'مطر'),
      MatchItem('☁️', 'غيوم'),
    ],
    AdaptiveLevel.medium: [
      MatchItem('☀️', 'مشمس'),
      MatchItem('⛈️', 'عاصف ممطر'),
      MatchItem('🌥️', 'غائم جزئياً'),
      MatchItem('🌫️', 'ضبابي'),
    ],
    AdaptiveLevel.advanced: [
      MatchItem('🌡️35°', 'موجة حارة'),
      MatchItem('❄️', 'حالة صقيع'),
      MatchItem('🌬️', 'رياح نشطة'),
      MatchItem('🌦️', 'مطر متقطع مع شمس'),
      MatchItem('⛅', 'غائم جزئياً معتدل'),
    ],
  }),
  'junior_weather_reporter': const GameInteractionConfig.match({
    AdaptiveLevel.weak: [
      MatchItem('☀️', 'القدس'),
      MatchItem('🌧️', 'رام الله'),
    ],
    AdaptiveLevel.medium: [
      MatchItem('☀️', 'غزة'),
      MatchItem('🌧️', 'نابلس'),
      MatchItem('🌬️', 'الخليل'),
    ],
    AdaptiveLevel.advanced: [
      MatchItem('⛈️', 'أريحا'),
      MatchItem('❄️', 'رام الله (شتاءً)'),
      MatchItem('🌫️', 'بيت لحم'),
      MatchItem('🌦️', 'طولكرم'),
    ],
  }),
  'weather_lab': const GameInteractionConfig.match({
    AdaptiveLevel.weak: [
      MatchItem('🌡️', 'ترمومتر - الحرارة'),
      MatchItem('☂️', 'مظلة - المطر'),
    ],
    AdaptiveLevel.medium: [
      MatchItem('🌡️', 'الحرارة'),
      MatchItem('💨', 'الرياح'),
      MatchItem('💧', 'الرطوبة'),
    ],
    AdaptiveLevel.advanced: [
      MatchItem('🌡️', 'مقياس الحرارة'),
      MatchItem('🧭', 'دوارة الرياح'),
      MatchItem('📏', 'مقياس هطول الأمطار'),
      MatchItem('📈', 'مقياس الضغط الجوي'),
    ],
  }),
  'weather_station': const GameInteractionConfig.match({
    AdaptiveLevel.weak: [
      MatchItem('🌡️', 'يقيس الحرارة'),
      MatchItem('🧭', 'يقيس اتجاه الرياح'),
    ],
    AdaptiveLevel.medium: [
      MatchItem('🌡️', 'الحرارة'),
      MatchItem('🧭', 'اتجاه الرياح'),
      MatchItem('☔', 'كمية الأمطار'),
    ],
    AdaptiveLevel.advanced: [
      MatchItem('🌡️', 'الحرارة'),
      MatchItem('🧭', 'اتجاه الرياح'),
      MatchItem('☔', 'كمية الأمطار'),
      MatchItem('📈', 'الضغط الجوي'),
      MatchItem('💧', 'الرطوبة النسبية'),
    ],
  }),
  'four_seasons': const GameInteractionConfig.match({
    AdaptiveLevel.weak: [
      MatchItem('🌸', 'الربيع'),
      MatchItem('☀️', 'الصيف'),
    ],
    AdaptiveLevel.medium: [
      MatchItem('🍂', 'الخريف'),
      MatchItem('❄️', 'الشتاء'),
      MatchItem('🌸', 'الربيع'),
    ],
    AdaptiveLevel.advanced: [
      MatchItem('☀️ ميل الأرض الأقصى نحو الشمس', 'الصيف'),
      MatchItem('❄️ ميل الأرض الأقصى بعيداً عن الشمس', 'الشتاء'),
      MatchItem('🍂 اعتدال الميل تناقصياً', 'الخريف'),
      MatchItem('🌸 اعتدال الميل تصاعدياً', 'الربيع'),
    ],
  }),
  'creature_explorer': const GameInteractionConfig.match({
    AdaptiveLevel.weak: [
      MatchItem('🐦', 'طيور'),
      MatchItem('🐟', 'أسماك'),
      MatchItem('🌳', 'نباتات'),
    ],
    AdaptiveLevel.medium: [
      MatchItem('🐫', 'الصحراء الفلسطينية'),
      MatchItem('🐟', 'البحر المتوسط'),
      MatchItem('🦅', 'الجبال'),
    ],
    AdaptiveLevel.advanced: [
      MatchItem('🐫', 'أريحا والأغوار'),
      MatchItem('🐟', 'الساحل الفلسطيني'),
      MatchItem('🦅', 'جبال الخليل'),
      MatchItem('🐸', 'الأودية الرطبة'),
    ],
  }),
  'planet_order': const GameInteractionConfig.sequence({
    AdaptiveLevel.weak: ['☀️ الشمس', '☿️ عطارد', '🌍 الأرض'],
    AdaptiveLevel.medium: ['☿️ عطارد', '♀️ الزهرة', '🌍 الأرض', '♂️ المريخ'],
    AdaptiveLevel.advanced: ['☿️ عطارد', '♀️ الزهرة', '🌍 الأرض', '♂️ المريخ', '🪐 المشتري', '🪐 زحل'],
  }),
  'planet_race': const GameInteractionConfig.sequence({
    AdaptiveLevel.weak: ['☿️ عطارد', '🌍 الأرض'],
    AdaptiveLevel.medium: ['☿️ عطارد', '♀️ الزهرة', '🌍 الأرض', '♂️ المريخ'],
    AdaptiveLevel.advanced: ['☿️ عطارد', '♀️ الزهرة', '🌍 الأرض', '♂️ المريخ', '🪐 المشتري'],
  }),
  'build_solar_system': const GameInteractionConfig.sequence({
    AdaptiveLevel.weak: ['☀️ الشمس (الأكبر)', '🪐 المشتري', '🌍 الأرض'],
    AdaptiveLevel.medium: ['☀️ الشمس', '🪐 المشتري', '🪐 زحل', '🌍 الأرض', '☿️ عطارد (الأصغر)'],
    AdaptiveLevel.advanced: [
      '☀️ الشمس',
      '🪐 المشتري',
      '🪐 زحل',
      '🌍 الأرض',
      '♀️ الزهرة',
      '♂️ المريخ',
      '☿️ عطارد',
    ],
  }),
  'build_the_chain': const GameInteractionConfig.sequence({
    AdaptiveLevel.weak: ['🌱 نبات', '🦗 جراد', '🐸 ضفدع'],
    AdaptiveLevel.medium: ['🌱 نبات', '🦗 جراد', '🐸 ضفدع', '🐍 أفعى'],
    AdaptiveLevel.advanced: ['🌱 نبات', '🦗 جراد', '🐸 ضفدع', '🐍 أفعى', '🦅 صقر'],
  }),
  'beam_maze': const GameInteractionConfig.sequence({
    AdaptiveLevel.weak: ['🔦 المصدر', '🎯 الهدف'],
    AdaptiveLevel.medium: ['🔦 المصدر', '🪞 مرآة 90°', '🎯 الهدف'],
    AdaptiveLevel.advanced: ['🔦 المصدر', '🪞 مرآة 1', '🪞 مرآة 2', '🪞 مرآة 3', '🎯 الهدف'],
  }),
  'move_the_bodies': const GameInteractionConfig.sequence({
    AdaptiveLevel.weak: ['☀️ الشمس', '🌍 الأرض', '🌕 القمر'],
    AdaptiveLevel.medium: ['☀️ الشمس', '🌍 الأرض', '🌑 القمر (كسوف)'],
    AdaptiveLevel.advanced: ['☀️ الشمس', '🌑 القمر', '🌍 الأرض', '🌑 ظل الأرض (خسوف)'],
  }),
  'weather_expert_challenge': const GameInteractionConfig.mcq({
    AdaptiveLevel.weak: [
      McqQuestion('أي رمز يدل على المطر؟', ['☀️', '🌧️', '🏜️'], 1),
      McqQuestion('ما هي أداة قياس الحرارة؟', ['ترمومتر', 'مظلة', 'كتاب'], 0),
    ],
    AdaptiveLevel.medium: [
      McqQuestion('ماذا نسمي الجو الغائم مع مطر خفيف؟', ['ممطر جزئياً', 'مشمس تماماً', 'صقيع'], 0),
      McqQuestion('أي أداة تقيس اتجاه الرياح؟', ['دوارة الرياح', 'الترمومتر', 'المظلة'], 0),
      McqQuestion('ماذا يقيس مقياس هطول الأمطار؟', ['كمية المطر', 'درجة الحرارة', 'سرعة الرياح'], 0),
    ],
    AdaptiveLevel.advanced: [
      McqQuestion(
        'انخفضت الحرارة فجأة وزادت الرطوبة والسحب الركامية تتجمع، ما الحالة الجوية المتوقعة؟',
        ['عاصفة رعدية', 'موجة حر', 'جفاف'],
        0,
      ),
      McqQuestion('ما العلاقة بين الضغط الجوي المنخفض والطقس؟', ['غالباً يرافقه طقس غير مستقر', 'دائماً طقس صافٍ', 'لا علاقة'], 0),
      McqQuestion('لماذا يُستخدم القمر الصناعي في التنبؤ الجوي؟', ['لرصد حركة السحب والعواصف', 'لقياس الحرارة فقط', 'لا فائدة منه'], 0),
    ],
  }),
  'space_journey': const GameInteractionConfig.mcq({
    AdaptiveLevel.weak: [
      McqQuestion('ما اسم الكوكب الذي نعيش عليه؟', ['الأرض', 'المريخ', 'زحل'], 0),
    ],
    AdaptiveLevel.medium: [
      McqQuestion('ما هو الكوكب الأحمر؟', ['المريخ', 'الزهرة', 'عطارد'], 0),
      McqQuestion('ما أقرب كوكب إلى الشمس؟', ['عطارد', 'الأرض', 'زحل'], 0),
    ],
    AdaptiveLevel.advanced: [
      McqQuestion('ما هو أكبر كوكب في المجموعة الشمسية؟', ['المشتري', 'الأرض', 'عطارد'], 0),
      McqQuestion('ما الكوكب المعروف بحلقاته البارزة؟', ['زحل', 'المريخ', 'الزهرة'], 0),
    ],
  }),
  'who_am_i': const GameInteractionConfig.mcq({
    AdaptiveLevel.weak: [
      McqQuestion('هذا الكوكب لونه أحمر، من أنا؟', ['المريخ', 'زحل', 'عطارد'], 0),
    ],
    AdaptiveLevel.medium: [
      McqQuestion('أنا الأقرب للشمس، من أنا؟', ['عطارد', 'الأرض', 'المشتري'], 0),
      McqQuestion('أنا الكوكب الذي تعيشون عليه، من أنا؟', ['الأرض', 'زحل', 'الزهرة'], 0),
    ],
    AdaptiveLevel.advanced: [
      McqQuestion('أنا الأكبر حجماً ولدي بقعة حمراء عظيمة، من أنا؟', ['المشتري', 'عطارد', 'الأرض'], 0),
      McqQuestion('لدي حلقات جليدية وصخرية واضحة، من أنا؟', ['زحل', 'المريخ', 'الزهرة'], 0),
    ],
  }),
  'day_and_night': const GameInteractionConfig.mcq({
    AdaptiveLevel.weak: [
      McqQuestion('متى يكون النهار؟', ['عندما تواجه الأرض الشمس', 'عندما تبتعد الأرض عن الشمس', 'دائماً'], 0),
    ],
    AdaptiveLevel.medium: [
      McqQuestion('لماذا يحدث الليل والنهار؟', ['دوران الأرض حول نفسها', 'دوران القمر حول الأرض', 'دوران الشمس حول الأرض'], 0),
      McqQuestion('كم ساعة تستغرق الأرض لتدور حول نفسها دورة كاملة؟', ['24 ساعة', '365 يوماً', 'ساعة واحدة'], 0),
    ],
    AdaptiveLevel.advanced: [
      McqQuestion('ماذا يحدث لو دارت الأرض أبطأ بكثير؟', ['تطول مدة النهار والليل', 'يختفي الليل تماماً', 'لا يتغير شيء'], 0),
      McqQuestion('كيف تؤثر زاوية ميل محور الأرض على طول النهار؟', ['تسبب اختلاف طول النهار بين الفصول', 'لا تؤثر إطلاقاً', 'تسبب توقف الدوران'], 0),
    ],
  }),
};
