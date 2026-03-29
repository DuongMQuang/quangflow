# Hard Gates & Red Flag Detection

Referenced by all phase files and agent files. Defines the non-negotiable discipline rules that prevent shortcuts.

---

## Core Rule

**Every shortcut has a cost. Every rationalization hides a risk.** When you catch yourself thinking "this doesn't need X," that is exactly when X is most needed. The protocol exists because your confidence is uncalibrated.

---

## Master Red Flag Table

When any agent (or Claude itself) produces reasoning matching the left column, treat it as a **red flag** — stop and apply the corrective action.

| Red Flag Statement | Why It's Dangerous | Corrective Action |
|---|---|---|
| "This is too simple to need a test" | Simple code has the most hidden assumptions | Write the test. If it's truly simple, the test takes 30 seconds. |
| "I already know the root cause" | Confirmation bias skips evidence collection | Follow the full investigation protocol in `_systematic-debugging.md` |
| "Let me just quickly fix this" | Quick fixes skip root cause analysis | Log the bug, investigate systematically, then fix |
| "The tests pass, so it works" | Tests only cover what you thought to test | Check coverage gaps, edge cases, and integration paths |
| "I'll add tests later" | Later never comes. Untested code ships. | Write the test now. TDD means test-first, not test-later. |
| "This refactor is safe, no test needed" | Refactors change behavior in unexpected ways | Run existing tests first, add regression tests for changed paths |
| "The user didn't ask for tests" | Professional standards don't require user requests | Tests are non-negotiable for logic code. Inform the user. |
| "It works on my machine" | Environment differences cause production failures | Test in CI-equivalent conditions, document environment assumptions |
| "We can skip the gate this one time" | One skip normalizes all future skips | Gates exist for this exact scenario. No exceptions. |
| "I'm confident this is correct" | Confidence is not evidence | Produce the evidence artifact. If you're right, it costs nothing. |

---

## Evidence Artifact Specification

All evidence MUST be saved to the `.evidence/` directory at the project root. Evidence is the proof that discipline was followed.

### Directory Structure

```
.evidence/
├── tdd/
│   ├── REQ-001-red.log        # Failing test output (RED phase)
│   ├── REQ-001-green.log      # Passing test output (GREEN phase)
│   └── REQ-002-red.log
├── debug/
│   ├── BUG-001-investigation.md   # Root cause investigation
│   └── BUG-001-resolution.md      # Fix verification
├── verification/
│   ├── phase-1-gate.md        # Phase transition evidence
│   ├── phase-2-gate.md
│   └── CERTIFICATION.md       # Phase 4 final certification
└── logs/
    ├── build.log              # Build output
    ├── test-run-{timestamp}.log
    └── lint.log
```

### Naming Rules

| Evidence Type | Naming Pattern | Example |
|---|---|---|
| TDD red phase | `REQ-{ID}-red.log` | `REQ-001-red.log` |
| TDD green phase | `REQ-{ID}-green.log` | `REQ-001-green.log` |
| Bug investigation | `BUG-{ID}-investigation.md` | `BUG-042-investigation.md` |
| Bug resolution | `BUG-{ID}-resolution.md` | `BUG-042-resolution.md` |
| Phase gate | `phase-{N}-gate.md` | `phase-2-gate.md` |
| Certification | `CERTIFICATION.md` | `CERTIFICATION.md` |
| Test run log | `test-run-{timestamp}.log` | `test-run-2026-03-28T14-00.log` |

---

## Phase Transition Gate Checklists

No phase advances without evidence. The table below lists what MUST exist before crossing each gate.

| Transition | Required Evidence | Where |
|---|---|---|
| Phase 1 → 2 | Requirements approved, REQUIREMENTS.md written | `plans/{slug}/REQUIREMENTS.md` |
| Phase 2 → 3 | Design option selected, DESIGN.md written, gotchas reviewed | `plans/{slug}/milestone-{N}/DESIGN.md` |
| Phase 3 → 4 | ROADMAP.md written, all tasks have acceptance criteria | `plans/{slug}/milestone-{N}/ROADMAP.md` |
| Phase 4 → ship | All tests pass (logs saved), CERTIFICATION.md written, no open gaps | `.evidence/verification/CERTIFICATION.md` |

### Backwards Compatibility

If a project uses `QA-REPORT.md` (pre-discipline-layer), treat it as equivalent to `CERTIFICATION.md` for gate-checking purposes. Do NOT require migration — just read whichever exists.

---

## Enforcement Layers

Discipline is enforced at three layers. No single layer is sufficient alone.

| Layer | Mechanism | What It Catches |
|---|---|---|
| **1. Prompt Protocols** | Instructions in phase files and agent prompts | Guides behavior before action |
| **2. Inline Phase Gates** | Review gates at end of each phase (APPROVE / CONFIRM / SHIP) | Catches missing work before advancing |
| **3. Script Validation** | `stage-gate.sh` checks for required artifacts | Catches protocol violations mechanically |

All three layers MUST agree before a phase transition occurs.
