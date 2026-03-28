# Discipline Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Embed TDD enforcement, systematic debugging, verification gates, hard gates, structured logging, and feature memory into QuangFlow's existing phases — plus eliminate solo mode.

**Architecture:** Six new protocol files in `commands/qf/_protocols/`, three new validation/hook scripts in `scripts/`, modifications to four existing phase files and two agent files. All protocols use hard gates (prompt-level) backed by script enforcement (system-level).

**Tech Stack:** Bash (scripts), Markdown (protocols/phases/agents)

---

## File Structure

### New files to create:
- `commands/qf/_protocols/_tdd-enforcement.md` — TDD red-green-refactor protocol
- `commands/qf/_protocols/_systematic-debugging.md` — 4-phase root cause process
- `commands/qf/_protocols/_verification-gates.md` — evidence-before-assertions protocol
- `commands/qf/_protocols/_hard-gates.md` — master red flag table + phase gate checklists
- `commands/qf/_protocols/_structured-logging.md` — log format standard + FE→BE bridge
- `commands/qf/_protocols/_context-memory.md` — Feature Memory Units + @mention system
- `scripts/validate/validate-tdd-coverage.sh` — verify red+green logs per REQ-ID
- `scripts/validate/validate-evidence.sh` — verify .evidence/ has required artifacts per phase
- `scripts/validate/validate-memory.sh` — verify FMU structure, no orphans, bidirectional links
- `scripts/hooks/auto-checkpoint.sh` — PostToolUse hook: auto-save agent progress
- `scripts/hooks/evidence-tracker.sh` — PostToolUse hook: track evidence in PIPELINE-STATE
- `scripts/hooks/save-feature-memory.sh` — phase transition hook: auto-update FMU

### Existing files to modify:
- `commands/qf/_protocols/_shared.md` — add hard-gates reference, evidence artifact spec, updated gate keywords
- `commands/qf/3-handoff.md` — inject TDD + logging + verification, remove SOLO option
- `commands/qf/4-verify.md` — evolve to "Verify & Certify", add TDD compliance audit
- `commands/qf/5-maintain.md` — inject systematic debugging protocol
- `commands/qf/quick.md` — remove solo mode, require minimal team (dev + tester)
- `agents/dev-teammate.md` — inject TDD enforcement into implementation protocol
- `agents/tester.md` — evolve: remove unit tests, add integration/E2E focus + TDD audit
- `scripts/validate/validate-stage-completion.sh` — add evidence checks to devs/verify stages

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

---

## Task 7: Create validation scripts

**Files:**
- Create: `scripts/validate/validate-tdd-coverage.sh`
- Create: `scripts/validate/validate-evidence.sh`
- Create: `scripts/validate/validate-memory.sh`

- [ ] **Step 1: Create `validate-tdd-coverage.sh`**

```bash
#!/usr/bin/env bash
# Validates TDD evidence coverage: every REQ-ID must have red + green logs.
#
# Usage:
#   bash scripts/validate/validate-tdd-coverage.sh <plans-feature-dir>
#
# Reads REQUIREMENTS.md for REQ-IDs, checks .evidence/tdd/ for matching logs.
# Exit codes: 0 = pass, 1 = block

set -euo pipefail

FEATURE_DIR="${1:-}"
if [[ -z "$FEATURE_DIR" ]]; then
  echo "Usage: validate-tdd-coverage.sh <plans-feature-dir>"
  exit 1
fi

# Find project root (parent of plans/)
PROJECT_ROOT="$(cd "$FEATURE_DIR/../.." 2>/dev/null && pwd || cd "$FEATURE_DIR/.." && pwd)"
EVIDENCE_DIR="$PROJECT_ROOT/.evidence/tdd"
REQS_FILE="$FEATURE_DIR/REQUIREMENTS.md"

PASS=0; FAIL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

echo -e "${BOLD}TDD Coverage Validation${NC}"
echo "Feature: $FEATURE_DIR"
echo ""

# Check REQUIREMENTS.md exists
if [[ ! -f "$REQS_FILE" ]]; then
  fail "REQUIREMENTS.md not found at $REQS_FILE"
  echo -e "\n${RED}Validation failed. 1 failure(s).${NC}"
  exit 1
fi

# Extract REQ-IDs
REQ_IDS=$(grep -oE 'REQ-[0-9]+' "$REQS_FILE" | sort -u)
if [[ -z "$REQ_IDS" ]]; then
  fail "No REQ-IDs found in REQUIREMENTS.md"
  echo -e "\n${RED}Validation failed. 1 failure(s).${NC}"
  exit 1
fi

REQ_COUNT=$(echo "$REQ_IDS" | wc -l | tr -d ' ')
echo "Found $REQ_COUNT REQ-IDs to check"
echo ""

# Check evidence directory exists
if [[ ! -d "$EVIDENCE_DIR" ]]; then
  fail ".evidence/tdd/ directory does not exist"
  echo "All $REQ_COUNT REQ-IDs are missing TDD evidence"
  echo -e "\n${RED}Validation failed.${NC}"
  exit 1
fi

# Check each REQ-ID has red + green logs
while IFS= read -r req_id; do
  RED_LOG="$EVIDENCE_DIR/${req_id}-red.log"
  GREEN_LOG="$EVIDENCE_DIR/${req_id}-green.log"

  # Check red log
  if [[ -f "$RED_LOG" ]]; then
    # Verify it contains a failure indicator
    if grep -qiE 'FAIL|ERROR|FAILED|AssertionError' "$RED_LOG" 2>/dev/null; then
      pass "$req_id: red log exists and contains failure"
    else
      fail "$req_id: red log exists but does NOT contain failure indicator (FAIL/ERROR)"
    fi
  else
    fail "$req_id: red log missing (.evidence/tdd/${req_id}-red.log)"
  fi

  # Check green log
  if [[ -f "$GREEN_LOG" ]]; then
    # Verify it contains a pass indicator and no failures
    if grep -qiE 'PASS|OK|SUCCESS|passed' "$GREEN_LOG" 2>/dev/null; then
      if grep -qiE 'FAIL|ERROR|FAILED' "$GREEN_LOG" 2>/dev/null; then
        fail "$req_id: green log contains both PASS and FAIL — tests not fully passing"
      else
        pass "$req_id: green log exists and all tests pass"
      fi
    else
      fail "$req_id: green log exists but does NOT contain pass indicator (PASS/OK/SUCCESS)"
    fi
  else
    fail "$req_id: green log missing (.evidence/tdd/${req_id}-green.log)"
  fi
done <<< "$REQ_IDS"

# Summary
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}TDD coverage complete. All $REQ_COUNT REQ-IDs have valid evidence.${NC}"
  exit 0
else
  echo -e "${RED}TDD coverage incomplete. $FAIL failure(s) out of $TOTAL checks.${NC}"
  exit 1
fi
```

