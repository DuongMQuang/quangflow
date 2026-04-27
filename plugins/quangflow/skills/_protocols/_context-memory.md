# Context Memory Protocol — Feature Memory Units

Referenced by all phase files and `cook.md`. Ensures context is never lost between sessions or agents.

---

## HARD-GATE

<HARD-GATE>
Do NOT start work on a feature without loading its FMU via @mention.
Context loss between sessions causes rework, contradictory decisions,
and missed requirements. Load before you work. Save before you stop.
</HARD-GATE>

---

## FMU Directory Structure

Each feature has a memory unit stored under `.memory/`:

```
.memory/
├── _index.md                    # Master index of all features
├── auth-system/
│   ├── CONTEXT.md               # Current state, decisions, blockers
│   └── LINKS.md                 # Related files, dependencies, references
├── payment-flow/
│   ├── CONTEXT.md
│   └── LINKS.md
└── user-dashboard/
    ├── CONTEXT.md
    └── LINKS.md
```

---

## _index.md Schema

The master index tracks all features at a glance:

```markdown
# Feature Memory Index

| Feature | Status | Dependencies | Last Updated |
|---|---|---|---|
| auth-system | active | none | 2026-03-28 |
| payment-flow | planning | auth-system | 2026-03-27 |
| user-dashboard | shipped | auth-system, payment-flow | 2026-03-25 |
```

### Status Values

| Status | Meaning |
|---|---|
| `planning` | Feature is in phases 0-2 (not yet in development) |
| `active` | Feature is in phases 3-4 (in development or verification) |
| `shipped` | Feature has passed Phase 4 and is live |
| `deprecated` | Feature is scheduled for removal or replacement |

---

## @mention Loading System

When a phase file or agent prompt references a feature, load its FMU automatically.

### Resolution Steps

1. **Parse the @mention** — Extract the feature slug from `@{feature-slug}`
2. **Locate the FMU** — Look for `.memory/{feature-slug}/CONTEXT.md`
3. **Load CONTEXT.md** — Read current state, decisions, blockers
4. **Load LINKS.md** — Read related files and dependencies

### Usage Examples

```
/quangflow:1-brainstorm           → loads FMU for the current feature (from plans/ context)
@auth-system                → loads .memory/auth-system/CONTEXT.md + LINKS.md
"Continue work on payment"  → resolves to @payment-flow, loads FMU
```

---

## Save Rules

FMUs are updated at specific events. This is NOT optional.

| Event | What to Save | Where |
|---|---|---|
| Phase completion | Updated state, phase output summary, key decisions | `.memory/{slug}/CONTEXT.md` |
| Design decision made | Decision rationale, alternatives considered | `.memory/{slug}/CONTEXT.md` |
| New dependency discovered | Dependency link, why it matters | `.memory/{slug}/LINKS.md` |
| Blocker encountered | Blocker description, status, who can unblock | `.memory/{slug}/CONTEXT.md` |
| File created or modified | File path, purpose, relationship to feature | `.memory/{slug}/LINKS.md` |
| Session ending | Current progress, next steps, open questions | `.memory/{slug}/CONTEXT.md` |
| Feature shipped | Final state, lessons learned, post-ship notes | `.memory/{slug}/CONTEXT.md` |

---

## Load Rules

FMUs are loaded at specific situations. This is NOT optional.

| Situation | What to Load |
|---|---|
| Starting any phase for a feature | `.memory/{slug}/CONTEXT.md` + `LINKS.md` |
| Agent spawned for a feature task | `.memory/{slug}/CONTEXT.md` (included in agent prompt) |
| Checking cross-feature dependencies | `.memory/_index.md` + relevant feature `LINKS.md` files |
| Resuming after session break | `.memory/{slug}/CONTEXT.md` for the active feature |
| Phase 2 (design) | Load FMUs for all features listed as dependencies in `_index.md` |
| Phase 5 (maintain) | Load FMU for the feature being debugged |

---

## FMU CONTEXT.md Template

```markdown
# {Feature Name} — Context

## Status
{planning | active | shipped | deprecated}

## Current Phase
Phase {N}: {phase name}

## Summary
{2-3 sentence description of the feature and its current state}

## Key Decisions
| ID | Decision | Rationale | Date |
|---|---|---|---|
| D-001 | {what was decided} | {why} | {date} |

## Blockers
| Blocker | Status | Owner |
|---|---|---|
| {description} | {open / resolved} | {who} |

## Open Questions
- {question 1}
- {question 2}

## Next Steps
- {next action 1}
- {next action 2}

## Session Log
| Date | Phase | What Happened |
|---|---|---|
| {date} | {phase} | {summary} |
```

---

## FMU LINKS.md Template

```markdown
# {Feature Name} — Links

## Source Files
| File | Purpose |
|---|---|
| {path} | {what it does for this feature} |

## Plan Files
| File | Purpose |
|---|---|
| plans/{slug}/REQUIREMENTS.md | Requirements for this feature |
| plans/{slug}/milestone-1/DESIGN.md | Architecture design |

## Dependencies
| Feature | Why |
|---|---|
| {feature-slug} | {why this feature depends on it} |

## External References
- {link or reference}
```

---

## Bidirectional Rule

When feature A depends on feature B:
- A's `LINKS.md` MUST reference B
- B's `LINKS.md` MUST reference A (as a dependent)

This ensures changes to B trigger awareness of impact on A.

---

## Red Flags

| Statement | Response |
|---|---|
| "I remember what we decided last session" | Memory is unreliable. Load the FMU and verify. |
| "This feature is independent, no need to check dependencies" | Check `_index.md` anyway. Hidden dependencies cause integration failures. |
| "I'll update the memory later" | Update it now, at the event. "Later" means "never" in practice. |
| "The context is all in the plan files" | Plan files are phase artifacts. FMUs are living context. They serve different purposes. |
