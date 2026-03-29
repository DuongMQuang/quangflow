# Dev Coordination Protocols

Referenced by `cook.md`. Covers cross-talk during parallel dev implementation and streaming pipeline optimization.

## Shared Decisions Log

`plans/{slug}/milestone-{N}/DECISIONS.md` — append-only log for implementation decisions not pre-planned in CONTRACTS.md.

```markdown
# Decisions — Milestone {N}

### D-001 [{agent}] — {one-line decision}
- **Context:** {why this decision was needed}
- **Choice:** {what was decided}
- **Affects:** {which modules/agents should know}
```

**Rules:**
- Any dev agent can append to DECISIONS.md during implementation
- Agents MUST read DECISIONS.md before starting work (injected in prompt)
- Lead monitors DECISIONS.md for cross-boundary impacts
- Decisions that contradict CONTRACTS.md must be flagged to lead immediately

## Dev Cross-Talk Protocol

During parallel implementation, devs may send concerns to lead via `SendMessage`:
- Cross-boundary issues (e.g., "I need endpoint X but it's in dev-backend's scope")
- Shared type disagreements (e.g., "CONTRACTS.md says X but I think it should be Y")
- Blocking dependencies (e.g., "I can't proceed until dev-backend creates the auth middleware")

**Lead handles cross-talk by batching:**
1. Collect concerns from all devs as they arrive
2. Do NOT relay concerns between devs directly (prevents cascading conversations)
3. When a concern requires user decision: present it immediately
4. When a concern is resolvable by lead: resolve and message the dev back
5. When a concern affects multiple devs: wait until all devs complete, then address in Stage 3

## Streaming Pipeline (optional optimization)

When tech-lead is enabled AND multiple devs are running:
- Tech-lead can start reviewing the FIRST completed dev's output while other devs still work
- Spawn tech-lead with `--partial` flag after first dev completes
- Tech-lead reviews completed code, queues findings, waits for remaining devs
- When all devs complete: tech-lead finishes full cross-dev integration review
- This overlaps Stage 2 and Stage 3, saving wall-clock time

**When to stream:** Only if 3+ devs AND tech-lead is enabled. For 2 devs, overhead isn't worth it.
**Fallback:** If streaming causes issues, revert to sequential (all devs → then tech-lead).
