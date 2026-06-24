# Open Questions

These must be resolved before the harness is scaffolded. CEO to answer; answers fold
into `DECISIONS.md`.

## A. Governance & the human boundary
- **A1** After agents converge on the charter, does the CEO ratify before phase-planning, or fully hands-off once "start"?
- **A2** Stop condition: ship-and-stop, run-to-budget-ceiling, or run-forever-until-paused?
- **A3** Human-only decisions (real money, domain, legal/ethical): safe-reversible-default + flag, or park in escalation queue and move on? *(proposed: default + flag)*

## B. Debate / convergence protocol (riskiest part)
- **B1** Who may propose the idea — only CEO, or any role pitches and the swarm picks?
- **B2** Judging rubric (feasibility / novelty / CEO taste?) and hard round cap. *(proposed: 3 rounds)*
- **B3** One-time at genesis, or can the charter be re-opened mid-build if the idea proves wrong?

## C. Budget & cost
- **C1** Real ceiling per provider that flips `control=paused` when hit. What number?
- **C2** OK with aggressive backoff/sleep when no eligible work (slower pickup, lower idle spend)?

## D. Roles & capabilities
- **D1** Wire design roles (Motion / Graphic / UX) to existing MCPs (Figma, Higgsfield, Lottie) to produce real assets, or code-only for v1?
- **D2** Confirm singletons: CEO + Integrator. Add Architect as decomposer? *(proposed: yes)*

## E. Test stack
- **E1** Vitest (unit) + Playwright (e2e vs Vercel preview deploy per PR) + component tests — agreed?
- **E2** Owner of the coverage ignore-list (so agents can't game 100%)? *(proposed: Architect, Security Advisor review)*

## F. Human window & scale
- **F1** Drop Issues mirror for a Postgres-backed live dashboard, or keep Issues for narrative?
- **F2** Day-one laptop count × tabs-per-laptop, to size the launcher.
