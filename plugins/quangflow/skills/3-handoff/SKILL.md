---
name: 3-handoff
description: "Use when entering execution handoff — ROADMAP generation, TDD/logging mandates, SHIP/REFINE gate"
---

You are now entering Phase 3: Execution Handoff.

## State Check
See `_protocols/_shared.md → State Check Template`. Required artifacts: REQUIREMENTS.md + DESIGN.md.
If missing DESIGN.md: "No design found. Run `/quangflow:2-design` first."
If missing REQUIREMENTS.md: "No requirements found. Run `/quangflow:1-brainstorm <idea>` first."

## Milestone Detection
See `_protocols/_shared.md → Milestone Detection`. Target artifact: `ROADMAP.md`.
Read REQUIREMENTS.md (project-level) + DESIGN.md (milestone-level) + CONTEXT.md (if exists).

## GOTCHAs Review (before generating artifacts)
See `_protocols/_shared.md → GOTCHAs System → Review Protocol`.
Read both `plans/GOTCHAS.md` (global) and `plans/{feature-slug}/GOTCHAS.md` (feature) if they exist. Filter by tags matching this milestone's requirements.
If relevant gotchas found: inject their rules as `> ⚠️ GOTCHA [global/feature]:` warnings in the appropriate ROADMAP.md phases.

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

## Output Files
Generate to ./plans/{feature-slug}/:

1. **REQUIREMENTS.md** (project-level) — UPDATE the existing draft:
   - Add requirement IDs (REQ-001, REQ-002, ...)
   - Add v1/v2 priority tags
   - Add acceptance criteria per requirement
   - Only finalize requirements tagged for current milestone [M{N}]
   - Change status for current milestone's requirements from DRAFT to FINAL
   - Leave future milestone requirements as DRAFT

2. **CONTEXT.md** (project-level) — append locked decisions from this milestone

3. **OPEN_QUESTIONS.md** (project-level) — append/update open items

Generate to ./plans/{feature-slug}/milestone-{N}/:

4. **ROADMAP.md** — phases with clear deliverable + done criteria per phase

## Code Quality Mandates
See `_protocols/_shared.md → Code Quality Mandates`. Inject into every ROADMAP phase.

## Task Granularity Check (auto — after ROADMAP generation)

<HARD-GATE>
No ROADMAP phase should produce >150 LOC or cover >3 REQ-IDs.
Large phases overwhelm agent context and reduce review quality.
</HARD-GATE>

For each phase in the generated ROADMAP.md:
1. Count REQ-IDs assigned to this phase
2. Estimate LOC from MODULES.md file targets:
   - CRUD endpoint: ~40 LOC
   - Service with business logic: ~80 LOC
   - Complex module (auth, realtime, state machine): ~120 LOC
3. **If REQ-IDs > 3 OR estimated LOC > 150:**
   - Auto-split into sub-tasks: Phase {N}.1, {N}.2, {N}.3...
   - Each sub-task: 1-2 REQ-IDs, single module focus
   - Each sub-task must be independently testable (own TDD cycle)
   - Use MODULES.md boundaries as natural split points
4. Update ROADMAP.md with sub-tasks replacing the original phase
5. Log: "Phase {N} split into {M} sub-tasks (estimated {LOC} LOC, {R} REQ-IDs)"

**Split rules:**
- Sub-tasks inherit the parent phase's priority and done criteria
- Sub-tasks get sequential numbering: Phase 2.1, 2.2, 2.3
- Each sub-task lists its specific REQ-IDs and target files
- Dev agents receive sub-tasks as their scoped phases (no change to dev-teammate.md)

**Skip condition:** If ALL phases are already ≤150 LOC and ≤3 REQ-IDs, skip silently.

## Review Gate

**Autopilot mode:** See `_protocols/_autopilot.md → Phase 3 — Handoff`.

**Normal mode:**
1. Read back CONTEXT.md locked decisions to the user
2. Ask: "Anything missing or incorrect? Type CONFIRM to finalize."

Agent waits. Does nothing until user types CONFIRM.

## Output Rule
See `_protocols/_shared.md → Output Rule`.

## Execution Gate
After CONFIRM, check REQUIREMENTS.md for `team_mode` and `team_composition` settings.

**If `team_mode: false` (solo selected in brainstorm):**

Surface:
```
ROADMAP.md ready. Execution mode: solo.

- **SHIP** — Run `/quangflow:cook --solo` (force solo, no spawn) or `/quangflow:cook` (Stage 0 auto-triage, will confirm solo).
  Main agent (Opus) edits files directly. Critical-advocate mindset enforced — list ≥2 alternatives per decision, log to SOLO-LOG.md.
  SOLO-LOG.md required: plans/{slug}/milestone-{N}/SOLO-LOG.md with REQ-IDs, files, TDD evidence, alternatives considered.
  NOT for sensitive areas (auth/payment/crypto/migration) — sensitive keywords force escalation to team.
- **REFINE** — Change execution mode: run `/quangflow:1-brainstorm` to re-scope, or type SWITCH to move to light/team mode now.
```

