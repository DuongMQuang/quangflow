# Protocol Files Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the 6 foundational protocol files that define TDD enforcement, systematic debugging, verification gates, hard gates, structured logging, and context memory.

**Architecture:** Six new protocol files in `commands/qf/_protocols/`. The hard-gates protocol is the foundation — all other protocols reference it for the red flag table and evidence spec. Each protocol uses `<HARD-GATE>` blocks for prompt-level enforcement.

**Tech Stack:** Bash, Markdown

**Parent plan:** `_index.md`
**Depends on:** (none — this is the foundation)

---

## Task 1: Create `_hard-gates.md` (foundation protocol)

**Files:**
- Create: `commands/qf/_protocols/_hard-gates.md`

This is the foundation — all other protocols reference it for the red flag table and evidence spec.

- [ ] **Step 1: Create the hard-gates protocol file**

```markdown
# Hard Gates & Red Flag Detection

Referenced by `_shared.md`. Injected into ALL phases. Provides master red flag table, evidence artifact specification, and phase-specific gate checklists.

## Core Rule

Every shortcut is a future bug. Every rationalization is a discipline failure. This protocol exists because agents — like humans — will convince themselves that "this one time" it's OK to skip the process. It is never OK.

## Master Red Flag Table

If you catch yourself thinking any of these, STOP and follow the process:

| Red flag thought | Reality |
|---|---|
| "This is too simple to need a test" | Simple code has the most hidden assumptions |
| "I'll add tests/logging/docs after" | You won't. Do it now. |
| "Quick fix for now" | Quick fixes become permanent debt |
| "It's probably X" | Investigate, don't guess |
| "Should work" / "seems correct" | Run it. Show the output. |
| "I know what this does" | Read the code. Memory lies. |
| "This doesn't need the full process" | Every shortcut becomes a bug |
| "Let me just get it working first" | Working without tests = working without proof |
| "The framework handles that" | Verify. Frameworks have bugs too. |
| "I'll come back and clean this up" | You won't come back. Do it now. |

## Evidence Artifact Specification

All evidence lives in `.evidence/` at the project root (sibling to `plans/`):

```
.evidence/
├── tdd/
│   ├── REQ-001-red.log          # failing test output (must contain FAIL)
│   ├── REQ-001-green.log        # passing test output (must contain PASS or OK)
│   └── ...
├── debug/
│   ├── BUG-001-investigation.md # investigation findings (before any fix)
│   └── BUG-001-resolution.md    # root cause + fix applied
├── verification/
│   ├── phase-1-gate.md          # evidence at Phase 1 → 2 transition
│   ├── phase-2-gate.md          # evidence at Phase 2 → 3 transition
│   ├── phase-3-gate.md          # evidence at Phase 3 → 4 transition
│   └── phase-4-certification.md # final certification (replaces QA-REPORT.md for new milestones)
└── logs/
    ├── test-run-YYYY-MM-DD.jsonl    # structured test logs
    ├── e2e-run-YYYY-MM-DD.jsonl     # E2E scenario logs
    └── fe-errors-YYYY-MM-DD.jsonl   # frontend errors bridged to BE
```

**Naming rules:**
- TDD logs: `REQ-{ID}-red.log` and `REQ-{ID}-green.log`
- Debug artifacts: `BUG-{ID}-investigation.md` and `BUG-{ID}-resolution.md`
- Verification gates: `phase-{N}-gate.md`
- Structured logs: `{type}-YYYY-MM-DD.jsonl`

## Phase Transition Gate Checklists

Each transition has required evidence. The `validate-evidence.sh` script enforces these.

| Transition | Required evidence | Script check |
|---|---|---|
| Phase 1 → 2 | REQUIREMENTS.md with REQ-IDs and acceptance criteria | File exists, REQ-IDs present |
| Phase 2 → 3 | DESIGN.md with chosen option; DEBATE.md if team mode | File exists, option marked chosen |
| Phase 3 → 4 | `.evidence/tdd/` has red+green logs for every REQ-ID; all tests green | `validate-tdd-coverage.sh` |
| Phase 4 → ship | CERTIFICATION.md with full traceability matrix, zero unresolved gaps | File exists, no UNRESOLVED entries |

**Backwards compatibility:** Existing milestones with QA-REPORT.md are recognized. CERTIFICATION.md is required only for milestones started after this protocol is installed.

## Enforcement Layers

This framework uses three layers of enforcement:

1. **Prompt protocols** — hard gate blocks in protocol `.md` files (agent reads and follows)
2. **Inline phase gates** — hard gate blocks embedded directly in phase `.md` files (visible during execution)
3. **Script validation** — bash scripts that check for evidence artifacts (blocks pipeline advancement)

All three layers must agree. If any layer blocks, the action is blocked.
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `wc -l commands/qf/_protocols/_hard-gates.md`
Expected: ~80 lines

- [ ] **Step 3: Commit**

```bash
git add commands/qf/_protocols/_hard-gates.md
git commit -m "feat: add _hard-gates.md — master red flag table and evidence spec"
```

---

## Task 2: Create `_tdd-enforcement.md`

**Files:**
- Create: `commands/qf/_protocols/_tdd-enforcement.md`

- [ ] **Step 1: Create the TDD enforcement protocol file**

```markdown
# TDD Enforcement Protocol

