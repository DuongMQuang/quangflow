You are now entering Phase 4: Verify & QA.

## State Check
- Scan ./plans/ for feature directories with finalized REQUIREMENTS.md and milestone directories containing ROADMAP.md
- If multiple features found, ask user which feature
- If missing, tell user: "No finalized requirements found. Run `/qf-3` first."

## Milestone Detection
- Find the next milestone with ROADMAP.md but no QA-REPORT.md
- Confirm with user: "Verifying milestone-{N}. Correct?"
- Read REQUIREMENTS.md (filter to current milestone's [M{N}] requirements), DESIGN.md, and CONTEXT.md

## Pre-flight: Implementation Check
- Check if source code exists for this milestone's features
- If no implementation found, tell user: "No implementation detected. Implement ROADMAP.md phases first, then re-run `/qf-4`."
- Do NOT proceed if there's nothing to verify

## Pre-flight: Existing Tests Check
- Check if tester agent already generated tests during Phase 3 (team mode)
- If tests exist: reuse them, run them, and supplement with any missing coverage
- If no tests exist (solo mode): generate tests from scratch (see Step 2)

## Automatic Review (always runs)

### Step 1: Requirements Traceability
- For each requirement ID tagged [M{N}] in REQUIREMENTS.md, verify implementation exists
- Map: REQ-ID → file(s) that implement it
- Flag any requirement not covered or partially implemented

### Step 2: Test Coverage (generate or supplement)
If tester agent already ran in Phase 3, check coverage gaps and supplement. Otherwise generate:

**Unit Tests** — always generate:
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

**If no GAPS.md exists (solo mode or tech-lead skipped):**
- Create GAPS.md with all detected gaps

## Automatic Review Output
Generate to ./plans/{feature-slug}/milestone-{N}/:
- QA-REPORT.md — test results, requirement coverage matrix, violations found
- GAPS.md — created or updated with gap findings from Step 5
- List: PASS / FAIL / WARN per requirement ID
- List: GAP-IDs with severity and status

## Review Gate
Present QA-REPORT.md + GAPS.md summary to user.

**If all PASS and no major gaps:**
- "All milestone-{N} requirements verified. No major gaps. Type SHIP to finalize."

**If any FAIL:**
- "Found test failures. Fix code and re-run `/qf-4`, or re-run `/qf-1` to revise requirements."

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
- Tell user: "Remediation phase(s) added. Implement them, then re-run `/qf-4` to validate."
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

## Output Rule
When writing files, save silently. Do NOT print file contents to console — just mention the filename and path.

## Next Step
When user types SHIP:
- If more milestones remain: "Milestone-{N} shipped! Next: run `/qf-2` to start milestone-{N+1}."
- If last milestone: "All milestones complete. Project is verified and ready to ship."