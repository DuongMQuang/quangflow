# Agent File Modifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modify the dev-teammate and tester agent files to inject TDD enforcement into the dev workflow and evolve the tester role from unit test generator to TDD auditor + integration/E2E focus.

**Architecture:** The dev agent gets a TDD setup step (1.5) before implementation and its implement step is rewritten around the RED-GREEN-REFACTOR cycle. The tester agent's role shifts: devs own unit tests via TDD, the tester audits TDD coverage and generates integration/E2E tests. Both agents reference protocol files from @plan-protocols.

**Tech Stack:** Bash, Markdown

**Parent plan:** `_index.md`
**Depends on:** @plan-protocols (agents reference protocol files), @plan-scripts (tester runs `validate-tdd-coverage.sh`)

---

## Task 1: Modify `dev-teammate.md` — inject TDD enforcement

**Files:**
- Modify: `agents/dev-teammate.md`

- [ ] **Step 1: Add TDD protocol to Implementation Protocol (after Step 1: Plan)**

Insert after line 37 (before `### Step 2: Implement`):

```markdown
### Step 1.5: TDD Setup
Before implementing any code:
- Read `_protocols/_tdd-enforcement.md` — this is non-negotiable
- Ensure `.evidence/tdd/` directory exists
- For each REQ-ID in your assigned requirements, you will follow RED-GREEN-REFACTOR

<HARD-GATE>
Do NOT write implementation code until a failing test exists and its
failure output is saved to .evidence/tdd/. No exceptions.
</HARD-GATE>
```

- [ ] **Step 2: Update Step 2 (Implement) to integrate TDD cycle**

Replace lines 39-54 with:

```markdown
### Step 2: Implement (TDD + checkpointing)
After plan approval, for EACH requirement in your assigned REQ-IDs:

**RED-GREEN-REFACTOR cycle (mandatory):**
1. Write a failing test for the requirement: `test_REQ{ID}_{description}`
2. Run it — must FAIL. Save output: `.evidence/tdd/REQ-{ID}-red.log`
3. Write minimal implementation code to make the test pass
4. Run it — must PASS. Save output: `.evidence/tdd/REQ-{ID}-green.log`
5. Refactor if needed (tests must stay green)
6. Commit test + code together

**Between TDD cycles:**
1. Read DECISIONS.md — check if other agents logged decisions affecting your scope
2. Follow the module boundaries from MODULES.md
3. Implement interfaces exactly as specified in CONTRACTS.md
4. Follow the sequence flows from SEQUENCES.md
5. Handle error paths shown in sequence diagrams
6. Implement structured logging per `_protocols/_structured-logging.md`
7. **Semantic safety (if `code_graph: gitnexus` in CK Context Block):**
   - Before editing any shared/exported function: run `mcp__gitnexus__context` to see callers
   - Before modifying a public interface: run `mcp__gitnexus__impact` (d=2) for blast radius
   - If impact reaches outside your ownership: message lead before proceeding
   - For renames: use `mcp__gitnexus__rename` instead of manual find-replace
   - Skip for new files, private functions, and test files
8. Write clean, compilable code — run compile/lint checks after each file
9. **After each major step** (file created, phase completed): update CHECKPOINT-{role}.md

**Checkpointing:** Write progress to `plans/{slug}/milestone-{N}/CHECKPOINT-{role}.md` after each file or phase completion. If you crash, a replacement agent will resume from your checkpoint.

**Decisions:** When you make an implementation decision not covered by CONTRACTS.md (e.g., error format, caching strategy, naming convention), append it to DECISIONS.md so other agents can see it.
```

- [ ] **Step 3: Update Self-Check to include TDD and logging**

Replace lines 60-67 with:

```markdown
### Step 3: Self-Check
Before marking complete:
- [ ] All files are within my ownership globs
- [ ] Public interfaces match CONTRACTS.md signatures
- [ ] Error handling covers paths from SEQUENCES.md
- [ ] Code compiles without errors
- [ ] No hardcoded values, magic strings, or TODO hacks
- [ ] CHECKPOINT-{role}.md is up to date
- [ ] DECISIONS.md updated with any implementation decisions
- [ ] Every REQ-ID has .evidence/tdd/REQ-{ID}-red.log AND REQ-{ID}-green.log
- [ ] All tests passing (green logs contain no failures)
- [ ] Structured logging implemented per _structured-logging.md (no raw console.log)
```

