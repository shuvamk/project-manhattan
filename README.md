# Project Manhattan

> **Public repo, but NOT community-ready.** Visibility is public only to unlock branch
> protection / required checks. Do not announce, promote, or describe this as a finished
> "clone-and-run" project until the owner (CEO) explicitly says so. **No real secret of
> any kind belongs in this repo — see D6.**

An autonomous multi-agent build swarm. A human CEO says **`start`**; a fleet of
role-playing agents (PM, Architect, Developer, Tester, Security Advisor, Researcher,
UX / Graphic / Motion Designers, Release) debate and lock an idea, plan it into a
dependency graph of tasks, and build it — across multiple laptops, with no human in
the critical path. Any agent can die anytime; any agent can spawn anywhere; the work
keeps going.

**The product being built is intentionally undefined.** This repo is the *harness*,
not the product.

## Status: CORE SCAFFOLDED — not yet run

The harness skeleton exists. Not yet wired to a live Supabase/Vercel and not yet run.

```
START.md                  ← the one command: what `start` does (idempotent)
CLAUDE.md                 ← per-session boot contract (auto-read)
spine/
  schema.sql              ← 5 tables + claim_task / renew_lease / heartbeat / reap_stale RPCs
  README.md
protocol/
  worker-loop.md  idempotency.md  blockers.md  tdd-gate.md
governance/
  decision-protocol.md    ← genesis · debate (≤3 rounds) · ratify · amend
  roles/                  ← CEO, Architect, Integrator (singletons) + pooled roles + template
.github/workflows/ci.yml  ← the 100% + e2e merge gate
scripts/
  bootstrap.sh            ← load env, verify keys, apply spine
  swarm-up.sh             ← tmux launcher (one pane per role, types `start`)
.env.example  docs/ENV.md ← keys + the no-secrets-in-repo rule (D6)
docs/DECISIONS.md         ← every locked decision and why
```

**Next:** provision Supabase + Vercel + a GitHub PAT, fill `.env`, apply the spine, add the
CI jobs as required status checks, and do the genesis dry-run before full fan-out.

## Locked decisions

| Area | Decision |
|---|---|
| Coordination truth | **Supabase Postgres** (atomic claims via `claim_task()` RPC + `FOR UPDATE SKIP LOCKED`); GitHub Issues / dashboard = human window only |
| Execution model | **Long-lived role-worker sessions** (tmux tabs × laptops), each may fan out sub-agents |
| Secrets | **Never in the repo** (D6, public). Fleet pulls real `.env` from a private channel at bootstrap; cloners bring their own keys |
| Merge gate | **Literal 100% coverage + e2e green** before any merge; walking-skeleton ships first |

Open questions are tracked in [`docs/OPEN-QUESTIONS.md`](docs/OPEN-QUESTIONS.md).