Agent waits for SHIP or REFINE.

On SHIP: auto-invoke `/quangflow:cook` (or `/quangflow:cook --solo` if user specifies). Cook handles the rest.
On REFINE: ask what they want to change; update `team_mode` in REQUIREMENTS.md; loop back to gate.

**If `team_mode: true`:**

1. Read `team_composition` from REQUIREMENTS.md
2. Map ROADMAP.md phases to team roles based on file ownership boundaries
3. Present the execution plan:

   "Team mode enabled. Here's the execution plan:

   | Role | Type | Phases | File Ownership |
   |------|------|--------|----------------|
   | lead | Orchestrator | Coordinate all | Main session |
   | domain-engineer | Architect (recommended) | Before devs | `plans/{slug}/milestone-{N}/design/` |
   | dev-backend | Developer | Phase 1, 3 | `src/api/*, src/models/*` |
   | dev-frontend | Developer | Phase 2, 4 | `src/components/*, src/pages/*` |
   | tech-lead | Reviewer (optional) | After devs | Read-only on all dev files |
   | tester | Tester | After review | `tests/*` |

   **Pipeline:** domain-engineer designs -> devs implement (parallel) -> [optional] tech-lead reviews -> tester tests

   Options:
   - **SHIP** — Launch team pipeline (`/quangflow:cook`)
   - **REFINE** — Adjust team composition"

**Autopilot shortcut:** See `_protocols/_autopilot.md → Phase 3`. Auto-SHIP, skip REFINE.

4. On **REFINE**:
   - Ask: "What would you like to change?" and accept freeform instructions
   - Lead, PM, and Tester roles cannot be removed
   - Apply changes, re-display updated table, ask again: SHIP / REFINE
   - Update `team_composition` in REQUIREMENTS.md after each refinement
   - Loop until user types SHIP

5. On **SHIP**:
   - Auto-invoke `/quangflow:cook` — cook.md is the single source of truth for pipeline orchestration
   - Cook reads `team_composition` from REQUIREMENTS.md and executes the full pipeline

**If `team_mode: false` (user explicitly opted out):**
- Leave `team_mode: false` — cook Stage 0 will route this to solo tier automatically.
- Surface: "Solo mode selected. Run `/quangflow:cook` (auto-triage) or `/quangflow:cook --solo` to execute. Main agent (Opus) edits files directly with critical-advocate mindset. SOLO-LOG.md required. NOT for sensitive areas (auth/payment/crypto/migration) — those force escalation to team."

**If `team_mode` unset (not specified):**
- Leave `team_mode` unset — cook Stage 0 auto-triages solo / light / team based on REQ count, phase count, file estimate, and sensitive keywords.
- Surface: "Execution mode not set. Run `/quangflow:cook` — Stage 0 will auto-select the right tier. Override with `--solo`, `--light`, or `--team` flags."

## Progress Logging
See `_protocols/_shared.md → Progress Tracking`. Append Phase 3 row to `plans/{feature-slug}/PROGRESS.md`.
Key decisions to log: execution mode (SHIP), ROADMAP phase count, team composition summary.

## Next Step
Tell user: "Phase 3 complete for milestone-{N}. Artifacts saved to `./plans/{feature-slug}/milestone-{N}/`."

Then suggest next command based on mode:

**If team_mode: true:**
```
**Next:** `/quangflow:cook` — Auto-triage + run pipeline (cook Stage 0 decides solo / light / team based on complexity)
  => Override: `/quangflow:cook --team` to force full team, `/quangflow:cook --light` for dev+tester only
  => Also available: `/quangflow:status` (check status), `/quangflow:status save` (save context)
```

**If team_mode: false (solo):**
```
**Next:** `/quangflow:cook --solo` — Solo execution: main agent edits directly, no spawn.
  => Or: `/quangflow:cook` to let Stage 0 confirm solo via auto-triage.
  => Also available: `/quangflow:status` (check status)
```

**If team_mode unset:**
```
**Next:** `/quangflow:cook` — Stage 0 auto-triages: solo / light / team based on REQ count, phases, file estimate, keywords.
  => Override: `--solo` / `--light` / `--team` flags.
  => Also available: `/quangflow:status` (check status)
```

**Note:** Solo mode is auto-selected by cook Stage 0 triage for trivial tasks (1 REQ, 1 phase, 1 file, no sensitive keywords). Cook prints a solo handoff message and the main agent edits files directly. See `_protocols/_complexity-triage.md` and `_protocols/_solo-handoff.md` for details.
