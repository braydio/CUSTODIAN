# Godot Addon Cleanup, Consolidation & Configuration (v1)

## What this slice did

Audited `custodian/addons/` (16 directories, 6 enabled editor plugins) against
live production usage rather than the prior audit's historical snapshot, then
removed everything with zero production consumers and unwound its config.

### Removed (zero production consumers, verified by grep across game/content/docs/scripts)

- `addons/fightengine/` — editor-plugin lifecycle functions were empty; its
  `HitBox2D`/`HurtBox2D`/`CollisionBox2D` classes were only consumed by its own
  demo scenes/scripts.
- `addons/limboai/` (82MB of per-platform native binaries) — its only consumer
  in the whole repo was Fight Engine's own demo (`move_state.gd`,
  `idle_state.gd`, `attack_state.gd`, `label.gd`, `player.gd`/`.tscn`); nothing
  production-facing referenced `BTPlayer`, `LimboState`, or any other LimboAI
  class.
- `addons/indie_game_components/` — `EightDirMoverComponent`,
  `GridMoverComponent`, `HealthComponent`, `ManaComponent`, etc. had no
  consumers; CUSTODIAN's own movement/health authorities were never touched.
- `addons/godot_mcp/` (legacy MCP integration) + `docs/GODOT_MCP_SETUP.md` +
  `scripts/start-godot-mcp.sh` — fully superseded by `addons/godot_ai/`, which
  remains the one functioning MCP integration (`_mcp_game_helper` autoload,
  `McpDebuggerPlugin`, `mcp_spawn_state.gd` dedup, etc.).
- `addons/ai_coding_assistant/` — overlapped with Codex/godot_ai workflows,
  already disabled, zero consumers.
- `addons/anim_sheet/`, `addons/aseprite_importer/` — already disabled, zero
  consumers, superseded by the canonical Aseprite live bridge / Asset Pipeline
  V2.
- `addons/sprite_pipeline/` (`fabs133/sprite-pipeline-plugin`, a vendored
  third-party OpenAI sprite generator) + its packaging metadata
  (`custodian/asset.cfg`, `docs/submissions/ASSET_LIBRARY_SUBMISSION.md`,
  `docs/submissions/ITCH_IO_SUBMISSION.md`). **Caution for future readers:**
  the string "sprite pipeline" is heavily overloaded in this repo —
  `SPRITE_PIPELINE_SYSTEM.md`, `CUSTODIAN_SPRITE_PIPELINE` env var, and
  `update_sprite_pipeline.md` all refer to CUSTODIAN's own canonical asset
  ingest pipeline (Asset Pipeline V2) and are unrelated to this addon. Verified
  each hit individually before concluding this addon itself had no consumers.
- `addons/__MACOSX/` — zip-archive debris.
- `addons/copy_all_errors/` — already disabled; godot_ai's own
  editor/game log capture (`editor_logger.gd`, `game_logger.gd`,
  `structured_log_ring.gd`, `McpDebuggerPlugin`) already covers this
  AI-agent-driven workflow's error-reporting needs.
- `addons/debug_console/` + its three dangling autoloads (`DebugCore`,
  `CommandRegistry`, `GameConsoleManager`, registered in `project.godot` even
  though the editor plugin itself was already disabled). Landed as its own
  commit since it's a separable concern from the vendor-addon purge.
  `GameConsoleManager._input()` listened for F12 globally at runtime and
  competed with the native `debug_hud` F12 toggle — removing it resolves that
  conflict. Zero other consumers of the three autoload names existed anywhere
  outside the addon.

### Retained

- `addons/dev-console/` — canonical tilde/backtick DevConsole, untouched.
- `addons/godot_ai/` — canonical MCP integration. Read `plugin.gd` (2250
  lines)/`connection.gd`/`utils/`: duplicate-server detection
  (`mcp_spawn_state.gd`) and Windows port reservation already exist. Made no
  changes — found no concrete defect, and the task explicitly warns against
  unevidenced "improvements" to working functionality.
- `addons/shader_library/` — configured and active (`[shader_library]` in
  `project.godot`); left as-is per "preserve existing shader destination."
- `addons/godotdev_nvim_node_copy/` — no evidence either way of an active
  Neovim workflow in docs; kept conservatively since it's zero-footprint and
  removing a personal editor tool without signal risked breaking a workflow
  this repo's docs simply don't mention. Lowest-confidence call in this slice
  — revisit if the user doesn't use Neovim.
- `addons/Sound FX Starter Pack Vol. 1/` (215MB) — exactly one file is
  actually used (`game/actors/operator/operator.gd:100` preloads
  `.../Motions and Impacts/Impact Vox Hammer.wav` directly). Per the brief's
  explicit "do not relocate referenced audio casually" guidance, left the
  whole pack untouched rather than partially pruning a licensed third-party
  pack mid-task.

### Config unwound

- `project.godot`: `[editor_plugins] enabled` dropped `fightengine` and
  `indie_game_components`; `[autoload]` dropped `DebugCore`,
  `CommandRegistry`, `GameConsoleManager`.
