# SEQUENCES — /qf:adopt Milestone 1

## Sequence 1: Happy Path — Full Adopt Flow

```mermaid
sequenceDiagram
    actor User
    participant CMD as adopt.md (Orchestrator)
    participant QA as Pre-scan Questionnaire
    participant SCAN as adopt-scanner
    participant SCAFF as adopt-scaffolder
    participant GATE as Draft Review Gate
    participant ROUTER as Post-Adopt Router

    User->>CMD: /qf:adopt

    CMD->>QA: Run 5 pre-scan questions
    QA-->>User: Q1: Primary language?
    User-->>QA: "TypeScript"
    QA-->>User: Q2: Project type (monolith/mono/microservices)?
    User-->>QA: "monolith"
    QA-->>User: Q3: Has tests? (y/n)
    User-->>QA: "y"
    QA-->>User: Q4: Has docs? (y/n)
    User-->>QA: "partial"
    QA-->>User: Q5: Adoption goal (new feature / maintenance)?
    User-->>QA: "new feature"
    QA-->>CMD: PreScanAnswers { language, type, hasTests, hasDocs, goal }

    CMD->>SCAN: Task(adopt-scanner, root=CWD, answers=PreScanAnswers)
    CMD->>SCAFF: Task(adopt-scaffolder, answers=PreScanAnswers)
    Note over CMD,SCAFF: Both agents spawned in parallel

    SCAN->>SCAN: Read manifests, dirs, entry points, configs
    SCAN->>SCAN: Detect stack, structure, conventions, gaps
    SCAN-->>CMD: ScannerFindings YAML

    CMD->>SCAFF: Pass ScannerFindings to scaffolder
    SCAFF->>SCAFF: Check for existing artifacts (none found)
    SCAFF->>SCAFF: Create plans/ .evidence/ .memory/
    SCAFF->>SCAFF: Generate CONTEXT.md (status: DRAFT)
    SCAFF-->>CMD: DraftArtifacts { contextPath, dirsCreated, partialAdoption: false }

    CMD->>GATE: Fan-in complete — present drafts
    GATE-->>User: Show CONTEXT.md draft + gap findings summary
    User-->>GATE: APPROVE

    GATE-->>CMD: ApprovalDecision { approved: true }
    CMD->>ROUTER: Finalize artifacts
    ROUTER->>ROUTER: Remove DRAFT status from CONTEXT.md
    ROUTER->>ROUTER: Write adoption metadata to Locked Decisions
    ROUTER-->>User: "Adoption complete. What's next?\n1. /qf:1-brainstorm\n2. /qf:5-maintain"
    User-->>ROUTER: (picks next command)
```

---

## Sequence 2: Partial Adoption — Existing Artifacts Detected

```mermaid
sequenceDiagram
    actor User
    participant CMD as adopt.md (Orchestrator)
    participant QA as Pre-scan Questionnaire
    participant SCAN as adopt-scanner
    participant SCAFF as adopt-scaffolder
    participant GATE as Draft Review Gate
    participant ROUTER as Post-Adopt Router

    User->>CMD: /qf:adopt

    CMD->>QA: Run 5 pre-scan questions
    QA-->>CMD: PreScanAnswers

    CMD->>SCAN: Task(adopt-scanner, root=CWD, answers=PreScanAnswers)
    CMD->>SCAFF: Task(adopt-scaffolder, answers=PreScanAnswers)
    Note over CMD,SCAFF: Both agents spawned in parallel

    SCAN-->>CMD: ScannerFindings YAML
    CMD->>SCAFF: Pass ScannerFindings

    SCAFF->>SCAFF: Check for existing artifacts
    Note over SCAFF: Found: plans/ (existing), CONTEXT.md (existing), .memory/ (existing)

    SCAFF-->>User: "Found existing plans/ — merge or skip?"
    User-->>SCAFF: "merge"
    SCAFF-->>User: "Found existing CONTEXT.md — update or keep?"
    User-->>SCAFF: "update"
    Note over SCAFF: .memory/ preserved automatically; .evidence/ always preserved

    SCAFF->>SCAFF: Merge plans/ content (additive only)
    SCAFF->>SCAFF: Update CONTEXT.md (preserve existing fields, add adopted: true)
    SCAFF->>SCAFF: Extend .memory/ with new findings
    SCAFF-->>CMD: DraftArtifacts { contextPath, mergedDirs: [plans, memory], partialAdoption: true }

    CMD->>GATE: Present drafts (with merge summary)
    GATE-->>User: Show updated CONTEXT.md + merge report + gap findings
    User-->>GATE: APPROVE

    GATE-->>CMD: ApprovalDecision { approved: true }
    CMD->>ROUTER: Finalize
    ROUTER->>ROUTER: Remove DRAFT status
    ROUTER->>ROUTER: Write adoption + merge metadata to Locked Decisions
    ROUTER-->>User: Adoption complete + route choice
```

