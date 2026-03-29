# Tech Lead Review — /qf:adopt Milestone 1

**Reviewer:** tech-lead
**Date:** 2026-03-28
**Branch:** main

---

## Summary

| Category | Count |
|----------|-------|
| Files reviewed | 7 |
| Minor issues | 6 |
| Major gaps | 1 |
| Plugin mirrors verified | Yes (exact copies) |
| Architecture compliance | PASS with caveats |

---

## Files Reviewed

1. `agents/adopt-scanner.md`
2. `agents/adopt-scaffolder.md`
3. `plugins/quangflow/agents/adopt-scanner.md`
4. `plugins/quangflow/agents/adopt-scaffolder.md`
5. `commands/qf/adopt.md`
6. `skills/qf/adopt/SKILL.md`
7. `plugins/quangflow/skills/qf/adopt/SKILL.md`

Also reviewed for context:
- `plans/adopt-existing-project/milestone-1/design/CONTRACTS.md`
- `plans/adopt-existing-project/milestone-1/design/OVERVIEW.md`
- `plans/adopt-existing-project/milestone-1/design/MODULES.md`
- `plans/adopt-existing-project/milestone-1/design/SEQUENCES.md`
- `plans/adopt-existing-project/milestone-1/DESIGN.md`
- `plans/adopt-existing-project/REQUIREMENTS.md`
- `plans/adopt-existing-project/milestone-1/DECISIONS.md`
- `CLAUDE.md` (command table update)
- `README.md` (command table update)

---

## Architecture Compliance Assessment

### Overall: PASS with one major gap

The implementation correctly captures the core architecture decisions:
- Scanner is read-only, returns YAML to orchestrator
- Scaffolder is additive-only
- Orchestrator handles fan-out/fan-in and does not scan/write directly
- Approval state machine present and case-insensitive
- Error resilience: scanner failure is non-blocking
- Partial adoption detection and merge/skip rules implemented
- Post-adopt routing based on adoption_goal implemented

All 4 sequences from SEQUENCES.md (happy path, partial adoption, scanner failure, rejection loop) are covered.

---

## Minor Issues

| # | File | Issue | Status |
|---|------|-------|--------|
| 1 | `agents/adopt-scaffolder.md` | `quangflow_version` hardcoded as `"1.1.0"` but CONTRACTS.md Contract 2 specifies `"2.0.0"`. Version mismatch will produce incorrect metadata. | Recommendation for lead |
| 2 | `agents/adopt-scaffolder.md` | Contract 2 requires `created: ""` field in metadata YAML. The generated template omits `created`. Downstream phases that read `created` will find it missing. | Recommendation for lead |
| 3 | `commands/qf/adopt.md` | Scanner agent prompt hardcodes the CONTRACTS.md path as `plans/adopt-existing-project/milestone-1/design/CONTRACTS.md`. This is the dev plan path, not a runtime path. At runtime this file won't exist in the adopted user's project — the instruction will silently fail. The scanner doesn't need to read CONTRACTS.md at runtime; the protocol is already embedded in `agents/adopt-scanner.md`. The line should be removed or changed to reference the agent file only. | Recommendation for lead |
| 4 | `commands/qf/adopt.md` | Step 6 Finalize creates `OPEN_QUESTIONS.md`. Contract 6 (Post-Adopt Metadata Contract) does not require creating OPEN_QUESTIONS.md as part of finalization — that file belongs to `/qf:1-brainstorm`. This is minor scope creep; the file creation is low-risk but undocumented in contracts. | Accepted deviation — useful, low risk |
| 5 | `agents/adopt-scanner.md` | Assumption annotation format uses `# ASSUMPTION:` (without warning emoji) while CONTRACTS.md consistently uses `# ⚠️ ASSUMPTION:` (with emoji). This inconsistency will produce scanner output that doesn't visually flag assumptions for the user at the review gate. | Recommendation for lead |
| 6 | `agents/adopt-scaffolder.md` | When CONTEXT.md already exists (partial adoption), the scaffolder spec says to record the draft file in `partial_adoption_details.merged`. However the text says "Record in `partial_adoption_details.merged`" but the scenario is preservation + new file, which should be split: existing file goes to `preserved`, new `CONTEXT.draft.md` goes to `merged`. The wording is ambiguous and may cause the orchestrator to misread the partial adoption report at the review gate. | Recommendation for lead |

