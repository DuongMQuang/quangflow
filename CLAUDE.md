# QuangFlow

A 5-phase workflow framework for Claude Code. Turns your AI assistant into a deliberate, structured project manager and architect.

## First Time Here?

Run `/qf:guide` for an interactive walkthrough of every phase.

Or jump straight in:
```
/qf:0-init <your project idea>
```

## Commands

| Command | Purpose |
|---------|---------|
| `/qf:guide` | Interactive guided tour — explore the workflow step-by-step |
| `/qf:adopt` | Onboard an existing codebase — adaptive scan, feature extraction, doc generation, confidence scoring |
| `/qf:0-init <idea>` | Project setup, codebase scan, create CONTEXT.md |
| `/qf:1-brainstorm` | Requirements discovery, clarifying questions, milestone splits |
| `/qf:2-design` | Architecture options with trade-offs |
| `/qf:3-handoff` | Execution artifacts, ROADMAP generation, SHIP/REFINE gate |
| `/qf:4-verify` | TDD audit, evidence certification, gap detection |
| `/qf:5-maintain` | Post-ship systematic debugging, structured log scan, hotfix |
| `/qf:quick <task>` | Streamlined flow for small tasks — minimal team (dev + tester) |
| `/qf:cook` | Launch agent team pipeline |
| `/qf:status` | Session-aware progress report |
| `/qf:test` | Auto-detect stack, smoke test the project |
| `/qf:update` | Pull latest QuangFlow and reinstall |

## Phase Flow

```
Init -> Brainstorm -> Design -> Handoff -> [Implement/TDD] -> Verify & Certify -> Ship
  0         1           2         3                                4
```

Each phase has a **review gate** — Claude never auto-advances. You stay in control.

## Learn More

- Full docs: [README.md](README.md)
- Hands-on walkthrough: [showcase/README.md](showcase/README.md)
