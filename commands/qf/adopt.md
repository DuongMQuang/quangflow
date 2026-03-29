You are now entering the Project Adoption command: `/qf:adopt`.

Onboards an existing codebase into the QuangFlow workflow by scanning the project, scaffolding
the required directory structure, and generating a CONTEXT.md ready for downstream phases.

## Purpose

`/qf:adopt` is the entry point for teams bringing an existing project under QuangFlow governance.
Unlike `/qf:0-init` (which starts fresh), adopt performs a thorough codebase scan and infers
tech stack, conventions, and gaps automatically — then presents a draft for user review before
committing anything permanently.

Differences from `/qf:0-init`:
- Spawns specialized sub-agents (scanner → feature extractor + doc generator → scaffolder) instead of scanning inline
- Produces a reviewed-and-approved CONTEXT.md (draft → finalize flow)
- Writes adoption provenance to `## Locked Decisions`
- Routes to `/qf:1-brainstorm` (new feature) or `/qf:5-maintain` (maintenance) based on stated goal

## Arguments

```
/qf:adopt       — Interactive, no arguments required
```

---

## Step 1: Feature Slug

Derive the feature slug from the project directory name (convert to kebab-case).

- If the directory name is ambiguous or contains spaces, ask:
  "What should this project be called? (used as the plan directory name, e.g. `my-project`)"
- Create directory: `./plans/{feature-slug}/`
- Set `FEATURE_SLUG` for all subsequent steps.

---

## Step 2: Pre-Scan Questions

Ask all 5 questions as a single batch. Use `AskUserQuestion` with structured options where applicable.

Present as:
"Before I scan your project, I need a few quick answers to guide the analysis."

**Q1 — Primary Language** (free text):
"What is the primary programming language of this project?"

**Q2 — Project Structure** (choice):
"What is the project structure type?"
- Options: `monolith`, `monorepo`, `microservices`

**Q3 — Test Suite** (choice):
"Does this project have a test suite?"
- Options: `yes`, `no`, `partial`

**Q4 — Documentation** (choice):
"Does this project have existing documentation?"
- Options: `yes`, `no`, `partial`

**Q5 — Adoption Goal** (choice):
"What is your primary goal after adoption?"
- Options: `new feature`, `maintenance`, `both`

Collect answers into a `PreScanAnswers` object:
```yaml
primary_language: ""        # from Q1
project_type_hint: ""       # "monolith" | "monorepo" | "microservices"
has_tests: ""               # "yes" | "no" | "partial"
has_docs: ""                # "yes" | "no" | "partial"
adoption_goal: ""           # "new_feature" | "maintenance" | "both"
```

---

## Step 3: Phase 1 — Run Scanner First

Scanner MUST complete before Phase 2 agents are spawned. Do NOT run scanner in parallel with other agents.

### 3a: Spawn adopt-scanner

READ `agents/adopt-scanner.md` (if it exists) before spawning.

Spawn via `Task(subagent_type: "planner", name: "adopt-scanner")` with this prompt:

```
You are adopt-scanner. Scan the project at {CWD}.

## PreScanAnswers
{PreScanAnswers YAML block}

## Instructions
Read agents/adopt-scanner.md for your full scanning protocol.
Your output MUST be a ScannerPhaseResult YAML block containing both ScannerFindings and FileMap,
as defined in agents/adopt-scanner.md → Output section.

CK Context:
- Work dir: {CWD}
- Plans: plans/
- Branch: {current git branch}
- Active plan: plans/{feature-slug}/
- Commits: conventional (feat:, fix:, docs:, refactor:, test:, chore:)
- Doc lookup: {doc_lookup}
- Code graph: {code_graph}
```

### 3b: Wait for Scanner Output

Wait for `adopt-scanner` to complete. Capture the `ScannerPhaseResult`:

```yaml
scanner_findings: {}    # ScannerFindings (M1 Contract 1)
file_map: {}            # FileMap (M2 Contract 8)
```

### Scanner Failure Handling

