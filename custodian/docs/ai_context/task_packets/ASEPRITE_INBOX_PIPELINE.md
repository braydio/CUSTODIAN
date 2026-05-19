# Aseprite Inbox Pipeline

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex CLI 2026-05-16
- Created: 2026-05-16
- Last updated: 2026-05-16

## Task

Add an aseprite drop folder and a helper script that moves exported PNGs into the sprite pipeline inbox, normalizes filenames to the pipeline naming contract, prompts for incomplete filename blocks when needed, and can optionally run the existing manifest/ingest pipeline afterward.

## Outcome

- Aseprite exports can be dropped into a dedicated staging folder.
- The helper script renames/moves PNGs into `_pipeline/inbox/` using pipeline-safe names.
- Incomplete or malformed names are resolved interactively instead of reaching ingest unchanged.
- The script can optionally chain the current manifest generation and ingest run.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/03_architecture/SPRITE_PIPELINE_SYSTEM.md`
- Active runtime/docs files: `custodian/content/sprites/_pipeline/README.md`, `custodian/tools/pipelines/README.md`, `custodian/tools/pipelines/ingest.py`, `custodian/tools/pipelines/generate_inbox_manifests.py`, `custodian/tools/pipelines/ingest_runtime.gd`
- Historical reference only: legacy Python-era sprite pipeline notes and archives

## Work Surface

- Files or folders expected to change:
  - `custodian/content/sprites/_pipeline/aseprite/`
  - `custodian/tools/pipelines/`
  - `custodian/content/sprites/_pipeline/README.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/sprites/_pipeline/archive/`
  - `custodian/content/sprites/_pipeline/logs/`
  - `custodian/content/sprites/_pipeline/normalized/`
- Out-of-scope areas:
  - runtime simulation logic
  - non-sprite asset pipelines

## Constraints

- Determinism concerns: filename normalization should be deterministic once the user supplies the missing blocks.
- Simulation/UI boundary concerns: none.
- Asset requirements: do not invent art; only move existing aseprite exports.
- Compatibility or migration concerns: preserve the existing inbox manifest and ingest flow.
- Clarifying questions or assumptions: assume the drop folder contains exported PNGs, optionally with adjacent JSON manifests, and that the helper should preserve the original files by moving them rather than copying.

## Implementation Plan

1. Add the aseprite staging folder and a helper script for normalization and optional ingest chaining.
2. Update sprite pipeline docs and AI context references for the new entrypoint.
3. Validate the script syntax and a dry-run or limited-path execution path.

## Acceptance

- Runtime behavior:
  - The helper can move PNGs from the aseprite staging folder into `_pipeline/inbox/`.
  - Incomplete names trigger prompts for the missing filename blocks.
  - Optional flags can run manifest generation and ingest after staging.
- Documentation:
  - The sprite pipeline docs mention the new aseprite staging workflow.
- Path/reference validation:
  - Script paths and pipeline paths resolve correctly from the repo root.
- Manual validation:
  - Running the helper on a sample export path produces a normalized inbox filename.
- Automated/headless validation:
  - The helper supports a non-interactive dry-run path.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: added `custodian/tools/pipelines/aseprite_inbox.py`, staged the new `custodian/content/sprites/_pipeline/aseprite/` drop folder, and updated sprite pipeline docs/context entries.
- Validated: `python -m py_compile custodian/tools/pipelines/aseprite_inbox.py custodian/tools/pipelines/generate_inbox_manifests.py`; `python custodian/tools/pipelines/aseprite_inbox.py --source /tmp/custodian-aseprite-test --dry-run --yes`; interactive prompt path with a throwaway temp PNG source.
- Deferred: the helper currently normalizes canonical sprite-sheet names only; if you want item or harvesting-node renaming prompts as first-class templates, that can be added next.

## Next Steps

- Next action: implement the aseprite staging helper and docs updates.
- Best starting files: `custodian/tools/pipelines/README.md`, `custodian/content/sprites/_pipeline/README.md`
- Required context: canonical sprite naming and current ingest CLI behavior
- Validation to run: script dry-run and direct syntax checks
- Blockers or open questions: none