---

## Major Gaps

### GAP-001: CONTEXT.md written to wrong path in scaffolder

**Severity:** Major
**File:** `agents/adopt-scaffolder.md`
**Contract violated:** Contract 2 + MODULES.md Module 3

**Description:**
The scaffolder generates CONTEXT.md at `plans/CONTEXT.md`, but:
- Contract 2 specifies the path as `plans/{slug}/CONTEXT.md`
- MODULES.md Module 3 states output path `plans/{slug}/CONTEXT.md`
- The adopt.md command (Step 1) creates `./plans/{feature-slug}/` and sets `FEATURE_SLUG` for all subsequent steps
- Step 6 Finalize (adopt.md) prints "Adoption finalized. CONTEXT.md saved to `plans/{feature-slug}/CONTEXT.md`" — confirming the expected path

The scaffolder writes to the wrong directory (`plans/CONTEXT.md` instead of `plans/{feature-slug}/CONTEXT.md`). In a real adoption run, CONTEXT.md would be placed at the root of `plans/` rather than inside the feature slug directory. This breaks downstream phase discovery since all `/qf:*` commands look for CONTEXT.md at `plans/{slug}/CONTEXT.md`.

**Impact:** All downstream phases that read `plans/{slug}/CONTEXT.md` would fail to find it. High severity.

**Fix required:** In `agents/adopt-scaffolder.md`, change all references from `plans/CONTEXT.md` to `plans/{feature-slug}/CONTEXT.md` (and `plans/CONTEXT.draft.md` to `plans/{feature-slug}/CONTEXT.draft.md`). The scaffolder receives `feature-slug` from the orchestrator via CK Context.

---

## Cross-Dev Integration Assessment

### Data Flow: PASS
- `adopt.md` correctly passes `PreScanAnswers` to both agents in their spawning prompts
- Scanner findings are passed to scaffolder after fan-in (Step 4 in adopt.md)
- The `draft` merge object in Step 4 correctly aggregates `context_md_path`, `gaps`, `partial_adoption`, `scanner_failed`, `assumptions`
- Error flag (`errorFlag: true`) correctly propagates to scaffolder on scanner failure

### Agent References: PASS
- `adopt.md` Step 3 correctly reads `agents/adopt-scanner.md` and `agents/adopt-scaffolder.md` before spawning
- Agent types match design: scanner=`planner`, scaffolder=`fullstack-developer`

### Module Boundaries: PASS (with note)
- Scanner: read-only confirmed — rules explicitly state "MUST NOT write, create, or modify any files"
- Scaffolder: additive-only confirmed — rules state "NEVER overwrite or delete"
- Orchestrator (adopt.md): does not scan directly, delegates file creation to scaffolder

---

## Contract Compliance Assessment

