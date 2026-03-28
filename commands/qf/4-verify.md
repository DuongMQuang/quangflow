You are now entering Phase 4: Verify & Certify.

## State Check
See `_protocols/_shared.md → State Check Template`. Required artifact: finalized REQUIREMENTS.md + ROADMAP.md.
If missing: "No finalized requirements found. Run `/qf:3-handoff` first."

## Milestone Detection
See `_protocols/_shared.md → Milestone Detection`. Target artifact: `CERTIFICATION.md` (or `QA-REPORT.md` for legacy).
Read REQUIREMENTS.md (filter to [M{N}]), DESIGN.md, and CONTEXT.md.

## Pre-flight: Artifact Validation (auto — run FIRST)
Run the artifact validation script before any LLM analysis:
```bash
bash {quangflow-root}/scripts/validate/validate-artifacts.sh ./plans/{feature-slug}
```
- If script reports failures: present them to user and ask to fix before proceeding
- If script reports only warnings: proceed but note the warnings
- This catches structural issues (missing sections, broken cross-refs) deterministically

## Pre-flight: Implementation Check
- Check if source code exists for this milestone's features
- If no implementation found, tell user: "No implementation detected. Implement ROADMAP.md phases first, then re-run `/qf:4-verify`."
- Do NOT proceed if there's nothing to verify

## Pre-flight: TDD Compliance Audit (auto — run BEFORE test generation)

<HARD-GATE>
Do NOT proceed to test generation until TDD evidence is verified.
Every REQ-ID must have red + green logs in .evidence/tdd/.
</HARD-GATE>

Run the TDD coverage validation script:
```bash
bash {quangflow-root}/scripts/validate/validate-tdd-coverage.sh ./plans/{feature-slug}
```
- If script exits 0: TDD coverage confirmed. Proceed.
- If script exits 1: present failures to user. Block until all REQ-IDs have evidence.

## Pre-flight: Log Audit
Check structured logs for ERROR/FATAL entries:
- Read `.evidence/logs/test-run-*.jsonl` (if exists)
- Filter for `level: "ERROR"` or `level: "FATAL"`
- If found: flag as potential issues
- If no structured logs exist: warn about missing logging

## Pre-flight: Existing Tests Check
- Check if tester agent already generated tests during Phase 3 (team mode)
- If tests exist: reuse them, run them, and supplement with any missing coverage
- If no tests exist: generate tests from scratch (see Step 2)

## Automatic Review (always runs)

### Step 1: Requirements Traceability
- For each requirement ID tagged [M{N}] in REQUIREMENTS.md, verify implementation exists
- Map: REQ-ID → file(s) that implement it
- Flag any requirement not covered or partially implemented

### Step 2: Test Coverage (audit and supplement)
Dev agents already generated unit tests via TDD. Audit existing coverage and supplement.
If tester agent already ran in Phase 3, check coverage gaps and supplement. If no tests exist, generate from scratch:

**Unit Tests** — audit existing, supplement gaps:
- Test each module/function in isolation
- Cover happy path, edge cases, error handling
- Match against edge cases discussed in Phase 1

**Integration Tests** — generate when multiple modules interact:
- Test API contracts between modules
- Test data flow across boundaries
- Verify external service integrations
- For milestone-2+: test integration with previous milestone's code

**E2E / Suite Tests** — generate when user-facing flows exist:
- Test complete user workflows end-to-end
- Validate against success metrics from REQUIREMENTS.md

### Step 3: Run Tests (with dependency awareness)

**Cross-milestone regression (milestone-2+):**
If current milestone > 1, also run tests from ALL previous milestones as a regression check.
- Run previous milestone tests FIRST — if they fail, flag as REGRESSION (not new failure)
- Report regressions separately: "Milestone-{N} code broke {X} tests from milestone-{N-1}"
- Regressions are auto-classified as CRITICAL gaps in GAPS.md — must be fixed before SHIP

**Current milestone tests:**
- Execute all tests (existing from Phase 3 tester + any newly generated)
- **Test dependency chain**: If a foundational test fails (e.g., auth, DB connection, model creation), mark all downstream tests as BLOCKED instead of running them:
  - Auth tests fail → block all tests requiring authenticated requests (watchlist, protected routes, etc.)
  - Model/migration tests fail → block all service and endpoint tests that depend on those models
  - Service tests fail → block endpoint tests that call those services
- Report: total, passed, failed, skipped, **blocked**
- For each failure: map back to which requirement ID is violated
- For blocked tests: note which upstream failure caused the block
- **Run order**: infrastructure → models → services → endpoints → E2E (stop cascade at first layer failure)

### Step 4: Code Quality Checks
- If tech-lead review ran in Phase 3, read REVIEW.md and verify issues were resolved
- Verify code quality mandates from CONTEXT.md are respected
- Check: single responsibility, interface stability, data model versioning
- Flag any violations

### Step 5: Gap & Tech Debt Detection
Scan implementation for gaps not caught by tests or reviews:

