# Environment & Secrets

Full template: [`.env.example`](../.env.example). Setup model is D6 (public repo).

## Hard rules
- **No real secret in this repo, ever — not even encrypted.** Public git history is
  permanent and globally indexed (D6).
- **Your fleet** gets the real `.env` via a private channel (Doppler / 1Password / a
  private sibling repo / out-of-band). `bootstrap.sh` loads it.
- **Public cloners** bring their own keys and run on their own billing.
- **Every paid provider gets a hard ~$50 cap** in its billing dashboard (C1). With A2
  (run forever) these caps + the `control` kill switch are the only safety net.

## What each key is for

| Key | Required? | Why |
|---|---|---|
| `SUPABASE_*` (4) | ✅ | the coordination spine — the swarm cannot run without it |
| `GITHUB_TOKEN` | ✅ | PRs, the CI gate, escalation issues |
| `VERCEL_*` (3) | ✅ to ship | deploy the product the swarm builds |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` | optional | AI if an agent chooses; not forced |
| `R2_*` (5) | optional | blob storage; provisioned so it's never a blocker |
| `RUNPOD_API_KEY` | optional | heavy/long compute escape hatch (most webapps won't need it) |
| `RESEND_API_KEY` | optional | transactional email — the #1 silent blocker once auth appears |
| `UPSTASH_REDIS_*` | optional | serverless redis: rate-limit / ephemeral locks |
| `SENTRY_DSN` | optional | so a dying agent's errors are visible |
| `STRIPE_SECRET_KEY` | optional | **test mode only** if the product touches payments |
| `CLOUDFLARE_API_TOKEN` | optional | DNS / R2 mgmt / Turnstile |
| `AUTH_SECRET` | ✅ if auth | random; `openssl rand -base64 32` |

## Runpod verdict
A generic Next.js webapp likely won't need it day one — R2 beats a Runpod volume for blobs,
and Vercel + Supabase cover most compute. Keep the key as an **optional escape hatch** for
jobs that exceed Vercel's execution limits (render/ML/batch). Don't build the spine around it.