- [ ] **Step 2: Create `validate-evidence.sh`**

```bash
#!/usr/bin/env bash
# Validates evidence artifacts exist for a given phase transition.
#
# Usage:
#   bash scripts/validate/validate-evidence.sh <plans-feature-dir> <phase>
#
# Phases: 1, 2, 3, 4 (checks evidence required to EXIT that phase)
# Exit codes: 0 = pass, 1 = block

set -euo pipefail

FEATURE_DIR="${1:-}"
PHASE="${2:-}"

if [[ -z "$FEATURE_DIR" || -z "$PHASE" ]]; then
  echo "Usage: validate-evidence.sh <plans-feature-dir> <phase>"
  exit 1
fi

PROJECT_ROOT="$(cd "$FEATURE_DIR/../.." 2>/dev/null && pwd || cd "$FEATURE_DIR/.." && pwd)"
EVIDENCE_DIR="$PROJECT_ROOT/.evidence"

PASS=0; FAIL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

echo -e "${BOLD}Evidence Validation — Phase $PHASE${NC}"
echo "Feature: $FEATURE_DIR"
echo ""

case "$PHASE" in
  1)
    # Phase 1 → 2: REQUIREMENTS.md with REQ-IDs
    REQS="$FEATURE_DIR/REQUIREMENTS.md"
    if [[ -f "$REQS" ]]; then
      REQ_COUNT=$(grep -cE 'REQ-[0-9]+' "$REQS" 2>/dev/null || echo 0)
      if [[ "$REQ_COUNT" -gt 0 ]]; then
        pass "REQUIREMENTS.md has $REQ_COUNT REQ-IDs"
      else
        fail "REQUIREMENTS.md exists but has no REQ-IDs"
      fi
    else
      fail "REQUIREMENTS.md missing"
    fi

    # Phase gate evidence
    GATE="$EVIDENCE_DIR/verification/phase-1-gate.md"
    if [[ -f "$GATE" ]]; then
      pass "Phase 1 gate evidence exists"
    else
      fail "Phase 1 gate evidence missing (.evidence/verification/phase-1-gate.md)"
    fi
    ;;

  2)
    # Phase 2 → 3: DESIGN.md with chosen option
    # Find milestone dir (most recent)
    MILESTONE_DIR=$(find "$FEATURE_DIR" -maxdepth 1 -name "milestone-*" -type d | sort -V | tail -1)
    if [[ -n "$MILESTONE_DIR" ]]; then
      DESIGN="$MILESTONE_DIR/DESIGN.md"
    else
      DESIGN="$FEATURE_DIR/DESIGN.md"
    fi

    if [[ -f "$DESIGN" ]]; then
      pass "DESIGN.md exists"
    else
      fail "DESIGN.md missing"
    fi

    GATE="$EVIDENCE_DIR/verification/phase-2-gate.md"
    if [[ -f "$GATE" ]]; then
      pass "Phase 2 gate evidence exists"
    else
      fail "Phase 2 gate evidence missing (.evidence/verification/phase-2-gate.md)"
    fi
    ;;

  3)
    # Phase 3 → 4: TDD coverage + all tests green
    echo "Running TDD coverage check..."
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if bash "$SCRIPT_DIR/validate-tdd-coverage.sh" "$FEATURE_DIR"; then
      pass "TDD coverage validation passed"
    else
      fail "TDD coverage validation failed — see above"
    fi

    GATE="$EVIDENCE_DIR/verification/phase-3-gate.md"
    if [[ -f "$GATE" ]]; then
      pass "Phase 3 gate evidence exists"
    else
      fail "Phase 3 gate evidence missing (.evidence/verification/phase-3-gate.md)"
    fi
    ;;

  4)
    # Phase 4 → ship: CERTIFICATION.md OR QA-REPORT.md (backwards compat)
    MILESTONE_DIR=$(find "$FEATURE_DIR" -maxdepth 1 -name "milestone-*" -type d | sort -V | tail -1)
    if [[ -n "$MILESTONE_DIR" ]]; then
      CHECK_DIR="$MILESTONE_DIR"
    else
      CHECK_DIR="$FEATURE_DIR"
    fi

    if [[ -f "$CHECK_DIR/CERTIFICATION.md" ]]; then
      pass "CERTIFICATION.md exists"
      # Check for UNRESOLVED entries
      UNRESOLVED=$(grep -ciE 'UNRESOLVED|unresolved' "$CHECK_DIR/CERTIFICATION.md" 2>/dev/null || echo 0)
      if [[ "$UNRESOLVED" -eq 0 ]]; then
        pass "No unresolved entries in CERTIFICATION.md"
      else
        fail "CERTIFICATION.md has $UNRESOLVED unresolved entries"
      fi
    elif [[ -f "$CHECK_DIR/QA-REPORT.md" ]]; then
      pass "QA-REPORT.md exists (legacy format accepted)"
    else
      fail "Neither CERTIFICATION.md nor QA-REPORT.md found"
    fi

    GATE="$EVIDENCE_DIR/verification/phase-4-certification.md"
    if [[ -f "$GATE" ]]; then
      pass "Phase 4 certification evidence exists"
    else
      # Also accept phase-4-gate.md as legacy
      if [[ -f "$EVIDENCE_DIR/verification/phase-4-gate.md" ]]; then
        pass "Phase 4 gate evidence exists (legacy name)"
      else
        fail "Phase 4 certification evidence missing"
      fi
    fi
    ;;

  *)
    fail "Unknown phase: $PHASE (expected 1, 2, 3, or 4)"
    ;;
esac

# Summary
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}Phase $PHASE evidence complete. OK to advance.${NC}"
  exit 0
else
  echo -e "${RED}Phase $PHASE evidence incomplete. $FAIL failure(s).${NC}"
  exit 1
fi
```

- [ ] **Step 3: Create `validate-memory.sh`**

