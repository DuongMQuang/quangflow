# Gaps — /qf:adopt Milestone 1

**Date:** 2026-03-28
**Source:** Tech lead review (REVIEW.md)

---

## GAP-001: Scaffolder writes CONTEXT.md to wrong path

**Severity:** Major
**File:** `agents/adopt-scaffolder.md` (and plugin mirror)
**Contract:** Contract 2 (CONTEXT.md Output Schema), MODULES.md Module 3

### Description

The scaffolder generates CONTEXT.md at `plans/CONTEXT.md` but the contract specifies `plans/{slug}/CONTEXT.md`. The orchestrator (adopt.md) creates `plans/{feature-slug}/` in Step 1 and all downstream `/qf:*` commands look for context at `plans/{slug}/CONTEXT.md`.

### Impact

All downstream phases break — they cannot find CONTEXT.md at the correct path. This is a runtime correctness failure.

### Fix

In `agents/adopt-scaffolder.md`:
- Line: `Generate draft CONTEXT.md at plans/CONTEXT.md`
  → Change to: `Generate draft CONTEXT.md at plans/{feature-slug}/CONTEXT.md`
- Line: `plans/CONTEXT.draft.md` (partial adoption case)
  → Change to: `plans/{feature-slug}/CONTEXT.draft.md`
- Update `context_md_path` output example to match new path

The feature slug is provided to the scaffolder via the CK Context field `Feature slug: {feature-slug}` in the orchestrator's spawn prompt.

Apply the same fix to `plugins/quangflow/agents/adopt-scaffolder.md`.

### Status

Fixed by tech-lead (2026-03-28). Updated `agents/adopt-scaffolder.md` and `plugins/quangflow/agents/adopt-scaffolder.md`. Also fixed co-located issues: version `"1.1.0"` → `"2.0.0"`, added missing `created` field, clarified partial adoption details split.
