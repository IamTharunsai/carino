// Cariño · Edge Function: moderation-intake
// Receives a media id after upload, runs the pre-screen (AI-05 via the
// screening provider), and sets media.moderation_state. Media stays
// 'pending' (undistributed) until this function approves it; explicit or
// borderline content goes 'held' for a HUMAN — the model never has the
// final word on distribution OR on enforcement.
// Invoked by: database webhook on public.media insert (service role).
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { record } = await req.json().catch(() => ({ record: null }));
  const mediaId = record?.id as string | undefined;
  if (!mediaId) return json({ error: "no media id" }, 400);

  // HOSTING PHASE: call the screening provider (Hive-class) with a signed
  // URL for the object. Verdict mapping is conservative by design:
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

async function screenMedia(
  _supabase: any,
  _record: any,
): Promise<"clear" | "borderline" | "illegal"> {
  // Not wired until the screening provider is contracted; until then
  // media remains 'pending' in the database (this stub returns borderline
  // = held for humans, the safe default — nothing auto-approves).
  return "borderline";
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}