```bash
#!/usr/bin/env bash
# Validates Feature Memory Unit structure.
#
# Usage:
#   bash scripts/validate/validate-memory.sh [feature-name]
#
# Without args: validates all FMUs. With arg: validates one FMU.
# Checks: required files, index consistency, bidirectional links, no orphans.
# Exit codes: 0 = pass, 1 = issues found

set -euo pipefail

FEATURE="${1:-}"
MEMORY_DIR=".memory"

PASS=0; FAIL=0; WARN=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARN=$((WARN + 1)); }

echo -e "${BOLD}Feature Memory Validation${NC}"
echo ""

# Check .memory/ exists
if [[ ! -d "$MEMORY_DIR" ]]; then
  echo "No .memory/ directory found. Feature Memory not yet initialized."
  exit 0
fi

# Check _index.md exists
INDEX="$MEMORY_DIR/_index.md"
if [[ -f "$INDEX" ]]; then
  pass "_index.md exists"
else
  fail "_index.md missing — create it with the FMU index table"
  exit 1
fi

# Get list of FMU directories
if [[ -n "$FEATURE" ]]; then
  FMUS="$MEMORY_DIR/$FEATURE"
  if [[ ! -d "$FMUS" ]]; then
    fail "FMU directory not found: $FMUS"
    exit 1
  fi
  FMU_LIST="$FEATURE"
else
  FMU_LIST=$(find "$MEMORY_DIR" -mindepth 1 -maxdepth 1 -type d -not -name '_*' -exec basename {} \; | sort)
fi

if [[ -z "$FMU_LIST" ]]; then
  echo "No FMU directories found."
  exit 0
fi

FMU_COUNT=$(echo "$FMU_LIST" | wc -l | tr -d ' ')
echo "Found $FMU_COUNT FMU(s) to validate"
echo ""

while IFS= read -r fmu; do
  FMU_DIR="$MEMORY_DIR/$fmu"
  echo -e "${BOLD}--- @$fmu ---${NC}"

  # Required: CONTEXT.md
  if [[ -f "$FMU_DIR/CONTEXT.md" ]]; then
    pass "CONTEXT.md exists"
  else
    fail "CONTEXT.md missing — every FMU needs a context file"
  fi

  # Optional but expected: LINKS.md
  if [[ -f "$FMU_DIR/LINKS.md" ]]; then
    pass "LINKS.md exists"

    # Check bidirectional links
    DEPS=$(grep -oE '@[a-zA-Z0-9_-]+' "$FMU_DIR/LINKS.md" 2>/dev/null | sort -u || true)
    for dep in $DEPS; do
      DEP_NAME="${dep#@}"
      DEP_LINKS="$MEMORY_DIR/$DEP_NAME/LINKS.md"
      if [[ -f "$DEP_LINKS" ]]; then
        if grep -q "@$fmu" "$DEP_LINKS" 2>/dev/null; then
          pass "Bidirectional link: @$fmu <-> $dep"
        else
          fail "One-way link: @$fmu -> $dep but $dep does not link back to @$fmu"
        fi
      else
        warn "$dep referenced in LINKS.md but has no LINKS.md of its own"
      fi
    done
  else
    warn "LINKS.md missing — add if this feature has dependencies"
  fi

  # Check _index.md has this FMU listed
  if grep -q "@$fmu" "$INDEX" 2>/dev/null; then
    pass "Listed in _index.md"
  else
    fail "@$fmu not listed in _index.md — add it to the index"
  fi

  echo ""
done <<< "$FMU_LIST"

# Check for orphans: FMUs in _index.md but no directory
echo -e "${BOLD}--- Orphan check ---${NC}"
INDEX_FMUS=$(grep -oE '@[a-zA-Z0-9_-]+' "$INDEX" 2>/dev/null | sed 's/@//' | sort -u || true)
for idx_fmu in $INDEX_FMUS; do
  if [[ ! -d "$MEMORY_DIR/$idx_fmu" ]]; then
    fail "Orphan in _index.md: @$idx_fmu listed but directory does not exist"
  fi
done

# Summary
echo ""
TOTAL=$((PASS + FAIL + WARN))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}Memory validation passed. $PASS checks OK, $WARN warnings.${NC}"
  exit 0
else
  echo -e "${RED}Memory validation found $FAIL issue(s). Fix before proceeding.${NC}"
  exit 1
fi
```

- [ ] **Step 4: Make all three scripts executable**

Run: `chmod +x scripts/validate/validate-tdd-coverage.sh scripts/validate/validate-evidence.sh scripts/validate/validate-memory.sh`

- [ ] **Step 5: Commit**

```bash
git add scripts/validate/validate-tdd-coverage.sh scripts/validate/validate-evidence.sh scripts/validate/validate-memory.sh
git commit -m "feat: add validation scripts — TDD coverage, evidence, and memory checks"
```

---

## Task 8: Create hook scripts

**Files:**
- Create: `scripts/hooks/auto-checkpoint.sh`
- Create: `scripts/hooks/evidence-tracker.sh`
- Create: `scripts/hooks/save-feature-memory.sh`

- [ ] **Step 1: Create `auto-checkpoint.sh`**

```bash
#!/usr/bin/env bash
# PostToolUse hook: auto-appends file changes to CHECKPOINT-{role}.md
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Write|Edit",
#       "command": "bash .claude/scripts/hooks/auto-checkpoint.sh"
#     }]
#   }
#
# Reads tool_input from stdin (JSON with file_path field).
# Requires QF_AGENT_ROLE env var to be set by cook.md.

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)

if [[ -z "$FILE_PATH" ]]; then
  exit 0  # No file path found, skip silently
fi

# Skip if not in an agent context
ROLE="${QF_AGENT_ROLE:-}"
if [[ -z "$ROLE" ]]; then
  exit 0  # Not running as a cook agent, skip
fi

# Find milestone dir from env
MILESTONE_DIR="${QF_MILESTONE_DIR:-}"
if [[ -z "$MILESTONE_DIR" || ! -d "$MILESTONE_DIR" ]]; then
  exit 0  # No milestone context, skip
fi

CHECKPOINT="$MILESTONE_DIR/CHECKPOINT-${ROLE}.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create checkpoint if it doesn't exist
if [[ ! -f "$CHECKPOINT" ]]; then
  cat > "$CHECKPOINT" << EOF
# Checkpoint — $ROLE
Updated: $TIMESTAMP

## Files Modified
EOF
fi

# Append the file change
echo "- $FILE_PATH ($TIMESTAMP)" >> "$CHECKPOINT"

# Update the timestamp
sed -i "s/^Updated: .*/Updated: $TIMESTAMP/" "$CHECKPOINT"
```

- [ ] **Step 2: Create `evidence-tracker.sh`**

