# Pipeline State & Team Config Persistence

Referenced by `cook.md`. Tracks pipeline progress and persists team configuration for session resume.

## Pipeline State Tracking

Track progress in `plans/{feature-slug}/milestone-{N}/PIPELINE-STATE.md`.
Enables crash recovery via `--from` flag.

**CRITICAL: Write state BEFORE each stage starts (not just after completion).**
This ensures that if the session crashes mid-stage, the state file records which stage was in progress.

**Update at two points per stage:**
1. **Before stage starts:** mark as `IN_PROGRESS`
2. **After stage completes:** mark as `completed`

## PIPELINE-STATE.md Schema

```markdown
# Pipeline State — {feature-slug} / Milestone {N}
Updated: {timestamp}

## Mode
pm_mode: {hands-on | autopilot}
hands_free: {true | false}

## Completed Stages
- [x] domain-engineer — completed {timestamp}
- [x] devs — completed {timestamp}, agents: dev-backend, dev-frontend
- [~] tech-lead — IN_PROGRESS since {timestamp}
- [ ] tester
- [ ] pm

## Last Completed Stage
devs

## Currently Running
tech-lead (started {timestamp})

## Resume Command
`/quangflow:cook --from tech-lead`

## Team Config
```yaml
model_assignments:
  domain-engineer: sonnet
  critic-feasibility: haiku
  critic-simplicity: haiku
  dev-backend: sonnet
  dev-frontend: haiku
  tech-lead: sonnet
  tester: sonnet
  pm: haiku

worktree_branches:
  dev-backend: qf/user-auth/m1/dev-backend
  dev-frontend: qf/user-auth/m1/dev-frontend

phase_assignments:
  dev-backend:
    phases: [1, 3]
    reqs: [REQ-001, REQ-002, REQ-003]
    ownership: "src/api/*, src/models/*, src/services/*"
  dev-frontend:
    phases: [2, 4]
    reqs: [REQ-004]
    ownership: "src/components/*, src/pages/*"
\```
```

## Writing Team Config

Cook writes the `## Team Config` section during pre-flight, AFTER:
- Complexity assessment completes (model assignments decided)
- Phase-to-dev mapping completes (from ROADMAP + team_composition)
- Worktree branch names generated (if 2+ devs)

This happens ONCE at pipeline start. The config persists across sessions.

## Resume Protocol (`--from` flag)

1. Read PIPELINE-STATE.md to verify the claimed stage was actually reached
2. If `## Team Config` exists: use persisted model_assignments, worktree_branches, phase_assignments — do NOT re-derive
3. Re-compute scoped context slicing fresh from current artifacts (avoids drift)
4. If `## Team Config` is missing (legacy or first run): fall back to re-deriving everything
5. If state file missing: warn "No pipeline state found. Run full pipeline or use `--only`?"
6. If requested stage hasn't been reached: warn "Stage `{stage}` requires `{previous}` to complete first."
7. If stage marked `IN_PROGRESS`: warn "Stage `{stage}` was interrupted. Re-running it."
8. If CHECKPOINT-{role}.md exists for interrupted stage: inject checkpoint into replacement agent prompt

## On Crash/Interruption

- PIPELINE-STATE.md preserves what completed, what's in progress, AND team config
- User runs `/quangflow:status` to see resume command
- User runs `/quangflow:cook --from {interrupted-or-next-stage}` to continue
- Resumed pipeline uses persisted team config — no re-derivation surprises
