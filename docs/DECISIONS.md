# Decisions Log

Append-only record of locked architectural decisions. Newest first.

## D7 — Genesis & operations (resolves OPEN-QUESTIONS A–F)

- **A1 Charter gate:** agents converge → CEO gets a ratify/veto window with an
  **auto-proceed timeout**. One cheap human checkpoint; hands-off-capable.
- **A2 Stop condition:** **run forever until the CEO pauses.** There is no automatic
  stop, so the **per-provider billing caps (C1) + the `control` kill switch are the only
  safety net** — they are load-bearing, not optional.
- **A3 Human-only decisions:** agent takes the **safe / reversible / test-mode default,
  logs an escalation, and keeps moving.** Never blocks on a human.
- **B1 Proposals:** **any role may submit one idea**; a structured score ranks them; CEO
  seeds and breaks ties.
- **B2 Rubric + cap:** judged on **feasibility (can the swarm TDD it) + value + shippable
  scope**; **hard cap of 3 debate rounds**, then forced decision.
- **B3 Amendments:** charter is **re-openable** via a formal amendment RFC that passes the
  same A1 ratify gate. Self-correcting without thrash.
- **C1 Spend caps:** **~$50 per provider** to start (OpenAI, Anthropic, Vercel, Supabase,
  Runpod, R2). Lift only after the spine is proven stable.
- **C2 Idle behavior:** an idle worker does **swarm-useful work** (review open PRs, write
  missing tests, refine docs) instead of sleeping — but **bounded by the pause flag and a
  global spend-rate governor** so run-forever + $50 caps don't burn out.
- **D1 Capability discovery:** the harness **wires in nothing from the owner's local
  machine.** Agents **discover available tools/MCPs at runtime** and degrade gracefully
  (use Figma/Higgsfield/Lottie if present, code-only if not). Core tenet: *assume nothing
  about the host; discover, don't hardcode.*
- **D2 Singletons:** **CEO** (runs genesis once), **Integrator** (owns merge queue),
  **Architect** (sole decomposer — owns task graph + module ownership). All else pooled.
- **E1 Test stack:** **Vitest (unit) + component tests + Playwright e2e against the live
  Vercel preview deploy per PR.** Live-preview e2e is what makes the 100% gate real.
- **E2 Coverage ignore-list:** **Architect owns it, Security Advisor approves, every change
  is a reviewed PR.** Prevents faking 100% by exempting hard code.
- **F1 Human window:** **Postgres-backed live dashboard (Supabase Realtime) is primary;**
  GitHub Issues are used only for **escalations + locked decisions**, not every task.
- **F2 Day-one scale:** launch at **2+ laptops × 8–10 tabs** (full roster). Gated by a
  **mandatory genesis dry-run**: prove claim→PR→CI→merge on the walking skeleton before
  full fan-out.

### Derived guards (consequences of the above)
- **Spend-rate governor:** a global $/hour throttle on top of provider caps, because A2 +
  C2 + F2 all push spend up against tight C1 caps.
- **Genesis dry-run gate:** no full fan-out until the loop is proven once, end to end.

## D6 — Repo is PUBLIC; secrets never enter it (amends D3)
The repo was made public (unlocks free branch protection + required status checks).
Consequence: **no real secret may ever be committed — not even encrypted.** Public Git
history is permanent and globally indexed; encrypted blobs are offline-brute-forceable.
This supersedes the "commit the encrypted env" part of D3.

New secrets model:
- **Repo:** `.env.example` with placeholder names only.
- **Owner's fleet:** real `.env` delivered via a private channel (Doppler / 1Password /
  private sibling repo / out-of-band); `bootstrap.sh` pulls/decrypts from there.
- **Public cloners:** bring their own keys and run on their own billing.

Every provider key still gets a hard spend cap. "Anyone can clone and `start`" now means
*with their own keys*, which is the correct open-source posture.

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