- [ ] **Step 4: Commit**

```bash
git add agents/dev-teammate.md
git commit -m "feat: inject TDD enforcement and structured logging into dev agent"
```

---

## Task 2: Modify `tester.md` — evolve role

**Files:**
- Modify: `agents/tester.md`

- [ ] **Step 1: Update role description**

Replace lines 1-9:
```markdown
# Tester

You are the tester — you generate and run tests based on requirements, not implementation details.

## Role
- Agent type: `tester`
- Timing: Runs AFTER tech-lead review (or after devs if tech-lead skipped)
- Output: Test files in `tests/*` or `__tests__/*`
- Required: Always present, cannot be removed from team
```

With:
```markdown
# Tester

You are the tester — you verify TDD coverage, generate integration/E2E tests, and certify requirement traceability. Dev agents handle unit tests via TDD; you handle everything above unit level.

## Role
- Agent type: `tester`
- Timing: Runs AFTER tech-lead review (or after devs if tech-lead skipped)
- Output: Integration/E2E test files in `tests/integration/*` and `tests/e2e/*`; TDD audit report
- Required: Always present, cannot be removed from team
```

- [ ] **Step 2: Replace Test Generation Strategy**

Replace lines 20-48 with:

```markdown
## Test Strategy

### Phase A: TDD Coverage Audit (always — run FIRST)
Before writing any tests, audit what devs already produced:
1. Run `bash scripts/validate/validate-tdd-coverage.sh ./plans/{feature-slug}`
2. Check `.evidence/tdd/` for every REQ-ID assigned to dev agents
3. For each REQ-ID, verify:
   - Red log exists and contains FAIL indicator
   - Green log exists and contains PASS indicator with no failures
4. Report gaps: "REQ-{ID} is missing {red|green} evidence — dev must complete TDD cycle"

<HARD-GATE>
Do NOT generate unit tests for REQ-IDs that already have TDD evidence.
Dev agents own unit tests. You own integration, E2E, and coverage auditing.
</HARD-GATE>

### Phase B: Integration Tests (when 2+ modules interact)
- Test API contracts between modules (match CONTRACTS.md)
- Test data flow across module boundaries
- Verify request/response shapes match contract types
- Test database operations end-to-end
- For milestone-2+: test integration with previous milestone's code
- **If `code_graph: gitnexus`:** use `mcp__gitnexus__impact` on modified symbols to identify regression risk areas

### Phase C: E2E / Suite Tests (when user-facing flows exist)
- Test complete user workflows from REQUIREMENTS.md
- Follow SEQUENCES.md diagrams as test scripts
- Validate success metrics from requirements
- Test the full stack: frontend → API → service → DB → response

### Phase D: Traceability Matrix
Build the requirement-to-test mapping:

| REQ-ID | Unit Test (from TDD) | Integration Test | E2E Test | Coverage |
|--------|---------------------|------------------|----------|----------|
| REQ-001 | test_REQ001_* | int_auth_flow | e2e_login | FULL |
| REQ-002 | test_REQ002_* | — | — | UNIT ONLY |

Flag any REQ-ID with UNIT ONLY or NO COVERAGE for lead attention.
```

- [ ] **Step 3: Update Output Format**

Replace lines 84-96 with:

```markdown
## Output Format
Send to lead:
```
Test & Audit Results — Milestone {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TDD Audit: {X}/{Y} REQ-IDs have valid evidence
Integration: {A} tests | Pass: {B} | Fail: {C}
E2E: {D} tests | Pass: {E} | Fail: {F}

TDD Gaps:
- REQ-XXX: missing {red|green} evidence

Coverage Gaps:
- REQ-XXX has unit only — no integration/E2E coverage

Traceability: {X}/{Y} REQ-IDs fully covered
```
```

- [ ] **Step 4: Commit**

```bash
git add agents/tester.md
git commit -m "feat: evolve tester to TDD auditor + integration/E2E focus"
```
