# SEQUENCES — /qf:adopt Milestone 2

All M1 sequences remain valid. M2 adds new sequences for the extended flow.

---

## Sequence 1: M2 Happy Path — Full Flow with Adaptive Scan + Feature Extraction + Docs

```mermaid
sequenceDiagram
    actor User
    participant CMD as adopt.md (Orchestrator)
    participant QA as Pre-scan Questionnaire
    participant SCAN as adopt-scanner (adaptive)
    participant FEAT as adopt-feature-extractor
    participant DOC as adopt-doc-generator
    participant SYNTH as Inline Synthesis
    participant SCAFF as adopt-scaffolder (enhanced)
    participant GATE as Draft Review Gate
    participant ROUTER as Post-Adopt Router

    User->>CMD: /qf:adopt

    CMD->>QA: Run 5 pre-scan questions
    QA-->>CMD: PreScanAnswers

    Note over CMD,SCAN: Phase 1 — Scanner runs FIRST (not parallel in M2)
    CMD->>SCAN: Task(adopt-scanner, root=CWD, answers=PreScanAnswers)
    SCAN->>SCAN: Count files → 320 → tier: medium
    SCAN-->>User: "Project size: 320 files (medium tier). Scanning ~80 files (25% coverage)."
    SCAN->>SCAN: Read manifests, configs, entry points
    SCAN->>SCAN: Sample 20% source files (seeded random)
    SCAN->>SCAN: Detect stack, structure, conventions, gaps
    SCAN->>SCAN: Build FileMap { total: 320, tier: medium, read: [...], sampled: [...], skipped: [...] }
    SCAN-->>CMD: ScannerPhaseResult { findings: ScannerFindings, file_map: FileMap }
    SCAN-->>User: "Scanned 80 of 320 files. Skipped 240 files (listed in FileMap.files_skipped)."

    Note over CMD,DOC: Phase 2 — Feature extractor + Doc generator run IN PARALLEL
    CMD->>FEAT: Task(adopt-feature-extractor, findings=ScannerFindings, fileMap=FileMap, answers=PreScanAnswers)
    CMD->>DOC: Task(adopt-doc-generator, findings=ScannerFindings, fileMap=FileMap, answers=PreScanAnswers)

    FEAT->>FEAT: Detect features by directory (src/auth/, src/payments/, src/dashboard/)
    FEAT->>FEAT: Trace imports from entry points (supplemental: +12 files, budget: 20)
    FEAT->>FEAT: Score: auth=confirmed/high, payments=confirmed/high, dashboard=inferred/medium
    FEAT-->>CMD: FeatureUnits [auth, payments, dashboard]

    DOC->>DOC: Generate component diagram from key_directories
    DOC->>DOC: Generate dependency graph from package.json + imports
    DOC->>DOC: Build module map (3 modules)
    DOC->>DOC: Supplemental reads: +8 files for interface analysis (budget: 15)
    DOC->>DOC: Score: confidence=medium (import tracing)
    DOC-->>CMD: DocArtifacts { component_diagram, dependency_graph, module_map, readme_sections, confidence: medium }

    Note over SYNTH: Phase 3 — Inline synthesis in orchestrator
    CMD->>SYNTH: reconcile(FeatureUnits, DocArtifacts, ScannerFindings)
    SYNTH->>SYNTH: Module count OK: 3 features, 3 key dirs — aligned
    SYNTH->>SYNTH: Naming: feature-extractor says "auth-service", doc-generator says "authentication" → normalize to "auth-service"
    SYNTH->>SYNTH: Dependencies merged: [react, express, pg] + [payments→auth] → UnifiedProjectModel
    SYNTH-->>CMD: UnifiedProjectModel { features: [auth-service, payments, dashboard], conflicts: [], synthesis_notes: [naming normalized] }

    Note over SCAFF: Phase 4 — Enhanced scaffolder
    CMD->>SCAFF: Task(adopt-scaffolder, model=UnifiedProjectModel, answers=PreScanAnswers)
    SCAFF->>SCAFF: Check for existing artifacts (none found)
    SCAFF->>SCAFF: Create plans/ .evidence/ .memory/
    SCAFF->>SCAFF: Generate CONTEXT.md with embedded Mermaid diagrams + confidence badges
    SCAFF->>SCAFF: Create .memory/_index.md (lists auth-service, payments, dashboard)
    SCAFF->>SCAFF: Create .memory/auth-service/ (CONTEXT, REQUIREMENTS, DESIGN, GOTCHAS, HISTORY, LINKS)
    SCAFF->>SCAFF: Create .memory/payments/ (same structure)
    SCAFF->>SCAFF: Create .memory/dashboard/ (same structure)
    SCAFF->>SCAFF: Mark all files DRAFT, add confidence badges
    SCAFF-->>CMD: DraftArtifacts { features_populated: [auth-service, payments, dashboard], docs_integrated: true, overall_confidence: medium }

    CMD->>GATE: Fan-in complete — present confidence-grouped artifacts
    GATE-->>User: "### High Confidence\n- Tech stack: TypeScript, React [confidence: high]"
    GATE-->>User: "### Medium Confidence\n- Feature: dashboard [confidence: medium]"
    GATE-->>User: "### Feature Memory Preview\n- .memory/auth-service/ ..."
    GATE-->>User: "### Architecture Diagrams\n[component diagram inline]"
    GATE-->>User: "### Synthesis Notes\n- Naming normalized: authentication → auth-service"
    User-->>GATE: APPROVE

    GATE-->>CMD: ApprovalDecision { approved: true }
    CMD->>ROUTER: Finalize artifacts
    ROUTER->>ROUTER: Remove DRAFT status from CONTEXT.md + all .memory/ files
    ROUTER->>ROUTER: Write adoption metadata to Locked Decisions
    ROUTER-->>User: "Adoption complete.\n1. /qf:1-brainstorm\n2. /qf:5-maintain"
```

