# QuangFlow

A 5-phase workflow framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that turns your AI assistant into a deliberate, structured project manager and architect.

## What It Does

Adds 12 slash commands to Claude Code:

| Command | Phase | Purpose |
|---------|-------|---------|
| `/qf:0-init <idea>` | 0. Init | Project setup, codebase scan, create CONTEXT.md (run once per feature) |
| `/qf:1-brainstorm` | 1. Requirements | Clarifying questions, edge cases, milestone splits, team composition |
| `/qf:2-design` | 2. Design | Architecture options with trade-offs, design pattern research, scalability gates |
| `/qf:3-handoff` | 3. Handoff | Execution artifacts (ROADMAP, REQUIREMENTS finalization), SHIP/REFINE gate |
| `/qf:4-verify` | 4. Verify & Certify | TDD compliance audit, requirements traceability, evidence certification |
| `/qf:5-maintain` | 5. Maintain | Post-ship bug fix, systematic debugging protocol, structured log scan |
| `/qf:quick <task>` | Quick | Streamlined flow for small tasks — minimal team (dev + tester), TDD enforced |
| `/qf:cook` | Orchestrator | Launches agent team pipeline (domain-engineer → devs → tech-lead → tester → PM) |
| `/qf:status` | Status | Session-aware status reporter with resume context |
| `/qf:test` | Smoke Test | Auto-detect stack, generate integration scripts, verify real module interactions |
| `/qf:guide` | Guide | Interactive guided tour — walk through every phase step-by-step |
| `/qf:update` | Update | Pull latest QuangFlow from GitHub and reinstall commands + agents |

## Philosophy

- **Slow in phases 1-2**: Surface problems before proposing solutions. Challenge assumptions. Devil's advocate every requirement.
- **Structured in phases 3-4**: Clear deliverables, acceptance criteria, test coverage, gap detection.
- **Never self-advances**: Every phase requires explicit user approval (APPROVE → pick option → CONFIRM → SHIP).
- **Plan over tools**: Spend more time designing, less time fixing.

## Install

### As a Plugin (recommended)

```bash
# Step 1: Add QuangFlow marketplace (one-time)
claude plugin marketplace add https://github.com/DuongMQuang/quangflow

# Step 2: Install
claude plugin install quangflow

# Update later
claude plugin update quangflow
```

