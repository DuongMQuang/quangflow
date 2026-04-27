# Complexity Triage Protocol

Referenced by `cook.md` Stage 0. Cook auto-decides solo / light / team based on task complexity. User can override at borderline or via `--team` flag / `QUANGFLOW_FORCE_TEAM=1` env var.

## Purpose

Avoid agent overkill on small tasks (1 LOC fix → 3 agents wastes tokens). Avoid full team for trivial work. Escalate to user when ambiguous.

## Tiers

| Tier | Spawn | Behavior |
|------|-------|----------|
| **solo** | 0 agents | Main agent (Opus) edits files directly. SOLO-LOG.md written by main. |
| **light** | 2 agents | dev + tester (current `/qf:quick` behavior). |
| **team** | 4-6 agents | Full pipeline: domain-engineer → devs → tech-lead → tester → PM (current `/qf:cook` behavior). |

## Heuristics

Inputs (read from REQUIREMENTS.md + ROADMAP.md if exist; otherwise infer from user task description):

- **REQ count**: number of REQ-IDs in scope for current milestone
- **Phase count**: number of ROADMAP phases for current milestone
- **File estimate**: number of source files expected to change (from MODULES.md or task description)
- **Keyword scan**: scan task description + REQ titles for sensitive terms

### Sensitive Keywords (force escalate, never solo)

If ANY of these appear in REQUIREMENTS.md or task description, the task CANNOT be `solo`. Escalate to `team` (or `light` minimum if user overrides).

```
auth, oauth, jwt, session, token, password, credential
payment, billing, charge, invoice, refund
crypto, encrypt, decrypt, hash, signature
migration, schema, alembic, ddl, drop table
sql injection, xss, csrf, csrf-token, sanitize
api key, secret, env var leak
```

Match is case-insensitive substring. The presence of any keyword forces the borderline prompt with `solo` removed from options.

### Tier Thresholds

| Tier | REQs | Phases | Files | Keywords |
|------|------|--------|-------|----------|
| solo | 1 | 1-2 | 1 | None |
| light | 2-4 | 2-3 | 2-3 | None |
| team | 5+ | 4+ | 4+ | Any |

### Borderline (escalate to user)

If signals are mixed, e.g.:
- 4 phases + 3 REQs (between light and team)
- 1 REQ but 3 files (between solo and light)
- Sensitive keyword + only 1 REQ
- File estimate unknown

→ Print decision matrix and ask user to pick: `[solo / light / team / cancel]`. Solo removed from options if any sensitive keyword matched.

## Decision Algorithm

Precedence (highest → lowest): per-invocation flag > env var > `team_mode` field > rubric > default.

```
1. If --team flag → return "team".
2. If --light flag → return "light".
3. If --solo flag → return "solo" (warn if sensitive keywords present, but proceed).
4. If --skip / --only / --from flag (any stage) → bypass triage, return "team".
5. If env var QUANGFLOW_FORCE_TEAM=1 → return "team", skip prompt.
6. Read REQUIREMENTS.md `team_mode` field:
   - team_mode: false → return "solo" (user opted out of team explicitly; smart routing must respect, override rubric).
   - team_mode: true or unset → continue to rubric.
7. Read REQUIREMENTS.md REQ-IDs, ROADMAP.md phases, task description.
8. Scan REQ descriptions + task text for sensitive keywords. If any match: borderline_keyword = true.
9. Compute (req_count, phase_count, file_count) — best estimates.
10. Apply thresholds:
    - All match "solo" thresholds AND no keywords → "solo"
    - All match "light" thresholds AND no keywords → "light"
    - Any match "team" threshold OR keywords → "team"
    - Otherwise (mixed) → borderline_mixed = true
11. If borderline_keyword OR borderline_mixed → print prompt, wait for user choice.
12. Return decided tier.
```

**Precedence rationale**:
- Flag is per-invocation explicit intent (strongest).
- Env var is session-level config (weaker than per-invocation).
- `team_mode: false` is project-level explicit opt-out; smart routing returns solo (not team), even if rubric would say team.
- Rubric is the auto-decision when nothing overrides.

## User Prompt Format

When borderline detected, print exactly this format:

```
**Complexity Triage — borderline**

Signals:
- REQ count: {N}
- Phase count: {N}
- File estimate: {N or "unknown"}
- Sensitive keywords: {list or "none"}

Cannot auto-decide. Pick a tier:
- **solo** — Main agent edits directly. {available | NOT available — sensitive keyword}
- **light** — Dev + tester (2 agents).
- **team** — Full pipeline (4-6 agents).
- **cancel** — Stop, don't execute.

Default: light. Override with `cook --team` to force team next time.

Your choice: [solo / light / team / cancel]
```

If solo is unavailable, mark it `NOT available` with reason.

## Output Format (cook consumes)

After triage decides:

