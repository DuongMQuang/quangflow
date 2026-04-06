# Context Limits Protocol

Referenced by `dev-teammate.md`, `cook.md`, and `_shared.md`. Prevents hallucination from context window exhaustion.

---

## HARD-GATE

<HARD-GATE>
No agent may continue working past 70% context window usage.
At 70%: checkpoint, commit, terminate. Orchestrator spawns fresh replacement.
</HARD-GATE>

---

## Thresholds

| Level | Action | Who |
|-------|--------|-----|
| 50% | Warning — log to CHECKPOINT-{role}.md | Any agent |
| 60% | Warning + auto-save all progress | Any agent |
| 70% | HARD STOP — checkpoint + commit + terminate | Any agent |

## Agent Behavior at 70%

When an agent detects it is approaching 70% context usage:

1. **Complete current sub-task** (not phase — the smallest unit of work)
2. **Commit all work-in-progress** with message: `wip: checkpoint at 70% context limit`
3. **Write CHECKPOINT-{role}.md** with:
   - Completed items (checked)
   - Current item (in progress)
   - Remaining items (unchecked)
   - Files created/modified so far
   - Any decisions made (reference DECISIONS.md entries)
4. **Report to orchestrator:**
   "Context at 70%. Checkpoint saved to CHECKPOINT-{role}.md. Terminating.
   Resume from: {current step description}"
5. **Terminate** — do not attempt to continue

## Orchestrator Response (cook.md)

When a dev agent reports 70% context limit:

1. Read CHECKPOINT-{role}.md
2. Verify committed files are intact
3. Spawn fresh agent with:
   - Original prompt (same role, same ownership)
   - Add: "RESUME from checkpoint — already completed: {list from checkpoint}. Continue from: {current step}."
   - Include CHECKPOINT-{role}.md content in prompt
4. Fresh agent picks up from checkpoint per `_error-recovery.md` protocol

## Detection (Proxy Signals)

Context usage is approximate — agents self-monitor based on:
- Number of tool calls made (proxy: >40 tool calls ≈ 60%+)
- Amount of file content read (proxy: >50KB read ≈ 60%+)
- Conversation length (proxy: >100 exchanges ≈ 70%+)

Conservative thresholds compensate for imprecise measurement.

## Non-Dev Agents

- **domain-engineer**: At 70%, save current design doc progress and terminate
- **tech-lead**: At 70%, save partial REVIEW.md and terminate
- **tester**: At 70%, save partial test files and terminate
- **spec-reviewer**: Unlikely to hit 70% (lightweight role), but same protocol applies
- **pm**: Never hits 70% (haiku model, structured output)
