# Sprite Inbox Manifest Pipeline

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex CLI 2026-05-15
- Created: 2026-05-15
- Last updated: 2026-05-15

## Task

Add a repo-local script that generates missing JSON manifests for PNGs dropped into `custodian/content/sprites/_pipeline/inbox/` using deterministic filename and image-size heuristics, then runs the existing sprite ingest pipeline.

## Outcome

- Dropped inbox PNGs can be converted into pipeline manifests without model assistance.
- The generated manifests match the current pipeline schema.
- The script runs the existing ingest pipeline after manifest generation.
- Existing manifests are left alone unless explicitly regenerated.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/03_architecture/SPRITE_PIPELINE_SYSTEM.md`
- Active runtime/docs files: `custodian/content/sprites/_pipeline/README.md`, `custodian/tools/pipelines/README.md`, `custodian/tools/pipelines/ingest.py`, `custodian/tools/pipelines/ingest_runtime.gd`
- Historical reference only: legacy Python-era sprite pipeline notes and archives

## Work Surface

- Files or folders expected to change:
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

- Determinism concerns: manifest generation should be filename/image-driven, not random.
- Simulation/UI boundary concerns: none.
- Asset requirements: do not invent art; only process existing inbox PNGs.
- Compatibility or migration concerns: preserve the existing ingest schema and archive/log behavior.
- Clarifying questions or assumptions: assume inbox PNGs are intended for one PNG one manifest unless a matching JSON already exists.

## Implementation Plan

1. Add a wrapper script that finds inbox PNGs lacking manifests and generates manifest JSON from filename and image dimensions.
2. Validate generated JSON, write it next to the PNG, and skip files that already have manifests unless regeneration is requested.
3. Run `custodian/tools/pipelines/ingest.py` after manifest generation and update the docs/context pack.

## Acceptance

- Runtime behavior:
  - The new script generates manifests for inbox PNGs and runs ingest.
- Documentation:
  - The sprite pipeline docs mention the new script and workflow.
- Path/reference validation:
  - Script paths and pipeline paths resolve correctly from the repo root.
- Manual validation:
  - Running the script on an inbox PNG produces a JSON manifest and then ingests it.
- Automated/headless validation:
  - The script supports a non-interactive run path.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: deterministic inbox manifest generator added at `custodian/tools/pipelines/generate_inbox_manifests.py`, pipeline README updated, and AI context indexed.
- Validated: `python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run`; `python -m py_compile custodian/tools/pipelines/generate_inbox_manifests.py`
- Deferred: no inbox PNGs were present to exercise the manifest-generation path end to end

## Next Steps

- Next action: harden the heuristic mappings if new asset domains appear.
- Best starting files: `custodian/tools/pipelines/ingest.py`, `custodian/content/sprites/_pipeline/README.md`
- Required context: current pipeline manifest schema and canonical sprite naming rules
- Validation to run: dry run on a temporary inbox PNG plus pipeline ingest
- Blockers or open questions: none
