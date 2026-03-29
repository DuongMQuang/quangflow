# Design Debate Protocol

Referenced by `cook.md` Stage 1.5. Optional — skip with `--skip debate` or if domain-engineer was skipped.

## Purpose

Catch design issues BEFORE devs start coding. Two parallel critics review design docs from different angles, then lead synthesizes and user decides.

## Execution

1. READ `.claude/agents/critic.md` for role instructions
2. Spawn TWO critic agents **in parallel**:

   **Feasibility Critic:**
   - `Task(subagent_type: "code-reviewer", name: "critic-feasibility")`
   - model: `haiku`
   - Focus: "Can this realistically be built? What's underestimated? Where will devs get stuck?"
   - Input: design docs (OVERVIEW, MODULES, SEQUENCES, CONTRACTS) + REQUIREMENTS.md + CONTEXT.md + ROADMAP.md
   - Output: max 10 findings, each with: issue, impact, suggested fix

   **Simplicity Critic:**
   - `Task(subagent_type: "code-reviewer", name: "critic-simplicity")`
   - model: `haiku`
   - Focus: "What's overengineered? What can be removed or simplified without losing value?"
   - Input: same as feasibility
   - Output: max 10 findings

3. WAIT for both to complete (parallel — no sequential dependency)

4. Synthesize findings into `plans/{slug}/milestone-{N}/design/DEBATE.md`:

   ```markdown
   # Design Debate — Milestone {N}

   ## Feasibility Concerns
   | # | Issue | Impact | Suggested Fix |
   |---|-------|--------|---------------|
   | F-1 | {issue} | {impact} | {fix} |

   ## Simplicity Concerns
   | # | Issue | Impact | Suggested Fix |
   |---|-------|--------|---------------|
   | S-1 | {issue} | {impact} | {fix} |

   ## Conflicts
   {where feasibility and simplicity critics disagree — if any}

   ## Lead Recommendation
   {lead's synthesis: which concerns to accept, which to dismiss, why}
   ```

5. Present summary to user:
   "Design debate complete. {N} feasibility concerns, {M} simplicity concerns.
   Top issues: {1-3 most impactful}
   Full report: `plans/{slug}/milestone-{N}/design/DEBATE.md`

   Options:
   - **PROCEED** — Accept recommendations, continue to dev stage
   - **REVISE** — Send feedback back to domain-engineer for design changes
   - **SKIP** — Ignore debate, continue with original design"

6. On **REVISE**: message domain-engineer with specific feedback, wait for updates, re-run critics (max 1 revision round)
7. On **PROCEED** or **SKIP**: continue to Stage 2

## Token Budget

Critics use `haiku` model to keep costs low. Max 10 findings each = bounded output.
