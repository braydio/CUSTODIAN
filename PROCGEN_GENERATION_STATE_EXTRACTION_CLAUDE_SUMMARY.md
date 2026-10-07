# PROCGEN_GENERATION_STATE_EXTRACTION — Closing Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4

Workstream `procgen-generation-state-extraction` (D3). Agent: claude.

## What changed
- New owner `custodian/game/world/procgen/generation/accepted_world_export.gd` (`ProcgenAcceptedWorldExport`): TileMap-to-cell capture, the ordered 69-key level-data schema (`pass`/`deep`/`shallow`/`cells` modes), the terrain-builder level-data summary, `dict_keys_as_vector2i_array`, detached cell copies, and the runtime authoring fingerprint.
- `ProcGenTilemap` delegates: `_capture_generated_tile_state`, `get_level_data` (now only gathers raw sources), `debug_get_generated_*_cells`, `debug_get_runtime_authoring_fingerprint`, `_dict_keys_as_vector2i_array`. `_get_terrain_builder_level_data` was deleted (sole caller was `get_level_data`). Host file 12,023 -> 11,978 lines.
- New parity smoke `procgen_accepted_world_export_smoke.gd`, registered in `validation_manifest.json`.
- Packet refreshed in place (guard section removed, completion truth/feedback filled), generation README, FILE_INDEX, and roadmap D3 row/state updated.

## Evidence
- Fixed seed 3716816988, 72x64: level-data hash `2068075335`, fingerprint hash `2896026968`, 69 keys — identical before and after (baseline stable over 3 runs).
- Passing: candidate promotion, candidate semantic model, spatial normalization, world contract prewarm, macro presentation, ash-bell generation contract, S1 quick (`determinism_ok=true`), new export smoke.
- Negative control: flipping `intent_zones_enabled` to false made the parity smoke fail with a hash drift; reverted.

## Awkward parts / limits (said plainly)
- **Overlay separation is not done.** The packet asked for runtime mutation overlays "represented separately". `_generated_floor_cells`/`_generated_wall_cells` are mutated at ~60 runtime sites (terrain commits, connector dry-runs), so they stay hosted by `ProcGenTilemap`; only capture and export moved, and exports are always detached copies. Real base-vs-overlay storage separation belongs to the GenerationGrid initiative (X1+) and is deferred there.
- The packet was marked refresh-gated in prose though its dependencies had archived and it named the execution agent as refresh owner with no user refresh required; I treated the re-audit as mine, recorded it in the packet, and removed the guard. Archive Resolve AR1-AR3 are landed; only the AR4 frontier-restraint review is open. None of its seams were touched.
- `random_floor_tiles` (RNG) and fingerprint `health` (timing) are not value-stable, so the parity hash excludes them and checks them structurally.
- `get_level_data` still lists every source field in the host; the key list now lives in two places (host source gathering, exporter schema). Collapsing that is a GenerationGrid-era concern.
- Dispatch was briefly blocked by another live Codex claim (`LOCAL DISPATCH BUSY`); I waited and retried without touching the lock.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: dispatch lock contention; fresh worktree lacked `.godot` import cache; level data not byte-stable across runs
- Root cause / contributing factors: concurrent Codex claim; recipes omit the import step for fresh worktrees; RNG/timing keys in level data and fingerprint
- Prevention / pipeline improvement: parity smoke excludes nondeterministic keys and checks them structurally
- Tooling / docs drift discovered: packet prose stayed "refresh-gated" after deps archived; VALIDATION_RECIPES does not mention `godot --import` before `--script` smokes in a fresh worktree
- Follow-up: fixed-in-scope
- What worked: baselining hashes before touching code made the extraction a mechanical, verifiable move

## Next Handoff
- Next workstream: procgen-generation-data-model-audit
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4
- Refresh reason: none
- Next action: D2 (`procgen-authored-claim-registry-extraction`) must complete; X1 then becomes eligible automatically.
- Blockers or open questions: none
