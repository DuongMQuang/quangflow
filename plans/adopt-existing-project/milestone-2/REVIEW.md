# Tech Lead Review — Milestone 2

## Summary

- Files reviewed: 10 (source files) + 5 plugin mirrors = 15 total
- Minor issues found: 7
- Major gaps found: 2
- Overall verdict: **PARTIAL — ship with minor fixes, escalate 2 major gaps**

---

## Files Reviewed

| File | Owner | Status |
|------|-------|--------|
| `agents/adopt-feature-extractor.md` | dev-new-agents | Reviewed |
| `plugins/quangflow/agents/adopt-feature-extractor.md` | dev-new-agents | Reviewed (mirror) |
| `agents/adopt-doc-generator.md` | dev-new-agents | Reviewed |
| `plugins/quangflow/agents/adopt-doc-generator.md` | dev-new-agents | Reviewed (mirror) |
| `agents/adopt-scanner.md` | dev-upgrades | Reviewed |
| `plugins/quangflow/agents/adopt-scanner.md` | dev-upgrades | Reviewed (mirror) |
| `agents/adopt-scaffolder.md` | dev-upgrades | Reviewed |
| `plugins/quangflow/agents/adopt-scaffolder.md` | dev-upgrades | Reviewed (mirror) |
| `commands/qf/adopt.md` | dev-orchestrator | Reviewed |
| `skills/qf/adopt/SKILL.md` | dev-orchestrator | Reviewed |
| `plugins/quangflow/skills/qf/adopt/SKILL.md` | dev-orchestrator | Reviewed (mirror) |

---

## Minor Issues

| # | File | Issue | Severity | Dev |
|---|------|-------|----------|-----|
| 1 | `agents/adopt-scaffolder.md` | UnifiedProjectModel field named `feature_units` (line 16) but Contract 12 specifies `features`. Scaffolder also references `feature_units` in its `.memory/` population section (lines 193, 201, 207, 308) and DraftArtifacts output comment (line 333). This naming mismatch means the scaffolder will not find the `features` array the orchestrator sets after synthesis. | Minor | dev-upgrades |
| 2 | `agents/adopt-scaffolder.md` | UnifiedProjectModel input schema uses `synthesis_conflicts` (line 18) but Contract 12 specifies the field as `conflicts`. Cascades into all downstream references within scaffolder. | Minor | dev-upgrades |
| 3 | `agents/adopt-doc-generator.md` | Confidence scoring rule states: "Overall confidence is the confidence of the weakest signal that was relied upon." Contract 11 specifies: "Overall doc artifact confidence" based on the primary signal used for the component diagram structure — not a weakest-signal rule. The dev implemented a stricter rule than the contract requires. In practice this will lower confidence scores more than intended (e.g., if directory signal is used for edges but manifest was used for structure, overall confidence becomes `low` instead of `high`). | Minor | dev-new-agents |
| 4 | `agents/adopt-feature-extractor.md` | Scanner-failed edge case output (Sequence 3B) in the design shows `name: "unknown-feature"`, but the contract's no-features-detected fallback is `name: "monolith"`. The agent definition uses `"monolith"` (correct) but does not mention `"unknown-feature"` — this is consistent. However, the notes field template in the scanner-failed branch says "Feature detection skipped. Populate manually." but the contract says notes should use the same format as a detected feature. This is cosmetically inconsistent but functionally acceptable. Low priority. | Minor | dev-new-agents |
| 5 | `commands/qf/adopt.md` | Step 3 labels itself "Phase 1" and Step 4 labels itself "Phase 2", but the DESIGN.md and MODULES.md describe a 4-phase pipeline (Scanner → Parallel Analysts → Synthesis → Scaffolder as Phase 1–4). The step numbering (Steps 3–9) is internal and acceptable, but the DESIGN.md flow labels ("Phase 1", "Phase 2", "Phase 3", "Phase 4") are not mirrored. This is a documentation inconsistency that could confuse future maintainers. | Minor | dev-orchestrator |
| 6 | `agents/adopt-scanner.md` | Output schema (line 176) uses `findings_so_far: {}` in the error block. M1 Contract 7 specifies `findings_so_far` as having explicit sub-keys `tech_stack`, `project_structure`, `conventions`, `gaps`. The scanner uses `{}` (bare object), which is weaker than the contract. Not a breaking issue but reduces schema fidelity. | Minor | dev-upgrades |
| 7 | `commands/qf/adopt.md` | Review gate Step 7 displays synthesis conflicts using `conflict.views.extractor` and `conflict.views.doc_generator` (lines 380–384). Contract 14 specifies these labels as `Extractor:` and `Doc generator:` with a capital D — matching exactly. The implementation matches. However the "Synthesis Notes" section shown in SEQUENCES.md Sequence 1 (gate output includes synthesis_notes) is **not present** in the review gate Step 7 display. The orchestrator shows conflicts but does not display `synthesis_notes[]` to the user. Contract 14 only requires conflicts display — but DESIGN.md approval flow item 6 says "Present synthesis conflicts" and SEQUENCES.md shows synthesis notes displayed at gate. Minor omission — synthesis_notes are in UnifiedProjectModel but not surfaced at review. | Minor | dev-orchestrator |

---

## Major Gaps

See GAPS.md for details.

### GAP-001: UnifiedProjectModel field name mismatch (`feature_units` vs `features`) breaks scaffolder .memory/ population

