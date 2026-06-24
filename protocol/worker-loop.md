# Worker Loop

The loop every pooled worker runs forever, until `control.status` ≠ `running`.

```
loop:
  1. control = get_control()
     if control.status != 'running': quiesce (finish nothing new, sleep, recheck). 
  2. heartbeat(agent_id)                      # prove you're alive
  3. task = claim_task(agent_id, role, 900)   # atomic; 0 or 1 row
  4. if task is null:
       do_swarm_useful_work()                 # C2 — see below
       backoff_sleep()                        # 5s → 15s → 60s cap
       continue
  5. work the task on branch task/<id>:
       - renew_lease(agent_id, task.id) periodically (well before 900s)
       - follow your role playbook + the task's Definition-of-Done
       - TDD always (protocol/tdd-gate.md): write failing test → code → green
  6. open a PR (idempotent — check runs for "task:<id>:pr_open" first)
  7. set task.status = 'in_review'; hand to Integrator queue
  8. if you hit a blocker → protocol/blockers.md (file it, move on, never wait)
  9. if you hit a human-only decision → safe reversible default + flag (A3)
  10. goto loop
```

## Claiming (the atomic rule)

You claim work **only** through `claim_task()`. Never set `claimed_by` by hand. The RPC
does `SELECT … FOR UPDATE SKIP LOCKED LIMIT 1` inside Postgres, so two agents physically
cannot grab the same row. It returns only tasks whose dependencies are all `done` and
whose role matches yours.

## Lease discipline

Your claim is a **lease** (`claimed_until`), not a lock. While working, call
`renew_lease()` periodically. If a renew returns `false`, you no longer hold the task —
**stop immediately** (a reaper gave it to someone else because you looked dead). Leaving
work reap-safe means: never push to `main`, keep changes on your branch, and make every
external side effect idempotent so a successor can re-run your task cleanly.

## do_swarm_useful_work() — never idle-spin (C2)

When no task is eligible, instead of sleeping idle, do bounded useful work — but check the
spend governor first and the pause flag every iteration:

1. Review an open PR that needs review.
2. Write a missing test toward the 100% gate.
3. Refine a `.context/` knowledge doc.
4. Reap stale leases (`reap_stale()`).

If the spend governor says we're over the $/hr limit, **sleep instead**. Useful-work is a
privilege the budget grants, not a right.

## Backoff

No work and nothing useful to do → exponential backoff sleep (5s, 15s, 60s cap), re-reading
`control` each wake so a `pause` takes effect fast.
