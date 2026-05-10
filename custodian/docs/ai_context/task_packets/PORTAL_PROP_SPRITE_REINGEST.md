# Portal Prop Sprite Reingest

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Ingest the current portal-ring sprite pipeline inbox assets into canonical environment prop runtime paths and keep existing portal FX runtime compatibility available.

## Outcome

Portal-ring idle, activation, and arrival runtime sheets exist under `res://content/sprites/environment/props/portal_ring/runtime/fx/`, `PortalTeleporter` uses the canonical prop-owned paths, and legacy `effects/runtime/portal_ring/` copies exist for compatibility.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
- Active runtime/docs files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/content/sprites/_pipeline/`
- Historical reference only: legacy Python runtime and older sprite names

## Work Surface

- Files or folders expected to change: portal ingest manifests, portal runtime sprite outputs, `portal_teleporter.gd`, AI context docs
- Files or folders expected to be read but not changed: sprite pipeline tooling and asset convention docs
- Out-of-scope areas: operator combat animation ingest and broader procgen portal behavior

## Constraints

- Determinism concerns: no simulation behavior changes beyond asset path/frame-count reads
- Simulation/UI boundary concerns: portal FX remains presentation-owned, teleport timing stays in `PortalTeleporter`
- Asset requirements: use existing inbox PNGs; do not invent missing art
- Compatibility or migration concerns: write canonical prop assets plus legacy effects copies while runtime moves to canonical prop paths
- Clarifying questions or assumptions: duplicate `portal_ringf__arrive_01__6ft.png` is byte-identical to `portal_ring__arrive_01__6ft.png` and should be archived instead of ingested as a second runtime asset

## Implementation Plan

1. Add sidecar JSON manifests for the portal inbox sheets.
2. Run sprite ingest for the portal manifests and import generated assets.
3. Repoint portal FX playback to canonical prop-owned paths and update documentation.

## Acceptance

- Runtime behavior: portal FX preload paths resolve to generated prop-owned runtime sheets
- Documentation: AI context documents mention canonical portal prop FX ownership
- Path/reference validation: generated output paths exist and duplicate inbox source is archived
- Manual validation: not required for this quick ingest slice
- Automated/headless validation: run the sprite ingest and a Godot import/check command if feasible

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? No

## Completion Notes

- Implemented: added portal ingest manifests, generated canonical prop-owned portal FX sheets, generated legacy effects compatibility copies, archived the duplicate typo arrival source, and repointed `PortalTeleporter` to the canonical prop-owned sheets.
- Validated: ran sprite ingest dry-run, non-dry-run ingest, Godot asset import, and headless script parsing for `portal_teleporter.gd`.
- Deferred: in-editor portal playback playtest.

## Next Steps

- Next action: playtest portal FX in a generated map
- Best starting files: `custodian/content/sprites/_pipeline/inbox/portal*.json`
- Required context: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
- Validation to run: `python3 tools/pipelines/ingest.py --manifest <portal manifest>` from `custodian/`
- Blockers or open questions: none
