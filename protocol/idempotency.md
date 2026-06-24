# Idempotency

Any agent can die mid-task and a successor will re-run that task from scratch. Therefore
**every external side effect must be safe to repeat.** This is what makes "die anytime,
spawn anywhere" actually hold.

## The rule

Before any side effect that isn't naturally idempotent (opening a PR, deploying, running a
migration, generating a paid asset), do:

```
key = "task:<task_id>:<kind>"          # deterministic — same task, same kind, same key
existing = select * from runs where idempotency_key = key
if existing: reuse existing.result      # already done — no-op, return the recorded result
else:
    result = perform_side_effect()
    insert into runs (idempotency_key, task_id, agent_id, kind, result) values (...)
```

## Deterministic naming

- **Branches:** `task/<task_id>` — a re-run reuses the same branch, not a new one.
- **Task creation:** every task has a unique `idempotency_key`; creating "the same" task
  twice is a no-op via the unique constraint. Derive it from stable inputs
  (e.g. `phase:<p>:<slug>`), never from a timestamp or random.
- **PRs / deploys / assets:** keyed in `runs` as above before the call.

## Why not just "check if it exists on the remote?"

Remote checks race (two agents check, both see nothing, both create). The `runs` ledger is
in the same Postgres as the claim, so "did this already happen" is answered transactionally,
not by a best-effort remote lookup.

## Forbidden

- No `Math.random()` / timestamps in any idempotency key or branch name.
- No side effect before its `runs` check.
- No "I'll just clean up the duplicate later" — there is no later; you may be dead.