```bash
#!/usr/bin/env bash
# PostToolUse hook: tracks evidence artifacts in PIPELINE-STATE.md
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Write|Edit",
#       "command": "bash .claude/scripts/hooks/evidence-tracker.sh"
#     }]
#   }
#
# Monitors writes to .evidence/ and updates PIPELINE-STATE.md with evidence status.

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only track writes to .evidence/
case "$FILE_PATH" in
  *.evidence/*|*/.evidence/*) ;;
  *) exit 0 ;;
esac

MILESTONE_DIR="${QF_MILESTONE_DIR:-}"
if [[ -z "$MILESTONE_DIR" || ! -d "$MILESTONE_DIR" ]]; then
  exit 0
fi

PIPELINE_STATE="$MILESTONE_DIR/PIPELINE-STATE.md"
if [[ ! -f "$PIPELINE_STATE" ]]; then
  exit 0
fi

# Extract REQ-ID or BUG-ID from filename
BASENAME=$(basename "$FILE_PATH")
ID=$(echo "$BASENAME" | grep -oE '(REQ|BUG)-[0-9]+' || true)

if [[ -z "$ID" ]]; then
  exit 0
fi

# Determine evidence type from path
TYPE=""
case "$FILE_PATH" in
  *tdd*red*) TYPE="red" ;;
  *tdd*green*) TYPE="green" ;;
  *verification*) TYPE="verified" ;;
  *debug*investigation*) TYPE="investigated" ;;
  *debug*resolution*) TYPE="resolved" ;;
esac

if [[ -z "$TYPE" ]]; then
  exit 0
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Append evidence tracking to PIPELINE-STATE if section exists
if grep -q "## Evidence Status" "$PIPELINE_STATE" 2>/dev/null; then
  # Update existing entry or add new one
  if grep -q "$ID" "$PIPELINE_STATE" 2>/dev/null; then
    # Entry exists — update the specific type
    sed -i "s/\($ID.*${TYPE}\) [XY-]/\1 Y/" "$PIPELINE_STATE"
  else
    # New entry
    echo "- $ID: $TYPE Y | ($TIMESTAMP)" >> "$PIPELINE_STATE"
  fi
else
  # Add Evidence Status section
  echo "" >> "$PIPELINE_STATE"
  echo "## Evidence Status" >> "$PIPELINE_STATE"
  echo "- $ID: $TYPE Y | ($TIMESTAMP)" >> "$PIPELINE_STATE"
fi
```

- [ ] **Step 3: Create `save-feature-memory.sh`**

```bash
#!/usr/bin/env bash
# Phase transition hook: auto-updates Feature Memory Unit on phase completion.
#
# Usage:
#   bash scripts/hooks/save-feature-memory.sh <feature-slug> <phase> <milestone-dir>
#
# Called by validate-stage-completion.sh after a phase passes validation.
# Extracts key info from phase artifacts and writes to .memory/{feature}/

set -euo pipefail

FEATURE="${1:-}"
PHASE="${2:-}"
MILESTONE_DIR="${3:-}"

if [[ -z "$FEATURE" || -z "$PHASE" ]]; then
  exit 0  # Missing args, skip silently
fi

MEMORY_DIR=".memory/$FEATURE"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
INDEX=".memory/_index.md"

# Create .memory/ and FMU directory if needed
mkdir -p "$MEMORY_DIR"

# Create _index.md if missing
if [[ ! -f "$INDEX" ]]; then
  cat > "$INDEX" << 'EOF'
# Feature Memory Index

| Feature | Status | Dependencies | Last updated |
|---------|--------|-------------|--------------|
EOF
fi

# Add to index if not present
if ! grep -q "@$FEATURE" "$INDEX" 2>/dev/null; then
  echo "| @$FEATURE | active | — | $TIMESTAMP |" >> "$INDEX"
fi

# Update timestamp in index
sed -i "s/\(@$FEATURE.*|\)[^|]*|$/\1 $TIMESTAMP |/" "$INDEX"

case "$PHASE" in
  0-init|init)
    # Create CONTEXT.md from plans artifacts
    FEATURE_DIR="$(dirname "$MILESTONE_DIR" 2>/dev/null || echo "plans/$FEATURE")"
    CONTEXT_SRC="$FEATURE_DIR/CONTEXT.md"
    if [[ -f "$CONTEXT_SRC" && ! -f "$MEMORY_DIR/CONTEXT.md" ]]; then
      cp "$CONTEXT_SRC" "$MEMORY_DIR/CONTEXT.md"
    fi
    ;;

  1-brainstorm|brainstorm)
    # Copy requirements to FMU
    FEATURE_DIR="$(dirname "$MILESTONE_DIR" 2>/dev/null || echo "plans/$FEATURE")"
    REQS_SRC="$FEATURE_DIR/REQUIREMENTS.md"
    if [[ -f "$REQS_SRC" ]]; then
      cp "$REQS_SRC" "$MEMORY_DIR/REQUIREMENTS.md"
    fi
    ;;

  2-design|design)
    # Copy design to FMU
    if [[ -n "$MILESTONE_DIR" && -f "$MILESTONE_DIR/DESIGN.md" ]]; then
      cp "$MILESTONE_DIR/DESIGN.md" "$MEMORY_DIR/DESIGN.md"
    fi
    ;;

  4-verify|verify)
    # Append verification summary to HISTORY.md
    HISTORY="$MEMORY_DIR/HISTORY.md"
    if [[ ! -f "$HISTORY" ]]; then
      echo "# Decision History — $FEATURE" > "$HISTORY"
      echo "" >> "$HISTORY"
    fi
    echo "- **$TIMESTAMP** — Phase 4 verified. Milestone certified." >> "$HISTORY"
    ;;

  5-maintain|maintain)
    # Bug fixes auto-append to GOTCHAS.md via the debugging protocol
    # This hook just updates HISTORY.md
    HISTORY="$MEMORY_DIR/HISTORY.md"
    if [[ ! -f "$HISTORY" ]]; then
      echo "# Decision History — $FEATURE" > "$HISTORY"
      echo "" >> "$HISTORY"
    fi
    echo "- **$TIMESTAMP** — Maintenance session completed." >> "$HISTORY"
    ;;
esac
```

- [ ] **Step 4: Make all three scripts executable**

Run: `chmod +x scripts/hooks/auto-checkpoint.sh scripts/hooks/evidence-tracker.sh scripts/hooks/save-feature-memory.sh`

- [ ] **Step 5: Commit**

```bash
git add scripts/hooks/auto-checkpoint.sh scripts/hooks/evidence-tracker.sh scripts/hooks/save-feature-memory.sh
git commit -m "feat: add progress hooks — auto-checkpoint, evidence tracking, FMU save"
```

---

## Task 9: Modify `_shared.md` — inject hard gates reference

**Files:**
- Modify: `commands/qf/_protocols/_shared.md`

- [ ] **Step 1: Add hard gates and evidence references to _shared.md**

After the `## Core Principles` section (line 8), add:

```markdown
## Discipline Layer
All phases are subject to the discipline protocols:
- **`_hard-gates.md`** — master red flag table, evidence spec, phase gate checklists. Read this if you catch yourself rationalizing a shortcut.
- **`_tdd-enforcement.md`** — RED-GREEN-REFACTOR cycle. Referenced by Phase 3 and dev agents.
- **`_systematic-debugging.md`** — 4-phase root cause process. Referenced by Phase 5 and all agents on failure.
- **`_verification-gates.md`** — evidence before assertions at every phase gate.
- **`_structured-logging.md`** — log format standard. Referenced by Phase 3 (implement), Phase 4 (audit), Phase 5 (debug).
- **`_context-memory.md`** — Feature Memory Units with @mention loading. Referenced by all phases.

<HARD-GATE>
Every phase transition MUST have evidence saved to .evidence/verification/.
See _verification-gates.md for the full protocol.
</HARD-GATE>
```

