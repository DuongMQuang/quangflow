# QuangFlow Discipline Layer — Design Spec

> **Date:** 2026-03-28
> **Status:** Approved
> **Branch:** TDD-brainstorm

## Summary

Embed a discipline layer into QuangFlow inspired by the Superpowers framework. Four core features — TDD enforcement, systematic debugging, verification gates, and hard gates/red flag detection — plus two supporting systems (structured logging and feature memory) are woven into existing phases. No new user-facing commands; all enforcement is iron-law strict via prompt + script. Additionally, refactor QuangFlow from a bash-installed tool into a Claude Code plugin for streamlined install/update/multi-platform support.

## Goals

1. Enforce test-driven development during implementation (tests before code, always)
2. Provide a systematic debugging protocol that prevents guess-and-fix spirals
3. Require evidence-based verification at every phase gate (no claims without proof)
4. Prevent rationalization with hard gates and red flag detection across all phases
5. Standardize structured logging for runtime evidence (info/warn/error/fatal, FE→BE bridge)
6. Scale context management via Feature Memory Units with @mention loading
7. Migrate to Claude Code plugin architecture for one-command install and multi-platform support

## Non-Goals

- No new user-facing slash commands (all features embed into existing phases)
- No changes to the phase order (0→1→2→3→4→5 stays the same)
- No removal of existing features (GOTCHAs, autopilot, team mode all preserved)

## Core Principle

**Multi-agent is the only mode.** Solo mode is eliminated. Every task — regardless of size — runs through the agent team pipeline. The team composition scales (fewer agents for small tasks, full team for large ones), but there is always a team. This means:

- Phase 3 handoff always produces team assignments (no SOLO option)
- `/qf:cook` is the only execution path (no manual single-agent implementation)
- `/qf:quick` still exists for small tasks but runs a minimal team (dev + tester), not solo
- The REFINE/SOLO/SHIP choice in Phase 3 becomes REFINE/SHIP only

---

## Architecture

### 6 New Internal Protocols

All protocols live in `commands/qf/_protocols/` (or `skills/_protocols/` post-plugin migration).

#### 1. `_tdd-enforcement.md`

**Injected into:** Phase 3 (handoff/implementation), `dev-teammate.md` agent

**Core rule:** No production code without a failing test first.

**TDD cycle per code change:**

1. Write a test that captures the requirement (RED)
2. Run it — must fail. Save output to `.evidence/tdd/REQ-XXX-red.log`
3. Write minimal code to pass (GREEN)
4. Run it — must pass. Save output to `.evidence/tdd/REQ-XXX-green.log`
5. Refactor if needed (tests must stay green)
6. Commit: test + code together, never separately

**Hard gate:**
```
<HARD-GATE>
Do NOT write implementation code until a failing test exists and its
failure output is saved to .evidence/tdd/. No exceptions. No "I'll
write tests after." No "this is too simple to test."
</HARD-GATE>
```

**Red flags:**
- "This is too simple to need a test"
- "I'll add tests after the implementation works"
- "The test would just test the framework"
- "Let me get the code working first, then add tests"

---

#### 2. `_systematic-debugging.md`

**Injected into:** Phase 5 (maintain), available to all agents on failure

**4-phase process:**

1. **Investigate** — gather evidence, read logs, reproduce the bug. No guessing. Save findings to `.evidence/debug/BUG-XXX-investigation.md`
2. **Analyze** — find working examples, compare differences, identify patterns
3. **Hypothesize & test** — form one theory, test minimally, one variable at a time
4. **Fix & verify** — write failing test for the bug, fix root cause, verify green

**Escalation rule:** 3+ failed fix attempts → stop fixing code, question the architecture.

**Auto-GOTCHA:** On resolution, write root cause + fix + domain tags to GOTCHAS.md.

**Hard gate:**
```
<HARD-GATE>
Do NOT propose a fix until you have completed the investigation phase
and documented findings in .evidence/debug/. "Just try changing X" is
not debugging — it's guessing.
</HARD-GATE>
```

