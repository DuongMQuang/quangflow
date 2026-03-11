You are the QuangFlow self-test runner — validates the entire flow in a sandbox before real use.

## Purpose
Run a simulated project through all QuangFlow phases (1→5) using a synthetic test case.
Catches: broken file references, missing gates, bad prompt logic, file creation failures.
Does NOT touch real project code. Everything happens in a temp sandbox.

## Arguments
```
/qf-t              — Full test: phases 1→5 in sandbox
/qf-t quick        — Quick test: validate file structure + command availability only
/qf-t phase N      — Test a specific phase (1-5) in isolation
```

---

## Sandbox Setup

1. Create temp sandbox directory:
   ```
   /tmp/quangflow-test-{timestamp}/
   ├── plans/
   ├── logs/
   │   ├── backend/
   │   └── frontend/
   ├── src/
   │   ├── api/
   │   ├── services/
   │   ├── components/
   │   └── models/
   └── tests/
   ```

2. Create minimal synthetic source code in `src/`:
   - `src/api/users.py` — simple CRUD endpoint stub (20 lines)
   - `src/services/user_service.py` — business logic stub (15 lines)
   - `src/models/user.py` — data model stub (10 lines)
   - `src/components/user-list.tsx` — simple component stub (15 lines)
   - `tests/test_user_service.py` — one passing test stub

3. Create synthetic log files in `logs/`:
   - `logs/backend/error.log` — 5 sample errors (2 CRITICAL, 2 ERROR, 1 WARNING)
   - `logs/frontend/error.log` — 2 sample errors (1 ERROR, 1 WARNING)

These stubs need only be syntactically valid, not functional. They exist to give each phase something to work with.

---

## Quick Test (`/qf-t quick`)

Validate structural prerequisites without running phases:

### Checks
| # | Check | How |
|---|-------|-----|
| 1 | Command files exist | Glob for `qf-{0,1,2,3,4,5,c,s,t}/*.md` in commands dir |
| 2 | Agent files exist | Glob for `agents/*.md` (domain-engineer, dev-teammate, tech-lead, tester, pm) |
| 3 | CLAUDE.md template valid | Read template, verify all 5 phases referenced |
| 4 | No broken cross-references | Grep all command files for `/qf-` references, verify each target exists |
| 5 | Severity levels consistent | Grep qf-5 for CRITICAL/ERROR/WARNING/INFO, verify all 4 present |
| 6 | Gate keywords present | Verify each phase has its gate: APPROVE (qf-1), choice (qf-2), CONFIRM (qf-3), SHIP (qf-4) |
| 7 | Status command covers all phases | Read qf-s, verify it references phases 1-5 + maintain |
| 8 | File naming consistency | Check all referenced file names (BUGLOG.md, STATUS.md, etc.) are consistent across commands |

### Output
```
QuangFlow Quick Test
====================
[PASS] Command files: 8/8 found
[PASS] Agent files: 5/5 found
[PASS] Template references: all 5 phases
[PASS] Cross-references: 0 broken
[PASS] Severity levels: all 4 in qf-5
[PASS] Gate keywords: all phases have gates
[PASS] Status coverage: phases 1-5 + maintain
[PASS] File naming: consistent

Result: 8/8 passed. QuangFlow is structurally valid.
```

Or if failures:
```
[FAIL] Agent files: missing tester.md
  -> Expected: agents/tester.md
  -> Fix: Create agent file or update reference in qf-c
```

---

## Full Test (`/qf-t`)

Runs each phase in sequence against the sandbox, validating inputs/outputs.

### Phase 0 Simulation (init)
**Input:** Synthetic idea: "user management CRUD with auth"
**Validate:**
- [ ] Feature slug created (e.g., `user-management`)
- [ ] `plans/user-management/` directory created
- [ ] CONTEXT.md written with: metadata, tech stack, project structure
- [ ] `quangflow_version` present in metadata
- [ ] `pm_mode` field present
- [ ] OPEN_QUESTIONS.md created

**Synthetic CONTEXT.md** (write directly):
```markdown
# Context — user-management

## Metadata
```yaml
quangflow_version: "1.1.0"
pm_mode: hands-on
project_type: existing
scan_depth: medium
created: 2026-03-11T14:00:00+07:00
```

## Tech Stack
- Python 3.11 + FastAPI + SQLAlchemy
- React 18 + TypeScript

## Project Structure
- src/api/ — API endpoints
- src/services/ — Business logic
- src/models/ — Data models
- src/components/ — React components

## Existing Patterns
- Repository pattern for data access
- JWT auth middleware

## Dependencies
- fastapi, sqlalchemy, pyjwt, react, typescript

## Constraints
- Must use existing JWT middleware

## Locked Decisions
(populated by later phases)
```

