# CONTRACTS — /qf:adopt Milestone 1

All public interfaces between modules. Developers MUST implement exactly these schemas.

---

## Contract 1: Scanner Findings Schema

**Producer:** `adopt-scanner`
**Consumer:** `adopt.md` (orchestrator), then forwarded to `adopt-scaffolder`
**Format:** YAML block in agent response (not written to file in M1)

```yaml
# ScannerFindings — full schema
tech_stack:
  languages: []            # string[] — e.g. ["TypeScript", "Python"]
  frameworks: []           # string[] — e.g. ["Next.js", "FastAPI"]
  databases: []            # string[] — e.g. ["PostgreSQL", "Redis"]
  build_tools: []          # string[] — e.g. ["npm", "Docker", "webpack"]
  package_managers: []     # string[] — e.g. ["npm", "pip"]

project_structure:
  pattern: ""              # "monolith" | "microservices" | "monorepo"
  key_directories:         # list of detected dirs with inferred purpose
    - path: ""             # string — relative path from project root
      purpose: ""          # string — inferred role of the directory
  entry_points: []         # string[] — relative paths to main entry files
  total_files: 0           # integer — total files found in project root

conventions:
  naming: ""               # string — e.g. "camelCase for files, PascalCase for components"
  file_organization: ""    # string — e.g. "feature-based (src/features/)"
  test_pattern: ""         # string — e.g. "co-located (__tests__/ next to source)"
  existing_docs: []        # string[] — relative paths to existing docs found

gaps:
  - type: ""               # "no_tests" | "no_docs" | "no_ci" | "unrecognized_structure"
    detail: ""             # string — specific description of the gap

error:                     # present only if scanner encountered an error
  occurred: false          # boolean
  message: ""              # string — error description
  partial: false           # boolean — true if some findings were collected before failure
```

**Notes:**
- All array fields default to `[]` if nothing detected (never null)
- `error` key is omitted entirely if no error occurred
- Every inferred field that is not confirmed by a manifest/config MUST be annotated inline with `# ⚠️ ASSUMPTION:` comment

> ⚠️ ASSUMPTION: Scanner reads only files accessible from project root. Symlinked external dirs are not followed in M1.

---

## Contract 2: CONTEXT.md Output Schema

**Producer:** `adopt-scaffolder`
**Consumer:** All downstream `/qf:*` commands
**Format:** Markdown file written to `plans/{slug}/CONTEXT.md`

```markdown
# Context — {feature-slug}

## Metadata
```yaml
quangflow_version: "2.0.0"
pm_mode: hands-on             # always hands-on for /qf:adopt (user is technical enough to run adopt)
project_type: existing        # always "existing" for adopted projects
scan_depth: full              # new value — indicates adopt-level scan
adopted: true                 # flag for downstream phases
adopted_at: ""                # ISO-8601 timestamp of adoption
scanner_failed: false         # true if scanner agent errored — fields may be incomplete
created: ""                   # ISO-8601 timestamp
```

## Tech Stack
{derived from scanner findings tech_stack, or "TBD — scanner failed, set manually" if error}

## Project Structure
{directory tree summary from scanner key_directories + pattern, or "Not determined — scanner failed"}

## Existing Patterns
{conventions block from scanner findings, or "Not determined — scanner failed"}

## Dependencies
{key deps from tech_stack.frameworks + tech_stack.databases, or "N/A"}

## Constraints
{gap findings formatted as list:
- ⚠️ No tests found — consider /qf:5-maintain to address
- ⚠️ No CI/CD configuration detected
...or "None identified" if gaps is empty}

## Locked Decisions
(populated by post-adopt router on approval — adoption metadata goes here)
```

**Required behavior:**
- All generated content marked `status: DRAFT` until orchestrator approves
- DRAFT marker: `> **STATUS: DRAFT** — Awaiting user approval via /qf:adopt review gate.` at top of file
- On finalize: DRAFT marker removed, adoption metadata written to `## Locked Decisions`
- Schema fields inherited from `/qf:0-init` Step 4 — do NOT diverge
- New fields: `adopted`, `adopted_at`, `scan_depth: full`, `scanner_failed`

---

## Contract 3: Pre-Scan Questions Contract

**Producer:** Pre-scan Questionnaire (inline in adopt.md)
**Consumer:** `adopt-scanner`, `adopt-scaffolder` (via orchestrator)
**Format:** Structured answers object passed in agent prompts

### Questions (fixed in M1)

| # | Question | Answer type | Example |
|---|----------|-------------|---------|
| Q1 | "What is the primary programming language of this project?" | free text | "TypeScript" |
| Q2 | "What is the project structure type? (monolith / monorepo / microservices)" | choice | "monolith" |
| Q3 | "Does this project have a test suite?" | yes / no / partial | "partial" |
| Q4 | "Does this project have existing documentation?" | yes / no / partial | "yes" |
| Q5 | "What is your primary goal after adoption? (new feature / maintenance / both)" | choice | "new feature" |