**Red flags:**
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "It's probably X, let me fix that"
- "This worked in another project, so..."

---

#### 3. `_verification-gates.md`

**Injected into:** Every phase transition, Phase 4 certification

**Core rule:** Evidence before assertions. Never claim success without fresh proof.

**At every phase gate:**

1. Run the verification command (test suite, build, lint, etc.)
2. Save output to `.evidence/verification/phase-N-gate.md`
3. Only then state the result — quoting actual output, not paraphrasing

**Banned language in completion claims:**
- "should work", "probably passes", "seems correct"
- "great!", "perfect!", "looks good!" (without evidence)
- "I believe this is complete" (without test output)

**Hard gate:**
```
<HARD-GATE>
Do NOT claim any phase is complete, any test passes, or any bug is
fixed without running a verification command and saving its output to
.evidence/verification/. Confidence is not evidence.
</HARD-GATE>
```

---

#### 4. `_hard-gates.md`

**Injected into:** All phases via `_shared.md`

**Contains:**
- Master red flag table (rationalization patterns across all features)
- Evidence artifact format specification (`.evidence/` directory structure)
- Phase-specific gate checklists (what must exist before transitioning)
- Script hooks reference (which scripts enforce which gates)

**Phase transition requirements:**

| Transition | Required evidence |
|---|---|
| Phase 1 → 2 | REQUIREMENTS.md with REQ-IDs, acceptance criteria |
| Phase 2 → 3 | DESIGN.md with chosen option, DEBATE.md (if team mode) |
| Phase 3 → 4 | `.evidence/tdd/` logs for every REQ-ID, all tests green |
| Phase 4 → ship | CERTIFICATION.md with full traceability matrix, zero unresolved gaps |

**Master red flag table:**

| Red flag thought | Reality |
|---|---|
| "This is too simple to need a test" | Simple code has the most hidden assumptions |
| "I'll add tests/logging/docs after" | You won't. Do it now. |
| "Quick fix for now" | Quick fixes become permanent debt |
| "It's probably X" | Investigate, don't guess |
| "Should work" / "seems correct" | Run it. Show the output. |
| "I know what this does" | Read the code. Memory lies. |
| "This doesn't need the full process" | Every shortcut becomes a bug |

---

#### 5. `_structured-logging.md`

**Injected into:** Phase 3 (devs must implement logging), Phase 4 (verify log coverage), Phase 5 (debugging reads logs)

**Log format standard — every log entry must have:**

```json
{
  "timestamp": "ISO-8601",
  "level": "INFO | WARN | ERROR | FATAL",
  "source": "frontend | backend | test | e2e",
  "module": "auth/login",
  "req_id": "REQ-003",
  "trace_id": "uuid-for-request-chain",
  "message": "human-readable description",
  "context": {},
  "stack": "only for ERROR/FATAL"
}
```

**Frontend → Backend log bridge:**
- FE errors (uncaught exceptions, failed API calls, console.error) sent to `/logs` endpoint on BE
- BE writes them to the same structured log file
- `source: "frontend"` distinguishes from backend logs
- `trace_id` links FE action → BE request → response for cross-stack tracing

**Log levels:**

| Level | When | Debugging use |
|---|---|---|
| `INFO` | Normal operations, state transitions | Verify happy path works |
| `WARN` | Recoverable issues, fallback triggered | Spot degradation before failure |
| `ERROR` | Failed operations, caught exceptions | Primary debugging signal |
| `FATAL` | Unrecoverable, app should stop | Crash investigation |

**Log-based verification:**
- Test suites write structured logs during runs
- E2E tests produce log output per scenario
- Verification gates check for ERROR/FATAL entries
- Debugging protocol filters by level/source/module

**Hard gate:**
```
<HARD-GATE>
All application code MUST use the structured logging format. Do NOT use
raw console.log/print/println for operational output. Unstructured logs
cannot be parsed by the debugging protocol or verification gates.
</HARD-GATE>
```

**Red flags:**
- "console.log is fine for now"
- "We don't need logging for this module"
- "I'll add logging after it works"
- "The test output is enough, no need for structured logs"

