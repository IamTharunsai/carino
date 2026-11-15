// stripe-webhook: the ONLY place a payment changes state. Verifies Stripe's
// signature, applies each event once (stripe_events), and:
//   checkout.session.completed (booking)  -> booking status 'paid'
//   checkout.session.completed (plus_web) -> entitlements active, source 'stripe_web'
//   customer.subscription.deleted         -> entitlements expired
// Deploy with --no-verify-jwt (Stripe can't send a Supabase JWT).
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { validSignature } from "./signature.ts";

Deno.serve(async (req: Request) => {
  const secret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  if (!secret) return new Response("not configured", { status: 503 });
  const payload = await req.text();
  if (!(await validSignature(payload, req.headers.get("stripe-signature") ?? "", secret))) {
    return new Response("bad signature", { status: 400 });
  }
  const event = JSON.parse(payload);
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const { error: dup } = await db.from("stripe_events").insert({ id: event.id, type: event.type });
  if (dup) return new Response("already processed", { status: 200 });

  const obj: any = event.data?.object ?? {};
  if (event.type === "checkout.session.completed" && obj.payment_status === "paid") {
    if (obj.metadata?.kind === "booking") {
      await db.from("experience_bookings").update({ status: "paid" })
        .eq("id", obj.metadata.booking_id).eq("stripe_session_id", obj.id);
    } else if (obj.metadata?.kind === "plus_web") {
      await db.from("entitlements").upsert({
        user_id: obj.metadata.user_id,
        product_id: "plus_web_monthly",
        store_transaction_ref: obj.subscription,
        state: "active",
        source: "stripe_web",
        updated_at: new Date().toISOString(),
      });
    }
  } else if (event.type === "customer.subscription.deleted") {
    await db.from("entitlements").update({ state: "expired", updated_at: new Date().toISOString() })
      .eq("store_transaction_ref", obj.id).eq("source", "stripe_web");
  }
  return new Response("ok", { status: 200 });
});
