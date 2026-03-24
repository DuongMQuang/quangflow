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

## How to Scope (Script-Enforced)

**Use the context builder script — do NOT manually filter documents:**
```bash
bash scripts/build-agent-context.sh --role {role} --milestone-dir {path} \
  --ownership "{globs}" --reqs "{REQ-IDs}" --phases "{phase-nums}" \
  --output plans/{slug}/milestone-{N}/.context-{role}.md
```

The script deterministically extracts:
- For devs: only their ROADMAP phases, their module sections from CONTRACTS/MODULES, their REQ-IDs
- For tester: acceptance criteria + edge cases only
- For all: GOTCHAs (last 5 entries from both global and feature files)

Pass the output file contents as the agent's context. Always also include: CK Context Block, agent instructions.

## Audit Trail

After building context, log what was injected:
```bash
bash scripts/log-agent-audit.sh --role {role} --milestone-dir {path} \
  --model {model} --context-file {context-path} --ownership "{globs}" --reqs "{ids}"
```
Creates/appends to `AUDIT-LOG.md` in the milestone directory. Enables post-hoc verification of what each agent received.

## Runtime Ownership Enforcement

For dev agents, a PreToolUse hook blocks file edits outside their ownership globs:
- Cook writes `.claude/.current-agent-ownership` before spawning each dev
- Hook at `scripts/hooks/enforce-ownership.sh` checks Write/Edit paths against ownership
- Violations are blocked with an error message directing the dev to message the lead

See `scripts/hooks/enforce-ownership.sh` for hook configuration instructions.
