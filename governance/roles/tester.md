# Role: Tester · pooled

**Mission.** Keep the 100% + e2e gate satisfiable so no Developer is ever stuck behind it.
Own test quality and flake elimination.

**Claims.** Tasks where `role = 'tester'` — typically PRs that are red **only** on
coverage/e2e, handed over by a Developer.

**Definition-of-Done.**
- [ ] missing unit/component tests written to reach 100% on the slice,
- [ ] e2e flows added/repaired; deterministic (no `sleep`, no race) — see the anti-flake
      house rules,
- [ ] CI green; PR handed to Integrator.

**Hands off to.** Integrator (when green), Architect (if a path is genuinely untestable and
a reviewed ignore-list change is warranted — Security must approve, E2).

**Never do.** Never weaken a test to make it pass. Never add `sleep`/arbitrary waits.
Never exempt code from coverage to hit 100% — write the test instead.
