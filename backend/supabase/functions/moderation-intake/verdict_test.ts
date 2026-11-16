import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { decide } from "./verdict.ts";

const ok = { nudity: 0, sexual: 0, minor: 0, violence: 0, hate: 0, weapons: 0, drugs: 0 };

Deno.test("clean photo is approved", () => assertEquals(decide(ok), "clear"));
Deno.test("model failure goes to a human", () => assertEquals(decide(null), "borderline"));
Deno.test("missing scores count as unsure", () => assertEquals(decide({ nudity: 0 }), "borderline"));
Deno.test("suggestive goes to a human", () => assertEquals(decide({ ...ok, sexual: 0.5 }), "borderline"));
Deno.test("possible minor + sexual content is illegal", () =>
  assertEquals(decide({ ...ok, minor: 0.4, nudity: 0.3 }), "illegal"));
