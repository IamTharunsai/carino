// Cariño · Edge Function: remote-config
// GET the active remote-config document for the app.
// The document can tune copy, drop composition, Spark windows, the match
// expiry hours, the city-batch flag, and feature flags. It can NEVER:
// verify a member, change a safety surface, or carry member data — the
// client whitelists exactly the keys in lib/services/remote_config.dart
// and enforces its hard limits no matter what this returns.
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (_req: Request) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data, error } = await supabase
    .from("remote_config_docs")
    .select("version, doc")
    .eq("active", true)
    .order("version", { ascending: false })
    .limit(1)
    .single();
  if (error || !data) {
    // Client falls back to compiled defaults — a config outage must
    // never break the app or invent values.
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  }
  return new Response(JSON.stringify(data.doc), {
    status: 200,
    headers: {
      "content-type": "application/json",
      "etag": `"cfg-${data.version}"`,
      "cache-control": "private, max-age=300",
    },
  });
});
