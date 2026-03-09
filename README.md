# QuangFlow

A 4-phase workflow framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that turns your AI assistant into a deliberate, structured project manager and architect.

## What It Does

Adds 6 slash commands to any Claude Code project:

| Command | Phase | Purpose |
|---------|-------|---------|
| `/qf-1 <idea>` | 1. Requirements | Clarifying questions, edge cases, milestone splits, team composition |
| `/qf-2` | 2. Design | Architecture options with trade-offs, design pattern research, scalability gates |
| `/qf-3` | 3. Handoff | Execution artifacts (ROADMAP, REQUIREMENTS finalization), SHIP/REFINE/SOLO gate |
| `/qf-4` | 4. Verify | Test generation, requirements traceability, gap detection, remediation |
| `/qf-c` | Orchestrator | Launches agent team pipeline (domain-engineer -> devs -> tech-lead -> tester -> PM) |
| `/qf-s` | Status | Session-aware status reporter with resume context |

## Philosophy

- **Slow in phases 1-2**: Surface problems before proposing solutions. Challenge assumptions. Devil's advocate every requirement.
- **Structured in phases 3-4**: Clear deliverables, acceptance criteria, test coverage, gap detection.
- **Never self-advances**: Every phase requires explicit user approval (APPROVE -> pick option -> CONFIRM -> SHIP).
- **Plan over tools**: Spend more time designing, less time fixing.

## Install

```bash
git clone https://github.com/YOUR_USERNAME/quangflow.git
cd quangflow
bash install.sh /path/to/your/project
```

Or from within your project:

```bash
bash /path/to/quangflow/install.sh .
```

### What Gets Installed

```
your-project/
├── .claude/
│   ├── commands/          # 6 slash commands (qf-1 through qf-s)
│   └── agents/            # 5 agent instruction files
├── plans/                 # Created empty — workflow artifacts go here
└── CLAUDE.md              # QuangFlow config (created or appended)
```

## Uninstall

```bash
bash /path/to/quangflow/uninstall.sh /path/to/your/project
```

Removes commands and agent files. Leaves `CLAUDE.md` and `plans/` intact.

## Quick Start

```
cd your-project
claude
/qf-1 user authentication with OAuth2 and JWT
```

The PM will ask clarifying questions in batches, challenge your assumptions, recommend milestone splits, and suggest a team composition. Follow the phases:

1. **Brainstorm** -> answer questions -> APPROVE
2. **Design** -> pick architecture option -> save DESIGN.md
3. **Handoff** -> review artifacts -> CONFIRM -> SHIP (team) or SOLO (manual)
4. **Verify** -> review QA report -> fix gaps -> SHIP

## Team Mode

For larger projects (2+ functional layers), the workflow supports parallel agent teams:

```
domain-engineer -> devs (parallel) -> [optional] tech-lead -> tester -> PM status
```

| Role | Agent Type | Purpose |
|------|-----------|---------|
| lead | main session | Orchestrator — coordinates team, user decisions |
| pm | project-manager | NPC — tracks progress, session resume |
| domain-engineer | planner | Designs modules, sequences, contracts before devs |
| dev-* | fullstack-developer | Implements code within file ownership boundaries |
| tech-lead | code-reviewer | Reviews quality, detects gaps (optional) |
| tester | tester | Generates & runs tests from requirements |

Agent scoping is configurable — choose **scoped agents** (separate dev-backend + dev-frontend) or **combined fullstack** during Phase 1.

## Milestone System

Large projects auto-split into milestones. Each milestone runs the full 4-phase cycle:

```
plans/my-feature/
├── REQUIREMENTS.md          # Master — tagged [M1], [M2], etc.
├── CONTEXT.md               # Locked decisions across milestones
├── milestone-1/
│   ├── DESIGN.md
│   ├── ROADMAP.md
│   ├── QA-REPORT.md
│   └── STATUS.md
├── milestone-2/
│   └── ...
```

## Key Features

- **Review gates**: Agent never self-advances. Every phase needs explicit approval.
- **Design pattern research**: Phase 2 evaluates applicable patterns (Repository, CQRS, etc.) with YAGNI checks.
- **Test dependency chains**: Phase 4 runs tests in order (infra -> models -> services -> endpoints -> E2E), marks downstream tests as BLOCKED on failure.
- **Gap detection**: Tech-lead classifies gaps as minor (fix inline) or major (remediation phase). User decides ADD/DEFER/IGNORE.
- **Session resume**: `/qf-s` reads STATUS.md and tells you exactly where you left off and what command to run next.
- **Context save**: `/qf-s save` snapshots state before `/clear` or `/exit`.
- **Per-agent token tracking**: Pipeline logs each agent's token usage, tool calls, and duration to STATUS.md.
- **Critical thinking**: Challenges assumptions in ALL phases, not just brainstorm.

## Customization

### CLAUDE.md

Edit the `CLAUDE.md` in your project root to:
- Set your tech stack
- Adjust the PM personality
- Add project-specific conventions
- Modify review gate behavior

### Agent Instructions

Edit files in `.claude/agents/` to customize agent behavior:
- `domain-engineer.md` — what design docs to produce
- `dev-teammate.md` — implementation protocol
- `tech-lead.md` — review checklist and severity classification
- `tester.md` — test generation strategy
- `pm.md` — status report structure

## License

MIT