---

## Sequence 2: Adaptive Sizing Decision — Large Project

```mermaid
sequenceDiagram
    actor User
    participant CMD as adopt.md (Orchestrator)
    participant SCAN as adopt-scanner (adaptive)

    CMD->>SCAN: Task(adopt-scanner, root=/large-project, answers=PreScanAnswers)

    SCAN->>SCAN: Recursive file count (exclude node_modules, .git, dist, __pycache__, venv)
    SCAN->>SCAN: Count = 1,843 files → tier: LARGE

    SCAN-->>User: "Project size: 1,843 files (large tier). Scanning up to 100 files for efficiency."
    Note over SCAN,User: Strategy reported BEFORE scanning begins

    SCAN->>SCAN: Always-read set: package.json, go.mod, docker-compose.yml, README.md, tsconfig.json
    SCAN->>SCAN: Always-read set: entry points (index.ts, main.go, server.ts)
    SCAN->>SCAN: Priority-read: files imported by entry points (up to import depth 2)
    SCAN->>SCAN: Priority-read: *.test.ts files (up to 10)
    SCAN->>SCAN: Priority-read: interface / type definition files (*.types.ts, *.d.ts)
    SCAN->>SCAN: Total key files: 68 — remaining budget: 32
    SCAN->>SCAN: Random sample from remaining source files (seeded): 32 files

    SCAN->>SCAN: Detect stack, structure, conventions, gaps from 100 read files
    SCAN->>SCAN: Build FileMap { total: 1843, tier: large, files_read: [100 files], files_skipped: [1743 files with reason: "large-tier budget"] }

    SCAN-->>CMD: ScannerPhaseResult { findings, file_map }
    SCAN-->>User: "Scanned 100 of 1,843 files (5% coverage). 1,743 files skipped (listed in scan report)."
    Note over SCAN,User: Post-scan transparency report — user knows what was missed
```

---

## Sequence 3: Feature Extractor Edge Cases

