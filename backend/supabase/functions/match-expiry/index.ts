// CariÃ±o Â· Edge Function: match-expiry (scheduled job)
// Runs every ~15 minutes (pg_cron / Supabase scheduled functions):
//   1. MATCH EXPIRY (REA Â§5.1): matches whose expires_at passed with NO
//      conversation activity move to 'archived' â€” never deleted. Once a
//      conversation exists, expiry no longer applies (expires_at cleared
//      by the messaging layer on first message).
//   2. MOMENTS: rows past expires_at are deleted with their media objects
//      (24h means 24h).
//   3. VANISH: messages past expires_at are marked dissolved; the sealed
//      vault copies (where a report is open) are untouched by this job.
// All clocks are server-side; clients never run these timers.
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
  const now = new Date().toISOString();
  const results: Record<string, number> = {};

  // 1. Archive expired, still-unmessaged matches.
  const { data: expired } = await supabase
    .from("matches")
    .select("id")
    .eq("state", "active")
    .lt("expires_at", now);
  let archived = 0;
  for (const m of expired ?? []) {
    const { count } = await supabase
      .from("conversations")
      .select("id", { count: "exact", head: true })
      .eq("match_id", m.id);
    if (!count) {
      await supabase
        .from("matches")
        .update({ state: "archived" })
        .eq("id", m.id);
      archived++;
    } else {
      // Conversation exists: expiry stops applying, permanently.
      await supabase
        .from("matches")
        .update({ expires_at: null })
        .eq("id", m.id);
    }
  }
  results.matches_archived = archived;

  // 2. Delete expired moments.
  const { data: deadMoments } = await supabase
    .from("moments")
    .select("id")
    .lt("expires_at", now);
  if (deadMoments?.length) {
    await supabase
      .from("moments")
      .delete()
      .in("id", deadMoments.map((m: any) => m.id));
  }
  results.moments_deleted = deadMoments?.length ?? 0;

  // 3. Dissolve due vanish messages.
  const { data: due } = await supabase
    .from("messages")
    .update({ dissolved_at: now, body: null, media_id: null })
    .lt("expires_at", now)
    .is("dissolved_at", null)
    .select("id");
  results.messages_dissolved = due?.length ?? 0;

  return new Response(JSON.stringify(results), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
});
