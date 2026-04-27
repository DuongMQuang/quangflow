---
name: close
description: "Use when closing a finished milestone — writes MILESTONE.yml so /quangflow:status hides it from default view"
---

You are the milestone close command — a lightweight finalize step that marks a milestone CLOSED without moving any files.

## Purpose

After a milestone ships (QA-REPORT.md / CERTIFICATION.md / SOLO-LOG.md present), user wants to "archive" it from the default `/quangflow:status` view to focus on active work. `/quangflow:close M_N` writes `plans/{slug}/milestone-{N}/MILESTONE.yml` with status=CLOSED. `/quangflow:status` filters CLOSED milestones unless `--all` flag passed.

KISS: no directory moves (preserves git blame + cross-references). No `--reopen` flag (manual delete of MILESTONE.yml if user wants to reopen).

## Arguments

```
/quangflow:close M_1                      — Close milestone-1 (validate pre-conditions)
/quangflow:close M_1 --reason "shipped"   — Close with custom reason (default: "completed")
/quangflow:close M_1 --force              — Skip pre-condition validation (use with care)
/quangflow:close M_1 --feature my-slug    — Disambiguate when multiple plan dirs exist
```

`M_N` syntax: `M_1`, `M_2`, `M_10`, etc. The number must match an existing milestone directory (`milestone-1`, `milestone-2`, ...).

## Pre-conditions (validation)

Before writing MILESTONE.yml, verify:

1. **Plan dir exists**: `plans/{slug}/milestone-{N}/` must be a directory.
2. **STATUS.md exists**: indicates the milestone has reached at least PM phase.
3. **At least one of**: `QA-REPORT.md` OR `CERTIFICATION.md` OR `SOLO-LOG.md` exists. This proves the milestone was verified or solo-logged.
4. **MILESTONE.yml does NOT already have `status: CLOSED`** — if already closed, abort with message "Milestone {N} already closed at {timestamp}. Delete MILESTONE.yml to reopen."

If `--force` flag passed, skip checks 2 and 3 (still require check 1 + check 4).

The validation logic is implemented in `{plugin-root}/scripts/validate/validate-milestone-close.sh`. Cook calls it before writing the yml. See script for exact exit codes.

## Execution

### Step 1: Find Plan Dir

If `--feature` flag passed: use `plans/{feature}/milestone-{N}/`.
If multiple plan dirs exist and no `--feature`: list them and ask user to disambiguate.
If exactly one plan dir: use it.

### Step 2: Run Pre-condition Validator

```bash
bash {plugin-root}/scripts/validate/validate-milestone-close.sh \
  --milestone-dir "plans/{slug}/milestone-{N}" \
  ${force:+--force}
```

Exit codes:
- 0: pre-conditions pass, proceed.
- 1: missing required artifact (STATUS.md or evidence file). Abort unless `--force`.
- 2: already closed. Abort.
- 3: plan dir not found. Abort.

If validator fails (exit 1) without `--force`: print failure reason from validator stdout, suggest `--force` if user is sure.

### Step 3: Write MILESTONE.yml

Create `plans/{slug}/milestone-{N}/MILESTONE.yml` with this exact schema:

```yaml
status: CLOSED
closed_at: <ISO-8601-UTC>             # e.g. 2026-04-27T13:11:00Z
closed_reason: completed              # or user-provided --reason
closed_by: quangflow:close            # always this literal string
quangflow_version: <plugin-version>   # read from .claude-plugin/plugin.json
artifacts:
  - STATUS.md
  - QA-REPORT.md                      # or CERTIFICATION.md or SOLO-LOG.md
notes: ""                             # optional, user can edit later
```

Fields:
- `status`: always `CLOSED` (the only value `/quangflow:close` writes).
- `closed_at`: ISO 8601 UTC timestamp at write time.
- `closed_reason`: from `--reason` flag, default `"completed"`.
- `closed_by`: always `"quangflow:close"`.
- `quangflow_version`: read from project's `.claude/.quangflow-version` if exists, else `"unknown"`.
- `artifacts`: list of evidence files found (subset of `[STATUS.md, QA-REPORT.md, CERTIFICATION.md, SOLO-LOG.md]`).
- `notes`: empty string (user may edit later).

### Step 4: Confirm

Print:
```
Milestone {N} closed.
- File: plans/{slug}/milestone-{N}/MILESTONE.yml
- Reason: {reason}
- Hidden from /quangflow:status default view (use --all to show).
- Reopen: delete MILESTONE.yml manually.
```

## Status Integration

`/quangflow:status` reads each milestone's MILESTONE.yml:
- Missing yml or `status != CLOSED` → milestone is OPEN, show in default view.
- `status: CLOSED` → milestone is CLOSED, hide from default view.
- `--all` flag → show CLOSED milestones grayed-out (e.g. with `(closed)` suffix).

See `status/SKILL.md → Multi-Milestone View` for display rules.

## Reopen (manual)

User who wants to reopen a closed milestone:
```bash
rm plans/{slug}/milestone-{N}/MILESTONE.yml
```

Then `/quangflow:status` will show it as OPEN again. No `--reopen` flag in v2.3.0 (KISS — defer to v2.4.0+ if user demand surfaces).

## Examples

### Close last shipped milestone

```
/quangflow:close M_1
→ validates STATUS.md + QA-REPORT.md exist
→ writes MILESTONE.yml with status=CLOSED, reason=completed
→ /quangflow:status no longer lists M_1 in default view
```

### Close with custom reason

```
/quangflow:close M_2 --reason "shipped to prod 2026-04-25"
→ writes MILESTONE.yml with closed_reason="shipped to prod 2026-04-25"
```

### Force close (no QA-REPORT)

```
/quangflow:close M_3 --force --reason "abandoned, not pursuing"
→ skips evidence check, writes yml
```

### Multiple features

```
/quangflow:close M_1 --feature my-feature-slug
→ targets plans/my-feature-slug/milestone-1/
```

### Already closed

```
/quangflow:close M_1
→ validator exit 2: "Milestone 1 already closed at 2026-04-25T10:00:00Z."
→ Abort. To reopen: rm MILESTONE.yml.
```

## Errors

| Condition | Behavior |
|-----------|----------|
| Plan dir not found | Print error, list available milestones, exit. |
| Multiple features, no `--feature` | Print list, ask user to specify. |
| STATUS.md missing | Print "missing STATUS.md", suggest `--force`, exit. |
| No QA / CERT / SOLO-LOG | Print "no evidence file", suggest `--force`, exit. |
| Already closed | Print closed-at timestamp, exit (no overwrite). |
| Write fails (permission) | Print error, suggest `chmod` or run with proper user. |

## Anti-Patterns (DO NOT)

- ❌ Move/rename milestone directory (breaks git blame and cross-references).
- ❌ Delete artifacts (status, qa-report, etc.) — keep evidence intact.
- ❌ Edit STATUS.md — close is a separate metadata file (MILESTONE.yml).
- ❌ Add `--reopen` flag (out of scope for v2.3.0).