```mermaid
sequenceDiagram
    participant CMD as adopt.md (Orchestrator)
    participant FEAT as adopt-feature-extractor

    Note over CMD,FEAT: Edge Case A — No clear features detected

    CMD->>FEAT: Task(adopt-feature-extractor, findings=ScannerFindings, fileMap=FileMap, answers=PreScanAnswers)
    FEAT->>FEAT: Scan key_directories: ["src"] — single source dir, no sub-structure
    FEAT->>FEAT: Import tracing: all files import from same shared utils, no feature clusters
    FEAT->>FEAT: Naming patterns: files named generically (index.ts, utils.ts, helpers.ts)
    FEAT->>FEAT: No features detected — applying fallback
    FEAT-->>CMD: FeatureUnits [{ name: "monolith", description: "Single-module project", status: inferred, confidence: low, files: ["src/"], dependencies: [], notes: "No clear feature boundaries detected. Recommend manual decomposition after adoption." }]

    Note over CMD,FEAT: Edge Case B — Scanner failed, answers-only mode

    CMD->>FEAT: Task(adopt-feature-extractor, findings={error: {occurred: true}}, fileMap={}, answers=PreScanAnswers)
    FEAT->>FEAT: Scanner failed — using PreScanAnswers only
    FEAT->>FEAT: primary_language=TypeScript, project_type_hint=monolith
    FEAT->>FEAT: Cannot trace imports without file list — skip directory + import detection
    FEAT->>FEAT: Cannot do supplemental reads without file map — skip
    FEAT-->>CMD: FeatureUnits [{ name: "unknown-feature", status: inferred, confidence: low, notes: "Scanner failed. Feature detection skipped. Populate manually." }]

    Note over CMD,FEAT: Edge Case C — Supplemental read budget exceeded

    CMD->>FEAT: Task(adopt-feature-extractor, findings=ScannerFindings, fileMap=FileMap, answers=PreScanAnswers)
    FEAT->>FEAT: Directory detection finds 12 candidate features
    FEAT->>FEAT: Import tracing on 12 candidates requests 28 supplemental reads
    FEAT->>FEAT: Budget cap: 20 supplemental reads
    FEAT->>FEAT: Prioritize: entry points + most-imported files → read 20 files
    FEAT->>FEAT: Remaining 8 files skipped — features scored conservatively (medium not high)
    FEAT-->>CMD: FeatureUnits [12 features, 4 with confidence degraded to medium due to budget cap]
```

---

## Sequence 4: Synthesis Conflict Resolution

```mermaid
sequenceDiagram
    participant CMD as adopt.md (Orchestrator)
    participant SYNTH as Inline Synthesis
    participant GATE as Draft Review Gate
    actor User

    Note over CMD,SYNTH: Conflict scenario: module count misalignment

    CMD->>SYNTH: reconcile(FeatureUnits[8 features], DocArtifacts[3 modules], ScannerFindings[5 dirs])

    SYNTH->>SYNTH: Rule 1 — Module count check: 8 features vs 5 dirs
    SYNTH->>SYNTH: |8 - 5| = 3 > max(8,5)/2 = 4 → WITHIN THRESHOLD (no conflict)
    Note over SYNTH: Rule 1 passes — misalignment threshold not exceeded

    SYNTH->>SYNTH: Rule 2 — Naming: feature-extractor says "user-management", doc-generator says "users"
    SYNTH->>SYNTH: Normalize to feature-extractor name: "user-management"
    Note over SYNTH: Rule 2: naming reconciled, no conflict flagged

    SYNTH->>SYNTH: Rule 3 — Dependencies: scanner found [react, express, pg], extractor found [user-management→auth, payments→auth]
    SYNTH->>SYNTH: Merge: tech deps + feature deps → unified_dependencies
    Note over SYNTH: Rule 3: merged cleanly

    SYNTH->>SYNTH: Rule 4 — Conflict check: feature-extractor says "analytics" is inferred/low, doc-generator has no "analytics" module
    SYNTH->>SYNTH: 2-way disagreement — flag as conflict: { type: feature_existence, subject: analytics, views: [extractor: present/low, doc-gen: absent] }
    SYNTH->>SYNTH: Add to conflicts list, set feature confidence: low

    SYNTH->>SYNTH: Rule 5 — Synthesis notes: ["naming normalized: users→user-management", "conflict: analytics feature uncertain"]

    SYNTH-->>CMD: UnifiedProjectModel { features: [...], conflicts: [{ analytics conflict }], synthesis_notes: [...] }

    CMD->>GATE: Present with conflicts
    GATE-->>User: "### Synthesis Conflicts (review required)\n⚠️ Feature 'analytics' — uncertain existence:\n  - Feature extractor: present (low confidence)\n  - Doc generator: not detected\nBoth views preserved in draft."
    User-->>GATE: APPROVE
    Note over GATE: Both views of 'analytics' preserved in .memory/ as low-confidence DRAFT
```

---

## Sequence 5: Graceful Degradation — Phase 2 Agent Failures

