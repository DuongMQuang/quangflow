# CHECKPOINT — dev-upgrades

**Role:** dev-upgrades
**Last updated:** 2026-03-29
**Status:** COMPLETE

---

## Phases Owned
- Phase 3: Scanner adaptive sizing upgrade (REQ-008) ✅
- Phase 4: Scaffolder enhancements — .memory/ + doc integration (REQ-006, REQ-010) ✅

---

## Files Modified

### Phase 3 — adopt-scanner.md
- `agents/adopt-scanner.md` — updated
- `plugins/quangflow/agents/adopt-scanner.md` — mirrored (byte-for-byte identical)

**What was added:**
- New **Step 0: Adaptive Sizing** inserted BEFORE all existing scan steps
  - Recursive file count (excluding node_modules, .git, dist, build, __pycache__, venv, .venv)
  - Tier determination table: small (<50), medium (50–500), large (500+)
  - User-facing tier + budget report emitted BEFORE scanning begins
  - Sampling strategy section (priority ordering for medium/large tiers)
- **Post-Scan Transparency Report** section added after Step 8
- **Output schema** upgraded from `ScannerFindings` to `ScannerPhaseResult` (two top-level keys):
  - `scanner_findings` — all M1 fields, unchanged
  - `file_map` — new M2 FileMap (Contract 8/9): total_files, tier, files_read, files_sampled, files_skipped, scan_coverage
- Role/output line updated: "ScannerPhaseResult YAML" instead of "ScannerFindings YAML"
- Rules section updated: 30-file M1 guideline superseded by tier system; added file tracking rules
- Completion section updated to reference ScannerPhaseResult

**What was preserved (M1 regression-safe):**
- All 8 existing scan steps (1–8) — unchanged
- All M1 ScannerFindings schema fields — unchanged, nested under `scanner_findings`
- All M1 rules (read-only, no assumptions, PreScanAnswers as hints, skip on failure)
- Error block schema — unchanged

### Phase 4 — adopt-scaffolder.md
- `agents/adopt-scaffolder.md` — updated
- `plugins/quangflow/agents/adopt-scaffolder.md` — mirrored (byte-for-byte identical)

**What was added:**
- **Inputs** section restructured: UnifiedProjectModel as primary M2 input, raw ScannerFindings as M1 fallback
  - Detection logic via top-level key check (scanner_findings vs tech_stack)
- **Doc Integration into CONTEXT.md** new section:
  - Component diagram embedded in `## Project Structure`
  - Dependency graph embedded in `## Dependencies`
  - Module map added as `## Module Map`
  - Handles `doc_generator_failed` edge case
- **.memory/ Population** new section:
  - `_index.md` master registry with feature listing + confidence badges
  - Per-feature directories: CONTEXT.md, REQUIREMENTS.md, DESIGN.md, GOTCHAS.md, HISTORY.md, LINKS.md
  - All files marked DRAFT with generator comment
  - Existing `.memory/` handling (additive-only, skip existing)
  - `feature_extractor_failed` edge case handling
- **Confidence Badges** section:
  - Weighted formula: scanner(0.4) + extractor(0.3) + doc-gen(0.3)
  - Score-to-label mapping: ≥0.67=high, ≥0.34=medium, <0.34=low
  - Applied to CONTEXT.md overall + per-feature memory files
- **DraftArtifacts output** extended with M2 fields (Contract 13):
  - `features_populated`, `docs_integrated`, `overall_confidence`, `feature_extractor_failed`, `doc_generator_failed`
- Role output line updated to mention .memory/ units

**What was preserved (M1 regression-safe):**
- Partial adoption detection logic — unchanged
- Directory creation list — unchanged
- CONTEXT.md generation schema — unchanged (sections extended, not replaced)
- scanner_failed handling — unchanged
- CONTEXT.draft.md logic for existing CONTEXT.md — unchanged
- All M1 DraftArtifacts fields — unchanged
- All M1 rules — unchanged

---

## Assumptions Made

1. `scanner_findings.project_structure.total_files` (M1 field) is now populated from Step 0's recursive count — more accurate than "estimated from directory listing". Both fields reflect the same value for consistency.
2. "Source files" for sampling = any file under detected source directories that is not a manifest, config, or entry point.
3. UnifiedProjectModel detection uses top-level key check: `scanner_findings` key = M2 model, `tech_stack` key = M1 raw ScannerFindings.
4. `.memory/_index.md` is not overwritten if it already exists (additive-only rule extends to memory index).

---

## Deviations from Plan

None. All ROADMAP task checkboxes for Phase 3 and Phase 4 are satisfied.

---

## Cross-Boundary Notes

- Orchestrator (dev-orchestrator, Phase 5) must pass `UnifiedProjectModel` to scaffolder. When synthesis is skipped, orchestrator must pass raw `ScannerFindings` for M1 fallback compat.
- Feature extractor (dev-new-agents, Phase 1) must return `FeatureUnits` matching the schema consumed by scaffolder's `.memory/` population step.
- Doc generator (dev-new-agents, Phase 2) must return `doc_artifacts` with `component_diagram`, `dependency_graph`, `module_map`, and `confidence` fields matching what scaffolder embeds.
