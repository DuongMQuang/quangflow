# GitNexus Integration

Referenced by `cook.md`. Optional — gracefully skipped when GitNexus MCP server is not configured.

GitNexus provides a code knowledge graph (dependencies, call chains, blast radius) via MCP tools.
It adds **semantic-level safety** on top of file-level isolation (worktrees) and path-level enforcement (ownership hook).

## Detection

Check if `mcp__gitnexus__query` is available during pre-flight:
- Available → set `code_graph: gitnexus` in CK Context Block
- Not available → set `code_graph: none`, skip all GitNexus steps below

## Available Tools

| Tool | What it does | When to use |
|------|-------------|-------------|
| `mcp__gitnexus__query` | Semantic search — find execution flows by description | Dev: "find all functions that handle user authentication" |
| `mcp__gitnexus__context` | 360° symbol view — callers, callees, process participation | Dev: before editing a shared function, check who calls it |
| `mcp__gitnexus__impact` | Blast radius — direct (d=1), transitive (d=2), speculative (d=3+) | Dev: before modifying a public interface, see what breaks |
| `mcp__gitnexus__detect_changes` | Map git diff to affected processes | Tech-lead: review each dev's changes for unintended side effects |
| `mcp__gitnexus__rename` | Graph-aware multi-file rename with confidence scores | Dev: safely rename shared types/functions across modules |
| `mcp__gitnexus__cypher` | Raw Cypher query on the graph | Advanced: custom dependency queries |
| `mcp__gitnexus__list_repos` | List all indexed repositories | Pre-flight: verify current repo is indexed |

## Integration Points

### Pre-flight (cook)
1. Verify current repo is indexed: `mcp__gitnexus__list_repos`
2. If not indexed: warn user "GitNexus available but repo not indexed. Run `gitnexus index` first. Skipping semantic analysis."

### Dev Agents (Stage 2)
Inject into each dev's prompt when `code_graph: gitnexus`:

```
## Semantic Safety (GitNexus available)
Before editing any SHARED function, type, or interface (used by other modules):
1. Run `mcp__gitnexus__context` on the symbol to see all callers/callees
2. Run `mcp__gitnexus__impact` with d=2 to check blast radius
3. If impact reaches outside your ownership: message the lead before proceeding
4. After completing changes: run `mcp__gitnexus__detect_changes` to verify scope

When to use:
- Modifying a function signature → always check impact
- Adding/removing parameters → always check callers
- Renaming anything exported → use `mcp__gitnexus__rename` instead of manual find-replace
- Unsure if something is shared → check context

When to skip:
- Creating brand new files (no existing callers)
- Editing internal/private functions (no external impact)
- Modifying test files (no production callers)
```

### Tech-Lead Review (Stage 3)
When `code_graph: gitnexus`, tech-lead should:

1. For each dev's completed work, run `mcp__gitnexus__detect_changes` on their diff
2. Check if any changes affect processes outside the dev's ownership
3. Flag cross-boundary impacts as review findings:
   - If the impact was intentional and documented in DECISIONS.md → OK
   - If the impact was unintentional → classify as minor or major gap

### Tester (Stage 4)
When `code_graph: gitnexus`, tester can:

1. Use `mcp__gitnexus__query` to find all execution flows related to each REQ-ID
2. Ensure tests cover the full flow, not just the modified functions
3. Use `mcp__gitnexus__impact` to identify regression risk areas — prioritize testing there

## Graceful Degradation

When `code_graph: none`:
- All GitNexus steps are skipped silently — no warnings, no failures
- Dev agents rely on CONTRACTS.md and MODULES.md for dependency awareness (manual, less reliable)
- Tech-lead does manual cross-dev integration review
- Tester generates tests from requirements only (no graph-guided coverage)

The workflow is fully functional without GitNexus. It's an enhancement, not a dependency.

## Setup Instructions (for users)

To enable GitNexus in your project:
1. Install: `npm install -g gitnexus` (or follow https://github.com/abhigyanpatwari/GitNexus)
2. Index your repo: `gitnexus index`
3. Add to Claude Code MCP config (`.claude/mcp.json` or `~/.claude/mcp.json`):
   ```json
   {
     "mcpServers": {
       "gitnexus": {
         "command": "gitnexus",
         "args": ["mcp"]
       }
     }
   }
   ```
4. Restart Claude Code — GitNexus tools will be auto-detected by `/qf:cook`