```mermaid
sequenceDiagram
    actor User
    participant CMD as adopt.md (Orchestrator)
    participant SCAN as adopt-scanner (adaptive)
    participant FEAT as adopt-feature-extractor
    participant DOC as adopt-doc-generator
    participant SYNTH as Inline Synthesis
    participant SCAFF as adopt-scaffolder (enhanced)
    participant GATE as Draft Review Gate

    CMD->>SCAN: Task(adopt-scanner)
    SCAN-->>CMD: ScannerPhaseResult { findings, file_map }

    Note over CMD: Phase 2 — spawn both agents in parallel
    CMD->>FEAT: Task(adopt-feature-extractor)
    CMD->>DOC: Task(adopt-doc-generator)

    FEAT-->>CMD: ERROR: agent timeout
    DOC-->>CMD: DocArtifacts { component_diagram, ... }

    Note over CMD: Feature extractor failed — non-blocking
    CMD->>CMD: featureExtractorFailed = true; features = []

    CMD->>SYNTH: reconcile(features=[], docs=DocArtifacts, scanner=ScannerFindings)
    SYNTH->>SYNTH: No features to reconcile — pass DocArtifacts through unchanged
    SYNTH->>SYNTH: synthesis_notes: ["Feature extractor failed — .memory/ population skipped"]
    SYNTH-->>CMD: UnifiedProjectModel { features: [], doc_artifacts: DocArtifacts, conflicts: [], synthesis_notes: ["..."] }

    CMD->>SCAFF: Task(adopt-scaffolder, model=UnifiedProjectModel)
    SCAFF->>SCAFF: features=[] → skip .memory/ population
    SCAFF->>SCAFF: doc_artifacts present → embed diagrams into CONTEXT.md
    SCAFF->>SCAFF: Note in DraftArtifacts: features_populated=[], docs_integrated=true
    SCAFF-->>CMD: DraftArtifacts { features_populated: [], docs_integrated: true, overall_confidence: medium }

    CMD->>GATE: Present with failure notice
    GATE-->>User: "⚠️ Feature extractor failed. .memory/ units not populated.\nDiagrams and module map are available.\nYou can re-run feature extraction."
    User-->>GATE: "re-run feature extraction"
    GATE-->>CMD: ApprovalDecision { approved: false, feedback: "re-run feature extraction", targetAgent: feature-extractor }

    CMD->>FEAT: Re-run adopt-feature-extractor (with same inputs)
    FEAT-->>CMD: FeatureUnits [auth, payments, dashboard]
    CMD->>SYNTH: Re-reconcile with features
    SYNTH-->>CMD: Updated UnifiedProjectModel
    CMD->>SCAFF: Re-run adopt-scaffolder with updated model
    SCAFF-->>CMD: Updated DraftArtifacts { features_populated: [auth, payments, dashboard] }

    CMD->>GATE: Present updated draft
    User-->>GATE: APPROVE
```

---

## Sequence 6: Rejection Loop — Extended Re-run Table (M2)

```mermaid
sequenceDiagram
    actor User
    participant CMD as adopt.md (Orchestrator)
    participant SCAN as adopt-scanner
    participant FEAT as adopt-feature-extractor
    participant DOC as adopt-doc-generator
    participant GATE as Draft Review Gate

    Note over CMD: Full flow completed — at review gate
    CMD->>GATE: Present confidence-grouped draft

    GATE-->>User: Draft shown with confidence badges

    User-->>GATE: "The diagram is wrong — it shows 2 layers but there are 3"
    GATE-->>CMD: ApprovalDecision { approved: false, feedback: "diagram wrong", targetAgent: doc-generator }

    Note over CMD: Targeted re-run: doc-generator only
    CMD->>DOC: Re-run adopt-doc-generator with feedback: "3 architectural layers"
    DOC-->>CMD: Updated DocArtifacts { component_diagram: updated, ... }

    Note over CMD: Re-run synthesis with updated DocArtifacts (feature units unchanged)
    CMD->>CMD: Re-synthesize: reconcile(existingFeatureUnits, updatedDocArtifacts, ScannerFindings)
    CMD->>CMD: Re-scaffold: regenerate CONTEXT.md with new diagrams

    CMD->>GATE: Present updated draft
    User-->>GATE: APPROVE

    Note over GATE,User: Example of scan-depth feedback (triggers full re-run cascade)
    Note over GATE: User: "It missed the infra/ directory — re-scan deeper"
    Note over CMD: Scanner re-run → then BOTH Phase 2 agents re-run → synthesis → scaffolder
```
