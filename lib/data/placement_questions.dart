import '../screens/games/engine/game_models.dart';

/// سؤال امتحان تحديد المستوى — [weight] نقاطه (سهل 1، متوسط 2، متقدم 3).
class PlacementQuestion {
  final QuizQuestion question;
  final int weight;

  const PlacementQuestion({required this.question, required this.weight});
}

/// بنك امتحان تحديد المستوى: 9 أسئلة علمية حقيقية متدرجة الصعوبة تغطي
/// الوحدات المختلفة. المجموع الأقصى 18 نقطة:
///   أقل من 8 → ضعيف، 8–13 → متوسط، أكثر من 13 → متقدم.
const List<PlacementQuestion> kPlacementQuestions = [
  // ── سهلة (نقطة واحدة) ────────────────────────────────────────────────
  PlacementQuestion(
    weight: 1,
    question: QuizQuestion(
      text: 'أي مما يلي كائن حي؟',
      options: ['الحجر', 'الشجرة', 'الماء', 'الهواء'],
      correct: 1,
      explanation: 'الشجرة كائن حي لأنها تتغذى وتنمو وتتكاثر.',
    ),
  ),
  PlacementQuestion(
    weight: 1,
    question: QuizQuestion(
      text: 'ما العضو الذي نتنفس به؟',
      options: ['المعدة', 'القلب', 'الرئتان', 'الدماغ'],
      correct: 2,
      explanation: 'الرئتان تدخلان الأكسجين وتخرجان ثاني أكسيد الكربون.',
    ),
  ),
  PlacementQuestion(
    weight: 1,
    question: QuizQuestion(
      text: 'كيف يكون الطقس عندما تتساقط قطرات الماء من السحاب؟',
      options: ['مشمس', 'ممطر', 'عاصف', 'ثلجي'],
      correct: 1,
      explanation: 'تساقط قطرات الماء من السحاب يعني أن الطقس ممطر.',
    ),
  ),
  // ── متوسطة (نقطتان) ──────────────────────────────────────────────────
  PlacementQuestion(
    weight: 2,
    question: QuizQuestion(
      text: 'ما الكوكب الثالث في البعد عن الشمس؟',
      options: ['عطارد', 'المريخ', 'الأرض', 'الزهرة'],
      correct: 2,
      explanation: 'الترتيب: عطارد ثم الزهرة ثم الأرض.',
    ),
  ),
  PlacementQuestion(
    weight: 2,
    question: QuizQuestion(
      text: 'أي المواد التالية موصلة للكهرباء؟',
      options: ['الخشب', 'البلاستيك', 'النحاس', 'الزجاج'],
      correct: 2,
      explanation: 'النحاس معدن موصل جيد للكهرباء، لذلك تصنع منه الأسلاك.',
    ),
  ),
  PlacementQuestion(
    weight: 2,
    question: QuizQuestion(
      text: 'بمَ يبدأ كل سلسلة غذائية؟',
      options: ['بحيوان مفترس', 'بنبات منتج', 'بحشرة', 'بالإنسان'],
      correct: 1,
      explanation: 'النبات هو المنتج لأنه يصنع غذاءه بنفسه من ضوء الشمس.',
    ),
  ),
  // ── متقدمة (3 نقاط) ──────────────────────────────────────────────────
  PlacementQuestion(
    weight: 3,
    question: QuizQuestion(
      text: 'لماذا نرى البرق قبل أن نسمع الرعد؟',
      options: [
        'لأن البرق يحدث أولاً دائماً',
        'لأن الضوء أسرع بكثير من الصوت',
        'لأن الرعد بعيد عنا',
        'لأن أعيننا أقوى من آذاننا',
      ],
      correct: 1,
      explanation: 'الضوء ينتقل أسرع بكثير من الصوت فيصلنا البرق قبل صوت الرعد.',
    ),
  ),
  PlacementQuestion(
    weight: 3,
    question: QuizQuestion(
      text: 'ماذا يحدث للدارة الكهربائية إذا فُتح المفتاح؟',
      options: [
        'تزداد قوة التيار',
        'ينقطع مسار التيار فينطفئ المصباح',
        'يشتعل المصباح أكثر',
        'تنفجر البطارية',
      ],
      correct: 1,
      explanation: 'فتح المفتاح يقطع مسار التيار الكهربائي فينطفئ المصباح.',
    ),
  ),
  PlacementQuestion(
    weight: 3,
    question: QuizQuestion(
      text: 'إذا اختفت الضفادع من سلسلة غذائية (نبات→جراد→ضفدع→ثعبان)، ماذا يحدث غالباً؟',
      options: [
        'لا يتغير شيء',
        'يقل الجراد وتجوع الثعابين',
        'يكثر الجراد وتجوع الثعابين',
        'تزيد النباتات والثعابين معاً',
      ],
      correct: 2,
      explanation: 'بدون الضفادع يتكاثر الجراد الذي كانت تأكله، وتفقد الثعابين غذاءها.',
    ),
  ),
];

/// المستوى الناتج من مجموع النقاط (الأقصى 18).
String placementLevelFor(int score) =>
    score > 13 ? 'Advanced' : score >= 8 ? 'Medium' : 'Weak';
