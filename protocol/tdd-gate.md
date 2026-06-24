# TDD Merge Gate

**The single hardest rule in the swarm: nothing merges to `main` unless coverage is 100%
and all e2e pass.** This is enforced mechanically by CI ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml))
and by branch protection — not by trust.

## Test-first, always

Every behavioral change follows: **write the failing test → write the code → green.** A PR
that adds code without the test that drives it will fail the coverage gate and cannot merge.

## The stack (E1)

| Layer | Tool | What it covers |
|---|---|---|
| Unit | **Vitest** | pure logic, utilities, server functions |
| Component | **Vitest + Testing Library** | React components, interaction |
| End-to-end | **Playwright** | full user flows against the running app |

CI runs unit+component with a **100% coverage threshold** (lines, branches, functions,
statements), then builds the app and runs Playwright against it. Red on any → no merge.

## The walking skeleton comes first

Because the gate blocks PR #1 too, the **first task the Architect ever emits** is the
walking skeleton: an empty Next.js app + one trivial unit test + one Playwright smoke +
this CI workflow, all green. Only after that PR merges can feature work flow. Never let
feature tasks queue ahead of the skeleton.

## The coverage ignore-list (E2)

Some files are genuinely not unit-testable (generated code, pure config). They may be
exempted via the coverage ignore-list **only** under these rules:

- The list lives in one reviewed file (e.g. `vitest.config` coverage `exclude`).
- **Only the Architect** edits it.
- **The Security Advisor must approve** the change.
- Every change is a normal PR (visible, accountable).

Any agent caught widening the ignore-list to dodge a hard-to-test path instead of writing
the test is gaming the gate — the Reviewer rejects the PR.

## The Tester role exists to unblock this

If a PR is red **only** on coverage/e2e, the Developer hands it to a **Tester**, who writes
the missing tests. A Developer is never stuck behind the gate — they file a Tester task and
move on (blockers.md).
