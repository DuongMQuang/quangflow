# QuangFlow

A 5-phase workflow framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that turns your AI assistant into a deliberate, structured project manager and architect.

## What It Does

Adds 11 slash commands to Claude Code:

| Command | Phase | Purpose |
|---------|-------|---------|
| `/qf:0-init <idea>` | 0. Init | Project setup, codebase scan, create CONTEXT.md (run once per feature) |
| `/qf:1-brainstorm` | 1. Requirements | Clarifying questions, edge cases, milestone splits, team composition |
| `/qf:2-design` | 2. Design | Architecture options with trade-offs, design pattern research, scalability gates |
| `/qf:3-handoff` | 3. Handoff | Execution artifacts (ROADMAP, REQUIREMENTS finalization), SHIP/REFINE/SOLO gate |
| `/qf:4-verify` | 4. Verify | Test generation, requirements traceability, gap detection, remediation |
| `/qf:5-maintain` | 5. Maintain | Post-ship bug fix, log scan, triage, parallel hotfix via dev agents |
| `/qf:quick <task>` | Quick | Single-pass for small tasks — skip design, milestones, team setup |
| `/qf:cook` | Orchestrator | Launches agent team pipeline (domain-engineer → devs → tech-lead → tester → PM) |
| `/qf:status` | Status | Session-aware status reporter with resume context |
| `/qf:test` | Smoke Test | Auto-detect stack, generate integration scripts, verify real module interactions |
| `/qf:update` | Update | Pull latest QuangFlow from GitHub and reinstall commands + agents |

## Philosophy

- **Slow in phases 1-2**: Surface problems before proposing solutions. Challenge assumptions. Devil's advocate every requirement.
- **Structured in phases 3-4**: Clear deliverables, acceptance criteria, test coverage, gap detection.
- **Never self-advances**: Every phase requires explicit user approval (APPROVE → pick option → CONFIRM → SHIP).
- **Plan over tools**: Spend more time designing, less time fixing.

## Install

### One-liner (remote)

```bash
# Interactive — asks global or project
curl -fsSL https://raw.githubusercontent.com/DuongMQuang/quangflow/main/remote-install.sh | bash

# Global install (available in all projects)
curl -fsSL https://raw.githubusercontent.com/DuongMQuang/quangflow/main/remote-install.sh | bash -s -- --global

# Project install (specific project only)
curl -fsSL https://raw.githubusercontent.com/DuongMQuang/quangflow/main/remote-install.sh | bash -s -- --project /path/to/project
```

### Manual

```bash
git clone https://github.com/DuongMQuang/quangflow.git
cd quangflow
bash install.sh              # interactive
bash install.sh --global     # install to ~/.claude/
bash install.sh --project    # install to current project
bash install.sh --update     # update commands+agents only (keeps CLAUDE.md)
```

### Global vs Project Install

| | Global (`~/.claude/`) | Project (`.claude/`) |
|---|---|---|
| **Scope** | All projects | This project only |
| **Best for** | Personal workflow across all repos | Team repos (commit `.claude/` to git) |
| **CLAUDE.md** | `~/.claude/CLAUDE.md` | `./CLAUDE.md` (project root) |
| **Plans dir** | Each project manages own `./plans/` | `./plans/` created automatically |

### What Gets Installed

```
{target}/.claude/
├── commands/
│   └── qf/
│       ├── _shared.md         # Shared protocols (state check, gates, output rules)
│       ├── _autopilot.md      # Autopilot mode protocol
│       ├── 0-init.md          # Phase 0: Project init
│       ├── 1-brainstorm.md    # Phase 1: Requirements
│       ├── 2-design.md        # Phase 2: Design
│       ├── 3-handoff.md       # Phase 3: Handoff
│       ├── 4-verify.md        # Phase 4: Verify
│       ├── 5-maintain.md      # Phase 5: Maintain
│       ├── quick.md           # Quick mode
│       ├── cook.md            # Team orchestrator
│       ├── status.md          # Status reporter
│       ├── test.md            # Smoke test
│       └── update.md          # Self-update
├── agents/
│   ├── _shared.md            # Shared agent protocols
│   ├── domain-engineer.md    # Design docs producer
│   ├── dev-teammate.md       # Implementation agent
│   ├── tech-lead.md          # Code reviewer
│   ├── tester.md             # Test generator
│   └── pm.md                 # Status tracker
└── scripts/
    └── validate/
        ├── validate-install.sh    # Verify QuangFlow installation integrity
        └── validate-artifacts.sh  # Verify plan artifacts structure
```

## Uninstall

```bash
bash /path/to/quangflow/uninstall.sh              # interactive (auto-detects)
bash /path/to/quangflow/uninstall.sh --global      # remove from ~/.claude/
bash /path/to/quangflow/uninstall.sh --project     # remove from current project
```

Removes only QuangFlow files. Leaves CLAUDE.md and plans/ intact.

## Quick Start

```
cd your-project
claude
/qf:1-brainstorm user authentication with OAuth2 and JWT
```

Follow the phases:

0. **Init** → setup project context → scan codebase → CONTEXT.md
1. **Brainstorm** → answer questions → APPROVE
2. **Design** → pick architecture option → save DESIGN.md
3. **Handoff** → review artifacts → CONFIRM → SHIP (team) or SOLO (manual)
4. **Verify** → review QA report → fix gaps → SHIP

## Team Mode

For larger projects (2+ functional layers), supports parallel agent teams:

```
domain-engineer → devs (parallel) → [optional] tech-lead → tester → PM status
```

| Role | Agent | Purpose |
|------|-------|---------|
| lead | main session | Orchestrator — coordinates team, user decisions |
| pm | project-manager | NPC — tracks progress, session resume |
| domain-engineer | planner | Designs modules, sequences, contracts before devs |
| dev-* | fullstack-developer | Implements code within file ownership boundaries |
| tech-lead | code-reviewer | Reviews quality, detects gaps (optional) |
| tester | tester | Generates & runs tests from requirements |

## Milestone System

Large projects auto-split into milestones. Each runs the full 4-phase cycle:

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

## Autopilot Mode

Auto-detects technical vs non-technical users at Phase 1 start.

Non-technical users get:
- Business-only questions (what, who, why — never how)
- Auto-picked tech stack, architecture, team composition
- Plain language at all gates
- Auto-triage in maintain mode

No flags needed — just answer "non-technical" when asked.

## Key Features

- **Crash recovery**: Pipeline state saved before each stage — resume with `--from` after interruption.
- **File ownership validation**: Detects overlapping dev globs before spawning team agents.
- **Cross-milestone regression**: Phase 4 re-runs previous milestone tests to catch regressions.
- **Review gates**: Agent never self-advances. Every phase needs explicit approval.
- **Critical thinking**: Challenges assumptions in ALL phases, not just brainstorm.
- **Design pattern research**: Phase 2 evaluates applicable patterns with YAGNI checks.
- **Test dependency chains**: Phase 4 runs tests in order, marks downstream as BLOCKED on failure.
- **Gap detection**: Tech-lead classifies gaps as minor/major. User decides ADD/DEFER/IGNORE.
- **Session resume**: `/qf:status` reads STATUS.md — tells you where you left off.
- **Context save**: `/qf:status save` snapshots state before `/clear` or `/exit`.

## Customization

Edit `CLAUDE.md` in your project root to set tech stack, PM personality, conventions, and review gate behavior.

Edit files in `.claude/agents/` to customize agent behavior per role.

## License

MIT
