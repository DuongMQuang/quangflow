---
name: 0-init
description: "Use when starting a new project or feature — scans codebase, creates CONTEXT.md, detects project type"
---

You are now entering Phase 0: Project Init.

Sets up project context before brainstorming. Run once per feature.

## Purpose
Separate project setup (who are you, what exists) from requirements discovery (what to build).
Creates the scaffold and scans the codebase so all subsequent phases start with context.

## Arguments
```
/quangflow:0-init <idea>       — Initialize with a feature idea
/quangflow:0-init              — Initialize interactively (asks for idea)
```

## Step 1: Feature Slug
- Derive a feature slug from $ARGUMENTS (kebab-case, e.g. "user-auth", "payment-flow")
- If no arguments: ask "What feature or project are you building? (brief description)"
- Create directory: `./plans/{feature-slug}/`

## Step 2: Autopilot Detection
Ask the user:

"Before we start — are you technical (developer/engineer) or non-technical (PM, founder, designer)?

1. **Technical** — Full control over architecture, tech stack, and design decisions
2. **Non-technical** — I'll handle all technical decisions for you. You focus on what you want built."

- If **Technical**: set `pm_mode: hands-on`
- If **Non-technical**: set `pm_mode: autopilot` — see `_protocols/_autopilot.md` for full behavior

### Hands-Free Mode Offer (autopilot only)
See `_protocols/_autopilot.md → Hands-Free Mode`. Offer restart with `claude --continue --dangerously-skip-permissions`.
Save state to PIPELINE-STATE.md (see `_protocols/_shared.md → PIPELINE-STATE Schema`).

## Step 3: Project Type Detection
Ask the user:

"Is this an **existing project** or a **new project from scratch**?

1. **Existing project** — I'll scan the codebase first to understand what's already built
2. **New project** — Starting fresh, no codebase to scan"

### If Existing Project
Ask scan depth:

"How deep should I scan the codebase?

- **Shallow** — Manifest files (package.json, etc.) + top-level directory structure. Fast, low token cost.
- **Medium** — Shallow + main entry points, config files, and existing docs in `./docs/`. Recommended.
- **Deep** — Medium + read key source files to understand patterns and architecture. Thorough but higher token cost."

**Perform the scan based on user's choice:**

#### Shallow Scan
- Read manifest files: package.json, requirements.txt, go.mod, Cargo.toml, pyproject.toml, etc.
- List top-level directory structure (1 level deep)
- Read CLAUDE.md and README.md if they exist

#### Medium Scan (includes Shallow)
- Read main entry points: index.ts, main.py, app.ts, server.ts, etc.
- Read config files: tsconfig.json, .env.example, docker-compose.yml, etc.
- Read all docs in `./docs/` directory (if exists)
- List `src/` structure (2 levels deep)

#### Deep Scan (includes Medium)
- Read key source files in each module directory (first file per directory)
- Identify existing patterns: routing, middleware, DB access, state management
- Note existing test setup and conventions

### If New Project
- Skip codebase scan
- Note in CONTEXT.md: `project_type: new`

## Step 4: Write CONTEXT.md
Save to `./plans/{feature-slug}/CONTEXT.md`:

```markdown
# Context — {feature-slug}

## Metadata
```yaml
quangflow_version: "1.1.0"
pm_mode: {hands-on | autopilot}
project_type: {existing | new}
scan_depth: {shallow | medium | deep | none}
created: {ISO timestamp}
```

## Tech Stack
{detected stack from scan, or "TBD — will be decided in Phase 1/2"}

## Project Structure
{directory tree summary from scan, or "New project — no existing structure"}

## Existing Patterns
{patterns found during scan, or "N/A"}

## Dependencies
{key deps relevant to the new feature, or "N/A"}

## Constraints
{any constraints from current architecture, or "None identified"}

## Locked Decisions
(populated by later phases)
```

## Step 5: Create OPEN_QUESTIONS.md
Save to `./plans/{feature-slug}/OPEN_QUESTIONS.md`:

```markdown
# Open Questions — {feature-slug}

(populated during brainstorm and later phases)
```

## Resume from PIPELINE-STATE (on restart)
Check `./plans/*/PIPELINE-STATE.md` for `hands_free: true`.
If found: skip Autopilot Detection, resume from last incomplete stage.
If not found: proceed with Step 1 above.

## Output Rule
See `_protocols/_shared.md → Output Rule`.

## Progress Logging
See `_protocols/_shared.md → Progress Tracking`. Append Phase 0 row to `plans/{feature-slug}/PROGRESS.md`.
Key decisions to log: project type (existing/new), scan depth, pm_mode.

## Next Step
Tell user: "Project initialized. Context saved to `./plans/{feature-slug}/CONTEXT.md`."

Then suggest next command:
```
**Next:** `/quangflow:1-brainstorm` — Discover requirements, edge cases, milestones, and team composition
  ↳ Skip? Jump to `/quangflow:2-design` only if you already have REQUIREMENTS.md written manually
  ↳ Also available: `/quangflow:status` (check status)
```

**Trivial feature shortcut:** For 1-file tasks with no design needed, skip brainstorm entirely:
```
/quangflow:cook --solo "<task description>"
```
Cook Stage 0 routes through solo handoff — main agent edits directly, SOLO-LOG.md required.
NOT for sensitive areas (auth/payment/crypto/migration) — those force escalation to team regardless of flag.