- [ ] **Step 2: Update gate keywords — remove SOLO option**

Find line 90 (`- Phase 3: `CONFIRM` (artifacts), then `SHIP / REFINE / SOLO` (execution)`) and replace with:

```markdown
- Phase 3: `CONFIRM` (artifacts), then `SHIP / REFINE` (execution)
```

- [ ] **Step 3: Update Milestone Detection target artifacts — add CERTIFICATION.md**

Find the target artifacts table (line 37) and add after Phase 4:

```markdown
- Phase 4 (verify): `CERTIFICATION.md` (or `QA-REPORT.md` for legacy milestones)
```

- [ ] **Step 4: Commit**

```bash
git add commands/qf/_protocols/_shared.md
git commit -m "feat: inject discipline layer references and update gate keywords in _shared.md"
```

---

## Task 10: Modify `3-handoff.md` — inject TDD, logging, verification; remove SOLO

**Files:**
- Modify: `commands/qf/3-handoff.md`

- [ ] **Step 1: Add discipline protocol references after GOTCHAs Review section (after line 15)**

Insert after the GOTCHAs Review section:

```markdown
## Discipline Protocols (injected into implementation)
When generating ROADMAP.md, inject these requirements into EVERY implementation phase:

<HARD-GATE>
All implementation phases MUST follow TDD (see _tdd-enforcement.md).
All application code MUST use structured logging (see _structured-logging.md).
All phase transitions MUST have verification evidence (see _verification-gates.md).
</HARD-GATE>

Each ROADMAP.md implementation phase must include:
1. **TDD mandate:** "Follow RED-GREEN-REFACTOR. Save evidence to .evidence/tdd/"
2. **Logging mandate:** "Implement structured logging per _structured-logging.md"
3. **Verification mandate:** "Save phase gate evidence to .evidence/verification/"

## Feature Memory — Context Loading
Before generating artifacts, load the feature's FMU via @mention (see `_context-memory.md`).
If no FMU exists for this feature, create one in `.memory/{feature-slug}/` with CONTEXT.md.
```

- [ ] **Step 2: Remove SOLO option from Execution Gate**

Replace the team mode options block (lines 74-78) from:
```markdown
   Options:
   - **SHIP** — Launch team pipeline (`/qf:cook`)
   - **REFINE** — Adjust team composition
   - **SOLO** — Switch to solo mode (implement manually)"
```

To:
```markdown
   Options:
   - **SHIP** — Launch team pipeline (`/qf:cook`)
   - **REFINE** — Adjust team composition"
```

- [ ] **Step 3: Remove SOLO handling (lines 81-92)**

Remove the `On **SOLO**:` block (lines 88-90):
```markdown
5. On **SOLO**:
   - Set `team_mode: false` in REQUIREMENTS.md
   - Fall through to solo Next Step below
```

And update `On **REFINE**:` to loop only SHIP/REFINE:
```markdown
   - Loop until user types SHIP
```

- [ ] **Step 4: Remove solo fallback (lines 96-98)**

Remove:
```markdown
**If `team_mode: false` (or not set):**
- Fall through to solo Next Step below
```

Replace with:
```markdown
**If `team_mode: false` (or not set):**
- Set `team_mode: true` automatically — multi-agent is the only mode
- Auto-compose minimal team: 1 dev + tester + pm
- Present team table and proceed to SHIP/REFINE gate
```

- [ ] **Step 5: Remove solo Next Step (lines 115-120)**

Remove the `**If team_mode: false (Solo):**` block entirely. Replace with note:

```markdown
**Solo mode has been removed.** All execution runs through `/qf:cook`.
```

- [ ] **Step 6: Commit**

```bash
git add commands/qf/3-handoff.md
git commit -m "feat: inject discipline protocols into Phase 3, remove solo mode"
```

---

## Task 11: Modify `4-verify.md` — evolve to "Verify & Certify"

**Files:**
- Modify: `commands/qf/4-verify.md`

- [ ] **Step 1: Update title and add discipline gate at the top**

Replace line 1:
```markdown
You are now entering Phase 4: Verify & QA.
```

With:
```markdown
You are now entering Phase 4: Verify & Certify.
```

- [ ] **Step 2: Add TDD compliance audit as new pre-flight (after Implementation Check)**

Insert after the "Pre-flight: Implementation Check" section:

```markdown
## Pre-flight: TDD Compliance Audit (auto — run BEFORE test generation)

<HARD-GATE>
Do NOT proceed to test generation until TDD evidence is verified.
Every REQ-ID must have red + green logs in .evidence/tdd/.
</HARD-GATE>

Run the TDD coverage validation script:
```bash
bash {quangflow-root}/scripts/validate/validate-tdd-coverage.sh ./plans/{feature-slug}
```
- If script exits 0: TDD coverage confirmed. Proceed.
- If script exits 1: present failures to user. Block until all REQ-IDs have evidence.
  - Tell user: "TDD evidence missing for {N} requirements. Dev agents must complete RED-GREEN-REFACTOR and save evidence to .evidence/tdd/ before verification can proceed."

## Pre-flight: Log Audit
Check structured logs for ERROR/FATAL entries:
- Read `.evidence/logs/test-run-*.jsonl` (if exists)
- Filter for `level: "ERROR"` or `level: "FATAL"`
- If found: flag as potential issues for investigation
- If no structured logs exist: warn "No structured test logs found. Verify logging was implemented per _structured-logging.md."
```

- [ ] **Step 3: Update Step 2 — Tester no longer generates unit tests**

Replace the "Step 2: Test Coverage" section with:

```markdown
### Step 2: Test Coverage Audit & Supplement
Dev agents already generated unit tests via TDD. The Tester agent generated integration/E2E tests.

**Audit existing coverage:**
- Verify every REQ-ID has at least one unit test (from TDD evidence)
- Verify integration tests exist for cross-module flows
- Verify E2E tests exist for user-facing workflows

**Supplement if gaps found:**
- If a REQ-ID has TDD evidence but no integration coverage: generate integration test
- If user flows exist but no E2E test: generate E2E test
- Do NOT regenerate unit tests that already exist from TDD
```

- [ ] **Step 4: Update output — CERTIFICATION.md replaces QA-REPORT.md for new milestones**

Replace the "Automatic Review Output" section with:

```markdown
## Automatic Review Output
Generate to ./plans/{feature-slug}/milestone-{N}/:

**For new milestones (discipline layer active):**
- CERTIFICATION.md — traceability matrix, evidence audit, log audit, gap summary (see `_verification-gates.md` for full schema)
- GAPS.md — created or updated with gap findings from Step 5

**For legacy milestones (backwards compatibility):**
- QA-REPORT.md — test results, requirement coverage matrix, violations found
- GAPS.md — as before

Save verification evidence to `.evidence/verification/phase-4-certification.md` per `_verification-gates.md`.
```

