# Gotchas — adopt-existing-project

Feature-specific lessons learned. See `plans/GOTCHAS.md` for global lessons.

---

## GOTCHA-001: Cross-dev field name coordination — UnifiedProjectModel producer/consumer mismatch

**Discovered:** M2 tech-lead review (2026-03-29)
**Phase:** Implementation (M2)
**Severity:** Critical

### What happened

The orchestrator (dev-orchestrator) named the feature list field `features` per Contract 12. The scaffolder (dev-upgrades) independently named it `feature_units`. Both devs were working from the same contract but the field name diverged at the implementation boundary. The mismatch caused `.memory/` population (REQ-006) to silently skip on every normal run.

Similarly, the conflict field was `conflicts` in the contract and orchestrator, but `synthesis_conflicts` in the scaffolder.

### Root cause

Contract 12 (UnifiedProjectModel) was defined by the domain engineer but was not enforced as a shared naming reference during implementation. Each dev named the field according to their own mental model without cross-checking the other dev's output schema.

### How to prevent

1. Before any multi-dev milestone: circulate a "field name glossary" derived directly from CONTRACTS.md. Each dev must ack the exact field names they produce AND consume.
2. In cross-dev contracts: explicitly call out the producer's output key name AND the consumer's expected input key name — even if they should be the same. Repetition prevents drift.
3. During tech-lead review: always grep for field names across all files in a pipeline stage. A one-line name mismatch silently breaks entire features.

---

## GOTCHA-002: Doc-generator confidence rule — "weakest signal" vs "primary signal"

**Discovered:** M2 tech-lead review (2026-03-29)
**Phase:** Implementation (M2)
**Severity:** Minor

### What happened

Contract 11 defines doc-generator confidence based on the "primary signal used to derive the component diagram structure." The dev implemented a "weakest signal" rule instead — overall confidence becomes the confidence of the weakest signal relied upon across all diagrams. This produces lower confidence scores than intended when a secondary signal (e.g., directory heuristics for edges) has lower quality than the primary signal (e.g., manifest for structure).

### Root cause

The contract's confidence rule was ambiguous. "Overall confidence" can reasonably mean "highest quality" (the contract's intent) or "lowest quality" (a more conservative interpretation). Dev chose the conservative interpretation without flagging the ambiguity.

### How to prevent

When contracts define "overall" confidence aggregation rules, make the aggregation function explicit: `max(signals)`, `min(signals)`, or `weighted_average(signals)`. Don't rely on adjectives like "primary" or "weakest" without defining a formula.
