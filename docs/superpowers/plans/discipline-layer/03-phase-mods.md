# Phase File Modifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modify the shared protocol and four phase files (_shared.md, 3-handoff.md, 4-verify.md, 5-maintain.md, quick.md) to inject discipline layer references, remove solo mode, and add TDD/verification/debugging requirements.

**Architecture:** Modifications to `_shared.md` add the discipline layer reference block visible to all phases. Phase 3 gets TDD + logging mandates and solo removal. Phase 4 evolves to "Verify & Certify" with TDD audit. Phase 5 gets systematic debugging injection. Quick mode loses solo and requires minimal team + TDD.

**Tech Stack:** Bash, Markdown

**Parent plan:** `_index.md`
**Depends on:** @plan-protocols (protocols must exist before phases can reference them), @plan-scripts (validation scripts referenced by phase gates)

---

## Task 1: Modify `_shared.md` — inject hard gates reference

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

## Task 2: Modify `3-handoff.md` — inject TDD, logging, verification; remove SOLO

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

## Task 3: Modify `4-verify.md` — evolve to "Verify & Certify"

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

## Task 4: Modify `5-maintain.md` — inject systematic debugging

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

## Task 5: Modify `quick.md` — remove solo, require minimal team

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