If adopt-scanner errors or times out:
1. Set `scannerFailed: true`
2. Log error message
3. Set `scanner_findings` to empty ScannerFindings with `error.occurred: true`
4. Set `file_map` to empty FileMap
5. Phase 2 agents will run using PreScanAnswers only (all output marked low confidence)
6. Continue — scanner failure is non-blocking

---

## Step 4: Phase 2 — Spawn Feature Extractor and Doc Generator in Parallel

After scanner completes (or fails), spawn both Phase 2 agents simultaneously. Both receive the same
ScannerFindings, FileMap, and PreScanAnswers.

### Agent: adopt-feature-extractor

READ `agents/adopt-feature-extractor.md` (if it exists) before spawning.

Spawn via `Task(subagent_type: "planner", name: "adopt-feature-extractor")` with this prompt:

```
You are adopt-feature-extractor. Analyze the project's features and modules.

## ScannerFindings
{ScannerFindings YAML block}

## FileMap
{FileMap YAML block}

## PreScanAnswers
{PreScanAnswers YAML block}

## Instructions
Read agents/adopt-feature-extractor.md for your full protocol.
Your output MUST be a FeatureUnits YAML block as defined in agents/adopt-feature-extractor.md → Output section.

CK Context:
- Work dir: {CWD}
- Plans: plans/
- Branch: {current git branch}
- Active plan: plans/{feature-slug}/
- Doc lookup: {doc_lookup}
- Code graph: {code_graph}
```

### Agent: adopt-doc-generator

READ `agents/adopt-doc-generator.md` (if it exists) before spawning.

Spawn via `Task(subagent_type: "planner", name: "adopt-doc-generator")` with this prompt:

```
You are adopt-doc-generator. Generate architecture documentation for the project.

## ScannerFindings
{ScannerFindings YAML block}

## FileMap
{FileMap YAML block}

## PreScanAnswers
{PreScanAnswers YAML block}

## Instructions
Read agents/adopt-doc-generator.md for your full protocol.
Your output MUST be a DocArtifacts YAML block as defined in agents/adopt-doc-generator.md → Output section.

CK Context:
- Work dir: {CWD}
- Plans: plans/
- Branch: {current git branch}
- Active plan: plans/{feature-slug}/
- Doc lookup: {doc_lookup}
- Code graph: {code_graph}
```

### Phase 2 Failure Handling

| Agent fails | Behavior |
|-------------|----------|
| adopt-feature-extractor fails | Non-blocking — set `featureExtractorFailed: true`, `features: []`, skip `.memory/` |
| adopt-doc-generator fails | Non-blocking — set `docGeneratorFailed: true`, skip diagrams |
| Both Phase 2 agents fail | Scaffolder falls back to M1 behavior (no `.memory/`, no diagrams) |

---

## Step 5: Synthesis — Inline Reconciliation

Once both Phase 2 agents complete (or fail), run inline synthesis. This is NOT a separate agent —
the orchestrator performs reconciliation using the rules below.

Collect inputs:
- `FeatureUnits` — from feature extractor (or empty if failed)
- `DocArtifacts` — from doc generator (or null if failed)
- `ScannerFindings.project_structure.key_directories` — from scanner

Initialize:
```yaml
unified_model:
  scanner_findings: {}    # original ScannerFindings (unchanged)
  file_map: {}            # original FileMap (unchanged)
  features: []            # will be populated after reconciliation
  doc_artifacts: {}       # DocArtifacts (unchanged, or null)
  conflicts: []           # unresolved conflicts to surface at review gate
  synthesis_notes: []     # log of every reconciliation action taken
```

### Reconciliation Rules (apply in order)

**Rule 1 — Module Count Check:**

Condition: `abs(features.length - key_dirs.length) > max(features.length, key_dirs.length) / 2`

Where `features.length` is the count from FeatureUnits and `key_dirs.length` is the count of
entries in `ScannerFindings.project_structure.key_directories`.

Action: Do NOT auto-reconcile. Add to `synthesis_notes`:
```
"Module count mismatch: feature extractor found {N} features, scanner found {M} key directories.
 Difference exceeds 50% threshold — flagged for user review."
```