- [ ] **Step 5: Update Milestone Detection target artifact**

Replace line 8:
```markdown
See `_protocols/_shared.md → Milestone Detection`. Target artifact: `QA-REPORT.md`.
```

With:
```markdown
See `_protocols/_shared.md → Milestone Detection`. Target artifact: `CERTIFICATION.md` (or `QA-REPORT.md` for legacy).
```

- [ ] **Step 6: Remove solo mode references in Pre-flight**

Replace line 28-29:
```markdown
- If tests exist: reuse them, run them, and supplement with any missing coverage
- If no tests exist (solo mode): generate tests from scratch (see Step 2)
```

With:
```markdown
- If tests exist: reuse them, run them, and supplement with any missing coverage
- If no tests exist: generate tests from requirements (see Step 2)
```

- [ ] **Step 7: Commit**

```bash
git add commands/qf/4-verify.md
git commit -m "feat: evolve Phase 4 to Verify & Certify with TDD audit and evidence checks"
```

---

## Task 12: Modify `5-maintain.md` — inject systematic debugging

**Files:**
- Modify: `commands/qf/5-maintain.md`

- [ ] **Step 1: Add debugging protocol reference at the top (after Purpose section)**

Insert after line 6:

```markdown
## Discipline Protocol
All bug investigation and fixing in this phase follows `_protocols/_systematic-debugging.md`.

<HARD-GATE>
Do NOT propose a fix until the investigation phase is complete and findings
are documented in .evidence/debug/. See _systematic-debugging.md for the
full 4-phase process.
</HARD-GATE>
```

- [ ] **Step 2: Update Hotfix Flow Step 1 (Investigate) to reference debugging protocol**

Replace the Step 1 section (lines 251-268) with:

```markdown
### Step 1: Investigate (follows _systematic-debugging.md Phase 1-2)
- Read the bug entry from BUGLOG.md
- Follow the systematic debugging protocol:
  1. **Reproduce** — confirm the bug exists, capture output
  2. **Read structured logs** — filter by `level=ERROR`, `module={affected}`, `source={frontend|backend}` (see `_structured-logging.md`)
  3. **Read stack traces** — identify exact file, function, line
  4. **Gather context** — load feature memory via `@{feature}` mention, check recent git changes
  5. **Document** — save findings to `.evidence/debug/BUG-{ID}-investigation.md`
- Present investigation summary to user:

```
**BUG-XXX Investigation:**
- **Root cause:** {explanation — from evidence, not guessing}
- **Evidence:** {log lines, stack traces, git changes}
- **Affected files:** {list}
- **Proposed fix:** {brief description}
- **Risk:** {what else could break}
- **Tests needed:** {what to test after fix}

Proceed with fix? (YES / ADJUST / SKIP)
```

Agent waits for user response.
```

- [ ] **Step 3: Update Hotfix Flow Step 2 (Fix) to require TDD**

Replace the Step 2 section (lines 270-275) with:

```markdown
### Step 2: Fix (follows _systematic-debugging.md Phase 3-4 + _tdd-enforcement.md)
- **Write a failing test** for the bug FIRST (RED phase)
  - Save output to `.evidence/tdd/BUG-{ID}-red.log`
- **Fix the root cause** — not a workaround, not a patch
  - Follow _systematic-debugging.md: one hypothesis, one variable at a time
  - If 3+ fix attempts fail: STOP and question the architecture (escalation rule)
- **Run the test** — must pass (GREEN phase)
  - Save output to `.evidence/tdd/BUG-{ID}-green.log`
- Run existing tests to check for regressions
- If regressions found: fix them before proceeding
```

- [ ] **Step 4: Update Step 4 (Log Gotcha) to include debugging resolution doc**

After the existing Step 4 content, add:

```markdown
- Also save resolution details to `.evidence/debug/BUG-{ID}-resolution.md` per `_systematic-debugging.md`
```

- [ ] **Step 5: Commit**

```bash
git add commands/qf/5-maintain.md
git commit -m "feat: inject systematic debugging and TDD into Phase 5 maintain"
```

---

## Task 13: Modify `quick.md` — remove solo, require minimal team

**Files:**
- Modify: `commands/qf/quick.md`

- [ ] **Step 1: Replace the solo preamble and implementation section**

Replace lines 1-6:
```markdown
You are in Quick Mode — a single-pass flow for small features, bug fixes, and minor changes.

Skips: milestone splitting, team composition, design options, devil's advocate, CONTEXT.md.
Produces: minimal REQUIREMENTS.md + flat ROADMAP.md in `./plans/{feature-slug}/`.
Strictly solo — no team pipeline.
```

With:
```markdown
You are in Quick Mode — a streamlined flow for small features, bug fixes, and minor changes.

Skips: milestone splitting, design options, devil's advocate, CONTEXT.md.
Produces: minimal REQUIREMENTS.md + flat ROADMAP.md in `./plans/{feature-slug}/`.
Runs a minimal team: 1 dev agent + tester agent (multi-agent always).

<HARD-GATE>
Even quick tasks follow TDD (see _tdd-enforcement.md) and require
verification evidence (see _verification-gates.md). No exceptions.
</HARD-GATE>
```

- [ ] **Step 2: Replace Step 4 (Implement) with team dispatch**

Replace lines 63-67:
```markdown
## Step 4: Implement
- Implement tasks from ROADMAP.md sequentially
- Run compile/lint after each file change
- Check off tasks as completed
```

With:
```markdown
## Step 4: Dispatch Minimal Team
Launch minimal team via `/qf:cook` (auto-configured):
- **dev-quick** (1 dev agent): implements ROADMAP tasks following TDD (`_tdd-enforcement.md`)
- **tester-quick** (tester agent): verifies dev's TDD coverage, generates integration test if needed

Pipeline: dev-quick → tester-quick → verify

The dev agent follows RED-GREEN-REFACTOR for each task. Evidence saved to `.evidence/tdd/`.
```

- [ ] **Step 3: Update Step 5 (Verify) to require evidence**

Replace lines 69-72:
```markdown
## Step 5: Verify
- Run relevant tests
- If tests pass: mark ROADMAP.md tasks as done
- If tests fail: fix and re-run
```

With:
```markdown
## Step 5: Verify
- Tester agent verifies TDD evidence exists for all REQ-IDs
- Run full test suite (unit from TDD + any integration from tester)
- Save verification evidence to `.evidence/verification/quick-gate.md`
- If tests pass: mark ROADMAP.md tasks as done
- If tests fail: dev agent fixes following `_systematic-debugging.md`
```

- [ ] **Step 4: Commit**

```bash
git add commands/qf/quick.md
git commit -m "feat: remove solo from quick mode, require minimal team + TDD"
```

---

## Task 14: Modify `dev-teammate.md` — inject TDD enforcement

