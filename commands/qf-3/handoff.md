You are now entering Phase 3: Execution Handoff.

## State Check
- **Find project root**: Walk up from CWD looking for `./plans/` directory (check parent dirs up to 3 levels). Use the directory containing `./plans/` as project root.
- Scan `{project-root}/plans/` for feature directories with REQUIREMENTS.md and milestone directories containing DESIGN.md
- If multiple features found, ask user which feature
- If missing DESIGN.md, tell user: "No design found. Run `/qf-2::design` first."
- If missing REQUIREMENTS.md, tell user: "No requirements found. Run `/qf-1::brainstorm <idea>` first."

## Milestone Detection
- Find the next milestone with DESIGN.md but no ROADMAP.md
- Confirm with user: "Generating handoff for milestone-{N}. Correct?"
- Read REQUIREMENTS.md (project-level) + DESIGN.md (milestone-level)
- Read CONTEXT.md if it exists (for locked decisions from previous milestones)

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

## Code Quality Mandates (inject into every ROADMAP phase)
- Each module must have a single responsibility
- New feature must not require modifying existing interfaces
- Data models must be versioned from day 1

## Review Gate
Before finishing handoff, you MUST:
1. Read back CONTEXT.md locked decisions to the user
2. Ask: "Anything missing or incorrect? Type CONFIRM to finalize."

Agent waits. Does nothing until user types CONFIRM.

## Output Rule
- When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.
- **Long content rule:** If content requiring user review/approval exceeds ~30 lines, write it to the appropriate plan file first, then present a concise summary (5-10 lines) in console with the file path. Let user read the file. Do NOT dump long content into console.

## Execution Gate
After CONFIRM, check REQUIREMENTS.md for `team_mode` and `team_composition` settings.

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
   - **SHIP** — Launch team pipeline (`/qf-c::cook`)
   - **REFINE** — Adjust team composition
   - **SOLO** — Switch to solo mode (implement manually)"

4. On **REFINE**:
   - Ask: "What would you like to change?" and accept freeform instructions
   - Lead, PM, and Tester roles cannot be removed
   - Apply changes, re-display updated table, ask again: SHIP / REFINE / SOLO
   - Update `team_composition` in REQUIREMENTS.md after each refinement
   - Loop until user types SHIP or SOLO

5. On **SOLO**:
   - Set `team_mode: false` in REQUIREMENTS.md
   - Fall through to solo Next Step below

6. On **SHIP**:
   - Auto-invoke `/qf-c::cook` — cook.md is the single source of truth for pipeline orchestration
   - Cook reads `team_composition` from REQUIREMENTS.md and executes the full pipeline

**If `team_mode: false` (or not set):**
- Fall through to solo Next Step below

## Next Step
Tell user: "Phase 3 complete for milestone-{N}. Artifacts saved to `./plans/{feature-slug}/milestone-{N}/`."

Then suggest next command based on mode:

**If team_mode: true:**
```
**Next:** `/qf-c::cook` — Launch team pipeline (domain-engineer -> devs -> tech-lead -> tester -> PM)
  => Skip? You can implement manually (Solo mode) — run `/qf-4::verify` after implementing
  => Also available: `/qf-s::status` (check status), `/qf-s::status save` (save context)
```

**If team_mode: false (Solo):**
```
**Next:** Implement ROADMAP.md phases manually, then run `/qf-4::verify` — QA/QC verification
  => Skip? `/qf-4::verify` can be skipped but gaps may go undetected
  => Also available: `/qf-s::status` (check status), `/qf-s::status save` (save context)
```
