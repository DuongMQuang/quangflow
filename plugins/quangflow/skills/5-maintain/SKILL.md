---
name: 5-maintain
description: "Use when project is shipped — systematic debugging, structured log scan, bug triage, hotfix"
---

You are now entering Phase 5: Maintain — post-ship hotfix and maintenance workflow.

## Purpose
After all milestones are SHIPPED, the project enters maintenance mode.
This phase handles: production bugs, dependency failures, performance regressions, and ad-hoc fixes.
It is lighter than the full qf:1→4 cycle but still structured.

## Discipline Protocol
All bug investigation and fixing in this phase follows `_protocols/_systematic-debugging.md`.

<HARD-GATE>
Do NOT propose a fix until the investigation phase is complete and findings
are documented in .evidence/debug/. See _systematic-debugging.md for the
full 4-phase process.
</HARD-GATE>

## State Check
- Scan ./plans/ for feature directories where ALL milestones have QA-REPORT.md (= shipped)
- If no shipped project found: "No shipped project. Run `/quangflow:4-verify` to verify and ship first."
- If multiple features found: ask user which feature
- Read the latest STATUS.md for context

## Arguments
```
/quangflow:5-maintain              — Enter maintain mode (auto-detect project)
/quangflow:5-maintain scan         — Scan logs, build/refresh BUGLOG.md
/quangflow:5-maintain fix BUG-XXX  — Start hotfix for a specific bug
```

---

## Bug Log System

### Log Sources
The agent reads application logs from known locations. Convention:

```
./logs/                         <- project log directory
├── backend/                    <- BE logs
│   ├── error.log               <- errors + exceptions
│   ├── app.log                 <- general application log
│   └── access.log              <- HTTP access log (optional)
├── frontend/                   <- FE logs (if captured)
│   ├── error.log               <- JS errors, build failures
│   └── console.log             <- browser console captures
└── infra/                      <- infra logs (optional)
    ├── docker.log
    └── ci.log
```

If project uses different log locations (e.g. `/tmp/backend.log`, `nohup.out`):
- Check common patterns: `nohup.out`, `/tmp/*.log`, `*.log` in project root
- Ask user once: "Where are your log files?" and remember in CONTEXT.md

### Log Discovery Protocol
1. Check `./logs/` directory first
2. Check common locations: `nohup.out`, `/tmp/*.log`, `*.log` in root
3. Check CONTEXT.md for previously configured log paths
4. If nothing found, ask user

### Severity Classification
When reading logs, classify entries:

| Severity | Pattern | Priority |
|----------|---------|----------|
| **CRITICAL** | Unhandled exceptions, data loss, security breach, service down | Fix immediately |
| **ERROR** | Failed requests, broken features, exception traces | Fix in this session |
| **WARNING** | Deprecation, performance degradation, retry exhaustion | Triage — fix or defer |
| **INFO** | Expected behavior, debug traces | Skip unless user asks |

### Reading Strategy (Smart Log Reading)
Do NOT dump entire log files. Read strategically:

1. **Bookmark system**: Track last-read position in BUGLOG.md metadata
   ```yaml
   log_bookmarks:
     backend/error.log: { last_line: 1847, last_read: "2026-03-10T15:00:00" }
     frontend/error.log: { last_line: 203, last_read: "2026-03-10T15:00:00" }
   ```
2. **On `/quangflow:5-maintain scan`**: Read only lines AFTER the bookmark (new entries since last scan)
3. **On first scan**: Read last 200 lines of each log file (recent window)
4. **Dedup**: Group identical errors by stack trace signature, count occurrences
5. **Time window**: Default to last 24h. User can override: `/quangflow:5-maintain scan 7d`

### BUGLOG.md Format
Save to `./plans/{feature-slug}/BUGLOG.md`:

```markdown
# Bug Log — {feature-slug}

## Metadata
```yaml
last_scan: "2026-03-10T15:08:00+07:00"
log_bookmarks:
  backend/error.log: { last_line: 2041, last_read: "2026-03-10T15:08:00" }
  frontend/error.log: { last_line: 305, last_read: "2026-03-10T15:08:00" }
log_paths:
  backend: ["./logs/backend/error.log", "/tmp/backend.log"]
  frontend: ["./logs/frontend/error.log"]
```

## Active Bugs

### BUG-001 [CRITICAL] — Service X returns 500 on endpoint Y
- **Source:** backend/error.log:1823
- **First seen:** 2026-03-10 14:30
- **Occurrences:** 47
- **Stack trace:** (abbreviated)
- **Affected:** REQ-003, REQ-007
- **Status:** NEW
- **Fix:** (empty until assigned)

### BUG-002 [WARNING] — Deprecated API call in dependency Z
- **Source:** backend/app.log:4501
- **First seen:** 2026-03-09 08:00
- **Occurrences:** 12
- **Affected:** unknown
- **Status:** NEW

## Resolved Bugs
(moved here after fix verified)

## Deferred Bugs
(moved here if user chooses DEFER)
```

