# OVERVIEW — /qf:adopt Milestone 1

## System Components

| Component | Type | Responsibility |
|-----------|------|----------------|
| `adopt.md` | Command / Orchestrator | Entry point. Runs pre-scan questions, fans out to agents, fans in results, presents review gate, routes post-approval. |
| `adopt-scanner` | Agent (planner / sonnet) | Read-only codebase analysis. Produces structured YAML findings. No file writes. |
| `adopt-scaffolder` | Agent (fullstack-developer / sonnet) | Creates QuangFlow directory scaffold and CONTEXT.md draft from scanner findings. Additive only. |
| Pre-scan Questionnaire | Inline step in adopt.md | 5 interactive questions collected before agents spawn. Results passed as context to both agents. |
| Draft Review Gate | Inline step in adopt.md | Presents DRAFT artifacts to user. Accepts APPROVE or feedback. Re-runs specific agents on rejection. |
| Post-Adopt Router | Inline step in adopt.md | After approval, presents `/qf:1-brainstorm` vs `/qf:5-maintain` choice and stores metadata. |

---

## System Flowchart

```mermaid
flowchart TD
    USER([User]) -->|"/qf:adopt"| ENTRY

    subgraph ORCHESTRATOR["adopt.md — Orchestrator"]
        ENTRY["adopt.md entry point"]
        PRE["Pre-scan: 5 questions\n(language, type, monorepo, tests, docs)"]
        FANOUT["Fan-out: spawn parallel agents"]
        FANIN["Fan-in: collect results\nmark all artifacts DRAFT"]
        REVIEW["Draft Review Gate\nPresent CONTEXT.md + gap findings"]
        GATE{User types\nAPPROVE?}
        REGEN["Re-run agent(s)\nwith user feedback"]
        FINALIZE["Finalize: remove DRAFT status\nwrite adoption metadata"]
        ROUTE["Post-adopt routing:\n1. /qf:1-brainstorm\n2. /qf:5-maintain"]
    end

    subgraph AGENTS["Parallel Agents"]
        SCANNER["adopt-scanner\n(planner / sonnet)\nReads codebase → YAML findings"]
        SCAFFOLDER["adopt-scaffolder\n(fullstack-developer / sonnet)\nCreates dirs + CONTEXT.md draft"]
    end

    subgraph OUTPUT["Generated Artifacts"]
        CTX["plans/{slug}/CONTEXT.md\n(status: DRAFT)"]
        DIRS["plans/ .evidence/ .memory/\ndirectory scaffold"]
        META["CONTEXT.md → Locked Decisions\nadoption metadata"]
    end

    ENTRY --> PRE
    PRE --> FANOUT
    FANOUT -->|"pre-scan answers\n+ project root"| SCANNER
    FANOUT -->|"pre-scan answers"| SCAFFOLDER
    SCANNER -->|"YAML findings\nvia orchestrator"| SCAFFOLDER
    SCANNER --> FANIN
    SCAFFOLDER --> FANIN
    FANIN --> REVIEW
    REVIEW --> GATE
    GATE -->|"Rejected:\nfeedback given"| REGEN
    REGEN --> REVIEW
    GATE -->|"APPROVE"| FINALIZE
    FINALIZE --> ROUTE
    ROUTE --> USER

    SCAFFOLDER -->|creates| DIRS
    SCAFFOLDER -->|generates| CTX
    FINALIZE -->|writes| META
```

---

## Key Design Decisions

- **Scanner is read-only**: never writes files. Returns findings directly to orchestrator via agent output.
- **Scaffolder receives scanner findings**: orchestrator passes findings in scaffolder's prompt context — no intermediate file needed in M1.
- **Standalone command, not reusing cook**: adopt is read-then-generate, not plan-then-build. No TDD, no file ownership, no worktree isolation needed.
- **CONTEXT.md schema compatibility**: exact same schema as `/qf:0-init` Step 4 with two additive fields (`adopted: true`, `scan_depth: full`).
- **Error resilience**: if scanner fails, scaffolder still runs with pre-scan answers only. Partial results surfaced to user.
