# Spine — the coordination substrate

Postgres (your Supabase) is the **source of truth** for the swarm: claims, leases, the
dependency graph, and the idempotency ledger. GitHub Issues and the dashboard are human
windows only (D1, F1).

## Apply it

```bash
psql "$SUPABASE_DB_URL" -f spine/schema.sql      # idempotent; bootstrap.sh does this for you
```

## Tables (the hand-built minimum — D5)

| Table | Purpose |
|---|---|
| `agents` | fleet registry + heartbeat (drives the reaper) |
| `tasks` | the work queue; claimed atomically via `claim_task()` |
| `task_deps` | dependency edges (DAG) → eligibility |
| `runs` | idempotency ledger → safe re-execution of side effects |
| `control` | singleton kill switch + global knobs (`status`, `phase`, spend governor) |

Everything else (`proposals`, `votes`, `charter`, `spend_ledger`, `pr_registry`) is the
swarm's own first work, added through the normal PR + TDD gate.

## RPCs (call over HTTPS via PostgREST — no held PG connections)

| Function | Use |
|---|---|
| `claim_task(agent, role, lease_s)` | atomic, lease-protected pull of the next eligible task |
| `renew_lease(agent, task, lease_s)` | extend your lease mid-work; `false` = you lost it |
| `heartbeat(agent)` | prove you're alive |
| `reap_stale(dead_after_s)` | release expired leases, mark dead agents; returns # released |

## Why RPC-over-HTTPS, not raw connections

Hundreds of agents holding Postgres connections would exhaust the pool — especially with a
`FOR UPDATE` transaction held open while an agent works. The `claim_task()` RPC does the
`SELECT … FOR UPDATE SKIP LOCKED` *inside* the function and commits in milliseconds; the
agent then works **outside** any transaction, protected only by the lease. No held
connections, no exhaustion (D1 correction).

## The kill switch

`update control set status='paused' where id=1;` — every worker checks this each loop and
quiesces. With A2 ("run forever"), this plus the $50 provider caps are the **only** safety
net. Treat them as load-bearing.