**Files:**
- Modify: `agents/dev-teammate.md`

- [ ] **Step 1: Add TDD protocol to Implementation Protocol (after Step 1: Plan)**

Insert after line 37 (before `### Step 2: Implement`):

```markdown
### Step 1.5: TDD Setup
Before implementing any code:
- Read `_protocols/_tdd-enforcement.md` — this is non-negotiable
- Ensure `.evidence/tdd/` directory exists
- For each REQ-ID in your assigned requirements, you will follow RED-GREEN-REFACTOR

<HARD-GATE>
Do NOT write implementation code until a failing test exists and its
failure output is saved to .evidence/tdd/. No exceptions.
</HARD-GATE>
```

- [ ] **Step 2: Update Step 2 (Implement) to integrate TDD cycle**

Replace lines 39-54 with:

```markdown
### Step 2: Implement (TDD + checkpointing)
After plan approval, for EACH requirement in your assigned REQ-IDs:

**RED-GREEN-REFACTOR cycle (mandatory):**
1. Write a failing test for the requirement: `test_REQ{ID}_{description}`
2. Run it — must FAIL. Save output: `.evidence/tdd/REQ-{ID}-red.log`
3. Write minimal implementation code to make the test pass
4. Run it — must PASS. Save output: `.evidence/tdd/REQ-{ID}-green.log`
5. Refactor if needed (tests must stay green)
6. Commit test + code together

**Between TDD cycles:**
1. Read DECISIONS.md — check if other agents logged decisions affecting your scope
2. Follow the module boundaries from MODULES.md
3. Implement interfaces exactly as specified in CONTRACTS.md
4. Follow the sequence flows from SEQUENCES.md
5. Handle error paths shown in sequence diagrams
6. Implement structured logging per `_protocols/_structured-logging.md`
7. **Semantic safety (if `code_graph: gitnexus` in CK Context Block):**
   - Before editing any shared/exported function: run `mcp__gitnexus__context` to see callers
   - Before modifying a public interface: run `mcp__gitnexus__impact` (d=2) for blast radius
   - If impact reaches outside your ownership: message lead before proceeding
   - For renames: use `mcp__gitnexus__rename` instead of manual find-replace
   - Skip for new files, private functions, and test files
8. Write clean, compilable code — run compile/lint checks after each file
9. **After each major step** (file created, phase completed): update CHECKPOINT-{role}.md

**Checkpointing:** Write progress to `plans/{slug}/milestone-{N}/CHECKPOINT-{role}.md` after each file or phase completion. If you crash, a replacement agent will resume from your checkpoint.

**Decisions:** When you make an implementation decision not covered by CONTRACTS.md (e.g., error format, caching strategy, naming convention), append it to DECISIONS.md so other agents can see it.
```

- [ ] **Step 3: Update Self-Check to include TDD and logging**

Replace lines 60-67 with:

```markdown
### Step 3: Self-Check
Before marking complete:
- [ ] All files are within my ownership globs
- [ ] Public interfaces match CONTRACTS.md signatures
- [ ] Error handling covers paths from SEQUENCES.md
- [ ] Code compiles without errors
- [ ] No hardcoded values, magic strings, or TODO hacks
- [ ] CHECKPOINT-{role}.md is up to date
- [ ] DECISIONS.md updated with any implementation decisions
- [ ] Every REQ-ID has .evidence/tdd/REQ-{ID}-red.log AND REQ-{ID}-green.log
- [ ] All tests passing (green logs contain no failures)
- [ ] Structured logging implemented per _structured-logging.md (no raw console.log)
```

- [ ] **Step 4: Commit**

```bash
git add agents/dev-teammate.md
git commit -m "feat: inject TDD enforcement and structured logging into dev agent"
```

---

## Task 15: Modify `tester.md` — evolve role

**Files:**
- Modify: `agents/tester.md`

- [ ] **Step 1: Update role description**