---

## Sequence 3: Error Path — Scanner Fails, Scaffolder Continues

```mermaid
sequenceDiagram
    actor User
    participant CMD as adopt.md (Orchestrator)
    participant QA as Pre-scan Questionnaire
    participant SCAN as adopt-scanner
    participant SCAFF as adopt-scaffolder
    participant GATE as Draft Review Gate
    participant ROUTER as Post-Adopt Router

    User->>CMD: /qf:adopt

    CMD->>QA: Run 5 pre-scan questions
    QA-->>CMD: PreScanAnswers

    CMD->>SCAN: Task(adopt-scanner, root=CWD, answers=PreScanAnswers)
    CMD->>SCAFF: Task(adopt-scaffolder, answers=PreScanAnswers)

    SCAN-->>CMD: ERROR: agent timeout / unrecognized structure
    Note over CMD: Scanner failed. Capture error. Continue.

    CMD->>SCAFF: Pass empty ScannerFindings + errorFlag: true
    SCAFF->>SCAFF: Check for existing artifacts
    SCAFF->>SCAFF: Create plans/ .evidence/ .memory/
    SCAFF->>SCAFF: Generate minimal CONTEXT.md from PreScanAnswers only
    Note over SCAFF: All inferred fields marked ⚠️ ASSUMPTION

    SCAFF-->>CMD: DraftArtifacts { contextPath, dirsCreated, scannerFailed: true }

    CMD->>GATE: Present drafts (with scanner error notice)
    GATE-->>User: "⚠️ Scanner failed. CONTEXT.md generated from your answers only.\nFields marked ⚠️ ASSUMPTION need manual review."
    GATE-->>User: Show partial CONTEXT.md draft

    User-->>GATE: "update the tech_stack section"
    GATE-->>CMD: ApprovalDecision { approved: false, feedback: "update tech_stack" }

    CMD->>SCAFF: Re-run scaffolder with user feedback (no scanner re-run)
    SCAFF-->>CMD: Updated DraftArtifacts

    CMD->>GATE: Present updated draft
    User-->>GATE: APPROVE

    GATE-->>CMD: ApprovalDecision { approved: true }
    CMD->>ROUTER: Finalize
    ROUTER->>ROUTER: Remove DRAFT status
    ROUTER->>ROUTER: Write metadata (note: scanner_failed: true)
    ROUTER-->>User: Adoption complete + route choice

    Note over User,ROUTER: Scanner failure is logged in CONTEXT.md Constraints.\nUser can re-run /qf:adopt to get full scan later.
```

---

## Sequence 4: Rejection Loop — User Requests Changes

```mermaid
sequenceDiagram
    actor User
    participant CMD as adopt.md (Orchestrator)
    participant SCAN as adopt-scanner
    participant SCAFF as adopt-scaffolder
    participant GATE as Draft Review Gate

    Note over CMD: Pre-scan and fan-out already complete (see Sequence 1)

    CMD->>GATE: Present draft CONTEXT.md + gap findings
    GATE-->>User: Draft shown

    User-->>GATE: "The tech stack is wrong — it's Vue not React"
    GATE-->>CMD: ApprovalDecision { approved: false, feedback: "tech stack: Vue not React", targetAgent: scanner }

    CMD->>SCAN: Re-run adopt-scanner with correction hint
    SCAN-->>CMD: Updated ScannerFindings (Vue detected)

    CMD->>SCAFF: Re-run adopt-scaffolder with updated findings
    SCAFF-->>CMD: Updated DraftArtifacts

    CMD->>GATE: Present updated draft
    GATE-->>User: Updated CONTEXT.md shown

    User-->>GATE: APPROVE
    Note over GATE: Approval received — proceed to finalize
```
