import { validSignature } from "./signature.ts";

async function sign(payload: string, secret: string, t: number) {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${t}.${payload}`));
  return `t=${t},v1=${[...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("")}`;
}

Deno.test("accepts a correctly signed, fresh event", async () => {
  const now = Math.floor(Date.now() / 1000);
  if (!(await validSignature('{"id":"evt_1"}', await sign('{"id":"evt_1"}', "whsec_x", now), "whsec_x"))) throw new Error("rejected valid");
});
Deno.test("rejects a forged body, wrong secret and a replayed timestamp", async () => {
  const now = Math.floor(Date.now() / 1000);
  const h = await sign('{"id":"evt_1"}', "whsec_x", now);
  if (await validSignature('{"id":"evt_2"}', h, "whsec_x")) throw new Error("forged body accepted");
  if (await validSignature('{"id":"evt_1"}', h, "whsec_other")) throw new Error("wrong secret accepted");
  const old = await sign('{"id":"evt_1"}', "whsec_x", now - 3600);
  if (await validSignature('{"id":"evt_1"}', old, "whsec_x")) throw new Error("replay accepted");
  if (await validSignature('{"id":"evt_1"}', "garbage", "whsec_x")) throw new Error("garbage accepted");
});
