// Cariño · Edge Function: delete-account (S-055, App Store 5.1.1(v))
// Deletes the CALLER's auth user; every member table cascades from
// profiles -> auth.users. Safety-vault rows tied to open reports survive
// (reporter FK has no cascade) — that retention is disclosed in S-055 copy.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
  if (!jwt) return new Response("unauthorized", { status: 401 });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: { user }, error } = await admin.auth.getUser(jwt);
  if (error || !user) return new Response("unauthorized", { status: 401 });

  const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
  if (delErr) return Response.json({ error: delErr.message }, { status: 500 });
  return Response.json({ deleted: true });
});
