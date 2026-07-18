// Supabase Edge Function: ai-get-hint
//
// Backs the "صفحة الذكاء الاصطناعي" screen's `ai_get_hint` event. Deploy
// with `supabase functions deploy ai-get-hint` and set an ANTHROPIC_API_KEY
// secret (`supabase secrets set ANTHROPIC_API_KEY=...`) to enable real LLM
// hints; the Flutter client falls back to a local hint bank if this
// function is not deployed or the request fails.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req: Request) => {
  try {
    const { question } = await req.json();
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");

    if (!apiKey || !question) {
      return new Response(JSON.stringify({ hint: null }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const completion = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-5",
        max_tokens: 200,
        system:
          "أنت شخصية 'السنديانة'، مساعد تعليمي ودود لأطفال المرحلة الابتدائية في فلسطين. " +
          "أجب بجملة أو جملتين مشجعتين بالعربية الفصحى المبسطة، دون كشف الإجابة النهائية مباشرة، بل قدم تلميحاً.",
        messages: [{ role: "user", content: question }],
      }),
    });

    const data = await completion.json();
    const hint = data?.content?.[0]?.text ?? null;

    return new Response(JSON.stringify({ hint }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ hint: null, error: String(error) }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }
});
