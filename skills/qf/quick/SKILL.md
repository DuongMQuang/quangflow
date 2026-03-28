---
name: quick
description: "Use for small tasks — streamlined flow with minimal team (dev + tester), TDD enforced"
---

You are in Quick Mode — a single-pass flow for small features, bug fixes, and minor changes.

Skips: milestone splitting, team composition, design options, devil's advocate, CONTEXT.md.
Produces: minimal REQUIREMENTS.md + flat ROADMAP.md in `./plans/{feature-slug}/`.
Runs a minimal team: 1 dev agent + tester agent (multi-agent always).

<HARD-GATE>
Even quick mode follows TDD. Dev agent must produce red/green evidence in .evidence/tdd/.
</HARD-GATE>

## When to Use
- Bug fixes, small UI tweaks, config changes
- Single-module features (1-2 files changed)
- Tasks with obvious implementation (no architecture decisions needed)

## Arguments
```
/qf:quick "add dark mode toggle"
/qf:quick "fix 404 on /settings page"
```

## Step 1: Quick Requirements (1 round max)
Ask at most 3 clarifying questions in a single batch. Focus on:
- What exactly needs to change?
- Any constraints or edge cases?
- How do we verify it works?

If user's description is already clear enough, skip questions entirely.

## Step 2: Scope Check
Count the implied requirements from user's description + answers:

**If 5+ distinct requirements or 2+ functional areas detected:**
- Warn: "This looks bigger than a quick task ({N} requirements across {M} areas). Recommend full flow: `/qf:1-brainstorm {idea}`. Continue in quick mode anyway? (YES / switch to full)"
- If user says switch: tell them to run `/qf:1-brainstorm {idea}` and stop
- If user says YES: proceed but log warning in REQUIREMENTS.md

**If 4 or fewer requirements in 1 area:** proceed normally.

## Step 3: Generate Artifacts
Write to `./plans/{feature-slug}/`:

**REQUIREMENTS.md** (minimal):
```markdown
# {Feature Title}
Mode: quick
Status: FINAL

## Requirements
- REQ-001: {requirement}
- REQ-002: {requirement}

## Verification
- {how to verify it works}
```

**ROADMAP.md** (flat, no phases):
```markdown
# Roadmap — {feature-slug}
Mode: quick

## Tasks
- [ ] {task 1} — {file(s) to change}
- [ ] {task 2} — {file(s) to change}
- [ ] Verify: {verification step}
```

## Step 4: Implement (minimal team dispatch)
- Auto-compose minimal team: 1 dev agent + 1 tester agent
- Dispatch via `/qf:cook` with quick-mode flag (no domain-engineer, no tech-lead)
- Dev agent implements tasks from ROADMAP.md using TDD (RED-GREEN-REFACTOR)
- Tester agent validates after dev completes
- Evidence saved to `.evidence/tdd/` automatically

## Step 5: Verify
- Verify TDD evidence exists in `.evidence/tdd/` for each REQ-ID
- Run relevant tests
- If tests pass: mark ROADMAP.md tasks as done
- If tests fail: fix and re-run
- Save verification gate evidence to `.evidence/verification/quick-gate.md`

## Review Gate
Present summary:
```
**Quick task complete:** {title}
- Files changed: {list}
- Tests: {pass/fail}
```

Ask: "Looks good? Type SHIP to finalize."

## Output Rule
- When writing files, save silently. Do NOT print file contents to console.

## Next Step
After SHIP:
```
**Done.** Artifacts at `./plans/{feature-slug}/`.
  => Run `/qf:test` for smoke test
  => Run `/qf:5-maintain` if more bugs to fix
  => Run `/qf:status` to update project status
```
