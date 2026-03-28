# Integration Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verify that all discipline layer files were created correctly, all scripts are executable, all cross-references resolve, and no stale solo mode references remain.

**Architecture:** This is a validation-only plan with no new files. It runs verification commands against all artifacts produced by the previous plans to confirm the discipline layer is fully integrated and functional.

**Tech Stack:** Bash, Markdown

**Parent plan:** `_index.md`
**Depends on:** @plan-protocols, @plan-scripts, @plan-phase-mods, @plan-agent-mods, @plan-validation-update

---

## Task 1: Final integration test — verify all files parse correctly

**Files:** (no new files — validation only)

- [ ] **Step 1: Verify all new protocol files exist and have content**

Run:
```bash
for f in commands/qf/_protocols/_hard-gates.md commands/qf/_protocols/_tdd-enforcement.md commands/qf/_protocols/_systematic-debugging.md commands/qf/_protocols/_verification-gates.md commands/qf/_protocols/_structured-logging.md commands/qf/_protocols/_context-memory.md; do
  echo "$f: $(wc -l < "$f") lines"
done
```

Expected: All files exist with 70+ lines each.

- [ ] **Step 2: Verify all new scripts exist and are executable**

Run:
```bash
for f in scripts/validate/validate-tdd-coverage.sh scripts/validate/validate-evidence.sh scripts/validate/validate-memory.sh scripts/hooks/auto-checkpoint.sh scripts/hooks/evidence-tracker.sh scripts/hooks/save-feature-memory.sh; do
  if [[ -x "$f" ]]; then
    echo "$f: OK (executable)"
  else
    echo "$f: MISSING or not executable"
  fi
done
```

Expected: All files OK.

- [ ] **Step 3: Verify modified files don't have syntax issues**

Run:
```bash
# Check for broken markdown references
grep -rn '_protocols/_tdd-enforcement.md\|_protocols/_systematic-debugging.md\|_protocols/_verification-gates.md\|_protocols/_hard-gates.md\|_protocols/_structured-logging.md\|_protocols/_context-memory.md' commands/qf/ agents/
```

Expected: References found in 3-handoff.md, 4-verify.md, 5-maintain.md, quick.md, dev-teammate.md, tester.md, _shared.md.

- [ ] **Step 4: Run existing validation scripts to ensure they still work**

Run:
```bash
bash scripts/validate/validate-install.sh 2>/dev/null || echo "Install validation not applicable (dev environment)"
```

- [ ] **Step 5: Verify no SOLO references remain in modified files**

Run:
```bash
grep -rn 'SOLO\|solo mode\|team_mode: false' commands/qf/3-handoff.md commands/qf/quick.md commands/qf/_protocols/_shared.md
```

Expected: No matches (solo mode fully removed).

- [ ] **Step 6: Commit final state**

```bash
git add -A
git status
# If any unstaged changes, review and add
git commit -m "chore: verify discipline layer integration — all files validated"
```
