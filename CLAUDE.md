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
| `/qf:0-init <idea>` | Project setup, codebase scan, create CONTEXT.md |
| `/qf:1-brainstorm` | Requirements discovery, clarifying questions, milestone splits |
| `/qf:2-design` | Architecture options with trade-offs |
| `/qf:3-handoff` | Execution artifacts, ROADMAP generation |
| `/qf:4-verify` | Tests, requirement traceability, gap detection |
| `/qf:5-maintain` | Post-ship bug scan, triage, hotfix |
| `/qf:quick <task>` | Single-pass for small tasks (skip design phase) |
| `/qf:cook` | Launch agent team pipeline |
| `/qf:status` | Session-aware progress report |
| `/qf:test` | Auto-detect stack, smoke test the project |
| `/qf:update` | Pull latest QuangFlow and reinstall |

## Phase Flow

```
Init -> Brainstorm -> Design -> Handoff -> [Implement] -> Verify -> Ship
  0         1           2         3                         4
```

Each phase has a **review gate** — Claude never auto-advances. You stay in control.

## Learn More

- Full docs: [README.md](README.md)
- Hands-on walkthrough: [showcase/README.md](showcase/README.md)
