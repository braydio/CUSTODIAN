# Project-Root Main Synchronization Rule

Updated root `AGENTS.md` to require agents that land a scoped task branch on
`origin/main` to run `git -C <project-root> pull --ff-only origin main` in the
user's project-root checkout. The rule requires checking root worktree state and
preserving/reporting unrelated dirty or divergent work when a safe fast-forward
cannot be made.

Validation: `agent_workflow_contract` passed; `git diff --check` passed.

The project-root checkout at `/home/braydenchaffee/Projects/CUSTODIAN` was on
`codex/twin-solaria-runtime-v1a`, based at `3b7abe30f081499ac8cf463a4181f87952f3d4dd`,
with substantial unrelated dirty and untracked work. After landing, the required
`git pull --ff-only origin main` was attempted and Git refused because the root
checkout has unstaged changes. The landed `AGENTS.md` addition was applied to
the project-root copy directly; all other unrelated work remains preserved.
