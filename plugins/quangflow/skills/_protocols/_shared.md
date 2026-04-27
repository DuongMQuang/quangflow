# Shared Protocols

Referenced by all `/quangflow:*` commands. Do NOT duplicate — link here instead.

---

## Core Principles
- **Systems > Prompts** — enforce correctness through scripts and structure, not just instructions
- **Verification > Generation** — validate with real checks (scripts, tests) before trusting LLM output
- **Iteration > Perfection** — ship, learn (GOTCHAs), improve next round
- **No lazy fixes** — solve root cause, never patch symptoms to pass a gate

## Discipline Layer
All phases are subject to the discipline protocols:
- **`_hard-gates.md`** — master red flag table, evidence spec, phase gate checklists
- **`_tdd-enforcement.md`** — RED-GREEN-REFACTOR cycle. Referenced by Phase 3 and dev agents.
- **`_systematic-debugging.md`** — 4-phase root cause process. Referenced by Phase 5 and all agents on failure.
- **`_verification-gates.md`** — evidence before assertions at every phase gate.
- **`_structured-logging.md`** — log format standard. Referenced by Phase 3, Phase 4, Phase 5.
- **`_context-memory.md`** — Feature Memory Units with @mention loading. Referenced by all phases.
- **`_context-limits.md`** — context window monitoring and 70% hard gate. Referenced by all agents and cook.

<HARD-GATE>
Every phase transition MUST have evidence saved to .evidence/verification/.
See _verification-gates.md for the full protocol.
</HARD-GATE>

## Project Root Detection
Walk up from CWD looking for `./plans/` directory. Check parent directories up to 3 levels. Use the directory containing `./plans/` as project root for all subsequent scans.

## State Check Template
Each phase follows this pattern (replace `{artifact}` with the phase-specific check):

1. Find project root (see above)
2. Scan `{project-root}/plans/` for feature directories containing the required artifact
3. If multiple features found: ask user which one
4. If required artifact missing: tell user which earlier phase to run
5. Read relevant project-level files (REQUIREMENTS.md, CONTEXT.md)

## Milestone Detection
1. Check REQUIREMENTS.md for milestone tags [M1], [M2], etc.
2. Check which milestone directories exist and which already have `{target-artifact}`
3. Auto-select the next milestone without `{target-artifact}`
4. Confirm with user: "Working on milestone-{N}. Correct?"
5. If single milestone project: skip confirmation

**Target artifacts per phase:**
- Phase 0 (init): `CONTEXT.md`
- Phase 1 (brainstorm): `REQUIREMENTS.md`
- Phase 2 (design): `DESIGN.md`
- Phase 3 (handoff): `ROADMAP.md`
- Phase 4 (verify): `CERTIFICATION.md` (or `QA-REPORT.md` for legacy milestones)

## Output Rule
- When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.
- **Long content rule:** If content requiring user review/approval exceeds ~30 lines, write it to the appropriate plan file first, then present a concise summary (5-10 lines) in console with the file path. Let user read the file. Do NOT dump long content into console.

## Command Suggestion Format
When presenting the next command, always use this format:

```
**Next:** `/quangflow:{N}-{phase}` — {brief description}
  ↳ Skip? {what happens if skipped}
  ↳ Also available: `/quangflow:status save` (save context), `/quangflow:status` (re-check status)
```

## PIPELINE-STATE Schema
Track progress in `plans/{feature-slug}/milestone-{N}/PIPELINE-STATE.md`:

```markdown
# Pipeline State — {feature-slug} / Milestone {N}
Updated: {timestamp}

## Mode
pm_mode: {hands-on | autopilot}
hands_free: {true | false}

## Completed Stages
- [x] {stage} — completed {timestamp}
- [ ] {stage}

## Last Completed Stage
{stage-name}

## Resume Command
`/quangflow:{N}-{phase}`
```

**Usage:**
- Created/updated after each stage completes (cook.md manages team stages)
- Read by `/quangflow:status` for resume context
- Read by `/quangflow:1-brainstorm` for hands-free resume
- Read by `/quangflow:cook --from` for crash recovery

## Review Gate Pattern
All phases follow the same gate structure:
1. Present summary (simplified in autopilot mode)
2. Ask for explicit user input (gate keyword varies: APPROVE / CONFIRM / SHIP)
3. Agent waits. Does nothing until user responds.
4. On approval: write artifacts and proceed to Next Step

**Gate keywords per phase:**
- Phase 1: `APPROVE` (requirements)
- Phase 2: pick option (architecture choice)
- Phase 3: `CONFIRM` (artifacts), then `SHIP / REFINE` (execution)
- Phase 4: `SHIP` (verification passed)
- Phase 5: `FIX NOW / FIX LATER / DEFER / IGNORE` (bug triage)

## Schema Version
All generated artifacts (REQUIREMENTS.md, CONTEXT.md, ROADMAP.md, etc.) MUST include `quangflow_version` in their metadata.
Current version: read from `.claude/.quangflow-version` file (written by installer).

When a phase reads an artifact, check `quangflow_version`:
- If missing: warn "This artifact was created before versioning. It may be missing fields added in newer versions."
- If older than current: warn "This artifact was created with QuangFlow v{old}. Current is v{new}. Some fields may differ."
- Do NOT block execution — just warn. Artifacts are forward-compatible.

