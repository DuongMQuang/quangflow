# Systematic Debugging Protocol

Referenced by `5-maintain.md`, `dev-teammate.md`, and `tester.md`. Prevents guesswork-driven debugging.

---

## HARD-GATE

> **Do NOT propose a fix until the investigation phase is complete and root cause is documented.** Guessing at fixes wastes time and introduces new bugs. Investigate first, fix second.

---

## 4-Phase Process

### Phase 1: Investigate

Gather facts before forming any hypothesis.

1. **Reproduce** — Can you trigger the bug reliably? Document exact steps.
2. **Isolate** — What is the smallest input/action that causes the failure?
3. **Collect logs** — Gather all relevant log output, error messages, stack traces.
4. **Map the path** — Trace the code path from input to failure point.
5. **Document** — Write the investigation file before moving on.

Save to `.evidence/debug/BUG-{ID}-investigation.md`:

```markdown
# Investigation — BUG-{ID}

## Bug Description
{one-line description}

## Reproduction Steps
1. {step}
2. {step}
3. {expected vs actual}

## Environment
- {runtime, OS, versions}

## Logs & Error Output
{paste relevant logs}

## Code Path Traced
{file:line → file:line → failure point}

## Observations
- {fact 1}
- {fact 2}
```

### Phase 2: Analyze

Review the evidence without jumping to solutions.

1. **List all facts** — What do you know for certain?
2. **List unknowns** — What information is missing?
3. **Check recent changes** — Was anything modified near the failure point? (git log, git blame)
4. **Check assumptions** — What does the code assume that might not be true?

### Phase 3: Hypothesize & Test

Now — and only now — form hypotheses.

1. **List 2-3 hypotheses** ranked by likelihood
2. **For each hypothesis:** design a test that would confirm or eliminate it
3. **Run the tests** — one hypothesis at a time, not all at once
4. **Record results** — which hypotheses survived, which were eliminated

### Phase 4: Fix & Verify

Apply the fix with full verification.

1. **Write a regression test** that reproduces the original bug (it should fail before the fix)
2. **Apply the minimal fix** — change as little as possible
3. **Run the regression test** — it MUST pass
4. **Run the full test suite** — no regressions
5. **Save evidence** to `.evidence/debug/BUG-{ID}-resolution.md`
6. **Log a GOTCHA** for the root cause (see `_shared.md` GOTCHAs System)

Save to `.evidence/debug/BUG-{ID}-resolution.md`:

```markdown
# Resolution — BUG-{ID}

## Root Cause
{what actually caused the bug}

## Fix Applied
{what was changed and why}

## Files Modified
- {file}: {what changed}

## Regression Test
- Test file: {path}
- Test name: {name}
- Confirms: {what it validates}

## Verification
- [ ] Regression test passes
- [ ] Full test suite passes
- [ ] No new warnings
```

---

## Escalation Rule

If **3 or more fix attempts** have failed for the same bug:

1. **Stop fixing.** The bug is a symptom of a deeper problem.
2. Question the architecture — is the design making this bug inevitable?
3. Escalate to the user: "This bug has resisted 3 fix attempts. The root cause may be architectural. Recommend reviewing the design of {component}."
4. Do NOT attempt a 4th fix without user approval.

---

## Auto-GOTCHA on Resolution

Every resolved bug MUST generate a GOTCHA entry (see `_shared.md` GOTCHAs System):
- **When:** Phase 5 / debugging
- **Root cause:** from the resolution document
- **Rule:** the preventive rule derived from the root cause
- **Tags:** relevant domain tags

---

## Red Flags

| Statement | Response |
|---|---|
| "I think I know what's wrong, let me just try this" | Follow the 4-phase process. Log your hypothesis in Phase 3. |
| "It's probably a typo / simple mistake" | Investigate anyway. "Probably" is not evidence. |
| "I changed something and it works now, not sure why" | You haven't found the root cause. Roll back and investigate. |
| "The fix is too big to test" | Break the fix into testable pieces. Every fix is testable. |
| "It only happens sometimes" | That's a concurrency, timing, or state bug. These are the hardest — investigate more, not less. |
| "Let me just restart the service" | Restarting hides the bug. Investigate the root cause first. |
