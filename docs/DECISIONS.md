# Decisions Log

Append-only record of locked architectural decisions. Newest first.

## D1 — Coordination truth: Postgres spine, not GitHub Issues
Supabase Postgres is the source of truth for claims, leases, dependency graph, and
idempotency. Agents claim work via a `claim_task()` **RPC over HTTPS** (PostgREST),
which runs `... FOR UPDATE SKIP LOCKED LIMIT 1` *inside* the function and returns one
row — the claim transaction opens and commits in milliseconds; agents work outside any
transaction, protected only by a lease. This avoids both the no-atomic-claim and the
rate-limit failure modes of GitHub Issues, and avoids Postgres connection exhaustion.
GitHub Issues / a live dashboard are the **human window only**, not the coordination
truth.

## D2 — Execution model: long-lived role-worker sessions
Each terminal tab is one persistent role worker running `claim → work → PR → heartbeat
→ repeat`. Many tabs per laptop, many laptops. Each worker may fan out sub-agents for
parallel slices of its own task. "Hundreds of agents" = effective concurrency, not
hundreds of literal tabs.

## D3 — Secrets: encrypted `.env`
Keys are committed only in encrypted form (age or git-crypt). One passphrase is shared
out-of-band. Preserves clone-and-go while limiting blast radius. Every provider key
gets a hard spend cap.

## D4 — Merge gate: literal 100% coverage + e2e green
No PR merges unless coverage is 100% and all e2e pass. Consequence: genesis's **first**
emitted task is always a green "walking skeleton" (empty Next.js app + trivial unit
test + Playwright smoke + the CI gate itself), or PR #1 could never merge. A dedicated
Tester role exists to unblock PRs that are red only on coverage/e2e.

## D5 — Minimum viable spine, swarm extends it
Hand-build only 5 tables — `agents`, `tasks`, `task_deps`, `runs`, `control`. The swarm
builds the rest (spend ledger, PR registry, decisions/votes) as its own first tasks.
