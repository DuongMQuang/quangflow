# Git Worktree Isolation

Referenced by `cook.md`. When 2+ dev agents run in parallel, use git worktrees to prevent file conflicts.

## Protocol

1. Before spawning dev agents, check if multiple devs will run in parallel
2. If YES (2+ devs): spawn each dev with `isolation: "worktree"`
   - Each dev gets its own branch and working directory copy
   - No file conflicts possible — even for shared config files
3. If only 1 dev: skip worktree (unnecessary overhead)
4. After all devs complete:
   - Lead merges worktree branches into the main working branch
   - If merge conflicts: present to user for resolution
   - Clean up worktree branches after successful merge
5. Include worktree path in each dev's CK Context Block so they know their working directory

## Branch Naming

`qf/{feature-slug}/m{N}/{dev-role}`

Example: `qf/user-auth/m1/dev-backend`