```yaml
tier: solo | light | team
reason: |
  Auto-detected: 1 REQ, 1 phase, 1 file, no sensitive keywords.
  (or)
  User override: picked 'team' on borderline (3 REQs, 4 phases).
  (or)
  Forced via QUANGFLOW_FORCE_TEAM=1.
inputs:
  req_count: 1
  phase_count: 1
  file_count: 1
  keywords_matched: []
```

Cook writes this to `plans/{slug}/milestone-{N}/.triage-decision.yml` for audit + resume.

## Fixtures (for testing)

### Fixture 1: Trivial fix → solo

```
Task: "fix typo in error message in src/auth/login.py line 42"
REQUIREMENTS.md: REQ-001 only ("fix typo in login error message")
ROADMAP.md: 1 phase ("apply fix + verify")
Files: 1 (login.py)
Keywords scan: "auth" found in path BUT not in REQ description → NOT a match (path-only)
Expected tier: solo
```

NOTE: Keyword match is on REQ description and task text, NOT file paths (avoid false positives like `src/auth/typo-fix.py`).

### Fixture 2: Small feature → light

```
Task: "add dark mode toggle to settings page"
REQUIREMENTS.md: REQ-001, REQ-002, REQ-003 (toggle UI, persist preference, system theme)
ROADMAP.md: 2 phases (UI + persistence)
Files: 3 (settings-page.tsx, theme-store.ts, theme.css)
Keywords scan: none
Expected tier: light
```

### Fixture 3: Security feature → team

```
Task: "add OAuth2 with refresh tokens"
REQUIREMENTS.md: REQ-001..REQ-006 (auth flow, token storage, refresh, revoke, etc.)
ROADMAP.md: 5 phases
Files: 8
Keywords scan: "oauth", "token", "auth" → matched
Expected tier: team (forced by keywords)
```

### Fixture 4: Borderline → user prompt

```
Task: "refactor pricing module to use new tax engine"
REQUIREMENTS.md: REQ-001..REQ-003 (3 REQs)
ROADMAP.md: 4 phases
Files: 3 (pricing-calc, tax-adapter, tests)
Keywords scan: none
Signals mixed (3 REQs = light, 4 phases = team) → borderline_mixed
Expected: print prompt, wait for user
```

### Fixture 5: Solo with sensitive keyword → escalate

```
Task: "rotate session secret in config"
REQUIREMENTS.md: REQ-001 ("update SESSION_SECRET env var")
ROADMAP.md: 1 phase
Files: 1 (config.py)
Keywords scan: "session", "secret" → matched
Solo thresholds met BUT keyword match → borderline_keyword
Expected: print prompt with solo NOT available, default light
```

### Fixture 6: team_mode false override → solo

```
Task: "anything"
REQUIREMENTS.md: REQ-001..REQ-005 (5 REQs — would be team by rubric)
team_mode: false (user explicitly opted out)
Keywords scan: none
Algorithm step 6 fires BEFORE rubric (step 7+)
Expected tier: solo (override rubric)
Reason: user explicit opt-out wins over auto-rubric
```

### Fixture 7: --team flag overrides team_mode false → team

```
Task: "fix typo"
REQUIREMENTS.md: REQ-001 (1 REQ — rubric says solo)
team_mode: false (config says solo)
Invocation: /qf:cook --team (per-invocation flag)
Algorithm step 1 fires (highest precedence)
Expected tier: team
Reason: per-invocation flag > config field
```

## Backward Compatibility

- `--skip <stage>` flags (existing): bypass triage entirely, run full team. Treat as explicit team intent.
- `--from <stage>` (existing): bypass triage, resume team pipeline.
- `--only <stage>` (existing): bypass triage, run specific stage in team mode.
- `QUANGFLOW_FORCE_TEAM=1`: env override, always team.
- Existing `/qf:quick` invocations route through triage with implicit `--light`.

## Cook Integration

In `cook/SKILL.md`, Stage 0 is the FIRST step before any other pre-flight:

```
### Stage 0: Complexity Triage
1. Run triage algorithm (this protocol).
2. Write decision to `.triage-decision.yml`.
3. Branch:
   - tier=solo → emit solo handoff (see `_solo-handoff.md`), STOP cook execution.
   - tier=light → continue with reduced pipeline (skip domain-engineer, debate, tech-lead).
   - tier=team → continue with full pipeline.
4. If borderline: prompt user, wait, then branch on choice.
```

## Audit Trail

Every cook invocation logs triage outcome:
- `.triage-decision.yml` (machine-readable)
- STATUS.md → `## Triage` section (human-readable summary)

Format in STATUS.md:
```markdown
## Triage
- Tier: light
- Reason: 3 REQs, 2 phases, no sensitive keywords
- Decided: 2026-04-27T13:11:00 (auto)
```

For solo, this is appended by SOLO-LOG.md instead.
