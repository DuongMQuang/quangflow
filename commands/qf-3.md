You are now entering Phase 3: Execution Handoff.

## State Check
- Scan ./plans/ for feature directories with REQUIREMENTS.md and milestone directories containing DESIGN.md
- If multiple features found, ask user which feature
- If missing DESIGN.md, tell user: "No design found. Run `/qf-2` first."
- If missing REQUIREMENTS.md, tell user: "No requirements found. Run `/qf-1 <idea>` first."

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
When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.

## Team Mode Execution
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

   **Pipeline:** domain-engineer designs → devs implement (parallel) → [optional] tech-lead reviews → tester tests

   Options:
   - **SHIP** — Launch team as shown above
   - **REFINE** — Adjust team composition (add/remove/rename roles, change ownership, reorder dependencies)
   - **SOLO** — Switch to solo mode (discard team, implement manually)"

4. On **REFINE**:
   - Ask: "What would you like to change?" and accept freeform instructions, e.g.:
     - "Split dev-backend into dev-api and dev-database"
     - "Remove dev-infra, merge into dev-backend"
     - "Add dev-worker for queue processing, ownership: src/workers/*"
     - "Change dev-frontend ownership to src/app/*, src/ui/*"
     - "Remove tech-lead" or "Make tech-lead required"
   - Lead role is always present and cannot be removed (it's the main session)
   - PM role is always present and cannot be removed (session memory NPC)
   - Tester role is always present and cannot be removed (vital for test generation)
   - Apply changes, re-display the updated table, and ask again: SHIP / REFINE / SOLO
   - Update `team_composition` in REQUIREMENTS.md after each refinement
   - Loop until user types SHIP or SOLO

5. On **SOLO**:
   - Set `team_mode: false` in REQUIREMENTS.md
   - Fall through to solo Next Step below

6. On **SHIP**:
   - Invoke `/qf-c ./plans/{feature-slug}/milestone-{N}/ROADMAP.md`
   - `/qf-c` reads `team_composition` from REQUIREMENTS.md and executes the full pipeline

7. **Domain Engineer Phase** (before devs start):
   If `domain-engineer` is in team_composition and not removed by user:

   - Spawn `Task(subagent_type: "planner", name: "domain-engineer")`
   - Domain engineer receives: REQUIREMENTS.md, DESIGN.md, ROADMAP.md, CONTEXT.md
   - Domain engineer produces these files in `plans/{feature-slug}/milestone-{N}/design/`:

     **a) `OVERVIEW.md`** — Simple architecture overview
     - System components and their responsibilities (keep concise)
     - High-level data flow between components
     - Key technology choices and why
     - Include Mermaid flowchart: top-level component interaction

     **b) `MODULES.md`** — Module boundary design
     - Each module: name, responsibility, public interface, dependencies
     - File structure: what files each module contains
     - Dependency rules: which modules can import from which
     - Include Mermaid class diagram: module relationships

     **c) `SEQUENCES.md`** — Key user flow sequence diagrams
     - One Mermaid sequence diagram per critical user flow (from REQUIREMENTS.md)
     - Shows: user → frontend → API → service → database (and back)
     - Cover happy path + primary error paths
     - Label each arrow with method/event names

     **d) `CONTRACTS.md`** — Interface contracts between modules
     - API endpoints: method, path, request/response types
     - Shared types/interfaces that cross module boundaries
     - Event contracts (if pub/sub or message queue)
     - Database schema overview (tables, key relationships)

   - All diagrams use **Mermaid** syntax (compatible with VSCode "Markdown Preview Mermaid Support" extension)
   - Lead presents design docs to user for review before spawning devs
   - Ask: "Domain engineer completed design docs. Review in `plans/{slug}/milestone-{N}/design/`. Proceed to devs? (YES / request changes)"
   - Each dev teammate receives these design docs alongside their task description

8. **Dev Phase**:
   - Each dev teammate receives: their assigned phases, file ownership globs, DESIGN.md, design docs from domain-engineer, and REQUIREMENTS.md
   - Devs implement in parallel following the module boundaries and contracts defined by domain-engineer

