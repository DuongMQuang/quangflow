# QuangFlow Showcase — Build a Task Tracker

A hands-on walkthrough that takes you through every QuangFlow phase by building a real task tracker app. You'll run each command yourself and see the workflow in action.

**What you'll build:** A full-stack task tracker with user auth, task CRUD, and a dashboard.
**Time:** ~30-60 minutes (depending on how deep you go at each phase)
**Prerequisites:** QuangFlow installed, Claude Code running

---

## Setup

```bash
# Create a new project
mkdir task-tracker && cd task-tracker
git init

# Start Claude Code
claude
```

---

## Phase 0 — Init

Scan the project and set up context.

```
/qf:0-init task tracker with user auth and dashboard
```

**What happens:**
- Asks if you're technical or non-technical (pick **technical** for this walkthrough)
- Asks if this is an existing or new project (pick **new**)
- Creates `plans/task-tracker/CONTEXT.md` with project metadata
- Creates `plans/task-tracker/OPEN_QUESTIONS.md`

**Check the output:**
```bash
cat plans/task-tracker/CONTEXT.md
```

You should see: `pm_mode: hands-on`, `project_type: new`, and an empty Tech Stack section.

---

## Phase 1 — Brainstorm

Discover requirements through structured questions.

```
/qf:1-brainstorm
```

**What happens:**
- Asks clarifying questions in batches (max 5 per round)
- Covers: core problem, users, success metrics, edge cases, out of scope
- Plays devil's advocate on your requirements
- Recommends milestone split (likely 1 milestone for this scope)
- Asks about team mode (pick **Solo** for this walkthrough)

**Answer the questions honestly.** Example answers:
- "Users are developers tracking personal tasks"
- "Success = tasks can be created, edited, completed, filtered"
- "Out of scope: collaboration, notifications, mobile app"

**When asked to APPROVE:** Type `APPROVE`

**Check the output:**
```bash
cat plans/task-tracker/REQUIREMENTS.md
```

You should see: REQ-IDs, edge cases, milestone tags [M1], `team_mode: false`.

**Also check:**
```bash
cat plans/task-tracker/PROGRESS.md
```

Phase 0 and Phase 1 should be logged in the timeline.

---

## Phase 2 — Design

Explore architecture options with trade-offs.

```
/qf:2-design
```

**What happens:**
- Reviews GOTCHAs (none yet — first project)
- Lists tension points in your requirements
- Researches applicable design patterns
- Proposes 2-3 architecture options with pros/cons
- Evaluates scalability gates (10x, 100x)

**Pick an option** when asked. For a task tracker, a simple MVC/REST option is usually best.

**Check the output:**
```bash
cat plans/task-tracker/milestone-1/DESIGN.md
```

You should see: chosen option, rejected options with reasons, tension analysis, scalability gates.

---

## Phase 3 — Handoff

Generate execution artifacts.

```
/qf:3-handoff
```

**What happens:**
- Reviews GOTCHAs again (still none)
- Finalizes REQUIREMENTS.md with acceptance criteria per REQ
- Generates ROADMAP.md with numbered phases, deliverables, done criteria
- Updates CONTEXT.md with locked decisions
- Asks you to CONFIRM

**Type `CONFIRM`** when ready.

Since we picked Solo mode, it will suggest implementing ROADMAP phases manually.

**Check the output:**
```bash
cat plans/task-tracker/milestone-1/ROADMAP.md
```

You should see: numbered phases with specific files to create, deliverables, and done criteria.

---

## Implement (Solo Mode)

Now implement the ROADMAP phases. You can do this yourself or ask Claude:

```
Implement Phase 1 from plans/task-tracker/milestone-1/ROADMAP.md
```

Repeat for each phase in the ROADMAP. Claude will:
- Read the ROADMAP phase
- Create the specified files
- Run compile/lint checks

---

## Phase 4 — Verify

Run QA/QC on your implementation.

```
/qf:4-verify
```

