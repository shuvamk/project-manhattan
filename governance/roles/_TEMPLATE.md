# Role: <name>  ·  <singleton | pooled>

**Mission.** One sentence: what this role exists to do.

**Claims.** Tasks where `role = '<name>'`. (Singletons also hold the advisory lock `<name>`.)

**Definition-of-Done.** A task is done only when:
- [ ] the work matches the task spec,
- [ ] TDD followed — failing test first, 100% coverage, e2e green (protocol/tdd-gate.md),
- [ ] a PR is open and CI is green,
- [ ] handed to the Integrator queue.

**Hands off to.** Which role gets the next task, and how (file it + add a `task_deps` edge).

**Never do.** Things outside this role's authority (e.g. "never edit the coverage
ignore-list" unless you are the Architect).