**Rule 2 — Naming Normalization:**

Condition: A feature from FeatureUnits and a module from `doc_artifacts.module_map` appear to
refer to the same entity but use different names (case-insensitive comparison, ignoring hyphens/underscores).

Action:
1. Normalize to the feature extractor's name (kebab-case)
2. Update `doc_artifacts.module_map[].name` to match
3. Add a conflict entry:
```yaml
- type: "naming"
  subject: "{the module in question}"
  views:
    extractor: "{feature extractor name}"
    doc_generator: "{doc generator name}"
  resolution: "normalized_to_extractor"
```
4. Add to `synthesis_notes`: `"Naming normalized: '{doc_gen_name}' → '{extractor_name}'"`

**Rule 3 — Dependency Merge:**

Condition: `ScannerFindings.tech_stack` contains technology-level dependencies AND
`FeatureUnits.features[].dependencies` contains feature-level dependencies.

Action: Merge both into `unified_model.features[].dependencies`. Tech-stack entries are prefixed
with `tech:` (e.g., `tech:postgresql`) to distinguish from feature-level entries.
Add to `synthesis_notes`: `"Dependencies merged: tech-stack + feature-level deps unified."`

**Rule 4 — Conflict Resolution:**

Condition: Any 2-way disagreement not covered by Rules 1–3 (e.g., feature existence dispute:
extractor claims a feature exists, doc generator's module_map does not list it, or vice versa).

Action:
1. Flag the affected feature/module as `confidence: low`
2. Add a conflict entry:
```yaml
- type: "feature_existence"   # or "dependency" as appropriate
  subject: "{subject of disagreement}"
  views:
    extractor: "{extractor's view}"
    doc_generator: "{doc generator's view}"
  resolution: "user_review_required"
```
3. Add to `synthesis_notes`: `"Conflict flagged: {subject} — user review required."`

**Rule 5 — Synthesis Notes:**

Every reconciliation action from Rules 1–4 MUST be recorded in `synthesis_notes[]`.
Empty `synthesis_notes` means no reconciliation was necessary.

### Copy Features to UnifiedProjectModel

After reconciliation, copy the (now-reconciled) features from FeatureUnits into
`unified_model.features`. Each feature retains its `confidence` from the feature extractor,
degraded by one level (`high→medium`, `medium→low`) if it was involved in a conflict.

> ⚠️ ASSUMPTION: Synthesis runs without spawning an agent. All reconciliation is inline prose
> logic executed by the orchestrator. If synthesis complexity grows in future milestones, consider
> extracting to a dedicated adopt-synthesizer agent.

---

## Step 6: Phase 3 — Spawn Scaffolder

Pass the `UnifiedProjectModel` to the scaffolder. Do NOT pass raw ScannerFindings directly.

READ `agents/adopt-scaffolder.md` (if it exists) before spawning.

Spawn via `Task(subagent_type: "fullstack-developer", name: "adopt-scaffolder")` with this prompt:

```
You are adopt-scaffolder. Scaffold the QuangFlow directory structure for the adopted project.

## UnifiedProjectModel
{UnifiedProjectModel YAML block}

## PreScanAnswers
{PreScanAnswers YAML block}

## Instructions
Read agents/adopt-scaffolder.md for your full scaffolding protocol.
Use the UnifiedProjectModel (not raw ScannerFindings) as your primary input.
Your output MUST be a DraftArtifacts YAML block as defined in agents/adopt-scaffolder.md → Output section.

CK Context:
- Work dir: {CWD}
- Feature slug: {feature-slug}
- Plans: plans/
- Branch: {current git branch}
- Active plan: plans/{feature-slug}/
- Commits: conventional (feat:, fix:, docs:, refactor:, test:, chore:)
- Doc lookup: {doc_lookup}
- Code graph: {code_graph}
```

Wait for adopt-scaffolder to complete. Capture `DraftArtifacts`.

---

## Step 7: Enhanced Review Gate

State: `AWAITING_REVIEW`

Present to the user in this order:

```
## Adoption Draft — Review Required

### High Confidence
{List all findings derived from clear signals (manifests, config files, dedicated directories).
 Format: "- {finding}" for each item.
 If none: "No high-confidence findings."}

### Medium Confidence
{List all findings derived from pattern-based inference (import clusters, naming heuristics).
 Format: "- {finding} ⚠️ inferred"
 If none: "No medium-confidence findings."}

### Low Confidence
{List all findings derived from heuristic guesses or answers-only mode.
 Format: "- {finding} ⚠️ LOW — review carefully"
 If none: "No low-confidence findings."}

### Feature Memory Units
{For each feature in UnifiedProjectModel.features:
  - .memory/{feature.name}/ [confidence: {feature.confidence}]
 If features is empty (extractor failed): "⚠️ Feature memory skipped — feature extractor failed."}

### Architecture Diagrams
{If doc_artifacts is not null:
  Render component_diagram inline (Mermaid fenced block)
  Render dependency_graph inline (Mermaid fenced block)
 If doc_artifacts is null (doc generator failed):
  "⚠️ Architecture diagrams skipped — doc generator failed."}

### Synthesis Conflicts
{If UnifiedProjectModel.conflicts is non-empty:
  For each conflict:
  ⚠️ [{conflict.type}] {conflict.subject}
     Extractor: {conflict.views.extractor}
     Doc generator: {conflict.views.doc_generator}
     Resolution: {conflict.resolution}
 If empty: "No synthesis conflicts."}

### Gap Findings
{Format ScannerFindings.gaps as a numbered list:
  1. [{type}] {detail}
  ...or "No gaps detected." if empty}

### Partial Adoption Report (if partial_adoption: true)
Merged: {DraftArtifacts.partial_adoption_details.merged}
Preserved: {DraftArtifacts.partial_adoption_details.preserved}
Updated: {DraftArtifacts.partial_adoption_details.updated}

### Scanner Warning (if scanner_failed: true)
⚠️  Scanner failed: {error message}
    CONTEXT.md was generated from your answers only.
    Fields marked ⚠️ ASSUMPTION need manual review before proceeding.

---
Type APPROVE to finalize, or describe what to change.
```

### On APPROVE (case-insensitive)
Transition to `APPROVED` → proceed to Step 8.

### On Any Other Text
Transition to `REJECTED_WITH_FEEDBACK`.

Determine which agent(s) to re-run based on feedback content using the extended routing table:

| Feedback about... | Re-run target | Cascade |
|-------------------|---------------|---------|
| Tech stack, structure, scanning depth | adopt-scanner | → then re-run BOTH Phase 2 agents → synthesis → scaffolder |
| Feature detection, memory units, feature names | adopt-feature-extractor only | → re-synthesis → scaffolder |
| Diagrams, module map, README sections | adopt-doc-generator only | → re-synthesis → scaffolder |
| CONTEXT.md formatting or structure | adopt-scaffolder only | — |
| Everything / major rethink | all agents | Full re-run (scanner → Phase 2 → synthesis → scaffolder) |

> ⚠️ ASSUMPTION: Targeted re-runs preserve the previous agent output from un-targeted agents.
> Example: re-running adopt-doc-generator reuses the existing FeatureUnits from the prior
> feature extractor run — it does NOT re-run the feature extractor.

Re-spawn the relevant agent(s) with original inputs + feedback appended:
```
## User Feedback on Previous Draft
{feedback text}

Please incorporate this feedback and produce an updated output.
```

After re-run completes, re-run synthesis with the updated outputs, then re-run scaffolder if
synthesis produced a changed UnifiedProjectModel. Return to `AWAITING_REVIEW` (re-present the draft).
No retry limit.

---

## Step 8: Finalize

On `APPROVED`:

1. Remove the DRAFT marker from CONTEXT.md:
   Remove: `> **STATUS: DRAFT** — Awaiting user approval via /qf:adopt review gate.`

2. Remove DRAFT markers from all `.memory/` files written during scaffolding:
   In each `.memory/` file, remove the line: `<!-- Generated by /qf:adopt — STATUS: DRAFT -->`
   Replace it with: `<!-- Generated by /qf:adopt — approved {ISO-8601 date} -->`

3. Write adoption metadata to `## Locked Decisions` in CONTEXT.md:

```markdown
## Locked Decisions

- Adopted on {ISO-8601 date} via /qf:adopt
- Tech stack detected: {comma-separated summary: languages + frameworks + databases}
- Project structure: {ScannerFindings.project_structure.pattern, or "not determined"}
- Scan found {N} gap(s): {comma-separated gap types, or "none"}
- Scanner failed: {yes/no}{if yes: " — fields marked ⚠️ ASSUMPTION need manual review"}
- Feature extractor: {ok / failed — .memory/ skipped}
- Doc generator: {ok / failed — diagrams skipped}
- Overall confidence: {DraftArtifacts.overall_confidence}
- Synthesis conflicts: {count, or "none"}
```

4. Create `./plans/{feature-slug}/OPEN_QUESTIONS.md` if it does not exist:
```markdown
# Open Questions — {feature-slug}

(populated during brainstorm and later phases)
```

5. Print: "Adoption finalized. CONTEXT.md saved to `plans/{feature-slug}/CONTEXT.md`."
   If features were written: "Feature memory units saved to `.memory/`."

---

## Step 9: Post-Adopt Router

Present the next-command choice based on `adoption_goal` from PreScanAnswers:

```
## What's next?

{if adoption_goal == "new_feature" or "both"}
Recommended for your goal:

1. /qf:1-brainstorm  — Discover requirements, edge cases, milestones, and team composition
                       ↳ Best if you have a new feature or enhancement to build on this project

2. /qf:5-maintain    — Post-ship systematic debugging, structured log scan, hotfix
                       ↳ Best if you want to fix bugs or maintain existing functionality

{if adoption_goal == "maintenance"}
Recommended for your goal:

1. /qf:5-maintain    — Post-ship systematic debugging, structured log scan, hotfix
                       ↳ Recommended based on your maintenance goal

2. /qf:1-brainstorm  — Discover requirements, edge cases, milestones, and team composition
                       ↳ If you decide to add new features later

Type 1 or 2 to continue, or type the command directly.
```

Pre-select suggestion based on `adoption_goal`:
- `new_feature` → suggest `/qf:1-brainstorm` (option 1)
- `maintenance` → suggest `/qf:5-maintain` (option 1)
- `both` → suggest `/qf:1-brainstorm` (option 1, note both are equally valid)

---

## Error Handling

| Error | Behavior |
|-------|----------|
| Scanner agent fails / times out | Set `scannerFailed: true`, continue with PreScanAnswers-only context; all Phase 2 agents receive empty findings (low confidence) |
| Feature extractor fails | Non-blocking — set `featureExtractorFailed: true`, `features: []`, skip `.memory/` |
| Doc generator fails | Non-blocking — set `docGeneratorFailed: true`, skip diagrams |
| Both Phase 2 agents fail | Scaffolder falls back to M1 behavior (no `.memory/`, no diagrams) |
| Scaffolder agent fails | Report error, abort — scaffolder is blocking (cannot finalize without CONTEXT.md) |
| Partial adoption conflict | Scaffolder presents merge/skip choices to user before proceeding |
| User loops on review gate | Accept indefinitely — no retry limit |
| plans/{slug}/ already exists | Treat as partial adoption — scaffolder handles merge/skip |

---

## Output Rule

See `_protocols/_shared.md → Output Rule`. Save files silently — do NOT print file contents.
Mention file paths only.

---

## Progress Logging

Append an adoption row to `plans/{feature-slug}/PROGRESS.md`:
```
| adopt | {ISO date} | scanner_failed={yes/no}, partial={yes/no}, gaps={N}, goal={adoption_goal}, extractor_failed={yes/no}, doc_gen_failed={yes/no}, conflicts={N}, confidence={overall_confidence} |
```

---

## Next Step

After router choice, tell user:
```
Project adopted. Context at `plans/{feature-slug}/CONTEXT.md`.
Also available: `/qf:status` (check status)
```
