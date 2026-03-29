# Shared Decisions Log — Milestone 1

Agents append implementation decisions not covered by CONTRACTS.md here.
Other agents should read this before starting work.

| # | Decision | By | Date | Affects |
|---|----------|----|------|---------|
| 1 | CLAUDE.md and README.md (command table updates) are outside dev-command file ownership. Flagging to lead for update. | dev-command | 2026-03-28 | CLAUDE.md, README.md |
| 2 | adopt.md command references `agents/adopt-scanner.md` and `agents/adopt-scaffolder.md` — these are owned by dev-agents (task #2). Command does graceful fallback if files do not exist yet. | dev-command | 2026-03-28 | commands/qf/adopt.md |
| 3 | Plugin mirror at `plugins/quangflow/skills/qf/adopt/SKILL.md` is an exact copy of `skills/qf/adopt/SKILL.md` per existing plugin convention. | dev-command | 2026-03-28 | plugins/quangflow/skills/qf/adopt/ |
