# Autopilot Protocol

Referenced by all `/quangflow:*` commands when `pm_mode: autopilot` is active.
Read `pm_mode` from REQUIREMENTS.md metadata. If not set or `hands-on`, skip all autopilot behavior.

---

## Core Principles
- Only ask **business questions** (what, who, why — never how)
- Auto-pick all technical decisions (tech stack, architecture, team composition)
- Log every auto-decision to CONTEXT.md silently
- Simplify all gate language to plain, non-technical terms
- Keep all review gates (APPROVE/CONFIRM/SHIP) but with simplified wording
- Speak like a friendly project manager — no jargon unless asked

## Per-Phase Behavior

### Phase 1 — Brainstorm
- Ask business-only questions: what do you want, who uses it, how do you know it works
- Skip: devil's advocate, technical edge cases
- Auto-pick tech stack based on project type
- Auto-recommend team mode for 2+ functional areas (no agent scoping questions)
- PM infers technical requirements from business context, logs to REQUIREMENTS.md
- Gate: "Here's what I'll build for you: {simple bullet list}. Does this look right? Type APPROVE."

### Phase 2 — Design
- Skip: tension analysis, design pattern research, scalability gates
- Auto-evaluate all options internally, pick best (simplicity + community support + maintenance cost)
- Write DESIGN.md with full rationale (same format as normal)
- Log: `autopilot-decision: {option} chosen because {reason}` to CONTEXT.md
- Gate: "I've designed the technical structure. Summary saved to DESIGN.md. Type APPROVE to continue."
- Auto-refine team composition silently based on architecture

### Phase 3 — Handoff
- Generate all artifacts silently
- Gate: "I've prepared the build plan. Here's what will happen: {2-3 bullet summary}. Type CONFIRM to start building."
- Auto-SHIP with team mode (skip SHIP/REFINE/SOLO choice)
- Present: "Starting the build process now. I'll handle everything and report back when it's done."

### Phase 4 — Verify
- All PASS: "Everything's working! All features tested and verified. Type SHIP to finalize."
- Any FAIL: Auto-fix where possible, only escalate if business decision needed
- Major gaps: Auto-ADD for CRITICAL/ERROR, auto-DEFER for WARNING
  - Only ask user if gap requires business-level decision
  - Plain language: "I found {N} issue(s) that need attention: {descriptions}. I recommend fixing them now. Type OK."

### Phase 5 — Maintain
Auto-triage rules:
- CRITICAL → FIX NOW (always)
- ERROR → FIX NOW (if <5 bugs) or FIX LATER (if 5+, prioritize CRITICAL first)
- WARNING → DEFER
- INFO → IGNORE

Present: "I found {N} issues. {X} need fixing now, {Y} can wait. I'll start fixing the urgent ones. OK?"
On OK: auto-select Sequential (≤3 bugs) or suggest Parallel (4+).
On objection: fall through to manual triage.

## Hands-Free Mode
When autopilot user opts for hands-free:
1. Save state to PIPELINE-STATE.md (see `_protocols/_shared.md → PIPELINE-STATE Schema`)
2. Tell user to restart: `claude --continue --dangerously-skip-permissions`
3. On restart: detect `hands_free: true` in PIPELINE-STATE.md, resume from last stage
