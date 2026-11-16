// Turns the vision model's scores (0..1) into a decision. Conservative:
// anything unclear, or a model failure, goes to a human — never auto-approved.
export type Scores = {
  nudity?: number; sexual?: number; minor?: number; violence?: number;
  hate?: number; weapons?: number; drugs?: number; not_a_person_photo?: number;
};
export type Verdict = "clear" | "borderline" | "illegal";

export function decide(s: Scores | null): Verdict {
  if (!s) return "borderline";
  const n = (k: keyof Scores) => (typeof s[k] === "number" ? (s[k] as number) : 1); // missing = unsure
  const seen = (k: keyof Scores) => (typeof s[k] === "number" ? (s[k] as number) : 0); // "illegal" needs real signals
  if (seen("minor") >= 0.3 && (seen("nudity") >= 0.2 || seen("sexual") >= 0.2)) return "illegal";
  const worst = Math.max(n("nudity"), n("sexual"), n("violence"), n("hate"), n("weapons"), n("drugs"));
  if (worst >= 0.35 || n("minor") >= 0.5) return "borderline";
  return "clear";
}
