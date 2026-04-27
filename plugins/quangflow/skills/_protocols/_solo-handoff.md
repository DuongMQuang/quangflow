# Solo Handoff Protocol

Referenced by `cook.md` Stage 0 when triage returns `tier: solo`. Cook prints a structured handoff message and EXITS (no spawn). Main agent (Opus) reads handoff, edits files directly, writes SOLO-LOG.md.

## Purpose

Solo mode = pure Opus thinking. No multi-agent orchestration. Main agent leverages extended thinking for deeply considered changes on small tasks. Critical-advocate is a MINDSET (not a spawned critic).

## Handoff Message Template

When cook decides `tier: solo`, print this EXACT message and exit:

```
================================================================================
SOLO HANDOFF — Main Agent (Opus) takes over
================================================================================

Triage: solo (1 REQ, 1 phase, 1 file, no sensitive keywords)

You will edit files directly. No agent team will spawn.

## Required Discipline

1. **Critical-Advocate Mindset** (replaces spawned critic):
   - Before writing code: list 2-3 alternative approaches, pick one, explain why others rejected.
   - During: ask "what if this assumption is wrong?" for each non-trivial decision.
   - After: review your own diff for KISS / YAGNI / DRY violations.

2. **TDD Mandate** (cannot skip):
   - Write failing test first → save output to `.evidence/tdd/REQ-{id}-red.log`.
   - Implement minimal code to pass → save passing output to `.evidence/tdd/REQ-{id}-green.log`.
   - Refactor if needed.

3. **Verification**:
   - Run full relevant test suite. Save to `.evidence/verification/solo-{slug}.log`.
   - Lint / typecheck if project has them.

4. **Solo Log** (mandatory):
   - Write `plans/{slug}/milestone-{N}/SOLO-LOG.md` with the schema below.
   - This is the equivalent of STATUS.md + REVIEW.md combined for solo work.

## Files in Scope

- {file 1}
- {file 2}
...

## REQ-IDs to Cover

- REQ-{id}: {description}

## Acceptance Criteria

- {criterion 1}
- {criterion 2}

## Next Step

After implementation:
- Verify SOLO-LOG.md exists with all required fields.
- Commit changes (conventional format).
- Run `/qf:status` to see updated state.
- Run `/qf:4-verify` if you want certification.

================================================================================
```

Cook substitutes `{slug}`, `{N}`, `{file 1..n}`, `{REQ-id}`, `{description}`, `{criterion}` from REQUIREMENTS.md / ROADMAP.md.

After printing this message, cook exits with status 0. Main agent reads the message and proceeds with editing.

## SOLO-LOG.md Schema

Solo task MUST write this file at `plans/{feature-slug}/milestone-{N}/SOLO-LOG.md`. `/qf:status` reads it to display solo work in milestone view.

```markdown
---
mode: solo
slug: {feature-slug}
milestone: {N}
status: in_progress | completed
started_at: {ISO 8601 timestamp}
completed_at: {ISO 8601 timestamp or null}
---

# Solo Log — Milestone {N}

## REQ-IDs Done
- REQ-{id}: {one-line outcome}
- REQ-{id}: {one-line outcome}

## Files Changed
- {absolute path 1} — {brief change}
- {absolute path 2} — {brief change}

## TDD Evidence
- Red log: `.evidence/tdd/REQ-{id}-red.log`
- Green log: `.evidence/tdd/REQ-{id}-green.log`
- Verification log: `.evidence/verification/solo-{slug}.log`

## Critical Thinking Notes

### Alternatives Considered
1. **{Approach A}** — REJECTED: {reason}
2. **{Approach B}** — REJECTED: {reason}
3. **{Chosen approach}** — PICKED: {why it wins}

### Surfaced Trade-offs
- {trade-off 1}: chose {X} over {Y} because {reason}.
- {trade-off 2}: ...

### Assumptions Validated
- {assumption}: confirmed by {test / log / observation}.

### Self-Review (KISS / YAGNI / DRY)
- KISS: {pass/fail + note}
- YAGNI: {pass/fail + note}
- DRY: {pass/fail + note}

## Commit
- Hash: {git hash, post-commit}
- Message: {conventional commit subject}

## Notes
{Anything else worth recording — gotchas, follow-ups, deferred items}
```

## Required Fields (validation)

A valid SOLO-LOG.md MUST contain:
- Frontmatter `mode: solo`, `slug`, `milestone`, `status`, `started_at`
- Section `## REQ-IDs Done` (≥1 entry)
- Section `## Files Changed` (≥1 entry)
- Section `## TDD Evidence` (red + green log paths)
- Section `## Critical Thinking Notes` with `### Alternatives Considered` (≥2 alternatives, ≥1 rejected)
- Section `## Commit` with hash + message (after commit)

Missing any required field → SOLO-LOG.md is INVALID. `/qf:status` will flag it.

## Status Integration

`/qf:status` reads SOLO-LOG.md (if exists) and shows in milestone view:

```
**Milestone {N}: SOLO COMPLETED**
- REQ-IDs: {count}
- Files: {count}
- Commit: {hash short}
- Critical thinking notes: {count of alternatives}
```

If `status: in_progress`: show as "SOLO IN PROGRESS — last update {timestamp}".

## Closing

When solo work is complete:
- User can run `/qf:close M_{N}` to mark milestone CLOSED (writes MILESTONE.yml).
- See `close/SKILL.md` for close command.

## Borderline Note

Solo is for SMALL tasks only. If during implementation you discover the task is bigger than expected (unexpected coupling, sensitive keyword surfaces, etc.):

1. STOP editing.
2. Append to SOLO-LOG.md: `## Escalation` with reason.
3. Tell user: "Task scope exceeded solo tier. Recommend `/qf:cook --team` to restart with full pipeline."
4. Do NOT continue solo. User decides whether to revert + restart or accept partial solo work.

## Anti-Patterns (DO NOT)

- ❌ Skip TDD because "trivial" — TDD evidence is mandatory even for 1 LOC.
- ❌ Skip critical-thinking alternatives — at least 2 must be listed and 1 rejected.
- ❌ Skip SOLO-LOG.md — `/qf:status` and `/qf:close` depend on it.
- ❌ Spawn an agent (defeats the purpose of solo tier).
- ❌ Edit files outside scope listed in handoff message — escalate instead.
