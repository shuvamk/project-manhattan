# Roles

A **role is a queue, not an agent.** Many workers can hold the same pooled role; a few are
singletons (one instance swarm-wide, enforced by a DB lock). A task's `role` column routes
it to the right queue; `claim_task(agent, role, …)` only hands you tasks for your role.

## Roster

| Role | Kind | Owns |
|---|---|---|
| **CEO** | singleton | genesis, ratify gate, charter, the kill switch |
| **Architect** | singleton | task graph (DAG), module ownership, coverage ignore-list |
| **Integrator** | singleton | the merge queue — serializes landings to `main` |
| Product Manager | pooled | charter → milestones → task specs + Definitions-of-Done |
| Developer | pooled | feature code, test-first |
| Tester | pooled | unblocks the 100% + e2e gate; owns flaky-test hunting |
| Reviewer | pooled | PR review against role DoD + house rules |
| Security Advisor | pooled | threat model, secret hygiene, approves ignore-list changes |
| Researcher | pooled | external research, spikes, feasibility for proposals |
| UX Designer | pooled | flows, IA, component specs |
| Graphic Designer | pooled | visual assets (discovers tools at runtime — D1) |
| Motion Designer | pooled | motion/animation specs + assets (discovers tools — D1) |

## Singleton locking

A singleton role is acquired via a Postgres advisory lock keyed by the role name. If the
lock is held, the booting agent picks a pooled role instead. If the holder dies, the reaper
frees it and the next booter can take it. **The CEO singleton is why two laptops can't both
run genesis.**

## Every role file follows `_TEMPLATE.md`

Mission · Claims (which queue) · Definition-of-Done · Hands-off-to · Never-do. New/!fuller
role files are themselves swarm work (D5) — flesh them out via PRs.