- `custodian/.gitignore`: dropped the stale `addons/godot_mcp/.cache/` rule.
- `docs/ASSET_LAYOUT_CONVENTION.md`: the "third-party addon assets" exception
  example pointed at `addons/fightengine/demo/Assets/...`; generalized it so
  it doesn't cite a now-deleted path.
- `tools/operator/operator_art_worktree.py`: dropped
  `custodian/addons/debug_console` from the Operator-art sparse-checkout
  profile.
- `tools/validation/validation_manifest.json`: added `coverage_excludes`
  entries for every removed vendor tree plus `custodian/.gitignore`,
  `custodian/asset.cfg`, and `scripts/start-godot-mcp.sh` — see Process
  Feedback below, this was a real tooling gap the deletion exposed.

### Documentation drift checked, not changed

`AGENTS.md` (root + `custodian/`), `README.md`, and
`docs/ai_context/CURRENT_STATE.md` already described DevConsole/F12/DebugBus/
DevObservatory as canonical — they matched the end state this slice produces,
so no edits were needed there. All other `SPRITE_PIPELINE`-adjacent doc hits
were the unrelated canonical pipeline (see caution note above) or archived
task-packet history, which is intentionally left alone.

## Validation

- `godot --headless --path custodian --import --quit`: clean full reimport
  (9526 assets), zero errors, before and after the changes.
- `godot --headless --path custodian --quit-after 60` (real boot,
  `runtime_entrypoint.tscn`): zero errors/warnings.
- `python3 custodian/tools/validation/run_validation.py --changed --base
  83ff15da47198a3c3b076864b055561683567994 --json`: **25/25 selected tests
  passed, coverage complete, `passed: true`.** Covers
  `asset_pipeline_v2`, `controller_input_contract`,
  `operator_2_5d_canonical_visual_contract`, `operator_art_worktree`,
  `operator_cli_publish_boundary`, `operator_workbench_ui`, `instant_replay`,
  `awakening_first_return`, `startup_world_entry`, `world_contract_prewarm`,
  `world_transition_handoff`, plus the validation-manifest-owned tests pulled
  in by the manifest edit.
- Manual read-based verification that no surviving file (game/content/docs/
  tools/.gitignore/CI workflows) still references any removed addon path or
  UID.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: (1) `tools/validation/run_validation.py --changed` requires
  every changed path — including deletions — to have test coverage or an
  explicit `coverage_excludes` entry; bulk-deleting never-covered vendor
  addons produced ~600 "uncovered" paths and a false non-green result despite
  all selected tests passing. Fixed by adding exclude globs for the removed
  trees (see above) rather than working around the gate. (2)
  `world_transition_handoff_smoke.gd` failed 3/3 in a row early in this
  session, which looked like a real regression from the debug_console
  removal. Bisection (temporary worktrees at the pre-cleanup commit, at the
  vendor-only commit, and with autoloads/addon-dir removed independently,
  each with a full fresh `--import`) proved it is a pre-existing flaky
  integration test — it is frame-count-bounded against async threaded scene
  loads, and fails under concurrent system load (this machine runs many
  parallel CUSTODIAN agent worktrees). It passed 4/4 and 11/11 (via the
  changed-file runner) once load settled, on both the baseline and the
  cleanup branch. Not caused by this workstream; not fixed by this workstream
  (out of scope).
- Root cause / contributing factors: coverage-exclude list was never extended
  for vendored addon trees because nothing had ever deleted one in bulk
  before; the flaky smoke test's frame-count waits don't account for CPU/disk
  contention from sibling agent worktrees on this shared machine.
- Prevention / pipeline improvement: consider a path-based coverage exclude
  rule for `custodian/addons/<vendor>/**` trees generically (vendor code this
  repo doesn't own), and consider making `world_transition_handoff_smoke.gd`'s
  waits load-tolerant (poll a real signal/state instead of a fixed frame
  budget) — filed here as a discovered issue, not fixed, since it's unrelated
  to addon cleanup.
- Tooling / docs drift discovered: see both items above.
- Follow-up: manual-follow-up (the `world_transition_handoff_smoke.gd`
  flakiness under concurrent load is worth a dedicated look; not blocking)
- What worked: bisecting with disposable `git worktree add <commit>` copies
  (on `/home/braydenchaffee/Projects`, not tmpfs `/tmp`, which hit a quota
  under concurrent worktree load) cleanly separated "caused by our change"
  from "pre-existing flake," which a single failing run could not have told
  apart.

## Repository-size reduction

600 files removed (63,359 deleted lines per `git diff --stat`), **87MB
on-disk** (`du -sh` per removed addon on the untouched main checkout):
LimboAI 82MB (dominated by its per-platform native `.so`/`.dll`/`.wasm`/
`.dylib` binaries, Git-LFS-tracked per `.gitattributes`), Fight Engine 1.2MB
(demo sprite sheets/GIFs, ordinary git), Debug Console 2.1MB, AI Coding
Assistant 688KB, `__MACOSX` 700KB, Sprite Pipeline 236KB, Godot MCP 220KB,
Indie Game Components 76KB, Aseprite Importer 68KB, AnimSheet 64KB, Copy All
Errors 20KB — the rest ordinary git, not LFS. Sound FX Starter Pack (215MB)
was deliberately **not** touched (one file in active use; see Retained
above), so it does not count toward this reduction.
