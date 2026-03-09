You are now entering Phase 1: Requirements Brainstorm.

## Setup
- Derive a feature slug from $ARGUMENTS (kebab-case, e.g. "user-auth", "payment-flow")
- Create directory: ./plans/{feature-slug}/
- This slug is used by all subsequent phases

## Rules
- Ask clarifying questions in BATCHES (max 5 per round)
- Do not write any files until user has answered at least 2 rounds
- After each round, summarize what you understood + what's still unclear

## Clarification Protocol
When a user's answer is vague, incomplete, or ambiguous, use `AskUserQuestion` to probe deeper.

### When to Probe
- Answer is one word or too short to act on (e.g., "yes", "maybe", "normal users")
- Answer contradicts a previous answer
- Answer introduces a new concept not yet discussed
- Critical requirement lacks specifics (scale, auth model, data format, etc.)
- User says "I don't know" or "not sure" — help them decide

### How to Ask
Use `AskUserQuestion` with structured options + free-type:

```json
{
  "questions": [{
    "question": "You mentioned 'large files'. What size range are we designing for?",
    "header": "Clarification: File Size",
    "options": [
      { "label": "< 10MB", "description": "Standard uploads, no special handling" },
      { "label": "10MB - 100MB", "description": "Chunked upload, progress bar needed" },
      { "label": "100MB - 1GB", "description": "Resumable upload, background processing" },
      { "label": "1GB+", "description": "Streaming upload, dedicated infra" }
    ],
    "multiSelect": false
  }]
}
```