---

#### 6. `_context-memory.md`

**Injected into:** Phase 0 (create FMU), all phases (load via @mention), Phase 4 (audit coverage)

**Feature Memory Units (FMUs):**

Each feature/module gets a self-contained context directory:

```
.memory/
├── _index.md                    # master registry of all FMUs
├── auth/
│   ├── CONTEXT.md               # what this feature is, dependencies, owners
│   ├── REQUIREMENTS.md          # only REQ-IDs for this feature
│   ├── DESIGN.md                # architecture decisions for this feature
│   ├── GOTCHAS.md               # lessons specific to this feature
│   ├── HISTORY.md               # key decisions timeline
│   └── LINKS.md                 # cross-references to related FMUs
├── payments/
│   └── ...
└── api-gateway/
    └── ...
```

**@mention loading system:**

When `@feature-name` is referenced:

1. Resolve against `.memory/_index.md`
2. Load ONLY that FMU's context files
3. Load LINKS.md to see dependencies (but don't auto-load linked FMUs — one level only)

**`_index.md` schema:**

```markdown
# Feature Memory Index

| Feature | Status | Dependencies | Last updated |
|---------|--------|-------------|--------------|
| @auth | active | — | 2026-03-28 |
| @payments | active | @auth, @api-gateway | 2026-03-28 |
```

**Save rules:**

| Event | What gets saved |
|---|---|
| Phase 0 init | Create FMU directory + CONTEXT.md |
| Phase 1 brainstorm | Write REQUIREMENTS.md to FMU |
| Phase 2 design | Write DESIGN.md to FMU |
| Any GOTCHA logged | Append to feature-specific GOTCHAS.md |
| Key decision made | Append to HISTORY.md with date + rationale |
| Cross-feature dependency found | Update LINKS.md on both sides |
| Bug resolved via debugging | Append to GOTCHAS.md + HISTORY.md |

**Load rules:**

| Situation | Load |
|---|---|
| `@feature` mentioned | That FMU's full context |
| Linked feature referenced | Linked FMU's CONTEXT.md only (summary) |
| Phase 4 verify | All FMUs in current milestone |
| Phase 5 maintain | FMU matching the bug's module |
| `/qf:status` | `_index.md` only (overview) |
| New dev agent spawned | Only FMUs matching their file ownership globs |

**Hard gate:**
```
<HARD-GATE>
Do NOT start work on any feature without loading its FMU via @mention.
Do NOT load all FMUs at once. If the feature has no FMU yet, create one
in Phase 0 before proceeding.
</HARD-GATE>
```

---

## Evidence Artifact System

All protocols write to a standardized `.evidence/` directory:

```
.evidence/
├── tdd/
│   ├── REQ-001-red.log          # failing test output
│   ├── REQ-001-green.log        # passing test output
│   └── ...
├── debug/
│   ├── BUG-001-investigation.md # investigation findings
│   └── BUG-001-resolution.md    # root cause + fix
├── verification/
│   ├── phase-1-gate.md          # evidence at each phase transition
│   ├── phase-3-gate.md
│   └── phase-4-certification.md # final certification
└── logs/
    ├── test-run-YYYY-MM-DD.jsonl    # structured test logs
    ├── e2e-run-YYYY-MM-DD.jsonl     # E2E scenario logs
    └── fe-errors-YYYY-MM-DD.jsonl   # frontend errors bridged to BE
```

Scripts validate evidence exists before allowing phase transitions.

---

## Tester Agent Evolution

With TDD, dev agents own unit tests. The Tester agent evolves:

**Removed responsibilities:**
- Unit test generation (devs handle via TDD)

**New responsibilities:**
- Verify dev TDD coverage is sufficient (no gaps)
- Integration test generation across module boundaries
- E2E requirement traceability matrix (REQ-ID → E2E scenario → pass/fail)
- Flag REQ-IDs with no test coverage from any source
- Cross-milestone regression testing

---

## Phase 4 Evolution — "Verify & Certify"

Phase 4 shifts from "generate and run tests" to "audit evidence, run full suite, certify."

**New Phase 4 flow:**

1. **TDD compliance audit** — script-verify every code file has corresponding red→green logs in `.evidence/tdd/`
2. **Run full test suite** — unit (from TDD) + integration + E2E (from Tester)
3. **Requirements traceability** — map every REQ-ID to test coverage (unit + integration + E2E)
4. **Log audit** — check structured logs for ERROR/FATAL entries
5. **Evidence completeness** — verify `.evidence/verification/` has all phase gate files
6. **Gap detection** — classify remaining gaps as minor/major
7. **Produce CERTIFICATION.md** — signed-off traceability matrix, not just QA-REPORT.md

**CERTIFICATION.md replaces QA-REPORT.md** as the final gate artifact. Existing projects with QA-REPORT.md are unaffected — the new format applies only to milestones started after the discipline layer is installed. Phase 4 recognizes both formats for backwards compatibility.

---

## Progress Saving Hooks

Three new hooks enforce automatic state persistence:

### 1. `auto-checkpoint.sh` (PostToolUse on Write/Edit)

After every file write by a dev agent, auto-append to CHECKPOINT-{role}.md. Agents don't need to remember to checkpoint — the system does it.

### 2. `evidence-tracker.sh` (PostToolUse on Write to `.evidence/`)

When files are written to `.evidence/`, auto-update PIPELINE-STATE.md with evidence status:

```markdown
## Evidence Status
- REQ-001: red Y | green Y | verified Y
- REQ-002: red Y | green X | verified -
- REQ-003: red X | green - | verified -
```

### 3. `save-feature-memory.sh` (triggered by stage completion validation)

On phase transition, extract key decisions/requirements/design from phase artifacts and write/update the FMU in `.memory/{feature}/`. Updates `_index.md` automatically.

---

## Plugin Migration

### New directory structure

```
quangflow/
├── .claude-plugin/
│   └── plugin.json              # Claude Code plugin metadata
├── .cursor-plugin/
│   └── plugin.json              # Cursor plugin metadata
├── package.json                 # OpenCode compatibility
├── skills/                      # renamed from commands/qf/
│   ├── 0-init/SKILL.md
│   ├── 1-brainstorm/SKILL.md
│   ├── 2-design/SKILL.md
│   ├── 3-handoff/SKILL.md
│   ├── 4-verify/SKILL.md
│   ├── 5-maintain/SKILL.md
│   ├── quick/SKILL.md
│   ├── cook/SKILL.md
│   ├── guide/SKILL.md
│   ├── status/SKILL.md
│   ├── test/SKILL.md
│   ├── update/SKILL.md
│   └── _protocols/              # internal protocols (not user-facing skills)
│       ├── _shared.md
│       ├── _tdd-enforcement.md      # NEW
│       ├── _systematic-debugging.md # NEW
│       ├── _verification-gates.md   # NEW
│       ├── _hard-gates.md           # NEW
│       ├── _structured-logging.md   # NEW
│       ├── _context-memory.md       # NEW
│       ├── _autopilot.md
│       ├── _pipeline-state.md
│       ├── _context-scoping.md
│       ├── _model-routing.md
│       ├── _dev-coordination.md
│       ├── _debate-protocol.md
│       ├── _gitnexus-integration.md
│       ├── _worktree-isolation.md
│       └── _error-recovery.md
├── agents/                      # stays the same
├── hooks/
│   ├── hooks.json               # Claude Code hooks config
│   ├── hooks-cursor.json        # Cursor hooks config
│   ├── auto-checkpoint.sh       # NEW
│   ├── evidence-tracker.sh      # NEW
│   ├── save-feature-memory.sh   # NEW
│   ├── enforce-ownership.sh     # existing
│   └── detect-gotcha-trigger.sh # existing
├── scripts/                     # validation scripts (stays the same)
├── install.sh                   # LEGACY — kept as fallback
├── uninstall.sh                 # LEGACY — kept as fallback
└── remote-install.sh            # LEGACY — kept as fallback
```

### Plugin manifests

**`.claude-plugin/plugin.json`:**
```json
{
  "name": "quangflow",
  "description": "5-phase workflow framework for Claude Code — structured project management with TDD, verification gates, and team orchestration",
  "version": "2.0.0",
  "author": { "name": "Duong M Quang" },
  "homepage": "https://github.com/DuongMQuang/quangflow",
  "repository": "https://github.com/DuongMQuang/quangflow",
  "license": "MIT",
  "keywords": ["workflow", "tdd", "debugging", "verification", "project-management", "team-orchestration"]
}
```

**`.cursor-plugin/plugin.json`:**
```json
{
  "name": "quangflow",
  "displayName": "QuangFlow",
  "version": "2.0.0",
  "skills": "./skills/",
  "agents": "./agents/",
  "hooks": "./hooks/hooks-cursor.json"
}
```

### Skill file format change

Each command `.md` file becomes a `SKILL.md` with YAML frontmatter:

**Before:** `commands/qf/0-init.md`
```markdown
# Phase 0: Init
...
```

**After:** `skills/0-init/SKILL.md`
```markdown
---
name: 0-init
description: "Use when starting a new project or feature — scans codebase, creates CONTEXT.md, detects project type"
---

# Phase 0: Init
...
```

### Legacy install preserved

- `install.sh`, `uninstall.sh`, `remote-install.sh` remain for users who prefer manual install
- `/qf:update` command still works for manual installs
- Plugin users get auto-updates via Claude Code plugin system

---

## Existing Phase Modifications

### Phase 3 (Handoff/Implementation)

Inject into the implementation section:
- Reference `_tdd-enforcement.md` — devs must follow RED-GREEN-REFACTOR
- Reference `_structured-logging.md` — devs must implement structured logging
- Reference `_verification-gates.md` — evidence required at implementation checkpoints

### Phase 4 (Verify → Verify & Certify)

Replace test generation with evidence audit:
- TDD compliance check (script-enforced)
- Full suite run (unit from TDD + integration/E2E from Tester)
- Log audit for ERROR/FATAL
- Produce CERTIFICATION.md instead of QA-REPORT.md

### Phase 5 (Maintain)

Inject systematic debugging:
- Reference `_systematic-debugging.md` as the bug-fixing protocol
- Auto-GOTCHA on resolution
- Structured log filtering as first investigation step

### All Phases

Inject hard gates:
- Reference `_hard-gates.md` via `_shared.md`
- Phase-specific gate checklists enforced by `validate-stage-completion.sh`
- Red flag tables visible in every phase prompt

---

## New Validation Scripts

| Script | Trigger | Purpose |
|---|---|---|
| `validate-tdd-coverage.sh` | Phase 3 → 4 transition | Verify every REQ-ID has red + green logs |
| `validate-evidence.sh` | Every phase transition | Check `.evidence/` has required artifacts |
| `validate-memory.sh` | Phase 0, on @mention | Verify FMU structure, no orphans, bidirectional links |
| `auto-checkpoint.sh` | PostToolUse (Write/Edit) | Auto-save agent progress |
| `evidence-tracker.sh` | PostToolUse (Write to `.evidence/`) | Track evidence status in PIPELINE-STATE |
| `save-feature-memory.sh` | Stage completion | Auto-update FMU on phase boundaries |

---

## Integration Map

```
TDD enforcement ──→ writes to .evidence/tdd/
                         ↓
Structured logging ──→ writes to .evidence/logs/
                         ↓
Verification gates ──→ reads .evidence/*, writes to .evidence/verification/
                         ↓
Hard gates ──→ reads .evidence/verification/, blocks if missing
                         ↓
Systematic debugging ──→ reads .evidence/logs/, writes to .evidence/debug/
                         ↓
                    auto-GOTCHAs to GOTCHAS.md
                         ↓
Context memory ──→ reads/writes .memory/{feature}/, loaded via @mention
                         ↓
Progress hooks ──→ auto-checkpoint, evidence tracking, FMU save
```

All six protocols feed into each other. Evidence is the connective tissue.
