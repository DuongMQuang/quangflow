# CONTRACTS — /qf:adopt Milestone 2

Developers MUST implement exactly these schemas. M1 contracts 1–7 are unchanged. M2 adds contracts 8–12 and extends contracts 4 and 5.

---

## M1 Contracts (unchanged — reference only)

| Contract | Schema name | Status |
|----------|-------------|--------|
| Contract 1 | ScannerFindings | Unchanged — see M1 CONTRACTS.md |
| Contract 2 | CONTEXT.md Output Schema | Unchanged — see M1 CONTRACTS.md |
| Contract 3 | PreScanAnswers | Unchanged — see M1 CONTRACTS.md |
| Contract 4 | DraftArtifacts | **Extended in M2** — see Contract 9 below |
| Contract 5 | Approval Gate | **Extended in M2** — see Contract 10 below |
| Contract 6 | Post-Adopt Metadata | Unchanged — see M1 CONTRACTS.md |
| Contract 7 | Error Signal (scanner) | Unchanged — see M1 CONTRACTS.md |

---

## Contract 8: FileMap Schema

**Producer:** `adopt-scanner`
**Consumer:** `adopt.md` (orchestrator), then forwarded to `adopt-feature-extractor` + `adopt-doc-generator`
**Format:** YAML block in agent response (additive alongside ScannerFindings)

```yaml
# FileMap — new output from scanner (M2)
file_map:
  total_files: 0           # integer — total project files detected (recursive, excludes ignored dirs)
  tier: ""                 # "small" | "medium" | "large"
  files_read: []           # string[] — relative paths of files actually read
  files_sampled: []        # string[] — relative paths sampled in medium/large tier (subset of files_read)
  files_skipped: []        # string[] — relative paths NOT read, with inline reason comment
  scan_coverage: ""        # string — percentage estimate, e.g. "100%", "35%", "12%"
```

**Notes:**
- `files_skipped` entries should include inline comment for reason, e.g. `"src/legacy/util.ts  # large-tier budget"`
- `files_read` includes BOTH the always-read set AND the sampled set
- For small tier: `files_sampled` is empty (all files are in `files_read`)
- `scan_coverage` is approximate: `(files_read.length / total_files) * 100`
- FileMap is a NEW key in ScannerPhaseResult — it does not replace or modify ScannerFindings

> ⚠️ ASSUMPTION: File count excludes `node_modules`, `.git`, `dist`, `build`, `__pycache__`, `venv`, `.venv`. Additional ignore patterns (e.g., `.next`, `coverage`) may need to be added based on common frameworks.

---

## Contract 9: ScannerPhaseResult Schema (M2 wrapper)

**Producer:** `adopt-scanner`
**Consumer:** `adopt.md` (orchestrator)
**Format:** Combines M1 ScannerFindings + new FileMap

```yaml
# ScannerPhaseResult — orchestrator receives both findings and file map
scanner_findings:          # ScannerFindings (M1 Contract 1 — unchanged)
  tech_stack: {}
  project_structure: {}
  conventions: {}
  gaps: []
  # error: {} — present only if scanner errored

file_map:                  # FileMap (M2 Contract 8 — new)
  total_files: 0
  tier: ""
  files_read: []
  files_sampled: []
  files_skipped: []
  scan_coverage: ""
```

**Notes:**
- Orchestrator MUST unpack both keys and pass each independently to Phase 2 agents
- If scanner failed: `scanner_findings.error.occurred = true` and `file_map` may be empty or partial

---

## Contract 10: FeatureUnits Schema

**Producer:** `adopt-feature-extractor`
**Consumer:** `adopt.md` (orchestrator → inline synthesis → adopt-scaffolder)
**Format:** YAML block in agent response (no file write)

