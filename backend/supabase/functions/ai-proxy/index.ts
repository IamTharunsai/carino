// Cariño · Edge Function: ai-proxy
// The ONLY path from the app to any AI model. Keys live here (server-side
// env), never in the client. Every feature runs its blueprint guardrails:
//   AI-01/02 conversation help — DRAFTS only; this function returns text,
//            the member sends it themselves. There is no send endpoint.
//   AI-03    profile coach — suggestions only, never auto-applied.
//   AI-04    scam/lie SIGNALS — scores are written to the Trust queue for
//            HUMAN review. A model score never bans anyone by itself.
//   AI-05    media pre-screen — holds distribution; humans decide.
//   AI-06    icebreakers — drafts, same rule as AI-01.
//   AI-07    support — always labelled AI in the client, human handoff
//            creates a support case.
// Every call logs suggestion metadata (never message content) to
// ai_interaction_log for the honesty audit.
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FEATURE_MODELS: Record<string, { provider: "anthropic" | "openai"; model: string; promptVersion: string }> = {
  "AI-01": { provider: "anthropic", model: "claude-sonnet", promptVersion: "openers-v4" }, // v4: grounded in body.shared ("You both" labels only, never message content)
  "AI-02": { provider: "anthropic", model: "claude-sonnet", promptVersion: "replies-v3" },
  "AI-03": { provider: "anthropic", model: "claude-sonnet", promptVersion: "coach-v2" },
  "AI-04": { provider: "openai", model: "gpt-screen", promptVersion: "signals-v5" },
  "AI-06": { provider: "anthropic", model: "claude-haiku", promptVersion: "icebreakers-v2" },
  "AI-07": { provider: "anthropic", model: "claude-sonnet", promptVersion: "support-v4" },
};

Deno.serve(async (req: Request) => {
  const auth = req.headers.get("Authorization");
  if (!auth) return json({ error: "unauthorized" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: userData } = await supabase.auth.getUser(
    auth.replace("Bearer ", ""),
  );
  const user = userData?.user;
  if (!user) return json({ error: "unauthorized" }, 401);

  // Per-user rate limit: model calls cost money and are an abuse vector.
  // ponytail: counts this user's log rows in the last minute; move to a
  // token bucket in Redis/KV if traffic ever needs it.
  const since = new Date(Date.now() - 60_000).toISOString();
  const { count } = await supabase
    .from("ai_interaction_log")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .gte("created_at", since);
  if ((count ?? 0) >= 20) {
    return json({ error: "rate_limited", retry_after_seconds: 60 }, 429);
  }

  const body = await req.json().catch(() => ({}));
  const feature = String(body.feature ?? "");
  const route = FEATURE_MODELS[feature];
  if (!route) return json({ error: "unknown feature" }, 400);

  // Per-feature AI consent (S-047) is checked server-side too — a client
  // with the feature off gets a clean refusal, not a silent call.
  // (member_profiles/privacy row carries the flags; checked here in the
  // hosting phase once the privacy table lands in this schema.)

  // --- Model call (provider SDKs wired at hosting; keys from env) ---
  // ANTHROPIC_API_KEY / OPENAI_API_KEY are read from function secrets.
  // The prompts live in versioned files alongside this function at
  // deploy time (promptVersion above is what gets logged).
  const drafts = await callModel(route, body);

  await supabase.from("ai_interaction_log").insert({
    user_id: user.id,
    feature,
    suggestion_id: crypto.randomUUID(),
    model: route.model,
    prompt_version: route.promptVersion,
  });

  // Drafts ONLY. This function has no route that sends anything to
  // another member — that is a deliberate, permanent design constraint.
  return json({ drafts });
});

async function callModel(
  _route: { provider: string; model: string; promptVersion: string },
  _body: any,
): Promise<string[]> {
  // HOSTING PHASE: invoke the provider SDK with the versioned prompt.
  // Until keys are configured the function returns an empty draft list
  // and the client uses its clearly-labelled local fallbacks — it never
  // fabricates model output here.
  return [];
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}
