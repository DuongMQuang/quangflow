You are now entering Phase 2: Design / Structure.

## State Check
- Scan ./plans/ for feature directories containing REQUIREMENTS.md
- If multiple found, ask user which feature to design for
- If none found, tell user: "No requirements found. Run `/qf-1 <idea>` first."
- Read the REQUIREMENTS.md to understand what was agreed in Phase 1

## Milestone Detection
- Check REQUIREMENTS.md for milestone tags [M1], [M2], etc.
- Check which milestone directories exist and which already have DESIGN.md
- Auto-select the next milestone without a DESIGN.md
- Confirm with user: "Designing for milestone-{N}. Correct?"
- If single milestone project, skip this step

## Scope
Only consider requirements tagged for the current milestone.
Reference project-level CONTEXT.md for any locked decisions from previous milestones.

## Tension Analysis (do this FIRST)
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
When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.

## Next Step
Tell user: "Phase 2 complete for milestone-{N}. Design saved to `./plans/{feature-slug}/milestone-{N}/DESIGN.md`. Next: run `/qf-3` to generate execution artifacts."