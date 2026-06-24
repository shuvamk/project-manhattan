# Decision Protocol — Genesis, Debate, Ratify, Amend

How an undefined idea becomes a locked charter and a task graph — with bounded debate and
exactly one optional human checkpoint.

## Phase: GENESIS (control.phase = 'genesis')

Runs once per swarm. Coordinated by the **CEO** singleton (DB-locked, so two machines can
never both run genesis).

### 1. Pitch (any role, B1)
Each role may submit **one** proposal as a row in the `proposals` table (the CEO creates
this table as genesis's first act — see "bootstrapping the genesis tables" below). A
proposal is: one-paragraph idea + why it has value + a rough first milestone.

### 2. Score (B2)
Every proposal is scored on three axes, each 1–5:
- **Feasibility** — can the swarm actually build it test-driven, with the available stack?
- **Value** — is it worth building?
- **Scope** — is a first version shippable within budget?

Scores are cast as `votes` rows (one vote per agent per proposal). The CEO tallies.

### 3. Debate (bounded — hard cap 3 rounds)
After scoring, the top proposals get **at most 3 rounds** of structured critique
(strengths / risks / "what would change my vote"). Each round, agents may revise scores.
**After round 3 the CEO forces a decision** — highest total wins; CEO breaks ties. No
infinite argument: round count is tracked in `control.notes`.

### 4. Ratify (A1)
The CEO posts the winning charter to a GitHub Issue labeled `charter` and opens a
**ratify window** (default 30 min, configurable). The human CEO may veto/amend in that
window. **If no response by the timeout, it auto-proceeds.** Hands-off-capable.

### 5. Lock & plan
On ratify (or timeout): write the charter to a `charter` row, set `control.phase =
'planning'`. The **Architect** decomposes the charter into phases → tasks → `task_deps`
edges, assigning each task a role-queue and a Definition-of-Done.

> **The Architect's FIRST emitted task is always the walking skeleton** (empty Next.js app
> + trivial unit test + Playwright smoke + CI gate green). See `protocol/tdd-gate.md`.
> Feature tasks must depend (directly or transitively) on the skeleton task.

### 6. Build
Architect sets `control.phase = 'building'`. Pooled workers enter the worker loop. Genesis
is over.

## Re-opening the charter mid-build (B3)

Any agent that discovers the idea is wrong files a **charter-amendment RFC** (a GitHub
Issue labeled `charter-amendment` + a proposal row). It goes through the **same ratify
gate** (step 4): CEO veto window with auto-proceed timeout. On acceptance the Architect
re-plans the affected phases. This lets the swarm self-correct without thrashing on every
disagreement.

## Bootstrapping the genesis tables (D5)

The hand-built spine is only the 5 core tables. `proposals`, `votes`, and `charter` are the
**swarm's own first work**: the CEO, as genesis act zero, opens a PR adding those tables
(migration through the normal TDD gate). This proves the spine + CI + merge loop end-to-end
*before* any product work — i.e. it doubles as the **genesis dry-run** (D7 derived guard).
Only after that PR merges does pitching begin.
