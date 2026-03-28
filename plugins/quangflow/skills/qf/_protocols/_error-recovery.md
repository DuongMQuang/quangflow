# Error Recovery (Checkpoint-Based Retry)

Referenced by `cook.md`. When an agent fails, the replacement should RESUME, not restart from scratch.

## Checkpoint Protocol

Dev agents write progress to `plans/{slug}/milestone-{N}/CHECKPOINT-{role}.md` after each major step:

```markdown
# Checkpoint — {role}
Updated: {timestamp}
## Completed
- [x] Created src/api/users.ts (Phase 1)
- [x] Created src/models/user.ts (Phase 1)
- [ ] Create src/services/user-service.ts (Phase 2) — IN PROGRESS
## Files Created
- src/api/users.ts
- src/models/user.ts
## Current Step
Phase 2: Implementing user-service.ts — writing createUser function
## Decisions Made
- D-003: Used bcrypt for password hashing (logged to DECISIONS.md)
```

## On Agent Failure

1. Read CHECKPOINT-{role}.md to understand what was completed
2. Spawn replacement agent with: original prompt + "RESUME from checkpoint — already completed: {list}. Continue from: {current step}"
3. Replacement agent reads existing files (already created by failed agent) and continues

## On Agent Timeout (stuck >5 min)

1. Message agent first: "Status check — are you blocked?"
2. If no response in 2 min: terminate and retry with checkpoint

## Other Recovery Rules

- If dev plan rejected twice: lead takes over that task directly
- Lead NEVER implements code — only coordinates. If forced to take over, spawn a new dev agent.
- If worktree merge has conflicts: present conflicts to user, do NOT auto-resolve
