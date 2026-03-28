# Verification Gates Protocol

Referenced by `4-verify.md`, `tester.md`, and phase gate checks. Ensures claims of completion are backed by evidence.

---

## HARD-GATE

> **Do NOT claim any phase is complete without producing the required evidence artifact.** Confidence is not evidence. "I checked" is not evidence. Only saved, auditable output is evidence.

---

## At Every Phase Gate

Before any phase can be marked complete, follow these three steps:

1. **Run the command** — Execute the actual verification (test suite, lint, build, etc.)
2. **Save the output** — Write raw output to `.evidence/` with appropriate naming
3. **State the result** — Report PASS or FAIL with the evidence file path

### Phase Gate Evidence Template

Save to `.evidence/verification/phase-{N}-gate.md`:

```markdown
# Phase {N} Gate Evidence

## Date
{timestamp}

## Checks Performed
| Check | Command | Result | Evidence |
|---|---|---|---|
| {check name} | `{command run}` | PASS / FAIL | `.evidence/{path}` |

## Gate Result
**{PASS / FAIL}**

## Notes
{any observations, warnings, or caveats}
```

---

## Banned Language in Completion Claims

The following phrases are **banned** when reporting phase completion. They indicate missing evidence.

| Banned Phrase | Why |
|---|---|
| "Should work" | Untested assumption |
| "Looks correct" | Visual inspection is not verification |
| "I believe this is complete" | Belief is not evidence |
| "Everything seems fine" | "Seems" means not checked |
| "No issues found" (without evidence) | Absence of evidence is not evidence of absence |

**Instead say:**
- "All {N} tests pass. Evidence saved to `.evidence/tdd/`. Gate: PASS."
- "Build succeeded. Lint passed with 0 warnings. Logs saved to `.evidence/logs/`. Gate: PASS."

---

## Phase 4 Certification

Phase 4 produces the final certification before ship. Save to `.evidence/verification/CERTIFICATION.md`:

```markdown
# Certification — {feature-slug} / Milestone {N}

## Date
{timestamp}

## Traceability Matrix
| Requirement | Test File | Test Name | Result | Evidence |
|---|---|---|---|---|
| REQ-001 | tests/auth.test.ts | "should validate JWT" | PASS | REQ-001-green.log |
| REQ-002 | tests/users.test.ts | "should create user" | PASS | REQ-002-green.log |

## Evidence Audit
| Evidence Type | Expected | Found | Missing |
|---|---|---|---|
| TDD red logs | {N} | {N} | {list or "none"} |
| TDD green logs | {N} | {N} | {list or "none"} |
| Debug investigations | {N} | {N} | {list or "none"} |
| Phase gate logs | {N} | {N} | {list or "none"} |

## Log Audit
- Build log: {PRESENT / MISSING}
- Test run log: {PRESENT / MISSING}
- Lint log: {PRESENT / MISSING}

## Gaps
| Gap | Severity | Status |
|---|---|---|
| {description} | {critical / major / minor} | {remediated / deferred / accepted} |

## Certification Statement
All requirements have been implemented, tested, and verified with saved evidence.
Gate result: **{PASS / FAIL}**
```

---

## Backwards Compatibility

If a project already uses `QA-REPORT.md` (from pre-discipline-layer QuangFlow):
- Accept it as valid Phase 4 output
- Do NOT require migration to CERTIFICATION.md
- If both exist, prefer CERTIFICATION.md for gate checks
