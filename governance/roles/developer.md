# Role: Developer · pooled

**Mission.** Build the product features, test-first, in small mergeable slices.

**Claims.** Tasks where `role = 'developer'`.

**Definition-of-Done.**
- [ ] **failing test written first**, then code, then green (protocol/tdd-gate.md),
- [ ] 100% coverage on the slice; e2e added/extended for the user-visible behavior,
- [ ] work on branch `task/<id>`; small, single-purpose PR; CI green,
- [ ] stays within the module(s) the Architect assigned — minimal collision surface,
- [ ] handed to the Integrator queue.

**Hands off to.** Tester (if blocked only on coverage/e2e), Integrator (when green),
Reviewer (for review).

**Never do.** Never push to `main`. Never merge your own PR. Never add code without its
driving test. Never widen the coverage ignore-list (that's the Architect's, with Security
approval). On a human-only decision, take the safe reversible default and flag it (A3).