### PreScanAnswers Object

```yaml
# PreScanAnswers schema — passed verbatim to both agent prompts
primary_language: ""        # string — from Q1
project_type_hint: ""       # "monolith" | "monorepo" | "microservices" — from Q2
has_tests: ""               # "yes" | "no" | "partial" — from Q3
has_docs: ""                # "yes" | "no" | "partial" — from Q4
adoption_goal: ""           # "new_feature" | "maintenance" | "both" — from Q5
```

**Notes:**
- Q1 answer used to guide scanner's manifest detection priority
- Q5 answer used by router to pre-select suggested next command
- All answers are hints; scanner findings override Q1/Q2 if contradicted by evidence

> ⚠️ ASSUMPTION: User answers are not validated beyond basic choice constraint. Free text (Q1) is accepted as-is.

---

## Contract 4: DraftArtifacts Schema

**Producer:** `adopt-scaffolder`
**Consumer:** `adopt.md` (orchestrator, for review gate and finalize)
**Format:** Structured summary in agent response

```yaml
# DraftArtifacts — scaffolder output summary
context_md_path: ""         # string — e.g. "plans/my-project/CONTEXT.md"
dirs_created: []            # string[] — dirs actually created (not already existing)
dirs_skipped: []            # string[] — dirs already existed (not recreated)
partial_adoption: false     # boolean — true if any existing QF artifacts were found
partial_adoption_details:   # present only if partial_adoption: true
  merged: []                # string[] — dirs/files merged (additive)
  preserved: []             # string[] — dirs/files left untouched
  updated: []               # string[] — files updated (user confirmed)
scanner_failed: false       # boolean — true if scaffolder received empty/error findings
assumptions: []             # string[] — list of ⚠️ ASSUMPTION items in generated CONTEXT.md
```

---

## Contract 5: Approval Gate Contract

**Producer:** User input
**Consumer:** `adopt.md` (orchestrator)
**Format:** Text input parsed by orchestrator

### Approval Flow

```
State: AWAITING_REVIEW
  Orchestrator presents:
    1. CONTEXT.md draft (formatted)
    2. Scanner gap findings (formatted list)
    3. Partial adoption report (if applicable)
    4. Prompt: "Type APPROVE to finalize, or describe what to change."

  User responds with one of:
    A. "APPROVE"          → transition to APPROVED
    B. Any other text     → treated as feedback, transition to REJECTED_WITH_FEEDBACK

State: APPROVED
  → Orchestrator calls finalize
  → Router presents next-command choice

State: REJECTED_WITH_FEEDBACK
  → Orchestrator determines which agent(s) to re-run:
    - Feedback about detected data (stack, structure) → re-run scanner
    - Feedback about formatting or content of CONTEXT.md → re-run scaffolder only
    - Feedback about both → re-run both
  → Agents re-run with feedback injected into prompt
  → Transition back to AWAITING_REVIEW
```

**Approval is case-insensitive:** "approve", "APPROVE", "Approve" all accepted.

> ⚠️ ASSUMPTION: There is no maximum retry count on rejection in M1. User can loop indefinitely.

---

## Contract 6: Post-Adopt Metadata Contract

**Producer:** Post-Adopt Router (inline in adopt.md)
**Consumer:** `CONTEXT.md → ## Locked Decisions`, all downstream `/qf:*` commands
**Format:** Appended to CONTEXT.md on finalize

```markdown
## Locked Decisions

- Adopted on {ISO-8601 date} via /qf:adopt
- Tech stack detected: {comma-separated summary from tech_stack}
- Project structure: {pattern}
- Scan found {N} gap(s): {comma-separated gap types, or "none"}
- Scanner failed: {yes/no} — {if yes: "fields marked ⚠️ ASSUMPTION need manual review"}
```

**Rules:**
- Written atomically on approval (not during DRAFT phase)
- Never modified by future phases (append-only like all Locked Decisions)
- Downstream commands use `adopted: true` flag to adjust behavior (e.g., `/qf:1-brainstorm` can pre-populate stack context)

---

## Contract 7: Error Signal Contract

**Producer:** `adopt-scanner` (on failure)
**Consumer:** `adopt.md` (orchestrator)
**Format:** Error block in agent response

```yaml
# Returned when scanner cannot complete normally
error:
  occurred: true
  message: ""              # human-readable description of the failure
  partial: true            # true if some findings were collected before failure
  findings_so_far:         # partial ScannerFindings if partial: true
    tech_stack: {}
    project_structure: {}
    conventions: {}
    gaps: []
```

**Orchestrator behavior on receiving error signal:**
1. Log error to orchestrator state
2. Set `scannerFailed: true` on the DraftArtifacts context passed to scaffolder
3. Scaffolder generates CONTEXT.md from PreScanAnswers + partial findings (if any)
4. Review gate displays prominent warning: `⚠️ Scanner failed. Fields marked ⚠️ ASSUMPTION need manual review.`
5. Adoption can still complete — scanner failure is non-blocking
