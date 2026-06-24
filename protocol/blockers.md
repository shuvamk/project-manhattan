# Blockers & Dependencies

The swarm must never deadlock and no agent ever waits idle on another. Two mechanisms:

## 1. Declared dependencies (the normal case)

When the Architect decomposes work, it records `task_deps` edges. `claim_task()` only ever
hands you a task whose dependencies are **all `done`**. So you never "wait" for a
dependency — you simply won't be given a task until it's ready, and you'll be given some
*other* eligible task in the meantime. Idle ≠ blocked.

## 2. Discovered blockers (mid-work)

If you start a task and discover it can't proceed (missing API, an upstream bug, an
ambiguous spec), do **all** of this and then **move on** — never sit and wait:

1. Set your task `status = 'blocked'`.
2. File the blocker as a new task in the right role's queue (idempotent key so you don't
   file it twice), with a clear spec + Definition-of-Done.
3. Add a `task_deps` edge: your task `depends_on` the new blocker task.
4. Release your claim (let the reaper or your own update return it to `open` — it will
   become eligible again once the blocker is `done`).
5. Go back to the loop and claim the next eligible task.

## Human-only blockers (A3)

If the blocker is a genuine human-only decision (spend real money, buy a domain,
legal/ethical/irreversible call):

- Take the **safe, reversible, test-mode default** and continue, **or** if there is no safe
  default, file it to the **escalation** path (a GitHub Issue labeled `escalation`, F1) and
  pick up other work.
- Never block the whole task waiting for the human. The human reviews escalations
  asynchronously.

## Anti-deadlock invariant

A dependency cycle is a bug. The Architect must keep `task_deps` a DAG. If an agent detects
a cycle (its task transitively depends on itself), it files an `escalation` and breaks the
cycle by abandoning the least-valuable task in it.