9. **After All Devs Complete — Tech Lead Review Gate**:
   When all dev tasks are marked completed, the lead (main session) asks the user:

   "All developers have completed their tasks. Would you like a tech lead review before testing?
   - **YES** — Spawn tech-lead agent to review code quality, module structure, tech debt, and cross-dev integration
   - **SKIP** — Go straight to tester"

   **If YES:**
   - Spawn `Task(subagent_type: "code-reviewer", name: "tech-lead")`
   - Tech-lead reviews all dev outputs for:
     - **Module structure**: Single responsibility, clean boundaries between dev ownership zones
     - **Cross-dev integration**: Do backend APIs match what frontend expects? Shared types consistent?
     - **Tech debt**: Hardcoded values, missing error handling, tight coupling, magic strings
     - **DESIGN.md compliance**: Does implementation match the chosen architecture?
     - **Code quality**: Clean code, no duplication across dev boundaries, consistent patterns
   - Tech-lead saves review report to `plans/{feature-slug}/milestone-{N}/REVIEW.md`
   - Tech-lead classifies each finding by severity:
     - **Minor** (fix now): Style issues, small bugs, missing validation, hardcoded values → send fix request to devs
     - **Major** (needs remediation phase): Architectural debt, tight coupling across modules, missing abstraction layers, scalability concerns → flag for escalation
   - **Minor issues flow:**
     - Tech-lead sends fix requests to specific devs via `SendMessage(type: "message")`
     - Wait for devs to fix and tech-lead to re-review
     - Loop until all minor issues resolved
   - **Major issues flow:**
     - Tech-lead writes `GAPS.md` to `plans/{feature-slug}/milestone-{N}/GAPS.md` containing:
       - Each gap: ID (GAP-001), description, severity, affected files, root cause, proposed remediation
       - Proposed remediation phase(s) with scope, estimated effort, and dependency on existing phases
     - Lead presents GAPS.md to user:
       "Tech-lead found {N} major gap(s) requiring remediation phases:
       - GAP-001: {description} → proposed phase: {title}
       - GAP-002: ...
       Options:
       - **ADD** — Append remediation phase(s) to ROADMAP.md, continue to tester
       - **DEFER** — Log to OPEN_QUESTIONS.md, address in next milestone
       - **IGNORE** — Accept tech debt, continue to tester"
     - If ADD: append phase(s) to ROADMAP.md, mark as `status: pending-remediation`
     - Remediation phases execute AFTER tester phase completes (don't block testing)
   - When review passes (all minor fixed, major decisions made) → proceed to tester

   **If SKIP:**
   - Proceed directly to tester

10. **Tester Phase**:
   - Spawn `Task(subagent_type: "tester", name: "tester")`
   - Tester receives: REQUIREMENTS.md (acceptance criteria), DESIGN.md, and list of implemented files
   - Tester generates tests based on requirements:
     - **Unit tests**: Per module, cover happy path + edge cases from Phase 1
     - **Integration tests**: Cross-module interactions, API contracts
     - **E2E/Suite tests**: User workflows from requirements
   - Tester runs all generated tests, reports pass/fail
   - After tester completes → proceed to PM status report

11. **PM Status Report** (always runs):
   PM is a required role — always spawn at this final checkpoint.

   - Spawn `Task(subagent_type: "project-manager", name: "pm")`
   - PM receives: REQUIREMENTS.md, ROADMAP.md, REVIEW.md (if exists), tester results, design docs
   - PM produces `STATUS.md` in `plans/{feature-slug}/milestone-{N}/STATUS.md` containing:

     **Progress Summary**
     - Milestone: {N} of {total}
     - Requirements completed: X/Y (with REQ-IDs)
     - Requirements pending: list with reasons

     **Pipeline Report**
     - Domain engineer: completed / skipped — key outputs
     - Dev tasks: X completed, Y issues found
     - Tech-lead review: completed / skipped — findings summary
     - Tester: X passed, Y failed, Z skipped

     **Blockers & Risks**
     - Any failed tests mapped to requirement IDs
     - Any tech-lead issues still unresolved
     - Cross-milestone dependencies for future milestones

     **Docs Impact**
     - Which docs in `./docs/` need updating (codebase-summary, system-architecture, etc.)
     - Changelog entries to add

     **Next Steps**
     - Recommended actions before `/qf-4`
     - If more milestones: what's needed for milestone-{N+1}

     **Session Resume** (for new session context)
     - Current phase: which PM phase is active (brainstorm/design/handoff/verify)
     - Current milestone: which milestone is in progress
     - Pipeline stage: where in the team pipeline (domain-engineer/devs/tech-lead/tester/done)
     - Last completed action: what was finished before session ended
     - Resume command: exact `/qf-*` command to run next
     - Blockers: anything that needs user attention before resuming

   - Lead presents STATUS.md summary to user
   - Tell user: "Implementation and testing complete. Status report at `plans/{slug}/milestone-{N}/STATUS.md`. Run `/qf-4` for final QA/QC and human verification."

   **PM can also be spawned on-demand** by the lead at any checkpoint during the pipeline:
   - After domain-engineer completes (design checkpoint)
   - After devs complete (implementation checkpoint)
   - After tech-lead completes (review checkpoint)
   - User can request: "status update" at any time → lead spawns PM

**If `team_mode: false` (or not set):**
- Fall through to solo Next Step below

## Session Resume Protocol
When a new session starts and user asks "where was I?" or similar:
1. Lead scans `./plans/` for feature directories with STATUS.md files
2. Read the most recent STATUS.md → "Session Resume" section
3. Present to user:
   - "**Project:** {feature-slug}"
   - "**Milestone:** {N} of {total}"
   - "**Last completed:** {last action}"
   - "**Next command:** `{resume command}`"
   - "**Blockers:** {any blockers or 'none'}"
4. User can then run the suggested command to pick up where they left off

## Next Step
Tell user: "Phase 3 complete for milestone-{N}. Artifacts saved to `./plans/{feature-slug}/milestone-{N}/`. Next steps:
- **Solo:** Implement ROADMAP.md phases, then run `/qf-4` to QA/QC.
- **Team:** Run `/qf-c ./plans/{feature-slug}/milestone-{N}/ROADMAP.md` to launch the team pipeline.
After milestone-{N} is shipped, run `/qf-2` for milestone-{N+1} (if applicable)."