```yaml
# FeatureUnits — feature extractor output
features:
  - name: ""              # string — feature name, kebab-case (e.g. "auth-service")
    description: ""       # string — what this feature does (1–2 sentences)
    status: ""            # "inferred" | "confirmed"
                          # confirmed = clear signal (dedicated directory + consistent naming)
                          # inferred = heuristic guess (import cluster, ambiguous grouping)
    confidence: ""        # "high" | "medium" | "low"
    files: []             # string[] — relative paths implementing this feature
    dependencies: []      # string[] — OTHER feature names this feature depends on
    notes: ""             # string — caveats, assumptions, or supplemental read notes

# Confidence scoring rules:
# - Dedicated directory + clear naming (e.g. src/auth/) → status: confirmed, confidence: high
# - Import cluster with consistent naming → status: inferred, confidence: medium
# - Single file or ambiguous grouping → status: inferred, confidence: low
# - Scanner failed (answers-only mode) → status: inferred, confidence: low (all features)
# - Budget cap hit → confidence degraded by one level (high→medium, medium→low)
```

**Edge case — no features detected:**
```yaml
features:
  - name: "monolith"
    description: "Single-module project with no detectable feature boundaries."
    status: "inferred"
    confidence: "low"
    files: ["src/"]
    dependencies: []
    notes: "No clear feature boundaries detected. Recommend manual decomposition after adoption."
```

**Supplemental read constraint:**
- Agent MAY read up to 20 additional files beyond `file_map.files_read`
- Agent MUST include in `notes` field: how many supplemental files were read

> ⚠️ ASSUMPTION: Feature detection is heuristic-based on directory structure and import graphs. For projects with unconventional structures (e.g., flat single-directory projects), confidence will be low regardless of project complexity.

---

## Contract 11: DocArtifacts Schema

**Producer:** `adopt-doc-generator`
**Consumer:** `adopt.md` (orchestrator → inline synthesis → adopt-scaffolder)
**Format:** YAML block in agent response (no file write)

```yaml
# DocArtifacts — doc generator output
component_diagram: ""     # string — Mermaid source (graph LR), one node per key module
                          # includes subgraph layers (frontend, backend, storage, external)
dependency_graph: ""      # string — Mermaid source (graph TD), package + module deps
module_map:               # list of module responsibility descriptions
  - name: ""              # string — module name (kebab-case, consistent with feature extractor)
    path: ""              # string — relative path to module root
    responsibility: ""    # string — single-sentence description of module's role
    public_interfaces: [] # string[] — key exports, APIs, or entry functions
readme_sections: []       # string[] — each element is a markdown block to append
                          # each block MUST start with: <!-- Generated by /qf:adopt -->
confidence: ""            # "high" | "medium" | "low" — overall doc artifact confidence

# Confidence scoring rules:
# - Diagram derived from manifest file (package.json, go.mod) → high
# - Diagram derived from config file (tsconfig.json, docker-compose.yml) → high
# - Diagram derived from import tracing → medium
# - Diagram derived from directory heuristics only → low
# - Scanner failed (skeleton only) → low (all)
```

**Component diagram format:**
```
graph LR
  subgraph frontend["Frontend"]
    FE["..."]
  end
  subgraph backend["Backend"]
    BE["..."]
  end
  FE -->|"HTTP"| BE
```

**README section format:**
```markdown
<!-- Generated by /qf:adopt -->
<!-- STATUS: DRAFT — review and edit before committing -->
## Architecture Overview
...section content...
```

**Supplemental read constraint:**
- Agent MAY read up to 15 additional files beyond `file_map.files_read`

> ⚠️ ASSUMPTION: Mermaid diagram strings are stored as multi-line strings in YAML. Orchestrator passes them to scaffolder as-is without parsing. Mermaid rendering is handled by the review gate display, not by any agent.

---

## Contract 12: UnifiedProjectModel Schema

**Producer:** Inline synthesis (in `adopt.md` orchestrator)
**Consumer:** `adopt-scaffolder`
**Format:** Structured object passed in scaffolder prompt context (not written to file)