**Gap categories:**
- **Partial implementation**: Requirement exists but only happy path covered, edge cases from Phase 1 missing
- **Integration gaps**: Modules work in isolation but cross-boundary contracts are incomplete
- **Tech debt**: Patterns that will cause pain at scale (N+1 queries, missing indexes, no caching layer, synchronous bottlenecks)
- **Missing error boundaries**: No graceful degradation, unhandled failure modes
- **Security gaps**: Auth bypass paths, unvalidated inputs at system boundaries

**Classification:**
- **Minor** (fix inline): Quick fixes devs can handle without architectural changes
- **Major** (needs remediation phase): Requires new code, new modules, or architectural refactoring

**If GAPS.md exists from Phase 3 tech-lead review:**
- Read existing GAPS.md, check which gaps were addressed (ADD/DEFER/IGNORE)
- Verify ADDed remediation phases were implemented
- Append any NEW gaps found in this step

**If no GAPS.md exists (no tests exist or tech-lead skipped):**
- Create GAPS.md with all detected gaps

## Automatic Review Output
Generate to ./plans/{feature-slug}/milestone-{N}/:
- CERTIFICATION.md — test results, requirement coverage matrix, TDD evidence summary, violations found (replaces QA-REPORT.md for new milestones; Phase 4 accepts both formats for backwards compatibility)
- GAPS.md — created or updated with gap findings from Step 5
- List: PASS / FAIL / WARN per requirement ID
- List: GAP-IDs with severity and status

## GOTCHAs Logging (after gap detection)
See `_protocols/_shared.md → GOTCHAs System → Logging Protocol`.
For each GAP found in Step 5, auto-create a gotcha entry in `plans/{feature-slug}/GOTCHAS.md`:
- Domain tag: infer from affected files (e.g., `src/api/*` → `backend`, `src/components/*` → `frontend`)
- Rule: derive from the gap's root cause — what should future phases check for?
- Tags: include the phase where this should have been caught (e.g., `phase-2` if it's a design gap, `phase-3` if ROADMAP missed it)

## Autopilot Mode Check
See `_protocols/_autopilot.md → Phase 4 — Verify`. If autopilot: auto-fix, plain-language results, auto-triage gaps.
If `hands-on` or not set: use normal review gate below.

## Review Gate
Present QA-REPORT.md + GAPS.md summary to user.

**If all PASS and no major gaps:**
- "All milestone-{N} requirements verified. No major gaps. Type SHIP to finalize."

**If any FAIL:**
- "Found test failures. Fix code and re-run `/qf:4-verify`, or re-run `/qf:1-brainstorm` to revise requirements."

**If major gaps found:**
- "Found {N} major gap(s) requiring attention:
  - GAP-XXX: {description} — {severity}
  Options per gap:
  - **ADD** — Create remediation phase in ROADMAP.md
  - **DEFER** — Move to next milestone, log in OPEN_QUESTIONS.md
  - **IGNORE** — Accept as known tech debt
  After addressing gaps, type SHIP to finalize."

**If ADD selected for any gap:**
- Append remediation phase(s) to ROADMAP.md
- Tell user: "Remediation phase(s) added. Implement them, then re-run `/qf:4-verify` to validate."
- Agent waits for re-run — does NOT auto-SHIP

**If all gaps resolved (DEFER/IGNORE/previously ADDed and verified):**
- Proceed to SHIP gate

Agent waits. Does nothing until user responds.

---

## Manual Review (optional, user-triggered)

Only if user requests deeper review after seeing QA-REPORT.md:

### Security Audit
- Input validation, auth checks, injection risks
- Flag OWASP top 10 concerns

### Performance Review
- Identify bottlenecks, unnecessary complexity
- Check scalability gates from DESIGN.md

### UX Walkthrough
- Walk through user flows described in REQUIREMENTS.md
- Flag friction points or missing error states

Append findings to QA-REPORT.md under "Manual Review" section.

## Progress Logging
See `_protocols/_shared.md → Progress Tracking`. Append Phase 4 row to `plans/{feature-slug}/PROGRESS.md`.
Key decisions to log: PASS/FAIL count, gap count, remediation needed (yes/no), iterations.

## Output Rule
See `_protocols/_shared.md → Output Rule`.

## Next Step
When user types SHIP:

**If more milestones remain:**
```
Milestone-{N} shipped!
**Next:** `/qf:2-design` — Design architecture for milestone-{N+1}
  ↳ Skip? Jump to `/qf:3-handoff` if reusing same architecture (confirm first)
  ↳ Also available: `/qf:status` (check status), `/qf:status save` (save context)
```

**If last milestone:**
```
All milestones complete! Project enters maintenance mode.
  => Report bugs: `/qf:5-maintain` (triage, investigate, fix)
  => Smoke test: `/qf:test` (verify project runs end-to-end)
  => Status: `/qf:status` (final status), `/qf:status save` (archive context)
```