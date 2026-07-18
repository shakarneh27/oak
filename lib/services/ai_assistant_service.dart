import 'package:supabase_flutter/supabase_flutter.dart';

/// المساعد الذكي (شخصية السنديانة). Tries the `ai-get-hint` Supabase Edge
/// Function (see supabase/functions/ai-get-hint) first — matching the
/// `ai_get_hint` event from the spec — and falls back to a local
/// rule-based hint bank so the assistant still works before an LLM key is
/// configured on the backend.
class AiAssistantService {
  final SupabaseClient _client;

  AiAssistantService(this._client);

  static const _localHints = <String, String>{
    'طقس': 'تذكر عناصر الطقس الأربعة: الشمس، الحرارة، الرياح، والهطول. حاول ربط كل صورة بعنصر منها!',
    'كوكب': 'رتّب الكواكب من الأقرب للشمس: عطارد، الزهرة، الأرض، المريخ... جرّب أن تحفظها بجملة طريفة!',
    'كسوف': 'الكسوف يحدث عندما يقف القمر بين الأرض والشمس. حرّك الأجرام الثلاثة وشاهد الظل يتكوّن.',
    'خسوف': 'الخسوف يحدث عندما تقف الأرض بين الشمس والقمر. جرّب رسم الترتيب الصحيح بنفسك.',
    'سلسلة غذائية': 'كل سلسلة غذائية تبدأ من نبات! فكّر من يأكل من، خطوة خطوة.',
    'تنوع حيوي': 'لكل كائن حي بيئته المناسبة. حاول تخيل أين يعيش هذا الكائن في فلسطين.',
    'ضوء': 'الضوء ينعكس بزاوية مساوية لزاوية سقوطه على المرآة — جرّب تدوير المرآة قليلاً!',
  };

  Future<String> getHint(String question) async {
    try {
      final response = await _client.functions.invoke('ai-get-hint', body: {'question': question});
      final hint = (response.data is Map) ? response.data['hint'] as String? : null;
      if (hint != null && hint.isNotEmpty) return hint;
    } catch (_) {
      // Edge function not deployed / offline — fall through to local hints.
    }
    for (final entry in _localHints.entries) {
      if (question.contains(entry.key)) return entry.value;
    }
    return 'أنا السنديانة، هنا لمساعدتك دائماً 🌳 حاول أن تصف لي أين تشعر بالصعوبة بالضبط.';
  }
}
