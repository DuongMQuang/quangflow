# Shared Protocols

Referenced by all `/qf:*` commands. Do NOT duplicate — link here instead.

---

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
- Phase 4 (verify): `QA-REPORT.md`

## Output Rule
- When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.
- **Long content rule:** If content requiring user review/approval exceeds ~30 lines, write it to the appropriate plan file first, then present a concise summary (5-10 lines) in console with the file path. Let user read the file. Do NOT dump long content into console.

## Command Suggestion Format
When presenting the next command, always use this format:

```
**Next:** `/qf:{N}-{phase}` — {brief description}
  ↳ Skip? {what happens if skipped}
  ↳ Also available: `/qf:status save` (save context), `/qf:status` (re-check status)
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
`/qf:{N}-{phase}`
```

**Usage:**
- Created/updated after each stage completes (cook.md manages team stages)
- Read by `/qf:status` for resume context
- Read by `/qf:1-brainstorm` for hands-free resume
- Read by `/qf:cook --from` for crash recovery

## Review Gate Pattern
All phases follow the same gate structure:
1. Present summary (simplified in autopilot mode)
2. Ask for explicit user input (gate keyword varies: APPROVE / CONFIRM / SHIP)
3. Agent waits. Does nothing until user responds.
4. On approval: write artifacts and proceed to Next Step

**Gate keywords per phase:**
- Phase 1: `APPROVE` (requirements)
- Phase 2: pick option (architecture choice)
- Phase 3: `CONFIRM` (artifacts), then `SHIP / REFINE / SOLO` (execution)
- Phase 4: `SHIP` (verification passed)
- Phase 5: `FIX NOW / FIX LATER / DEFER / IGNORE` (bug triage)

## Schema Version
All generated artifacts (REQUIREMENTS.md, CONTEXT.md, ROADMAP.md, etc.) MUST include `quangflow_version` in their metadata.
Current version: read from `.claude/.quangflow-version` file (written by installer).

When a phase reads an artifact, check `quangflow_version`:
- If missing: warn "This artifact was created before versioning. It may be missing fields added in newer versions."
- If older than current: warn "This artifact was created with QuangFlow v{old}. Current is v{new}. Some fields may differ."
- Do NOT block execution — just warn. Artifacts are forward-compatible.

## Code Quality Mandates
Injected into every ROADMAP phase and verified in Phase 4:
- Each module must have a single responsibility
- New features must not require modifying existing interfaces
- Data models must be versioned from day 1

## GOTCHAs System — Self-Improvement Loop

### Purpose
Capture mistakes, surprises, and hard-won lessons so they inform future phases.
GOTCHAs are per-feature: `plans/{feature-slug}/GOTCHAS.md`.

### GOTCHAS.md Format
```markdown
# GOTCHAs — {feature-slug}

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
- **Phase 2 (design):** Read GOTCHAS.md, filter by tags matching current milestone's concerns. Present relevant gotchas before proposing design options.
- **Phase 3 (handoff):** Read GOTCHAS.md, inject relevant rules into ROADMAP.md phases as warnings.
- **Cook (dev prompts):** Include gotchas tagged with each dev's domain in their prompt context.

### Logging Protocol
1. Read existing GOTCHAS.md (if exists) to get next G-ID
2. Append new entry with auto-incremented ID
3. Mention: "Logged gotcha G-{NNN}: {description}"
4. Do NOT print the full entry to console

### Review Protocol
1. Read GOTCHAS.md
2. Filter entries by tags relevant to current phase/milestone
3. If relevant gotchas found, present summary:
   "**Past lessons ({N} relevant):**
   - G-001: {rule} (from: {when})
   - G-003: {rule} (from: {when})"
4. If no gotchas exist or none relevant: skip silently