```yaml
# UnifiedProjectModel — synthesis output
unified_model:
  scanner_findings: {}    # ScannerFindings — original (unchanged from scanner output)
  file_map: {}            # FileMap — from scanner (unchanged)
  features: []            # Feature[] — reconciled from feature extractor
                          # (names normalized, conflicts flagged)
  doc_artifacts: {}       # DocArtifacts — from doc generator (unchanged)
  conflicts: []           # Conflict[] — unresolved conflicts for user at review gate
  synthesis_notes: []     # string[] — what was reconciled and how

# Conflict entry schema:
conflicts:
  - type: ""              # "naming" | "feature_existence" | "module_count" | "dependency"
    subject: ""           # string — what the conflict is about (e.g., "analytics feature")
    views:                # the two differing views
      extractor: ""       # string — feature extractor's view
      doc_generator: ""   # string — doc generator's view
    resolution: ""        # "flagged_low_confidence" | "normalized_to_extractor" | "user_review_required"

# Fallback when Phase 2 agents fail:
# - feature extractor failed → features: [] (empty, not null)
# - doc generator failed → doc_artifacts: null
# - both failed → falls back to M1 behavior (no .memory/, no diagrams)
```

**Synthesis rules (inline in orchestrator):**

| Rule | Condition | Action |
|------|-----------|--------|
| Module count | `abs(features.length - key_dirs.length) > max(features.length, dirs.length) / 2` | Flag in synthesis_notes; do NOT auto-reconcile |
| Naming | Feature extractor and doc generator use different names for same module | Normalize to feature extractor name; record in synthesis_notes |
| Dependencies | Scanner has tech deps + extractor has feature-level deps | Merge both lists into unified_model.features[].dependencies |
| Conflict resolution | Any 2-way disagreement | Flag as `confidence: low`; add to conflicts[]; present at review gate |
| Synthesis notes | Every reconciliation action | Record in synthesis_notes[] for user transparency |

> ⚠️ ASSUMPTION: Synthesis runs in the orchestrator without spawning an agent. This means synthesis logic is part of the command definition (adopt.md / SKILL.md), not a separate markdown agent file. If synthesis complexity grows in future milestones, it should be extracted to a separate agent.

---

## Contract 13: Extended DraftArtifacts Schema (M2 extension of M1 Contract 4)

**Producer:** `adopt-scaffolder`
**Consumer:** `adopt.md` (review gate + finalize)
**Format:** Structured summary in agent response

```yaml
# DraftArtifacts — M2 extended (all M1 fields preserved)

# M1 fields (unchanged):
context_md_path: ""         # string — e.g. "plans/my-project/CONTEXT.md"
dirs_created: []            # string[] — dirs actually created
dirs_skipped: []            # string[] — dirs already existed
partial_adoption: false     # boolean
partial_adoption_details:   # present only if partial_adoption: true
  merged: []
  preserved: []
  updated: []
scanner_failed: false       # boolean
assumptions: []             # string[]

# M2 additions:
features_populated: []      # string[] — feature names written to .memory/
                            # empty if feature extractor failed
docs_integrated: false      # boolean — whether Mermaid diagrams embedded in CONTEXT.md
                            # false if doc generator failed
overall_confidence: ""      # "high" | "medium" | "low" — weighted average across all artifacts
                            # weighted: scanner(0.4) + extractor(0.3) + doc-gen(0.3)
feature_extractor_failed: false  # boolean — true if .memory/ was skipped due to agent failure
doc_generator_failed: false      # boolean — true if diagrams were skipped due to agent failure
```

**Confidence weighting:**
- `overall_confidence = high` if weighted average ≥ 0.67 (most signals from manifests/configs)
- `overall_confidence = medium` if weighted average ≥ 0.34
- `overall_confidence = low` if weighted average < 0.34

---

## Contract 14: Extended Approval Gate (M2 extension of M1 Contract 5)

**Producer:** User input
**Consumer:** `adopt.md` (orchestrator)
**Format:** Text input parsed by orchestrator

### Extended Approval Flow