**Severity:** Major (broken cross-dev integration)

The orchestrator (`adopt.md`) constructs `unified_model.features[]` during synthesis (Step 5, line 219). The scaffolder (`adopt-scaffolder.md`) expects the same model but references the key as `feature_units` (line 16 of its input schema). This means when the scaffolder receives the `UnifiedProjectModel`, it will find `features` (set) but look for `feature_units` (absent) — triggering the `feature_extractor_failed` branch incorrectly and skipping all `.memory/` population. The `.memory/` feature for REQ-006 will silently fail on every normal run.

### GAP-002: `synthesis_conflicts` vs `conflicts` field name in UnifiedProjectModel breaks scaffolder conflict handling

**Severity:** Major (broken cross-dev integration)

The orchestrator constructs `unified_model.conflicts[]` (adopt.md Step 5, line initialization). Contract 12 also specifies the key as `conflicts`. The scaffolder input schema declares this field as `synthesis_conflicts` (line 18). Since the scaffolder references synthesis conflicts in its logic, this will cause conflict data to be lost at the scaffolder boundary — no conflict-aware behavior will trigger correctly.

---

## Contract Compliance

| Contract | Description | Producer | Status | Notes |
|----------|-------------|----------|--------|-------|
| Contract 8 | FileMap Schema | adopt-scanner | PASS | All 6 fields present and correctly specified |
| Contract 9 | ScannerPhaseResult | adopt-scanner | PASS | Both `scanner_findings` and `file_map` keys present; error fallback correct |
| Contract 10 | FeatureUnits | adopt-feature-extractor | PASS | All fields match schema; edge cases covered; supplemental read budget enforced |
| Contract 11 | DocArtifacts | adopt-doc-generator | PARTIAL | Schema fields all present. Confidence scoring uses "weakest signal" rule (stricter than contract's "primary diagram signal" rule — see Minor #3) |
| Contract 12 | UnifiedProjectModel | adopt.md (inline synthesis) | PARTIAL | Orchestrator produces `features` (correct). Scaffolder declares input as `feature_units` + `synthesis_conflicts` (wrong field names — see GAP-001, GAP-002) |
| Contract 13 | Extended DraftArtifacts | adopt-scaffolder | PASS | All M1 fields preserved; M2 additions present (`features_populated`, `docs_integrated`, `overall_confidence`, `feature_extractor_failed`, `doc_generator_failed`); confidence weighting formula matches contract |
| Contract 14 | Extended Approval Gate | adopt.md | PASS | Confidence-grouped display, feature memory preview, diagrams inline, conflicts, gap findings all present. Synthesis notes not surfaced (minor gap only) |
| Contract 15 | Feature Memory Unit | adopt-scaffolder | PASS | All 6 memory files specified; `_index.md` format correct; DRAFT markers present; existing `.memory/` handling correct; LINKS.md cross-references correct |

---

## Architecture Compliance

| Dimension | Status | Notes |
|-----------|--------|-------|
| DESIGN.md compliance | PASS | Sequential pipeline (Scanner → Parallel Analysts → Synthesis → Scaffolder) correctly implemented |
| CONTRACTS.md compliance | PARTIAL | 2 field name mismatches break cross-dev integration (GAP-001, GAP-002) |
| Module boundaries | PASS | All 6 modules stay in their lanes; no module reaching into another's internals |
| M1 backward compatibility | PASS | All M1 scanner steps preserved; all M1 scaffolder behaviors preserved; M1 contracts 1–7 remain valid; M1 orchestration logic preserved |
| Plugin mirror consistency | PASS | All 5 plugin mirrors are byte-for-byte identical to their sources |
| Edge case coverage | PASS | All specified edge cases handled: no-features fallback, scanner-failed, budget exceeded, minimal project, Phase 2 failure combinations, graceful degradation |
| Cross-dev integration (flow) | PARTIAL | Orchestrator → feature-extractor → scaffolder data flow broken at field naming boundary (GAP-001, GAP-002). Orchestrator → doc-generator → scaffolder flow is intact |
| Synthesis rules | PASS | All 5 reconciliation rules (module count, naming, dependency merge, conflict, synthesis notes) implemented correctly in orchestrator |

---

## Recommendations

1. **Fix GAP-001 and GAP-002 before shipping.** The field name mismatches are unambiguous and will cause REQ-006 (`.memory/` population) to silently skip on every normal run. These are one-line fixes in `adopt-scaffolder.md` — rename `feature_units` → `features` and `synthesis_conflicts` → `conflicts` in the input schema block and all internal references.

2. **Decide on doc-generator confidence rule (Minor #3).** Either align the doc-generator to the contract's "primary diagram signal" rule, or update the contract to reflect the "weakest signal" interpretation. Both are defensible — but they must agree.

3. **Surface synthesis_notes at the review gate (Minor #7).** The SEQUENCES.md design shows synthesis notes visible to the user. Consider adding a `### Synthesis Notes` section to the Step 7 review gate display, populated from `UnifiedProjectModel.synthesis_notes[]`.

4. **Forward-looking: UnifiedProjectModel field naming convention.** The mismatch between `feature_units` (scaffolder) and `features` (contract/orchestrator) suggests the domain engineer's contract was not fully distributed to all dev agents before implementation. For M3, ensure all devs have a shared field-name reference before coding begins.