### Rules for Probing
- Max 2 probes per unclear answer (don't interrogate)
- Always provide 3-5 concrete options based on common patterns
- Last option can be "Other — I'll describe" for free-type escape
- If user picks "Other", accept their freeform answer and move on
- If after 2 probes the answer is still unclear, log to OPEN_QUESTIONS.md and move forward with a stated assumption
- Prefix assumptions with: `⚠️ ASSUMPTION: {assumption}. Will revisit if wrong.`

## Must Cover Before Closing Phase 1
- [ ] Core user problem (not feature)
- [ ] Who are the users, what are their contexts
- [ ] Success metric — how do we know this worked?
- [ ] At least 3 edge cases discussed
- [ ] Explicit list of what is OUT OF SCOPE

## Devil's Advocate
Before finalizing, you MUST challenge each requirement:
"What assumption is this requirement making? What if that assumption is wrong?"

## Milestone Split Recommendation
After requirements are understood, assess complexity:
- Count total requirements and distinct functional areas
- If 8+ requirements OR 3+ distinct functional areas, RECOMMEND splitting into milestones
- Present a proposed split: which requirements belong to which milestone
- Tag each requirement: [M1], [M2], etc.
- Milestone-1 should be the minimal viable scope (core functionality)
- Later milestones build on top

If project is small enough for single milestone, say so. User decides.

Ask: "I recommend [1 | N] milestone(s). Here's the proposed split: [summary]. Do you agree, or want to adjust?"

## Review Gate
Before writing files, you MUST:
1. Present a summary: "Here's what I understood"
2. Present devil's advocate challenges
3. Present milestone split recommendation
4. Ask explicitly: "Do you approve requirements and milestone split? Type APPROVE to continue."

Agent waits. Does nothing until user types APPROVE.

## Team Mode Preference
After APPROVE, analyze the approved requirements to suggest an execution mode.

### Team Composition Analysis
Scan all approved requirements and identify which **functional layers** are involved:

| Layer | Detected when requirements mention... | Role |
|-------|---------------------------------------|------|
| **Backend** | API, database, auth, server, models, migrations, webhooks, cron, queue | `fullstack-developer` focused on backend |
| **Frontend** | UI, pages, components, forms, dashboard, responsive, styling | `fullstack-developer` focused on frontend |
| **Infrastructure** | Docker, CI/CD, deployment, env config, cloud, monitoring | `fullstack-developer` focused on infra |
| **Mobile** | iOS, Android, React Native, Flutter, mobile app | `fullstack-developer` focused on mobile |
### Present Suggestion
Based on the analysis, present:

"Based on the requirements, I identified these functional layers:
- **Backend**: [list relevant requirements]
- **Frontend**: [list relevant requirements]
- (etc.)

**Suggested execution mode:**
1. **Solo** — Implement sequentially (best for small scope)
2. **Agent Team** — Parallel teammates with file ownership boundaries (see below)

Type `1` for Solo or `2` for Agent Team."

### Agent Scoping (only if Agent Team selected AND 2+ layers detected)
If user picks Agent Team and there are distinct layers (e.g. backend + frontend), ask:

"Your project has distinct **{layer-1}** and **{layer-2}** code. How should dev agents be scoped?

1. **Scoped agents** — Separate `dev-backend` + `dev-frontend` agents. Each only reads/writes its own files. Lower token usage, faster per-agent.
2. **Combined fullstack** — Single `dev-fullstack` agent handles both. Simpler coordination, but reads all files (higher token usage).

Type `1` or `2`."

- If **Scoped**: create separate dev roles per detected layer (e.g. `dev-backend`, `dev-frontend`, `dev-mobile`)
- If **Combined**: create a single `dev-fullstack` role owning all implementation files
- If only 1 layer detected: skip this question, use a single dev role automatically

### Present Team Table
After scoping decision, present:

| Role | Type | Focus | File Ownership |
|------|------|-------|----------------|
| lead | Orchestrator | Coordinate team, user decisions | Main session |
| pm | Project Manager (always) | Track progress, resume context across sessions, report status | `plans/{feature-slug}/milestone-{N}/STATUS.md` |
| domain-engineer | Architect (recommended) | Module design docs, sequence flows, interface contracts (Mermaid) | `plans/{feature-slug}/milestone-{N}/design/` |
| dev-{scope} | Developer | {focus per scoping choice} | {ownership per scoping choice} |
| tech-lead | Reviewer (optional) | Code review, tech debt, cross-dev integration | Read-only on all dev files |
| tester | Tester | Generate & run unit/integration/e2e tests based on requirements | `tests/*, __tests__/*` |

**Pipeline:** domain-engineer designs → devs implement (parallel) → [optional] tech-lead reviews → tester tests
**Cross-cutting:** pm reports status at each checkpoint

"Any changes to the team composition, or looks good?"

### Rules
- Only suggest layers that are actually present in requirements (don't pad)
- If only 1 layer detected, recommend Solo (team overhead not worth it)
- If 2+ layers detected, recommend Agent Team
- Max 4 dev roles (combine small layers if needed)
- Lead (main session) is orchestrator only — does NOT do code review or design work itself
- Domain-engineer is a separate `planner` agent, **recommended for 2+ devs** — designs modules before devs start
- Tech-lead is a separate `code-reviewer` agent, **optional** — user decides at execution time
- Tester is always a separate agent — generates tests based on REQUIREMENTS.md before user verification
- User can adjust dev roles: add, remove, rename, change file ownership
- After user confirms, ask: "Any changes to the team composition, or looks good?"

### On User Selection
- If **Solo**: write `team_mode: false` into REQUIREMENTS.md metadata
- If **Agent Team**: write into REQUIREMENTS.md metadata:
  ```yaml
  team_mode: true
  team_composition:
    - role: lead
      focus: "Orchestrator — coordinate team, user decisions"
      type: main-session
    - role: pm
      focus: "Track progress, resume context across sessions, report status at checkpoints"
      ownership: "plans/{feature-slug}/milestone-{N}/STATUS.md"
      agent_type: project-manager
      required: true
      note: "Always present — session memory NPC. Updates STATUS.md at every checkpoint."
    - role: domain-engineer
      focus: "Module design, sequence flows (Mermaid), interface contracts"
      ownership: "plans/{feature-slug}/milestone-{N}/design/*"
      agent_type: planner
      recommended: true
      note: "Runs BEFORE devs. Produces design docs that devs follow."
    # --- Dev roles: adapt based on agent scoping choice ---
    # If SCOPED (separate agents per layer):
    - role: dev-backend
      focus: "API endpoints, database models, auth services"
      ownership: "src/api/*, src/models/*, src/services/*"
      agent_type: fullstack-developer
      blocked_by: [domain-engineer]
    - role: dev-frontend
      focus: "UI components, pages, styling"
      ownership: "src/components/*, src/pages/*, src/styles/*"
      agent_type: fullstack-developer
      blocked_by: [domain-engineer]
    # If COMBINED (single fullstack agent):
    # - role: dev-fullstack
    #   focus: "Full implementation — API, models, services, UI, pages"
    #   ownership: "src/*"
    #   agent_type: fullstack-developer
    #   blocked_by: [domain-engineer]
    - role: tech-lead
      focus: "Code review, tech debt, cross-dev integration"
      agent_type: code-reviewer
      optional: true
      blocked_by: [dev-backend, dev-frontend]
    - role: tester
      focus: "Generate & run unit/integration/e2e tests based on requirements"
      ownership: "tests/*, __tests__/*"
      agent_type: tester
      blocked_by: [tech-lead]
  ```

## On APPROVE
Write REQUIREMENTS.md to ./plans/{feature-slug}/REQUIREMENTS.md containing:
- Feature slug and description
- Core problem statement
- User personas and contexts
- Success metrics
- Edge cases
- Out of scope items
- Milestone breakdown: which requirements in [M1], [M2], etc.
- Execution mode: team_mode (true/false), team_composition (if team mode — roles, focus, ownership, agent_type, blocked_by)
- Status: DRAFT (will be finalized in Phase 3)

If multiple milestones, create milestone directories: ./plans/{feature-slug}/milestone-1/, milestone-2/, etc.

## Output Rule
When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.

## Next Step
Tell user: "Phase 1 complete. Draft saved to `./plans/{feature-slug}/REQUIREMENTS.md` with [N] milestone(s). Next: run `/qf-2` to explore architecture options for milestone-1."

Start by asking the first batch of clarifying questions about:
$ARGUMENTS