**What happens:**
- Runs artifact validation script (checks plan file structure)
- Maps each REQ-ID to implementation files (traceability)
- Generates tests (unit, integration)
- Runs tests
- Detects gaps (missing edge cases, tech debt)
- Logs GOTCHAs for any gaps found

**If all PASS:** Type `SHIP`
**If any FAIL:** Fix issues and re-run `/qf:4-verify`
**If gaps found:** Choose ADD (fix now), DEFER (later), or IGNORE per gap

**Check the output:**
```bash
cat plans/task-tracker/milestone-1/QA-REPORT.md
cat plans/task-tracker/GOTCHAS.md  # if any gaps were found
cat plans/task-tracker/PROGRESS.md  # timeline updated
```

---

## Phase 5 — Maintain (optional)

If you want to see the maintenance workflow:

1. Add some fake errors to a log file:
```bash
mkdir -p logs/backend
cat > logs/backend/error.log << 'EOF'
2026-03-24 10:00:00 ERROR Failed to validate task input: missing title
  File "src/api/tasks.py", line 23, in create_task
2026-03-24 10:05:00 CRITICAL Unhandled exception: database connection refused
  File "src/services/task_service.py", line 45, in get_tasks
EOF
```

2. Run maintain:
```
/qf:5-maintain scan
```

**What happens:**
- Discovers log files
- Classifies errors by severity (CRITICAL, ERROR, WARNING, INFO)
- Deduplicates identical errors
- Creates `plans/task-tracker/BUGLOG.md`

3. Triage bugs:
```
Type TRIAGE
```

4. Fix a bug:
```
/qf:5-maintain fix BUG-001
```

---

## Bonus: Team Mode

Want to see the full agent team pipeline? Start a new feature with team mode:

```
/qf:0-init e-commerce checkout flow
/qf:1-brainstorm
```

When asked about team mode, pick **Agent Team**. Then:

```
/qf:2-design
/qf:3-handoff
```

When asked SHIP/REFINE/SOLO, pick **SHIP** to launch the team pipeline.

```
/qf:cook
```

**What happens:**
- Domain-engineer designs modules and contracts
- Critics debate the design (feasibility + simplicity)
- Dev agents implement in parallel (with worktree isolation if 2+ devs)
- Tech-lead reviews cross-dev integration
- Tester generates and runs tests
- PM produces status report

Watch the pipeline progress in real-time. All artifacts save to `plans/e-commerce-checkout/milestone-1/`.

---

## What You Produced

After the full walkthrough, your `plans/` directory looks like:

```
plans/
├── GOTCHAS.md                    ← global lessons
└── task-tracker/
    ├── REQUIREMENTS.md           ← requirements with REQ-IDs
    ├── CONTEXT.md                ← locked decisions
    ├── OPEN_QUESTIONS.md         ← unresolved items
    ├── PROGRESS.md               ← project timeline
    └── milestone-1/
        ├── DESIGN.md             ← chosen architecture
        ├── ROADMAP.md            ← execution plan
        ├── QA-REPORT.md          ← test results + coverage
        └── design/               ← (team mode only)
```

---

## Quick Reference

| Phase | Command | Gate | Output |
|-------|---------|------|--------|
| 0 | `/qf:0-init <idea>` | — | CONTEXT.md |
| 1 | `/qf:1-brainstorm` | APPROVE | REQUIREMENTS.md |
| 2 | `/qf:2-design` | Pick option | DESIGN.md |
| 3 | `/qf:3-handoff` | CONFIRM → SHIP/SOLO | ROADMAP.md |
| 4 | `/qf:4-verify` | SHIP | QA-REPORT.md |
| 5 | `/qf:5-maintain` | FIX NOW/DEFER | BUGLOG.md |
| — | `/qf:status` | — | Status report |
| — | `/qf:quick <task>` | SHIP | Minimal artifacts |
| — | `/qf:cook` | — | Team pipeline |
| — | `/qf:test` | — | Validation report |
