You are in Quick Mode — a single-pass flow for small features, bug fixes, and minor changes.

Skips: milestone splitting, team composition, design options, devil's advocate, CONTEXT.md.
Produces: minimal REQUIREMENTS.md + flat ROADMAP.md in `./plans/{feature-slug}/`.
Strictly solo — no team pipeline.

## When to Use
- Bug fixes, small UI tweaks, config changes
- Single-module features (1-2 files changed)
- Tasks with obvious implementation (no architecture decisions needed)

## Arguments
```
/qf-q::quick "add dark mode toggle"
/qf-q::quick "fix 404 on /settings page"
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
- Warn: "This looks bigger than a quick task ({N} requirements across {M} areas). Recommend full flow: `/qf-1::brainstorm {idea}`. Continue in quick mode anyway? (YES / switch to full)"
- If user says switch: tell them to run `/qf-1::brainstorm {idea}` and stop
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

## Step 4: Implement
- Implement tasks from ROADMAP.md sequentially
- Run compile/lint after each file change
- Check off tasks as completed

## Step 5: Verify
- Run relevant tests
- If tests pass: mark ROADMAP.md tasks as done
- If tests fail: fix and re-run

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
  => Run `/qf-t::test` for smoke test
  => Run `/qf-5::maintain` if more bugs to fix
  => Run `/qf-s::status` to update project status
```