---

## Scan Flow (`/quangflow:5-maintain scan`)

1. Discover log files (see Log Discovery Protocol)
2. Read new entries since last bookmark
3. Parse and classify by severity
4. Dedup by error signature
5. Map errors to requirements/files where possible (grep stack traces for known files)
6. Update or create BUGLOG.md
7. Present summary:

```
Scan complete. Found {N} new issues since last scan:
- {X} CRITICAL — need immediate fix
- {Y} ERROR — fix recommended
- {Z} WARNING — triage needed

Top issues:
1. BUG-XXX [CRITICAL]: {description} (47 occurrences)
2. BUG-XXX [ERROR]: {description} (12 occurrences)
3. BUG-XXX [WARNING]: {description} (3 occurrences)

Actions:
- `/quangflow:5-maintain fix BUG-XXX` — start hotfix for a specific bug
- Type a BUG-ID to see full details
- Type TRIAGE to review all NEW bugs
```

Agent waits. Does nothing until user responds.

---

## Autopilot Triage
See `_protocols/_autopilot.md → Phase 5 — Maintain`. If autopilot: auto-triage by severity, present plain summary, proceed on OK.
On user objection: fall through to manual Triage Flow below.

---

## Triage Flow (user types TRIAGE)

For each NEW bug, starting with highest severity:

Present bug details and ask via `AskUserQuestion`:
```json
{
  "questions": [{
    "question": "BUG-XXX [SEVERITY]: {description}\nSource: {file}:{line}\nOccurrences: {N}\n\nWhat should we do?",
    "header": "Bug Triage",
    "options": [
      { "label": "FIX NOW", "description": "Start hotfix immediately" },
      { "label": "FIX LATER", "description": "Keep in active bugs, fix in future session" },
      { "label": "DEFER", "description": "Move to deferred — known issue, not blocking" },
      { "label": "IGNORE", "description": "Not a real bug / expected behavior" }
    ],
    "multiSelect": false
  }]
}
```

Update BUGLOG.md status per decision.
After triage, if any FIX NOW selected, proceed to Bug Dispatch.

---

## Bug Dispatch (after triage or multi-fix)

Count how many bugs are marked FIX NOW. Choose execution mode:

### Single bug (1 FIX NOW)
Proceed directly to Hotfix Flow below. Main agent handles it.

### Multiple bugs (2+ FIX NOW)
Present dispatch options to user:

```
{N} bugs marked FIX NOW:
- BUG-001 [CRITICAL]: {desc} — affects backend (app/services/*)
- BUG-003 [ERROR]: {desc} — affects frontend (src/components/*)
- BUG-005 [ERROR]: {desc} — affects backend (app/api/*)

Execution mode:
1. **Sequential** — fix one at a time (safest, no conflicts)
2. **Parallel agents** — spawn debugger agents per domain (faster, needs distinct file ownership)
```

**If Sequential (default):** Fix highest-severity first, one by one via Hotfix Flow.

**If Parallel agents:**
- Group bugs by affected domain (backend, frontend, infra) based on stack trace files
- Spawn one `debugger` agent per domain group:
  ```
  Task(subagent_type: "debugger", name: "fix-backend")
    Prompt: BUGLOG.md context + BUG-001, BUG-005 details + file ownership: app/**
  Task(subagent_type: "debugger", name: "fix-frontend")
    Prompt: BUGLOG.md context + BUG-003 details + file ownership: src/**
  ```
- **File ownership rules**: Each agent only edits files in its domain. Shared files (configs, types) stay with main agent.
- Monitor completion, collect results, update BUGLOG.md
- Run full test suite after all agents complete

### Assignment tracking
When bugs are dispatched (sequential or parallel), update BUGLOG.md entries:
```markdown
- **Status:** IN PROGRESS
- **Assigned:** {agent-name or "main"}
- **Started:** {timestamp}
```

---

## Escalation — Requirement-Level Issues
During investigation, if a bug reveals a missing or incorrect requirement (not just a code bug):

