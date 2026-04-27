# Changelog

All notable changes to QuangFlow are documented here.

## [2.2.0] — 2026-04-06

### Added — Two-Pass Review Pipeline
- **spec-reviewer agent**: REQ compliance check before tech-lead quality review (commit 35b49ab).
- **Pipeline evolution**: `devs → spec-reviewer → tech-lead → tester` (Stage 2.5 inserted in cook).
- **Task granularity gate**: Phase 3 auto-splits ROADMAP phases >150 LOC or >3 REQ-IDs into sub-phases.
- **Context hard gate (70%)**: Auto-checkpoint + terminate + fresh agent resume when context window hits 70%.

### Changed
- `cook` pipeline updated with Stage 2.5 (spec-reviewer) and context monitoring.
- `dev-teammate` agent updated for two-pass handoff.
- Validation script updated for new spec-reviewer stage.

## [2.1.0] — 2026-03-30

### Added — Plugin Distribution
- **Self-hosted marketplace**: New `plugins/quangflow/` substructure + `marketplace.json` enables Claude Code plugin install (`/plugin marketplace add ...`).
- **`/qf:adopt` command**: Adaptive codebase scanning, feature extraction, and DRAFT doc generation for onboarding existing projects (commit 80face2). _Note: Now invoked as `/quangflow:adopt` when installed via plugin._
- **Plugin manifest** (`plugin.json`) + flat `skills/` directory for Claude Code discovery.

### Fixed
- Skills directory flattened for Claude Code skill discovery (commit 7a50ac2).
- `validate-evidence.sh` now correctly looks in `.evidence/verification/` instead of feature dir.

### Documentation
- README updated with working plugin install instructions.

## [2.0.0] — 2026-03-28

### Added — Discipline Layer
- **TDD enforcement** (`_tdd-enforcement.md`): Iron-law RED-GREEN-REFACTOR cycle. No production code without a failing test. Evidence saved to `.evidence/tdd/`.
- **Systematic debugging** (`_systematic-debugging.md`): 4-phase root cause process (Investigate → Analyze → Hypothesize → Fix). 3+ failed attempts triggers architecture escalation.
- **Verification gates** (`_verification-gates.md`): Evidence-before-assertions at every phase transition. Banned language: "should work", "probably passes."
- **Hard gates & red flags** (`_hard-gates.md`): Master rationalization table (10 patterns). Three enforcement layers: prompts + inline gates + scripts.
- **Structured logging** (`_structured-logging.md`): JSON log standard with level/source/module/trace_id. Frontend errors bridge to backend via `/api/logs`.
- **Feature Memory Units** (`_context-memory.md`): Per-feature context in `.memory/` loaded via `@mention`. Scales context across sessions and agents.

### Added — Scripts & Hooks
- `validate-tdd-coverage.sh`: Verify red+green TDD evidence per REQ-ID
- `validate-evidence.sh`: Verify `.evidence/` artifacts per phase transition
- `validate-memory.sh`: Verify FMU structure, bidirectional links, no orphans
- `auto-checkpoint.sh`: PostToolUse hook — auto-save agent progress
- `evidence-tracker.sh`: PostToolUse hook — track evidence in PIPELINE-STATE
- `save-feature-memory.sh`: Phase transition hook — auto-update FMU
- `check-update.sh`: SessionStart hook — notify when new version available

### Changed — Phase Evolution
- **Phase 3 (Handoff)**: Now injects TDD/logging/verification mandates into ROADMAP. SOLO option removed.
- **Phase 4 (Verify → Verify & Certify)**: TDD compliance audit added. Produces CERTIFICATION.md instead of QA-REPORT.md (legacy format still accepted).
- **Phase 5 (Maintain)**: Systematic debugging protocol injected. Bug fixes require TDD evidence.
- **Quick mode**: Now runs minimal team (dev + tester) instead of solo. TDD enforced.

### Changed — Agent Evolution
- **dev-teammate**: TDD cycle mandatory (Step 1.5 + restructured Step 2). Structured logging required. 3 new self-check items.
- **tester**: No longer generates unit tests (devs own those via TDD). Now: TDD coverage auditor + integration/E2E test generator + traceability matrix builder.

### Removed
- **Solo mode**: Multi-agent is the only mode. All tasks run through agent team pipeline.
- **SOLO option** from Phase 3 handoff gate (SHIP/REFINE only).

### Infrastructure
- Plugin installation support (Claude Code, Cursor, OpenCode) — recommended over bash install
- Session-start update notification hook

## [1.1.0] — 2026-03-26

### Added
- GitNexus MCP integration for semantic-level code safety
- Interactive guided tour (`/qf:guide`)
- Showcase walkthrough documentation

## [1.0.0] — 2026-03-20

### Added
- Initial release: 5-phase workflow (init → brainstorm → design → handoff → verify → maintain)
- 12 slash commands
- Team mode with 6 agent roles
- Autopilot mode for non-technical users
- GOTCHAs self-improvement loop
- Crash recovery with pipeline state tracking