Replace lines 1-9:
```markdown
# Tester

You are the tester — you generate and run tests based on requirements, not implementation details.

## Role
- Agent type: `tester`
- Timing: Runs AFTER tech-lead review (or after devs if tech-lead skipped)
- Output: Test files in `tests/*` or `__tests__/*`
- Required: Always present, cannot be removed from team
```

With:
```markdown
# Tester

You are the tester — you verify TDD coverage, generate integration/E2E tests, and certify requirement traceability. Dev agents handle unit tests via TDD; you handle everything above unit level.

## Role
- Agent type: `tester`
- Timing: Runs AFTER tech-lead review (or after devs if tech-lead skipped)
- Output: Integration/E2E test files in `tests/integration/*` and `tests/e2e/*`; TDD audit report
- Required: Always present, cannot be removed from team
```

- [ ] **Step 2: Replace Test Generation Strategy**

Replace lines 20-48 with:

```markdown
## Test Strategy

### Phase A: TDD Coverage Audit (always — run FIRST)
Before writing any tests, audit what devs already produced:
1. Run `bash scripts/validate/validate-tdd-coverage.sh ./plans/{feature-slug}`
2. Check `.evidence/tdd/` for every REQ-ID assigned to dev agents
3. For each REQ-ID, verify:
   - Red log exists and contains FAIL indicator
   - Green log exists and contains PASS indicator with no failures
4. Report gaps: "REQ-{ID} is missing {red|green} evidence — dev must complete TDD cycle"

<HARD-GATE>
Do NOT generate unit tests for REQ-IDs that already have TDD evidence.
Dev agents own unit tests. You own integration, E2E, and coverage auditing.
</HARD-GATE>

### Phase B: Integration Tests (when 2+ modules interact)
- Test API contracts between modules (match CONTRACTS.md)
- Test data flow across module boundaries
- Verify request/response shapes match contract types
- Test database operations end-to-end
- For milestone-2+: test integration with previous milestone's code
- **If `code_graph: gitnexus`:** use `mcp__gitnexus__impact` on modified symbols to identify regression risk areas

### Phase C: E2E / Suite Tests (when user-facing flows exist)
- Test complete user workflows from REQUIREMENTS.md
- Follow SEQUENCES.md diagrams as test scripts
- Validate success metrics from requirements
- Test the full stack: frontend → API → service → DB → response

### Phase D: Traceability Matrix
Build the requirement-to-test mapping:

| REQ-ID | Unit Test (from TDD) | Integration Test | E2E Test | Coverage |
|--------|---------------------|------------------|----------|----------|
| REQ-001 | test_REQ001_* | int_auth_flow | e2e_login | FULL |
| REQ-002 | test_REQ002_* | — | — | UNIT ONLY |

Flag any REQ-ID with UNIT ONLY or NO COVERAGE for lead attention.
```

- [ ] **Step 3: Update Output Format**

Replace lines 84-96 with:

```markdown
## Output Format
Send to lead:
```
Test & Audit Results — Milestone {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TDD Audit: {X}/{Y} REQ-IDs have valid evidence
Integration: {A} tests | Pass: {B} | Fail: {C}
E2E: {D} tests | Pass: {E} | Fail: {F}

TDD Gaps:
- REQ-XXX: missing {red|green} evidence

Coverage Gaps:
- REQ-XXX has unit only — no integration/E2E coverage

Traceability: {X}/{Y} REQ-IDs fully covered
```
```

- [ ] **Step 4: Commit**

```bash
git add agents/tester.md
git commit -m "feat: evolve tester to TDD auditor + integration/E2E focus"
```

---

## Task 16: Modify `validate-stage-completion.sh` — add evidence checks

**Files:**
- Modify: `scripts/validate/validate-stage-completion.sh`

- [ ] **Step 1: Add evidence check to `devs` stage**

After the existing devs checks (file ownership, line ~140), add:

```bash
      # Check 4: TDD evidence exists for assigned REQ-IDs
      if [[ -n "$OWNERSHIP" ]]; then
        EVIDENCE_DIR="$(cd "$MILESTONE_DIR/../.." && pwd)/.evidence/tdd"
        if [[ -d "$EVIDENCE_DIR" ]]; then
          # Count evidence files that match any log pattern
          EVIDENCE_COUNT=$(find "$EVIDENCE_DIR" -name "REQ-*-green.log" 2>/dev/null | wc -l | tr -d ' ')
          if [[ "$EVIDENCE_COUNT" -gt 0 ]]; then
            pass "TDD evidence: $EVIDENCE_COUNT REQ-IDs have green logs"
          else
            fail "TDD evidence: no green logs found in .evidence/tdd/ — devs must follow TDD"
          fi
        else
          fail ".evidence/tdd/ directory missing — devs must save TDD evidence"
        fi
      fi
```

- [ ] **Step 2: Update `verify` stage to check for CERTIFICATION.md**

Replace the verify stage check (lines 200-206) with:

```bash
  verify)
    # CERTIFICATION.md or QA-REPORT.md must exist (backwards compat)
    if [[ -f "$MILESTONE_DIR/CERTIFICATION.md" ]]; then
      pass "CERTIFICATION.md exists"
      # Check for unresolved entries
      UNRESOLVED=$(grep -ciE 'UNRESOLVED' "$MILESTONE_DIR/CERTIFICATION.md" 2>/dev/null || echo 0)
      if [[ "$UNRESOLVED" -eq 0 ]]; then
        pass "No unresolved entries in CERTIFICATION.md"
      else
        fail "CERTIFICATION.md has $UNRESOLVED unresolved entries"
      fi
    elif [[ -f "$MILESTONE_DIR/QA-REPORT.md" ]]; then
      pass "QA-REPORT.md exists (legacy format accepted)"
    else
      fail "Neither CERTIFICATION.md nor QA-REPORT.md found — verify must produce one"
    fi

    # Evidence directory check
    PROJECT_ROOT="$(cd "$MILESTONE_DIR/../.." && pwd)"
    EVIDENCE_DIR="$PROJECT_ROOT/.evidence"
    if [[ -d "$EVIDENCE_DIR/verification" ]]; then
      GATE_COUNT=$(find "$EVIDENCE_DIR/verification" -name "phase-*" 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$GATE_COUNT" -gt 0 ]]; then
        pass "Verification evidence: $GATE_COUNT phase gate file(s)"
      else
        fail "Verification evidence directory exists but no phase gate files found"
      fi
    else
      fail ".evidence/verification/ missing — phase gates must save evidence"
    fi

    # Existing GAPS + GOTCHAS check (preserved from original)
```

- [ ] **Step 3: Add `save-feature-memory.sh` call at the end of successful validation**

Before the final summary (line 264), add:

```bash
# Auto-save to Feature Memory on successful validation
if [[ $FAIL -eq 0 ]]; then
  FEATURE_SLUG=$(basename "$FEATURE_DIR")
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  MEMORY_HOOK="$SCRIPT_DIR/../hooks/save-feature-memory.sh"
  if [[ -x "$MEMORY_HOOK" ]]; then
    bash "$MEMORY_HOOK" "$FEATURE_SLUG" "$STAGE" "$MILESTONE_DIR" 2>/dev/null || true
  fi
fi
```

- [ ] **Step 4: Commit**

```bash
git add scripts/validate/validate-stage-completion.sh
git commit -m "feat: add TDD evidence and CERTIFICATION.md checks to stage validation"
```

---

## Task 17: Final integration test — verify all files parse correctly

**Files:** (no new files — validation only)

- [ ] **Step 1: Verify all new protocol files exist and have content**

Run:
```bash
for f in commands/qf/_protocols/_hard-gates.md commands/qf/_protocols/_tdd-enforcement.md commands/qf/_protocols/_systematic-debugging.md commands/qf/_protocols/_verification-gates.md commands/qf/_protocols/_structured-logging.md commands/qf/_protocols/_context-memory.md; do
  echo "$f: $(wc -l < "$f") lines"
done
```

Expected: All files exist with 70+ lines each.

- [ ] **Step 2: Verify all new scripts exist and are executable**

Run:
```bash
for f in scripts/validate/validate-tdd-coverage.sh scripts/validate/validate-evidence.sh scripts/validate/validate-memory.sh scripts/hooks/auto-checkpoint.sh scripts/hooks/evidence-tracker.sh scripts/hooks/save-feature-memory.sh; do
  if [[ -x "$f" ]]; then
    echo "$f: OK (executable)"
  else
    echo "$f: MISSING or not executable"
  fi
done
```

Expected: All files OK.

- [ ] **Step 3: Verify modified files don't have syntax issues**

Run:
```bash
# Check for broken markdown references
grep -rn '_protocols/_tdd-enforcement.md\|_protocols/_systematic-debugging.md\|_protocols/_verification-gates.md\|_protocols/_hard-gates.md\|_protocols/_structured-logging.md\|_protocols/_context-memory.md' commands/qf/ agents/
```

Expected: References found in 3-handoff.md, 4-verify.md, 5-maintain.md, quick.md, dev-teammate.md, tester.md, _shared.md.

- [ ] **Step 4: Run existing validation scripts to ensure they still work**

Run:
```bash
bash scripts/validate/validate-install.sh 2>/dev/null || echo "Install validation not applicable (dev environment)"
```

- [ ] **Step 5: Verify no SOLO references remain in modified files**

Run:
```bash
grep -rn 'SOLO\|solo mode\|team_mode: false' commands/qf/3-handoff.md commands/qf/quick.md commands/qf/_protocols/_shared.md
```

Expected: No matches (solo mode fully removed).

- [ ] **Step 6: Commit final state**

```bash
git add -A
git status
# If any unstaged changes, review and add
git commit -m "chore: verify discipline layer integration — all files validated"
```