| Contract | Compliance | Notes |
|----------|-----------|-------|
| Contract 1: ScannerFindings schema | PASS | Schema matches. `error` field presence is correctly documented. Annotation format inconsistency (Minor #5). |
| Contract 2: CONTEXT.md schema | PARTIAL | Path bug (GAP-001). Version mismatch (Minor #1). Missing `created` field (Minor #2). |
| Contract 3: Pre-scan 5 questions | PASS | All 5 questions (Q1-Q5) present in Step 2 with correct types and PreScanAnswers mapping. |
| Contract 4: DraftArtifacts schema | PASS | Scaffolder output matches schema exactly including `partial_adoption_details` sub-object. |
| Contract 5: Approval Gate | PASS | State machine (AWAITING_REVIEW → APPROVED/REJECTED_WITH_FEEDBACK) present, case-insensitive APPROVE, no retry limit. Targeted re-run table present. |
| Contract 6: Post-Adopt Metadata | PASS | Locked Decisions block format matches. Written on finalize only. |
| Contract 7: Error Signal | PASS | Scanner error format documented in scanner output rules. Orchestrator error handling table in adopt.md covers all cases. |

---

## Format Consistency Assessment

### Agent files vs existing agents (domain-engineer.md, dev-teammate.md): PASS
Both agent files follow the established format:
- `## Role` with agent type, timing, and output
- `## Inputs You Receive`
- Protocol sections with ordered steps
- `## Output` with schema
- `## Rules`
- `## Completion` reference to `_shared.md`

### Command file vs existing commands (0-init.md, cook.md): PASS
- Sequential numbered steps
- Sub-sections for each component
- Error handling table
- Output Rule reference

### Skill file frontmatter: PASS
Both `skills/qf/adopt/SKILL.md` and plugin mirror have proper frontmatter with `name` and `description`.

---

## Plugin Mirror Verification: PASS

| Source | Mirror | Status |
|--------|--------|--------|
| `agents/adopt-scanner.md` | `plugins/quangflow/agents/adopt-scanner.md` | Exact copy |
| `agents/adopt-scaffolder.md` | `plugins/quangflow/agents/adopt-scaffolder.md` | Exact copy |
| `skills/qf/adopt/SKILL.md` | `plugins/quangflow/skills/qf/adopt/SKILL.md` | Exact copy |

Note: DECISIONS.md Decision #1 flags that CLAUDE.md and README.md updates were deferred to the lead. Both files have been updated with `/qf:adopt` entries — confirmed.

---

## Recommendations for Lead

1. **Fix GAP-001 (high priority):** Update `agents/adopt-scaffolder.md` to write CONTEXT.md to `plans/{feature-slug}/CONTEXT.md`. The feature slug is available from the orchestrator CK Context. Also update the plugin mirror after fixing.

2. **Fix Minor #1 (version):** Change `quangflow_version: "1.1.0"` to `"2.0.0"` in adopt-scaffolder.md CONTEXT.md template. Update plugin mirror.

3. **Fix Minor #2 (missing created field):** Add `created: {ISO-8601 timestamp}` field to the CONTEXT.md metadata template in adopt-scaffolder.md.

4. **Fix Minor #3 (hardcoded contracts path):** Remove the `plans/adopt-existing-project/milestone-1/design/CONTRACTS.md` reference from the scanner spawn prompt in adopt.md (and SKILL.md). The protocol is already embedded in the agent file.

5. **Minor #5 (assumption annotations):** Standardize annotation to `# ⚠️ ASSUMPTION:` in adopt-scanner.md to match CONTRACTS.md convention.

6. **Minor #6 (partial adoption details):** Clarify the `CONTEXT.draft.md` case: existing file → `preserved`, new draft file → `merged`. Current wording sends both to `merged`.

Items 1-3 are the most impactful for runtime correctness. Items 4-6 are clarity/convention fixes.

---

## Fixes Applied by Tech Lead

All high-priority issues resolved inline (2026-03-28):

| Issue | Fix Applied |
|-------|-------------|
| GAP-001: wrong CONTEXT.md path | Fixed in `agents/adopt-scaffolder.md` + plugin mirror |
| Minor #1: version mismatch `"1.1.0"` | Fixed → `"2.0.0"` in scaffolder + plugin mirror |
| Minor #2: missing `created` field | Added to CONTEXT.md template in scaffolder + plugin mirror |
| Minor #3: hardcoded contracts path in spawn prompt | Fixed in `commands/qf/adopt.md` + both SKILL.md files |
| Minor #5: assumption annotation format | Fixed `# ASSUMPTION:` → `# ⚠️ ASSUMPTION:` in scanner + plugin mirror |
| Minor #6: ambiguous partial adoption details | Clarified in scaffolder + plugin mirror |

Minor #4 (OPEN_QUESTIONS.md creation in finalize) accepted as low-risk deviation — not reverted.

---

## Verdict

All issues resolved. Implementation is architecturally sound and contract-compliant. Ready for tester (Stage 4).
