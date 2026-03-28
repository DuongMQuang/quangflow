y# Discipline Layer — Implementation Plan Index

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Embed TDD enforcement, systematic debugging, verification gates, hard gates, structured logging, and feature memory into QuangFlow's existing phases — plus eliminate solo mode.

**Architecture:** Six new protocol files in `commands/qf/_protocols/`, six new scripts in `scripts/`, modifications to four existing phase files and two agent files. All protocols use hard gates (prompt-level) backed by script enforcement (system-level).

**Tech Stack:** Bash (scripts), Markdown (protocols/phases/agents)

**Spec:** `docs/superpowers/specs/2026-03-28-discipline-layer-design.md`

---

## Execution Order

Plans must be executed in this order — each depends on the previous.

| # | Plan | Tasks | Creates / Modifies | Depends on |
|---|------|-------|--------------------|------------|
| 1 | @plan-protocols | 6 tasks | 6 new protocol files | — (foundation) |
| 2 | @plan-scripts | 2 tasks | 6 new scripts (validation + hooks) | @plan-protocols |
| 3 | @plan-phase-mods | 5 tasks | 4 phase files + _shared.md | @plan-protocols, @plan-scripts |
| 4 | @plan-agent-mods | 2 tasks | dev-teammate.md, tester.md | @plan-protocols |
| 5 | @plan-validation-update | 1 task | validate-stage-completion.sh | @plan-scripts |
| 6 | @plan-integration-test | 1 task | (verification only) | all above |

## Plan Files

- `01-protocols.md` — Create the 6 new protocol files (@plan-protocols)
- `02-scripts.md` — Create validation + hook scripts (@plan-scripts)
- `03-phase-mods.md` — Modify phase files + _shared.md (@plan-phase-mods)
- `04-agent-mods.md` — Evolve dev-teammate and tester agents (@plan-agent-mods)
- `05-validation-update.md` — Update validate-stage-completion.sh (@plan-validation-update)
- `06-integration-test.md` — Final verification across all files (@plan-integration-test)

## File Structure Summary

### New files (12):
- `commands/qf/_protocols/_hard-gates.md`
- `commands/qf/_protocols/_tdd-enforcement.md`
- `commands/qf/_protocols/_systematic-debugging.md`
- `commands/qf/_protocols/_verification-gates.md`
- `commands/qf/_protocols/_structured-logging.md`
- `commands/qf/_protocols/_context-memory.md`
- `scripts/validate/validate-tdd-coverage.sh`
- `scripts/validate/validate-evidence.sh`
- `scripts/validate/validate-memory.sh`
- `scripts/hooks/auto-checkpoint.sh`
- `scripts/hooks/evidence-tracker.sh`
- `scripts/hooks/save-feature-memory.sh`

### Modified files (8):
- `commands/qf/_protocols/_shared.md`
- `commands/qf/3-handoff.md`
- `commands/qf/4-verify.md`
- `commands/qf/5-maintain.md`
- `commands/qf/quick.md`
- `agents/dev-teammate.md`
- `agents/tester.md`
- `scripts/validate/validate-stage-completion.sh`
