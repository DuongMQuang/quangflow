# Shared Protocols

Referenced by all `/qf-*` commands. Do NOT duplicate — link here instead.

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
- Phase 2 (design): `DESIGN.md`
- Phase 3 (handoff): `ROADMAP.md`
- Phase 4 (verify): `QA-REPORT.md`

## Output Rule
- When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.
- **Long content rule:** If content requiring user review/approval exceeds ~30 lines, write it to the appropriate plan file first, then present a concise summary (5-10 lines) in console with the file path. Let user read the file. Do NOT dump long content into console.

## Command Suggestion Format
When presenting the next command, always use this format:

```
**Next:** `/qf-{N}` — {brief description}
  ↳ Skip? {what happens if skipped}
  ↳ Also available: `/qf-s::status save` (save context), `/qf-s::status` (re-check status)
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
`/qf-{N}::command`
```

**Usage:**
- Created/updated after each stage completes (cook.md manages team stages)
- Read by `/qf-s::status` for resume context
- Read by `/qf-1::brainstorm` for hands-free resume
- Read by `/qf-c::cook --from` for crash recovery

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

## Code Quality Mandates
Injected into every ROADMAP phase and verified in Phase 4:
- Each module must have a single responsibility
- New features must not require modifying existing interfaces
- Data models must be versioned from day 1
