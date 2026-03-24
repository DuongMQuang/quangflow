# Scoped Context Injection

Referenced by `cook.md`. Each agent receives ONLY the context slices relevant to their role — not the full project dump. Reduces token usage and keeps agents focused.

## Scoping Matrix

| Agent | Gets | Does NOT get |
|-------|------|-------------|
| domain-engineer | REQUIREMENTS.md, DESIGN.md, CONTEXT.md, ROADMAP.md, GOTCHAS (filtered) | Source code, test files, BUGLOG |
| critic | Design docs (OVERVIEW, MODULES, SEQUENCES, CONTRACTS), REQUIREMENTS.md, CONTEXT.md | Source code, BUGLOG, STATUS |
| dev-{scope} | ROADMAP phases **for their scope only**, CONTRACTS.md, MODULES.md **sections for their modules only**, SEQUENCES.md **flows involving their modules**, GOTCHAS (filtered by domain), DECISIONS.md | Other dev's ROADMAP phases, rejected design options, full REQUIREMENTS (only their REQ-IDs) |
| tech-lead | All dev output files, DESIGN.md, CONTRACTS.md, MODULES.md | ROADMAP phases, brainstorm edge cases, rejected options |
| tester | REQUIREMENTS.md (acceptance criteria + edge cases only), CONTRACTS.md, list of implemented files | Design rationale, rejected options, ROADMAP |
| pm | REQUIREMENTS.md, ROADMAP.md, REVIEW.md, GAPS.md, tester results | Source code, design docs detail |

## How to Scope

- For devs: filter ROADMAP.md to only include phases assigned to that dev role
- For devs: extract only their module sections from MODULES.md and CONTRACTS.md
- For tester: extract acceptance criteria and edge cases from REQUIREMENTS.md, omit problem statement and personas
- Always include: CK Context Block, agent instructions, DECISIONS.md