1. Log it in BUGLOG.md with tag `ESCALATION: requirement gap`
2. Present to user:
   "This bug points to a requirement gap — not just a code issue:
   - **Gap:** {description of what's missing}
   - **Impact:** {which flows are affected}

   Options:
   - **Fix here** — Patch it in maintain mode (quick fix, may not be complete)
   - **Escalate** — Run `/quangflow:1-brainstorm` to properly scope this as a new requirement (uses the short milestone-2+ confirmation flow)"

3. If user picks **Escalate**: stop maintain flow, tell user to run `/quangflow:1-brainstorm {feature-slug}` which will use the milestone-2+ short confirmation flow to add the new requirement properly
4. If user picks **Fix here**: proceed with the fix as a normal bug

---

## Hotfix Flow (`/quangflow:5-maintain fix BUG-XXX`)

Lighter than full qf:1→4 cycle. No brainstorm, no milestone, no team pipeline.

### Step 1: Investigate
Follow `_protocols/_systematic-debugging.md` Phase 1 (Observe) and Phase 2 (Hypothesize):

- Read the bug entry from BUGLOG.md
- Read structured logs: check `.evidence/logs/` for relevant `*.jsonl` files, filter by correlation ID or timestamp
- Read the source log lines (full context around the error)
- Read the affected source files (from stack trace)
- Identify root cause using systematic debugging process
- Save findings to `.evidence/debug/BUG-{ID}-investigation.md`
- Present to user:

```
**BUG-XXX Investigation:**
- **Root cause:** {explanation}
- **Affected files:** {list}
- **Proposed fix:** {brief description}
- **Risk:** {what else could break}
- **Tests needed:** {what to test after fix}
- **Evidence:** .evidence/debug/BUG-{ID}-investigation.md

Proceed with fix? (YES / ADJUST / SKIP)
```

Agent waits for user response.

### Step 2: Fix (TDD required)
- **Write failing test FIRST** — reproduce the bug as a failing test case
- Save red evidence: `.evidence/tdd/BUG-{ID}-red.log`
- Apply the fix to affected files (root cause, not symptoms)
- Run the failing test — it should now pass
- Save green evidence: `.evidence/tdd/BUG-{ID}-green.log`
- Run existing tests to check for regressions
- If tests fail: diagnose, fix, repeat
- **Escalation rule:** If fix attempt fails 3+ times, stop and present findings to user. Do NOT keep retrying blindly.

### Step 3: Verify
- Run full test suite (or targeted tests for affected area)
- Check the specific error no longer appears in logs (if server is running)
- Update BUGLOG.md: move bug to Resolved with fix details

```markdown
### BUG-XXX [CRITICAL] — Service X returns 500 on endpoint Y
- **Status:** RESOLVED
- **Fixed:** 2026-03-10 15:30
- **Fix:** Replaced vnstock3 API with VNDirect direct API (dependency was IP-banned)
- **Files changed:** app/services/fundamental_service.py, tests/test_fundamental_service.py
- **Regression test:** test_fundamental_service.py::test_api_failure_returns_all_null
```

### Step 4: Log Gotcha & Resolution Evidence
Save resolution to `.evidence/debug/BUG-{ID}-resolution.md` with: root cause, fix applied, files changed, tests added.

See `_protocols/_shared.md → GOTCHAs System → Logging Protocol`.
After each bug fix, auto-create a gotcha entry in `plans/{feature-slug}/GOTCHAS.md`:
- Domain tag: infer from affected files
- Rule: what should have prevented this bug (missing test, bad assumption, unchecked edge case)
- Tags: include `phase-4` if tests should have caught it, `phase-2` if design was flawed, etc.

### Step 5: Commit (optional)
Ask user: "Fix verified. Commit? (YES / NO)"
If YES, create conventional commit: `fix: {brief description} (BUG-XXX)`

---

## Dependency Failure Protocol

When a bug is caused by an external dependency breaking (API down, library deprecated, service IP-banned):

1. **Classify as dependency failure** in BUGLOG.md: add `type: dependency-failure`
2. **Research alternatives** — spawn `researcher` agent to find replacement APIs/libraries
3. **Present options** to user (similar to Phase 2 design options but scoped to the dependency):
   ```
   Dependency failure: {library/API} — {what broke}

   Alternatives:
   1. {Alternative A}: {pros/cons}
   2. {Alternative B}: {pros/cons}
   3. {Workaround}: {temporary fix}

   Which approach? (1/2/3)
   ```
4. **Implement replacement** using Hotfix Flow (Step 2-4)
5. **Update CONTEXT.md** with the dependency decision for future reference

---

## Recurring Issues Detection

When scanning, check for patterns:
- Same error recurring across multiple scans → flag as **chronic issue**
- Errors that were RESOLVED but reappear → flag as **regression**
- Errors correlated with specific times (e.g., market hours) → flag as **time-dependent**

Present recurring patterns in scan summary:
```
Recurring patterns detected:
- BUG-003 was resolved on 03/08 but reappeared (regression)
- BUG-007 only occurs between 09:00-15:00 (time-dependent)
```

---

## Exit Maintain Mode

When user is done:
- Ensure all FIX NOW bugs are resolved or reclassified
- Update BUGLOG.md with final state
- Update STATUS.md: `phase: maintain, status: idle`
- Print: "Maintenance session complete. {X} bugs fixed, {Y} deferred, {Z} new. Resume with `/quangflow:5-maintain` next session."

## Output Rule
See `_protocols/_shared.md → Output Rule`.
