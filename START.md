# START — the one command

A human opens Claude Code in this repo and types **`start`**. That's it. This file is
the entrypoint every session runs. It is **idempotent**: running it on a fresh swarm
begins genesis; running it on a live swarm joins the work. No human is in the critical
path after this.

## What `start` does (in order)

1. **Bootstrap.** Run `scripts/bootstrap.sh` — loads env, verifies required keys
   (fails loud and early if a key is missing), applies `spine/schema.sql` if the spine
   isn't there yet. See [`docs/ENV.md`](docs/ENV.md).
2. **Discover capabilities.** Probe what this machine actually has (MCP servers, CLIs,
   GPUs). Wire in *nothing* assumed — degrade gracefully (D1). Record findings in `meta`.
3. **Pick a role.** From `$MANHATTAN_ROLE` if set, else claim the highest-need open role
   (singletons — CEO, Integrator, Architect — are DB-locked; see
   [`governance/roles/`](governance/roles/)).
4. **Register.** Insert into `agents` with id `"<machine>:<role>:<uuid>"`; start a
   heartbeat (every 30s call `heartbeat()`).
5. **Read the phase** from `control.phase`:
   - `genesis` → participate in [the genesis protocol](governance/decision-protocol.md):
     pitch/debate/score an idea, converge in ≤3 rounds, CEO ratifies (auto-proceed
     timeout), charter locks, Architect emits the **walking-skeleton task first**.
   - `planning` / `building` → enter the **worker loop**
     ([`protocol/worker-loop.md`](protocol/worker-loop.md)).
6. **Loop forever** until `control.status` is `paused`/`stopped`. Claim → work → PR →
   verify CI green → hand to Integrator → repeat. No eligible task? Do swarm-useful work
   (C2). Hit a human-only decision? Take the safe reversible default and flag it (A3).

## Invariants every session must hold

- **Atomic claims only** — never edit a task's owner by hand; only `claim_task()`.
- **Lease discipline** — renew your lease while working; if you can't, assume you lost it.
- **Idempotency** — every external side effect is checked against `runs` first.
- **Never push to `main`** — work on `task/<id>` branches, land via PR + green CI only.
- **Respect the kill switch** — check `control.status` every loop; `paused` → quiesce.
- **You may die anytime** — leave no half-state that isn't reap-safe.
