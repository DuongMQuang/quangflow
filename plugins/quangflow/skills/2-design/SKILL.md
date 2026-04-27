---
name: 2-design
description: "Use when entering design phase — architecture options with trade-offs, design pattern research"
---

You are now entering Phase 2: Design / Structure.

## State Check
See `_protocols/_shared.md → State Check Template`. Required artifact: REQUIREMENTS.md.
If none found: "No requirements found. Run `/quangflow:1-brainstorm <idea>` first."

## Milestone Detection
See `_protocols/_shared.md → Milestone Detection`. Target artifact: `DESIGN.md`.

## Scope
Only consider requirements tagged for the current milestone.
Reference project-level CONTEXT.md for any locked decisions from previous milestones.

## Autopilot Mode Check
See `_protocols/_autopilot.md → Phase 2 — Design`. If `pm_mode: autopilot`: auto-pick best option, skip to review gate.
If `hands-on` or not set: proceed with normal flow below.

## GOTCHAs Review (do this BEFORE tension analysis)
See `_protocols/_shared.md → GOTCHAs System → Review Protocol`.
Read both `plans/GOTCHAS.md` (global) and `plans/{feature-slug}/GOTCHAS.md` (feature) if they exist. Filter by tags relevant to this milestone's domain (e.g., `design`, `database`, `auth`, etc.).
If relevant gotchas found: present them (prefixed [global] or [{feature}]) before tension analysis so they inform design decisions.

## Tension Analysis (do this AFTER gotchas review)
List the "tension points" in this milestone's requirements:
- Requirements that pull in different directions
- Things that are easy now but hard to change later
- Decisions that will affect everything downstream
- For milestone-2+: tensions with previous milestone decisions

## Design Pattern Research (do this BEFORE proposing options)
For the problem domain of this milestone, research applicable software design patterns:

1. **Identify the core problem types** in this milestone's requirements:
   - Data access patterns → Repository, Active Record, Data Mapper, Unit of Work
   - Complex business logic → Strategy, State Machine, Command, Chain of Responsibility
   - System communication → Observer, Pub/Sub, Mediator, Event Sourcing
   - Object creation → Factory, Builder, Abstract Factory
   - Structural concerns → Adapter, Facade, Decorator, Proxy
   - Architectural patterns → CQRS, Hexagonal, Clean Architecture, MVC, Microservices

2. **Evaluate each candidate pattern** against the actual requirements:
   - Does this pattern solve a real problem we have? (not hypothetical)
   - What's the implementation cost vs benefit for our scope?
   - Is it overkill for the current milestone? (YAGNI check)
   - Will it help or hurt in future milestones?

3. **Present only patterns that genuinely fit** (max 3):
   "Applicable design patterns for this milestone:
   - **{Pattern}**: Fits because {reason}. Adds {complexity}. Helps with {benefit}.
   - **{Pattern}**: Fits because {reason}. But may be overkill because {reason}.
   Do NOT suggest patterns just to be thorough — only if they provide clear value."

4. **Integrate chosen patterns** into the design options below.

## Design Options
Propose EXACTLY 2-3 structural options. For each option include:
- Core structure (data model or architecture)
- **Design patterns applied** and why (from research above)
- Where it scales well
- Where it breaks down (be honest)
- Estimated complexity to change later
- For milestone-2+: compatibility with previous milestone's architecture

## Scalability Gates (answer for each option)
- Data volume: what happens at 10x, 100x?
- Team scale: where does parallel work conflict?
- Feature extension: which future milestones will be easy/hard?

## Review Gate
Before proceeding, you MUST:
1. Present all options with trade-offs
2. Ask explicitly: "Which option do you choose? Any modifications?"

Agent waits. Does nothing until user picks an option.

## On Choice
Write DESIGN.md to ./plans/{feature-slug}/milestone-{N}/DESIGN.md containing:

### Architecture Overview Diagram (MUST be first section after title)
Include a Mermaid diagram at the top of DESIGN.md showing the high-level architecture:
- **Use `graph LR` (left-to-right)** — group by layer: Frontend → Backend → Storage → External
- Each subgraph = one layer (FE, BE, DB, External). Readers instantly see which concern each box belongs to.
- Module-level only — no individual components. Detail diagrams come later in `design/` subfolder.
- Max 8-12 nodes total. Keep it scannable.
- Data flow arrows between layers with brief labels.

Example structure in DESIGN.md:
```
# Milestone {N} — Design
...
## Architecture Overview
\`\`\`mermaid
graph LR
  subgraph FE["Frontend"]
    ...
  end
  subgraph BE["Backend"]
    ...
  end
  subgraph DB["Storage"]
    ...
  end
  subgraph EXT["External"]
    ...
  end
  FE -->|requests| BE
  BE -->|read/write| DB
  ...
\`\`\`
```

This diagram gives readers instant visual context before reading detailed sections.

### Remaining sections:
- Chosen option with full rationale
- Rejected options and why
- Tension analysis results
- Scalability assessment for chosen option
- Cross-milestone compatibility notes (if applicable)

## Team Composition Refinement
If REQUIREMENTS.md has `team_mode: true`, refine the team based on the chosen architecture:

1. Re-read `team_composition` from REQUIREMENTS.md
2. Compare against the chosen design — the architecture may reveal:
   - Roles that should be **split** (e.g., "backend" → "api-developer" + "database-developer")
   - Roles that should be **merged** (e.g., infra is too small, combine with backend)
   - Roles that should be **added** (e.g., design chose a message queue → need "worker-developer")
   - **File ownership** that needs updating based on actual project structure from DESIGN.md
3. Present updated composition:

   "Based on the chosen architecture, I'd refine the team:

   | Change | Before | After | Reason |
   |--------|--------|-------|--------|
   | Split | dev-backend | dev-api + dev-data | Separate API layer from data layer per chosen design |
   | Merge | dev-infra | → into dev-backend | Infra scope too small for dedicated role |
   | Add | — | dev-worker | Architecture includes async job queue |

   Updated team:
   | Role | Focus | File Ownership |
   |------|-------|----------------|
   | ... | ... | ... |

   Adjust or approve?"

4. If user approves or adjusts, **update** `team_composition` in REQUIREMENTS.md
5. If user says "no changes needed", keep existing composition

**Skip this section entirely if `team_mode: false` or not set.**

## Output Rule
See `_protocols/_shared.md → Output Rule`.

## Progress Logging
See `_protocols/_shared.md → Progress Tracking`. Append Phase 2 row to `plans/{feature-slug}/PROGRESS.md`.
Key decisions to log: chosen option name, patterns applied, team refinements.

## Next Step
Tell user: "Phase 2 complete for milestone-{N}. Design saved to `./plans/{feature-slug}/milestone-{N}/DESIGN.md`."

Then suggest next command:
```
**Next:** `/quangflow:3-handoff` — Generate execution artifacts (ROADMAP, CONTEXT, team pipeline)
  ↳ Skip? Not recommended — Phase 3 produces the ROADMAP that devs/team follow
  ↳ Also available: `/quangflow:status` (check status), `/quangflow:status save` (save context)
```