## Progress Tracking

Every phase MUST append an entry to `plans/{feature-slug}/PROGRESS.md` when it completes.
This is NOT optional — the stage gate script checks for it.

### PROGRESS.md Schema
```markdown
# Progress — {feature-slug}

## Overview
| Milestone | Phases Done | Sessions | Status |
|-----------|------------|----------|--------|
| M1 | 0→4 | 4 | SHIPPED |
| M2 | 0→2 | 1 | IN PROGRESS |

## Milestone 1

| Phase | Started | Completed | Sessions | Iterations | Key Decisions |
|-------|---------|-----------|----------|------------|---------------|
| 0-init | 2026-03-10 | 2026-03-10 | 1 | 1 | existing project, medium scan |
| 1-brainstorm | 2026-03-10 | 2026-03-10 | 1 | 3 rounds | 8 REQs, 2 milestones |
| 2-design | 2026-03-11 | 2026-03-11 | 1 | 1 | Option A (MVC+JWT) |
| cook | 2026-03-12 | 2026-03-12 | 1 | 1+remediation | 1 gap, 120K tokens |
| 4-verify | 2026-03-13 | 2026-03-13 | 1 | 2 | 4/4 PASS |

## Metrics
- Total sessions: {N}
- Gotchas logged: {N}
- Gaps found: {N} ({N} remediated, {N} deferred)
```

### Logging Protocol
Each phase appends its row to the milestone table when it completes:
1. If PROGRESS.md doesn't exist: create it with the Overview table and current milestone section
2. If milestone section doesn't exist: add it
3. Append phase row with: start time, completion time, session count (1 if same session), iterations, key decisions
4. Update the Overview table's "Phases Done" and "Status" columns
5. Update Metrics section

### Who Updates What
- **Phase 0-4:** Each phase appends its own row after review gate passes
- **Cook:** Appends the "cook" row with agent usage totals and gap count
- **PM agent:** Updates Metrics section at pipeline end
- **`/quangflow:status`:** Reads PROGRESS.md for timeline display

## Code Quality Mandates
Injected into every ROADMAP phase and verified in Phase 4:
- Each module must have a single responsibility
- New features must not require modifying existing interfaces
- Data models must be versioned from day 1

## GOTCHAs System — Self-Improvement Loop

### Purpose
Capture mistakes, surprises, and hard-won lessons so they inform future phases.

### Two Levels
- **Global GOTCHAs** (`plans/GOTCHAS.md`) — lessons that apply across ALL features in the project. General patterns, recurring mistakes, team conventions learned the hard way.
- **Feature GOTCHAs** (`plans/{feature-slug}/GOTCHAS.md`) — lessons specific to one feature's domain, architecture, or codebase area.

### GOTCHAS.md Format
```markdown
# GOTCHAs — {feature-slug OR "Global"}

### G-001 [{domain}] — {one-line description}
- **When:** {which phase/stage discovered this}
- **Root cause:** {why it happened — bad assumption, missing check, etc.}
- **Rule:** {concrete rule to prevent recurrence}
- **Tags:** {comma-separated: phase-2, design, auth, database, etc.}
```

**Domain tags:** `backend`, `frontend`, `infra`, `auth`, `database`, `api`, `testing`, `design`, `requirements`, `deployment`

### When to Log (automatic)
- **Phase 4 (verify):** For each GAP found → create a gotcha entry
- **Phase 5 (maintain):** For each bug fixed → create a gotcha entry
- **Tech-lead review:** For each major finding → create a gotcha entry

### When to Review (automatic)
- **Phase 2 (design):** Read BOTH global and feature GOTCHAS.md. Filter by tags matching current milestone's concerns. Present relevant gotchas before proposing design options.
- **Phase 3 (handoff):** Read BOTH. Inject relevant rules into ROADMAP.md phases as `> ⚠️ GOTCHA:` warnings.
- **Cook (dev prompts):** Include matching gotchas from BOTH levels in each dev's prompt context.

### Logging Protocol
1. Read existing GOTCHAS.md (if exists) to get next G-ID
2. **Scope decision:** Determine if gotcha is global or feature-specific:
   - **Clearly feature-specific** (e.g., "this API's pagination is off-by-one") → log to `plans/{feature-slug}/GOTCHAS.md`
   - **Clearly general** (e.g., "always validate webhook signatures") → log to `plans/GOTCHAS.md`
   - **Uncertain** → ask user: "This gotcha could apply broadly. Log it as **global** (all features) or **feature-specific** ({feature-slug} only)?"
3. Append new entry with auto-incremented ID (IDs are scoped per file: global G-IDs and feature G-IDs are independent)
4. Mention: "Logged gotcha G-{NNN} ({global|feature}): {description}"
5. Do NOT print the full entry to console

### Review Protocol
1. Read `plans/GOTCHAS.md` (global) + `plans/{feature-slug}/GOTCHAS.md` (feature)
2. Filter entries by tags relevant to current phase/milestone
3. If relevant gotchas found, present summary:
   "**Past lessons ({N} relevant):**
   - [global] G-001: {rule} (from: {when})
   - [{feature}] G-003: {rule} (from: {when})"
4. If no gotchas exist or none relevant: skip silently