Plugin benefits: one-command install, auto-updates, no file conflicts.

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
│       ├── _protocols/          # Internal protocols (not user-facing commands)
│       │   ├── _shared.md              #   State check, gates, output rules
│       │   ├── _autopilot.md           #   Autopilot mode protocol
│       │   ├── _tdd-enforcement.md     #   RED-GREEN-REFACTOR cycle
│       │   ├── _systematic-debugging.md #  4-phase root cause process
│       │   ├── _verification-gates.md  #   Evidence-before-assertions
│       │   ├─��� _hard-gates.md          #   Red flag table, phase gate checklists
│       │   ├── _structured-logging.md  #   Log format standard, FE→BE bridge
│       │   ├── _context-memory.md      #   Feature Memory Units (@mention)
│       │   └── ...                     #   Context scoping, model routing, etc.
│       ├── 0-init.md            # Phase 0: Project init
│       ├── 1-brainstorm.md      # Phase 1: Requirements
│       ├── 2-design.md          # Phase 2: Design
│       ├── 3-handoff.md         # Phase 3: Handoff
│       ├── 4-verify.md          # Phase 4: Verify
│       ├── 5-maintain.md        # Phase 5: Maintain
│       ├── guide.md             # Interactive guided tour
│       ├── quick.md             # Quick mode
│       ├── cook.md              # Team orchestrator
│       ├── status.md            # Status reporter
│       ├── test.md              # Smoke test
│       └── update.md            # Self-update
├── agents/
│   ├── _shared.md            # Shared agent protocols
│   ├── domain-engineer.md    # Design docs producer
│   ├── dev-teammate.md       # Implementation agent
│   ├── tech-lead.md          # Code reviewer
│   ├── tester.md             # Test generator
│   ├── pm.md                 # Status tracker
│   └── critic.md             # Design debate critic (feasibility/simplicity)
└── scripts/
    ├── validate/
    │   ├── validate-install.sh        # Verify QuangFlow installation integrity
    │   ├── validate-artifacts.sh      # Verify plan artifacts structure
    │   ├── validate-tdd-coverage.sh   # Verify red+green TDD logs per REQ-ID
    │   ├── validate-evidence.sh       # Verify .evidence/ per phase transition
    │   ├── validate-memory.sh         # Verify FMU structure, bidirectional links
    │   └── validate-stage-completion.sh # Pipeline stage advancement checks
    └── hooks/
        ├── enforce-ownership.sh       # PreToolUse: file ownership boundaries
        ├── detect-gotcha-trigger.sh   # Lesson detection
        ├── auto-checkpoint.sh         # PostToolUse: auto-save agent progress
        ├── evidence-tracker.sh        # PostToolUse: track evidence in PIPELINE-STATE
        └── save-feature-memory.sh     # Phase transition: auto-update FMU
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
/qf:guide
```

The guide walks you through every phase interactively. Or jump straight in:

```
/qf:0-init my feature idea
```

Follow the phases:

0. **Init** → setup project context → scan codebase → CONTEXT.md
1. **Brainstorm** → answer questions → APPROVE
2. **Design** → pick architecture option → save DESIGN.md
3. **Handoff** → review artifacts → CONFIRM → SHIP (team always)
4. **Verify & Certify** → TDD audit → evidence certification → fix gaps → SHIP

**Want a full walkthrough?** See [showcase/README.md](showcase/README.md) or run `/qf:guide` for an interactive tour.

## Team Mode

For larger projects (2+ functional layers), supports parallel agent teams:

```
domain-engineer → [optional] debate → devs (parallel) → [optional] tech-lead → tester → PM status
```

| Role | Agent | Purpose |
|------|-------|---------|
| lead | main session | Orchestrator — coordinates team, user decisions |
| pm | project-manager | NPC — tracks progress, session resume |
| domain-engineer | planner | Designs modules, sequences, contracts before devs |
| critics | code-reviewer (haiku) | Parallel feasibility + simplicity review of design (optional) |
| dev-* | fullstack-developer | Implements code via TDD within file ownership boundaries |
| tech-lead | code-reviewer | Reviews quality, detects gaps (optional) |
| tester | tester | Audits TDD coverage, generates integration/E2E tests, certifies traceability |

## Milestone System

Large projects auto-split into milestones. Each runs the full 4-phase cycle:

```
plans/my-feature/
├── REQUIREMENTS.md          # Master — tagged [M1], [M2], etc.
├── CONTEXT.md               # Locked decisions across milestones
├── milestone-1/
│   ├── DESIGN.md
│   ├── ROADMAP.md
│   ├── CERTIFICATION.md         # (or QA-REPORT.md for legacy milestones)
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

### Discipline Layer (new)
- **TDD enforcement**: Iron-law RED-GREEN-REFACTOR — no production code without a failing test first. Evidence saved to `.evidence/tdd/`.
- **Systematic debugging**: 4-phase root cause process (Investigate → Analyze → Hypothesize → Fix). 3+ failed attempts → question the architecture.
- **Verification gates**: Evidence before assertions — every phase transition requires saved proof. No "should work" or "probably passes."
- **Hard gates & red flags**: Master rationalization table catches shortcuts before they happen. Three enforcement layers: prompts + inline gates + scripts.
- **Structured logging**: JSON log standard (level, source, module, trace_id). Frontend errors bridge to backend. Debugging reads structured logs first.
- **Feature Memory Units**: Per-feature context in `.memory/` loaded via `@mention`. Scales context without drowning in it.
- **Multi-agent only**: Solo mode eliminated. Every task runs through the agent team pipeline. `/qf:quick` uses a minimal team (dev + tester).

### Core
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
- **GitNexus integration** (optional): Adds semantic-level safety — blast radius analysis, cross-boundary impact detection, graph-aware renames. Auto-detected when [GitNexus](https://github.com/abhigyanpatwari/GitNexus) MCP server is configured.
- **GOTCHAs self-improvement**: Lessons auto-logged from gaps/bugs, auto-reviewed before design/handoff. User corrections detected by hook.
- **Progress tracking**: PROGRESS.md records phase timeline, session count, iterations, key decisions per milestone.
- **Auto-checkpoint hooks**: PostToolUse hooks auto-save agent progress, track evidence artifacts, and update Feature Memory on phase transitions.

## Customization

Edit `CLAUDE.md` in your project root to set tech stack, PM personality, conventions, and review gate behavior.

Edit files in `.claude/agents/` to customize agent behavior per role.

## License

MIT
