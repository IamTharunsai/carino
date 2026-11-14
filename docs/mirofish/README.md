# MiroFish audience simulation for Cariño

[MiroFish](https://github.com/666ghj/MiroFish) builds a crowd of AI personas
from a seed document and simulates how they react. Use it to pressure-test
positioning, pricing and launch messaging before spending on ads.

**Keep it separate from the app.** MiroFish is AGPL-3.0: never copy its code
into this repository or ship it inside the app. Run it as a local research
tool only. Results are simulated opinions, not real users — treat them as
hypotheses to test with real people (the Columbus pilot).

## What it needs (you must provide)
- `LLM_API_KEY`, `LLM_BASE_URL`, `LLM_MODEL_NAME` — any OpenAI-compatible
  provider (e.g. an OpenAI or Anthropic-compatible gateway key you own).
- `ZEP_API_KEY` — Zep Cloud (free tier is enough to start).
- Python 3.11–3.12, Node 18+, `uv`. Simulations are expensive: start with
  **fewer than 40 rounds**.

## Run it
```powershell
# outside this repo
cd C:\Users\mrtha\Desktop
git clone https://github.com/666ghj/MiroFish
cd MiroFish
copy .env.example .env      # then fill the four keys above in .env
npm run setup:all
npm run dev                 # UI at http://localhost:3000 (keep it local; no auth)
```
Upload `SEED.md` (this folder) as the seed material, paste one question from
`QUESTIONS.md` as the prediction goal, run ≤ 40 rounds, then export the
ReportAgent's report into `docs/mirofish/results/` and update
`docs/EXPERIENCE-STRATEGY.md` with anything that holds up.

Privacy: the seed contains product strategy only — no member data. Never
upload real user data, chats or photos to MiroFish or its LLM provider.
