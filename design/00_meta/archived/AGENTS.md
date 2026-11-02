# AGENTS.md — PAI-OpenCode Repository

| Runtime | Linter | Lang |
|---------|--------|------|
| Bun (never npm/yarn/pnpm) | Biome (never ESLint/Prettier) | TypeScript ESM |

## Startup Order

Before beginning any non-trivial task:

1. Read `/home/Projects/pai-opencode/BRAYDEN/README.md` for the context protocol.
2. Read `/home/Projects/pai-opencode/BRAYDEN/INDEX.md` for the context map.
3. Read `/home/Projects/pai-opencode/BRAYDEN/CURRENT.md` if it exists for active session state.
4. Read `/home/Projects/pai-opencode/BRAYDEN/TASKLOG.md` for recent session history.
5. Read any additional BRAYDEN files referenced by `INDEX.md` that are relevant to the task.

Use BRAYDEN context throughout the session without waiting to be prompted.

Recommended BRAYDEN files:
- `README.md` - context protocol and memory rules
- `INDEX.md` - map of available context
- `CURRENT.md` - active task state, assumptions, blockers, and next actions
- `PROJECTS.md` - durable project summaries
- `PREFERENCES.md` - durable user workflow preferences
- `DECISIONS.md` - important decisions and rationale
- `COMMANDS.md` - known-good commands and repo-specific workflows
- `REFERENCES.md` - important paths, docs, and reusable references
- `TASKLOG.md` - concise chronological work log

```bash
bun install                  # Install dependencies
bun test                     # Run tests
biome check .                # Lint + format check
biome check --write .        # Auto-fix
```

**Directory Structure:**
- Repo root: `~/Projects/pai-opencode/`
- OpenCode home: `~/Projects/pai-opencode/.opencode/` (symlinked to `~/.opencode`)
- Skills location: `~/.opencode/skills/` → repo's `.opencode/skills/`

**Commits:** `feat(scope):`, `fix(scope):`, `docs:`, `chore:` — branch from `dev`, PR to `dev`, never commit to `main`.

**PAI System:** Loaded via skill system (`PAI/SKILL.md`, tier: always). Not in this file.

***BRAYDEN Context:** `/home/Projects/pai-opencode/BRAYDEN/` is the required repo-local operating context. It stores persistent operating notes, active project context, task state, decisions, references, and user preferences.

The agent must keep BRAYDEN context current:
- update `BRAYDEN/CURRENT.md` when the active task, blocker, assumption, or next action changes;
- update `BRAYDEN/INDEX.md` when new files, sections, projects, topics, or references are added;
- update the most specific BRAYDEN file when durable information is learned that is likely to be relevant again;
- append concise timestamped entries to `BRAYDEN/TASKLOG.md` after meaningful task steps;
- reference relevant BRAYDEN entries during work when they materially affect the task;
- keep notes concise, factual, organized, and current.

The agent should remember:
- active projects and their goals;
- durable user preferences that affect execution;
- repo-specific conventions;
- important commands, paths, and workflows;
- architecture decisions;
- known bugs, blockers, and fixes;
- recurring workflows;
- assumptions future agents should preserve.

The agent must not store:
- API keys, passwords, tokens, credentials, or private environment values;
- disposable chatter;
- raw command output unless unusually important;
- speculation as fact;
- stale details without marking or archiving them;
- personal details that do not affect repo work.
The agent must also:
- update `CURRENT.md` when the active task, blocker, or next action changes;
- update `PROJECTS.md`, `PREFERENCES.md`, `DECISIONS.md`, `COMMANDS.md`, or `REFERENCES.md` when durable information is learned;
- update `INDEX.md` when new files, sections, or topics are added.

The agent must not:
- store secrets or credentials in BRAYDEN files;
- record disposable chatter;
- preserve speculation as fact;
- bloat the task log with low-value command transcripts;
- overwrite user intent without explicit evidence.

**rtk (Rust Token Killer) Usage:**
`rtk` is a high-performance CLI proxy that filters and summarizes system outputs before they reach the LLM context, saving tokens.

**General Rule:** Prefer `rtk` prefix for any CLI commands *especially* when they are expected to  produce  large output. Use direct commands when `rtk` lacks required behavior, when exact output is needed, or when troubleshooting `rtk` itself. Examples:
- `rtk git status` instead of `git status`
- `rtk git diff` instead of `git diff`
- `rtk git log --oneline -10` instead of `git log --oneline -10`
- `rtk ls` instead of `ls`
- `rtk tree` instead of `tree`
- `rtk grep -n "pattern" path/` instead of `grep -rn "pattern" path/`

**rtk grep Usage:**
The `rtk` tool has a specific argument order for grep that differs from `rg`:
- **Wrong:** `rtk grep -n --glob "*.md" "pattern" path/` 
- **Correct:** `rtk grep -n "pattern" path/ --glob "*.md"`
- **Rule:** `rtk grep [OPTIONS] <PATTERN> [PATH] [EXTRA_RG_ARGS...]`
- For complex searches, fall back to `rg` or native `grep` tool.

**Key rtk subcommands for this project:**
| Command | Purpose | Example |
|---------|---------|---------|
| `rtk git` | Git with compact output | `rtk git status`, `rtk git diff` |
| `rtk grep` | Compact grep (strips whitespace, groups by file) | `rtk grep -n "pattern" path/` |
| `rtk ls` | Token-optimized directory listing | `rtk ls -la` |
| `rtk tree` | Directory tree with token optimization | `rtk tree .` |
| `rtk read` | Read file with intelligent filtering | `rtk read file.txt` |
| `rtk diff` | Ultra-condensed diff (only changed lines) | `rtk diff` |
| `rtk log` | Filter and deduplicate log output | `rtk log --oneline -10` |
| `rtk find` | Find files with compact tree output | `rtk find . -name "*.gd"` |
| `rtk gain` | Show token savings summary | `rtk gain` |

**Important:** The `bash()` tool spawns a NEW shell each time. Use `workdir` parameter, NOT `cd`. For rtk commands in CUSTODIAN repo, use `workdir: "/home/linux/Projects/CUSTODIAN"`.