Referenced by `3-handoff.md` and `dev-teammate.md`. Enforces test-driven development during all implementation work.

## Core Rule

<HARD-GATE>
Do NOT write implementation code until a failing test exists and its
failure output is saved to .evidence/tdd/. No exceptions. No "I'll
write tests after." No "this is too simple to test."
</HARD-GATE>

## The RED-GREEN-REFACTOR Cycle

For EVERY code change tied to a requirement:

### 1. RED — Write a failing test
- Write a test that captures the requirement's acceptance criteria
- The test MUST reference the REQ-ID in a comment or test name: `test_REQ001_user_can_login`
- Run the test
- It MUST fail (if it passes, your test doesn't test anything new)
- Save the failing output: `cat test-output > .evidence/tdd/REQ-{ID}-red.log`

### 2. GREEN — Write minimal code to pass
- Write the MINIMUM code to make the failing test pass
- No extra features, no "while I'm here" additions
- Run the test
- It MUST pass
- Save the passing output: `cat test-output > .evidence/tdd/REQ-{ID}-green.log`

### 3. REFACTOR — Clean up (tests stay green)
- Refactor implementation if needed (remove duplication, improve naming)
- Run tests after each refactor step — they must stay green
- Do NOT add new functionality during refactor

### 4. COMMIT — Test + code together
- Commit the test and implementation together, never separately
- Format: `feat: {description} (REQ-{ID})`

## Evidence Requirements

Both log files MUST exist for each REQ-ID before Phase 3 → 4 transition:
- `.evidence/tdd/REQ-{ID}-red.log` — must contain at least one FAIL/ERROR/FAILED indicator
- `.evidence/tdd/REQ-{ID}-green.log` — must contain PASS/OK/SUCCESS indicator and zero failures

The `validate-tdd-coverage.sh` script checks this automatically.

## Red Flags

If you catch yourself thinking any of these, STOP:
- "This is too simple to need a test" — see `_hard-gates.md` master table
- "I'll add tests after the implementation works"
- "The test would just test the framework"
- "Let me get the code working first, then add tests"
- "I already know this code works"

## Scope

TDD applies to:
- All production code tied to a REQ-ID
- All bug fixes (write failing test for the bug BEFORE fixing)
- All new modules, functions, and endpoints

TDD does NOT apply to:
- Configuration files (YAML, JSON, env)
- Documentation
- Build scripts and CI/CD configs
- Generated code (migrations, schemas) — but test the generation output

## Multi-Agent Context

When dev agents run in parallel:
- Each dev writes TDD evidence for their assigned REQ-IDs only
- The Tester agent later audits that all REQ-IDs have evidence
- If a dev's evidence is missing, the pipeline blocks at Phase 4
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `wc -l commands/qf/_protocols/_tdd-enforcement.md`
Expected: ~75 lines

- [ ] **Step 3: Commit**

```bash
git add commands/qf/_protocols/_tdd-enforcement.md
git commit -m "feat: add _tdd-enforcement.md — RED-GREEN-REFACTOR protocol with evidence"
```

---

## Task 3: Create `_systematic-debugging.md`

**Files:**
- Create: `commands/qf/_protocols/_systematic-debugging.md`

- [ ] **Step 1: Create the systematic debugging protocol file**

```markdown
# Systematic Debugging Protocol

Referenced by `5-maintain.md`. Available to all agents when encountering failures during implementation.

## Core Rule

<HARD-GATE>
Do NOT propose a fix until you have completed the investigation phase
and documented findings in .evidence/debug/. "Just try changing X" is
not debugging — it's guessing.
</HARD-GATE>

## 4-Phase Process

### Phase 1: Investigate

Before touching any code:

1. **Reproduce** — confirm the bug exists. Run the failing scenario and capture output.
2. **Read logs** — filter structured logs (see `_structured-logging.md`) by:
   - `level=ERROR` or `level=FATAL`
   - `module={affected-module}`
   - `source={frontend|backend}`
   - Time window matching the bug report
3. **Read stack traces** — identify the exact file, function, and line
4. **Gather context** — read the affected files, check recent changes (`git log -5 {file}`)
5. **Document** — save findings to `.evidence/debug/BUG-{ID}-investigation.md`:

```markdown
# Investigation — BUG-{ID}

## Bug Description
{what's happening vs what should happen}

## Reproduction Steps
1. {step}
2. {step}
Expected: {X}  Actual: {Y}

## Evidence
- Log entries: {relevant log lines}
- Stack trace: {key frames}
- Affected files: {list}
- Recent changes: {git log summary}

## Observations
- {fact 1}
- {fact 2}

## NOT YET: Hypothesis
(Do not form a hypothesis until Phase 2)
```

### Phase 2: Analyze

1. **Find working examples** — find similar code in the project that DOES work
2. **Compare differences** — what's different between the working and broken code?
3. **Identify patterns** — is this a known pattern? Check GOTCHAS.md for prior lessons.
4. **Load feature memory** — use `@{feature}` mention to load the FMU for context

### Phase 3: Hypothesize & Test

1. **Form ONE theory** — based on investigation + analysis, form a single hypothesis
2. **Test minimally** — make the smallest possible change to test the hypothesis
3. **One variable at a time** — never change two things at once
4. **If hypothesis fails** — return to Phase 2 with new evidence. Do NOT try random fixes.

### Escalation Rule

**After 3 failed fix attempts:** STOP fixing code. Question the architecture.

Ask yourself:
- Is the design fundamentally wrong for this use case?
- Am I fixing symptoms instead of the root cause?
- Does this module need to be restructured?

If the answer to any is yes: log this in GOTCHAS.md as a design-level issue and escalate to the user.

### Phase 4: Fix & Verify

1. **Write a failing test** for the bug (follows `_tdd-enforcement.md`)
   - Save output to `.evidence/tdd/BUG-{ID}-red.log`
2. **Fix the root cause** — not a workaround, not a patch
3. **Run the test** — must pass
   - Save output to `.evidence/tdd/BUG-{ID}-green.log`
4. **Run full test suite** — verify no regressions
5. **Document resolution** — save to `.evidence/debug/BUG-{ID}-resolution.md`:

```markdown
# Resolution — BUG-{ID}

## Root Cause
{explanation}

## Fix Applied
- Files changed: {list}
- What was changed: {description}

## Verification
- Bug-specific test: {test name} — PASS
- Regression suite: {X} passed, {Y} failed

## Defense in Depth
- {additional validation added at layer X}
- {additional check added at layer Y}
```

6. **Auto-GOTCHA** — write root cause + fix + domain tags to GOTCHAS.md:
   - Use the logging protocol in `_shared.md → GOTCHAs System`
   - Tag with the phase where this should have been caught
   - Tag with the domain (backend, frontend, etc.)

## Red Flags

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "It's probably X, let me fix that"
- "This worked in another project, so..."
- "I've seen this before, it's always Y"
- "Let me revert and try a different approach" (without understanding why the first failed)
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `wc -l commands/qf/_protocols/_systematic-debugging.md`
Expected: ~105 lines

- [ ] **Step 3: Commit**

```bash
git add commands/qf/_protocols/_systematic-debugging.md
git commit -m "feat: add _systematic-debugging.md — 4-phase root cause process"
```

---

## Task 4: Create `_verification-gates.md`

**Files:**
- Create: `commands/qf/_protocols/_verification-gates.md`

- [ ] **Step 1: Create the verification gates protocol file**

```markdown
# Verification Gates Protocol

Referenced by ALL phase files. Enforces evidence-based completion claims at every phase transition.

## Core Rule

<HARD-GATE>
Do NOT claim any phase is complete, any test passes, or any bug is
fixed without running a verification command and saving its output to
.evidence/verification/. Confidence is not evidence.
</HARD-GATE>

## At Every Phase Gate

Before stating that a phase is complete:

1. **Run the verification command** appropriate to the phase:
   - Phase 1 → 2: `bash scripts/validate/validate-artifacts.sh ./plans/{feature-slug}` (checks REQUIREMENTS.md structure)
   - Phase 2 → 3: `bash scripts/validate/validate-artifacts.sh ./plans/{feature-slug}` (checks DESIGN.md)
   - Phase 3 → 4: `bash scripts/validate/validate-tdd-coverage.sh ./plans/{feature-slug}` + full test suite
   - Phase 4 → ship: `bash scripts/validate/validate-evidence.sh ./plans/{feature-slug}` (checks all evidence)

2. **Save the output** to `.evidence/verification/phase-{N}-gate.md`:

```markdown
# Phase {N} Gate Evidence

## Command Run
`{exact command}`

## Output
```
{raw output from the command}
```

## Result
{PASS or FAIL — derived from actual output, not opinion}

## Timestamp
{ISO-8601}
```

3. **Only then state the result** — quote the actual output, not a paraphrase

## Banned Language in Completion Claims

Never use these phrases when claiming work is done:
- "should work" / "probably passes" / "seems correct"
- "great!" / "perfect!" / "looks good!" (without evidence)
- "I believe this is complete" (without test output)
- "tests are passing" (without showing which tests, when run)
- "everything looks good" (without specifying what was checked)

**Instead say:**
- "Test suite ran at {time}: {X} passed, {Y} failed. Output saved to .evidence/verification/phase-{N}-gate.md"
- "Validation script exited 0. {N} checks passed, 0 failed. Evidence at {path}"

## Phase 4 Certification

Phase 4 produces `CERTIFICATION.md` (not just QA-REPORT.md) for new milestones:

```markdown
# Certification — {feature-slug} / Milestone {N}

## Traceability Matrix
| REQ-ID | Unit Test (TDD) | Integration Test | E2E Test | Status |
|--------|-----------------|------------------|----------|--------|
| REQ-001 | test_REQ001_* | int_auth_flow | e2e_login | PASS |
| REQ-002 | test_REQ002_* | int_payment | — | PASS |

## Evidence Audit
| Artifact | Path | Exists | Valid |
|----------|------|--------|-------|
| REQ-001 red log | .evidence/tdd/REQ-001-red.log | Y | Y (contains FAIL) |
| REQ-001 green log | .evidence/tdd/REQ-001-green.log | Y | Y (contains PASS) |
| Phase 3 gate | .evidence/verification/phase-3-gate.md | Y | Y |

## Log Audit
- ERROR entries in test run: 0
- FATAL entries in test run: 0
- Unstructured log usage detected: {Y/N}

## Gaps
| GAP-ID | Severity | Status |
|--------|----------|--------|
| (none) | — | — |

## Certification
All requirements verified. All evidence present and valid. Zero unresolved gaps.
Certified by: {agent role} at {timestamp}
```

## Backwards Compatibility

Existing milestones that already have QA-REPORT.md are recognized as valid.
CERTIFICATION.md is required only for milestones started AFTER the discipline layer is installed.
Phase 4 checks for either artifact and accepts both.
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `wc -l commands/qf/_protocols/_verification-gates.md`
Expected: ~95 lines

- [ ] **Step 3: Commit**

```bash
git add commands/qf/_protocols/_verification-gates.md
git commit -m "feat: add _verification-gates.md — evidence-before-assertions protocol"
```

---

## Task 5: Create `_structured-logging.md`

**Files:**
- Create: `commands/qf/_protocols/_structured-logging.md`

- [ ] **Step 1: Create the structured logging protocol file**

```markdown
# Structured Logging Protocol

Referenced by `3-handoff.md` (devs implement), `4-verify.md` (audit coverage), `5-maintain.md` (debugging reads logs).

## Core Rule

<HARD-GATE>
All application code MUST use the structured logging format. Do NOT use
raw console.log/print/println for operational output. Unstructured logs
cannot be parsed by the debugging protocol or verification gates.
</HARD-GATE>

## Log Format Standard

Every log entry must be a single JSON line with these fields:

```json
{
  "timestamp": "2026-03-28T14:30:00.000Z",
  "level": "INFO",
  "source": "backend",
  "module": "auth/login",
  "req_id": "REQ-003",
  "trace_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "User login successful",
  "context": { "user_id": "123", "method": "email" },
  "stack": null
}
```

### Required Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `timestamp` | string | always | ISO-8601 with timezone |
| `level` | enum | always | `INFO`, `WARN`, `ERROR`, `FATAL` |
| `source` | enum | always | `frontend`, `backend`, `test`, `e2e` |
| `module` | string | always | Slash-separated path: `auth/login`, `payments/checkout` |
| `req_id` | string | if applicable | REQ-ID this log relates to (null if general) |
| `trace_id` | string | always | UUID linking FE→BE request chain |
| `message` | string | always | Human-readable, no PII |
| `context` | object | optional | Structured data relevant to the event |
| `stack` | string | ERROR/FATAL only | Full stack trace |

### Log Levels

| Level | When to use | Debugging use |
|-------|------------|---------------|
| `INFO` | Normal operations, state transitions, request start/end | Verify happy path works |
| `WARN` | Recoverable issues, fallback triggered, deprecation | Spot degradation before failure |
| `ERROR` | Failed operations, caught exceptions, contract violations | Primary debugging signal |
| `FATAL` | Unrecoverable state, app should terminate | Crash investigation |

## Frontend → Backend Log Bridge

Frontend errors must be captured and sent to the backend for unified logging:

### What to capture on FE:
- `window.onerror` / `window.onunhandledrejection` — uncaught exceptions
- Failed API calls (non-2xx responses)
- `console.error()` calls (wrap or intercept)

### How to send:
- POST to `/api/logs` (or project-specific endpoint)
- Payload: array of log entries in the standard format
- `source: "frontend"` distinguishes from backend logs
- Include `trace_id` from the original request that triggered the error

### Backend handler:
- Receives FE log entries
- Writes them to the same `.jsonl` log file as backend entries
- Validates format, drops malformed entries with a WARN

## Log File Locations

```
./logs/
├── app-YYYY-MM-DD.jsonl         # combined BE + bridged FE logs
├── test-YYYY-MM-DD.jsonl        # test suite logs
└── e2e-YYYY-MM-DD.jsonl         # E2E scenario logs
```

Evidence copies go to:
```
.evidence/logs/
├── test-run-YYYY-MM-DD.jsonl    # copied from ./logs/ after test run
├── e2e-run-YYYY-MM-DD.jsonl     # copied from ./logs/ after E2E run
└── fe-errors-YYYY-MM-DD.jsonl   # FE errors for the day
```

## Integration with Other Protocols

- **TDD:** Test runs produce structured logs. Red/green evidence includes log output.
- **Debugging:** `_systematic-debugging.md` reads structured logs as first investigation step. Filter by level, source, module.
- **Verification:** `_verification-gates.md` checks logs for ERROR/FATAL entries at phase gates.
- **Phase 4:** Audits that every module produces structured logs. Flags unstructured output.
- **Phase 5:** Log scanning uses structured format for smart reading (see 5-maintain.md bookmark system).

## Red Flags

- "console.log is fine for now"
- "We don't need logging for this module"
- "I'll add logging after it works"
- "The test output is enough, no need for structured logs"
- "Logging is boilerplate, I'll skip it for this file"

## Implementation Notes for Dev Agents

When implementing logging in a new project:
1. Create a logger utility matching the project's language/framework
2. The utility must output one JSON line per entry to stdout or a file
3. Include a `createLogger(module)` factory that auto-fills the `module` field
4. Include a FE error bridge if the project has a frontend
5. Add log directory to `.gitignore` (logs are runtime artifacts, not source)
6. Add `.evidence/` to `.gitignore` (evidence is per-session, not committed to main)
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `wc -l commands/qf/_protocols/_structured-logging.md`
Expected: ~110 lines

- [ ] **Step 3: Commit**

```bash
git add commands/qf/_protocols/_structured-logging.md
git commit -m "feat: add _structured-logging.md — log format standard with FE→BE bridge"
```

---

## Task 6: Create `_context-memory.md`

**Files:**
- Create: `commands/qf/_protocols/_context-memory.md`

- [ ] **Step 1: Create the context memory protocol file**

```markdown
# Context Memory Protocol — Feature Memory Units

Referenced by all phases. Manages per-feature context via @mention loading for scalable projects.

## Core Rule

<HARD-GATE>
Do NOT start work on any feature without loading its FMU via @mention.
Do NOT load all FMUs at once. If the feature has no FMU yet, create one
in Phase 0 before proceeding.
</HARD-GATE>

## Feature Memory Units (FMUs)

Each feature/module gets a self-contained context directory in `.memory/`:

```
.memory/
├── _index.md                    # master registry of all FMUs
├── auth/
│   ├── CONTEXT.md               # what this feature is, dependencies, owners
│   ├── REQUIREMENTS.md          # REQ-IDs scoped to this feature
│   ├── DESIGN.md                # architecture decisions for this feature
│   ├── GOTCHAS.md               # lessons specific to this feature
│   ├── HISTORY.md               # key decisions timeline (date + rationale)
│   └── LINKS.md                 # cross-references to related FMUs
├── payments/
│   └── ...
└── api-gateway/
    └── ...
```

## `_index.md` Schema

```markdown
# Feature Memory Index

| Feature | Status | Dependencies | Last updated |
|---------|--------|-------------|--------------|
| @auth | active | — | 2026-03-28 |
| @payments | active | @auth, @api-gateway | 2026-03-28 |
| @api-gateway | active | @auth | 2026-03-25 |
| @notifications | planning | @auth | 2026-03-28 |
```

**Status values:** `planning`, `active`, `shipped`, `deprecated`

## @mention Loading System

When anyone references `@feature-name`:

1. Resolve the name against `.memory/_index.md`
2. If found: load that FMU's full context (all files in the directory)
3. Also read LINKS.md to see dependencies — but load linked FMUs at CONTEXT.md level only (summary, not full)
4. If not found: warn "No FMU for @{name}. Create one with Phase 0 or manually."

**Usage examples:**
- `"Fix the login timeout bug @auth"` → loads `.memory/auth/` full context
- `"This payment flow calls @auth for token validation"` → loads `.memory/payments/` (primary) + `.memory/auth/CONTEXT.md` (linked summary)
- `"/qf:1-brainstorm @notifications"` → creates `.memory/notifications/` if it doesn't exist, loads related FMUs

## Save Rules — When to Write

| Event | What gets saved | Where |
|---|---|---|
| Phase 0 init | Create FMU directory + CONTEXT.md | `.memory/{feature}/CONTEXT.md` |
| Phase 1 brainstorm | Feature-scoped requirements | `.memory/{feature}/REQUIREMENTS.md` |
| Phase 2 design | Architecture decisions | `.memory/{feature}/DESIGN.md` |
| Any GOTCHA logged | Feature-specific lesson | `.memory/{feature}/GOTCHAS.md` |
| Key decision made | Decision + date + rationale | `.memory/{feature}/HISTORY.md` |
| Cross-feature dep found | Update both sides | `.memory/{feature}/LINKS.md` |
| Bug resolved | Root cause + fix | `.memory/{feature}/GOTCHAS.md` + `HISTORY.md` |

## Load Rules — What to Load When

| Situation | What to load |
|---|---|
| `@feature` mentioned | That FMU's full context |
| Linked feature referenced | Linked FMU's CONTEXT.md only |
| Phase 4 verify | All FMUs in current milestone |
| Phase 5 maintain | FMU matching the bug's module |
| `/qf:status` | `_index.md` only (overview) |
| New dev agent spawned | Only FMUs matching their file ownership globs |

## FMU CONTEXT.md Template

```markdown
# {Feature Name}

## Purpose
{One paragraph: what this feature does and why it exists}

## Dependencies
- @{feature-name}: {what it provides to us}

## Owners
- {agent role or developer}: {what they own}

## Key Constraints
- {constraint 1}
- {constraint 2}

## Status
{planning | active | shipped | deprecated}

## Last Updated
{ISO-8601 date}
```

## FMU LINKS.md Template

```markdown
# Links — {Feature Name}

## Depends On
- @{feature}: {what we consume from them}

## Depended On By
- @{feature}: {what they consume from us}

## Related (no dependency)
- @{feature}: {how we're related}
```

**Bidirectional rule:** When adding a link from A→B, also add the reverse link from B→A. The `validate-memory.sh` script checks for this.

## Red Flags

- "I'll just read the whole project context"
- "I don't need to check the feature memory for this"
- "This is a small change, no need to load context"
- "I remember what this feature does from earlier"
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `wc -l commands/qf/_protocols/_context-memory.md`
Expected: ~120 lines

- [ ] **Step 3: Commit**

```bash
git add commands/qf/_protocols/_context-memory.md
git commit -m "feat: add _context-memory.md — Feature Memory Units with @mention loading"
```
