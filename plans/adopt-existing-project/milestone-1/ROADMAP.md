# Milestone 1 — ROADMAP: Core Adopt Flow

## Overview
Implement the `/qf:adopt` command with parallel scanner/scaffolder agents, draft-then-review approval flow, and post-adopt routing.

**Requirements in scope:** REQ-001 [M1], REQ-002 [M1], REQ-003 [M1], REQ-004 [M1], REQ-005 [M1]

---

## Phase 1: adopt-scanner agent definition (REQ-002)

**Owner:** dev-agents
**Deliverable:** `agents/adopt-scanner.md` + `plugins/quangflow/agents/adopt-scanner.md`

### Tasks
- [ ] Define agent role, inputs, and output schema (structured findings YAML from DESIGN.md)
- [ ] Specify scan targets: manifest files (package.json, requirements.txt, go.mod, Cargo.toml, pyproject.toml, etc.)
- [ ] Specify scan targets: entry points (index.ts, main.py, app.ts, server.ts, etc.)
- [ ] Specify scan targets: config files (tsconfig.json, .env.example, docker-compose.yml, etc.)
- [ ] Specify scan targets: directory tree (2 levels deep for structure analysis)
- [ ] Specify scan targets: README.md and existing docs
- [ ] Define convention extraction rules (naming, file organization, test patterns)
- [ ] Define gap detection rules (no_tests, no_docs, no_ci, unrecognized_structure)
- [ ] Define output format: structured YAML matching the scanner findings schema in DESIGN.md
- [ ] Handle edge case: no recognizable structure → return `gaps: [{type: "unrecognized_structure"}]`

### Acceptance Criteria
- Agent reads codebase and returns structured findings YAML
- Findings include: tech_stack, project_structure, conventions, gaps
- Agent does NOT write any files — returns findings only
- Agent handles empty/minimal projects without crashing

### Done Criteria
- [ ] `agents/adopt-scanner.md` exists with complete agent definition
- [ ] Mirrored to `plugins/quangflow/agents/adopt-scanner.md`
- [ ] Agent definition follows same format as existing agents (domain-engineer.md, dev-teammate.md)

> **Discipline:** Follow RED-GREEN-REFACTOR. Save evidence to `.evidence/tdd/`. Implement structured logging per `_structured-logging.md`. Save phase gate evidence to `.evidence/verification/`.

---

## Phase 2: adopt-scaffolder agent definition (REQ-003)

**Owner:** dev-agents
**Deliverable:** `agents/adopt-scaffolder.md` + `plugins/quangflow/agents/adopt-scaffolder.md`

### Tasks
- [ ] Define agent role, inputs (scanner findings + pre-scan answers), and outputs
- [ ] Specify directory creation: `plans/{slug}/`, `.evidence/`, `.evidence/tdd/`, `.evidence/debug/`, `.evidence/verification/`, `.evidence/logs/`, `.memory/`
- [ ] Specify CONTEXT.md generation using exact `/qf:0-init` Step 4 schema
- [ ] Add `adopted: true` and `scan_depth: full` fields to CONTEXT.md metadata
- [ ] Add `adopted_at: ISO-8601` timestamp
- [ ] Define partial adoption detection: check for existing `plans/`, `CONTEXT.md`, `.memory/`, `.evidence/`
- [ ] Define merge strategy: ask user "merge or skip?" for existing artifacts
- [ ] Define additive-only rule: never overwrite existing project files
- [ ] Mark all output as `status: DRAFT`
- [ ] Create OPEN_QUESTIONS.md scaffold

### Acceptance Criteria
- Agent creates QuangFlow directory structure from scanner findings
- CONTEXT.md matches exact schema from `/qf:0-init` (backward-compatible)
- Detects and handles existing QuangFlow artifacts (partial adoption)
- Never overwrites existing project files
- All output marked DRAFT

### Done Criteria
- [ ] `agents/adopt-scaffolder.md` exists with complete agent definition
- [ ] Mirrored to `plugins/quangflow/agents/adopt-scaffolder.md`
- [ ] Agent definition follows same format as existing agents

> **Discipline:** Follow RED-GREEN-REFACTOR. Save evidence to `.evidence/tdd/`. Implement structured logging per `_structured-logging.md`. Save phase gate evidence to `.evidence/verification/`.

---

## Phase 3: adopt.md command — orchestration core (REQ-001)

**Owner:** dev-command
**Deliverable:** `commands/qf/adopt.md` + `skills/qf/adopt/SKILL.md` + `plugins/quangflow/skills/qf/adopt/SKILL.md`

### Tasks
- [ ] Define command entry point with arguments: `/qf:adopt` (interactive), `/qf:adopt <slug>` (with feature slug)
- [ ] Implement Step 1: Feature slug derivation (kebab-case from project directory name or user input)
- [ ] Implement Step 2: Pre-scan questions (5 interactive questions):
  - Project type confirmation (web app, CLI, library, API, mobile, etc.)
  - Primary language/framework
  - Monorepo? (single app vs multiple apps)
  - Test setup (existing tests? framework?)
  - Documentation expectations (minimal, standard, comprehensive)
- [ ] Implement Step 3: Fan-out — spawn adopt-scanner and adopt-scaffolder as parallel agents
  - Read `agents/adopt-scanner.md` for scanner prompt
  - Scanner runs first; scaffolder receives scanner findings
  - Handle agent spawn errors gracefully
