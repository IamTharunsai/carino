// export-data: "Download my data" (GDPR Art. 15/20, CCPA right to know).
// Returns everything the signed-in member has given us, as one JSON file.
// Never includes other people's private rows (their notes, reflections,
// verification) and never raw ID images (we don't hold them).
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// table -> column that holds the member's id. ponytail: a flat list; add a
// row when a new member-owned table lands (the migration test lists them).
const OWNED: Record<string, string> = {
  profiles: "id",
  member_profiles: "user_id",
  verification_records: "user_id", // results + references only
  likes: "from_user",
  passes: "from_user",
  messages: "sender",
  plans: "proposed_by",
  plan_feedback: "user_id",
  reports: "reporter",
  appeals: "user_id",
  blocks: "blocker",
  notifications: "user_id",
  trusted_contacts: "user_id",
  moments: "author",
  conversation_prefs: "user_id",
  private_notes: "user_id",
  private_reflections: "user_id",
  experience_bookings: "user_id",
  presence_sessions: "user_id",
};

Deno.serve(async (req: Request) => {
  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
  if (!jwt) return new Response("unauthorized", { status: 401 });
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: u } = await admin.auth.getUser(jwt);
  const uid = u?.user?.id;
  if (!uid) return new Response("unauthorized", { status: 401 });

  const out: Record<string, any> = { exported_at: new Date().toISOString(), user_id: uid };
  for (const [table, col] of Object.entries(OWNED)) {
    const { data, error } = await admin.from(table).select("*").eq(col, uid).limit(10000);
    out[table] = error ? { error: "unavailable" } : data;
  }
  return new Response(JSON.stringify(out, null, 2), {
    headers: {
      "content-type": "application/json",
      "content-disposition": `attachment; filename="carino-data-${uid}.json"`,
    },
  });
});