```
State: AWAITING_REVIEW (M2)
  Orchestrator presents (in order):
    1. Confidence-grouped findings:
       ### High Confidence (auto-detected from clear signals)
       ### Medium Confidence (pattern-based inference)
       ### Low Confidence (heuristic guess — review carefully)
    2. Feature memory units preview:
       ### Feature Memory Units
       - .memory/auth-service/ [confidence: high]
       - .memory/payments/ [confidence: high]
    3. Architecture diagrams inline:
       ### Architecture Diagrams
       [component_diagram rendered]
       [dependency_graph rendered]
    4. Synthesis conflicts (if any):
       ### Synthesis Conflicts
       ⚠️ [conflict descriptions with both views]
    5. Scanner gap findings (M1 unchanged)
    6. Partial adoption report (if applicable, M1 unchanged)
    7. Prompt: "Type APPROVE to finalize, or describe what to change."
```

### Extended Re-run Routing Table

| Feedback about... | Re-run target | Cascade |
|-------------------|---------------|---------|
| Tech stack, structure, scanning depth | adopt-scanner | → then re-run BOTH Phase 2 agents → synthesis → scaffolder |
| Feature detection, memory units, feature names | adopt-feature-extractor only | → re-synthesis → scaffolder |
| Diagrams, module map, README sections | adopt-doc-generator only | → re-synthesis → scaffolder |
| CONTEXT.md formatting or structure | adopt-scaffolder only | — |
| Everything / major rethink | all agents | Full re-run (scanner → Phase 2 → synthesis → scaffolder) |

> ⚠️ ASSUMPTION: Targeted re-runs preserve the previous agent output from the un-targeted agents. For example, re-running doc-generator reuses the existing FeatureUnits from the previous feature extractor run — it does NOT re-run the feature extractor.

---

## Contract 15: Feature Memory Unit Schema

**Producer:** `adopt-scaffolder`
**Consumer:** All downstream `/qf:*` commands (via `@feature-name` mention)
**Format:** Markdown files written to `.memory/{feature-name}/`

### `.memory/_index.md`

```markdown
# Memory Index — {project-slug}

<!-- Generated by /qf:adopt — STATUS: DRAFT -->

{for each feature:}
- [{feature.name}]({feature.name}/CONTEXT.md) — {feature.description} [confidence: {feature.confidence}]
```

### `.memory/{feature-name}/CONTEXT.md`

```markdown
# {feature.name}

<!-- Generated by /qf:adopt — STATUS: DRAFT -->
<!-- confidence: {feature.confidence} | status: {feature.status} -->

## What this feature does
{feature.description}

## Source files
{for each file in feature.files: - `{file}`}

## Dependencies
{for each dep in feature.dependencies: - {dep}}

## Notes
{feature.notes or "None"}
```

### Other `.memory/{feature-name}/` files

| File | Initial content |
|------|----------------|
| `REQUIREMENTS.md` | `# Requirements — {feature.name}\n\n<!-- Populate during /qf:1-brainstorm -->` |
| `DESIGN.md` | `# Design — {feature.name}\n\n<!-- Populate during /qf:2-design -->` |
| `GOTCHAS.md` | `# Gotchas — {feature.name}\n\n<!-- Add lessons learned here -->` |
| `HISTORY.md` | `# History — {feature.name}\n\n<!-- Key decisions timeline -->` |
| `LINKS.md` | `# Links — {feature.name}\n\n{for each dep: - Related: [{dep}](../{dep}/CONTEXT.md)}` |

**Rules:**
- All files written with DRAFT status marker
- DRAFT marker removed on finalize (same as CONTEXT.md)
- If `.memory/{feature-name}/` already exists: extend (additive), never overwrite existing content

> ⚠️ ASSUMPTION: Feature names from FeatureUnits are used as directory names. Names must be valid filesystem path segments (kebab-case enforced). Feature extractor MUST output kebab-case names. Scaffolder should sanitize (replace spaces, slashes) as a safety measure.