- [ ] Implement Step 4: Fan-in — collect agent outputs, present to user
- [ ] Implement error handling: if scanner fails → show partial results; if scaffolder fails → show scanner findings only

### Acceptance Criteria
- Command spawns scanner and scaffolder agents
- Pre-scan questions are asked before agents run
- Scanner findings are passed to scaffolder
- If any agent fails, partial results are still presented
- Command follows same markdown format as existing commands (0-init.md, cook.md)

### Done Criteria
- [ ] `commands/qf/adopt.md` exists with complete command definition
- [ ] `skills/qf/adopt/SKILL.md` exists (skill mirror)
- [ ] `plugins/quangflow/skills/qf/adopt/SKILL.md` exists (plugin mirror)
- [ ] Command references `agents/adopt-scanner.md` and `agents/adopt-scaffolder.md`

> **Discipline:** Follow RED-GREEN-REFACTOR. Save evidence to `.evidence/tdd/`. Implement structured logging per `_structured-logging.md`. Save phase gate evidence to `.evidence/verification/`.

---

## Phase 4: Draft review + approval gate (REQ-004)

**Owner:** dev-command
**Deliverable:** Approval flow section in `commands/qf/adopt.md`

### Tasks
- [ ] Add review presentation section: display draft CONTEXT.md contents to user
- [ ] Add review presentation section: display scanner gap findings summary
- [ ] Add review presentation section: display directory structure that was/will be created
- [ ] Implement approval gate: "Type APPROVE to finalize, or describe what to change."
- [ ] Implement rejection flow: accept user feedback → identify which agent to re-run → re-spawn with feedback
- [ ] Implement finalization: remove DRAFT status from artifacts, write final versions
- [ ] Handle edge case: user approves with modifications ("APPROVE but change X") → apply inline edits

### Acceptance Criteria
- User sees all draft artifacts before finalizing
- APPROVE finalizes all artifacts (removes DRAFT status)
- Rejection allows targeted regeneration with feedback
- No artifacts are finalized without explicit user approval

### Done Criteria
- [ ] Approval flow section exists in `commands/qf/adopt.md`
- [ ] APPROVE / reject / re-run logic is fully specified

> **Discipline:** Follow RED-GREEN-REFACTOR. Save evidence to `.evidence/tdd/`. Implement structured logging per `_structured-logging.md`. Save phase gate evidence to `.evidence/verification/`.

---

## Phase 5: Post-adopt routing (REQ-005)

**Owner:** dev-command
**Deliverable:** Routing section in `commands/qf/adopt.md`

### Tasks
- [ ] Add post-approval routing: present two options with descriptions
  - `/qf:1-brainstorm` — Plan a new feature on top of the adopted project
  - `/qf:5-maintain` — Enter maintenance mode (scan for bugs, monitor logs)
- [ ] Store adoption metadata in CONTEXT.md `## Locked Decisions`:
  - Adopted on {date} via /qf:adopt
  - Tech stack detected: {summary from scanner}
  - Scan found {N} gaps (listed in Constraints section)
- [ ] Update CLAUDE.md command table to include `/qf:adopt`
- [ ] Update README.md command table to include `/qf:adopt`

### Acceptance Criteria
- User is presented with clear next-step options after adoption
- Adoption metadata is persisted in CONTEXT.md for downstream phases
- CLAUDE.md and README.md reflect the new command

### Done Criteria
- [ ] Routing section exists in `commands/qf/adopt.md`
- [ ] CONTEXT.md locked decisions section is specified
- [ ] CLAUDE.md and README.md updated with `/qf:adopt` entry

> **Discipline:** Follow RED-GREEN-REFACTOR. Save evidence to `.evidence/tdd/`. Implement structured logging per `_structured-logging.md`. Save phase gate evidence to `.evidence/verification/`.

---

## Phase 6: Integration + smoke test

**Owner:** tester
**Deliverable:** End-to-end validation of the full adopt flow

### Tasks
- [ ] Verify adopt-scanner.md agent definition is complete and follows existing agent format
- [ ] Verify adopt-scaffolder.md agent definition is complete and follows existing agent format
- [ ] Verify adopt.md command definition is complete and follows existing command format
- [ ] Verify skill mirrors exist (skills/qf/adopt/SKILL.md, plugins/quangflow/skills/qf/adopt/SKILL.md)
- [ ] Verify plugin mirrors exist (plugins/quangflow/agents/adopt-scanner.md, adopt-scaffolder.md)
- [ ] Trace full flow: command → pre-scan → fan-out → fan-in → review → approve → route
- [ ] Verify CONTEXT.md schema compatibility with `/qf:0-init` Step 4
- [ ] Verify partial adoption edge case is handled in scaffolder
- [ ] Verify error handling: scanner failure, scaffolder failure, both failure
- [ ] Verify CLAUDE.md and README.md have been updated

### Acceptance Criteria
- All files exist in correct locations
- Flow is traceable end-to-end from command to routing
- No broken references between command and agent files
- CONTEXT.md output is compatible with all downstream `/qf:*` commands

### Done Criteria
- [ ] All verification checks pass
- [ ] QA report written to milestone-1/
