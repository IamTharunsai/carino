// stripe-checkout: creates a Stripe Checkout session for
//   {kind: "booking", booking_id}  — a Decompress booking (Stripe Connect:
//       paid to the venue's connected account, Cariño keeps the commission
//       as application_fee_amount; the member pays the listed price only)
//   {kind: "plus_web"}             — Cariño Plus bought on the WEBSITE.
// In-app Plus is NOT sold here: iOS/Android require store billing.
// Amounts always come from the database, never from the client.
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SITE = Deno.env.get("SITE_URL") ?? "https://carino-liard.vercel.app";

Deno.serve(async (req: Request) => {
  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
  if (!jwt) return json({ error: "unauthorized" }, 401);
  const key = Deno.env.get("STRIPE_SECRET_KEY");
  if (!key) return json({ error: "payments_not_configured" }, 503);

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: u } = await db.auth.getUser(jwt);
  const uid = u?.user?.id;
  if (!uid) return json({ error: "unauthorized" }, 401);

  const body = await req.json().catch(() => ({}));
  const form = new URLSearchParams();
  form.set("client_reference_id", uid);
  form.set("success_url", `${SITE}/#/paid?session={CHECKOUT_SESSION_ID}`);
  form.set("cancel_url", `${SITE}/#/payment-cancelled`);
  form.set("metadata[user_id]", uid);

  if (body.kind === "booking") {
    const { data: b } = await db
      .from("experience_bookings")
      .select("id,user_id,status,member_pays_cents,commission_cents,party_size,experiences(title,stripe_account_id)")
      .eq("id", String(body.booking_id ?? ""))
      .single();
    if (!b || b.user_id !== uid) return json({ error: "not_your_booking" }, 404);
    if (b.status !== "reserved") return json({ error: "not_payable", status: b.status }, 409);
    if (b.member_pays_cents <= 0) return json({ error: "free_booking" }, 409);
    const venue = (b as any).experiences?.stripe_account_id;
    if (!venue) return json({ error: "venue_not_connected" }, 409); // pay at the venue instead
    form.set("mode", "payment");
    form.set("line_items[0][quantity]", "1");
    form.set("line_items[0][price_data][currency]", "usd");
    form.set("line_items[0][price_data][unit_amount]", String(b.member_pays_cents));
    form.set("line_items[0][price_data][product_data][name]", `${(b as any).experiences?.title ?? "Experience"} · ${b.party_size} people`);
    form.set("payment_intent_data[application_fee_amount]", String(b.commission_cents));
    form.set("payment_intent_data[transfer_data][destination]", venue);
    form.set("metadata[kind]", "booking");
    form.set("metadata[booking_id]", b.id);
  } else if (body.kind === "plus_web") {
    const price = Deno.env.get(body.plan === "annual" ? "STRIPE_PRICE_PLUS_ANNUAL" : "STRIPE_PRICE_PLUS_MONTHLY");
    if (!price) return json({ error: "plus_price_not_configured" }, 503);
    form.set("mode", "subscription");
    form.set("line_items[0][price]", price);
    form.set("line_items[0][quantity]", "1");
    form.set("metadata[kind]", "plus_web");
    form.set("subscription_data[metadata][user_id]", uid);
  } else {
    return json({ error: "unknown kind" }, 400);
  }

  const res = await fetch("https://api.stripe.com/v1/checkout/sessions", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/x-www-form-urlencoded" },
    body: form,
  });
  const session = await res.json();
  if (!res.ok) return json({ error: "stripe_error", detail: session?.error?.message }, 502);
  if (body.kind === "booking") {
    await db.from("experience_bookings").update({ stripe_session_id: session.id }).eq("id", body.booking_id);
  }
  return json({ url: session.url, id: session.id });
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), { status, headers: { "content-type": "application/json" } });
}
