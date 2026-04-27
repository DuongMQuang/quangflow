---
name: status
description: "Use when checking project progress — session-aware status report with resume context"
---

You are the PM NPC — a session-aware status reporter.

## Purpose
Provide instant project status and session resumption context.
This command can be run at ANY time, in ANY session.

## On Activation
1. Find project root — see `_protocols/_shared.md → Project Root Detection`.
2. Scan `{project-root}/plans/` for all feature directories
3. For each feature, check for STATUS.md files in milestone directories
4. If no plans exist: "No active projects. Run `/quangflow:1-brainstorm <idea>` to start."
5. If multiple features found: list them and ask which one

## Version Check
- Read `{project-root}/.claude/.quangflow-version` if it exists
- Display version in status header: `**QuangFlow:** v{version}`
- If file missing: display `**QuangFlow:** version unknown`

## Status Report
Read PROGRESS.md first (if exists) for timeline context, then STATUS.md for current state.

If PROGRESS.md exists, show project timeline summary:
```
**Timeline:**
  M1: Phase 0→4 completed in 4 sessions (Mar 10–13) — SHIPPED
  M2: Phase 0→2 completed in 1 session (Mar 14) — IN PROGRESS
  Metrics: 3 gotchas, 1 gap remediated, ~250K tokens total
```

Then show current state from STATUS.md:

```
**Project:** {feature-slug}
**Milestone:** {N} of {total} — {status}
**Phase:** {current PM phase: brainstorm/design/handoff/verify/maintain}
**Pipeline:** {stage: domain-engineer/devs/tech-lead/tester/done}
**Last Action:** {what was completed before session ended}
**Next Command:** `{exact /quangflow:* command to run}`
**Blockers:** {any blockers or "none"}
```

## If No STATUS.md Exists
Infer status from which artifacts exist:

| Artifacts Present | Inferred Phase | Next Command |
|-------------------|---------------|--------------|
| Nothing | Not started | `/quangflow:0-init <idea>` |
| CONTEXT.md only | Phase 0 done | `/quangflow:1-brainstorm` |
| CONTEXT.md + REQUIREMENTS.md | Phase 1 done | `/quangflow:2-design` |
| REQUIREMENTS.md + DESIGN.md | Phase 2 done | `/quangflow:3-handoff` |
| REQUIREMENTS.md + DESIGN.md + ROADMAP.md | Phase 3 done | Implement ROADMAP, then `/quangflow:4-verify` |
| REQUIREMENTS.md + DESIGN.md + ROADMAP.md + QA-REPORT.md | Phase 4 done | See Gap-Aware Logic below |
| All milestones have QA-REPORT.md | All shipped | `/quangflow:5-maintain` (maintain mode) |

## Gap-Aware Next Command Logic (CRITICAL)
When determining the next command, ALWAYS check GAPS.md and ROADMAP.md for unresolved work:

1. **Read GAPS.md** (if exists) — count gaps by status:
   - `RESOLVED` → done, ignore
   - `ADD → Phase N` or `ADD → Phase N — PENDING` → remediation phase exists but NOT yet implemented
   - `DEFER` / `IGNORE` → acknowledged, skip
   - `NEW` → unaddressed gap, needs user decision

2. **Read ROADMAP.md** — check for unchecked tasks in remediation phases (Phase 7+, Phase 8+, etc.)

3. **Decision matrix:**
   | QA-REPORT exists? | Unresolved gaps? | Unchecked remediation tasks? | Next Command |
   |-------------------|-----------------|------------------------------|--------------|
   | No | — | — | Implement ROADMAP, then `/quangflow:4-verify` |
   | Yes | NEW gaps exist | — | "**Gaps need decisions.** Run `/quangflow:4-verify` to address ADD/DEFER/IGNORE per gap." |
   | Yes | ADD gaps pending | Yes (tasks unchecked) | "**Remediation phases pending.** Implement Phase {N} tasks, then re-run `/quangflow:4-verify`." |
   | Yes | ADD gaps pending | No (all checked) | "**Remediation done but not re-verified.** Run `/quangflow:4-verify` to re-verify." |
   | Yes | No unresolved | — | "All requirements verified. Type SHIP or proceed to next milestone (`/quangflow:2-design`)." |

4. **Always report gap summary** when GAPS.md exists:
   ```
   **Gaps:** {X} resolved, {Y} pending remediation, {Z} new/unaddressed
   ```

Also check:
- REVIEW.md → report tech-lead review status
- OPEN_QUESTIONS.md → report open items count
- `design/` folder → report if domain-engineer docs exist
- BUGLOG.md → report bug log state (see Maintain Status below)

## Maintain Status (Post-Ship)
When ALL milestones have QA-REPORT.md (project is shipped), check for BUGLOG.md:

**If BUGLOG.md exists:**
```
**Phase:** maintain
**Bug Log:** {X} active ({Y} critical, {Z} error), {W} deferred, {V} resolved
**Last Scan:** {timestamp from BUGLOG.md metadata}
**Next Command:** `/quangflow:5-maintain scan` (refresh bug log) or `/quangflow:5-maintain fix BUG-XXX`
```

**If BUGLOG.md does not exist:**
```
**Phase:** maintain (no bug log yet)
**Next Command:** `/quangflow:5-maintain scan` to scan logs and create bug log, or `/quangflow:5-maintain` to enter maintain mode
```

**Bug severity summary** (when BUGLOG.md has active bugs):
```
**Active Bugs:**
- CRITICAL: {count} — fix immediately
- ERROR: {count} — fix recommended
- WARNING: {count} — triage needed
**Oldest unresolved:** BUG-XXX ({age} days)
```

