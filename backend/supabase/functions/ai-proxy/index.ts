// Cariño · Edge Function: ai-proxy
// The ONLY path from the app to any AI model. Keys live here (server-side
// secrets), never in the client. Provider: NVIDIA NIM (OpenAI-compatible),
// set by AI_PROVIDER / NVIDIA_* secrets.
//
// Honesty rules enforced here:
//   - AI-01 openers: DRAFTS only. There is no send endpoint — the member
//     edits and sends themselves. Grounded ONLY in the "You both" labels.
//   - translate: labelled "Translated" in the app, original one tap away.
//   - debrief: one private suggestion for the member, never shared.
// Every call logs metadata (never message content) to ai_interaction_log.
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Feature = { promptVersion: string; maxTokens: number; build: (b: any) => string };

const clip = (v: unknown, n: number) => String(v ?? "").slice(0, n).replace(/[\u0000-\u001f]/g, " ");

const FEATURES: Record<string, Feature> = {
  "AI-01": {
    promptVersion: "openers-v5-nim",
    maxTokens: 300,
    build: (b) => {
      const shared = (Array.isArray(b.shared) ? b.shared : []).slice(0, 10).map((s: unknown) => clip(s, 30));
      return `Write 3 short, warm first-message drafts (each under 25 words) that a dating-app member could send to ${clip(b.member_name, 40) || "their match"}.
Base them ONLY on these shared interests: ${shared.join(", ") || "none — keep them general and friendly"}.
No pickup lines, nothing sexual, no compliments on looks, no personal data. They are drafts the member will edit.
Reply with JSON only: {"drafts": ["...", "...", "..."]}`;
    },
  },
  translate: {
    promptVersion: "translate-v1-nim",
    maxTokens: 400,
    build: (b) =>
      `Translate this chat message into ${clip(b.to, 20) || "English"}. Keep the tone. Reply with JSON only: {"text": "..."}\n\nMessage: ${clip(b.text, 1000)}`,
  },
  debrief: {
    promptVersion: "debrief-v1-nim",
    maxTokens: 120,
    build: (b) =>
      `A dating-app member just had a first plan. Did it happen: ${!!b.happened}. Felt comfortable: ${!!b.comfortable}. Worthwhile: ${!!b.worthwhile}.
Give ONE kind, practical suggestion for next time in under 30 words. If they didn't feel comfortable, put safety first and mention reporting if anything happened.
Reply with JSON only: {"tip": "..."}`,
  },
};

Deno.serve(async (req: Request) => {
  const auth = req.headers.get("Authorization");
  if (!auth) return json({ error: "unauthorized" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: userData } = await supabase.auth.getUser(auth.replace("Bearer ", ""));
  const user = userData?.user;
  if (!user) return json({ error: "unauthorized" }, 401);

  // Per-user rate limit: model calls cost money and are an abuse vector.
  // ponytail: counts this user's log rows in the last minute; move to a
  // token bucket in KV if traffic ever needs it.
  const since = new Date(Date.now() - 60_000).toISOString();
  const { count } = await supabase
    .from("ai_interaction_log")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .gte("created_at", since);
  if ((count ?? 0) >= 20) return json({ error: "rate_limited", retry_after_seconds: 60 }, 429);

  // Cost-abuse guard: drafts need tiny inputs; refuse oversized payloads.
  const raw = await req.text();
  if (raw.length > 8_000) return json({ error: "payload too large" }, 413);
  let body: any = {};
  try { body = JSON.parse(raw); } catch { /* empty body -> unknown feature */ }
  const name = String(body.feature ?? "");
  const feature = FEATURES[name];
  if (!feature) return json({ error: "unknown feature" }, 400);

  const out = await callModel(feature.build(body), feature.maxTokens);

  await supabase.from("ai_interaction_log").insert({
    user_id: user.id,
    feature: name,
    suggestion_id: crypto.randomUUID(),
    model: Deno.env.get("NVIDIA_MODEL") ?? "unset",
    prompt_version: feature.promptVersion,
  });

  // Validate the model's output shape before it reaches the app.
  if (name === "AI-01") {
    const drafts = (Array.isArray(out?.drafts) ? out.drafts : [])
      .filter((d: unknown) => typeof d === "string" && d.trim())
      .slice(0, 3)
      .map((d: string) => d.trim().slice(0, 200));
    return json({ drafts }); // empty -> the app uses its labelled local openers
  }
  if (name === "translate") return json({ text: typeof out?.text === "string" ? out.text.slice(0, 2000) : null });
  return json({ tip: typeof out?.tip === "string" ? out.tip.slice(0, 300) : null });
});

/// One chat completion; returns the parsed JSON object or null (never throws).
async function callModel(prompt: string, maxTokens: number): Promise<any> {
  const key = Deno.env.get("NVIDIA_API_KEY");
  if (!key) return null; // not configured: the app falls back honestly
  try {
    const res = await fetch(`${Deno.env.get("NVIDIA_BASE_URL") ?? "https://integrate.api.nvidia.com/v1"}/chat/completions`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${key}`, "Content-Type": "application/json" },
      signal: AbortSignal.timeout(20_000),
      body: JSON.stringify({
        model: Deno.env.get("NVIDIA_MODEL") ?? "nvidia/nemotron-3-ultra-550b-a55b",
        messages: [
          { role: "system", content: "You help members of Cariño, a verified dating and social app. You only ever write drafts or private suggestions. Always reply with the exact JSON requested and nothing else." },
          { role: "user", content: prompt },
        ],
        max_tokens: maxTokens,
        temperature: 0.7,
        chat_template_kwargs: { enable_thinking: false },
      }),
    });
    if (!res.ok) return null;
    const data = await res.json();
    const text: string = data?.choices?.[0]?.message?.content ?? "";
    const m = text.match(/\{[\s\S]*\}/);
    return m ? JSON.parse(m[0]) : null;
  } catch {
    return null;
  }
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}
