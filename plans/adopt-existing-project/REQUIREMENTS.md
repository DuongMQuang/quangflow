# Requirements: /qf:adopt — Adopt Existing Project

---
feature_slug: adopt-existing-project
status: M2-FINAL
pm_mode: hands-on
milestones: 2
team_mode: true
team_composition:
  - role: lead
    focus: "Orchestrator — coordinate team, user decisions"
    type: main-session
  - role: pm
    focus: "Track progress, resume context across sessions, report status at checkpoints"
    ownership: "plans/adopt-existing-project/milestone-*/STATUS.md"
    agent_type: project-manager
    required: true
  - role: domain-engineer
    focus: "Module design, contracts, sequences for M2 agents + synthesis"
    ownership: "plans/adopt-existing-project/milestone-2/design/*"
    agent_type: planner
    recommended: true
  - role: dev-new-agents
    focus: "adopt-feature-extractor.md + adopt-doc-generator.md agent definitions"
    ownership: "agents/adopt-feature-extractor.md, agents/adopt-doc-generator.md, plugins/quangflow/agents/adopt-feature-extractor.md, plugins/quangflow/agents/adopt-doc-generator.md"
    agent_type: fullstack-developer
    blocked_by: [domain-engineer]
  - role: dev-upgrades
    focus: "Scanner adaptive sizing upgrade + scaffolder .memory/ + doc integration"
    ownership: "agents/adopt-scanner.md, agents/adopt-scaffolder.md, plugins/quangflow/agents/adopt-scanner.md, plugins/quangflow/agents/adopt-scaffolder.md"
    agent_type: fullstack-developer
    blocked_by: [domain-engineer]
  - role: dev-orchestrator
    focus: "adopt.md extended orchestration — synthesis logic, confidence scoring, extended review gate"
    ownership: "commands/qf/adopt.md, skills/qf/adopt/*, plugins/quangflow/skills/qf/adopt/*"
    agent_type: fullstack-developer
    blocked_by: [domain-engineer]
  - role: tech-lead
    focus: "Code review, cross-dev integration, contract compliance"
    agent_type: code-reviewer
    optional: true
    blocked_by: [dev-new-agents, dev-upgrades, dev-orchestrator]
  - role: tester
    focus: "Verify all flows, contract compliance, regression against M1"
    ownership: "tests/*, __tests__/*"
    agent_type: tester
    blocked_by: [tech-lead]
---

## Core Problem

QuangFlow assumes greenfield projects via `/qf:0-init`. Existing projects with established codebases, conventions, and history have no onramp into the workflow. Project owners must manually set up QuangFlow artifacts, which is tedious and error-prone.

## Target User

Project owner who built/maintains an existing project and wants to adopt QuangFlow for future development.

## Success Metric

A project owner can run `/qf:adopt`, review the generated drafts, and immediately use any `/qf:*` command without manual setup.

## Requirements

### Milestone 1 — Core Adopt Flow [M1]

- **REQ-001**: `/qf:adopt` command with parallel agent team [M1]
  - Command entry point that spawns specialized agents in parallel
  - Orchestrates the scan → draft → review → approve flow
  - Handles errors gracefully if any agent fails (partial results still useful)

- **REQ-002**: Architecture scanning agent [M1]
  - Detects tech stack (languages, frameworks, databases, build tools)
  - Identifies project structure patterns (monolith, microservices, monorepo)
  - Maps directory layout and key entry points
  - Extracts conventions (naming, file organization, test patterns)

- **REQ-003**: Scaffolder agent [M1]
  - Creates `plans/`, `.evidence/`, `.memory/` directories
  - Generates CONTEXT.md with detected tech stack, project type, conventions
  - Detects and skips/merges if QuangFlow artifacts already exist (partial adoption)
  - Does NOT overwrite existing project files (additive only)

- **REQ-004**: Draft-then-review flow with approval gate [M1]
  - All generated artifacts are marked as DRAFT
  - User reviews each artifact category before finalizing
  - Approval gate: user must type APPROVE to finalize
  - If user rejects: agents can regenerate specific artifacts with feedback

- **REQ-005**: Post-adopt routing [M1]
  - After approval, present choice:
    - `/qf:1-brainstorm` — build something new on top of the adopted project
    - `/qf:5-maintain` — enter maintain mode for the existing project
  - Store adoption metadata in CONTEXT.md for future commands to reference

### Milestone 2 — Deep Analysis & Memory [M2]

- **REQ-006**: Feature extraction agent [M2]
  - Identifies distinct features/modules from codebase analysis
  - Maps each feature to potential Feature Memory Units
  - Flags features as "inferred" (needs user confirmation) vs "confirmed"
  - Populates `.memory/` with per-feature context files

- **REQ-007**: Doc generation agent [M2]
  - Produces architecture diagrams (Mermaid) — component diagram, dependency graph
  - Generates module map with responsibility descriptions
  - Creates/updates README sections (does not overwrite existing README content)

- **REQ-008**: Adaptive scanning for any project size [M2]
  - Small projects (< 50 files): read all files
  - Medium projects (50-500 files): read key files + sample others
  - Large projects (500+ files): smart sampling — entry points, configs, key modules, tests
  - Scanning strategy is transparent to user (reports what was/wasn't scanned)

- **REQ-009**: Synthesis step after parallel scanning [M2]
  - Reconciles findings across architect, feature extractor, and doc generator
  - Resolves conflicts (e.g., module count disagreements)
  - Produces unified project model that all output artifacts reference

- **REQ-010**: Confidence scoring on draft artifacts [M2]
  - Each draft artifact gets a confidence score (high/medium/low)
  - High confidence: auto-generated from clear signals (e.g., package.json detected)
  - Low confidence: inferred from heuristics (e.g., "this looks like a microservice")
  - User knows which drafts need careful review vs. which are reliable

## Edge Cases

1. **Partial adoption**: Project already has `plans/` or CONTEXT.md — detect and merge, don't overwrite
2. **Monorepo**: Multiple apps in one repo — ask user which app to scope, or adopt all
3. **No tests/no docs/messy structure**: Note gaps as findings, don't fail the scan
4. **Very large projects (1000+ files)**: Sampling strategy must still produce accurate architecture map
5. **Non-standard project structures**: Projects without standard framework conventions — rely on file analysis, not assumptions

## Out of Scope

- Migrating FROM another workflow tool (e.g., converting Jira tickets to requirements)
- Auto-fixing code quality issues found during scan
- Setting up CI/CD or deployment pipelines
- Rewriting/replacing existing documentation (additive only)
- Supporting non-code projects (docs-only repos, design repos)
