# TDD Enforcement Protocol

Referenced by `3-handoff.md`, `dev-teammate.md`, and `cook.md`. Ensures test-driven development is followed, not just claimed.

---

## HARD-GATE

<HARD-GATE>
Do NOT write implementation code until a failing test exists for the
requirement being implemented. No exceptions. No "I'll test it after."
The test comes first — always.
</HARD-GATE>

---

## RED-GREEN-REFACTOR Cycle

Every implementation task follows this exact sequence:

### Step 1: RED — Write a Failing Test
- Write a test that describes the expected behavior
- Run it. It MUST fail.
- Save the failing output to `.evidence/tdd/REQ-{ID}-red.log`
- If the test passes immediately: your test is wrong (it's not testing new behavior)

### Step 2: GREEN — Write Minimal Code
- Write the **minimum** implementation code to make the test pass
- Do not add features, optimizations, or "while I'm here" changes
- Run the test. It MUST pass.
- Save the passing output to `.evidence/tdd/REQ-{ID}-green.log`

### Step 3: REFACTOR
- Clean up the implementation code (extract functions, rename variables, remove duplication)
- Run all tests after refactoring — they MUST still pass
- Do NOT add new behavior during refactoring

### Step 4: COMMIT
- Commit the test + implementation together
- Commit message references the requirement: `feat(REQ-{ID}): {description}`

---

## Evidence Requirements

For each requirement implemented via TDD:

- `REQ-{ID}-red.log` MUST exist — proves the test failed before implementation
- `REQ-{ID}-green.log` MUST exist — proves the test passed after implementation
- Both logs MUST contain actual test runner output, not hand-written summaries

Phase 4 verification will audit these logs. Missing logs = failed gate.

---

## Red Flags

| Statement | Response |
|---|---|
| "I wrote the test and implementation together" | That is not TDD. Delete the implementation, verify the test fails, then re-implement. |
| "The test is trivial so I skipped the red phase" | Save the red log anyway. Trivial tests still need evidence. |
| "I'll write the test after I figure out the design" | Write a test for the interface you want. The test IS the design exploration. |
| "This code is just glue / config / boilerplate" | See Scope below. If it has logic, it needs a test. |
| "The test framework isn't set up yet" | Setting up the test framework IS the first task. Do it before any feature code. |

---

## Scope

### TDD Applies To
- All business logic and domain code
- API endpoints and request handling
- Data transformations and validation
- State management logic
- Any function with conditional branches

### TDD Does NOT Apply To
- Static configuration files (JSON, YAML, TOML)
- Type definitions / interfaces with no logic
- Import/export wiring (barrel files)
- CSS / styling (unless logic-driven)
- One-line pass-through functions with no branching

When in doubt: write the test. The cost of an unnecessary test is near zero. The cost of a missing test is unbounded.

---

## Multi-Agent Context

When used in a team pipeline (`cook.md`):
- Each dev agent follows TDD independently for their assigned tasks
- The tech-lead agent verifies evidence logs exist during review
- If a dev agent skips TDD, the tech-lead MUST reject the work and reassign
- Evidence logs are per-requirement, not per-agent — multiple agents can contribute to the same requirement's evidence
