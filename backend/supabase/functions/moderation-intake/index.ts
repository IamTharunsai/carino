// Cariño · Edge Function: moderation-intake
// Receives a media id after upload, runs the pre-screen (AI-05 via the
// screening provider), and sets media.moderation_state. Media stays
// 'pending' (undistributed) until this function approves it; explicit or
// borderline content goes 'held' for a HUMAN — the model never has the
// final word on distribution OR on enforcement.
// Invoked by: database webhook on public.media insert (service role).
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { decide, type Verdict } from "./verdict.ts";

Deno.serve(async (req: Request) => {
  // Only the DB webhook / scheduler may call this (verify_jwt=false). Fail closed.
  const secret = Deno.env.get("JOB_SECRET");
  if (!secret || req.headers.get("x-job-secret") !== secret) {
    return new Response("forbidden", { status: 403 });
  }
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { record } = await req.json().catch(() => ({ record: null }));
  const mediaId = record?.id as string | undefined;
  if (!mediaId) return json({ error: "no media id" }, 400);

  // AI pre-screen (NVIDIA vision). Verdict mapping is conservative:
  //   clear            -> approved
  //   borderline/adult -> held (human reviews; profile media of adults is
  //                       policy-governed, not auto-rejected)
  //   csam/illegal     -> rejected + immediate Trust escalation + vault
  const verdict = await screenMedia(supabase, record);
  const state =
    verdict === "clear" ? "approved" : verdict === "illegal" ? "rejected" : "held";

  await supabase
    .from("media")
    .update({ moderation_state: state })
    .eq("id", mediaId);

  if (verdict === "illegal") {
    // Escalation row for the Trust queue (S-057) — staff act, not the model.
    await supabase.from("reports").insert({
      reporter: record.owner,
      reported: record.owner,
      category: "Inappropriate content",
      reason: "Automated screen: illegal content signal",
      surface: "moderation-intake",
      status: "in_review",
    });
  }
  return json({ mediaId, state });
});

/// AI pre-screen with an NVIDIA vision model on a 2-minute signed URL.
/// Returns "borderline" (human review) whenever anything is unclear.
async function screenMedia(supabase: any, record: any): Promise<Verdict> {
  const key = Deno.env.get("NVIDIA_API_KEY");
  if (!key || record?.kind === "voice_intro") return "borderline";
  const { data: signed } = await supabase.storage
    .from(record.bucket).createSignedUrl(record.object_path, 120);
  if (!signed?.signedUrl) return "borderline";
  try {
    const res = await fetch(`${Deno.env.get("NVIDIA_BASE_URL") ?? "https://integrate.api.nvidia.com/v1"}/chat/completions`, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      signal: AbortSignal.timeout(20_000),
      body: JSON.stringify({
        model: Deno.env.get("NVIDIA_VISION_MODEL") ?? "meta/llama-3.2-90b-vision-instruct",
        max_tokens: 200,
        temperature: 0,
        messages: [{
          role: "user",
          content: [
            { type: "text", text: "You screen photos for a dating app for verified adults. Score 0..1 how likely this image shows: nudity, sexual content, a minor (under 18), violence/gore, hate symbols, weapons, drugs. Reply with JSON only: {\"nudity\":0,\"sexual\":0,\"minor\":0,\"violence\":0,\"hate\":0,\"weapons\":0,\"drugs\":0}" },
            { type: "image_url", image_url: { url: signed.signedUrl } },
          ],
        }],
      }),
    });
    if (!res.ok) return "borderline";
    const text: string = (await res.json())?.choices?.[0]?.message?.content ?? "";
    const m = text.match(/\{[\s\S]*\}/);
    return decide(m ? JSON.parse(m[0]) : null);
  } catch {
    return "borderline";
  }
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}
