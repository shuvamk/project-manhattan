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

## Status: SPEC — not yet scaffolded

Nothing here is built yet. The coordination spine, worker loop, genesis protocol, and
CI gate are still being specified. See [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Locked decisions

| Area | Decision |
|---|---|
| Coordination truth | **Supabase Postgres** (atomic claims via `claim_task()` RPC + `FOR UPDATE SKIP LOCKED`); GitHub Issues / dashboard = human window only |
| Execution model | **Long-lived role-worker sessions** (tmux tabs × laptops), each may fan out sub-agents |
| Secrets | **Never in the repo** (D6, public). Fleet pulls real `.env` from a private channel at bootstrap; cloners bring their own keys |
| Merge gate | **Literal 100% coverage + e2e green** before any merge; walking-skeleton ships first |

Open questions are tracked in [`docs/OPEN-QUESTIONS.md`](docs/OPEN-QUESTIONS.md).
