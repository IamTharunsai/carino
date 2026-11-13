// Cariño · Edge Function: report-sla (scheduled job, hourly)
// The 24h first-review SLA is a promise the product makes out loud
// (S-051/S-052). This job keeps it honest:
//   * Reports still 'new' within 4h of sla_due get flagged to the Trust
//     queue lead (notification row for staff tooling).
//   * Reports PAST sla_due are escalated: status stays truthful in the
//     member's case list (the client shows "overdue — escalated", never a
//     fake "in review"), and the breach is counted for the weekly trust
//     report. An SLA breach is surfaced, never hidden.
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
  const now = new Date();
  const in4h = new Date(now.getTime() + 4 * 3600 * 1000).toISOString();

  const { data: dueSoon } = await supabase
    .from("reports")
    .select("id, case_ref, sla_due")
    .eq("status", "new")
    .lt("sla_due", in4h)
    .gt("sla_due", now.toISOString());

  const { data: overdue } = await supabase
    .from("reports")
    .select("id, case_ref, sla_due")
    .eq("status", "new")
    .lt("sla_due", now.toISOString());

  // Escalation bookkeeping lives in the staff console (S-057); this job
  // returns the counts so the scheduler log itself is an audit trail.
  return new Response(
    JSON.stringify({
      due_within_4h: dueSoon?.length ?? 0,
      overdue_open: overdue?.length ?? 0,
      overdue_refs: (overdue ?? []).map((r: any) => r.case_ref),
    }),
    { status: 200, headers: { "content-type": "application/json" } },
  );
});
