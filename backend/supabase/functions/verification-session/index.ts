// Cariño · Edge Function: verification-session
// Opens a verification session with the IDV vendor and returns its
// reference. The vendor (Persona/Veriff class) is OPEN DECISION D-01 —
// until the contract exists this function creates the pending record and
// returns a clearly-marked "vendor_pending" session so client states
// (S-005/S-006/S-007 pending) behave identically in development.
//
// Rules that hold regardless of vendor:
//   * The client never uploads ID images to OUR storage. The vendor SDK
//     captures; we receive result + reference by webhook only.
//   * verification_records is written ONLY here / by the webhook handler
//     (service role). A client cannot self-grant any layer result.
//   * The record starts at 'pending' — S-007's Passed state requires all
//     three layers 'passed' AND age21_result 'passed'.
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

  const vendor = Deno.env.get("IDV_VENDOR"); // 'persona' | 'veriff' (D-01)
  const providerRef = vendor
    ? `pending-${vendor}-${crypto.randomUUID()}`
    : `vendor-pending-${crypto.randomUUID()}`;

  await supabase.from("verification_records").upsert({
    user_id: user.id,
    provider: vendor ?? "pending-vendor",
    provider_ref: providerRef,
    age21_result: "pending",
    liveness_result: "pending",
    photo_match_result: "pending",
    badge_state: "none",
    updated_at: new Date().toISOString(),
  });

  // HOSTING PHASE: create the real vendor inquiry/session here and
  // return its SDK token. The response shape stays identical.
  return json({
    provider_ref: providerRef,
    vendor_configured: Boolean(vendor),
    status: "pending",
  });
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}