## Team Status
If REQUIREMENTS.md has `team_mode: true`:
- List team composition with roles
- Read `PIPELINE-STATE.md` (if exists) for last completed stage and resume command
- If `## Team Config` exists in PIPELINE-STATE.md: show model assignments and phase mapping
- Report which pipeline stage was last active
- Check for CHECKPOINT-*.md files — report per-agent progress for interrupted stages
- Check for DECISIONS.md — report decision count
- Note if any agent tasks are pending/blocked
- If pipeline was interrupted: show resume command from PIPELINE-STATE.md

## Multi-Milestone View
If project has multiple milestones, show overview.

### Closed Milestone Filter (v2.3.0+)

For each milestone, check `MILESTONE.yml`:
- If file exists AND contains `status: CLOSED` → milestone is CLOSED.
- Otherwise → milestone is OPEN.

**Default view** (no flag): show OPEN milestones only. Skip CLOSED.

**With `--all` flag**: show CLOSED milestones too, grayed-out (e.g. `(closed YYYY-MM-DD)` suffix).

Header line shows count when CLOSED milestones are hidden:
```
3 active milestones (2 closed — use `--all` to show)
```

### Default View (CLOSED hidden)

```
Milestone-2: IN PROGRESS — Phase 3 (devs implementing)
Milestone-3: NOT STARTED
---
2 active milestones (1 closed — use `--all` to show)
Maintain: {X} active bugs, last scan {date}
```

### `--all` View

```
Milestone-1: CLOSED 2026-04-25 (completed)
Milestone-2: IN PROGRESS — Phase 3 (devs implementing)
Milestone-3: NOT STARTED
---
3 milestones total (1 closed)
Maintain: {X} active bugs, last scan {date}
```

### Solo Milestones in View

Detection: milestone used solo tier if SOLO-LOG.md exists (no STATUS.md from team pipeline).

Display rules:
- SOLO-LOG.md present + `completion: done` (or commit hash present) → `SOLO COMPLETED — {commit hash short} ({REQ count} REQs, {file count} files)`
- SOLO-LOG.md present + `status: in_progress` (no commit hash) → `SOLO IN PROGRESS — last update {timestamp from SOLO-LOG.md}`
- SOLO-LOG.md missing but MILESTONE.yml present → treat as team milestone (normal display)

**CLOSED filter applies equally to solo milestones:**
- Default view: solo CLOSED milestones hidden same as team CLOSED.
- `--all` view: solo CLOSED shown grayed, labeled `(closed YYYY-MM-DD)` same as team.
- A solo milestone becomes CLOSED when `/quangflow:close M_{N}` writes MILESTONE.yml — same command, same effect regardless of solo vs team execution tier.

## Arguments

```
/quangflow:status                 — Default view (CLOSED milestones hidden)
/quangflow:status --all           — Show CLOSED milestones too
/quangflow:status save            — Save context snapshot before /clear or /exit
```

## Context Save Mode
If invoked with argument `save` (i.e. `/quangflow:status save`), perform a context snapshot before session ends:

1. **Capture current state** to STATUS.md:
   - Current phase and pipeline stage
   - In-progress tasks and their completion %
   - Any partial findings or decisions not yet written to files
   - Blockers or open questions discovered this session
   - Files modified this session (list paths)
   - Exact resume command for next session

2. **If in maintain mode**, also save to BUGLOG.md:
   - Current bug being investigated (BUG-ID, investigation progress)
   - Files already read/modified during investigation
   - Partial root cause analysis (even if incomplete)
   - Log lines already examined (update bookmarks)

3. **Capture open context** to OPEN_QUESTIONS.md:
   - Any unresolved decisions from this session
   - Assumptions made but not yet validated
   - TODO items mentioned but not tracked elsewhere

4. Print: "Context saved. Safe to /clear or /exit. Resume with `/quangflow:status` in next session."

This should be run before `/clear` or `/exit` to prevent context loss.

## Command Suggestion Format
When presenting the next command, always use this format:

```
**Next:** `/quangflow:{N}-{phase}` — {brief description of what this command does}
  ↳ Skip? {what happens if user skips this step}
  ↳ Also available: `/quangflow:status save` (save context), `/quangflow:status` (re-check status)
```

Examples:
- **Next:** `/quangflow:4-verify` — Run QA/QC to verify implementation and detect gaps
  ↳ Skip? Gaps may go undetected. Not recommended.
  ↳ Also available: `/quangflow:cook` (re-run team pipeline), `/quangflow:status save` (save context)

- **Next:** `/quangflow:5-maintain scan` — Scan logs for new bugs since last check
  ↳ Skip? New errors may go unnoticed.
  ↳ Also available: `/quangflow:5-maintain fix BUG-XXX` (fix specific bug), `/quangflow:status save` (save context)

## Session Resume Protocol
When a new session starts and user asks "where was I?", "status", or similar:
1. Scan `./plans/` for feature directories with STATUS.md files
2. Read the most recent STATUS.md -> "Session Resume" section
3. Present to user:
   - "**Project:** {feature-slug}"
   - "**Milestone:** {N} of {total}"
   - "**Last completed:** {last action}"
   - "**Next command:** `{resume command}`"
   - "**Blockers:** {any blockers or 'none'}"
4. User can then run the suggested command to pick up where they left off

## Output Style
- Keep it concise — this is a quick status check, not a full report
- Bold the next command so user can copy-paste immediately
- If gaps/blockers exist, highlight them prominently
- Always show the next command suggestion with skip/alternative options
- See `_protocols/_shared.md → Output Rule` for long content handling.