**Result:** PASS if file created with all sections

### Phase 1 Simulation (brainstorm)
**Input:** Read synthetic CONTEXT.md
**Validate:**
- [ ] REQUIREMENTS.md written with: problem, personas, success metrics, edge cases, out-of-scope
- [ ] Milestone tags present ([M1] at minimum)
- [ ] team_mode field present (true or false)
- [ ] If team_mode true: team_composition YAML is valid

**Synthetic REQUIREMENTS.md** (write directly, don't actually run qf-1 interactively):
```markdown
# Requirements — user-management

## Problem
Users need CRUD operations with authentication.

## Requirements
- [M1] REQ-001: User registration with email/password
- [M1] REQ-002: Login endpoint returns JWT
- [M1] REQ-003: List users (admin only)
- [M1] REQ-004: User profile page (frontend)

## Edge Cases
- Duplicate email registration
- Expired JWT handling
- Empty user list

## Out of Scope
- OAuth providers
- Email verification

## Execution
team_mode: false
```

**Result:** PASS if file created with all sections / FAIL with missing section name

### Phase 2 Simulation (design)
**Input:** Read synthetic REQUIREMENTS.md
**Validate:**
- [ ] `plans/user-management/milestone-1/` directory created
- [ ] DESIGN.md written with: chosen option, rejected options, tension analysis
- [ ] Design references requirement IDs (REQ-001, etc.)
- [ ] Scalability gates section present

**Synthetic DESIGN.md** (write directly):
```markdown
# Design — user-management / milestone-1

## Chosen: Simple MVC with JWT auth
- FastAPI endpoints + SQLAlchemy models + JWT middleware
- Pattern: Repository pattern for data access

## Rejected
- Option B: Microservices — overkill for 4 requirements

## Tension Analysis
- Auth middleware vs per-route guards: chose middleware (simpler)

## Scalability Gates
- 10x users: add Redis session cache
- 100x: move to dedicated auth service
```

**Result:** PASS if file created with all sections

### Phase 3 Simulation (handoff)
**Input:** Read REQUIREMENTS.md + DESIGN.md
**Validate:**
- [ ] ROADMAP.md created with numbered phases
- [ ] Each phase has: deliverable, done criteria
- [ ] REQUIREMENTS.md updated: REQ IDs have acceptance criteria, status FINAL
- [ ] CONTEXT.md created or updated
- [ ] OPEN_QUESTIONS.md exists

**Synthetic ROADMAP.md** (write directly):
```markdown
# Roadmap — milestone-1

## Phase 1: Database models + migrations
- Deliverable: User model, migration script
- Done: Model created, migration runs without error
- Files: src/models/user.py, migrations/

## Phase 2: Auth endpoints
- Deliverable: /register, /login, /me endpoints
- Done: All 3 return correct responses
- Files: src/api/users.py, src/services/user_service.py

## Phase 3: Frontend user list
- Deliverable: User list component
- Done: Renders user data from API
- Files: src/components/user-list.tsx

## Phase 4: Tests
- Deliverable: Unit + integration tests
- Done: 80%+ coverage, all pass
- Files: tests/
```

**Result:** PASS if all files created

### Phase 4 Simulation (verify)
**Input:** Read REQUIREMENTS.md + DESIGN.md + ROADMAP.md + synthetic source code
**Validate:**
- [ ] QA-REPORT.md created
- [ ] Requirement traceability: each REQ-ID mapped to file(s)
- [ ] Test section references test files
- [ ] PASS/FAIL/WARN per requirement
- [ ] GAPS.md created (even if empty)

**Synthetic QA-REPORT.md** (write directly):
```markdown
# QA Report — milestone-1

## Requirement Coverage
| REQ | Status | Files | Tests |
|-----|--------|-------|-------|
| REQ-001 | PASS | src/models/user.py, src/api/users.py | test_user_service.py |
| REQ-002 | PASS | src/api/users.py | test_user_service.py |
| REQ-003 | PASS | src/api/users.py | test_user_service.py |
| REQ-004 | PASS | src/components/user-list.tsx | — |

## Test Results
- Total: 4, Passed: 4, Failed: 0

## Gaps
None detected.
```

**Result:** PASS if coverage matrix complete

### Phase 5 Simulation (maintain)
**Input:** Synthetic log files in `logs/`
**Validate:**
- [ ] BUGLOG.md created
- [ ] Log bookmarks populated
- [ ] Bugs classified by severity (CRITICAL, ERROR, WARNING)
- [ ] Bug IDs assigned (BUG-001, BUG-002, ...)
- [ ] Dedup works (identical errors grouped)
- [ ] Affected files mapped from stack traces

**Synthetic log content** (`logs/backend/error.log`):
```
2026-03-10 14:00:01 ERROR Failed to connect to database: Connection refused
  File "src/services/user_service.py", line 23, in get_user
2026-03-10 14:00:02 ERROR Failed to connect to database: Connection refused
  File "src/services/user_service.py", line 23, in get_user
2026-03-10 14:30:00 CRITICAL Unhandled exception in /api/users: TypeError: NoneType
  File "src/api/users.py", line 45, in list_users
2026-03-10 14:31:00 CRITICAL Unhandled exception in /api/users: TypeError: NoneType
  File "src/api/users.py", line 45, in list_users
2026-03-10 15:00:00 WARNING Deprecated: use new_auth() instead of old_auth()
  File "src/services/user_service.py", line 10
```

**Validate BUGLOG.md output:**
- [ ] 3 unique bugs (not 5 — dedup should merge identical errors)
- [ ] BUG-001 [CRITICAL] — 2 occurrences
- [ ] BUG-002 [ERROR] — 2 occurrences
- [ ] BUG-003 [WARNING] — 1 occurrence
- [ ] Bookmarks set to end of file

**Result:** PASS if correct bug count + severity + dedup

### Status Simulation
After all phases, validate `/qf-s` would produce correct output:
- [ ] Detects "all milestones shipped"
- [ ] Reports bug log state from BUGLOG.md
- [ ] Suggests `/qf-5 scan` as next command

---

## Test Report

After all phases complete, generate summary:

```
QuangFlow Full Test Report
==========================
Sandbox: /tmp/quangflow-test-{timestamp}/

Phase 0 (init):        [PASS] CONTEXT.md + OPEN_QUESTIONS.md — 7/7 sections
Phase 1 (brainstorm):  [PASS] REQUIREMENTS.md — 6/6 sections
Phase 2 (design):      [PASS] DESIGN.md — 4/4 sections
Phase 3 (handoff):     [PASS] ROADMAP.md + CONTEXT.md updated — 5/5 files
Phase 4 (verify):      [PASS] QA-REPORT.md — coverage matrix complete
Phase 5 (maintain):    [PASS] BUGLOG.md — 3 bugs detected, dedup correct
Status:                [PASS] Detects shipped state + bug log

Result: 7/7 phases passed. QuangFlow is ready for use.

Sandbox kept at: /tmp/quangflow-test-{timestamp}/
  -> Inspect artifacts: ls /tmp/quangflow-test-{timestamp}/plans/
  -> Clean up: rm -rf /tmp/quangflow-test-{timestamp}/
```

If any failures:
```
Phase 5 (maintain):    [FAIL] BUGLOG.md — expected 3 bugs, found 5 (dedup broken)
  -> Check: qf-5 dedup logic in "Dedup by error signature" section
  -> Sandbox preserved for inspection
```

---

## Phase Isolation Test (`/qf-t phase N`)

Test a single phase. Creates minimal prerequisites for that phase:
- `/qf-t phase 1` — just sandbox + stubs, run phase 1 validation
- `/qf-t phase 3` — creates REQUIREMENTS.md + DESIGN.md, then validates phase 3 output
- `/qf-t phase 5` — creates all prior artifacts + log files, validates maintain phase

Useful for iterating on a specific phase after making changes.

---

## Important Notes
- All artifacts are **written directly** (synthetic data), NOT by running actual qf-1→4 interactively
- The test validates the **expected contract** of each phase: what files it should create, what sections they contain, what cross-references exist
- Test does NOT validate prompt quality or agent behavior — only structural contracts
- Sandbox is preserved after test for manual inspection
- Run `/qf-t` after modifying any command file to catch regressions

## Output Rule
When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.
